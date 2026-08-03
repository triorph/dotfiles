"""Focused unit tests for the refactored building blocks.

These exercise the new data classes directly (Epub, paths, row classes,
Snapshot) rather than the end-to-end flow covered elsewhere.
"""

from __future__ import annotations

import sqlite3
import zipfile

from conftest import (
    ONBOARD_PREFIX,
    _chapter_content_id,
    _chapter_frag,
    make_db,
    make_epub,
)

from kobo_progress import (
    BookRow,
    ChapterRow,
    ContentType,
    Epub,
    Pointer,
    Snapshot,
    TocChapterRow,
    chapter_content_id,
    derive_content_id,
    existing_chapter_splits,
    mnt_path,
    relativize_dest,
)

BOOK_REL = "onedayokay/Test Book.kepub.epub"
BOOK_CID = ONBOARD_PREFIX + BOOK_REL


def _ptr(frag: str) -> str:
    return frag + "#"


def _open(db_path):
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    return conn


def _epub_with_titles(path, num_chapters):
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("mimetype", "application/epub+zip")
        for n in range(num_chapters):
            z.writestr(
                _chapter_frag(n),
                f"<html><body><h1>Chapter {n} - The Title</h1><p>body</p></body></html>",
            )


# ----------------------------- ContentType -----------------------------


def test_content_type_values():
    assert ContentType.BOOK.value == "6"
    assert ContentType.CHAPTER.value == "9"
    assert ContentType.TOC.value == "899"


# ----------------------------- paths -----------------------------


def test_paths_helpers():
    assert derive_content_id(BOOK_REL) == BOOK_CID
    assert mnt_path(BOOK_CID) == "/mnt/onboard/" + BOOK_REL
    assert chapter_content_id(BOOK_CID, "x.html") == "/mnt/onboard/" + BOOK_REL + "!!x.html"


def test_relativize_dest_absolute_and_relative():
    assert relativize_dest("/root", "sub/book.epub") == "sub/book.epub"
    assert relativize_dest("/root", "/root/sub/book.epub") == "sub/book.epub"


# ----------------------------- Epub -----------------------------


def test_epub_splits_and_max(tmp_path):
    epub = str(tmp_path / "book.epub")
    make_epub(epub, num_chapters=4)
    e = Epub(epub)
    assert set(e.splits()) == {0, 1, 2, 3}
    assert e.max_split() == 3
    assert e.fragment_for_split(2) == _chapter_frag(2)


def test_epub_word_count_and_title(tmp_path):
    epub = str(tmp_path / "book.epub")
    _epub_with_titles(epub, num_chapters=3)
    e = Epub(epub)
    assert e.title(_chapter_frag(1)) == "Chapter 1 - The Title"
    # "Chapter 1 - The Title body" -> 6 words
    assert e.word_count(_chapter_frag(1)) == 6


def test_epub_title_falls_back_to_fragment(tmp_path):
    epub = str(tmp_path / "book.epub")
    make_epub(epub, num_chapters=2)  # no <h1>
    assert Epub(epub).title(_chapter_frag(1)) == _chapter_frag(1)


def test_epub_chapter_weight_sums_to_100(tmp_path):
    epub = str(tmp_path / "book.epub")
    make_epub(epub, num_chapters=5)
    e = Epub(epub)
    total = sum(e.chapter_weight(f) for f in e.splits().values())
    assert abs(total - 100) < 1e-9


# ----------------------------- BookRow -----------------------------


def _make_book(tmp_path, **kw):
    db = str(tmp_path / "k.sqlite")
    make_db(
        db,
        BOOK_CID,
        num_chapters=kw.get("num_chapters", 5),
        file_size=kw.get("file_size", 1000),
        read_status=kw.get("read_status", 1),
        percent=kw.get("percent", 50),
        chapter_bookmarked=kw.get("bookmark", _ptr(_chapter_frag(3))),
    )
    return db


def test_bookrow_from_database_and_properties(tmp_path):
    db = _make_book(tmp_path, num_chapters=7, read_status=2)
    conn = _open(db)
    book = BookRow.from_database(conn, BOOK_CID)
    assert book.num_shortcovers == 7
    assert book.read_status == 2


