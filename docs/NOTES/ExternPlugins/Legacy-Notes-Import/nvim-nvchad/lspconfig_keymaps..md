## Neovim LSP Keymaps Übersicht (Lua-Tabelle mit deutscher Beschreibung)

| Tasten            | Lua-Funktion                           | Beschreibung (Deutsch)                                          |
| ----------------- | -------------------------------------- | --------------------------------------------------------------- |
| `grn`             | `vim.lsp.buf.rename()`                 | Symbol umbenennen                                               |
| `gra`             | `vim.lsp.buf.code_action()`            | Code-Aktion (z. B. Quickfix, Refactoring)                       |
| `grr`             | `vim.lsp.buf.references()`             | Alle Referenzen dieses Symbols anzeigen                         |
| `gri`             | `vim.lsp.buf.implementation()`         | Implementierungen anzeigen (z. B. Methoden einer Schnittstelle) |
| `gO`              | `vim.lsp.buf.document_symbol()`        | Alle Symbole im aktuellen Dokument anzeigen                     |
| `K`               | `vim.lsp.buf.hover()`                  | Dokumentation zu Symbol unter dem Cursor                        |
| `gq`              | `vim.lsp.buf.format({ async = true })` | Formatieren der aktuellen Zeile (ggf. anpassbar)                |
| `Ctrl-S` (Insert) | `vim.lsp.buf.signature_help()`         | Hilfe zu Funktionsparametern (Signaturhilfe)                    |
| `gd`              | `vim.lsp.buf.definition()`             | Gehe zur Definition eines Symbols                               |
| `gD`              | `vim.lsp.buf.declaration()`            | Gehe zur Deklaration (z. B. globale Variablen)                  |
| `gt`              | `vim.lsp.buf.type_definition()`        | Zeigt den Typ eines Symbols (z. B. Interface)                   |
| `[d`              | `vim.diagnostic.goto_prev()`           | Vorheriger LSP-Fehler (Diagnostic)                              |
| `]d`              | `vim.diagnostic.goto_next()`           | Nächster LSP-Fehler                                             |
| `<leader>e`       | `vim.diagnostic.open_float()`          | Zeigt Fehler-Hinweis (Popup)                                    |
| `<leader>q`       | `vim.diagnostic.setloclist()`          | Öffnet die Lokalliste mit aktuellen Fehlern                     |
| `<leader>f`       | `vim.lsp.buf.format({ async = true })` | Formatieren des gesamten Dokuments (asynchron)                  |

---
