# Neo-tree — User-Commands

Betrifft `nvim-neo-tree/neo-tree.nvim`. Die Source-Plugins
`mrbjarksen/neo-tree-diagnostics.nvim` und
`TimCreasman/neo-tree-tests-source.nvim` sowie `s1n7ax/nvim-window-picker`
registrieren keine eigenen User-Commands.

## 1. `:Neotree` — Plugin-Default

Registriert von `neo-tree.nvim` selbst in `plugin/neo-tree.lua` (nicht von
dieser Config) als einziges natives Neo-tree-Usercmd. `[default]`,
unverändert. Parser-Quelle im Plugin selbst (außerhalb dieses Repos):
`nvim-data/lazy/neo-tree.nvim/lua/neo-tree/command/parser.lua`.

| Argument | Typ | Werte |
|---|---|---|
| `action` | Liste | `close`, `focus`, `show` |
| `position` | Liste | `left`, `right`, `top`, `bottom`, `float`, `current` |
| `source` | Liste | `filesystem`, `buffers`, `git_status`, `document_symbols`, `diagnostics`, `tests`, `migrations`, `last` |
| `dir` | Pfad (Directory) | beliebiges Verzeichnis |
| `reveal_file` | Pfad (File) | Datei, die fokussiert werden soll |
| `git_base` | Git-Ref | Referenz für Git-Status-Vergleich |
| `toggle` | Flag | — |
| `reveal` | Flag | — |
| `reveal_force_cwd` | Flag | — |
| `selector` | Flag | — |

Beispiele: `:Neotree show filesystem left`, `:Neotree toggle reveal`,
`:Neotree close`. Diese Config nutzt `:Neotree` nicht direkt in eigenen
Keymaps — die `<M-c>`/`<M-f>`/`<M-l>`/`<M-r>`-Mappings
([Keymaps/NeoTree.md](../Keymaps/NeoTree.md)) rufen stattdessen die
Lua-API `require("neo-tree.command").execute({...})` mit denselben
Argumenten direkt auf, ohne über das Ex-Command zu gehen.

---

## 2. Custom-Usercmds dieser Config

**Keine mehr seit 2026-09-19.** `:NeoTreeCheckHealth` prüfte nur noch, ob
die Config-eigenen neo-tree-Module laden, und `:NeoTreeDebugSources` gehörte
zum Source-Switcher; beides ist mit dem Umzug in filetree.nvim entfallen
(`lua/config/neotree/usercmds/`, `checkhealth/`, `sources/` gelöscht).
Ersatz: `:checkhealth filetree` und `:Filetree source debug`.

| Command | Wirkung | Status |
|---|---|---|
| `:Filetree source [name\|pick\|next\|prev\|debug]` | filetree.nvims Source-Switcher — Picker, Wechsel nach Name, Zyklus, Debug-Dump | [custom] (filetree.nvim) |
| `:Filetree toggle [left\|right\|float\|current]` | filetree.nvims `tree_toggle` — dieselbe Aktion wie die `<M-*>`-Tasten | [custom] (filetree.nvim) |

Ein früherer dritter Usercmd-Block für `pdfport` wurde entfernt (Kommentar in
derselben Datei) — filetree.nvim's `preview`-Feature dispatcht PDFs jetzt über
`<Tab>`/`<CR>` im Baum mit demselben pdfport-Backend, ein separates Usercmd
war überflüssig.

Kein eigener `commands`-Block in `lua/plugins/neotree.lua`s `config.neotree`
außer den oben genannten zwei — die restlichen `commands = ALL_COMMANDS` in
[lua/plugins/neotree.lua](../../../../../lua/plugins/neotree.lua) sind
**Neo-tree-interne Node-Commands** (`state.commands`, an Keymaps gebunden,
z. B. `neotest_run_nearest`), keine Vim-Usercmds — siehe
[Keymaps/NeoTree.md](../Keymaps/NeoTree.md) Abschnitt „Quelle: `tests`".
