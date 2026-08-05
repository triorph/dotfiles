"""The end-to-end flow that installs an updated EPUB while preserving progress."""

from __future__ import annotations

import json
import logging
import os
import shutil
import sqlite3
from dataclasses import dataclass
from datetime import datetime

from . import paths
from .content_rows import (
    BookRow,
    ChapterRow,
    TocChapterRow,
    existing_chapter_splits,
    existing_toc_splits,
)
from .epub import Epub
from .progress import Snapshot, compute_resume_pointer

_log = logging.getLogger("kobo_progress")


@dataclass
class PreserveResult:
    """Outcome of :func:`preserve_progress`."""

    snapshot_path: str
    backup_path: str | None
    chapters_registered: int
    pointer_changed: bool
    filesize_synced: bool = True


class ChapterRegistrar:
    """Reconciles a book's chapter (9) and TOC (899) rows against the EPUB.

    Preventing the device re-import means the KOBO never learns about new
    chapters, so we insert the rows it would have created. The two row types are
    reconciled *independently*: a chapter needs a content row if it lacks one and
    a TOC row if it lacks one. This also backfills TOC rows for chapters an older
    (buggy) run added content rows for but never gave a TOC entry.
    """

    def __init__(self, conn: sqlite3.Connection, book: BookRow, epub: Epub) -> None:
        self.conn = conn
        self.book = book
        self.epub = epub

    def missing_chapter_splits(self) -> list[int]:
        """EPUB splits with no chapter (9) row yet."""
        have = existing_chapter_splits(self.conn, self.book.content_id)
        return sorted(n for n in self.epub.splits() if n not in have)

    def missing_toc_splits(self) -> list[int]:
        """EPUB splits with no TOC (899) row yet."""
        have = existing_toc_splits(self.conn, self.book.content_id)
        return sorted(n for n in self.epub.splits() if n not in have)

    def register(self) -> int:
        """Insert any missing chapter/TOC rows; bump NumShortcovers per new chapter.

        Returns the number of new chapter (9) rows inserted. TOC backfills do not
        count as new chapters and do not change NumShortcovers.
        """
        fragments = self.epub.splits()
        new_chapters = self.missing_chapter_splits()
        for split in new_chapters:
            ChapterRow.for_split(
                self.conn, self.book.content_id, self.epub, split, fragments[split]
            ).insert(self.conn)
        for split in self.missing_toc_splits():
            TocChapterRow.for_split(
                self.conn, self.book.content_id, self.epub, split, fragments[split]
            ).insert(self.conn)
        if new_chapters:
            self.book.set_num_shortcovers(
                self.conn, self.book.num_shortcovers + len(new_chapters)
            )
        self.conn.commit()
        return len(new_chapters)


def prev_max_split(conn: sqlite3.Connection, book_content_id: str) -> int:
    """Highest ``split_NNN`` among the book's existing chapter rows, or -1."""
    splits = existing_chapter_splits(conn, book_content_id)
    return max(splits) if splits else -1


def restore_mtime(file_path: str, original_mtime: float) -> None:
    """Restore a file's access/modification time (helps avoid a device re-import)."""
    os.utime(file_path, (original_mtime, original_mtime))


def _write_snapshot(source_epub_path: str, snapshot: Snapshot) -> str:
    """Write the JSON snapshot next to the source EPUB."""
    base = os.path.splitext(os.path.basename(source_epub_path))[0]
    path = os.path.join(
        os.path.dirname(os.path.abspath(source_epub_path)), f"{base}.kobo_progress.json"
    )
    with open(path, "w") as f:
        json.dump(snapshot.to_json(), f, indent=2)
    return path


def _backup_db(db_path: str) -> str:
    stamp = datetime.now().strftime("%Y%m%d%H%M%S")
    backup_path = f"{db_path}.bak{stamp}"
    shutil.copyfile(db_path, backup_path)
    return backup_path


def preserve_progress(
    onboard_root: str,
    book_rel_path: str,
    new_epub_path: str,
    onboard_prefix: str = paths.DEFAULT_ONBOARD_PREFIX,
    backup: bool = True,
) -> PreserveResult:
    """Install ``new_epub_path`` over the on-device book, preserving progress.

    Steps (all while the KOBO is mounted): snapshot the current progress, back up
    the DB (unless ``backup`` is False), overwrite the on-device file, register
    any appended chapters, sync the book row's pointer + ``___FileSize``, and
    restore the file's mtime so the device is less likely to re-import.

    The JSON snapshot sidecar is written next to ``new_epub_path`` (the source).
    """
    book_rel_path = paths.relativize_dest(onboard_root, book_rel_path)
    db_path = os.path.join(onboard_root, ".kobo", "KoboReader.sqlite")
    dest_path = os.path.join(onboard_root, book_rel_path)
    content_id = paths.derive_content_id(book_rel_path, onboard_prefix)

    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    try:
        # Fail before touching the file if the book isn't known to the device.
        book = BookRow.from_database(conn, content_id)
        if book is None:
            raise LookupError(f"No book row for ContentID: {content_id}")
        snapshot = Snapshot.capture(conn, book)
        previous_max = prev_max_split(conn, content_id)

        snapshot_path = _write_snapshot(new_epub_path, snapshot)
        backup_path = _backup_db(db_path) if backup else None

        original_mtime = os.path.getmtime(dest_path)
        shutil.copyfile(new_epub_path, dest_path)

        epub = Epub(dest_path)
        chapters_registered = ChapterRegistrar(conn, book, epub).register()
        pointer = compute_resume_pointer(snapshot, epub, previous_max)
        pointer_changed = not pointer.is_empty()  # any set field -> we moved it
        book.apply_pointer(
            conn,
            pointer,
            os.path.getsize(dest_path),
            update_pointer=pointer_changed,
        )
        conn.commit()
        restore_mtime(dest_path, original_mtime)
    finally:
        conn.close()

    _log.info(
        "%s: registered %d new chapter(s); pointer %s; filesize synced.",
        book_rel_path,
        chapters_registered,
        "moved to " + pointer.chapter_id_bookmarked if pointer_changed else "kept",
    )
    return PreserveResult(
        snapshot_path=snapshot_path,
        backup_path=backup_path,
        chapters_registered=chapters_registered,
        pointer_changed=pointer_changed,
    )
