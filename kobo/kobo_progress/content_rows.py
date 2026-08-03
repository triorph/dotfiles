"""Typed views over rows of the KoboReader ``content`` table.

The ``content`` table mixes three kinds of row, distinguished by ``ContentType``:

- :class:`BookRow` (``6``): the book itself; holds the reading pointer and the
  chapter count (``NumShortcovers``).
- :class:`ChapterRow` (``9``): one chapter's content (an xhtml file).
- :class:`TocChapterRow` (``899``): one table-of-contents/navigation entry.

Reads use ``SELECT *`` and pull out only the fields we care about. Writes are
plain, explicit SQL. New chapter/TOC rows *copy an existing row of the same kind
as a template* (to inherit device-specific NOT NULL columns such as ``___UserID``)
and then set the handful of columns we care about explicitly on top.
"""

from __future__ import annotations

import enum
import sqlite3
from dataclasses import dataclass

from . import paths
from .epub import Epub, split_number


class ContentType(str, enum.Enum):
    """``content.ContentType`` values (only these three exist in the DB)."""

    BOOK = "6"  # the book row; holds the reading pointer + NumShortcovers
    CHAPTER = "9"  # a chapter's content (one xhtml file)
    TOC = "899"  # a navigation/table-of-contents entry (per chapter)


# --------------------------------- Pointer ---------------------------------


@dataclass
class Pointer:
    """A book's reading position.

    A field left as ``None`` means "leave that column unchanged" when applied.
    """

    chapter_id_bookmarked: str | None = None
    read_status: int | None = None
    percent_read: int | None = None
    paragraph_bookmarked: int | None = None
    bookmark_word_offset: int | None = None
    current_chapter_progress: float | None = None
    adobe_location: str | None = None

    @classmethod
    def from_row(cls, row: sqlite3.Row) -> "Pointer":
        return cls(
            chapter_id_bookmarked=row["ChapterIDBookmarked"],
            read_status=row["ReadStatus"],
            percent_read=row["___PercentRead"],
            paragraph_bookmarked=row["ParagraphBookmarked"],
            bookmark_word_offset=row["BookmarkWordOffset"],
            current_chapter_progress=row["CurrentChapterProgress"],
            adobe_location=row["adobe_location"],
        )

    def as_snapshot_dict(self) -> dict:
        """SQLite-column-keyed dict of every field (for the audit snapshot)."""
        return {
            "ChapterIDBookmarked": self.chapter_id_bookmarked,
            "ReadStatus": self.read_status,
            "___PercentRead": self.percent_read,
            "ParagraphBookmarked": self.paragraph_bookmarked,
            "BookmarkWordOffset": self.bookmark_word_offset,
            "CurrentChapterProgress": self.current_chapter_progress,
            "adobe_location": self.adobe_location,
        }

    def is_empty(self) -> bool:
        """True if nothing would be changed (all fields are None)."""
        return all(v is None for v in self.as_snapshot_dict().values())


# --------------------------------- BookRow ---------------------------------


@dataclass
class BookRow:
    """The ``ContentType='6'`` book row: reading pointer + chapter count.

    We only keep the fields the tool reads; our updates touch specific columns
    and leave every other column of the row exactly as it was.
    """

    content_id: str
    read_status: int | None
    percent_read: int | None
    num_shortcovers: int
    file_size: int | None
    pointer: Pointer

    @classmethod
    def from_database(
        cls, conn: sqlite3.Connection, content_id: str
    ) -> "BookRow | None":
        cur = conn.execute(
            "SELECT * FROM content WHERE ContentID = ? AND ContentType = ?",
            (content_id, ContentType.BOOK.value),
        )
        row = cur.fetchone()
        if row is None:
            return None
        return cls(
            content_id=content_id,
            read_status=row["ReadStatus"],
            percent_read=row["___PercentRead"],
            num_shortcovers=row["NumShortcovers"] or 0,
            file_size=row["___FileSize"],
            pointer=Pointer.from_row(row),
        )

    def apply_pointer(
        self,
        conn: sqlite3.Connection,
        pointer: Pointer,
        file_size: int,
        update_pointer: bool = True,
    ) -> None:
        """Sync ``___FileSize``, and optionally the reading pointer.

        ``___FileSize`` is always written. When ``update_pointer`` is True the
        pointer columns are written too (as-is, including any None). When it is
        False only ``___FileSize`` changes and the reading position is left exactly
        as it was — used for mid-book/unread books where we must not move the place.
        """
        if update_pointer:
            conn.execute(
                """
                UPDATE content SET
                    ChapterIDBookmarked = ?,
                    ReadStatus = ?,
                    ___PercentRead = ?,
                    ParagraphBookmarked = ?,
                    BookmarkWordOffset = ?,
                    CurrentChapterProgress = ?,
                    adobe_location = ?,
                    ___FileSize = ?
                WHERE ContentID = ? AND ContentType = ?
                """,
                [
                    pointer.chapter_id_bookmarked,
                    pointer.read_status,
                    pointer.percent_read,
                    pointer.paragraph_bookmarked,
                    pointer.bookmark_word_offset,
                    pointer.current_chapter_progress,
                    pointer.adobe_location,
                    file_size,
                    self.content_id,
                    ContentType.BOOK.value,
                ],
            )
        else:
            conn.execute(
                "UPDATE content SET ___FileSize = ? "
                "WHERE ContentID = ? AND ContentType = ?",
                (file_size, self.content_id, ContentType.BOOK.value),
            )

    def set_num_shortcovers(self, conn: sqlite3.Connection, count: int) -> None:
        conn.execute(
            "UPDATE content SET NumShortcovers = ? "
            "WHERE ContentID = ? AND ContentType = ?",
            (count, self.content_id, ContentType.BOOK.value),
        )


