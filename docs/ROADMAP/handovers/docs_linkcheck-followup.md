# Finish the markdown-link sweep across the repo collection

Status: **paused, resume any time.** Recorded 2026-09-24. Not urgent — every
repo is already in a far better state than it started; this is the tail end,
explicitly deferred rather than pushed through.

## Where this came from

Two asks in one session: (1) review nvim-config's own comments for
stale/uninformative ones (done, separate work, see git log around
2026-09-24), and (2) fix broken markdown links across nvim-config and,
especially, the WKDBooks notes vault. (2) turned into building
[`scripts/docs_linkcheck.py`]($NVIM_CONFIG_DIR/scripts/docs_linkcheck.py)
into a real, reusable tool (it already existed as a smaller script; see its
own git history) and then running it across the whole `$REPOS_DIR`
collection.

**Read `docs_linkcheck.py`'s own module docstring before touching any of
this again** — it documents `--fix`, `--fix-dead`, `--json`, `--report`, and
the `$REPOS_DIR`/`$NVIM_CONFIG_DIR` expansion (mirrors gopath.nvim's
`env_variable_resolution`) precisely, and several non-obvious bugs it used
to have (case-insensitive-filesystem blindness, a regex that used to run
across newlines, a Windows console-codepage mojibake bug, missing
percent-decoding) are explained right there with the concrete file that
exposed each one.

## What's already done

- **CASE + high-confidence ANCHOR auto-fix** (`--fix`) applied across all
  ~50 repos under `$REPOS_DIR` plus nvim-config itself: ~3800 mechanical
  fixes, zero manual review needed (deterministic corrections only).
- **`$REPOS_DIR`/`$NVIM_CONFIG_DIR` normalization**: every old drive-lettered
  `X:/repos/...` and the previous machine's nvim-config path, rewritten via
  `replacer.nvim`'s headless batch API (`require("replacer.batch").run(...)`
  from `nvim --headless -u NONE -c "set rtp+=…" -c "lua …" -c "qa"` — see
  git log message on the commit titled "normalize drive-lettered /repos/…"
  for the exact invocation). **Scope this to `*.md` explicitly if you rerun
  it** — an unscoped first pass also rewrote `.patch`/`.json` files that
  must stay byte-exact (historical diffs, telemetry snapshots); caught and
  reverted before commit, not repeated.
- **Fully resolved, verified DEAD/ANCHOR down to 0–1 genuinely-unfixable
  finding each**: nvim-config (78→1), WKDBook-Tricentis (71→1),
  `WKDBooks/Development/{Native-Sprachen,WebDevelopment,OS}` (all →0-2).
- **WKDBooks overall: 4295 → ~90** remaining findings (dead+anchor), a ~98%
  reduction. Everything above plus `wkdbook-myplugins`, `wkdbook-Neovim`,
  `wkdbook-Lua`, `SoftwareDokumentationen`, `wkdbook-SoftwareDevelopment`,
  `Spickzettel`, `AI`, `Aktuelle-Literatur`, and all the small stragglers
  have each had at least one real, verified pass.

## What's left

Re-run to get the current exact numbers and file list — they will have
drifted slightly from further normal editing:

```bash
python $NVIM_CONFIG_DIR/scripts/docs_linkcheck.py $REPOS_DIR/WKDBooks --json > findings.json
```

As of this writing, ~90 findings remain in WKDBooks, concentrated in
`wkdbook-myplugins` (~61, already swept twice — see commits
`acc977f`/`02b582e`) and a long tail of smaller areas already swept once
(commits `5c4b581` through `98f86d7`). Every prior round documented its
LEAVE cases with a reason (unfilled templates, never-created task cards,
plugins with no sibling checkout, intentional "how to insert a link" syntax
placeholders) — **a third pass on the same directories will mostly
re-confirm those same LEAVE verdicts**, not find new fixes. Diminishing
returns; the honest move next time is probably to accept the remainder as
permanently-LEAVE rather than sweep a fourth time, unless the underlying
repos change (e.g. a plugin gets its own checkout, a template finally gets
filled in).

Also still open, smaller and separate from the vault sweep:

- **`--report FILE`** (writes an annotatable Markdown checklist of whatever
  is still unresolved) exists and works, but has only been used once, on
  nvim-config. Worth trying again if there's appetite for the
  copy-into-a-file-and-annotate workflow at WKDBooks scale — 90 findings is
  a lot for one file, might want it split per-area.
- Check whether `Configs`, `docmap-desktop`, `my-zsh`, and the handful of
  single-digit-finding plugin repos (`lib.nvim`, `casedesk.nvim`,
  `cascade.nvim`, `data.nvim`, `buffer-ctx.nvim`, `mdview.nvim`, `my.nvim`,
  `ui.nvim`, `pdfport.nvim`, `filetree.nvim`, `emojis.nvim`, `ai.nvim`) ever
  got a real look — they were auto-fixed but not manually triaged; small
  enough to be a 10-minute pass each, never got to it in this session.

## How to resume (the pattern that worked)

1. `docs_linkcheck.py <root> --json` → the current finding list for that
   root.
2. For anything beyond a handful of findings, delegate to a background
   agent scoped to ONE subdirectory at a time (never more than one agent
   running at once — this session ran ~8 sequential rounds this way). Give
   it: the JSON finding list, the tool's docstring, and the explicit warning
   that a DEAD link's basename-match "moved to X?" hint has been proven
   wrong once already (an unrelated same-named file after a refactor) — it
   must verify by reading content, not trust the hint.
3. Review the agent's commit before pushing: confirm it only touched files
   under its assigned subdirectory (`git show --stat --name-only <hash>`),
   and that no non-`.md` files got swept in by an unscoped `git add -A`.
4. Push, re-scan, repeat with the next-largest remaining area.
