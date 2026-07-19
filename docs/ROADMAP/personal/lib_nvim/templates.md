# Audit: test-runner template adoption + lib.nvim candidates

Scope: every plugin in `usrcmd_composer.md`'s checklist (26 repos). Two
questions per repo, per `lib.md` point 1 and the `nvim/templates/` work
already landed in `lib.nvim`:

1. Could it use the `lib.nvim/nvim/templates/resolve_lib_nvim.lua` test-runner
   template (or does its current test setup already cover the same ground)?
2. Does its `util`/`utils`/`common` folder have something generic enough to
   be worth pulling into `lib.nvim` itself?

Written after checking all 26 repos' test setups and `util`-style folders
directly (file reads, not guesses).

## 1. Test-runner template adoption

Four caller patterns already exist in `lib.nvim/nvim/templates/README.md`:
**A** hard-fail, **B** soft-continue, **C** partial-skip, **D**
exclude-from-scope. "Dependency" below reflects what the code actually does
(unconditional `require("lib...")` vs. `pcall`-guarded), not what a README
claims — a couple of repos' docs are stale on this point.

| plugin | test suite | lib.nvim dependency | status |
| --- | --- | --- | --- |
| `buffer-ctx.nvim` | `docs/TESTS/run.lua` | soft (bridge + fallback) | ✅ has template, Pattern B |
| `cascade.nvim` | `docs/TESTS/run.lua` | soft (fully pcall-guarded bridge) | ✅ no template needed — never breaks without lib.nvim |
| `color_my_ascii.nvim` | `TESTS/run.lua` | hard | ✅ has template, Pattern A |
| `dap.nvim` | none | hard (cross, normalize, notify unconditional) | no suite yet — use Pattern A if one is added |
| `debugging.nvim` | `docs/TESTS/run.lua` | hard | ✅ has template, Pattern A |
| `diff.nvim` | `docs/TESTS/run.lua` | hard | ✅ has template, Pattern A |
| `emojis.nvim` | `docs/TESTS/run.lua` | soft (fully pcall-guarded bridge) | ✅ no template needed |
| `fileops.nvim` | `docs/TESTS/run.lua` | hard | ✅ has template (the original), Pattern A |
| `filetree.nvim` | `TESTS/smart_rename_refs/run.lua` | hard elsewhere, but this specific suite doesn't touch lib.nvim-backed modules | not urgent; the existing resolver here is an older sibling-only version (no `$LIB_NVIM_PATH`, no `lazy` fallback) — worth upgrading to the shared template if this suite ever grows to cover `trash/*`/`backup.lua` |
| `github_stats.nvim` | `lua/github_stats/tests/*_spec.lua` (busted/plenary-style `describe`/`it`) | hard (12 files) | different test philosophy — assumes a full plugin-managed Neovim session (lib.nvim already on rtp via lazy), not a headless standalone run; template doesn't apply unless a headless mode is added later |
| `gopath.nvim` | none | mixed: bridge modules (`util/cross.lua`, `util/safe.lua`) are soft/documented-optional, but `alternate/helpers/matcher.lua` and `resolvers/common/tailsearch.lua` hard-require `lib.lua.*` directly with no `pcall` — de facto hard already | no suite yet — Pattern A if one is added; also worth tightening the "optional dependency" language in `util/cross.lua`'s doc comment, since two other files already assume it's present |
| `language.nvim` | none | hard | no suite yet — Pattern A if one is added |
| `lib.nvim` | `docs/TESTS/run.lua` | — (is the lib) | n/a |
| `markdown.nvim` | `TESTS/run.lua` | hard | ✅ has template, Pattern A |
| `mdview.nvim` | `tests/lua/*_spec.lua`, `tests/nvim/*_spec.lua` (+`tests/nvim/harness.lua`) | hard (8 files) | **gap**: `harness.lua`'s header only documents a manual `--cmd "set rtp+=.,../lib.nvim"` — no `$LIB_NVIM_PATH` override, no `lazy` fallback, no `package.path` registration. Good candidate to adopt the shared template (Pattern A) |
| `migrate.nvim` | `docs/TESTS/run.lua` | hard for `migrate.opt`/`migrate.notify`/`migrate.common.*` | ✅ Pattern D (excludes those modules, documented in a comment) — the precedent Pattern D is named after |
| `nvim-cmdlog` | none | **zero** — confirmed, no `require("lib.` anywhere | matches the composer roadmap's note; add the dependency before adding a test suite, then pick a pattern |
| `nvim-containers` | none (a few files literally named `inspect_container*.lua`, not tests) | soft (`util/run_argv.lua` explicitly pcall-bridges `lib.nvim.cross.run_argv`, matching its `notify.lua` convention) | no suite yet — Pattern B fits its existing soft-dependency stance if one is added |
| `open.nvim` | none | hard (11 files) | no suite yet — Pattern A if one is added |
| `pdfport.nvim` | none | hard (12 files) | no suite yet — Pattern A if one is added |
| `pickers.nvim` | `docs/TESTS/pickers_spec.lua` | hard | ✅ has its own equivalent (Pattern C, partial-skip); today also aligned to accept `$LIB_NVIM_PATH` (kept `$REPOS_DIR` for back-compat) |
| `project-insight.nvim` | none | hard (7 files) | no suite yet — Pattern A if one is added |
| `recommender.nvim` | none | mixed: `util/lib.lua` is a soft pcall-bridge, but `analyzers/regex.lua`/`blacklist.lua` hard-require `lib.lua.*` directly | no suite yet — Pattern A if one is added |
| `replacer.nvim` | `tests/*.lua` | hard | **gap**: no `lib.nvim` resolution at all in the test files (checked `health_debug.lua` — only checks `replacer` itself is on rtp). Not urgent since these look like manual/interactive checks rather than a CI-headless suite, but worth the template if that changes |
| `reposcope.nvim` | none | hard (8 files) | no suite yet — Pattern A if one is added |
| `sessions.nvim` | none | hard (`lib.nvim.usercmd.composer`, `lib.nvim.usercmd`) | no suite yet — Pattern A if one is added |

