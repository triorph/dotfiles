# Planning & Handoff Notes — kobo_progress

> Purpose: give a fresh session (human or AI) enough context to continue this
> project, verify the assumptions we made, and fix issues as they surface.
> Last updated: 2026-07-27 (session 2: chapter registration added).

## 1. Goal

Preserve KOBO reading progress when re-sideloading an **append-only** EPUB (a web
serial rebuilt with new chapters appended). Overwriting the file normally makes
the KOBO re-import it as a new/"Unread" book, losing the reading position.

## 2. Current status

**Done (working, 59 tests passing, TDD red→green→refactor):**
- Core logic + `preserve_progress` orchestrator + argparse CLI with a `uv` PEP 723
  run shim, all stdlib-only. **Session 3 split the old single-file module into a
  package of small classes** (see the repo map in §7); run via
  `python -m kobo_progress` or `./kobo_progress/__main__.py`.
- **Chapter registration** (session 2): inserts chapter (`ContentType='9'`) rows
  for appended chapters and bumps `NumShortcovers`. **Session 3 also inserts the
  matching TOC (`ContentType='899'`) rows** so new chapters appear in the table
  of contents. Verified against a copy of the real DB + a real book.
- **Independent 9/899 reconcile + TOC backfill** (session 5): `ChapterRegistrar`
  now diffs the EPUB against the chapter rows and the TOC rows *separately*
  (`missing_chapter_splits` / `missing_toc_splits`), inserting whichever is
  missing per split. This **backfills TOC rows** for chapters an earlier/buggier
  run gave a content row but no TOC entry — including gaps in the middle of the
  book. `NumShortcovers` bumps only by the count of new chapter (9) rows; a
  TOC-only backfill does not change it.
- **Typed rows + explicit SQL** (session 4): the `content` table is accessed
  through typed dataclasses (`BookRow`, `Pointer`) rather than raw dicts. Reads do
  `SELECT *` and pull out only the fields we use; writes are plain, hand-written
  `UPDATE`/`INSERT` (no dynamic string building except the template-copy insert,
  which must inherit unknown NOT NULL columns). `BookRow.apply_pointer` has two
  explicit states via `update_pointer: bool` — write the whole pointer +
  `___FileSize`, or sync `___FileSize` only (leaving the reading position alone).
- `logging` module output; `preserve_progress` returns a `PreserveResult` dataclass.
- JSON snapshot sidecar written **next to the source EPUB** (keyed by SQLite
  column names, via `Pointer.as_snapshot_dict`).
- Tests in `tests/` (`test_kobo_progress.py` core, `test_orchestration.py` flow,
  `test_chapters.py` chapter + TOC registration, `test_classes.py` per-class units).
- `README.md` for usage.

**Confirmed since session 1:**
- **The no-reset trick WORKED on-device** (matching `___FileSize` + restoring
  mtime → no re-import → progress preserved). But that exposed the follow-on bug:
  the device never learns about new chapters, hence chapter registration.

**Not done / next candidates:**
- Wiring into the user's existing Python EPUB-building script + a batch aggregator
  (back up DB once, then loop with `backup=False`).
- A guard for an absolute `dest` that is NOT under `onboard_root` (currently
  `os.path.relpath` would yield a `../..` path instead of erroring).
- Tuning approximate chapter weights (`___FileSize`/`___FileOffset`) if the
  on-device progress bar looks off (see §5E).
- Isolating the no-reset trigger (mtime vs size) — it held once but wasn't
  isolated (see §5A).

## 3. How things actually work (verified on the user's real device)

Confirmed by inspecting a real `KoboReader.sqlite` + real `.kepub.epub` files:

- **Progress lives in `KoboReader.sqlite`**, at `<onboard_root>/.kobo/`, NOT in the
  EPUB. Table `content`:
  - Book row: `ContentType='6'`, `ContentID = file:///mnt/onboard/<rel path>`.
  - Chapter rows: `ContentType='9'`, `ContentID = /mnt/onboard/<rel path>!!<frag>`
    (note: **no** `file://` scheme, and a **`!!`** separator). `BookID` points at
    the book row's `ContentID`.
- **Reading pointer** is on the book row: `ChapterIDBookmarked` is a **bare
  fragment + '#'**, e.g. `cleaned-..._split_103.html#` (NOT a full path, no `!!`).
  Other fields: `___PercentRead`, `ReadStatus` (0 unread / 1 reading / 2 finished),
  `ParagraphBookmarked`, `BookmarkWordOffset`, `CurrentChapterProgress`.
- **`Bookmark` table** holds only user **dog-ears/highlights** (`Type='dogear'`);
  just 2 rows in the whole DB, none for the serials. It is NOT reading-position
  state — we deliberately leave it untouched.
- **Chapters** are Calibre-style `cleaned-..._split_NNN.html`; order is by the
  numeric `NNN` suffix (DB `VolumeIndex` == split number + 1 due to front matter).
  The OPF spine was in reverse order — do NOT rely on OPF order; use `split_NNN`.
