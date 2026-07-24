# migrate.nvim — `:MigrateOpt` / `:MigrateNotify` Cheatsheet

Two independent top-level commands, each its own `lib.nvim.usercmd.composer`
verb on a `path = {}` root route. This was the roadmap's "needs a real
design decision" repo — its grammar dispatches on **argument shape**
(empty / `%` / `cwd` / range), not a subcommand string.

Source: `lua/migrate/common/command.lua` (`:MigrateOpt` factory, reused by
any future module registered the same way), `lua/migrate/notify/init.lua`
(`:MigrateNotify` — bespoke, doesn't go through the factory)
Docs: `docs/BINDINGS.md`, `docs/commands.md`, `doc/migrate.txt`

| Command | Effect |
| --- | --- |
| `:MigrateOpt` / `:MigrateNotify` | Migrate the current line, applied immediately |
| `:[range]MigrateOpt` / `:[range]MigrateNotify` | Migrate the given range, applied immediately (no picker) |
| `:MigrateOpt %` / `:MigrateNotify %` | Scan the whole buffer, open Telescope picker |
| `:MigrateOpt cwd` / `:MigrateNotify cwd` | Scan cwd via ripgrep, open Telescope picker (`MigrateNotify cwd` auto-writes) |
| `:MigrateNotify [mode] <module_name>` | `module_name` sets the injected `require(...).create("[name]")` label |

## Notes

- **`ctx.raw`-bypass dispatch, not composer's bound `ctx.args`** — same
  technique replacer.nvim/language.nvim use. Two behaviors here specifically
  don't map onto composer's own positional-arg binding:
  1. **Range beats argument, unconditionally.** `cmd_opts.range > 0` is
     checked *before* looking at any argument at all — `:1,5MigrateOpt cwd`
     migrates the range and silently ignores `"cwd"` entirely (not an
     error). Composer's own `bind_args` has no such "range short-circuits
     positional binding" concept.
  2. **`:MigrateNotify`'s `module_name` is always token 2, even in range
     mode**, where token 1 (`mode`) is parsed but thrown away. This is a
     genuine pre-existing quirk (flagged as a background task, see below) —
     preserved verbatim rather than "fixed" during the migration.
  3. Only the **first** whitespace-run token of the raw arg string is ever
     read for `:MigrateOpt` (`cmd_opts.args:match("%S+")`) — a 2nd token
     (`:MigrateOpt % foo`) is silently dropped, not an error. `run` reads
     `ctx.raw.args` and re-derives this the same way, not `ctx.args`/`ctx.rest`.
- **Two composer verbs, two different registration paths, on purpose.**
  `:MigrateOpt` goes through `migrate.common.command.M.register()` (a
  reusable factory — currently its only caller, but written for future
  migration-tool modules to share). `:MigrateNotify` never used that
  factory pre-migration (different grammar: an extra `module_name` arg,
  different per-mode auto-write rules) and still doesn't — it calls
  `composer.verb()` directly in `notify/init.lua`. Not worth forcing a
  shared abstraction over two genuinely different grammars.
- **Dropped `MigrateCommon.CommandOpts.complete`** (an optional raw
  `fun(arg_lead, cmd_line, cursor_pos)` completion override on the factory).
  It had zero callers in the entire repo (only `:MigrateOpt` uses the
  factory, and it never set `complete`), and composer has no plug-in point
  for an arbitrary raw completion callback per verb anyway (completion is
  always driven by registered arg types) — keeping a dead, unbridgeable
  field would just be a documented-but-broken promise. If a future module
  needs custom completion, give its arg its own `composer.register_type()`
  (as `:MigrateNotify`'s `MIGRATE_NOTIFY_SCOPE`/`MIGRATE_MODULE_NAME` do),
  same as every other repo in this rollout.
- **`nargs` is always `"*"` under composer** — both commands already used
  permissive `nargs` (`"?"` for the factory, `"*"` for `:MigrateNotify`
  originally), so this is a no-op change here, unlike language.nvim's
  `:TranslateReplace` (`"+"` → `"*"`).
- **Bare invocation depended on a same-day lib.nvim fix** (the same one
  language.nvim's bare `:Spellcheck` needed — see that cheatsheet and
  `usrcmd_composer.md`'s "Phase 8" section). Both `:MigrateOpt` and
  `:MigrateNotify` are directly bound to optional keymaps
  (`<cmd>MigrateOpt<cr>`/`<cmd>MigrateNotify<cr>` in
  `lua/migrate/bindings/keymaps.lua`) specifically for the bare,
  current-line invocation — this had to keep working. Confirmed working
  post-fix (headless-verified end to end, not just assumed from the
  language.nvim precedent).
- Existing test suite (`docs/TESTS/`) explicitly scopes itself to
  dependency-free logic (`migrate.opt.migrator`, `migrate.notify.parser`)
  and out-of-scopes anything touching `lib.nvim`/`telescope.nvim` — the
  command/binding layer was never covered, so nothing needed updating
  there; ran it anyway as a smoke check (`ok` on both specs).
- Headless-verified (with `telescope.nvim`/`plenary.nvim` on the runtimepath
  from the user's lazy install): registration (`nargs=*`, `range` enabled),
  `<Tab>` completion (`:MigrateOpt` unfiltered `%`/`cwd`, `:MigrateNotify`
  prefix-filtered, `module_name` slot correctly offers nothing), current-line
  dispatch (mutated the buffer correctly), range-mode dispatch with an
  argument present (argument correctly ignored, both lines migrated), and
  the invalid-single-token-argument path (produced the *original* custom
  error text — "Invalid argument: bogus. Use: [empty], %, or cwd" — not
  composer's own generic enum-rejection message, confirming the bypass
  preserved exact original error wording). `:checkhealth migrate` reports
  the new `lib.nvim.usercmd.composer` line.

## Pre-existing bug found (flagged separately, not fixed here)

`doc/migrate.txt` documents `:{range}MigrateNotify [module_name]` as if
`module_name` were the first token in range mode. It isn't — the code always
reads it from the *second* whitespace-separated token regardless of range
mode (the first token, `mode`, is parsed but discarded in the range branch).
So `:'<,'>MigrateNotify my.module` actually leaves `module_name` unset;
`:'<,'>MigrateNotify x my.module` is what the code actually requires. Doc/code
mismatch unrelated to this migration.
