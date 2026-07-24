# fileops.nvim — Keymaps Cheatsheet

Source: `lua/fileops/bindings/keymaps.lua`
Bridge: local `map()` helper — prefers `lib.nvim.map`, falls back to `vim.keymap.set` (mode always `n`).
Cross-reference: `docs/BINDINGS.md`, `docs/keymaps.md` — both current and complete.

## Cycle (`cfg.keymaps.cycle ~= false`, each lhs individually remappable/disable-able via `config.keymaps.lhs.<key>`)

| lhs | action | desc |
| --- | --- | --- |
| `<leader>nf` | Next file in dir, replacing current buffer | "[fileops] Next file (replace)" |
| `<leader>pf` | Previous file, replacing current buffer | "[fileops] Previous file (replace)" |
| `<leader>nfn` | Next file, stays in buffer list (edits in place) | "[fileops] Next file (stay listed)" |
| `<leader>pfn` | Previous file, stays in buffer list | "[fileops] Previous file (stay listed)" |
| `<leader>nF` | Next file, added to buffer list without switching | "[fileops] Next file (background)" |
| `<leader>pF` | Previous file, background | "[fileops] Previous file (background)" |
| `<leader>NF` | Next file in vsplit | "[fileops] Next file (vsplit)" |
| `<leader>PF` | Previous file in vsplit | "[fileops] Previous file (vsplit)" |

All cycle keys respect a numeric count prefix (`vim.v.count1`).

## Delete (`cfg.keymaps.delete ~= false`, separate master switch)

| lhs | action | desc |
| --- | --- | --- |
| `<leader>dcf` | Deletes current file + closes buffer | "[fileops] Delete current file" |

## which-key

Group labels for `<leader>n` ("fileops: next file") and `<leader>p`
("fileops: prev file") only — soft dependency, no-op if absent.
