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

| File | Covers |
|---|---|
| `tasks/tasks_vault_spec.lua` | `tasks.vault`: root resolution order, area listing (skips `_Telemetry`/`TEMPLATES`/`TOOLS`/empty folders, includes the named extras), path builders, area/slug/id validators |
| `tasks/tasks_fsio_spec.lua` | `tasks.fsio.write_atomic`: parent created, bytes as given, no temp file left, a stale fixed-name temp file neither blocks nor is reused (the temp name is unique per process and call) |
| `tasks/tasks_model_spec.lua` | `tasks.model`: every field, the summary rules, each validation error code, the `title-comment` hint (` #` in a hand-written title), CRLF files, the enums and date arithmetic, ranking (deterministic for any input order), every filter incl. `stale` |
| `tasks/tasks_scan_spec.lua` | `tasks.scan`: path order, a broken file does not abort, nested files flagged, missing `tasks/` folder, TTL cache vs `refresh`, Backlog files with/without frontmatter, `find`/`find_done`/`backlog_slugs` |
| `tasks/tasks_index_spec.lua` | `tasks.index`: the exact bytes of the per-area index and the global overview, escaping and truncation, determinism, write-only-when-different (mtime survives), `check` reasons, CRLF checkout, orphan removal, best-effort `write_all` |
| `tasks/tasks_mutate_spec.lua` | `tasks.mutate`: template, `slugify`, `new` (collisions incl. Backlog, every rejected input creates nothing), `set` (only named keys change, no-op keeps `updated`, rejected patches, CRLF), `readme_add_row`, `done` (buckets, README, index, idempotence, resume after an interrupted run, rollback after a failing last step, CRLF, missing README) |
| `tasks/tasks_check_spec.lua` | `tasks.check`: a clean vault has no findings; each finding code is provoked and removed again; area filter, sorting, report format |
| `tasks/tasks_cli_spec.lua` | `tasks.cli` in-process (every command, exit codes, usage errors, filters) and `scripts/tasks.lua` in a real child Neovim |
| `tasks/tasks_routes_spec.lua` | the `:MyPlugins tasks/task/open` layer (`plugin_repos/tasks_*.lua`) driven through the real composer as a test command: every route, filters, the `--to=` targets (file, csv, quickfix, buffer, dashboard hook), `tasks index [--check]`, `task new` (incl. the missing-title prompt chain), `set` (values with spaces, removal, refusals), `done` (confirmation, buffer follows the file), template, `open` (pickers.nvim dispatch stubbed, fallback), and `<Tab>` completion |
| `tasks/tasks_dash_spec.lua` | the pure half of the dashboard (`plugin_repos/tasks_dash_core.lua`): list lines and highlights, header and filter chips, filter state and its stored form, the status/prio cycles, batch planning, `apply_set` / `apply_done` against a fixture vault (one index write per touched area, a failing task does not stop the batch, a second run changes nothing), export targets |
| `tasks/tasks_dash_picker_spec.lua` | the dashboard window: the plain `vim.ui.select` fallback, the default `tasks_cmd.dashboard` seam, and -- when snacks.nvim is installed (`$SNACKS_DIR` or lazy's data folder; otherwise reported as skipped) -- the real `Snacks.picker` opened headless and driven with `nvim_feedkeys`: lines and title, `s`, `<Tab>` + `p`, `<CR>`, `g?`, `f` (status, tag, clear all, blocked), `e` (buffer, marked tasks to a CSV file, cancel), `D` (declined, accepted batch), `gr`, `gb`, `r`; prompts are scripted stubs |
| `tasks/fixture.lua` | helper, not a spec: builds the temporary vault |

Every spec works on a fresh temp directory (`H.tmpdir()`, removed after the
spec); none touches the real vault.