- **Chapter-row schema (for registration).** Each chapter has a `ContentType='9'`
  row. Key columns and how we fill them for a NEW chapter:
  - `ContentID` = `<mnt path>!!<frag>`; `BookID` = book `ContentID`; `Title` = frag.
  - `VolumeIndex` = split_number + 1.
  - `WordCount` = words in the chapter HTML (we compute; ~close to Kobo's).
  - `___FileSize` on a chapter row is NOT bytes — it's a **fractional weight**;
    the sum across chapters ≈ 100. We approximate as word-count share * 100.
  - `___FileOffset` is an integer bucket that **saturates at 99** near book end;
    we hardcode 99 for appended-at-end chapters.
  - `ReadStatus=0`, `___PercentRead=0`, `___NumPages=-1`, `MimeType='application/xhtml+xml'`.
  - The `content` table has **NOT NULL columns without defaults** (notably
    **`___UserID`**, real value `''`). To be robust we **copy an existing chapter
    row of the same book as a template** and override only per-chapter fields, so
    required/device-specific columns are inherited automatically.
- **`NumShortcovers`** on the BOOK row = the chapter count. Must be incremented
  by the number of newly-registered chapters, or new chapters won't display.
- **The KOBO injects `koboSpan` markup itself at import** (proven: the DB stored
  `titlepage.xhtml#kobo.1.1` while the on-disk titlepage file contained no spans;
  file size matched the DB `___FileSize`, ruling out a stale row). The user's
  EPUBs are plain (no koboSpan). Injection appears deterministic per-chapter DOM,
  so unchanged (append-only) chapters regenerate the same anchors → saved pointer
  still resolves.
- **Finished books rewind** the pointer to `titlepage.xhtml#...` and set
  `ReadStatus=2`, `___PercentRead=100`. Per-chapter progress rows survive UNTIL a
  re-import zeroes them. So "furthest read" is only recoverable if snapshotted
  before the overwrite.
- **The reset is a re-import rebuild** triggered by changed bytes. Identity is
  **path-derived and stable** (`ContentID`/`ImageId` from path), so the row is
  rebuilt in place (not orphaned under a new id). That's why save/restore is
  clean rather than needing a transplant.
- **`___NumPages` is `-1`** (KePub computes pages live) — we don't need to
  recompute pagination. The only file-identity field we patch is `___FileSize`.

## 4. Design decisions (agreed with the user)

- **Resume routing** (in `compute_resume_pointer`):
  - Not finished (mid-book OR unread) → keep pointer verbatim.
  - Finished (`ReadStatus==2`) + new chapters → jump to **first new chapter**
    (`prev_max_split + 1`), set `ReadStatus=1`, reset offsets/percent.
  - Finished + no new chapters → **no-op** (leave as-is).
- **`is_finished` uses `ReadStatus==2` ONLY** — deliberately NOT the titlepage
  pointer, because a genuinely unread book also points at the titlepage.
- **`prev_max_split`** is read from the **DB** chapter rows; the first-new-chapter
  **fragment/stem** is taken from the **new EPUB** (user preference).
- **No verify/rollback** after the DB write — we trust SQLite + the DB backup.
- **`backup` flag** — single-file runs back up by default; batch runs pass
  `backup=False` and back up once up front.
- **CLI arg order** is cp-like: `<onboard_root> <src> <dest>` where `src` is the
  local new EPUB and `dest` is the on-device path (relative OR absolute-under-root).
- **Chapter registration is independent of the pointer logic.** `preserve_progress`
  ALWAYS calls `register_new_chapters` when there are missing splits — even for a
  mid-book book (which keeps its pointer). Registration = "make the device aware
  new chapters exist"; the pointer logic = "where to resume". Two separate steps.
- **JSON snapshot sidecar** is written next to the SOURCE epub as
  `<name>.kobo_progress.json` (travels with your build, not the device).
- **Result dict / logging.** `preserve_progress` returns `snapshot_path`,
  `backup_path`, `chapters_registered`, `pointer_changed`, `filesize_synced`, and
  logs a one-line summary via the `logging` module (`kobo_progress` logger).
- **Approx percent (Case B)** = `round(first_new_split / new_max_split * 100)`,
  computed in floating point BEFORE rounding (int division would give 0).
- **Bookmark table left untouched** (dog-ears only, not progress).

## 5. KEY ASSUMPTIONS (unverified — check these if things break)

**A. The "no-reset" bet — CONFIRMED ONCE, not isolated.** Setting the DB
`___FileSize` to match the new file AND restoring the file's original **mtime**
stopped a re-import on the tested device: progress was preserved and the book did
NOT go Unread. Not yet isolated which signal (mtime vs size) is the trigger.
- Mitigation still in place: we also write the pointer back, so progress is
  restored even if a future firmware re-imports.
- **Experiment to isolate:** on one book, overwrite with original mtime restored
  vs. changed; then repeat changing file size. There is NO content-hash column in
  the schema, so hashing is unlikely to be the trigger.
- Consequence of no-reset: the device never learns new chapters → we register
  them ourselves (see §3 chapter-row schema + `register_new_chapters`).

**B. Deterministic span injection.** We assume unchanged chapters get identical
device-injected `koboSpan` ids, so a saved pointer resolves post-update. Strongly
suggested by evidence but not exhaustively proven. If positions land slightly off
after an update, this is the suspect.

**C. Append-only invariant.** We assume existing `split_NNN.html` files are
byte-identical across updates and never renumbered/re-split. If the user's build
pipeline re-splits or renumbers, both the pointer AND `first new chapter` logic
break. Verify the pipeline preserves split filenames.

**D. Timing/ordering.** The tool does everything in one invocation while mounted
(snapshot → backup → overwrite → register chapters → DB write → mtime restore).
It assumes the device is NOT actively importing during the DB write, and that no
import happens after we write. If the KOBO scans on eject and wipes our write, we
may need a different approach (see §6).

**E. Approximate chapter weights (registration).** Inserted chapter rows use a
word-count-proportional `___FileSize` weight and a fixed `___FileOffset=99`. We do
NOT re-normalise existing chapters' weights (so the total weight can drift above
100 after several updates). This only affects the **progress-bar proportions**,
not whether chapters appear. If the on-device progress bar looks wrong, revisit
`_chapter_weight`/`___FileOffset` (and consider recomputing offsets/weights for
all chapter rows). Our `WordCount` also differs slightly from Kobo's own parse.

