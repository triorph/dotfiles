"""KOBO reading-progress preserver.

Public API re-exported for convenience::

    from kobo_progress import preserve_progress, BookRow, Epub
"""

from __future__ import annotations

from .content_rows import (
    BookRow,
    ChapterRow,
    ContentType,
    Pointer,
    TocChapterRow,
    chapter_progress,
    existing_chapter_splits,
    existing_toc_splits,
)
from .epub import Epub, split_number
from .orchestrator import (
    ChapterRegistrar,
    PreserveResult,
    prev_max_split,
    preserve_progress,
    restore_mtime,
)
from .paths import (
    DEFAULT_ONBOARD_PREFIX,
    chapter_content_id,
    derive_content_id,
    mnt_path,
    relativize_dest,
)
from .progress import Snapshot, compute_resume_pointer

__all__ = [
    "BookRow",
    "ChapterRow",
    "ChapterRegistrar",
    "ContentType",
    "DEFAULT_ONBOARD_PREFIX",
    "Epub",
    "Pointer",
    "PreserveResult",
    "Snapshot",
    "TocChapterRow",
    "chapter_content_id",
    "chapter_progress",
    "compute_resume_pointer",
    "derive_content_id",
    "existing_chapter_splits",
    "existing_toc_splits",
    "mnt_path",
    "prev_max_split",
    "preserve_progress",
    "relativize_dest",
    "restore_mtime",
    "split_number",
]
