# `docs/ROADMAP/tools/` — could any of these become real modules?

Roadmap question: *"könnten daraus echte Module für die nvim-config/lib.nvim
entstehen?"*, later widened to *"oder für eines der Plugins"* — so each of the
eight scripts here was checked against nvim-config, lib.nvim, and the full
plugin list under `E:\repos` (`buffer-ctx.nvim` … `spotlight.nvim`, plus the
native `docmap-desktop`), not just the two named in the original wording.

## Summary

| Script | Verdict | Home |
|---|---|---|
| `keymap_command_audit.lua` | **Yes** — promote | lib.nvim, as a real usercmd |
| `keymap_command_gaps.py` | **Yes** — fold into the above | lib.nvim, same command |
| `autocmd_dispatch_bench.lua` | **Yes** — promote | lib.nvim, as a dev script |
| `duplicate_functions.py` | Partial — good fit, real gap | insights.nvim, needs multi-root support first |
| `magic_numbers.py` | Partial — good fit | insights.nvim, new analysis mode |
| `platform_branches.py` | Partial — good fit | insights.nvim, new analysis mode |
| `hardcoded_constants.py` | Partial — good fit | insights.nvim, new analysis mode |
| `run_all_tests.sh` | No natural plugin home | stays a personal script |

## Yes — promote as-is

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
per `git log`). A third, `:LibBindingsAudit` or similar, printing keymap
actions next to command routes for the currently-loaded plugins, is the
natural sibling — not a new pattern, just the missing third leg of a family
that already exists.

### `keymap_command_gaps.py` → same lib.nvim command

This is pass two over pass one's own output: it reads the tab-separated dump
`keymap_command_audit.lua` printed to a scratch file and flags actions with no
name/description overlap in the command routes. That split only exists because
today's version is a throwaway CLI pair (Lua dumps text, Python reads it back
from a hardcoded temp path). Inside a real lib.nvim command there is no
serialize/reparse step needed — the gap-detection is just a second output mode
(`:LibBindingsAudit gaps`) over the same in-memory data the audit pass already
built.

### `autocmd_dispatch_bench.lua` → lib.nvim, `scripts/`

Benchmarks `lib.nvim.bindings.autocmd.dispatcher` specifically (native
autocmd vs. the dispatcher's per-event Lua matching, at 1/5/20/50 handlers).
No other repo owns that API, so lib.nvim is the only candidate — the question
is only "script or command". A **dev script**, not a user-facing command: its
audience is "someone changing the dispatcher's own implementation", not an
end user. Belongs in lib.nvim's own `scripts/` (alongside whatever generates
its docs) as a rerunnable regression check for dispatcher overhead, not behind
a usercmd nobody but a contributor would ever run.

## Partial — good conceptual fit, real gap before it can move

`duplicate_functions.py`, `magic_numbers.py`, `platform_branches.py`, and
`hardcoded_constants.py` are all the same shape: walk every `*.nvim` repo
under `E:\repos`, regex over `.lua` files, report candidates. None of them
touch a specific plugin's API the way the two above do — they're pure
text/filesystem scans, so in principle *any* plugin could host the code. But
one plugin is already, specifically, in the business of static analysis over
a project's Lua source: **insights.nvim** (`:Insights metrics` — per-file/
per-folder line, word, and ratio analysis; `:Insights symbols` — a real Lua
symbol index; `:Insights imports` — reference/definition tracking). That is
the same category of work (read source, report patterns), just a different
axis than `metrics`'s line-counting today — hunting for magic numbers,
hardcoded config candidates, and platform branches is "code smell scanning",
metrics is "size/ratio scanning". Neither lib.nvim (runtime plumbing, not a
static-analysis engine) nor nvim-config (a personal config, not a published
tool) is as good a fit as a plugin whose whole purpose is already this.

**The real gap:** insights.nvim's commands are scoped to one project at a
time (`cwd`, an explicit directory, or `--current` buffer) — there is no
"scan N sibling repos and cross-reference the results" mode. That is exactly
what `duplicate_functions.py` needs (a function body only counts if the
*same* body shows up in *two different repos*) and it is a genuine multi-root
feature, not a rename. `magic_numbers.py`/`platform_branches.py`/
`hardcoded_constants.py` are less affected — each already reports one repo at
a time internally (the `for repo in repos:` loop is just the CLI's own
batching) — porting those three as new `:Insights` analysis modes
(`--find=magic-numbers`, `--find=platform-branches`,
`--find=hardcoded-constants`, or three flags) needs no new architecture, only
new detection logic in Lua.

So: **duplicate_functions.py stays where it is until insights.nvim grows
multi-root scanning** (a real, separately-scoped feature, not a byproduct of
this move); the other three are portable to insights.nvim now, as-is,
whenever that's worth the Lua rewrite from Python.

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
