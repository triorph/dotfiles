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
import logging
import os
import re
import shutil
import sqlite3
import zipfile
from datetime import datetime

_log = logging.getLogger("kobo_progress")

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


def derive_content_id(
    file_path: str, onboard_prefix: str = DEFAULT_ONBOARD_PREFIX
) -> str:
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
        numbers = [
            n for name in zf.namelist() if (n := _split_number(name)) is not None
        ]
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


def compute_resume_pointer(
    snapshot: dict, new_epub_path: str, prev_max_split: int
) -> dict:
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
    # Approximate progress: position of the first new chapter within the new
    # total, computed in floating point before rounding.
    out["___PercentRead"] = round(float(first_new) / float(new_max_split) * 100)
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


def count_words(epub_path: str, fragment: str) -> int:
    """Return the number of words in the given chapter fragment of the EPUB."""
    with zipfile.ZipFile(epub_path) as zf:
        for name in zf.namelist():
            if os.path.basename(name) == fragment:
                html = zf.read(name).decode("utf-8", "ignore")
                break
        else:
            raise LookupError(f"{fragment} not found in {epub_path}")
    text = re.sub(r"<[^>]+>", " ", html)
    return len(text.split())


def _mnt_path(content_id: str) -> str:
    """Book ContentID without the file:// scheme (chapter rows use this form)."""
    return (
        content_id[len("file://") :] if content_id.startswith("file://") else content_id
    )


def _chapter_content_id(content_id: str, fragment: str) -> str:
    return _mnt_path(content_id) + "!!" + fragment


def _epub_splits(epub_path: str) -> dict[int, str]:
    """Map split-number -> chapter fragment (basename) for the EPUB's chapters."""
    result: dict[int, str] = {}
    with zipfile.ZipFile(epub_path) as zf:
        for name in zf.namelist():
            n = _split_number(name)
            if n is not None:
                result[n] = os.path.basename(name)
    return result


def missing_chapter_splits(
    conn: sqlite3.Connection, content_id: str, new_epub_path: str
) -> list[int]:
    """Return split numbers present in the EPUB but absent from the DB chapter rows."""
    have = set()
    cur = conn.execute(
        "SELECT ContentID FROM content WHERE BookID = ? AND ContentType = '9'",
        (content_id,),
    )
    for (cid,) in cur.fetchall():
        n = _split_number(cid)
        if n is not None:
            have.add(n)
    return sorted(n for n in _epub_splits(new_epub_path) if n not in have)


def register_new_chapters(
    conn: sqlite3.Connection, content_id: str, new_epub_path: str
) -> int:
    """Insert ContentType='9' rows for appended chapters and bump NumShortcovers.

    Returns the number of chapters registered.
    """
    book = find_book_row(conn, content_id)
    if book is None:
        raise LookupError(f"No book row for ContentID: {content_id}")
    missing = missing_chapter_splits(conn, content_id, new_epub_path)
    if not missing:
        return 0
    template = _template_chapter_row(conn, content_id)
    fragments = _epub_splits(new_epub_path)
    for split in missing:
        frag = fragments[split]
        row = dict(template)
        # Per-chapter fields; everything else is inherited from the template so
        # NOT NULL / device-specific columns (e.g. ___UserID) are satisfied.
        row["ContentID"] = _chapter_content_id(content_id, frag)
        row["Title"] = frag
        row["VolumeIndex"] = split + 1
        row["ReadStatus"] = 0
        row["___PercentRead"] = 0
        row["___NumPages"] = -1
        row["___FileOffset"] = 99
        row["___FileSize"] = _chapter_weight(new_epub_path, frag)
        row["WordCount"] = count_words(new_epub_path, frag)
        cols = list(row)
        col_list = ", ".join('"' + c + '"' for c in cols)
        placeholders = ", ".join("?" for _ in cols)
        conn.execute(
            f"INSERT INTO content ({col_list}) VALUES ({placeholders})",
            [row[c] for c in cols],
        )
    new_count = (book["NumShortcovers"] or 0) + len(missing)
    conn.execute(
        "UPDATE content SET NumShortcovers = ? WHERE ContentID = ? AND ContentType = '6'",
        (new_count, content_id),
    )
    conn.commit()
    return len(missing)


