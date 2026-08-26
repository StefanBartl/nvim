# debugging.nvim — User Commands Cheatsheet

`:Debug` rebuilt via `lib.nvim.usercmd.composer` (migrated 2026-07-19).
**No syntax change**: same `:Debug {category} {action} [args]` grammar,
same ~15 categories / ~50 actions, same feature-flag gating.

Source: `lua/debugging/commands.lua` (registry + dispatch, unchanged),
`lua/debugging/bindings/usercmds.lua` (composer route-tree builder, new)
Docs: `docs/commands.md`, `doc/debugging.txt`

15 categories (`messages`, `noice`, `report`, `autocmds`, `inspect`,
`cursor`, `dump`, `keylogger`, `indent`, `markdown`, `neotree`, `module`,
`proc`, `performance`, `health`), each gated by `config.features.*`. See
`docs/commands.md` for the full action table.

## Notes

- **Dispatch bypasses composer's bound values, same as replacer.nvim**:
  every route's `run` calls the ORIGINAL, unmodified
  `commands.dispatch(ctx.raw.fargs)` — `ctx.raw` is composer's untouched
  nvim-callback opts table, same `.fargs` shape the old
  `nvim_create_user_command` callback received. The declared `args` schema
  per route exists purely to drive `<Tab>` completion; the registry,
  feature-gating, and error messages in `commands.lua` are byte-for-byte
  unchanged. `commands.lua` now exports `registry()`/`enabled()`/
  `enabled_categories()` (previously local) so the new
  `bindings/usercmds.lua` can build routes from the same data without
  duplicating it.
- **Only enabled categories get a route, snapshotted at `setup()` time** —
  matches the original completion's own `enabled_categories()` filtering
  (`neotree` is opt-in via `features.neotree = false` by default, and
  correctly absent from `:Debug <Tab>` until enabled). **One accepted,
  documented tradeoff**: dispatching a *disabled* category by typing its
  exact name (e.g. `:Debug neotree status` with `features.neotree = false`)
  now gets composer's generic "unknown subcommand" + full usage dump,
  instead of the original's specific "category %q is disabled (enable
  features.%s)" hint — an unregistered category has no route to carry that
  message through composer's error path. Documented in both
  `doc/debugging.txt`'s `features` section and this file; not fixed, since
  reproducing it would mean registering disabled categories anyway (undoing
  the completion-hiding) or adding a generic composer catch-all this repo's
  route model doesn't need elsewhere.
- **Custom `DBG_AUTOCMD_EXPR` composer type** reproduces the
  `autocmds sources`/`autocmds all` free-form `key=value` completion
  (`event=`, `sort=`, `impl=`, ... then live values after `event=`) by
  delegating straight to the existing `debugging.autocmds.sources.complete`
  — verified the exact documented examples in `docs/commands.md`
  (`:Debug autocmds sources event=Buf<Tab>` → `event=BufAdd event=BufEnter
  ...`) still produce identical output.
- **`indent treesitter`** gets a `values = {"true","false"}` hint on its
  arg for parity with the original's bespoke bool completion.
- Already a hard `lib.nvim` dependency before this migration (`bindings/
  usercmds.lua` previously used `lib.nvim.usercmd.create` directly, no
  pcall) — README/installation docs were already accurately described as
  "Requires lib.nvim", nothing to fix there. Added a `lib.nvim.usercmd.
  composer` line to the existing `health.lua` lib.nvim section (which
  already checked several other `lib.nvim.*` submodules the same way).
- `docs/TESTS/run.lua` already explicitly documents lib.nvim as a hard
  test-suite dependency ("Unlike buffer-ctx.nvim, lib.nvim is a HARD
  dependency here") with its own sibling-checkout auto-detection — no
  changes needed.
- CI (`.github/workflows/ci.yml`, stylua/luacheck/headless test suite) was
  added on 2026-07-30, after this migration — stale "no CI" note superseded.

## Handle completion (2026-08-24)

`report win`, `inspect buffer` and `inspect window` now complete their handle
argument via composer's `WINDOW`/`BUFFER` argtypes, and
`keylogger start [file]` gets `PATH` completion. They previously shared the
generic `STRING` slot, which offered nothing — and a window or buffer id is
*unguessable*, so the only way to supply one was `:echo win_getid()` first.

`proc` ids and `performance startup` deliberately keep the generic slot:
this plugin does not enumerate those values, so a completer would have
nothing true to offer. Pinned in `docs/TESTS/handle_args_spec.lua`.
