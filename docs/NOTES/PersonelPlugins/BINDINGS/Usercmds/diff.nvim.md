# diff.nvim — User Commands Cheatsheet

`:Diff`/`:DiffClear`/`:DiffBuffers`/`:DiffOrig`/`:DiffExit` rebuilt via
`lib.nvim.usercmd.composer` (migrated 2026-07-19) — the plugin that
originally motivated Phase 7's `Route.kv` bare `key=value` grammar. **No
syntax change**: same 5 independently name-configurable top-level commands
(NOT a subcommand tree — each is its own composer verb, since each has a
genuinely distinct grammar and independent `cfg.commands.*` name).

Source: `lua/diff_nvim/bindings/usrcmds.lua`
Docs: `doc/diff.txt`, `docs/installation.md`, `README.md`

| Command | Grammar |
| --- | --- |
| `:[range]Diff [target=…] [source=…] [base=…] [view=…] [output=…]` | run a diff |
| `:DiffClear` | close all `:Diff` windows, disable diffmode |
| `:DiffBuffers [view=…] [output=…]` | diff current buffer against another open buffer (picker) |
| `:DiffOrig` | diff current buffer against its on-disk saved version |
| `:DiffExit` | leave diff mode from anywhere |

## Notes

- **`Route.kv` used for real** (the case Phase 7 was built for) — but
  dispatch bypasses composer's own bound `ctx.kv` and calls the ORIGINAL,
  unmodified `core.run(ctx.raw.args, range)` / `core.run_buffers(ctx.raw.args)`
  directly with the raw args string (same pattern as replacer.nvim/
  debugging.nvim: the declared `kv` schema exists purely to drive `<Tab>`
  completion). `core`'s own key=value parsing is completely untouched.
- **`KvSpec.values` — a real (if small) composer gap found and fixed
  alongside this migration**: `target=`/`source=`/`base=`'s completion
  lists (`"clipboard"`, `"ask"`, `"git:HEAD"`) are *hints*, not a closed
  set — a real file path (`target=some/file.lua`) is also valid. Using
  `KvSpec.enum` would have been a real regression (composer's kv
  validation rejects anything outside an `enum`). Discovered that
  `KvSpec`'s type only officially documented `enum` (closed set), while
  `values` (soft hints, unenforced) was ArgSpec-only in the docs — but the
  underlying `argtypes.validate`/`argtypes.complete` functions are
  generic and already read `spec.values` for any `STRING`-typed spec table
  regardless of whether it's technically an ArgSpec or a KvSpec. Verified
  this works via a direct headless test (a non-hint-list target value is
  still accepted, not rejected), then documented `KvSpec.values?` in
  `lib.nvim`'s own `@types/init.lua` to match reality — a doc-only fix,
  zero functional/behavioral change (the capability already worked).
- **`doc/diff.txt` had two small pre-existing inaccuracies**, fixed while
  already touching this exact section: the completion reference table
  claimed `target=`/`base=` completion included "(+ file paths)" — never
  actually implemented in the original `complete()` (verified: the
  original only ever returned the 3-entry hint list, and composer now
  reproduces that exact behavior, confirmed identical via a headless
  diff). And the architecture section's file list omitted `:DiffBuffers`
  from `usrcmds.lua`'s command list.
- CI already correctly checks out `lib.nvim` as a sibling and sets
  `$LIB_NVIM_PATH` — no CI fix needed here (unlike several other repos in
  this migration series).
