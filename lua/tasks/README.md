# `tasks` -- the wkdbook task engine

Open work in the wkdbook vault is one Markdown file per task
(`<area>/ROADMAP/tasks/<slug>.md`, flat-YAML frontmatter), with a generated
overview per area (`<area>/ROADMAP/TASKS.md`). This namespace reads, ranks,
indexes, creates, changes, finishes and checks those files. The format, the
rules R1-R12 and the reasoning are in the vault:
`wkdbook-myplugins/ALL/Task-System-Konzept.md`.

It is **pure Lua with no UI and no notifications**: functions return data or
`nil, err`, and the callers decide how loud to be. The editor commands
(`:MyPlugins tasks ...`) and the headless CLI are front ends over it, so the
whole folder can later move into a plugin of its own without a rewrite
(decision E4 of the concept: config first, plugin later).

**Why `lua/tasks/`.** The namespace is deliberately a top-level one, not below
`bindings.usrcmds.plugin_repos`: the engine does not depend on `:MyPlugins`.
`tasks` is a generic word, so a third-party plugin shipping `lua/tasks/` would
shadow it; none of the installed plugins nor of the checkouts under `$REPOS_DIR` does today. If one ever
does, rename the folder and the `require("tasks.*")` calls (nothing else
refers to it).

```
lua/tasks/
├── init.lua      lazy aggregator (tasks.vault, tasks.model, ...)
├── fsio.lua      byte-exact file primitives (atomic write, O_EXCL create, CRLF helpers)
├── vault.lua     vault root, areas, paths, id/slug validation
├── model.lua     task record, enums, ranking, filters
├── scan.lua      collect task files (open and Backlog)
├── index.lua     render/write ROADMAP/TASKS.md, global export text
├── mutate.lua    template, new, set, done
├── check.lua     rule checker
├── cli.lua       command-line front end
└── @types/       LuaLS types
scripts/tasks.lua   headless entry (nvim --headless -u NONE -l)
TESTS/tasks/        specs (run with TESTS/run.lua)
```

## Modules

| Module | What it does | Key functions |
|---|---|---|
| `tasks.vault` | Resolves the vault root (`opts.root`, `set_root`, `$TASKS_VAULT`, then `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins` via `lib.nvim.system.env`). An *area* is a folder holding `ROADMAP/` or `Backlog/`, plus `ALL`, `nvim-config`, `docmap-desktop`, `migrate.nvim`; `_`-prefixed folders, `TEMPLATES` and `TOOLS` are skipped. Builds every path; whitelists area names, slugs and ids before they become path segments. | `root`, `areas`, `has_area`, `tasks_dir`, `index_path`, `backlog_dir`, `parse_id`, `valid_slug` |
| `tasks.model` | `parse_text` / `from_file` turn a file into a `Tasks.Task`. A broken file is still returned, with `errors` / `error_codes` and `valid = false`: one bad file never hides the rest. `summary` is the frontmatter `summary`, else the first body paragraph. Sorting is status rank (`doing`, `decision`, `blocked`, `open`, `parked`), then prio, then area, then slug. | `parse_text`, `from_file`, `sort`, `compare`, `filter`, `filter_from_options`, `split_commas`, `is_date`, `days_between` |
| `tasks.scan` | `lib.nvim.fs.collect_recursive` (or the TTL cache `scan_cached` with `ttl_seconds`) over `ROADMAP/tasks/` and `Backlog/`. Nested task files are returned, flagged. Backlog files count as tasks only with frontmatter and a `status`. | `area`, `all`, `backlog`, `find`, `find_done`, `backlog_slugs` |
| `tasks.index` | `render` is pure and deterministic: the same tasks give the same bytes, whatever order they are found in. `write_area` writes only when the content differs (a CRLF checkout counts as equal and keeps its line endings), removes the file when no task is open, and with `check = true` only reports `stale` (`missing` / `outdated` / `orphan`). `render_global` returns the all-areas overview as text; nothing writes `ALL/TASKS.md` (decision E2: it is never committed). | `render`, `write_area`, `write_all`, `render_global` |
| `tasks.mutate` | `new` creates the file with `O_CREAT\|O_EXCL` (a taken slug gets `-2`, `-3`, ...; a slug used in `Backlog/` counts as taken). `set` validates the patch, changes only the named keys through `lib.nvim.markdown.frontmatter` and bumps `updated` only when something changed. `done` is rule R6 (below). All three regenerate the area index. | `template`, `new`, `set`, `done`, `slugify`, `readme_add_row`, `SETTABLE` |
| `tasks.check` | Collects findings over one area or the vault (table below). | `run`, `format` |
| `tasks.cli` | Parses a command line, calls the engine, prints tab-separated lines, returns an exit code, never raises. | `run` |

## Front ends

