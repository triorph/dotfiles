"""Path and ContentID helpers for KOBO sideloading.

The KOBO stores a book's ``ContentID`` as ``file:///mnt/onboard/<rel path>`` while
chapter/TOC rows reference the same file *without* the ``file://`` scheme and with a
``!!<fragment>`` separator. These helpers centralise those conventions.
"""

from __future__ import annotations

import os

DEFAULT_ONBOARD_PREFIX = "file:///mnt/onboard/"

_SCHEME = "file://"
_CHAPTER_SEP = "!!"


def derive_content_id(
    file_path: str, onboard_prefix: str = DEFAULT_ONBOARD_PREFIX
) -> str:
    """Build the KOBO ``ContentID`` for a sideloaded file.

    ``file_path`` is the path of the file *relative to the onboard root* (e.g.
    ``"onedayokay/Book.kepub.epub"``); the returned value is the full
    ``file:///mnt/onboard/...`` identifier the KOBO stores.
    """
    return onboard_prefix + file_path


def mnt_path(content_id: str) -> str:
    """Book ContentID without the ``file://`` scheme (chapter rows use this form)."""
    return content_id[len(_SCHEME) :] if content_id.startswith(_SCHEME) else content_id


def chapter_content_id(content_id: str, fragment: str) -> str:
    """The ``<mnt path>!!<fragment>`` id used by chapter/TOC rows."""
    return mnt_path(content_id) + _CHAPTER_SEP + fragment


def relativize_dest(onboard_root: str, dest: str) -> str:
    """Return ``dest`` relative to ``onboard_root`` if it is an absolute path under it."""
    if not os.path.isabs(dest):
        return dest
    return os.path.relpath(dest, onboard_root)
