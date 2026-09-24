# conform.nvim — User-Commands

`conform.nvim` bringt **ein** eigenes Command mit und keine Keymaps (keine
`vim.keymap.set`-Aufrufe im Plugin-Code). Alles Weitere hier ist **[custom]**
— eine eigene Wrapper-Schicht dieser Config um `require("conform")`.

## [default] Aus dem Plugin selbst

| Command | Quelle | Wirkung |
|---|---|---|
| `:ConformInfo` | `lazy/conform.nvim/plugin/conform.lua` | `require("conform.health").show_window()` — Fenster mit den für den aktuellen Buffer konfigurierten Formattern, ihrem Auflösungsstatus (gefunden / nicht im `PATH`) und dem Log. Der schnellste Weg zur Frage „warum formatiert das nicht". |

Registriert wird es aus dem `plugin/`-Verzeichnis des Plugins, also sobald
lazy.nvim conform lädt — nicht erst durch `conform.setup()`.

Frühere Fassungen dieses Blattes behaupteten, conform.nvim habe „keine
eigenen Usercmds". Das war falsch und ist von `:Bindings check` gefunden
worden: `:ConformInfo` stand als undokumentiertes Live-Command im Bericht,
mit `conform.nvim` in der Eigentümerspalte.

## Die eigene Wrapper-Schicht

Früher riefen zwei Stellen `conform.setup()` auf (letzter Aufruf gewinnt); die
erste — der `config`-Block des `stevearc/conform.nvim`-Specs in dieser Config
selbst — ist mit der lsp.nvim-Extraktion entfallen (`lua/plugins/lsp.lua`
existiert nicht mehr; siehe
[lsp.nvim's pack/core.lua]($REPOS_DIR/lsp.nvim/lua/lsp/pack/core.lua), das den
Spec bewusst ohne eigenen `config` lässt, "damit nichts konkurriert").

[lua/lsp/formatter/conform.lua]($REPOS_DIR/lsp.nvim/lua/lsp/formatter/conform.lua)
(`M.setup`), aufgerufen aus
[lua/lsp/init.lua]($REPOS_DIR/lsp.nvim/lua/lsp/init.lua), ist damit die einzige
verbliebene, autoritative `conform.setup()`-Stelle — setzt
`notify_on_error = true`, eine eigene `formatters_by_ft`-Tabelle sowie
explizite `command`-Pfade (Mason/pipx/pyenv-Auflösung via `resolve()`),
**ohne** `format_on_save`. Format-on-Save ist also faktisch nicht durch
conform.setup selbst aktiv, sondern ausschließlich durch die eigene
`lsp.formatter`-Abstraktion (s.u.).

## Format-on-Save ist eine eigene Abstraktion, kein Conform-Feature

Diese Config benutzt **nicht** Conforms eingebautes `format_on_save`. Stattdessen
baut [lua/lsp/formatter/init.lua]($REPOS_DIR/lsp.nvim/lua/lsp/formatter/init.lua)
(`M.build`) eine eigene Formatter-API (`vim.g._formatter_api`) mit:

- Conform-first, LSP-`vim.lsp.buf.format`-Fallback,
- View-Preservation über alle Fenster, die den Buffer zeigen (`winsaveview`/
  `winrestview`),
- einem eigenen togglebaren `BufWritePre`-Autocmd (Augroup `LspFormatOnSave`),
  Default **deaktiviert** (`opts.format_on_save = false`).

Die folgenden Commands sind dünne Wrapper um genau diese API. Registriert in
[lua/lsp/usercmds/formatter.lua]($REPOS_DIR/lsp.nvim/lua/lsp/usercmds/formatter.lua)
(`M.attach`), aufgerufen aus `lsp/init.lua`.

| Command | Wirkung |
|---|---|
| `:LspFormat` | Einmaliges, stilles Formatieren des aktuellen Buffers (`formatter.format(0)`) — Conform zuerst, LSP-Fallback falls kein Formatter greift. |
| `:LspFormatToggle` | Format-on-Save an/aus (`formatter.toggle()`). |
| `:LspFormatOn` | Format-on-Save aktivieren (`formatter.enable()`). |
| `:LspFormatOff` | Format-on-Save deaktivieren (`formatter.disable()`). |
| `:LspFormatStatus` | Aktuellen Zustand (`true`/`false`) per `notify.info` anzeigen. |
| `:LspFormatWhich` | Formatter-Kette + Verfügbarkeit (`fn.exepath`) für den aktuellen Buffer anzeigen — nur für `filetype=markdown`/`markdown.mdx` implementiert, sonst "No formatter chain known". Ruft `require("lsp.formatter.conform").which(0)`. |

Alle Registrierungen sind per `pcall` gegen doppelte Definition abgesichert
(`desc_tag = "[lsp_conform] "`).

## Markdown-spezifische Commands

Zusätzlich, buffer-unabhängig registriert in
[lua/lsp/languages/documentation/markdown.lua]($REPOS_DIR/lsp.nvim/lua/lsp/languages/documentation/markdown.lua)
(FileType-Autocmd-Setup für `markdown`/`mdx`):

| Command | Wirkung |
|---|---|
| `:MdFormat` | Formatiert direkt über `conform.format()` (nicht über die `lsp.formatter`-API) mit `lsp_fallback = false`. Formatter-Kette: `{"mdformat", "prettierd", "prettier"}` für `filetype=markdown`, sonst `{"prettierd", "prettier"}` (z. B. `markdown.mdx`). |
| `:MdFormatPrettier` | Erzwingt `{"prettierd", "prettier"}` unabhängig vom Filetype. |

Beide fallen auf `vim.lsp.buf.format()` zurück, falls `conform` nicht ladbar ist.

## Sonstige direkte `conform.format()`-Aufrufe (kein Usercmd)

Nicht als Command, sondern direkt aus Keymaps/Menu-Einträgen aufgerufen — siehe
[Keymaps/Conform.md](../Keymaps/Conform.md):

- `<leader>fm` (global, [lua/bindings/mappings/general.lua](../../../../../lua/bindings/mappings/general.lua))
- `<leader>fm` (buffer-lokal, überschrieben für `markdown`/`mdx`)
- `<leader>aF` (buffer-lokal, nur `astro`)
- Menu-Eintrag "Format Buffer" in [lua/config/menu/custom_menu/init.lua](../../../../../lua/config/menu/custom_menu/init.lua)
