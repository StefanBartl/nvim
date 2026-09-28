# Finish the markdown-link sweep across the repo collection

Status: **mostly done, small tail left.** Recorded 2026-09-24, updated
2026-09-28. Every repo is already in a far better state than it started;
what remains below is genuinely the tail end.

## 2026-09-28 update

Resumed in worktree `docs-linkcheck-followup-5b3584` (branch
`claude/docs-linkcheck-followup-5b3584`, pushed). Re-ran
`docs_linkcheck.py` across all of `$REPOS_DIR/WKDBooks`: 87 findings
(down from the ~90 estimated here).

- Reviewed all 29 findings outside `wkdbook-myplugins` by hand. 1 real fix
  (`wkdbook-Neovim/nvim-api/Main/Main.md`: `JobControl.md` link updated to
  `JobControl-Lua.md` after that doc was split — commit `37fd881`). The
  other 28 re-confirmed as LEAVE (unfilled `Vorlage.md` templates,
  "how to insert a link" example syntax, an anchor that's real but set via
  HTML `<figure id=...>` rather than a heading — a checker limitation, not
  a bug in the doc — and a genuinely missing `casedesk.nvim.md` belege doc
  that nobody ever wrote, which is a content gap, not a link fix).
- Delegated `wkdbook-myplugins` (58 findings, the bulk) to one background
  agent per the established pattern. It found and fixed 5 real issues
  (commit `5a144b4`): a duplicated `repos/` path segment, a link into
  another machine's `/home/steve/...`, two `$NVIM_CONFIG_DIR/...`-style
  reformats for links that can never resolve as relative paths (nvim
  config's docs live outside the vault), and 3 anchors that drifted after
  headings gained a "— built <date>" suffix. Everything else re-confirmed
  LEAVE, matching prior sweeps.
- **New finding worth keeping**: running the checker from *inside* a
  nested worktree (`.claude/worktrees/<branch>/...`) adds extra path
  depth versus the real checkout, which turns correct
  `../../../../../<plugin>.nvim/...` cross-repo links into false-positive
  DEAD reports. Always verify a DEAD cross-repo relative link against the
  real `$REPOS_DIR/WKDBooks` checkout depth before trusting the worktree's
  own scan.
- Remaining ~82 findings in `wkdbook-myplugins` after this pass are almost
  entirely: (a) the same cross-repo relative links that are only
  false-positive-DEAD from a nested worktree and are fine at real depth
  (spot-checked several, e.g. `debugging.nvim/lua/debugging/commands.lua`,
  `color_my_ascii.nvim/docs/BINDINGS.md` — both exist), and (b) genuine
  never-created backlog/template targets already documented as LEAVE
  across three sweeps now (`acc977f`, `02b582e`, `5a144b4`). Treat the
  remainder as permanently LEAVE — a fourth pass is very unlikely to find
  anything new.

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
