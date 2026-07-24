#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///
"""KOBO reading-progress preserver.

Given an updated (append-only) EPUB and a mounted KOBO ``KoboReader.sqlite``,
update the book row so reading progress is preserved across the update.

Run directly with uv:  ``./kobo_progress/kobo_progress.py <root> <src> <dest>``
"""

from __future__ import annotations

import json
import os
import re
import shutil
import sqlite3
import zipfile
from datetime import datetime

DEFAULT_ONBOARD_PREFIX = "file:///mnt/onboard/"


_SPLIT_RE = re.compile(r"_split_(\d+)\.x?html")

# Pointer fields copied verbatim from a snapshot in the "keep position" case.
_POINTER_FIELDS = (
    "ChapterIDBookmarked",
    "ReadStatus",
    "___PercentRead",
    "ParagraphBookmarked",
    "BookmarkWordOffset",
    "CurrentChapterProgress",
    "adobe_location",
)


def derive_content_id(file_path: str, onboard_prefix: str = DEFAULT_ONBOARD_PREFIX) -> str:
    """Build the KOBO ``ContentID`` for a sideloaded file.

    ``file_path`` is the path of the file *relative to the onboard root* (e.g.
    ``"onedayokay/Book.kepub.epub"``); the returned value is the full
    ``file:///mnt/onboard/...`` identifier the KOBO stores.
    """
    return onboard_prefix + file_path


def find_book_row(conn: sqlite3.Connection, content_id: str) -> dict | None:
    """Return the ``ContentType='6'`` book row for ``content_id`` as a dict, or None."""
    cur = conn.execute(
        "SELECT * FROM content WHERE ContentID = ? AND ContentType = '6'",
        (content_id,),
    )
    row = cur.fetchone()
    return dict(row) if row is not None else None


def _split_number(text: str) -> int | None:
    match = _SPLIT_RE.search(text)
    return int(match.group(1)) if match else None


def snapshot_progress(conn: sqlite3.Connection, content_id: str) -> dict:
    """Capture pointer fields and the per-chapter progress vector for a book."""
    row = find_book_row(conn, content_id)
    if row is None:
        raise LookupError(f"No book row for ContentID: {content_id}")
    snapshot = {field: row[field] for field in _POINTER_FIELDS}
    chapter_progress: dict[int, int] = {}
    cur = conn.execute(
        "SELECT ContentID, ___PercentRead FROM content "
        "WHERE BookID = ? AND ContentType = '9'",
        (content_id,),
    )
    for chapter_id, percent in cur.fetchall():
        n = _split_number(chapter_id)
        if n is not None:
            chapter_progress[n] = percent
    snapshot["chapter_progress"] = chapter_progress
    return snapshot


def max_split_number(epub_path: str) -> int:
    """Return the highest ``split_NNN`` number among the EPUB's chapter files."""
    with zipfile.ZipFile(epub_path) as zf:
        numbers = [n for name in zf.namelist() if (n := _split_number(name)) is not None]
    return max(numbers) if numbers else -1


def prev_max_split_from_db(conn: sqlite3.Connection, content_id: str) -> int:
    """Return the highest ``split_NNN`` number among the book's chapter rows."""
    cur = conn.execute(
        "SELECT ContentID FROM content WHERE BookID = ? AND ContentType = '9'",
        (content_id,),
    )
    numbers = [n for (cid,) in cur.fetchall() if (n := _split_number(cid)) is not None]
    return max(numbers) if numbers else -1


def is_finished(snapshot: dict) -> bool:
    """True if the book is finished. Uses the device ReadStatus (2) only."""
    return snapshot.get("ReadStatus") == 2


def _fragment_for_split(new_epub_path: str, split_number: int) -> str:
    """Return the bare chapter fragment (e.g. ``..._split_104.html``) from the EPUB."""
    with zipfile.ZipFile(new_epub_path) as zf:
        for name in zf.namelist():
            if _split_number(name) == split_number:
                return os.path.basename(name)
    raise LookupError(f"split_{split_number:03d} not found in {new_epub_path}")


def compute_resume_pointer(snapshot: dict, new_epub_path: str, prev_max_split: int) -> dict:
    """Return the pointer fields to write after an update (Case A vs Case B).

    - Not finished (mid-book or unread): keep the existing pointer verbatim.
    - Finished with new chapters: jump to the first new chapter, un-finish.
    - Finished with no new chapters: no-op (leave everything as-is).
    """
    out = {field: snapshot.get(field) for field in _POINTER_FIELDS}
    if not is_finished(snapshot):
        return out
    new_max_split = max_split_number(new_epub_path)
    if new_max_split <= prev_max_split:
        return out  # finished, nothing new -> leave unchanged
    first_new = prev_max_split + 1
    out["ChapterIDBookmarked"] = _fragment_for_split(new_epub_path, first_new) + "#"
    out["ReadStatus"] = 1
    out["___PercentRead"] = 0
    out["ParagraphBookmarked"] = 0
    out["BookmarkWordOffset"] = 0
    out["CurrentChapterProgress"] = 0.0
    return out


