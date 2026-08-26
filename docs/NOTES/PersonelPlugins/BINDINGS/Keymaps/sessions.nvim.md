# sessions.nvim — Keymaps Cheatsheet

Source: `lua/sessions/bindings/keymaps/init.lua`, `lua/sessions/bindings/which_key/init.lua`
Cross-reference: `docs/BINDINGS.md` — accurate and current, no discrepancies.

Routed through a local `set()` closure that tries `require("lib.nvim.bindings.keymap")`,
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
| `km.current` | n | `:Session current` | "Session: show active session" | only if `km.current` is set |
| `km.picker` | n | `:SessionLoad` | "Session: pick a session (preview)" | only if `km.picker` is set |
| `km.toggle_track` | n | `:Session toggle-track` | "Session: toggle git skip-worktree" | only if `km.toggle_track` is set |
| `km.save_tab` | n | `:Session save-tab` | "Session: save this tab's layout" | only if `km.save_tab` is set |
| `km.load_tab` | n | `:Session load-tab` | "Session: load a tab layout" | only if `km.load_tab` is set |
| `km.save_layout` | n | `:Session save-layout` | "Session: save window layout" | only if `km.save_layout` is set |
| `km.load_layout` | n | `:Session load-layout` | "Session: load window layout" | only if `km.load_layout` is set |

**Extended 2026-08-24** from four names to eleven — one per `:Session`
subcommand that takes no *required* argument, plus the `:SessionLoad` picker.
The old four keep their names (`save_ts` still spells the `save-timestamp`
subcommand) because renaming would break existing configs silently.

`delete` and `rename` are deliberately absent: both require a name argument,
and a keymap is a bare keypress with nothing to pass. Setting `km.delete`
reports exactly that rather than "unknown key" — it is a real subcommand, not
a typo. The stale `pcall(require, "lib.nvim.bindings.keymap")` fallback is gone;
registration goes through `lib.nvim.bindings.keymap`.

## which-key

Registers only a group label (not individual keys) — soft dependency,
no-op if which-key isn't installed. Computes the label prefix as the
**longest common prefix** across whichever keymaps are actually
configured, so the group label doesn't clobber unrelated `<leader>s...`
mappings from other plugins if the user picked a wider shared prefix on
purpose. Only runs if `cfg.which_key.enable` (default on) **and** at least
one keymap is set.
