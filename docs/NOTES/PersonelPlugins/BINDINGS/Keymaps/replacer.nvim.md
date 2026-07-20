# replacer.nvim — Keymaps Cheatsheet

replacer.nvim has no `bindings/` directory — keymaps only exist as
ephemeral, buffer-local mappings inside its two interactive pickers.
Defaults: `RP_Config.keymaps` in `lua/replacer/config/DEFAULTS.lua`:
`toggle_select = "<Tab>"`, `toggle_select_prev = "<S-Tab>"`,
`apply_all = "<C-a>"`, `quit = "<Esc>"`.

Cross-reference: `docs/BINDINGS.md` — accurate and current; explicitly notes
a documented-but-not-yet-implemented `r` key (replace-single-and-reopen) as a
future item, not a real binding: *"Earlier README/vimdoc revisions listed
this as if it already existed — it did not; this file reflects only keys
that are actually wired up."*

## fzf-lua picker (`lua/replacer/pickers/fzf.lua`)

Most bindings are fzf's own terminal-native `--bind`/actions table, not real
Neovim keymaps.

| lhs | mode | action | note |
| --- | --- | --- | --- |
| `<Esc>` | t | `<C-\><C-n>` — leave terminal-insert mode | Fixed; stays fixed even if `cfg.keymaps.quit` is remapped |
| `keys.quit` (`<Esc>`) | n | Closes the picker window | Buffer-local to the fzf terminal buffer |
| `key_all` (`apply_all`, `<C-a>`) | fzf `--bind` | Apply replacement to all matches (optionally behind `confirm.open()` if `cfg.confirm_all`) | which-key cannot label this |
| `key_next`/`key_prev` (`toggle_select`/`toggle_select_prev`, `<Tab>`/`<S-Tab>`) | fzf `--bind` | Toggle multi-select | same |

## Telescope picker (`lua/replacer/pickers/telescope.lua`)

Via Telescope's `attach_mappings`, genuine `vim.keymap.set` calls under the
hood.

| lhs | mode | action |
| --- | --- | --- |
| `keys.toggle_select` (`<Tab>`) | i, n | Toggle selection + move to next |
| `keys.toggle_select_prev` (`<S-Tab>`) | i, n | Toggle selection + move to previous |
| `keys.apply_all` (`<C-a>`) | i, n | Apply to every match (optionally behind `confirm.open()`), close picker |
| `keys.quit` (`<Esc>`) | i | `:stopinsert` (first stage of double-escape) |
| `keys.quit` (`<Esc>`) | n | Actually closes the picker |
| `<CR>` (Telescope's own default select, not remappable) | — | Multi-select aware: applies to all multi-selected entries if any, else the single entry under cursor |

`common.register_which_key` (both pickers) is a soft, guarded which-key
label registration — no-op if which-key.nvim isn't installed or lacks `.add()`.
