# buffer-ctx.nvim — User Commands Cheatsheet

Four command trees, built via `lib.nvim.usercmd.composer` (migrated
2026-07-19). `lib.nvim` is now a **required** dependency (was previously
optional, only for `notify`/`map` cosmetics) — the whole command layer
`require`s `lib.nvim.usercmd.composer` unconditionally at module load.

Source: `lua/buffer_ctx/commands.lua` (`:Insert`/`:Copy`), `lua/buffer_ctx/format/init.lua` (`:Format`), `lua/buffer_ctx/mark/init.lua` (`:Mark`)
Docs: `docs/BINDINGS.md`, `docs/commands.md`, `doc/buffer-ctx.txt`

| Command | Args | Effect |
| --- | --- | --- |
| `:Insert {subcmd} [args…]` | see catalog below | Insert context text at cursor |
| `:Copy {subcmd} [args…]` | see catalog below | Copy context text to clipboard |
| `:CopyFilepathAbsolute` | — | Compat alias for `:Copy filepath absolute` |
| `:CopyFilepathRelative` | — | Compat alias for `:Copy filepath relative` |
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
| `timestamp` | `[format] [--utc]` | Current timestamp; sticky UTC via `timestamp = { utc = true }` config. Formats: `iso`, `iso-date`, `iso-time`, `unix`, `human`, `short`, `log`, `filename`, `long`, `weekday`, `time`, `12h`, `rfc2822` |
| `date` | `[format] [--utc]` | Shorthand for `timestamp`, defaulting to `iso-date` instead of `iso` — same format list |
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
| `column <N> [fill]` | target column, fill char | Align visual selection to column (charwise/blockwise only, since 2026-07-31) |
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

- **Composer migration design**: all three registration sites
  (`commands.lua`, `format/init.lua`, `mark/init.lua`) kept their existing
  dispatch tables (`DISPATCH`, `subcommands`/`register_subcommand`) and
  per-subcommand handler functions completely unchanged — only the final
  `nvim_create_user_command` + hand-rolled `complete()` pair was replaced
  with a `composer.verb(...)` call. Each route declares a single optional
  first-arg, then forwards `{a1, ...ctx.rest}` into the original, unmodified
  handler — zero behavior change to dispatch/validation/error messages.
- **Completion regression, accepted tradeoff**: `:Format` previously
  completed at *every* token position (each subcommand's `complete(arg_lead)`
  is position-agnostic, ignoring how many tokens already precede it) — the
  single-first-arg composer route model only completes the first token per
  subcommand now (e.g. `:Format sort -r <Tab>` no longer re-offers `-i`/`-n`).
  `:Insert`/`:Copy` already had this exact limitation pre-migration (their
  old completer explicitly checked `arg_idx == 1`), so no change there.
  Recovering full multi-position completion would require re-modeling each
  subcommand's ad hoc flag/kv-ish grammar onto composer's `flags`/`kv`
  schemas individually — not done, low value for a personal plugin.
- **CI gap found and fixed**: `.github/workflows/ci.yml`'s `test`/`health`
  jobs ran deliberately *without* lib.nvim ("soft dependency" comment) to
  exercise the standalone fallback path. That's no longer valid — the
  default `setup()` path now hard-requires `lib.nvim.usercmd.composer` (no
  pcall, matching every other migrated repo). Fixed by checking out
  `StefanBartl/lib.nvim` as a sibling in both jobs, matching cascade.nvim's
  precedent. `docs/TESTS/run.lua` already auto-detects a sibling checkout.
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
- **`column`'s submode detection was wrong for two ordinary shapes
  (fixed 2026-07-31)**: `validate_selection()` used to *infer* charwise vs.
  linewise vs. blockwise from mark geometry (same line → charwise, same
  column → blockwise, else linewise) instead of asking Vim. Verified against
  live selections: a charwise selection spanning two lines, and any blockwise
  selection wider than one column, were both misreported as linewise — both
  then took the single-line `align_single_line` branch instead of
  `align_block_lines` (measured before/after: a 4-column-wide block align
  touched 0 of 2 lines before the fix, 2 of 2 after). Now reads
  `vim.fn.visualmode()` directly. Also gained `visual = { "charwise",
  "blockwise" }` on the composer route (via a new `def.visual` passthrough in
  `build_routes`), so a linewise selection is refused with a clear message —
  its marks run from column 0 to `MAXCOL`, nothing for column alignment to
  work with. Needs lib.nvim's `route.visual` (lib.nvim commit `84737e1`).
