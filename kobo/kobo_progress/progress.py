"""Pure reading-position logic: snapshotting and resume routing (no IO)."""

from __future__ import annotations

import sqlite3
from dataclasses import dataclass, field

from .content_rows import BookRow, Pointer, chapter_progress
from .epub import Epub

FINISHED_READ_STATUS = 2


@dataclass
class Snapshot:
    """A book's preserved reading position: a Pointer + per-chapter progress."""

    pointer: Pointer
    chapter_progress: dict[int, int] = field(default_factory=dict)

    @property
    def is_finished(self) -> bool:
        """True if the book is finished. Uses the device ReadStatus (2) only."""
        return self.pointer.read_status == FINISHED_READ_STATUS

    @classmethod
    def capture(cls, conn: sqlite3.Connection, book: BookRow) -> "Snapshot":
        """Capture the pointer and per-chapter progress vector for a book."""
        return cls(
            pointer=book.pointer,
            chapter_progress=chapter_progress(conn, book.content_id),
        )

    def to_json(self) -> dict:
        """A JSON-serialisable form of the snapshot (keyed by SQLite column names)."""
        data = self.pointer.as_snapshot_dict()
        data["chapter_progress"] = self.chapter_progress
        return data


def compute_resume_pointer(
    snapshot: Snapshot, epub: Epub, prev_max_split: int
) -> Pointer:
    """Return the Pointer to write after an update.

    Returns an EMPTY Pointer (all fields None -> leave the book row untouched)
    unless the book was *finished* and new chapters were added. This avoids
    clobbering a live intra-chapter position for mid-book/unread books.

    - Not finished (mid-book or unread): empty (no changes).
    - Finished with no new chapters: empty (no changes).
    - Finished with new chapters: jump to the first new chapter, un-finish.
    """
    if not snapshot.is_finished:
        return Pointer()
    new_max_split = epub.max_split()
    if new_max_split <= prev_max_split:
        return Pointer()  # finished, nothing new -> leave unchanged
    first_new = prev_max_split + 1
    return Pointer(
        chapter_id_bookmarked=epub.fragment_for_split(first_new) + "#",
        read_status=1,
        # Approximate progress: position of the first new chapter within the new
        # total, computed in floating point before rounding.
        percent_read=round(float(first_new) / float(new_max_split) * 100),
        paragraph_bookmarked=0,
        bookmark_word_offset=0,
        current_chapter_progress=0.0,
    )
