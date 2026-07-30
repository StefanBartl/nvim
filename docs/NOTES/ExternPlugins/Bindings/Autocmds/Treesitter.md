# nvim-treesitter — Autocmds

Registriert im `config`-Block des `nvim-treesitter/nvim-treesitter`-Specs in
[lua/plugins/treesitter.lua](../../../../../lua/plugins/treesitter.lua) (modernes
`main`-Branch-Setup, keine deprecated `:TSInstall`/`configs`-API). Alle drei
sind **[custom]** — der moderne `nvim-treesitter`-Branch installiert selbst
keine Autocmds mehr, das Aktivieren von Highlight/Fold/Indent ist explizit
Aufgabe der Config (siehe Plugin-README, Abschnitt "Quickstart").

Alle drei Autocmds sind ungruppierte `FileType`-Autocmds (`lib.nvim.autocmd`,
kein eigener Augroup) und teilen sich dieselbe Guard-Bedingung
`guards.is_enabled(args.buf)` aus
[lib.nvim.treesitter.guard](../../../../../lua/lib/nvim/treesitter/guard.lua) —
ist der Buffer/Filetype über den Guard ausgeschlossen, greift keiner der drei.

| Event | Quelle | Zweck |
|---|---|---|
| `FileType` | treesitter.lua | `vim.treesitter.start(args.buf)` — aktiviert Treesitter-Highlighting für den Buffer. |
| `FileType` | treesitter.lua | Setzt `vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"` und `vim.wo.foldmethod = "expr"` — Treesitter-basiertes Folding. |
| `FileType` | treesitter.lua | Setzt `vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"` — experimentelle Treesitter-Indentation. |

## Konflikt-Hinweis: doppelte Konfiguration

Zusätzlich existiert [lua/lsp/core/treesitter.lua](../../../../../lua/lsp/core/treesitter.lua)
(`M.setup`), aufgerufen aus [lua/lsp/init.lua](../../../../../lua/lsp/init.lua)
noch vor dem LSP-Capabilities-Aufbau. Es benutzt die **alte**
`require("nvim-treesitter.configs").setup({ highlight = { enable = true }, indent = { enable = true } })`-API,
die auf dem modernen `main`-Branch dieses Plugins offiziell nicht mehr
existiert (`pcall`-abgesichert, schlägt vermutlich still fehl bzw. ist ein
Leftover aus einer älteren Konfiguration). Die tatsächlich wirksame
Aktivierung läuft über die drei `FileType`-Autocmds oben.

## `nvim-treesitter-context`

Kein Autocmd, aber themengleich: [lua/plugins/treesitter.lua](../../../../../lua/plugins/treesitter.lua)
lädt `nvim-treesitter/nvim-treesitter-context` lazy on `BufReadPost` mit
`opts = { enable = true, max_lines = 3 }` — Sticky-Context-Fenster oben im
Buffer, keine eigenen Keymaps/Usercmds in dieser Config.

## `nvim-treesitter-textobjects`

Der Plugin-Spec (`lazy = false`) lädt `nvim-treesitter/nvim-treesitter-textobjects`,
aber es gibt in diesem Repo **keine** Konfiguration dafür (kein
`textobjects`-Block, keine `select_textobject`/`move`-Keymaps) — das Plugin ist
installiert, aber praktisch ungenutzt. Textobjects laufen stattdessen über
`echasnovski/mini.ai` und `wellle/targets.vim`
([lua/plugins/textobjects.lua](../../../../../lua/plugins/textobjects.lua)), die
funktional dieselbe Rolle übernehmen. Siehe dazu ggf. eine eigene
Mini.ai/Targets-Doku außerhalb dieses Bindings-Ordners.
