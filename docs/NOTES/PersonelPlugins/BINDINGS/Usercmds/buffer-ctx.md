# buffer-ctx.nvim — User Commands Cheatsheet

Four command trees, `<Tab>`-completable throughout.

Source: `lua/buffer_ctx/commands.lua` (`:Insert`/`:Copy`), `lua/buffer_ctx/format/init.lua` (`:Format`), `lua/buffer_ctx/mark/init.lua` (`:Mark`)
Docs: `docs/BINDINGS.md`, `docs/commands.md`, `doc/buffer-ctx.txt`

| Command | Args | Effect |
| --- | --- | --- |
| `:Insert {subcmd} [args…]` | see catalog below | Insert context text at cursor |
| `:Copy {subcmd} [args…]` | see catalog below | Copy context text to clipboard |
| `:Format {subcmd} [args…]` | see catalog below | Buffer/selection formatting |
| `:Mark {subcmd}` | `toggle`\|`yank` | Toggle per-line marks / yank them |
| `:MarkLineToggle` | — | Compat alias for `:Mark toggle` |
| `:MarkLinesYank` | — | Compat alias for `:Mark yank` |

## `:Insert` / `:Copy` subcommand catalog

Identical catalog for both — `:Insert` writes at the cursor, `:Copy` writes to
the system clipboard (+ unnamed register).

| Subcommand | Args | Result |
| --- | --- | --- |
| `filepath` | `[cwd\|abs\|nvim\|nvim_module] [lua\|unix\|win\|system] [0-3]` | Path of current buffer. `nvim_module` is an alias for `module`. |
| `filename` | `[noext]` | Filename, with or without extension |
| `module` | `[require\|lua_ls\|js\|c\|generic]` | `require("foo.bar")` / `---@module` / etc. |
| `location` | `[cwd\|abs\|lua] [range]` | `path:line`; with `range`, `path:L1-L2` from a `:'<,'>` selection or an explicit range |
| `timestamp` | `[format] [--utc]` | Current timestamp; sticky UTC via `timestamp = { utc = true }` config |
| `date` | — | Shorthand for `timestamp iso-date` |
| `uuid` | `[standard\|compact\|upper\|braced]` | UUID v4 |
| `annotation` | `{type} [args…]` | LuaLS annotation line(s) — see types below |
| `boilerplate` | `[template] [name]` | Multi-line code template; no arg → `vim.ui.select` picker |
| `snippet` | `[name]` | VSCode-format snippet from `snippets.paths`; no arg → picker |
| `env` | `{VAR}` | Value of an environment variable (tab-completable) |
| `git` | `[hash\|short\|branch\|tag]` | Git revision info for the buffer's repo (needs `git` in PATH) |
| `linecount` | — | Line count of the current buffer |
| `bufnr` | — | Handle of the current buffer |

### `annotation` types

`module`, `class`, `field`, `param`, `return`, `alias`, `overload`,
`diagnostic`, `deprecated`, `function` (interactive multi-line dialog).
Args not given on the command line are prompted via `vim.fn.input`.
`overload`/`deprecated` take the whole remainder of the line as free text.

## `:Format` subcommand catalog

| Subcommand | Args | Action |
| --- | --- | --- |
| `column <N> [fill]` | target column, fill char | Align visual selection to column |
| `table [ALIGN] [opts]` | `header=`, `cell=`, `skip=`, `scope=` | Format Markdown table(s) |
| `textwidth <N\|max>` | number or `max` | Set `textwidth` and reflow text |
| `filter [--remove] <pat>` | pattern(s) | Keep or remove matching lines |
| `enum [STYLE] [opts]` | `decimal`/`alpha`/`roman`, `sep=`, `start=`, `inline=` | Enumerate visual selection tokens |
| `trim` | — | Remove trailing whitespace |
| `sort [-r] [-i] [-n]` | flags | Sort lines |
| `unique [-i]` | flag | Remove duplicate lines |
| `case <mode>` | `upper`/`lower`/`title`/`sentence` | Change case |
| `indent [--spaces\|--tabs] [N]` | flags, width | Fix indentation |
| `clear` | — | Clear buffer |
| `squeeze` | — (range-aware) | Collapse consecutive blank lines to at most one |

`column` and `squeeze` are range-aware: with no range they act buffer-wide
(`squeeze`) or need a visual selection (`column`); with an explicit range
(`:'<,'>Format squeeze`, `:10,20Format squeeze`) only that span is touched.

## Notes

- **`squeeze` range plumbing**: `format_handler` threads the command's
  `line1`/`line2` through to subcommand handlers as an optional `ctx` second
  argument (`nil` when no range was given) — added 2026-07-18 alongside
  `squeeze`. Existing handlers ignore the extra arg; safe, additive change.
- **`location range`**: falls back to the last visual selection's `'<`/`'>`
  marks when no explicit range is given, since `:Copy location range` (no
  numbers) doesn't auto-populate a range the way `:'<,'>Format squeeze` does.
- **snippet tabstops are flattened, not expanded**: `${1:default}` → `default`,
  `${1|a,b|}` → `a`, bare `$0`/`$1` dropped. buffer-ctx inserts plain text; for
  real tabstop navigation use a snippet engine instead.
- **`git` is the one shell-out**: every other subcommand is pure Lua, no
  external process. Runs in the buffer's own directory (not cwd), so it stays
  correct after `:cd`. Detached HEAD reports an error for `branch` rather than
  the literal string `"HEAD"`.
