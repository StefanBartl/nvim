# sessions.nvim — Keymaps Cheatsheet

Source: `lua/sessions/bindings/keymaps/init.lua`, `lua/sessions/bindings/which_key/init.lua`
Cross-reference: `docs/BINDINGS.md` — accurate and current, no discrepancies.

Routed through a local `set()` closure that tries `require("lib.nvim.map")`,
falls back to `vim.keymap.set` (`noremap=true, silent=true`). **Entirely
opt-in** — `config/DEFAULTS.lua` sets `keymaps = false` by default; there are
no baked-in default lhs strings (the "suggested" values below only appear in
the module doc-comment/README, not as active defaults) — each mapping is
registered only if its own config key is explicitly set.

| lhs (config key) | mode | action | desc | condition |
| --- | --- | --- | --- | --- |
| `km.save` | n | `:Session save` | "Session: save" | only if `km.save` is set |
| `km.load` | n | `:Session load` | "Session: load" | only if `km.load` is set |
| `km.save_ts` | n | `:Session save-timestamp` | "Session: save with timestamp" | only if `km.save_ts` is set |
| `km.list` | n | `:Session list` | "Session: list" | only if `km.list` is set |

## which-key

Registers only a group label (not individual keys) — soft dependency,
no-op if which-key isn't installed. Computes the label prefix as the
**longest common prefix** across whichever of the 4 keymaps are actually
configured, so the group label doesn't clobber unrelated `<leader>s...`
mappings from other plugins if the user picked a wider shared prefix on
purpose. Only runs if `cfg.which_key.enable` (default on) **and** at least
one keymap is set.
