"""Tests for the KOBO reading-progress preserver (written first, TDD RED)."""

from __future__ import annotations

import os
import sqlite3

import pytest

from conftest import (
    ONBOARD_PREFIX,
    _chapter_content_id,
    _chapter_frag,
    make_db,
    make_epub,
)

from kobo_progress import kobo_progress as kp

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


# ----------------------------- 1. derive_content_id -----------------------------


def test_derive_content_id_builds_onboard_path():
    assert kp.derive_content_id(BOOK_REL) == BOOK_CID


def test_derive_content_id_respects_custom_prefix():
    assert (
        kp.derive_content_id("foo/bar.epub", "file:///x/") == "file:///x/foo/bar.epub"
    )


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
    row = kp.find_book_row(conn, BOOK_CID)
    assert row is not None
    assert row["ContentType"] == "6"
    assert row["___FileSize"] == 1000


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
    assert kp.find_book_row(conn, _content_id_for("nope/none.epub")) is None


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
    snap = kp.snapshot_progress(conn, BOOK_CID)
    assert snap["ChapterIDBookmarked"] == _ptr(_chapter_frag(5))
    assert snap["ReadStatus"] == 1
    assert snap["___PercentRead"] == 99
    # chapter vector: split-number -> percent (only >0 need be present, but 5 must be)
    assert snap["chapter_progress"][5] == 3
    assert snap["chapter_progress"][4] == 100


# ----------------------------- 4. max_split_number -----------------------------


def test_max_split_number(tmp_path):
    epub = str(tmp_path / "book.epub")
    make_epub(epub, num_chapters=10)  # splits 000..009
    assert kp.max_split_number(epub) == 9


# ----------------------------- 5. is_finished -----------------------------


def test_is_finished_true_for_read_status_2():
    assert (
        kp.is_finished({"ReadStatus": 2, "ChapterIDBookmarked": _ptr(_chapter_frag(3))})
        is True
    )


def test_is_finished_false_for_titlepage_pointer_when_not_finished():
    # A genuinely unread book also points at the titlepage; it must NOT be
    # treated as finished. Only ReadStatus == 2 counts as finished.
    assert (
        kp.is_finished({"ReadStatus": 1, "ChapterIDBookmarked": "titlepage.xhtml#"})
        is False
    )
    assert (
        kp.is_finished({"ReadStatus": 0, "ChapterIDBookmarked": "titlepage.xhtml#"})
        is False
    )


def test_is_finished_false_midbook():
    assert (
        kp.is_finished({"ReadStatus": 1, "ChapterIDBookmarked": _ptr(_chapter_frag(3))})
        is False
    )


# ----------------------------- 6/7. compute_resume_pointer -----------------------------


def test_case_a_midbook_keeps_exact_pointer(tmp_path):
    epub = str(tmp_path / "book.epub")
    make_epub(epub, num_chapters=110)  # appended new chapters
    snap = {
        "ReadStatus": 1,
        "___PercentRead": 99,
        "ChapterIDBookmarked": _ptr(_chapter_frag(103)),
        "ParagraphBookmarked": 2,
        "BookmarkWordOffset": 5,
        "CurrentChapterProgress": 0.5,
        "chapter_progress": {103: 3},
    }
    out = kp.compute_resume_pointer(snap, epub, prev_max_split=103)
    assert out["ChapterIDBookmarked"] == _ptr(_chapter_frag(103))
    assert out["ReadStatus"] == 1
    assert out["___PercentRead"] == 99
    assert out["ParagraphBookmarked"] == 2
    assert out["BookmarkWordOffset"] == 5


def test_case_b_finished_jumps_to_first_new_chapter(tmp_path):
    epub = str(tmp_path / "book.epub")
    make_epub(epub, num_chapters=110)  # splits 000..109; prev max was 103
    snap = {
        "ReadStatus": 2,
        "___PercentRead": 100,
        "ChapterIDBookmarked": "titlepage.xhtml#",
        "chapter_progress": {103: 100},
    }
    out = kp.compute_resume_pointer(snap, epub, prev_max_split=103)
    # first new chapter = split_104 (bare fragment + '#')
    assert out["ChapterIDBookmarked"] == _ptr(_chapter_frag(104))
    assert out["ReadStatus"] == 1
    # approximate progress = first_new_split / new_max_split * 100, computed in
    # floating point BEFORE rounding (104/109*100 = 95.41 -> 95, not int-div 0).
    expected_pct = round(float(104) / float(109) * 100)
    assert expected_pct == 95
    assert out["___PercentRead"] == expected_pct


