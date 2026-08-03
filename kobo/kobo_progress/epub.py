"""Read-only view over an EPUB's chapter files.

Chapters are Calibre-style ``cleaned-..._split_NNN.html`` files; ordering is by the
numeric ``NNN`` suffix. All EPUB parsing the tool needs lives here.
"""

from __future__ import annotations

import os
import re
import zipfile

_SPLIT_RE = re.compile(r"_split_(\d+)\.x?html")
_TAG_RE = re.compile(r"<[^>]+>")
_H1_RE = re.compile(r"<h1[^>]*>(.*?)</h1>", re.I | re.S)


def split_number(text: str) -> int | None:
    """Return the ``split_NNN`` number embedded in ``text``, or None."""
    match = _SPLIT_RE.search(text)
    return int(match.group(1)) if match else None


class Epub:
    """A book EPUB, addressed by its chapter fragments (basenames)."""

    def __init__(self, path: str) -> None:
        self.path = path

    def splits(self) -> dict[int, str]:
        """Map split-number -> chapter fragment (basename) for the EPUB's chapters."""
        result: dict[int, str] = {}
        with zipfile.ZipFile(self.path) as zf:
            for name in zf.namelist():
                n = split_number(name)
                if n is not None:
                    result[n] = os.path.basename(name)
        return result

    def max_split(self) -> int:
        """Return the highest ``split_NNN`` number, or -1 if there are none."""
        splits = self.splits()
        return max(splits) if splits else -1

    def fragment_for_split(self, split_number_: int) -> str:
        """Return the chapter fragment (basename) for a given split number."""
        frag = self.splits().get(split_number_)
        if frag is None:
            raise LookupError(f"split_{split_number_:03d} not found in {self.path}")
        return frag

    def read_fragment(self, fragment: str) -> str:
        """Return the decoded HTML of the given chapter fragment."""
        with zipfile.ZipFile(self.path) as zf:
            for name in zf.namelist():
                if os.path.basename(name) == fragment:
                    return zf.read(name).decode("utf-8", "ignore")
        raise LookupError(f"{fragment} not found in {self.path}")

    def word_count(self, fragment: str) -> int:
        """Return the number of words in the given chapter fragment."""
        text = _TAG_RE.sub(" ", self.read_fragment(fragment))
        return len(text.split())

    def title(self, fragment: str) -> str:
        """Return the chapter's human-readable title (its ``<h1>``), else the fragment.

        The reader lists this text in the table of contents.
        """
        m = _H1_RE.search(self.read_fragment(fragment))
        if m is None:
            return fragment
        return re.sub(r"\s+", " ", _TAG_RE.sub("", m.group(1))).strip()

    def chapter_weight(self, fragment: str) -> float:
        """Approximate a chapter's fractional weight (share of total words * 100)."""
        counts = {frag: self.word_count(frag) for frag in self.splits().values()}
        total = sum(counts.values()) or 1
        return counts[fragment] / total * 100
