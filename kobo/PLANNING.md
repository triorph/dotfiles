# Planning & Handoff Notes — kobo_progress

> Purpose: give a fresh session (human or AI) enough context to continue this
> project, verify the assumptions we made, and fix issues as they surface.
> Last updated: 2026-07-27.

## 1. Goal

Preserve KOBO reading progress when re-sideloading an **append-only** EPUB (a web
serial rebuilt with new chapters appended). Overwriting the file normally makes
the KOBO re-import it as a new/"Unread" book, losing the reading position.

## 2. Current status

**Done (working, 27 tests passing, TDD red→green→refactor):**
- Core logic + `preserve_progress` orchestrator + argparse CLI with a `uv` PEP 723
  run shim, all stdlib-only, in `kobo_progress/kobo_progress.py`.
- Tests in `tests/` (`test_kobo_progress.py` core, `test_orchestration.py` flow).
- `README.md` for usage.

**Not done / next candidates:**
- Wiring into the user's existing Python EPUB-building script + a batch aggregator
  (back up DB once, then loop with `backup=False`).
- A guard for an absolute `dest` that is NOT under `onboard_root` (currently
  `os.path.relpath` would yield a `../..` path instead of erroring).
- Validating the untested device assumptions (see §5) — **most important**.

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
- **`Bookmark` table was EMPTY** for the user's books — position is entirely on the
  `content` book row. (Keep code tolerant if some book DOES have Bookmark rows.)
- **Chapters** are Calibre-style `cleaned-..._split_NNN.html`; order is by the
  numeric `NNN` suffix (DB `VolumeIndex` == split number + 1 due to front matter).
  The OPF spine was in reverse order — do NOT rely on OPF order; use `split_NNN`.
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

## 5. KEY ASSUMPTIONS (unverified — check these if things break)

**A. The "no-reset" bet (biggest risk).** We assume that setting the DB
`___FileSize` to match the new file AND restoring the file's original **mtime** is
enough that the KOBO does NOT re-import the changed file. This was NOT tested on
the device (user couldn't run experiments at the time).
- If FALSE, the device re-imports anyway. Mitigation already in place: we also
  write the correct pointer back, so progress should still be restored after a
  re-import. But if the re-import happens *after* our DB write and zeroes it, the
  ordering breaks — see §6.
- **Experiment to run:** on one book, overwrite with original mtime restored vs.
  changed; see if progress survives. Then repeat changing file size. This
  isolates whether mtime and/or size trigger the rescan. There is NO content-hash
  column in the schema, so hashing is unlikely to be the trigger.

**B. Deterministic span injection.** We assume unchanged chapters get identical
device-injected `koboSpan` ids, so a saved pointer resolves post-update. Strongly
suggested by evidence but not exhaustively proven. If positions land slightly off
after an update, this is the suspect.

**C. Append-only invariant.** We assume existing `split_NNN.html` files are
byte-identical across updates and never renumbered/re-split. If the user's build
pipeline re-splits or renumbers, both the pointer AND `first new chapter` logic
break. Verify the pipeline preserves split filenames.

**D. Timing/ordering.** The tool does everything in one invocation while mounted
(snapshot → backup → overwrite → DB write → mtime restore). It assumes the device
is NOT actively importing during the DB write, and that no import happens after we
write. If the KOBO scans on eject and wipes our write, we may need a different
approach (see §6).

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
kobo_progress/kobo_progress.py   # tool: core fns + preserve_progress + main() CLI
tests/conftest.py                # builds synthetic KoboReader.sqlite + fake EPUBs
tests/test_kobo_progress.py      # 20 core-logic tests
tests/test_orchestration.py      # 7 orchestration/flow tests
README.md                        # user-facing usage
PLANNING.md                      # this file
```

Run tests: `python3 -m pytest tests/ -q`

## 8. Working agreement (from user's global memory)

Strongly collaborative + **test-driven development**: write tests first, confirm
they fail at runtime (not compile/import), **wait for the user to validate the
tests**, then implement (green), then refactor to minimise the diff. Do not write
implementation before the user has checked the tests.