**Net new work if you want to close every gap now:** `mdview.nvim`'s
`tests/nvim/harness.lua` is the one active suite that both hard-depends on
lib.nvim *and* lacks the resolver — that's the highest-value adoption target.
`filetree.nvim` and `replacer.nvim` are lower urgency (existing suites don't
currently exercise lib.nvim-backed code). Everything else either already has
it, doesn't need it (soft/fully-bridged), or has no suite yet to wire it into.

## 2. Interesting for `lib.nvim` itself

Ordered by how concrete/demonstrated the gap is, not by repo.

### a) `create_entry`'s missing filename validation — concrete, demonstrated bug surface

`lib.nvim/lua/lib/nvim/fs/create_entry/init.lua` (used by `pickers.nvim`'s
create-file action) only checks that `name` is a non-empty string — no check
for OS-illegal characters (`\/:*?"<>|`, NUL, whitespace-only). A user typing
a bad name currently fails at the raw `io.open`/`mkdirp` syscall with
whatever the OS returns, instead of a clean message before attempting it.

`reposcope.nvim/lua/reposcope/utils/protection.lua`'s `is_valid_filename(name)`
already does exactly this check, cleanly, with readable error strings. Good
candidate: pull it into `lib.nvim` (`lib.nvim.fs.is_valid_filename` or a
`lib.lua.strings` validator) and call it from `create_entry` before the
mkdirp/io.open attempt.

### b) Cross-platform "open with system default app"

Independently hand-rolled in three places, with meaningfully different
completeness:
- `open.nvim/lua/open_nvim/handlers/default.lua` — most complete: handles
  WSL→Windows path translation via `wslpath`, URL detection, per-OS argv
  (`cmd.exe /C start`, `open`, `xdg-open`).
- `markdown.nvim/lua/markdown_nvim/util/platform.lua`'s `M.open()` — prefers
  `vim.ui.open`, falls back to a smaller per-OS argv set — **no WSL handling
  at all**, so a WSL user hits the Linux `xdg-open` branch even when a
  Windows-side opener would be correct (same class of gap `open.nvim`
  already solved).
