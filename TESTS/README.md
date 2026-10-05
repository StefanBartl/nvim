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
nvim -n -i NONE --headless -u NONE -l TESTS/run.lua tasks_mutate    # specs whose path contains the argument
```

One line per spec, `CONFIG_TESTS_OK` and exit code 0 when all pass, exit code 1
when one fails, 2 when lib.nvim cannot be found. lib.nvim is looked up in
`$LIB_NVIM_DIR`, `$LIB_NVIM_PATH`, `$REPOS_DIR/lib.nvim`, then lazy.nvim's data
folder (the same order `scripts/tasks.lua` uses).

The specs are not part of the CI workflow yet (it would need a lib.nvim
checkout); CI lints and format-checks this folder.

## Specs

The engine's own specs (vault, fsio, model, scan, index, mutate, check, form, cli, frecency, ci) moved with the engine into the
`tasks.nvim` repo (`TESTS/` there); the ones below test the editor front ends and the parts of the engine they use.

| File | Covers |
|---|---|
| `tasks/tasks_routes_spec.lua` | the `:MyPlugins tasks/task/open` layer (`plugin_repos/tasks_*.lua`) driven through the real composer as a test command: every route, filters, the `--to=` targets (file, csv, quickfix, buffer, dashboard hook), `tasks index [--check]`, `task new` (incl. the missing-title prompt chain), `set` (values with spaces, removal, refusals), `done` (confirmation, buffer follows the file), template, `open` (pickers.nvim dispatch stubbed, fallback), and `<Tab>` completion |
| `tasks/tasks_dash_spec.lua` | the pure half of the dashboard (`plugin_repos/tasks_dash_core.lua`): list lines and highlights, header and filter chips, filter state and its stored form, the status/prio cycles, batch planning, `apply_set` / `apply_done` against a fixture vault (one index write per touched area, a failing task does not stop the batch, a second run changes nothing), export targets |
| `tasks/tasks_dash_picker_spec.lua` | the dashboard window: the plain `vim.ui.select` fallback, the default `tasks_cmd.dashboard` seam, and -- when snacks.nvim is installed (`$SNACKS_DIR` or lazy's data folder; otherwise reported as skipped) -- the real `Snacks.picker` opened headless and driven with `nvim_feedkeys`: lines and title, `s`, `<Tab>` + `p`, `<CR>`, `g?`, `f` (status, tag, clear all, blocked), `e` (buffer, marked tasks to a CSV file, cancel), `D` (declined, accepted batch), `gr`, `gb`, `r`; prompts are scripted stubs |
| `tasks/fixture.lua` | helper, not a spec: builds the temporary vault |

Every spec works on a fresh temp directory (`H.tmpdir()`, removed after the
spec); none touches the real vault.