def apply_update(
    conn: sqlite3.Connection,
    content_id: str,
    pointer_fields: dict,
    new_file_size: int,
) -> None:
    """Write pointer fields and ``___FileSize`` back to the book row."""
    if find_book_row(conn, content_id) is None:
        raise LookupError(f"No book row for ContentID: {content_id}")
    updates = {k: v for k, v in pointer_fields.items() if v is not None}
    updates["___FileSize"] = new_file_size
    assignments = ", ".join(f'"{col}" = ?' for col in updates)
    params = list(updates.values()) + [content_id]
    conn.execute(
        f"UPDATE content SET {assignments} WHERE ContentID = ? AND ContentType = '6'",
        params,
    )
    conn.commit()


def restore_mtime(file_path: str, original_mtime: float) -> None:
    """Set ``file_path``'s modification time back to ``original_mtime``."""
    os.utime(file_path, (original_mtime, original_mtime))


def preserve_progress(
    onboard_root: str,
    book_rel_path: str,
    new_epub_path: str,
    onboard_prefix: str = DEFAULT_ONBOARD_PREFIX,
    backup: bool = True,
) -> dict:
    """Install ``new_epub_path`` over the on-device book, preserving progress.

    Steps (all while the KOBO is mounted): snapshot the current progress, back up
    the DB (unless ``backup`` is False), overwrite the on-device file, sync the
    book row's pointer + ``___FileSize``, and restore the file's mtime so the
    device is less likely to re-import.

    Returns a result dict including the snapshot sidecar path.
    """
    book_rel_path = _relativize_dest(onboard_root, book_rel_path)
    kobo_dir = os.path.join(onboard_root, ".kobo")
    db_path = os.path.join(kobo_dir, "KoboReader.sqlite")
    dest_path = os.path.join(onboard_root, book_rel_path)
    content_id = derive_content_id(book_rel_path, onboard_prefix)

    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    try:
        # Fail before touching the file if the book isn't known to the device.
        snapshot = snapshot_progress(conn, content_id)
        prev_max_split = prev_max_split_from_db(conn, content_id)

        snapshot_path = _write_snapshot(kobo_dir, book_rel_path, snapshot)
        backup_path = _backup_db(db_path) if backup else None

        original_mtime = os.path.getmtime(dest_path)
        shutil.copyfile(new_epub_path, dest_path)

        pointer = compute_resume_pointer(snapshot, dest_path, prev_max_split)
        apply_update(conn, content_id, pointer, os.path.getsize(dest_path))
        restore_mtime(dest_path, original_mtime)
    finally:
        conn.close()

    return {"snapshot_path": snapshot_path, "backup_path": backup_path}


def _relativize_dest(onboard_root: str, dest: str) -> str:
    """Return ``dest`` relative to ``onboard_root`` if it is an absolute path under it."""
    if not os.path.isabs(dest):
        return dest
    return os.path.relpath(dest, onboard_root)


def _snapshot_slug(book_rel_path: str) -> str:
    return re.sub(r"[^A-Za-z0-9]+", "_", book_rel_path).strip("_")


def _write_snapshot(kobo_dir: str, book_rel_path: str, snapshot: dict) -> str:
    path = os.path.join(kobo_dir, f"kobo_progress_{_snapshot_slug(book_rel_path)}.json")
    with open(path, "w") as f:
        json.dump(snapshot, f, indent=2)
    return path


def _backup_db(db_path: str) -> str:
    stamp = datetime.now().strftime("%Y%m%d%H%M%S")
    backup_path = f"{db_path}.bak{stamp}"
    shutil.copyfile(db_path, backup_path)
    return backup_path


def main(argv: list[str] | None = None) -> int:
    import argparse

    parser = argparse.ArgumentParser(
        description="Install an updated EPUB onto a mounted KOBO while preserving "
        "reading progress.",
    )
    parser.add_argument("onboard_root", help="Path to the mounted KOBO root (contains .kobo/).")
    parser.add_argument("src", help="Local path to the updated EPUB to install (source).")
    parser.add_argument("dest", help="Book path relative to the onboard root (destination).")
    parser.add_argument(
        "--onboard-prefix", default=DEFAULT_ONBOARD_PREFIX,
        help="ContentID prefix the device uses (default: %(default)s).",
    )
    parser.add_argument(
        "--no-backup", action="store_true",
        help="Skip the per-file DB backup (for batch runs that back up once up front).",
    )
    args = parser.parse_args(argv)

    result = preserve_progress(
        args.onboard_root,
        args.dest,
        args.src,
        onboard_prefix=args.onboard_prefix,
        backup=not args.no_backup,
    )
    print(f"Snapshot written to: {result['snapshot_path']}")
    if result["backup_path"]:
        print(f"DB backed up to:     {result['backup_path']}")
    print("Progress preserved.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
