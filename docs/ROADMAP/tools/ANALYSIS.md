# `docs/ROADMAP/tools/` — could any of these become real modules?

Roadmap question: *"könnten daraus echte Module für die nvim-config/lib.nvim
entstehen?"*, later widened to *"oder für eines der Plugins"* — so each of the
eight scripts here was checked against nvim-config, lib.nvim, and the full
plugin list under `E:\repos` (`buffer-ctx.nvim` … `spotlight.nvim`, plus the
native `docmap-desktop`), not just the two named in the original wording.

## Summary

| Script | Verdict | Home | Status |
|---|---|---|---|
| `keymap_command_audit.lua` | **Yes** | lib.nvim, real usercmd | ✅ integrated — `bindings/audit.lua`, `:LibBindingsAudit` |
| `keymap_command_gaps.py` | **Yes** — folded into the above | lib.nvim, same command | ✅ integrated — `:LibBindingsAuditGaps` |
| `autocmd_dispatch_bench.lua` | **Yes** | lib.nvim, dev script | ✅ integrated — `scripts/bench_dispatcher.lua` |
| `duplicate_functions.py` | **Yes** — corrected below | lib.nvim, real usercmd | ✅ integrated — `dev/duplicates.lua`, `:LibDuplicateScan` |
| `magic_numbers.py` | Partial — good fit | insights.nvim, new analysis mode | not started |
| `platform_branches.py` | **Dropped** — no repo gets it | none | n/a |
| `hardcoded_constants.py` | Partial — good fit | insights.nvim, new analysis mode | not started |
| `run_all_tests.sh` | No natural plugin home | stays a personal script | not started |

**Correction (after first pass):** `duplicate_functions.py` was originally
filed under insights.nvim below, reasoned as "static analysis over a
project's source, insights.nvim's own domain." That framing was wrong — the
point of this script was never "report duplication" in general, it is
specifically "find functions that appear in more than one *plugin* repo and
should therefore live in *lib.nvim*". That question belongs with the thing
the answer points at, not with a generic analysis engine. Moved to lib.nvim
instead, as `:LibDuplicateScan [path]` — scope is a root directory (cwd by
default), one level down from the "one project" scope everything else in
this file assumed. `platform_branches.py` was dropped outright: no repo in
this ecosystem is getting a platform-branch scanner built into it.

## Integrated into lib.nvim

### `keymap_command_audit.lua` → lib.nvim

Reads only `lib.nvim.bindings.keymap.registered()` and
`lib.nvim.bindings.usercmd.composer.registry()` — both are lib.nvim's own
registries, not the target plugin's internals. The `--clean` + fresh-`require`
harness only exists because this runs as a throwaway `nvim -l` script *outside*
any real session. As a real lib.nvim usercmd it would not need that at all: it
could just introspect whatever is *already* loaded in the current session —
strictly simpler than what it does today.