- **Editor:** `:MyPlugins tasks | task | open` (`lua/bindings/usrcmds/plugin_repos/tasks_routes.lua`,
  `tasks_cmd.lua`, `tasks_view.lua`, and the dashboard `tasks_dash.lua` / `tasks_dash_core.lua`; documented in that folder's README). It adds only what an
  editor needs on top of the engine: composer routes and `<Tab>` completion, the `--to=` delivery
  (`lib.nvim.harvest`, `lib.nvim.ui.list`), a form for a missing title, a confirmation before
  `done`, opening files and re-pointing buffers, a picker over one area folder. The filter words
  (`--status=`, `--prio=<=2`, ...) are parsed by `model.filter_from_options`, shared with the CLI, and
  the keys `task set` accepts are `mutate.SETTABLE`.
- **Headless:** `scripts/tasks.lua` (below).

### `done` (rule R6)

`status: done`, `done_in`, `updated`; the file moves to `Backlog/FEATURES/`
(`feature`, `idea`, `research`) or `Backlog/TASKS/` (`task`, `bug`, and tasks
without a kind) as `YYYY-MM-DD_<slug>.md`; the row goes on top of that
section of `Backlog/README.md` (count recomputed, `_noch leer_` replaced by a
table, line endings kept); the area index is regenerated.

Failure safety: the four files involved are snapshotted with
`lib.nvim.checkpoint` first and restored byte-exact when any step fails.
Re-running a finished task answers `already` and changes nothing; if an earlier
run died after creating the Backlog file but before deleting the old one, the
next run completes it. A target that exists with different content, or a
finished task with the same id under another date, is refused.

### Findings of `check`

| Code | Meaning |
|---|---|
| `frontmatter-missing`, `frontmatter-invalid`, `title-missing`, `status-missing`, `field-type`, `unreadable` | the file cannot be read as a task |
| `unknown-status`, `unknown-kind`, `bad-prio`, `bad-effort`, `bad-date` | a field has a value outside its enum / format |
| `slug` | filename is not a kebab-case ASCII slug, or the file lies in a subfolder of `tasks/` |
| `index-stale`, `index-error` | `ROADMAP/TASKS.md` is missing, outdated or left over / could not be checked |
| `bad-blocked-by`, `blocked-by-self`, `blocked-by-dangling` | the blocker is malformed, the task itself, or exists nowhere |
| `blocked-by-done` (warning) | the blocker is already finished |
| `done-in-roadmap` | `status: done` in `ROADMAP/tasks/` |
| `open-in-backlog` | a task file in `Backlog/` whose status is not `done` |
| `duplicate-id` | an open and a finished task share an id |
| `frontmatter-warning` (warning) | a frontmatter line was kept but not understood |

Only `error` findings make a run fail.

## Headless CLI -- `scripts/tasks.lua`

For sessions without a running Neovim (rule R12) and for CI. One
implementation: the script only sets `runtimepath` (this config's `lua/`, and
lib.nvim) and calls `tasks.cli`.

```sh
nvim --headless -u NONE -l scripts/tasks.lua list --status=doing,decision
nvim --headless -u NONE -l scripts/tasks.lua new lib.nvim "Notify: unify channels" --kind=feature --prio=2 --tags=ui
nvim --headless -u NONE -l scripts/tasks.lua set lib.nvim/notify-unify-channels status=doing
nvim --headless -u NONE -l scripts/tasks.lua done lib.nvim/notify-unify-channels --done-in=lib.nvim@abc1234
nvim --headless -u NONE -l scripts/tasks.lua index --check
nvim --headless -u NONE -l scripts/tasks.lua check
```

| Command | Effect |
|---|---|
| `list [area] [--status=a,b] [--prio=1,2\|<=2] [--kind=k] [--tag=t] [--stale=N] [--blocked] [--format=tsv\|ids]` | open tasks, sorted; `id status prio effort kind updated title`, tab-separated |
| `index [area] [--check]` | write / verify `ROADMAP/TASKS.md` (all areas without argument) |
| `new <area> <title> [--kind --prio --effort --tags=a,b --summary --slug --status] [--no-index]` | create a task file |
| `set <area>/<slug> key=value ... [--no-index]` | change frontmatter; an empty value removes the key |
| `done <area>/<slug> [--done-in=text] [--date=YYYY-MM-DD] [--no-index]` | finish and move to `Backlog/` |
| `check [area]` | rule check |
| `template [--title --kind --prio --effort --tags]` | print the task template |
| `areas` | list the vault's areas |
| `export [--top=N] [--no-links]` | all-areas overview as Markdown on stdout (never written to a file) |

Global options (before or after the command): `--vault=<dir>`,
`--today=YYYY-MM-DD`. Exit codes: `0` success, `1` a finding / stale index in
`--check` / a failed operation, `2` a usage error. Errors go to stderr.

The vault is `$TASKS_VAULT`, else `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins`.
lib.nvim is looked up in `$LIB_NVIM_DIR`, `$LIB_NVIM_PATH`,
`$REPOS_DIR/lib.nvim`, then lazy.nvim's data folder.

## Tests

Specs live in `TESTS/tasks/` and run against a temporary fixture vault, never
against the real one:

```sh
nvim -n -i NONE --headless -u NONE -l TESTS/run.lua            # all
nvim -n -i NONE --headless -u NONE -l TESTS/run.lua tasks_mutate   # one
```

See [`TESTS/README.md`](../../TESTS/README.md).