## 6. If assumptions fail — next-step options

- **If no-reset fails and re-import wipes our DB write:** switch to a
  **save-then-restore-around-import** flow: snapshot before, let the device import
  (eject/replug), then run a second "restore" pass that writes the pointer to the
  freshly rebuilt row. Would need to split `preserve_progress` into `save` and
  `restore` phases keyed by the JSON sidecar.
- **If the device changes `ContentID`/`ImageId` on re-import (orphaning):** we'd
  need to transplant progress onto the new row / repoint identity. (Current
  evidence says identity is path-stable, so this is unlikely — but verify if a
  book shows up duplicated.)
- **If `koboSpan`/positions drift:** consider making the build produce *real*
  KePubs (inject `koboSpan` deterministically) so anchors are fully under our
  control, decoupling from device import behaviour.
- **If some books DO have `Bookmark` rows:** extend snapshot/restore to include
  the `Bookmark` table (currently untested; code focuses on the `content` row).

## 7. Repo map

```
kobo_progress/paths.py           # ContentID / on-device path helpers
kobo_progress/epub.py            # Epub: reads splits/titles/word counts from the EPUB
kobo_progress/content_rows.py    # BookRow/ChapterRow/TocChapterRow + ContentType enum
kobo_progress/progress.py        # Snapshot + compute_resume_pointer (pure logic)
kobo_progress/orchestrator.py    # preserve_progress + ChapterRegistrar + PreserveResult
kobo_progress/__init__.py        # public API re-exports
kobo_progress/__main__.py        # CLI entry point (python -m kobo_progress / direct)
tests/conftest.py                # builds synthetic KoboReader.sqlite + fake EPUBs
tests/test_kobo_progress.py      # core-logic tests (pointer/percent/snapshot)
tests/test_orchestration.py      # orchestration/flow tests (preserve_progress)
tests/test_chapters.py           # chapter + TOC registration tests
tests/test_classes.py            # per-class unit tests (Epub/rows/Snapshot/paths)
README.md                        # user-facing usage
PLANNING.md                      # this file
```

Run tests: `python3 -m pytest tests/ -q`  (59 tests). Note: the repo now uses a
`.venv` via `mise.toml` (python 3.10); if pytest is missing, `uv pip install pytest`.

Key types/functions (session 3: refactored into a package of small classes):
- `orchestrator.preserve_progress(root, dest, src, backup=)` — entry point;
  returns a `PreserveResult` dataclass.
- `orchestrator.ChapterRegistrar` — reconciles chapter (9) and TOC (899) rows
  against the EPUB *independently* (`missing_chapter_splits`/`missing_toc_splits`),
  inserting whichever is missing per split (backfills TOC-only gaps). Bumps
  `NumShortcovers` only by the count of new chapter rows.
- `content_rows.BookRow/ChapterRow/TocChapterRow` — typed `content`-table rows,
  each with `from_database`/insert/update; new rows copy a same-kind template
  row to inherit NOT NULL cols. `ContentType` enum (BOOK=6/CHAPTER=9/TOC=899).
- `epub.Epub` — `splits`, `max_split`, `title` (from `<h1>`), `word_count`,
  `chapter_weight`.
- `progress.Snapshot` + `compute_resume_pointer` (Case A/B/no-op).

## 8. Working agreement (from user's global memory)

Strongly collaborative + **test-driven development**: write tests first, confirm
they fail at runtime (not compile/import), **wait for the user to validate the
tests**, then implement (green), then refactor to minimise the diff. Do not write
implementation before the user has checked the tests.
