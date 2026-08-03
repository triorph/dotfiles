"""Tests for the KOBO reading-progress preserver (written first, TDD RED)."""

from __future__ import annotations

import os
import sqlite3

from conftest import (
    ONBOARD_PREFIX,
    _chapter_content_id,
    _chapter_frag,
    make_db,
    make_epub,
)

from kobo_progress import (
    BookRow,
    ContentType,
    Epub,
    Pointer,
    Snapshot,
    compute_resume_pointer,
    derive_content_id,
    prev_max_split,
    restore_mtime,
)

BOOK_REL = "onedayokay/Test Book.kepub.epub"


def _content_id_for(rel: str) -> str:
    return ONBOARD_PREFIX + rel


BOOK_CID = _content_id_for(BOOK_REL)


def _ptr(frag: str) -> str:
    """The book-row pointer form: a bare fragment with a trailing '#'."""
    return frag + "#"


# ----------------------------- helpers -----------------------------


def _open(db_path):
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    return conn


def _snap(pointer: Pointer, chapter_progress: dict | None = None) -> Snapshot:
    return Snapshot(pointer=pointer, chapter_progress=chapter_progress or {})


# ----------------------------- 1. derive_content_id -----------------------------


def test_derive_content_id_builds_onboard_path():
    assert derive_content_id(BOOK_REL) == BOOK_CID


def test_derive_content_id_respects_custom_prefix():
    assert derive_content_id("foo/bar.epub", "file:///x/") == "file:///x/foo/bar.epub"


# ----------------------------- 2. find_book_row -----------------------------


def test_find_book_row_returns_book(tmp_path):
    db = str(tmp_path / "k.sqlite")
    make_db(
        db,
        BOOK_CID,
        num_chapters=5,
        file_size=1000,
        read_status=1,
        percent=50,
        chapter_bookmarked=_ptr(_chapter_frag(3)),
    )
    conn = _open(db)
    book = BookRow.from_database(conn, BOOK_CID)
    assert book is not None
    assert book.read_status == 1  # loaded as a typed BookRow
    assert book.file_size == 1000


def test_find_book_row_missing_returns_none(tmp_path):
    db = str(tmp_path / "k.sqlite")
    make_db(
        db,
        BOOK_CID,
        num_chapters=5,
        file_size=1000,
        read_status=1,
        percent=50,
        chapter_bookmarked=_ptr(_chapter_frag(3)),
    )
    conn = _open(db)
    assert BookRow.from_database(conn, _content_id_for("nope/none.epub")) is None


# ----------------------------- 3. snapshot_progress -----------------------------


def test_snapshot_captures_pointer_and_chapter_vector(tmp_path):
    db = str(tmp_path / "k.sqlite")
    make_db(
        db,
        BOOK_CID,
        num_chapters=6,
        file_size=1000,
        read_status=1,
        percent=99,
        chapter_bookmarked=_ptr(_chapter_frag(5)),
        chapter_progress={4: 100, 5: 3},
    )
    conn = _open(db)
    snap = Snapshot.capture(conn, BookRow.from_database(conn, BOOK_CID))
    assert snap.pointer.chapter_id_bookmarked == _ptr(_chapter_frag(5))
    assert snap.pointer.read_status == 1
    assert snap.pointer.percent_read == 99
    # chapter vector: split-number -> percent (only >0 need be present, but 5 must be)
    assert snap.chapter_progress[5] == 3
    assert snap.chapter_progress[4] == 100


# ----------------------------- 4. max_split_number -----------------------------


def test_max_split_number(tmp_path):
    epub = str(tmp_path / "book.epub")
    make_epub(epub, num_chapters=10)  # splits 000..009
    assert Epub(epub).max_split() == 9


# ----------------------------- 5. is_finished -----------------------------


def test_is_finished_true_for_read_status_2():
    snap = _snap(Pointer(read_status=2, chapter_id_bookmarked=_ptr(_chapter_frag(3))))
    assert snap.is_finished is True


def test_is_finished_false_for_titlepage_pointer_when_not_finished():
    # A genuinely unread book also points at the titlepage; it must NOT be
    # treated as finished. Only ReadStatus == 2 counts as finished.
    assert (
        _snap(Pointer(read_status=1, chapter_id_bookmarked="titlepage.xhtml#")).is_finished
        is False
    )
    assert (
        _snap(Pointer(read_status=0, chapter_id_bookmarked="titlepage.xhtml#")).is_finished
        is False
    )


def test_is_finished_false_midbook():
    snap = _snap(Pointer(read_status=1, chapter_id_bookmarked=_ptr(_chapter_frag(3))))
    assert snap.is_finished is False