def _template_chapter_row(conn: sqlite3.Connection, content_id: str) -> dict:
    """Return an existing chapter row (as a dict) to use as an insert template."""
    cur = conn.execute(
        "SELECT * FROM content WHERE BookID = ? AND ContentType = '9' "
        "ORDER BY VolumeIndex DESC LIMIT 1",
        (content_id,),
    )
    row = cur.fetchone()
    if row is None:
        raise LookupError(f"No existing chapter rows to template for: {content_id}")
    return dict(row)


def _chapter_weight(epub_path: str, fragment: str) -> float:
    """Approximate a chapter's fractional weight (share of total words * 100)."""
    splits = _epub_splits(epub_path)
    counts = {frag: count_words(epub_path, frag) for frag in splits.values()}
    total = sum(counts.values()) or 1
    return counts[fragment] / total * 100


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

    The JSON snapshot sidecar is written next to ``new_epub_path`` (the source).
    Returns a result dict: ``snapshot_path``, ``backup_path``,
    ``chapters_registered``, ``pointer_changed``, ``filesize_synced``.
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

        snapshot_path = _write_snapshot(new_epub_path, snapshot)
        backup_path = _backup_db(db_path) if backup else None

        original_mtime = os.path.getmtime(dest_path)
        shutil.copyfile(new_epub_path, dest_path)

        chapters_registered = register_new_chapters(conn, content_id, dest_path)
        pointer = compute_resume_pointer(snapshot, dest_path, prev_max_split)
        pointer_changed = pointer.get("ChapterIDBookmarked") != snapshot.get(
            "ChapterIDBookmarked"
        )
        apply_update(conn, content_id, pointer, os.path.getsize(dest_path))
        restore_mtime(dest_path, original_mtime)
    finally:
        conn.close()

    _log.info(
        "%s: registered %d new chapter(s); pointer %s; filesize synced.",
        book_rel_path,
        chapters_registered,
        "moved to " + pointer["ChapterIDBookmarked"] if pointer_changed else "kept",
    )
    return {
        "snapshot_path": snapshot_path,
        "backup_path": backup_path,
        "chapters_registered": chapters_registered,
        "pointer_changed": pointer_changed,
        "filesize_synced": True,
    }


def _relativize_dest(onboard_root: str, dest: str) -> str:
    """Return ``dest`` relative to ``onboard_root`` if it is an absolute path under it."""
    if not os.path.isabs(dest):
        return dest
    return os.path.relpath(dest, onboard_root)


def _write_snapshot(source_epub_path: str, snapshot: dict) -> str:
    """Write the JSON snapshot next to the source EPUB."""
    base = os.path.splitext(os.path.basename(source_epub_path))[0]
    path = os.path.join(
        os.path.dirname(os.path.abspath(source_epub_path)), f"{base}.kobo_progress.json"
    )
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
    parser.add_argument(
        "onboard_root", help="Path to the mounted KOBO root (contains .kobo/)."
    )
    parser.add_argument(
        "src", help="Local path to the updated EPUB to install (source)."
    )
    parser.add_argument(
        "dest", help="Book path relative to the onboard root (destination)."
    )
    parser.add_argument(
        "--onboard-prefix",
        default=DEFAULT_ONBOARD_PREFIX,
        help="ContentID prefix the device uses (default: %(default)s).",
    )
    parser.add_argument(
        "--no-backup",
        action="store_true",
        help="Skip the per-file DB backup (for batch runs that back up once up front).",
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="Enable debug logging.",
    )
    args = parser.parse_args(argv)

    logging.basicConfig(
        level=logging.DEBUG if args.verbose else logging.INFO,
        format="%(levelname)s %(message)s",
    )

    result = preserve_progress(
        args.onboard_root,
        args.dest,
        args.src,
        onboard_prefix=args.onboard_prefix,
        backup=not args.no_backup,
    )
    _log.info("Snapshot written to: %s", result["snapshot_path"])
    if result["backup_path"]:
        _log.info("DB backed up to: %s", result["backup_path"])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
