#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///
"""Command-line entry point.

Run as a module:      ``python3 -m kobo_progress <root> <src> <dest>``
Or directly via uv:   ``./kobo_progress/__main__.py <root> <src> <dest>``
"""

from __future__ import annotations

import argparse
import logging

try:  # normal package import (python -m kobo_progress)
    from .orchestrator import preserve_progress
    from .paths import DEFAULT_ONBOARD_PREFIX
except ImportError:  # run directly by path (./kobo_progress/__main__.py)
    import os
    import sys

    sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    from kobo_progress.orchestrator import preserve_progress
    from kobo_progress.paths import DEFAULT_ONBOARD_PREFIX

_log = logging.getLogger("kobo_progress")


def main(argv: list[str] | None = None) -> int:
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
    _log.info("Snapshot written to: %s", result.snapshot_path)
    if result.backup_path:
        _log.info("DB backed up to: %s", result.backup_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