def test_bookrow_apply_pointer_writes_pointer_and_filesize(tmp_path):
    db = _make_book(tmp_path)
    conn = _open(db)
    book = BookRow.from_database(conn, BOOK_CID)
    book.apply_pointer(
        conn,
        Pointer(
            read_status=1,
            percent_read=42,
            chapter_id_bookmarked=_ptr(_chapter_frag(1)),
        ),
        555,
    )
    conn.commit()
    reread = BookRow.from_database(conn, BOOK_CID)
    assert reread.file_size == 555
    assert reread.percent_read == 42
    assert reread.pointer.chapter_id_bookmarked == _ptr(_chapter_frag(1))


def test_bookrow_apply_pointer_filesize_only_leaves_position(tmp_path):
    db = _make_book(tmp_path)
    conn = _open(db)
    book = BookRow.from_database(conn, BOOK_CID)
    # update_pointer=False -> only ___FileSize changes; reading position untouched.
    book.apply_pointer(conn, Pointer(), 555, update_pointer=False)
    conn.commit()
    reread = BookRow.from_database(conn, BOOK_CID)
    assert reread.file_size == 555
    assert reread.percent_read == 50  # unchanged from _make_book default
    assert reread.pointer.chapter_id_bookmarked == _ptr(_chapter_frag(3))


def test_bookrow_set_num_shortcovers(tmp_path):
    db = _make_book(tmp_path, num_chapters=5)
    conn = _open(db)
    book = BookRow.from_database(conn, BOOK_CID)
    book.set_num_shortcovers(conn, 12)
    conn.commit()
    assert BookRow.from_database(conn, BOOK_CID).num_shortcovers == 12


# ----------------------------- ChapterRow / TocChapterRow -----------------------------


def test_chapterrow_for_split_builds_expected_row(tmp_path):
    db = _make_book(tmp_path, num_chapters=5)
    epub = str(tmp_path / "book.epub")
    _epub_with_titles(epub, num_chapters=7)
    conn = _open(db)
    frag = _chapter_frag(6)
    row = ChapterRow.for_split(conn, BOOK_CID, Epub(epub), 6, frag)
    assert row.row["ContentID"] == _chapter_content_id(BOOK_CID, frag)
    assert row.row["ContentType"] == ContentType.CHAPTER.value
    assert row.row["VolumeIndex"] == 7  # split + 1
    assert row.row["___FileOffset"] == 99


def test_tocrow_for_split_builds_expected_row(tmp_path):
    db = _make_book(tmp_path, num_chapters=5)
    epub = str(tmp_path / "book.epub")
    _epub_with_titles(epub, num_chapters=7)
    conn = _open(db)
    frag = _chapter_frag(6)
    row = TocChapterRow.for_split(conn, BOOK_CID, Epub(epub), 6, frag)
    assert row.row["ContentID"] == _chapter_content_id(BOOK_CID, frag) + "-1"
    assert row.row["ChapterIDBookmarked"] == _chapter_content_id(BOOK_CID, frag)
    assert row.row["ContentType"] == ContentType.TOC.value
    assert row.row["VolumeIndex"] == 6  # == split number
    assert row.row["Title"] == "Chapter 6 - The Title"


def test_chapterrow_existing_splits(tmp_path):
    db = _make_book(tmp_path, num_chapters=4)
    conn = _open(db)
    assert existing_chapter_splits(conn, BOOK_CID) == {0, 1, 2, 3}


# ----------------------------- Snapshot -----------------------------


def test_snapshot_capture_and_to_json(tmp_path):
    db = str(tmp_path / "k.sqlite")
    make_db(
        db,
        BOOK_CID,
        num_chapters=4,
        file_size=1000,
        read_status=2,
        percent=100,
        chapter_bookmarked=_ptr(_chapter_frag(3)),
        chapter_progress={2: 100, 3: 20},
    )
    conn = _open(db)
    snap = Snapshot.capture(conn, BookRow.from_database(conn, BOOK_CID))
    assert snap.is_finished is True
    assert snap.chapter_progress[3] == 20
    data = snap.to_json()
    assert data["ChapterIDBookmarked"] == _ptr(_chapter_frag(3))
    assert data["chapter_progress"][3] == 20
