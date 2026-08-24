# migrate.nvim — Keymaps Cheatsheet

Source: `lua/migrate/bindings/keymaps.lua`, `lua/migrate/common/picker.lua`
Cross-reference: `docs/BINDINGS.md` — verified accurate and current, no discrepancies.

Optional, **off by default** (`config.keymaps = false`). If the user sets
`keymaps = { opt = "<lhs>", notify = "<lhs>", hl = "<lhs>", lsp = "<lhs>" }`
(registered via `require("lib.nvim.map")`, now looped generically over
`migrate.registry`'s entries instead of two hardcoded fields):

| lhs (user-chosen) | mode | action | desc |
| --- | --- | --- | --- |
| `km.opt` | n | `:MigrateOpt` (current line, or N lines with a count) | "migrate: run :MigrateOpt (current line, or N with a count)" |
| `km.notify` | n | `:MigrateNotify` (current line, or N lines with a count) | "migrate: run :MigrateNotify (current line, or N with a count)" |
| `km.hl` | n | `:MigrateHl` (current line, or N lines with a count) | "migrate: run :MigrateHl (current line, or N with a count)" |
| `km.lsp` | n | `:MigrateLsp` (current line, or N lines with a count) | "migrate: run :MigrateLsp (current line, or N with a count)" |

## which-key

No group registration — no fixed prefix to label, so `bindings/which_key.lua`
only reports which-key's presence for `:checkhealth`. which-key still picks
up each `desc` automatically and labels them individually.

**Count support (since 2026-08-24):** a count migrates that many lines —
`3<leader>mo` covers the cursor line and the two below it, clamped to the
end of the buffer. It is issued as an explicit `:{line1},{line2}` range, so
it takes the same immediate-apply path a Visual selection does. The commands
were range-capable all along; nothing was passing them a range from a keymap.

Spelling the count as a range rather than relying on Vim's own
count-to-address translation is the point: `:3MigrateOpt` would mean
"line 3", not "three lines from here".

The rhs values are Lua functions now, not `<cmd>…<cr>` strings — `<cmd>`
swallows the count. **The `desc` strings changed** (they now end
"(current line, or N with a count)"), so anything matching on the old exact
text needs updating.

## Telescope picker keys (active only while a migration picker is open)

| lhs | mode | action |
| --- | --- | --- |
| `<CR>` | — | Replaces Telescope's default select: applies the current entry, or every multi-selected (`<Tab>`) entry |
| `<C-a>` | i, n | Apply ALL matches (not just selected) |
| `<S-A>` | i, n | Same, "alternative" alias |
| `<M-a>` | i, n | Same, "another alternative" |
| `<C-y>` | i, n | Same, "Yes to all" mnemonic |

The four apply-all bindings (`<C-a>`/`<S-A>`/`<M-a>`/`<C-y>`) are acknowledged
in source as redundant aliases, kept "for compatibility."