lib.nvim already has exactly this shape of command twice
(`:LibUsercmdDocs[Check]`, `:LibAutocmdDocs[Check|All]` — both real,
per `git log`). A third leg of that same family, now real too:
[`bindings/audit.lua`](https://github.com/StefanBartl/lib.nvim/blob/main/lua/lib/nvim/bindings/audit.lua)
(`keymap_actions`/`command_routes`/`gaps`, `:LibBindingsAudit[Gaps] [path]`
— see [`bindings/README.md`](https://github.com/StefanBartl/lib.nvim/blob/main/lua/lib/nvim/bindings/README.md)).
Simpler than the original script even: no `--clean` + fresh-`require`
harness needed, it reads whatever is already loaded in the current session.

### `keymap_command_gaps.py` → same lib.nvim command

Folded into `audit.lua` as `M.gaps()` / `:LibBindingsAuditGaps` — no
serialize/reparse step needed once both halves live in the same process; the
gap-detection is just a second read of the same in-memory data the audit
pass already built, not a second CLI reading the first one's dumped output
back off disk.

### `autocmd_dispatch_bench.lua` → lib.nvim, `scripts/`

Benchmarks `lib.nvim.bindings.autocmd.dispatcher` specifically (native
autocmd vs. the dispatcher's per-event Lua matching, at 1/5/20/50 handlers).
No other repo owns that API, so lib.nvim was the only candidate — relocated
to [`scripts/bench_dispatcher.lua`](https://github.com/StefanBartl/lib.nvim/blob/main/scripts/bench_dispatcher.lua)
as-is (only the hardcoded `rtp:append` line dropped, since it now runs from
inside the repo it benchmarks), and linked from the dispatcher's own README
at the exact sentence that motivated it ("an argument you cannot re-measure
in your own config is one you have to take on faith").

### `duplicate_functions.py` → lib.nvim (corrected from the first pass)

Originally filed under insights.nvim below on a "static analysis, that's its
domain" reading. Wrong axis: this was never a general duplication reporter,
it exists to answer one specific question — which functions appear in more
than one plugin repo and should therefore be pulled into lib.nvim — and that
question belongs with lib.nvim, the thing the answer names, not with a
general-purpose analyzer. Now
[`dev/duplicates.lua`](https://github.com/StefanBartl/lib.nvim/blob/main/lua/lib/nvim/dev/duplicates.lua)
(`:LibDuplicateScan [path]`, `path` optional and defaulting to cwd — see
[`dev/README.md`](https://github.com/StefanBartl/lib.nvim/blob/main/lua/lib/nvim/dev/README.md)), first occupant of a
new `lib.nvim.dev` namespace for cross-repo tooling that isn't any one
plugin's runtime concern. Scope is one level up from everything else here:
`path`'s *immediate subdirectories* are the repos compared against each
other (a hit needs the *same* body in *two different* repos), not `path`
itself — pointing it at a single plugin's own root, with no siblings
underneath, correctly finds nothing. lib.nvim's own directory is always
excluded from the repo set, for the obvious reason.

## Partial — good conceptual fit, not yet built

`magic_numbers.py` and `hardcoded_constants.py` are the same shape: walk
every `*.nvim` repo under `E:\repos`, regex over `.lua` files, report
candidates — but, unlike the four above, they touch no specific plugin's
API, they're pure text scans, one repo at a time (the `for repo in repos:`
loop is just the CLI's own batching, not cross-referencing). In principle any
plugin could host that code; **insights.nvim** already is, specifically, in
the business of static analysis over a project's Lua source (`:Insights
metrics` — per-file/per-folder line, word, and ratio analysis; `:Insights
symbols` — a real Lua symbol index; `:Insights imports` — reference/
definition tracking). Same category of work (read source, report patterns),
a different axis than `metrics`'s line-counting today — magic numbers and
hardcoded config candidates are "code smell scanning", metrics is "size/
ratio scanning". Porting these two as new `:Insights` analysis modes needs no
new architecture (insights.nvim's existing `cwd`/directory/`--current`
scoping already fits — neither needs `duplicate_functions.py`'s cross-repo
comparison), only new detection logic written in Lua. Not started yet —
`platform_branches.py`, the third member of this original group, was
dropped outright rather than queued here: no repo in this ecosystem is
getting a platform-branch scanner.

## No natural plugin home

### `run_all_tests.sh` → stays a personal script

Iterates every `*.nvim` repo under `E:\repos`, finds each one's own test
runner (`TESTS/run.lua`, `tests/run.lua`, `TESTS/smoke.lua`, or the sole
`TESTS/*.lua`), and reports pass/fail per repo. This is workspace-wide dev
tooling for *this machine's* checkout layout — it has nothing to do with any
one plugin's own functionality, and no published plugin should ship a script
that assumes `E:\repos` holds thirty sibling checkouts. None of the listed
plugins are "manage my other repos" tools, so there's no candidate to move
this into. Worth keeping, but as a personal script — if it's going to be
rerun regularly rather than ad hoc, it belongs in nvim-config's own
`scripts/` (a permanent home) rather than `docs/ROADMAP/tools/` (which reads
as scratch/investigation), but that's a filing decision, not a "does this
need to become a module" one.
