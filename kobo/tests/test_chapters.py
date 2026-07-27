"""Tests for registering newly-appended chapters into the DB (TDD RED first).

Background (from the real device): when we prevent a re-import (the no-reset
trick), the KOBO never learns about appended chapters. We must insert a
chapter (``CONTENT_TYPE_CHAPTER``) row per new chapter and bump the book row's
``NumShortcovers`` (the chapter count), so the reader shows them.

Real chapter-row semantics we decoded:
- ContentID = "<mnt path>!!<frag>"  (no file:// scheme)
- VolumeIndex = split_number + 1  (titlepage=0, split_000=1, ...)
- ___FileOffset = an integer bucket that saturates near 99 at the end of a book
- ___FileSize = a fractional *weight*; sum across chapters ~= 100
- WordCount = words in the chapter HTML
- ReadStatus=0, ___PercentRead=0, ___NumPages=-1 for a new unread chapter
"""

from __future__ import annotations

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
BOOK_CID = ONBOARD_PREFIX + BOOK_REL


def _open(db_path):
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    return conn


def _chapter_rows(conn):
    cur = conn.execute(
        "SELECT * FROM content WHERE ContentType=? AND BookID=? ORDER BY VolumeIndex",
        (kp.CONTENT_TYPE_CHAPTER, BOOK_CID),
    )
    return [dict(r) for r in cur.fetchall()]


def _toc_rows(conn):
    """TOC (navigation) rows are the table-of-contents entries."""
    cur = conn.execute(
        "SELECT * FROM content WHERE ContentType=? AND BookID=? ORDER BY VolumeIndex",
        (kp.CONTENT_TYPE_TOC, BOOK_CID),
    )
    return [dict(r) for r in cur.fetchall()]


# ----------------------------- word count -----------------------------


def test_count_words_in_chapter(tmp_path):
    epub = str(tmp_path / "book.epub")
    make_epub(epub, num_chapters=3)  # chapter n has (10 + n) words
    assert kp.count_words(epub, _chapter_frag(2)) == 12


# ----------------------------- detect missing chapters -----------------------------


def test_missing_chapter_splits(tmp_path):
    """Return split numbers present in the EPUB but absent from the DB rows."""
    db = str(tmp_path / "k.sqlite")
    make_db(
        db,
        BOOK_CID,
        num_chapters=104,
        file_size=1000,  # DB has splits 000..103
        read_status=2,
        percent=100,
        chapter_bookmarked="titlepage.xhtml#",
    )
    epub = str(tmp_path / "book.epub")
    make_epub(epub, num_chapters=107)  # EPUB has 000..106
    conn = _open(db)
    assert kp.missing_chapter_splits(conn, BOOK_CID, epub) == [104, 105, 106]


def test_no_missing_chapters(tmp_path):
    db = str(tmp_path / "k.sqlite")
    make_db(
        db,
        BOOK_CID,
        num_chapters=104,
        file_size=1000,
        read_status=2,
        percent=100,
        chapter_bookmarked="titlepage.xhtml#",
    )
    epub = str(tmp_path / "book.epub")
    make_epub(epub, num_chapters=104)
    conn = _open(db)
    assert kp.missing_chapter_splits(conn, BOOK_CID, epub) == []


# ----------------------------- register new chapters -----------------------------


def test_register_inserts_rows_with_correct_shape(tmp_path):
    db = str(tmp_path / "k.sqlite")
    make_db(
        db,
        BOOK_CID,
        num_chapters=104,
        file_size=1000,
        read_status=2,
        percent=100,
        chapter_bookmarked="titlepage.xhtml#",
    )
    epub = str(tmp_path / "book.epub")
    make_epub(epub, num_chapters=106)  # new: split_104, split_105
    conn = _open(db)

    kp.register_new_chapters(conn, BOOK_CID, epub)

    rows = _chapter_rows(conn)
    # split_105 is the new last chapter -> VolumeIndex 106
    new = {r["Title"]: r for r in rows}
    frag104, frag105 = _chapter_frag(104), _chapter_frag(105)
    assert frag104 in new and frag105 in new

    r = new[frag105]
    assert r["ContentID"] == _chapter_content_id(BOOK_CID, frag105)
    assert r["ContentType"] == kp.CONTENT_TYPE_CHAPTER
    assert r["BookID"] == BOOK_CID
    assert r["MimeType"] == "application/xhtml+xml"
    assert r["VolumeIndex"] == 106  # split_number + 1
    assert r["ReadStatus"] == 0
    assert r["___PercentRead"] == 0
    assert r["___NumPages"] == -1
    assert r["WordCount"] == 115  # 10 + 105


def test_register_bumps_numshortcovers(tmp_path):
    db = str(tmp_path / "k.sqlite")
    make_db(
        db,
        BOOK_CID,
        num_chapters=104,
        file_size=1000,  # NumShortcovers=104
        read_status=2,
        percent=100,
        chapter_bookmarked="titlepage.xhtml#",
    )
    epub = str(tmp_path / "book.epub")
    make_epub(epub, num_chapters=107)  # 3 new chapters
    conn = _open(db)

    kp.register_new_chapters(conn, BOOK_CID, epub)

    row = kp.find_book_row(conn, BOOK_CID)
    assert row["NumShortcovers"] == 107


