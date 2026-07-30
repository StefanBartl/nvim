# conform.nvim — Keymaps

`conform.nvim` selbst bringt keine Default-Keymaps mit (reine Lib). Alle
folgenden Mappings sind **[custom]** und rufen `require("conform").format()`
direkt auf — nicht über die `:LspFormat*`-Commands (siehe
[Usercmds/Conform.md](../Usercmds/Conform.md)). Keymap und Usercmd-Familie
laufen hier also bewusst getrennt: die Commands steuern die eigene
`lsp.formatter`-Abstraktion (View-Preservation, Toggle-Status), die Keymaps
rufen Conform "roh".

## Global

| Mapping | Modus | Aktion | Quelle |
|---|---|---|---|
| `<leader>fm` | n, x | `conform.format({ lsp_fallback = true, timeout_ms = 3000 })` | [lua/bindings/mappings/nvchad.lua](../../../../../lua/bindings/mappings/nvchad.lua) |

## Buffer-lokal (überschreibt `<leader>fm` je Filetype)

| Mapping | Filetype | Aktion | Quelle |
|---|---|---|---|
| `<leader>fm` | `markdown`, `mdx` | `conform.format({ bufnr, timeout_ms = 2000, lsp_fallback = false })` — LSP-Fallback bewusst aus, nur Conform-Formatter | [lua/lsp/languages/documentation/markdown.lua](../../../../../lua/lsp/languages/documentation/markdown.lua) |
| `<leader>aF` | `astro` | `conform.format({ bufnr, timeout_ms = 2000 })`, Fallback auf `vim.lsp.buf.format` falls Conform fehlt | [lua/lsp/languages/webdev/astro/keymaps.lua](../../../../../lua/lsp/languages/webdev/astro/keymaps.lua) |

Beide buffer-lokalen Mappings werden per `FileType`-Autocmd mit `{ buffer = ev.buf }`
gesetzt und überschreiben damit für Buffer dieses Filetyps die globale
`<leader>fm`-Definition (letztes `vim.keymap.set` auf demselben `{buffer, lhs}`
gewinnt).

## Hinweis: `<leader>fm` ist überladen

Derselbe Chord taucht in [lua/config/menu/neotree/entries.lua](../../../../../lua/config/menu/neotree/entries.lua)
als Neo-Tree-Menüeintrag "Open in file manager" auf — das ist aber ein
Neo-Tree-internes Mapping (nur im Neo-Tree-Fenster aktiv, eigener Kontext) und
kollidiert nicht mit dem globalen Format-Mapping in normalen Buffern.

## Nicht per Keymap, nur per Command

Die `:LspFormat*`-Familie (Toggle/On/Off/Status/Which) sowie `:MdFormat` und
`:MdFormatPrettier` haben bewusst **keine** Keymap-Entsprechung — siehe
[Usercmds/Conform.md](../Usercmds/Conform.md).