def test_unread_book_keeps_titlepage_pointer(tmp_path):
    """A genuinely unread book (not finished) must stay at the start, not jump."""
    epub = str(tmp_path / "book.epub")
    make_epub(epub, num_chapters=110)
    snap = {
        "ReadStatus": 0,
        "___PercentRead": 0,
        "ChapterIDBookmarked": "titlepage.xhtml#",
        "ParagraphBookmarked": 0,
        "BookmarkWordOffset": 0,
        "CurrentChapterProgress": 0.0,
        "chapter_progress": {},
    }
    out = kp.compute_resume_pointer(snap, epub, prev_max_split=103)
    assert out["ChapterIDBookmarked"] == "titlepage.xhtml#"


def test_finished_no_new_chapters_is_noop(tmp_path):
    """Finished book with no new chapters: leave progress exactly as-is."""
    epub = str(tmp_path / "book.epub")
    make_epub(
        epub, num_chapters=104
    )  # splits 000..103; prev max also 103 => nothing new
    snap = {
        "ReadStatus": 2,
        "___PercentRead": 100,
        "ChapterIDBookmarked": "titlepage.xhtml#",
        "chapter_progress": {103: 100},
    }
    out = kp.compute_resume_pointer(snap, epub, prev_max_split=103)
    assert out["ChapterIDBookmarked"] == "titlepage.xhtml#"  # unchanged
    assert out["ReadStatus"] == 2  # stays finished
    assert out["___PercentRead"] == 100  # unchanged


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
    kp.apply_update(
        conn,
        BOOK_CID,
        pointer_fields={
            "ChapterIDBookmarked": _ptr(_chapter_frag(103)),
            "ReadStatus": 1,
            "___PercentRead": 99,
            "ParagraphBookmarked": 0,
            "BookmarkWordOffset": 0,
        },
        new_file_size=2222,
    )
    row = kp.find_book_row(conn, BOOK_CID)
    assert row["___FileSize"] == 2222
    assert row["___PercentRead"] == 99
    assert row["ChapterIDBookmarked"] == _ptr(_chapter_frag(103))


# ----------------------------- 9. restore_mtime -----------------------------


def test_restore_mtime(tmp_path):
    f = tmp_path / "book.epub"
    f.write_bytes(b"data")
    target = 1_600_000_000.0
    kp.restore_mtime(str(f), target)
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
    fields = {
        "ChapterIDBookmarked": _ptr(_chapter_frag(103)),
        "ReadStatus": 1,
        "___PercentRead": 99,
        "ParagraphBookmarked": 0,
        "BookmarkWordOffset": 0,
    }
    kp.apply_update(conn, BOOK_CID, fields, new_file_size=2222)
    kp.apply_update(conn, BOOK_CID, fields, new_file_size=2222)
    row = kp.find_book_row(conn, BOOK_CID)
    assert row["___FileSize"] == 2222
    assert row["ChapterIDBookmarked"] == _ptr(_chapter_frag(103))


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
    with pytest.raises(LookupError):
        kp.apply_update(
            conn, _content_id_for("nope/none.epub"), {"ReadStatus": 1}, new_file_size=1
        )


# ----------------------------- 12. end-to-end Case A after a reset -----------------------------


def test_end_to_end_case_a_restores_after_reset(tmp_path):
    """Simulate: mid-book, device reset the row (percent 0, titlepage), tool restores it."""
    db = str(tmp_path / "k.sqlite")
    epub = str(tmp_path / "book.epub")
    make_epub(epub, num_chapters=110)

    # Snapshot represents the pre-update mid-book state.
    snap = {
        "ReadStatus": 1,
        "___PercentRead": 99,
        "ChapterIDBookmarked": _ptr(_chapter_frag(103)),
        "ParagraphBookmarked": 1,
        "BookmarkWordOffset": 4,
        "CurrentChapterProgress": 0.5,
        "chapter_progress": {103: 3},
    }

    # DB currently in a *reset* state (as if device re-imported).
    make_db(
        db,
        BOOK_CID,
        num_chapters=110,
        file_size=9999,
        read_status=0,
        percent=0,
        chapter_bookmarked="titlepage.xhtml#",
    )
    conn = _open(db)

    pointer = kp.compute_resume_pointer(snap, epub, prev_max_split=103)
    kp.apply_update(conn, BOOK_CID, pointer, new_file_size=os.path.getsize(epub))

    row = kp.find_book_row(conn, BOOK_CID)
    assert row["ChapterIDBookmarked"] == _ptr(_chapter_frag(103))
    assert row["ReadStatus"] == 1
    assert row["___PercentRead"] == 99
    assert row["___FileSize"] == os.path.getsize(epub)


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
    snap = kp.snapshot_progress(conn, BOOK_CID)
    ptr = snap["ChapterIDBookmarked"]
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
    assert kp.prev_max_split_from_db(conn, BOOK_CID) == 103