- **`date` options (2026-07-21)**: `:Insert date`/`:Copy date` gained the same
  `[format] [--utc]` grammar as `:Insert timestamp` (previously it was a fixed
  `iso-date`, no args). `timestamp.lua` also gained 5 formats: `long`
  (weekday + full date), `weekday`, `time` (alias of `iso-time`), `12h`,
  `rfc2822`. Two real Windows/locale bugs found while adding these, both
  fixed by hand-building the string instead of trusting `os.date`'s strftime:
  `%p` (AM/PM) silently vanishes under Windows' C runtime, and `%A`/`%B`/`%a`/`%b`
  (weekday/month names) follow the system locale rather than English (a German
  locale renders `%a` as `"Di"`) — `long`/`weekday`/`rfc2822` now use a fixed
  English name table instead. `human` format is untouched (pre-existing,
  still locale-dependent via `%B`).
- **`:CopyFilepathAbsolute` / `:CopyFilepathRelative` (2026-08-06)**: single-word
  compat aliases for `:Copy filepath absolute` / `:Copy filepath relative`,
  the most-used invocation of the command. Registered directly in
  `commands.lua`'s `M.register()`, same pattern as `:Mark`'s
  `MarkLineToggle`/`MarkLinesYank` — untouched by composer, dispatched
  through the existing `M._dispatch("filepath", …, "clip")`.
- **`:checkhealth buffer_ctx` no longer crashes without lib.nvim (2026-08-06)**:
  `health.lua` called `lib.nvim.usercmd.composer.checkhealth(...)` at four
  spots with no guard, even though it separately `pcall`-checks for
  `lib.nvim.usercmd.composer` two lines above and warns gracefully if absent.
  Without lib.nvim installed, `:checkhealth buffer_ctx` raised an uncaught
  error partway through and never reached the Format/Mark sections — now
  gated behind the same `pcall` result; verified both with and without
  lib.nvim on the runtimepath.
- **`:Copy`/keymap-copy notifications moved to the caller (2026-08-06)**:
  `util/clip.lua`'s `M.copy` used to notify (`info`/`warn`) on its own; a
  shared low-level sink notifying internally meant a caller passing `{ silent
  = true }` (e.g. `:Mark yank`) still saw `clip`'s own `warn` fire regardless.
  `M.copy` is now a pure sink returning `(ok, err, preview)`; every call site
  (`commands.lua`'s `sink_text`/`sink_lines`, all three keymaps in
  `keymaps.lua`, `mark.yank`) now decides itself whether/how to report. No
  user-visible change in the success/failure messages themselves, just where
  they're issued from.

## `:Mark` grew three things (2026-08-24)

- **`:Mark clear [category]`** — new subcommand. Before it, unmarking meant
  toggling each line individually.
- **`:Mark toggle` is range-capable** — `:'<,'>Mark toggle` marks a
  selection. Not a per-line toggle: a partially marked range gets fully
  marked, and only a fully marked one unmarks.
- **`toggle`/`clear`/`yank` take an optional category** — named appearances
  configured via `mark.categories`, tab-completed through the
  `MARK_CATEGORY` argtype. An unknown name is refused with the configured
  list. `mark.sign` still configures the `default` category, so older
  configs are unaffected.
