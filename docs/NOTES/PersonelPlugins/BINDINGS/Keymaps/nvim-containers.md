# sandbox.nvim — Keymaps Cheatsheet

**None — confirmed genuinely zero.** A full source grep for
`vim.keymap.set(`/`nvim_set_keymap(`/`nvim_buf_set_keymap(` and any local
`map()`-style helper found no matches anywhere in `lua/containers/`. All UI
views (`ui/list_view.lua`, `ui/log_view.lua`, `ui/inspect_view.lua`,
`ui/error_view.lua`) delegate window/buffer creation to the external
`lib.nvim.window.open_named_scratch()` helper and add no keymaps of their
own.

A stub at `lua/containers/bindings/keymaps/README.md` confirms this is
intentional: *"No default keymaps are defined by sandbox.nvim — all
functionality is exposed via user commands... Add keymap modules here if/when
default keymaps are introduced."*

All functionality is exposed exclusively through `:Container`, `:Image`, and
(conditionally, when `wsl.exe` is reachable) `:Wsl`, built on
`lib.nvim.usercmd.composer`.

Cross-reference: `docs/BINDINGS.md` states "There are no default keymaps or
autocmds" explicitly — matches source, safe to use as-is.
