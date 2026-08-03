"""Tests for the orchestration layer (preserve_progress) — TDD RED first."""

from __future__ import annotations

import os
import shutil
import sqlite3

import pytest

from conftest import ONBOARD_PREFIX, _chapter_frag, make_db, make_epub

from kobo_progress import BookRow, preserve_progress

BOOK_REL = "onedayokay/Test Book.kepub.epub"
BOOK_CID = ONBOARD_PREFIX + BOOK_REL


def _ptr(frag: str) -> str:
    return frag + "#"


def _open(db_path):
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    return conn


def _setup_onboard(
    tmp_path, *, num_chapters, read_status, percent, bookmark, file_size
):
    """Create a fake onboard root with the DB (in .kobo) and the book file."""
    onboard = tmp_path / "onboard"
    (onboard / ".kobo").mkdir(parents=True)
    (onboard / "onedayokay").mkdir(parents=True)
    db_path = onboard / ".kobo" / "KoboReader.sqlite"
    make_db(
        str(db_path),
        BOOK_CID,
        num_chapters=num_chapters,
        file_size=file_size,
        read_status=read_status,
        percent=percent,
        chapter_bookmarked=bookmark,
    )
    return onboard, db_path


def test_preserve_midbook_keeps_pointer_and_syncs_filesize(tmp_path):
    onboard, db_path = _setup_onboard(
        tmp_path,
        num_chapters=104,
        read_status=1,
        percent=99,
        bookmark=_ptr(_chapter_frag(103)),
        file_size=1000,
    )
    # Old file on device (small), and the new appended EPUB to install.
    dest = onboard / BOOK_REL
    make_epub(str(dest), num_chapters=104)  # current file
    old_mtime = 1_600_000_000.0
    os.utime(str(dest), (old_mtime, old_mtime))
    new_epub = tmp_path / "new.epub"
    make_epub(str(new_epub), num_chapters=110)  # appended

    result = preserve_progress(
        onboard_root=str(onboard),
        book_rel_path=BOOK_REL,
        new_epub_path=str(new_epub),
    )

    conn = _open(str(db_path))
    book = BookRow.from_database(conn, BOOK_CID)
    assert book.pointer.chapter_id_bookmarked == _ptr(_chapter_frag(103))  # unchanged
    assert book.read_status == 1
    assert book.percent_read == 99  # unchanged (mid-book)
    assert book.file_size == os.path.getsize(str(dest))  # synced to installed file
    # file was actually replaced with the new (larger) epub
    assert os.path.getsize(str(dest)) == os.path.getsize(str(new_epub))
    # mtime restored to the original
    assert abs(os.path.getmtime(str(dest)) - old_mtime) < 1.0
    # new chapters (104..109) were registered even though it's mid-book
    assert result.chapters_registered == 6
    assert book.num_shortcovers == 110


def test_preserve_accepts_absolute_dest_under_onboard(tmp_path):
    """dest may be an absolute path under onboard_root, not just relative."""
    onboard, db_path = _setup_onboard(
        tmp_path,
        num_chapters=104,
        read_status=1,
        percent=99,
        bookmark=_ptr(_chapter_frag(103)),
        file_size=1000,
    )
    dest = onboard / BOOK_REL
    make_epub(str(dest), num_chapters=104)
    new_epub = tmp_path / "new.epub"
    make_epub(str(new_epub), num_chapters=110)

    # Pass the FULL absolute destination path.
    preserve_progress(str(onboard), str(dest), str(new_epub))

    conn = _open(str(db_path))
    book = BookRow.from_database(conn, BOOK_CID)
    assert book.pointer.chapter_id_bookmarked == _ptr(_chapter_frag(103))
    assert book.file_size == os.path.getsize(str(dest))


def test_preserve_finished_jumps_to_first_new_chapter(tmp_path):
    onboard, db_path = _setup_onboard(
        tmp_path,
        num_chapters=104,
        read_status=2,
        percent=100,
        bookmark="titlepage.xhtml#",
        file_size=1000,
    )
    dest = onboard / BOOK_REL
    make_epub(str(dest), num_chapters=104)
    new_epub = tmp_path / "new.epub"
    make_epub(str(new_epub), num_chapters=110)  # splits up to 109; prev max 103

    result = preserve_progress(str(onboard), BOOK_REL, str(new_epub))

    conn = _open(str(db_path))
    book = BookRow.from_database(conn, BOOK_CID)
    assert book.pointer.chapter_id_bookmarked == _ptr(_chapter_frag(104))  # first new chapter
    assert book.read_status == 1
    assert result.chapters_registered == 6  # 104..109
    assert book.num_shortcovers == 110


