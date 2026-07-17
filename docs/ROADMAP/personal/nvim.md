# nvim

- Redo: `U` implementieren

## nvim config autocmds

I'll start by locating the autocmds in the nvim config, then cross-reference against the plugin list.

This confirms it — `autocmds/general/helpers.lua`'s `no_name_guard_sweep` has no tree-awareness (it can race with neo-tree's own buffer swaps during startup, which is exactly the bug that got it disabled), while [buffer.lua](E:\repos\filetree.nvim\lua\filetree\util\buffer.lua) in filetree.nvim already has a `TREE_FT` table and multi-adapter awareness. Let me check filetree's feature-registration pattern before porting the guard there.

Confirmed: filetree.nvim isn't wired into this config yet (that's the still-open "Liste 1" migration) — the live config uses its own `lua/config/neotree/` block directly. filetree.nvim is still the right place to build this though, since it's the adapter-aware target for that migration. Implementing the guard now.

Now the feature module itself, mirroring `layout_guard`'s structure:

Now wire it into the registry, config defaults, types, and autocmd catalog.

These diagnostics are pre-existing (unrelated lines I didn't touch). Let me verify the full diff and run a quick syntax check.

Those are require-path errors from missing `runtimepath`, not syntax errors — the parser got past compilation into execution. Let me do a proper load with the plugin's own lua dir on the path.

All modules load cleanly. Now let me update the disabled guard in the nvim config to point at its new home, then move to the broader autocmd-to-plugin mapping analysis.

Now let me get a quick purpose summary for each of the 25 plugins to map autocmds against them.

## Summary

**1. Implemented the no_name_guard port** into filetree.nvim (it was disabled in the nvim-config because the generic version had no tree-window exclusion and raced with neo-tree's own startup sequence — `state.tree nil` in commands.lua:827):

- [buffer.lua](E:\repos\filetree.nvim\lua\filetree\util\buffer.lua) — added `is_stray_no_name()` and `find_named_buffer()`
- [features/nav/no_name_guard/init.lua](E:\repos\filetree.nvim\lua\filetree\features\nav\no_name_guard\init.lua) — new feature, follows `layout_guard`'s exact pattern, excludes `adapter.get_winid()` from every sweep so it can never step on the tree window
- Wired into `features/init.lua`, `config/DEFAULTS.lua`, `@types/config.lua`, `bindings/autocmds.lua`
- All changed modules `require()`-load cleanly under a real rtp (checked via headless nvim)
- Updated the disabled entry in [autocmds/init.lua](C:\Users\bartl\AppData\Local\nvim\lua\autocmds\init.lua:26) to point at the new home instead of just saying "TEMP DISABLED"

It stays off in the nvim-config itself until "Liste 1" (the neo-tree→filetree.nvim migration, still open per your `NVIM_CFG_CLEANUP` roadmap) actually lands — right now `lua/config/neotree/` still owns neo-tree directly, so filetree.nvim isn't wired in yet.

## 2. Autocmd → plugin mapping



**No good fit among the 24** (stay host-level, since nothing in the list covers their domain): kitty padding/margin tweaks (general + terminals, duplicated in both!), cursorline-on-focus, `last_loc` (duplicated near-identically in *both* `general` and `text` — worth deduping regardless of plugin extraction), terminal `numbers`/`auto_insert`, `git.commit_ft` (trivial filetype-local opts), `git.gitsigns_refresh`/`blame_on_hold` (thin gitsigns wrappers, not worth a standalone plugin), neotest auto-discovery, eslint/prettier BufWritePre, snacks dashboard opener.

Two duplication findings worth a follow-up independent of the plugin question: **(a)** kitty spacing setup is implemented twice, verbatim, in `general` and `terminals`; **(b)** `last_loc` is implemented twice, near-verbatim, in `general` and `text`.



## Neues Plugin: `opts.nvim` oder `options.nvim` oder `config.nvim` oder ...

| Modul | Ziel-Plugin | Warum | Konfidenz |
|---|---|---|---|
| `config/lazygit/actions/{badd,replace}`, `resolve_path` | pickers / buffer-ctx / lib | Badd = Background-Buffer (dupliziert, s. Liste 2) | mittel |

### → Eigene *neue* Plugins (passen in KEINES der bestehenden)

Der Vollständigkeit halber, da du „auslagern" fragst — diese Domänen haben kein bestehendes Zuhause:
| Modul | Vorschlag | Warum |
|---|---|---|
| `config/neotest/**` | eigenes / dap-kit-Sibling | Test-Runner-Adapter, große eigenständige Einheit |

---



