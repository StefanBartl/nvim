# migrate.nvim — Keymaps Cheatsheet

Source: `lua/migrate/bindings/keymaps.lua`, `lua/migrate/common/picker.lua`
Cross-reference: `docs/BINDINGS.md` — verified accurate and current, no discrepancies.

Optional, **off by default** (`config.keymaps = false`). If the user sets
`keymaps = { opt = "<lhs>", notify = "<lhs>" }` (registered via
`require("lib.nvim.map")`):

| lhs (user-chosen) | mode | action | desc |
| --- | --- | --- | --- |
| `km.opt` | n | `:MigrateOpt` (current-line mode) | "migrate: run :MigrateOpt (current line)" |
| `km.notify` | n | `:MigrateNotify` (current-line mode) | "migrate: run :MigrateNotify (current line)" |

Which-key picks up `desc` automatically since there's no fixed prefix;
`bindings/which_key.lua` registers no groups, only reports which-key's
presence for `:checkhealth`.

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
