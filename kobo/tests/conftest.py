"""Shared fixtures/helpers for kobo_progress tests.

Builds a minimal synthetic ``KoboReader.sqlite`` and tiny fake EPUBs that mimic
the structure we observed on a real device (book row + per-chapter rows,
Calibre-style ``cleaned-..._split_NNN.html`` chapter files, a ``titlepage.xhtml``,
and a ``page.xhtml`` at spine index 0).
"""

from __future__ import annotations

import os
import sqlite3
import sys
import zipfile

import pytest

# Make the package importable when running from the repo root.
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

ONBOARD_PREFIX = "file:///mnt/onboard/"
CHAPTER_STEM = "cleaned-testbook_split_"
# Chapter rows store ContentID as "<mnt path without scheme>!!<frag>".
CHAPTER_SEP = "!!"


def _chapter_frag(n: int) -> str:
    return f"{CHAPTER_STEM}{n:03d}.html"


def _mnt_path(book_cid: str) -> str:
    """Book ContentID without the file:// scheme (chapter rows use this form)."""
    return book_cid[len("file://"):] if book_cid.startswith("file://") else book_cid


def _chapter_content_id(book_cid: str, frag: str) -> str:
    return _mnt_path(book_cid) + CHAPTER_SEP + frag


def make_epub(path: str, num_chapters: int) -> None:
    """Create a minimal EPUB with ``num_chapters`` chapter files (split_000..).

    Includes ``titlepage.xhtml`` and ``page.xhtml`` front matter, plus
    ``cleaned-testbook_split_NNN.html`` chapter files. Content is plain (no
    koboSpan), matching the user's real files.
    """
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("mimetype", "application/epub+zip")
        z.writestr("titlepage.xhtml", "<html><body><div>cover</div></body></html>")
        z.writestr("page.xhtml", "<html><body><p>front matter</p></body></html>")
        for n in range(num_chapters):
            z.writestr(
                _chapter_frag(n),
                f"<html><body><p>chapter {n}</p></body></html>",
            )


def _build_content_schema(conn: sqlite3.Connection) -> None:
    """Create a minimal ``content`` table with the columns the tool touches."""
    conn.execute(
        """
        CREATE TABLE content (
            ContentID TEXT PRIMARY KEY,
            ContentType TEXT,
            BookID TEXT,
            VolumeIndex INTEGER,
            Title TEXT,
            ReadStatus INTEGER,
            ___PercentRead INTEGER,
            ___FileSize INTEGER,
            ___NumPages INTEGER,
            ChapterIDBookmarked TEXT,
            ParagraphBookmarked INTEGER,
            BookmarkWordOffset INTEGER,
            CurrentChapterProgress REAL,
            adobe_location TEXT,
            TimeSpentReading INTEGER,
            TimesStartedReading INTEGER,
            DateLastRead TEXT
        )
        """
    )
    conn.execute("CREATE TABLE Bookmark (BookmarkID TEXT, VolumeID TEXT)")


def make_db(
    path: str,
    content_id: str,
    num_chapters: int,
    file_size: int,
    *,
    read_status: int,
    percent: int,
    chapter_bookmarked: str,
    chapter_progress: dict[int, int] | None = None,
) -> None:
    """Create a synthetic KoboReader.sqlite with one book + its chapter rows.

    ``chapter_bookmarked`` is the bare fragment + '#' (e.g. ``split_103.html#``) or
    ``titlepage.xhtml#`` stored in the book row's ChapterIDBookmarked.
    ``chapter_progress`` maps split-number -> percent.
    """
    conn = sqlite3.connect(path)
    try:
        _build_content_schema(conn)
        # Book row (ContentType 6): ChapterIDBookmarked is a BARE fragment + '#'.
        conn.execute(
            """INSERT INTO content
               (ContentID, ContentType, BookID, VolumeIndex, ReadStatus, ___PercentRead,
                ___FileSize, ___NumPages, ChapterIDBookmarked, ParagraphBookmarked,
                BookmarkWordOffset, CurrentChapterProgress, adobe_location,
                TimeSpentReading, TimesStartedReading, DateLastRead)
               VALUES (?, '6', NULL, -1, ?, ?, ?, -1, ?, 0, 0, 0.0, '', 100, 1, '2026-07-26T21:04:00Z')""",
            (content_id, read_status, percent, file_size, chapter_bookmarked),
        )
        # Chapter rows (ContentType 9): ContentID uses "<mnt path>!!<frag>".
        # VolumeIndex 0 = page.xhtml, then splits.
        conn.execute(
            """INSERT INTO content (ContentID, ContentType, BookID, VolumeIndex, ___PercentRead, ReadStatus)
               VALUES (?, '9', ?, 0, 0, 0)""",
            (_chapter_content_id(content_id, "page.xhtml"), content_id),
        )
        chapter_progress = chapter_progress or {}
        for n in range(num_chapters):
            frag = _chapter_frag(n)
            conn.execute(
                """INSERT INTO content
                   (ContentID, ContentType, BookID, VolumeIndex, Title, ___PercentRead, ReadStatus)
                   VALUES (?, '9', ?, ?, ?, ?, 0)""",
                (_chapter_content_id(content_id, frag), content_id, n + 1, frag,
                 chapter_progress.get(n, 0)),
            )
        conn.commit()
    finally:
        conn.close()


@pytest.fixture
def onboard_prefix() -> str:
    return ONBOARD_PREFIX


@pytest.fixture
def chapter_frag():
    return _chapter_frag