# ----------------------------- 6/7. compute_resume_pointer -----------------------------


def test_case_a_midbook_returns_no_pointer_changes(tmp_path):
    """Mid-book: the progress row must NOT be touched (returns no fields to write).

    Writing the pointer back, even 'verbatim', was clobbering the intra-chapter
    position (jumped to the start of the chapter). The safe fix is to leave the
    book row untouched for non-finished books.
    """
    epub = str(tmp_path / "book.epub")
    make_epub(epub, num_chapters=110)  # appended new chapters
    snap = _snap(
        Pointer(
            read_status=1,
            percent_read=99,
            chapter_id_bookmarked=_ptr(_chapter_frag(103)),
            paragraph_bookmarked=2,
            bookmark_word_offset=5,
            current_chapter_progress=0.5,
        ),
        {103: 3},
    )
    out = compute_resume_pointer(snap, Epub(epub), prev_max_split=103)
    assert out.is_empty()


def test_case_b_finished_jumps_to_first_new_chapter(tmp_path):
    epub = str(tmp_path / "book.epub")
    make_epub(epub, num_chapters=110)  # splits 000..109; prev max was 103
    snap = _snap(
        Pointer(
            read_status=2,
            percent_read=100,
            chapter_id_bookmarked="titlepage.xhtml#",
        ),
        {103: 100},
    )
    out = compute_resume_pointer(snap, Epub(epub), prev_max_split=103)
    # first new chapter = split_104 (bare fragment + '#')
    assert out.chapter_id_bookmarked == _ptr(_chapter_frag(104))
    assert out.read_status == 1
    # approximate progress = first_new_split / new_max_split * 100, computed in
    # floating point BEFORE rounding (104/109*100 = 95.41 -> 95, not int-div 0).
    expected_pct = round(float(104) / float(109) * 100)
    assert expected_pct == 95
    assert out.percent_read == expected_pct


def test_unread_book_keeps_titlepage_pointer(tmp_path):
    """A genuinely unread book (not finished) must stay at the start, not jump."""
    epub = str(tmp_path / "book.epub")
    make_epub(epub, num_chapters=110)
    snap = _snap(
        Pointer(
            read_status=0,
            percent_read=0,
            chapter_id_bookmarked="titlepage.xhtml#",
            paragraph_bookmarked=0,
            bookmark_word_offset=0,
            current_chapter_progress=0.0,
        )
    )
    out = compute_resume_pointer(snap, Epub(epub), prev_max_split=103)
    assert out.is_empty()  # unread & not finished -> leave the row untouched


def test_finished_no_new_chapters_is_noop(tmp_path):
    """Finished book with no new chapters: leave progress exactly as-is."""
    epub = str(tmp_path / "book.epub")
    make_epub(
        epub, num_chapters=104
    )  # splits 000..103; prev max also 103 => nothing new
    snap = _snap(
        Pointer(
            read_status=2,
            percent_read=100,
            chapter_id_bookmarked="titlepage.xhtml#",
        ),
        {103: 100},
    )
    out = compute_resume_pointer(snap, Epub(epub), prev_max_split=103)
    assert out.is_empty()  # finished but nothing new -> leave the row untouched


# ----------------------------- 8. apply_update -----------------------------


def test_apply_update_sets_filesize_and_pointer(tmp_path):
    db = str(tmp_path / "k.sqlite")
    make_db(
        db,
        BOOK_CID,
        num_chapters=104,
        file_size=1000,
        read_status=1,
        percent=99,
        chapter_bookmarked=_ptr(_chapter_frag(103)),
    )
    conn = _open(db)
    book = BookRow.from_database(conn, BOOK_CID)
    book.apply_pointer(
        conn,
        Pointer(
            chapter_id_bookmarked=_ptr(_chapter_frag(103)),
            read_status=1,
            percent_read=99,
            paragraph_bookmarked=0,
            bookmark_word_offset=0,
        ),
        file_size=2222,
    )
    conn.commit()
    book = BookRow.from_database(conn, BOOK_CID)
    assert book.file_size == 2222
    assert book.percent_read == 99
    assert book.pointer.chapter_id_bookmarked == _ptr(_chapter_frag(103))


# ----------------------------- 9. restore_mtime -----------------------------


def test_restore_mtime(tmp_path):
    f = tmp_path / "book.epub"
    f.write_bytes(b"data")
    target = 1_600_000_000.0
    restore_mtime(str(f), target)
    assert abs(os.path.getmtime(str(f)) - target) < 1.0


# ----------------------------- 10. idempotency -----------------------------


