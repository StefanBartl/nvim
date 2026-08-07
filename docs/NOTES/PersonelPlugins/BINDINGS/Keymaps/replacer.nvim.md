# replacer.nvim — Keymaps Cheatsheet

replacer.nvim has no `bindings/` directory — keymaps only exist as
ephemeral, buffer-local mappings inside its two interactive pickers.
Defaults: `RP_Config.keymaps` in `lua/replacer/config/DEFAULTS.lua`:
`toggle_select = "<Tab>"`, `toggle_select_prev = "<S-Tab>"`,
`apply_all = "<C-a>"`, `replace_and_reopen = "<C-r>"`, `quit = "<Esc>"`.

Cross-reference: `docs/BINDINGS.md` — accurate and current. `r`
(replace-single-and-reopen) shipped as `replace_and_reopen`, default
`<C-r>` — deliberately a modifier key, not the bare `r` originally floated
in the roadmap, since both pickers' query line is live text input and a
bare letter would swallow that character instead of reaching the search box.

## fzf-lua picker (`lua/replacer/pickers/fzf.lua`)

Most bindings are fzf's own terminal-native `--bind`/actions table, not real
Neovim keymaps.

| lhs | mode | action | note |
| --- | --- | --- | --- |
| `<Esc>` | t | `<C-\><C-n>` — leave terminal-insert mode | Fixed; stays fixed even if `cfg.keymaps.quit` is remapped |
| `keys.quit` (`<Esc>`) | n | Closes the picker window | Buffer-local to the fzf terminal buffer |
| `key_all` (`apply_all`, `<C-a>`) | fzf `--bind` | Apply replacement to all matches (optionally behind `confirm.open()` if `cfg.confirm_all`) | which-key cannot label this |
| `key_next`/`key_prev` (`toggle_select`/`toggle_select_prev`, `<Tab>`/`<S-Tab>`) | fzf `--bind` | Toggle multi-select | same |
| `key_reopen` (`replace_and_reopen`, `<C-r>`) | fzf `--bind` | Apply entry under cursor, reopen picker (recursive `run()` call) with the rest | same |

## Telescope picker (`lua/replacer/pickers/telescope.lua`)

Via Telescope's `attach_mappings`, genuine `vim.keymap.set` calls under the
hood.

| lhs | mode | action |
| --- | --- | --- |
| `keys.toggle_select` (`<Tab>`) | i, n | Toggle selection + move to next |
| `keys.toggle_select_prev` (`<S-Tab>`) | i, n | Toggle selection + move to previous |
| `keys.apply_all` (`<C-a>`) | i, n | Apply to every match (optionally behind `confirm.open()`), close picker |
| `keys.replace_and_reopen` (`<C-r>`) | i, n | Apply entry under cursor, close, reopen with the rest (recursive `run()` call) |
| `keys.quit` (`<Esc>`) | i | `:stopinsert` (first stage of double-escape) |
| `keys.quit` (`<Esc>`) | n | Actually closes the picker |
| `<CR>` (Telescope's own default select, not remappable) | — | Multi-select aware: applies to all multi-selected entries if any, else the single entry under cursor |

## which-key

`common.register_which_key` (shared by both pickers) is a soft, guarded
which-key label registration — no-op if which-key.nvim isn't installed or
lacks `.add()`. No fixed group prefix (these are ephemeral, picker-local
keymaps, not a global namespace); each picker key gets its own label
instead. The fzf-lua picker's `--bind` actions (`apply_all`/
`toggle_select*`/`replace_and_reopen`, table above) are the exception —
they never reach which-key at all, since they're fzf's own terminal-native
binding mechanism, not real `vim.keymap.set` calls.
