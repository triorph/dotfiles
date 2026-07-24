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

1. **Snapshots** the book's current progress from `KoboReader.sqlite` (and writes
   a JSON sidecar for auditing).
2. **Backs up** the database (skippable for batch runs).
3. **Overwrites** the on-device file with your updated EPUB.
4. **Syncs** the book row's pointer and `___FileSize`, and **restores the file's
   mtime**, so the device is less likely to re-import.

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
python3 -m kobo_progress.kobo_progress /Volumes/KOBOeReader ./new_build.epub "onedayokay/Book.kepub.epub"

# dest may also be an absolute path under the onboard root:
python3 -m kobo_progress.kobo_progress /Volumes/KOBOeReader ./new_build.epub /Volumes/KOBOeReader/onedayokay/Book.kepub.epub
```

Direct execution via [uv](https://docs.astral.sh/uv/) (the file carries a PEP 723
inline-script shim and is executable):

```bash
./kobo_progress/kobo_progress.py /Volumes/KOBOeReader ./new_build.epub "onedayokay/Book.kepub.epub"
```

The tool is standard-library only, so `python3 -m ...` works with no dependencies
even without uv.

### Batch use

Back up the database **once** yourself, then loop with `--no-backup` (or the
`backup=False` argument to `preserve_progress`) so you don't accumulate a backup
per file.

## Assumptions / caveats

- **No-reset bet:** we assume matching `___FileSize` in the DB **and** restoring
  the file's original mtime is enough to stop the device re-importing. Even if
  that turns out to be false on a given firmware, the pointer is written back
  too, so your place is still restored after any re-import.
- Chapters are ordered by their `split_NNN` filename suffix (Calibre-style
  output), and updates are **append-only** (existing chapter files are unchanged).
- "Finished" is detected via the device `ReadStatus` column only.

### To validate later (device experiments)

To confirm the no-reset bet on your firmware, on one book: overwrite with the
original mtime restored vs. changed, and observe whether progress survives; then
repeat while changing the file size. This isolates whether mtime and/or size
trigger the rescan.

## Development

```bash
python3 -m pytest tests/ -q
```