def test_apply_update_idempotent(tmp_path):
    db = str(tmp_path / "k.sqlite")
    make_db(
        db,
        BOOK_CID,
        num_chapters=104,
        file_size=1000,
        read_status=1,
        percent=99,
        chapter_bookmarked=_ptr(_chapter_frag(103)),
    )
    conn = _open(db)
    pointer = Pointer(
        chapter_id_bookmarked=_ptr(_chapter_frag(103)),
        read_status=1,
        percent_read=99,
        paragraph_bookmarked=0,
        bookmark_word_offset=0,
    )
    book = BookRow.from_database(conn, BOOK_CID)
    book.apply_pointer(conn, pointer, file_size=2222)
    book.apply_pointer(conn, pointer, file_size=2222)
    conn.commit()
    book = BookRow.from_database(conn, BOOK_CID)
    assert book.file_size == 2222
    assert book.pointer.chapter_id_bookmarked == _ptr(_chapter_frag(103))


# ----------------------------- 11. missing book / empty bookmark -----------------------------


def test_apply_update_missing_book_raises(tmp_path):
    db = str(tmp_path / "k.sqlite")
    make_db(
        db,
        BOOK_CID,
        num_chapters=5,
        file_size=1000,
        read_status=1,
        percent=50,
        chapter_bookmarked=_ptr(_chapter_frag(3)),
    )
    conn = _open(db)
    # The book-not-found guard now lives at the orchestrator boundary; the row
    # loader simply returns None for an unknown book.
    assert BookRow.from_database(conn, _content_id_for("nope/none.epub")) is None


# ----------------------------- 12. end-to-end Case A after a reset -----------------------------


def test_end_to_end_midbook_leaves_row_but_syncs_filesize(tmp_path):
    """Mid-book: the book row is untouched except ___FileSize (no-reset preserves it)."""
    db = str(tmp_path / "k.sqlite")
    epub = str(tmp_path / "book.epub")
    make_epub(epub, num_chapters=110)

    # DB holds the real mid-book position (mid-chapter offsets present).
    make_db(
        db,
        BOOK_CID,
        num_chapters=104,
        file_size=1000,
        read_status=1,
        percent=99,
        chapter_bookmarked=_ptr(_chapter_frag(103)),
    )
    conn = _open(db)
    # Simulate a mid-chapter position saved on the row.
    conn.execute(
        "UPDATE content SET ParagraphBookmarked=7, BookmarkWordOffset=12 "
        "WHERE ContentID=? AND ContentType=?",
        (BOOK_CID, ContentType.BOOK.value),
    )
    conn.commit()

    book = BookRow.from_database(conn, BOOK_CID)
    snap = Snapshot.capture(conn, book)
    pointer = compute_resume_pointer(snap, Epub(epub), prev_max_split=103)
    assert pointer.is_empty()  # nothing to change for a mid-book book
    book.apply_pointer(
        conn,
        pointer,
        file_size=os.path.getsize(epub),
        update_pointer=not pointer.is_empty(),
    )
    conn.commit()

    book = BookRow.from_database(conn, BOOK_CID)
    # Position untouched, including intra-chapter offsets.
    assert book.pointer.chapter_id_bookmarked == _ptr(_chapter_frag(103))
    assert book.read_status == 1
    assert book.percent_read == 99
    assert book.pointer.paragraph_bookmarked == 7
    assert book.pointer.bookmark_word_offset == 12
    # Only the file size was synced.
    assert book.file_size == os.path.getsize(epub)


# ----------------------------- 13. real device string formats -----------------------------


def test_snapshot_pointer_is_bare_fragment_with_hash(tmp_path):
    """The book-row pointer must be a bare fragment + '#', not a full path."""
    db = str(tmp_path / "k.sqlite")
    make_db(
        db,
        BOOK_CID,
        num_chapters=5,
        file_size=1000,
        read_status=1,
        percent=50,
        chapter_bookmarked=_ptr(_chapter_frag(3)),
    )
    conn = _open(db)
    snap = Snapshot.capture(conn, BookRow.from_database(conn, BOOK_CID))
    ptr = snap.pointer.chapter_id_bookmarked
    assert ptr.endswith(".html#")
    assert not ptr.startswith("file://")
    assert "!!" not in ptr


def test_prev_max_split_reads_from_chapter_rows(tmp_path):
    """The tool should read prev_max_split from DB chapter rows (!! ContentIDs)."""
    db = str(tmp_path / "k.sqlite")
    make_db(
        db,
        BOOK_CID,
        num_chapters=104,
        file_size=1000,  # splits 000..103
        read_status=1,
        percent=99,
        chapter_bookmarked=_ptr(_chapter_frag(103)),
    )
    conn = _open(db)
    assert prev_max_split(conn, BOOK_CID) == 103