- `project-insight.nvim`'s `util/platform.lua` and `filetree.nvim`'s
  `util/platform.lua` don't open anything themselves but both bridge OS
  detection for exactly this kind of use.

Recommend a `lib.nvim.cross.open_default(target)` extracted from
`open.nvim`'s version (the correct one) — same shape as the existing
`copy_to_clipboard` helper. `open.nvim`'s own "default" handler would then
delegate to it (matching how its `run_detached` was already upstreamed into
`lib.nvim.cross.run`), and `markdown.nvim` gains WSL support for free instead
of carrying its own incomplete copy.

### c) Mason-managed binary resolution

`dap.nvim/lua/dap_nvim/utils/executable.lua`'s `mason_path(package_name)` —
`stdpath("data")/mason/bin/<name>[.cmd on Windows]`, existence-checked via
`uv.fs_stat`. Generic to any plugin preferring a Mason-installed tool over
bare PATH lookup (`debugging.nvim` is the obvious next consumer, same
domain). Candidate: `lib.nvim.system.mason_bin(name)` alongside a small
`find_executable(name_or_list)` (see next item — `exists`/`path` here overlap
with it).

### d) Unified platform selector + executable-candidate lookup

Three independent small overlaps:
- `filetree.nvim/util/platform.lua` layers a `current(): "windows"|"wsl"|
  "mac"|"linux"` selector *and* `has_executable()`/`get_cwd()` on top of
  `lib.nvim.cross.platform.*`'s separate booleans — `lib.nvim.cross` has no
  single-call equivalent of `current()`.
- `open.nvim/util.lua`'s `find_exec(candidates)` (first executable found in a
  candidate list) and `dap.nvim/utils/executable.lua`'s `exists`/`path` cover
  closely related ground, independently.

Candidate: `lib.nvim.cross.platform.current()` (one selector) plus a
`lib.nvim.system.find_executable(name_or_candidates)` — thin enough that
each plugin's own file stays a one-line wrapper afterward, matching the
existing bridge convention rather than removing the per-plugin file.

### e) Shape-based usercommand dispatch — directly relevant to the composer rollout

`migrate.nvim/lua/migrate/common/command.lua`'s `register()` dispatches on
**argument shape** (no args → current line, range → range mode, `%` → buffer
mode, `cwd` → cwd mode) rather than a subcommand string. `usrcmd_composer.md`
already flags `migrate.nvim` as the one repo that "doesn't map onto
composer's token-tree model directly... needs a short design pass before
implementing." This module *is* a working design for that: a
`lib.nvim.usercmd.shape_dispatch` (or a composer root-route flavor) built
from migrate.nvim's already-proven implementation, rather than designing one
from scratch when migrate.nvim's turn comes up in the checklist.

*(Note: `migrate.nvim/common/picker.lua`'s generic multi-select Telescope
picker was also considered — batch-apply keymaps, preview, entry formatting
— but it's a hard `telescope.nvim` dependency throughout, which doesn't fit
`lib.nvim`'s no-heavy-framework policy. If it gets generalized, `pickers.nvim`'s
engine-adapter layer is the better home, not `lib.nvim`.)*

### f) Debounce "skipped calls" counter

`reposcope.nvim/utils/protection.lua`'s `debounce_with_counter(fn, delay_ms)`
wraps `lib.nvim.debounce` to also track how many calls arrived while a
previous timer was pending (for "N updates coalesced" UI feedback).
`lib.nvim.debounce.new()` has no built-in equivalent. Small, self-contained,
plausible for any plugin doing live-typing-triggered work (`markdown.nvim`'s
table-view, `mdview.nvim`'s live push, `debugging.nvim`'s sources autocmd all
debounce something already).

### g) `safe_mkdir`/writability check

`reposcope.nvim/utils/protection.lua`'s `safe_mkdir` re-implements `mkdir -p`
via `vim.fn.mkdir(path, "p")` instead of using `lib.nvim.fs.mkdirp` (already
uv-based and fast-event-safe) — no functional bug, just duplicate logic. Its
`is_dir_writeable` (write-test-file probe) has no `lib.nvim` equivalent and
is a reasonable, small addition if `mkdirp` gains an optional
writability-check flag.


