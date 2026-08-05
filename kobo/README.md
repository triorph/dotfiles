# kobo_progress

Preserve your reading position on a KOBO eReader when you re-sideload an
**append-only** EPUB (e.g. a web serial that you rebuild whenever new chapters
drop).

## The problem

When you overwrite a book's file on the device, the KOBO re-imports it and
treats it as a brand-new book — resetting it to *Unread* and losing your place.
Your progress isn't stored in the EPUB; it lives in the device database at
`<KOBO>/.kobo/KoboReader.sqlite`.

## What this tool does

While the KOBO is mounted over USB, `kobo_progress`:

1. **Snapshots** the book's current progress from `KoboReader.sqlite` (writes a
   JSON sidecar next to the source EPUB for auditing).
2. **Backs up** the database (skippable for batch runs).
3. **Overwrites** the on-device file with your updated EPUB.
4. **Registers the new chapters** — reconciles the database against the EPUB and
   inserts whatever is missing: a chapter content row and/or a table-of-contents
   row per chapter, then bumps the book's chapter count (`NumShortcovers`) by the
   number of genuinely new chapters. This is required because the no-reset trick
   means the device never re-parses the file itself.
5. **Syncs** the book row's pointer and `___FileSize`, and **restores the file's
   mtime**, so the device does not re-import.

> **Why step 4 matters:** preventing the re-import preserves your progress, but it
> also means the KOBO never discovers the new chapters on its own. We add them to
> the database directly — both the chapter content and the TOC entry — so they
> show up in the reader *and* in the table of contents.
>
> The content and TOC rows are reconciled **independently**: a chapter gets a
> content row if it lacks one and a TOC row if it lacks one. So if an earlier run
> (or an older, buggier version of this tool) added a chapter's content but not
> its TOC entry, a later run **backfills the missing TOC row** — including gaps in
> the middle of the book — without needing a full re-import.

### Resume behaviour

| Book state | Result after update |
| --- | --- |
| Mid-book | Restored to the **exact** same spot |
| Unread | Left at the start |
| Finished, with new chapters | Jumps to the **first new chapter**, marked as reading |
| Finished, no new chapters | Left untouched |

## Usage

```bash
# <onboard_root> <src> <dest>   (cp-like ordering: source then destination)
python3 -m kobo_progress /Volumes/KOBOeReader ./new_build.epub "onedayokay/Book.kepub.epub"

# dest may also be an absolute path under the onboard root:
python3 -m kobo_progress /Volumes/KOBOeReader ./new_build.epub /Volumes/KOBOeReader/onedayokay/Book.kepub.epub
```

Direct execution via [uv](https://docs.astral.sh/uv/) (the entry point carries a
PEP 723 inline-script shim and is executable):

```bash
./kobo_progress/__main__.py /Volumes/KOBOeReader ./new_build.epub "onedayokay/Book.kepub.epub"
```

The tool is standard-library only, so `python3 -m ...` works with no dependencies
even without uv.

### Code layout

The package is split by responsibility:

| Module | Responsibility |
| --- | --- |
| `paths.py` | ContentID / on-device path helpers |
| `epub.py` | `Epub` — reads chapters, titles, word counts from the EPUB |
| `content_rows.py` | `BookRow`, `Pointer`, `ChapterRow`, `TocChapterRow`, the `ContentType` enum, and `existing_chapter_splits`/`existing_toc_splits` |
| `progress.py` | `Snapshot` + resume routing (pure logic) |
| `orchestrator.py` | `preserve_progress` flow + `ChapterRegistrar` (independent 9/899 reconcile) + `PreserveResult` |
| `__main__.py` | CLI entry point |

### Batch use

Back up the database **once** yourself, then loop with `--no-backup` (or the
`backup=False` argument to `preserve_progress`) so you don't accumulate a backup
per file.

## Assumptions / caveats

- **No-reset bet (confirmed once):** matching `___FileSize` in the DB **and**
  restoring the file's original mtime stopped a re-import on the tested device —
  progress was preserved. Because the device then never re-parses the file, we
  register new chapters ourselves (step 4). Even if a future firmware does
  re-import, the pointer is written back too, so your place is still restored.
- Chapters are ordered by their `split_NNN` filename suffix (Calibre-style
  output), and updates are **append-only** (existing chapter files are unchanged).
- "Finished" is detected via the device `ReadStatus` column only.
- **Chapter weights are approximate.** Inserted chapter rows use a word-count
  based `___FileSize` weight and a fixed `___FileOffset=99`; existing chapters are
  not re-normalised. This only affects the progress-bar proportions, not whether
  chapters appear. Revisit here if the on-device progress bar looks off.
- The user's dog-ear **`Bookmark`** rows are left untouched (they are not part of
  reading-position state).

### To validate later (device experiments)

The no-reset bet has held once but hasn't been isolated. On one book: overwrite
with the original mtime restored vs. changed, and observe whether progress
survives; then repeat while changing the file size. This isolates whether mtime
and/or size trigger the rescan.

## Development

```bash
python3 -m pytest tests/ -q
```
