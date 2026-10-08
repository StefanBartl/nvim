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

The specs are not part of the CI workflow yet (it would need a lib.nvim
checkout); CI lints and format-checks this folder.

## Specs

The specs of the task system (engine, CLI, editor front ends) moved with it into the `tasks.nvim` repo (`TESTS/` there).

| File | Covers |
|---|---|
| `neotree/event_handlers_spec.lua` | the `neo_tree_window_after_open` handler: the tree window gets `foldmethod=manual` / `foldenable` off window-locally (no leak into buffers shown there later or windows split off the editor), also when the tree window is not the current one; hostile arguments do not throw |

Every spec works on a fresh temp directory (`H.tmpdir()`, removed after the
spec); none touches the real vault.