# ----------------------- chapter / TOC (inserted) rows -----------------------


def _template_row(
    conn: sqlite3.Connection, book_content_id: str, content_type: ContentType
) -> dict:
    """Return the last existing row of ``content_type`` (as a dict) to copy from.

    New rows inherit every column of this template so device-specific NOT NULL
    columns (e.g. ``___UserID``) are satisfied without us enumerating them.
    """
    cur = conn.execute(
        "SELECT * FROM content WHERE BookID = ? AND ContentType = ? "
        "ORDER BY VolumeIndex DESC LIMIT 1",
        (book_content_id, content_type.value),
    )
    row = cur.fetchone()
    if row is None:
        raise LookupError(
            f"No existing {content_type.name} rows to template for: {book_content_id}"
        )
    return dict(row)


def _insert_row(conn: sqlite3.Connection, row: dict) -> None:
    """Insert a full column->value mapping (column list built from the template)."""
    columns = list(row)
    column_sql = ", ".join(f'"{c}"' for c in columns)
    placeholders = ", ".join("?" for _ in columns)
    conn.execute(
        f"INSERT INTO content ({column_sql}) VALUES ({placeholders})",
        [row[c] for c in columns],
    )


def existing_chapter_splits(
    conn: sqlite3.Connection, book_content_id: str
) -> set[int]:
    """Return the split numbers that already have a chapter row."""
    cur = conn.execute(
        "SELECT ContentID FROM content WHERE BookID = ? AND ContentType = ?",
        (book_content_id, ContentType.CHAPTER.value),
    )
    return {n for (cid,) in cur.fetchall() if (n := split_number(cid)) is not None}


def chapter_progress(
    conn: sqlite3.Connection, book_content_id: str
) -> dict[int, int]:
    """Map split-number -> ``___PercentRead`` for the book's chapter rows."""
    cur = conn.execute(
        "SELECT ContentID, ___PercentRead FROM content "
        "WHERE BookID = ? AND ContentType = ?",
        (book_content_id, ContentType.CHAPTER.value),
    )
    progress: dict[int, int] = {}
    for content_id, percent in cur.fetchall():
        n = split_number(content_id)
        if n is not None:
            progress[n] = percent
    return progress


class ChapterRow:
    """A ``ContentType='9'`` chapter content row to be inserted."""

    def __init__(self, row: dict) -> None:
        self.row = row

    @classmethod
    def for_split(
        cls,
        conn: sqlite3.Connection,
        book_content_id: str,
        epub: Epub,
        split: int,
        fragment: str,
    ) -> "ChapterRow":
        """Copy a chapter template, then set the columns we care about explicitly."""
        row = _template_row(conn, book_content_id, ContentType.CHAPTER)
        row["ContentID"] = paths.chapter_content_id(book_content_id, fragment)
        row["Title"] = fragment
        row["VolumeIndex"] = split + 1
        row["ReadStatus"] = 0
        row["___PercentRead"] = 0
        row["___NumPages"] = -1
        row["___FileOffset"] = 99
        row["___FileSize"] = epub.chapter_weight(fragment)
        row["WordCount"] = epub.word_count(fragment)
        return cls(row)

    def insert(self, conn: sqlite3.Connection) -> None:
        _insert_row(conn, self.row)


class TocChapterRow:
    """A ``ContentType='899'`` table-of-contents/navigation row to be inserted.

    Without this row a chapter is reachable by paging but never listed in the
    reader's table of contents.
    """

    def __init__(self, row: dict) -> None:
        self.row = row

    @classmethod
    def for_split(
        cls,
        conn: sqlite3.Connection,
        book_content_id: str,
        epub: Epub,
        split: int,
        fragment: str,
    ) -> "TocChapterRow":
        """Copy a TOC template, then set the columns we care about explicitly."""
        chapter_cid = paths.chapter_content_id(book_content_id, fragment)
        row = _template_row(conn, book_content_id, ContentType.TOC)
        row["ContentID"] = chapter_cid + "-1"
        row["ChapterIDBookmarked"] = chapter_cid
        row["Title"] = epub.title(fragment)
        row["VolumeIndex"] = split
        return cls(row)

    def insert(self, conn: sqlite3.Connection) -> None:
        _insert_row(conn, self.row)
