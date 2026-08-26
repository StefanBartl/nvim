# fileops.nvim — Keymaps Cheatsheet

Source: `lua/fileops/bindings/keymaps.lua`
Bridge: local `map()` helper — prefers `lib.nvim.bindings.keymap`, falls back to `vim.keymap.set` (mode always `n`).
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

## Eight further `lhs` keys, all unset by default (2026-08-24)

None of these binds anything unless you name an `lhs`, so the table above
is still the complete list of what fileops actually claims out of the box.

| `lhs` key | action | desc |
| --- | --- | --- |
| `next_filtered` | Prompt for a glob, then cycle forward within it | "[fileops] Next file matching a glob" |
| `prev_filtered` | Same, backward | "[fileops] Previous file matching a glob" |
| `delete_force` | Delete + force-close despite unsaved changes | "[fileops] Delete current file (force, discards unsaved changes)" |
| `path` | Copy the current path to the clipboard | "[fileops] Copy path to clipboard" |
| `cd` | cd to the current file's directory | "[fileops] cd to the current file's directory" |
| `info` | Show file info | "[fileops] Show file info" |
| `lockinfo` | Diagnose which process locks this file | "[fileops] Diagnose which process locks this file" |
| `bulk_rename` | Bulk rename in this directory | "[fileops] Bulk rename in this directory" |

The prompting ones prompt because a bare keypress carries no argument — a
glob for the filtered cycle, a pattern plus a replacement for the bulk
rename. The filtered cycle remembers the last glob for the session and still
honours a count.

`delete_force` is the `:File! delete` form: the plain `delete` key refuses on
a modified buffer and points at the command, which is right for a default
key but left the forced variant reachable only by retyping it.
