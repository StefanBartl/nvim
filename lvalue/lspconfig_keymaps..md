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

## Empfohlene Lua-Konfiguration (NVChad Keymap Beispiel)

```lua
-- LSP Standardfunktionen
map("n", "grn", "<cmd>lua vim.lsp.buf.rename()<CR>", { silent = true, noremap = true, desc = "LSP: Rename Symbol" })
map("n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>", { silent = true, noremap = true, desc = "LSP: Code Action" })
map("n", "gra", "<cmd>lua vim.lsp.buf.code_action()<CR>", { silent = true, noremap = true, desc = "LSP: Code Action" })
map("n", "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<CR>", { silent = true, noremap = true, desc = "LSP: Code Action" })
map("n", "grr", "<cmd>lua vim.lsp.buf.references()<CR>", { silent = true, noremap = true, desc = "LSP: References" })
map("n", "gri", "<cmd>lua vim.lsp.buf.implementation()<CR>", { silent = true, noremap = true, desc = "LSP: Implementations" })
map("n", "gO", "<cmd>lua vim.lsp.buf.document_symbol()<CR>", { silent = true, noremap = true, desc = "LSP: Document Symbols" })
map("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", { silent = true, noremap = true, desc = "LSP: Hover Documentation" })
map("i", "<C-s>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", { silent = true, noremap = true, desc = "LSP: Signature Help" })
map("n", "gq", "<cmd>lua vim.lsp.buf.format({ async = true })<CR>", { silent = true, noremap = true, desc = "LSP: Format Line" })

-- Weitere nützliche LSP-Funktionen
map("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", { silent = true, noremap = true, desc = "LSP: Go to Definition" })
map("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", { silent = true, noremap = true, desc = "LSP: Go to Declaration" })
map("n", "gt", "<cmd>lua vim.lsp.buf.type_definition()<CR>", { silent = true, noremap = true, desc = "LSP: Type Definition" })

-- Navigation durch Diagnostics
map("n", "[d", "<cmd>lua vim.diagnostic.goto_prev()<CR>", { silent = true, noremap = true, desc = "LSP: Previous Diagnostic" })
map("n", "]d", "<cmd>lua vim.diagnostic.goto_next()<CR>", { silent = true, noremap = true, desc = "LSP: Next Diagnostic" })

-- Diagnostic Tools
map("n", "<leader>e", "<cmd>lua vim.diagnostic.open_float()<CR>", { silent = true, noremap = true, desc = "LSP: Show Diagnostic Popup" })
map("n", "<leader>q", "<cmd>lua vim.diagnostic.setloclist()<CR>", { silent = true, noremap = true, desc = "LSP: Set Location List" })
map("n", "<leader>f", "<cmd>lua vim.lsp.buf.format({ async = true })<CR>", { silent = true, noremap = true, desc = "LSP: Format Document" })
```

```lua
-- Beispiel für Lazy Keymap Setup in Neovim mit NVChad
local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

keymap("n", "grn", vim.lsp.buf.rename, opts)
keymap("n", "<leader>rn", vim.lsp.buf.rename, opts)
keymap("n", "gra", vim.lsp.buf.code_action, opts)
keymap("n", "<leader>ca", vim.lsp.buf.code_action, opts)
keymap("n", "grr", vim.lsp.buf.references, opts)
keymap("n", "gri", vim.lsp.buf.implementation, opts)
keymap("n", "gO", vim.lsp.buf.document_symbol, opts)
keymap("n", "K", vim.lsp.buf.hover, opts)
keymap("i", "<C-s>", vim.lsp.buf.signature_help, opts)
keymap("n", "gq", function() vim.lsp.buf.format({ async = true }) end, opts)

-- Weitere Vorschläge
keymap("n", "gd", vim.lsp.buf.definition, opts)
keymap("n", "gD", vim.lsp.buf.declaration, opts)
keymap("n", "gt", vim.lsp.buf.type_definition, opts)
keymap("n", "[d", vim.diagnostic.goto_prev, opts)
keymap("n", "]d", vim.diagnostic.goto_next, opts)
keymap("n", "<leader>e", vim.diagnostic.open_float, opts)
keymap("n", "<leader>q", vim.diagnostic.setloclist, opts)
keymap("n", "<leader>f", function() vim.lsp.buf.format({ async = true }) end, opts)
```

---
