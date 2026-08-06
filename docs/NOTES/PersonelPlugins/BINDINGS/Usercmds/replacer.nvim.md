# replacer.nvim — User Commands Cheatsheet

`:Replace`/`:Replacer`/`:Surround`/`:Wrap` rebuilt via `lib.nvim.usercmd.composer`
(migrated 2026-07-19) — the plugin that originally motivated Phase 6's flag
grammar. **No syntax change at all**: unlike every other migration in this
series, the command names and full grammar stay byte-for-byte identical.
`:ReplaceDebug` (in `debug.lua`) is untouched — deprioritized in the roadmap,
not migrated this pass.

Source: `lua/replacer/command.lua` (`:Replace`/`:Replacer`),
`lua/replacer/surround.lua` (`:Surround`/`:Wrap`)
Docs: `docs/BINDINGS.md`, `README.md`, `doc/replacer.txt`

| Command | Grammar |
| --- | --- |
| `:[range]Replace[!] {old} {new} [scope] [--flags]` | search-and-replace |
| `:Replacer` | alias for `:Replace` |
| `:[range]Surround[!] {pattern} [delim] [scope] [--flags]` | wrap matches with a delimiter |
| `:Wrap` | alias for `:Surround` |
| `:ReplaceEscape {text}` | escape text for use as a Vim regex pattern (echo + unnamed register) |
| `:ReplaceTest [pattern] [sample]` | small floating live pattern-test panel |
| `:ReplaceRoot[!] {old} {new} [--flags]` | like `:Replace`, scope is an auto-detected project root; prompts if ambiguous |
| `:ReplaceUndo [id]` | restore files from a `--checkpoint` snapshot (most recent by default) |
| `:ReplaceHistory` | vim.ui.select over last 50 applies, re-runs the choice |
| `:ReplaceSavePreset {name} {old} {new} [scope] [--flags]` / `:ReplacePreset {name}` | named reusable replace requests, JSON under stdpath("data")/replacer/ |
| `:ReplaceBatch[!] {source} [scope] [--flags]` | multiple old=>new pairs, one full :Replace dispatch per pair; source = file/clipboard/qf |
| `:ReplaceFNames[!] {old} {new} [scope] [--dry]` | rename files/dirs whose basename matches; nested matches skipped (re-run to catch) |

## 2026-07-24 roadmap implementation pass

Working through `docs/ROADMAP.md` "Planned" section item by item (one
feature per commit, removed from ROADMAP.md as each lands). So far:
error-message quality, `--preserve-ws`, `--case-preserve` (new
`lua/replacer/casing.lua`), `--word`/`--code-only` (new
`lua/replacer/tscode.lua`, Tree-sitter best-effort/fails-open),
`:ReplaceEscape`/`:ReplaceTest`/backreferences (new `lua/replacer/regex.lua`).
All additive flags/config, off by default, zero behavior change when unset.
Still in progress — more roadmap items to follow in later commits on
`claude/replacer-nvim-roadmap-28b128`.

## Notes

- **`path = {} root route, dispatch bypasses composer's own bound values`**:
  both commands are flat grammars with no subcommand word — the textbook
  `path = {}` root-route case the roadmap anticipated. But unlike every
  prior migration's "forward `ctx.pos`/`ctx.rest` into the unchanged
  handler" pattern, here the route's `run` calls the ORIGINAL
  `handler(opts)`/`handle(run_fun, opts)` with **`ctx.raw`** directly —
  composer's untouched nvim-callback opts table, with the exact same
  `.args` string, `.bang`, `.range`/`.line1`/`.line2` shape as before. The
  declared `args`/`flags` schema on the route exists *purely* to drive
  `<Tab>` completion; `parse_request`/`apply_tokens`/`BOOL_FLAGS`/
  `VALUE_FLAGS`/`apply_value_flag` are 100% unchanged and still do the
  real parsing. Chosen because this plugin does real file mutations
  (search-and-replace across a codebase) — re-deriving request
  construction from `ctx.args`/`ctx.flags` would have meant reimplementing
  business logic that already handles quoting, escaping, repeatable
  flags, and cross-field validation (`--engine=`, `--context=`) correctly.