def test_register_is_idempotent(tmp_path):
    db = str(tmp_path / "k.sqlite")
    make_db(
        db,
        BOOK_CID,
        num_chapters=104,
        file_size=1000,
        read_status=2,
        percent=100,
        chapter_bookmarked="titlepage.xhtml#",
    )
    epub = str(tmp_path / "book.epub")
    make_epub(epub, num_chapters=106)
    conn = _open(db)

    kp.register_new_chapters(conn, BOOK_CID, epub)
    kp.register_new_chapters(conn, BOOK_CID, epub)  # second run: nothing new

    rows = _chapter_rows(conn)
    titles = [r["Title"] for r in rows]
    # no duplicates
    assert len(titles) == len(set(titles))
    row = kp.find_book_row(conn, BOOK_CID)
    assert row["NumShortcovers"] == 106


def test_register_no_new_chapters_is_noop(tmp_path):
    db = str(tmp_path / "k.sqlite")
    make_db(
        db,
        BOOK_CID,
        num_chapters=104,
        file_size=1000,
        read_status=2,
        percent=100,
        chapter_bookmarked="titlepage.xhtml#",
    )
    epub = str(tmp_path / "book.epub")
    make_epub(epub, num_chapters=104)
    conn = _open(db)

    before = len(_chapter_rows(conn))
    kp.register_new_chapters(conn, BOOK_CID, epub)
    after = len(_chapter_rows(conn))
    assert before == after
    assert kp.find_book_row(conn, BOOK_CID)["NumShortcovers"] == 104


# ----------------------------- table of contents (899 rows) -----------------------------


def _epub_with_titles(path, num_chapters):
    """An EPUB whose chapters carry an <h1> title, like the real device files."""
    import zipfile

    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("mimetype", "application/epub+zip")
        z.writestr("titlepage.xhtml", "<html><body><div>cover</div></body></html>")
        for n in range(num_chapters):
            z.writestr(
                _chapter_frag(n),
                f"<html><body><h1>Chapter {n} - The Title</h1><p>body</p></body></html>",
            )


def test_chapter_title_from_h1(tmp_path):
    """The human-readable TOC title comes from the chapter HTML's <h1>."""
    epub = str(tmp_path / "book.epub")
    _epub_with_titles(epub, num_chapters=3)
    assert kp.chapter_title(epub, _chapter_frag(2)) == "Chapter 2 - The Title"


def test_chapter_title_falls_back_to_fragment(tmp_path):
    """With no <h1>, fall back to the bare fragment name."""
    epub = str(tmp_path / "book.epub")
    make_epub(epub, num_chapters=3)  # make_epub chapters have no <h1>
    assert kp.chapter_title(epub, _chapter_frag(2)) == _chapter_frag(2)


def test_register_inserts_toc_rows_with_correct_shape(tmp_path):
    db = str(tmp_path / "k.sqlite")
    make_db(
        db,
        BOOK_CID,
        num_chapters=104,
        file_size=1000,
        read_status=2,
        percent=100,
        chapter_bookmarked="titlepage.xhtml#",
    )
    epub = str(tmp_path / "book.epub")
    _epub_with_titles(epub, num_chapters=106)  # new: split_104, split_105
    conn = _open(db)

    kp.register_new_chapters(conn, BOOK_CID, epub)

    toc = {r["VolumeIndex"]: r for r in _toc_rows(conn)}
    frag105 = _chapter_frag(105)
    # A TOC row must exist for the new chapter, at VolumeIndex == split_number.
    assert 105 in toc
    r = toc[105]
    assert r["ContentType"] == kp.CONTENT_TYPE_TOC
    assert r["BookID"] == BOOK_CID
    assert r["ContentID"] == _chapter_content_id(BOOK_CID, frag105) + "-1"
    assert r["ChapterIDBookmarked"] == _chapter_content_id(BOOK_CID, frag105)
    assert r["Title"] == "Chapter 105 - The Title"
    assert r["MimeType"] == "application/x-kobo-epub+zip"
    assert r["Depth"] == 1


def test_register_adds_one_toc_row_per_new_chapter(tmp_path):
    db = str(tmp_path / "k.sqlite")
    make_db(
        db,
        BOOK_CID,
        num_chapters=104,
        file_size=1000,
        read_status=2,
        percent=100,
        chapter_bookmarked="titlepage.xhtml#",
    )
    epub = str(tmp_path / "book.epub")
    _epub_with_titles(epub, num_chapters=107)  # 3 new chapters
    conn = _open(db)

    before = len(_toc_rows(conn))
    kp.register_new_chapters(conn, BOOK_CID, epub)
    after = len(_toc_rows(conn))
    assert after - before == 3


def test_register_toc_rows_are_idempotent(tmp_path):
    db = str(tmp_path / "k.sqlite")
    make_db(
        db,
        BOOK_CID,
        num_chapters=104,
        file_size=1000,
        read_status=2,
        percent=100,
        chapter_bookmarked="titlepage.xhtml#",
    )
    epub = str(tmp_path / "book.epub")
    _epub_with_titles(epub, num_chapters=106)
    conn = _open(db)

    kp.register_new_chapters(conn, BOOK_CID, epub)
    kp.register_new_chapters(conn, BOOK_CID, epub)  # second run: nothing new

    ids = [r["ContentID"] for r in _toc_rows(conn)]
    assert len(ids) == len(set(ids))  # no duplicate TOC rows
    assert len(_toc_rows(conn)) == 106
