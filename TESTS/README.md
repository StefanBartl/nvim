# TESTS

Headless specs for the parts of this config that are plain Lua (no UI, no
plugin needed except lib.nvim). Same shape as lib.nvim's own suite: each
`*_spec.lua` returns `function(H)`, `H` is the shared assertion helper
(`harness.lua`: `eq` with deep compare, `ok`, `has`, `lacks`, `tmpdir`,
`write`, `read`, `crlf`).

## Run

From the config root (any directory works, the runner finds its own place):

```sh
nvim -n -i NONE --headless -u NONE -l TESTS/run.lua                 # everything
nvim -n -i NONE --headless -u NONE -l TESTS/run.lua sync_status     # specs whose path contains the argument
```

One line per spec, `CONFIG_TESTS_OK` and exit code 0 when all pass, exit code 1
when one fails, 2 when lib.nvim cannot be found. lib.nvim is looked up in
`$LIB_NVIM_DIR`, `$LIB_NVIM_PATH`, `$REPOS_DIR/lib.nvim`, then lazy.nvim's data
folder (the same order `scripts/tasks.lua` uses).

Runtime: the whole suite takes about 2.5 minutes on Windows, almost all of it in
the `sync/` specs, which work on real git repositories and kill real process
trees (measured 2026-10-17: `sync_integration` ~58 s, `sync_assist` ~50 s,
`sync_dash` ~19 s, `sync_busy` a few seconds). A spec prints its line only when
it is finished, so a silent minute is not a hang. Give a full run a timeout of
at least 5 minutes (a wrapper with the usual 2-minute limit kills it in the
middle of the sync specs), or filter, e.g. `run.lua sync_status`.

The specs are not part of the CI workflow yet (it would need a lib.nvim
checkout); CI lints and format-checks this folder.

## Specs

The specs of the task system (engine, CLI, editor front ends) moved with it into the `tasks.nvim` repo (`TESTS/` there).

| File | Covers |
|---|---|
| `bindings_explorer/checklist_drift_spec.lua` | `bindings_audit.drift` (`:BindingsRuntimeChecklistDrift`): entries by section/group/code span, ticks/notes/descriptions are not drift, gone/new with line numbers, the backtick-key and `` `` x `` `` spans, the real checklist parses completely |
| `blink/path_guard_spec.lua` | `config.blink_path_guard`: blink.cmp's cmdline `get_completions` gets PATH back when getcompletion() throws (fake module and, on Windows with blink.cmp installed, the real one), the error and success return values pass through, install is idempotent |
| `bindings_explorer/report_dir_spec.lua` | `config.report_dir()` (target of `:Bindings report` and `:BindingsRuntimeChecklist`) names a folder this checkout has, and `BINDINGS-RUNTIME-CHECKLIST.md` sits in it |
| `neotree/event_handlers_spec.lua` | the `neo_tree_window_after_open` handler: the tree window gets `foldmethod=manual` / `foldenable` off window-locally (no leak into buffers shown there later or windows split off the editor), also when the tree window is not the current one; hostile arguments do not throw |
| `neotree/job_handle_close_spec.lua` | `config.neotree.job_handle_close`: neo-tree's `utils.job` leaves one open uv process handle per finished job (shown on a fake with the upstream shape); patched, none stays open (also without callback and, when installed, with the real neo-tree module), callbacks get code and stdout, install is idempotent |
| `noice/routes_spec.lua` | the generic notify route sits behind the notify skip rules (first match wins); every route (skip or view) names `filter.event`, and one that includes `cmdline` needs a `cmdline_reason` |
| `ui_open/debug_export_spec.lua` | `config.ui_open`: after `setup()` (Windows) no `_`-prefixed function field is exported (runtime-analysis' telemetry wraps those); the original sits in `_debug.orig_open`, is the pre-setup `vim.ui.open` and is defined in `vim/ui.lua` |
| `startup/heartbeat_spec.lua` | `startup.heartbeat`: stalls (> 60 ms, boundary) and busy time per second from synthetic beat times (jitter boundary, a gap split over two seconds, idle seconds, empty input); `start()` honours `vim.g.startup_heartbeat = false`, is idempotent and stops after its window; the `:StartupReport` section (`report.heartbeat_lines`): summary, longest stall first, "… n more", busy seconds, recording state, and `report.lines()` carries it |
| `strip_coauthor/git_spec.lua` | `scripts/strip_coauthor/git.lua` on a throwaway repo: a trailer on the root commit, both spellings, no cap on the trailer commits, tree/subjects untouched by the rewrite |

Every spec works on a fresh temp directory (`H.tmpdir()`, removed after the
spec); none touches the real vault.
