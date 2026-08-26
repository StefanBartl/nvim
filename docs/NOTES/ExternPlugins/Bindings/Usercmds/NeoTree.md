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

Registriert in
[lua/config/neotree/usercmds/init.lua](../../../../../lua/config/neotree/usercmds/init.lua)
(`M.enable()`), aufgerufen aus
[lua/config/neotree/init.lua](../../../../../lua/config/neotree/init.lua)s
`M.setup()`. Gebaut mit `lib.nvim.bindings.usercmd.create` (kein Composer/Verb wie bei
Harpoon — einfache 1:1-Commands).

| Command | Wirkung | Status |
|---|---|---|
| `:NeoTreeCheckHealth` | Ruft `config.neotree.checkhealth.check()` auf — Config-eigener Health-Check (getrennt von Neo-trees eigenem `:checkhealth neo-tree`). | [custom] |
| `:NeoTreeDebugSources` | Ruft `config.neotree.sources.switcher.debug_sources()` auf — Debug-Ausgabe zur Source-Erkennung des Switchers. | [custom] |

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