def test_preserve_creates_db_backup(tmp_path):
    onboard, db_path = _setup_onboard(
        tmp_path,
        num_chapters=104,
        read_status=1,
        percent=99,
        bookmark=_ptr(_chapter_frag(103)),
        file_size=1000,
    )
    dest = onboard / BOOK_REL
    make_epub(str(dest), num_chapters=104)
    new_epub = tmp_path / "new.epub"
    make_epub(str(new_epub), num_chapters=110)

    preserve_progress(str(onboard), BOOK_REL, str(new_epub))

    backups = list((onboard / ".kobo").glob("KoboReader.sqlite.bak*"))
    assert len(backups) == 1


def test_preserve_skip_backup(tmp_path):
    """With backup=False (batch mode), no per-file DB backup is created."""
    onboard, db_path = _setup_onboard(
        tmp_path,
        num_chapters=104,
        read_status=1,
        percent=99,
        bookmark=_ptr(_chapter_frag(103)),
        file_size=1000,
    )
    dest = onboard / BOOK_REL
    make_epub(str(dest), num_chapters=104)
    new_epub = tmp_path / "new.epub"
    make_epub(str(new_epub), num_chapters=110)

    preserve_progress(str(onboard), BOOK_REL, str(new_epub), backup=False)

    backups = list((onboard / ".kobo").glob("KoboReader.sqlite.bak*"))
    assert backups == []


def test_preserve_writes_snapshot_sidecar(tmp_path):
    onboard, db_path = _setup_onboard(
        tmp_path,
        num_chapters=104,
        read_status=1,
        percent=99,
        bookmark=_ptr(_chapter_frag(103)),
        file_size=1000,
    )
    dest = onboard / BOOK_REL
    make_epub(str(dest), num_chapters=104)
    new_epub = tmp_path / "new.epub"
    make_epub(str(new_epub), num_chapters=110)

    result = preserve_progress(str(onboard), BOOK_REL, str(new_epub))
    assert os.path.exists(result.snapshot_path)
    # sidecar lives next to the SOURCE epub, not in the book target dir / .kobo
    assert os.path.dirname(os.path.abspath(result.snapshot_path)) == os.path.dirname(
        os.path.abspath(str(new_epub))
    )


def test_preserve_result_reports_action(tmp_path):
    """Result dict reports what happened (for logging): pointer change + counts."""
    onboard, db_path = _setup_onboard(
        tmp_path,
        num_chapters=104,
        read_status=1,
        percent=99,
        bookmark=_ptr(_chapter_frag(103)),
        file_size=1000,
    )
    dest = onboard / BOOK_REL
    make_epub(str(dest), num_chapters=104)
    new_epub = tmp_path / "new.epub"
    make_epub(str(new_epub), num_chapters=110)

    result = preserve_progress(str(onboard), BOOK_REL, str(new_epub))
    assert result.pointer_changed is False  # mid-book: pointer kept
    assert result.chapters_registered == 6
    assert result.filesize_synced is True


def test_preserve_missing_book_raises_and_does_not_replace_file(tmp_path):
    onboard, db_path = _setup_onboard(
        tmp_path,
        num_chapters=104,
        read_status=1,
        percent=99,
        bookmark=_ptr(_chapter_frag(103)),
        file_size=1000,
    )
    # Point at a book that isn't in the DB.
    (onboard / "other").mkdir()
    other_rel = "other/Missing.kepub.epub"
    dest = onboard / other_rel
    make_epub(str(dest), num_chapters=5)
    original_size = os.path.getsize(str(dest))
    new_epub = tmp_path / "new.epub"
    make_epub(str(new_epub), num_chapters=20)

    with pytest.raises(LookupError):
        preserve_progress(str(onboard), other_rel, str(new_epub))
    # file must be untouched when the book isn't found
    assert os.path.getsize(str(dest)) == original_size
