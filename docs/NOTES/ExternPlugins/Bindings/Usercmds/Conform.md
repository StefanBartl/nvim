# conform.nvim — User-Commands

`conform.nvim` selbst ist eine reine Lib ohne eigene Usercmds oder Keymaps
(siehe [conform.nvim README](https://github.com/stevearc/conform.nvim) —
kein `user_commands`-Abschnitt, keine `vim.keymap.set`-Aufrufe im Plugin-Code).
Alles, was hier dokumentiert ist, ist daher **[custom]** — eine eigene
Wrapper-Schicht dieser Config um `require("conform")`.

Zwei Setup-Stellen rufen `conform.setup()` auf (letzter Aufruf gewinnt):

1. [lua/plugins/lsp.lua](../../../../../lua/plugins/lsp.lua) — im `config`-Block
   des `stevearc/conform.nvim`-Specs, mit einer eigenen `formatters_by_ft`-Tabelle
   und `format_on_save = { timeout_ms = 1200, lsp_fallback = true }`.
2. [lua/lsp/formatter/conform.lua](../../../../../lua/lsp/formatter/conform.lua)
   (`M.setup`), aufgerufen aus
   [lua/lsp/init.lua](../../../../../lua/lsp/init.lua) direkt danach — setzt
   `notify_on_error = true`, eine eigene (überlappende, aber nicht identische)
   `formatters_by_ft`-Tabelle sowie explizite `command`-Pfade (Mason/pipx/pyenv-
   Auflösung via `resolve()`), **ohne** `format_on_save`. Dieser zweite Aufruf
   überschreibt den ersten vollständig (Conform hält nur eine globale Config) —
   Format-on-Save ist also faktisch nicht durch conform.setup selbst aktiv,
   sondern ausschließlich durch die eigene `lsp.formatter`-Abstraktion (s.u.).

## Format-on-Save ist eine eigene Abstraktion, kein Conform-Feature

Diese Config benutzt **nicht** Conforms eingebautes `format_on_save`. Stattdessen
baut [lua/lsp/formatter/init.lua](../../../../../lua/lsp/formatter/init.lua)
(`M.build`) eine eigene Formatter-API (`vim.g._formatter_api`) mit:

- Conform-first, LSP-`vim.lsp.buf.format`-Fallback,
- View-Preservation über alle Fenster, die den Buffer zeigen (`winsaveview`/
  `winrestview`),
- einem eigenen togglebaren `BufWritePre`-Autocmd (Augroup `LspFormatOnSave`),
  Default **deaktiviert** (`opts.format_on_save = false`).

Die folgenden Commands sind dünne Wrapper um genau diese API. Registriert in
[lua/lsp/usercmds/formatter.lua](../../../../../lua/lsp/usercmds/formatter.lua)
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
[lua/lsp/languages/documentation/markdown.lua](../../../../../lua/lsp/languages/documentation/markdown.lua)
(FileType-Autocmd-Setup für `markdown`/`mdx`):

| Command | Wirkung |
|---|---|
| `:MdFormat` | Formatiert direkt über `conform.format()` (nicht über die `lsp.formatter`-API) mit `lsp_fallback = false`. Formatter-Kette: `{"mdformat", "prettierd", "prettier"}` für `filetype=markdown`, sonst `{"prettierd", "prettier"}` (z. B. `markdown.mdx`). |
| `:MdFormatPrettier` | Erzwingt `{"prettierd", "prettier"}` unabhängig vom Filetype. |

Beide fallen auf `vim.lsp.buf.format()` zurück, falls `conform` nicht ladbar ist.

## Sonstige direkte `conform.format()`-Aufrufe (kein Usercmd)

Nicht als Command, sondern direkt aus Keymaps/Menu-Einträgen aufgerufen — siehe
[Keymaps/Conform.md](../Keymaps/Conform.md):

- `<leader>fm` (global, [lua/bindings/mappings/nvchad.lua](../../../../../lua/bindings/mappings/nvchad.lua))
- `<leader>fm` (buffer-lokal, überschrieben für `markdown`/`mdx`)
- `<leader>aF` (buffer-lokal, nur `astro`)
- Menu-Eintrag "Format Buffer" in [lua/config/menu/custom_menu/init.lua](../../../../../lua/config/menu/custom_menu/init.lua)