- **Two verb *names* sharing one spec table**: `composer.verb("Replace",
  spec)` and `composer.verb("Replacer", spec)` (same for `Surround`/`Wrap`)
  both register from the identical `spec` Lua table — confirmed safe
  (`composer.verb`/`register()` only reads the spec to build a route tree
  and register the command; it doesn't mutate it in a way that would let
  the two registrations interfere).
- **`:Surround`'s `--nested`/`--allow-nested`** flag is pulled out of the
  token stream by `surround.lua`'s own pre-filter *before* handing the
  rest to the shared `:Replace` flag parser (which would otherwise reject
  it as unknown) — unchanged. Added as two separate composer `FlagSpec`
  entries (`nested`, `allow-nested`) purely so both spellings complete.
- **Completion is now position-aware, a real improvement in most slots**:
  the original `complete()` returned one flat, position-agnostic candidate
  list (scope keywords + flag names + delimiter aliases all mixed
  together) regardless of cursor position — so e.g. `:Replace <Tab>`
  nonsensically offered `--dry`/`cwd` as candidates for the free-text
  `{old}` search-pattern slot. Composer's route now only offers scope
  keywords (`%`/`cwd`/`.`) at the actual scope position, delimiter aliases
  at the actual delim position, and flag names after a partial `--`
  prefix — `{old}`/`{new}`/`{pattern}` (genuinely free text) get no
  completion, which is correct. One accepted regression: composer treats
  a **bare** `--` (exactly two dashes, nothing after) as the
  stop-flag-parsing sentinel and deliberately does not offer flag-name
  completion for it (a documented composer behavior, not specific to this
  repo) — typing one more character (`--d`, `--l`, ...) completes
  normally.
- **Dependency docs were already inconsistent before this migration**:
  `lib.nvim.ui.kit.confirm` was already a hard, unconditional `require` in
  `init.lua` (no pcall) — but README.md's packer example and
  `doc/replacer.txt` both still labeled it "optional: progress indicator"
  in one place while the top banner correctly said "Requires lib.nvim" in
  another. Fixed both to consistently say "required" as part of this
  migration's doc sweep (also now true for an additional reason: the
  command layer itself).
- **Stale as of 2026-08-06 — now has CI**: this note used to say "No CI, no
  headless test runner". That's no longer true: `.github/workflows/ci.yml`
  now runs `luacheck` + `stylua --check` + three headless suites
  (`tests/feature_smoke.lua`, `tests/surround_smoke.lua`,
  `tests/async_utf8.lua`) against `-u NONE` with `lib.nvim` checked out
  alongside on every push/PR to `main`.
- **`:Surround` narrows to the exact selection on a charwise range
  (2026-07-31)**: previously `line_range` restricted matches by LINE only, so
  a charwise selection of just "foo" in `foo bar foo baz` wrapped *every*
  "foo" on that line, not just the selected one. A single-line charwise range
  (`ctx.range.mode == "v"`, `line1 == line2`) now also filters by column via
  a new `col_range_filter` composed with the existing `--nested` skip-filter
  (`and_filters` — `RP_Request` has one `filter` slot). Linewise and
  multi-line charwise ranges are unchanged (still whole-line-span) — narrowing
  to columns only makes sense with exactly one line's worth of them. `:Replace`
  itself was **not** touched — this is `:Surround`/`:Wrap` only. Needs
  lib.nvim's `ctx.range.col1`/`col2` (lib.nvim commit `e2f018d`).
- **`:Surround`/`:Wrap` are only reachable via `plugin/replacer.lua`**, not via
  `require("replacer").setup()` — noticed while writing a headless
  verification script for the above: `cmd.register`/`sur.register` are called
  from the autoloaded `plugin/*.lua` entry point, `init.lua`'s own `setup()`
  never calls them. Pre-existing, unrelated to the fix; not changed.
