# Trouble — Keymaps

Registriert in
[lua/bindings/mappings/trouble.lua](../../../../../lua/bindings/mappings/trouble.lua)
(aufgerufen aus `bindings.mappings.init`).

**Wichtig:** `trouble.nvim` bringt selbst **keine** globalen Default-Keymaps
mit. Der Plugin-Spec
([lua/plugins/trouble.lua](../../../../../lua/plugins/trouble.lua)) ruft
`require("trouble").setup({ preview = …, modes = … })` auf — **ohne**
`opts.keys`. Das im README des installierten Plugins
(`nvim-data/lazy/trouble.nvim/README.md`) gezeigte `keys = { … }`-Beispiel
(`<leader>xx`, `<leader>xX`, `<leader>cs`, `<leader>cl`, `<leader>xL`,
`<leader>xQ`) ist nur eine **Empfehlung für die eigene Lazy-Spec** — hier
nicht übernommen. Alle Maps unten sind daher **[custom]**, gesetzt per
`lib.nvim.map` (`vim.g.__map_helper`) direkt in `bindings/mappings/trouble.lua`.

---

## Diagnostics-Views

| Mapping | Aktion | = Command | Status |
|---|---|---|---|
| `<leader>xt` | Diagnostics-Liste togglen | `:Trouble diagnostics toggle` | [custom] |
| `<leader>xx` | Alle Diagnostics | `:Trouble diagnostics` | [custom] |
| `<leader>xw` | Workspace-Diagnostics (`filter.buf=nil`) | `:Trouble diagnostics filter.buf=nil` | [custom] |
| `<leader>xd` | Buffer-Diagnostics (`filter.buf=0`) | `:Trouble diagnostics filter.buf=0` | [custom] |

Hinweis: `<leader>xx` liegt hier auf „alle Diagnostics" (nicht togglend), im
README-Beispiel dagegen auf `diagnostics toggle` — unterschiedliche Bindung
trotz gleicher lhs, weil hier eigenständig vergeben statt aus dem README
übernommen.

## LSP-Views

| Mapping | Aktion | = Command | Status |
|---|---|---|---|
| `<leader>xlr` | References | `:Trouble lsp_references` | [custom] |
| `<leader>xld` | Definitions | `:Trouble lsp_definitions` | [custom] |
| `<leader>xlt` | Type Definitions | `:Trouble lsp_type_definitions` | [custom] |
| `<leader>xli` | Implementations | `:Trouble lsp_implementations` | [custom] |
| `<leader>xls` | Document Symbols | `:Trouble lsp_document_symbols` | [custom] |

## Listen

| Mapping | Aktion | = Command | Status |
|---|---|---|---|
| `<leader>xl` | Location List | `:Trouble loclist` | [custom] |
| `<leader>xq` | Quickfix List | `:Trouble qflist` | [custom] |

## Navigation (nativ, plugin-unabhängig)

| Mapping | Aktion | = Command | Status |
|---|---|---|---|
| `[q` / `]q` | Vorheriger/nächster Quickfix-Eintrag | `:cprevious` / `:cnext` | [custom] |
| `[l` / `]l` | Vorheriger/nächster Location-Eintrag | `:lprevious` / `:lnext` | [custom] |

Diese vier rufen die **nativen** Vim-Commands auf, nicht Trouble-eigene
Funktionen — sie navigieren aber effektiv innerhalb einer offenen
Trouble-Quickfix-/Loclist-Ansicht, da Trouble die native Liste spiegelt.

## Workspace-Diagnostics-Navigation (Trouble v3 API)

| Mapping | Aktion | Status |
|---|---|---|
| `]w` | Nächster Workspace-Diagnostic-Eintrag im offenen Trouble-Fenster (`trouble.next`, `skip_groups=true`, `jump=true`) | [custom] |
| `[w` | Vorheriger Workspace-Diagnostic-Eintrag (`trouble.prev`, analog) | [custom] |

Beide sind No-Ops mit Notify (`[trouble] diagnostics list not open`), wenn
gerade kein Trouble-Diagnostics-Fenster offen ist (`trouble.is_open`).
Bewusst auf `]w`/`[w` statt `]d`/`[d` gelegt, um mit Neovims nativer
Diagnostic-Navigation nicht zu kollidieren (siehe Kommentar im Quellcode).

---

## Im Trouble-Fenster selbst (Plugin-Default)

Aus `nvim-data/lazy/trouble.nvim/lua/trouble/config/init.lua`
(`M.defaults.keys`) — der Plugin-Spec überschreibt `opts.keys` nicht, also
sind diese window-lokalen Maps **[default]** und aktiv, sobald ein
Trouble-Fenster offen ist:

| Taste | Aktion | Status |
|---|---|---|
| `?` | Hilfe | [default] |
| `r` | Refresh | [default] |
| `R` | Auto-Refresh togglen | [default] |
| `q` | Fenster schließen | [default] |
| `o` | Eintrag öffnen + Fenster schließen | [default] |
| `<esc>` | Abbrechen | [default] |
| `<cr>` / `<2-leftmouse>` | Zu Eintrag springen | [default] |
| `<c-s>` | In Split öffnen | [default] |
| `<c-v>` | In Vsplit öffnen | [default] |
| `}` / `]]` | Nächster Eintrag | [default] |
| `{` / `[[` | Vorheriger Eintrag | [default] |
| `dd` (n) / `d` (v) | Eintrag(e) löschen | [default] |
| `i` | Inspect | [default] |
| `p` | Preview | [default] |
| `P` | Preview togglen | [default] |
| `zo`/`zO`/`zc`/`zC`/`za`/`zA`/`zm`/`zM`/`zr`/`zR`/`zx`/`zX`/`zn`/`zN`/`zi` | Fold open/close/toggle/more/reduce/update/enable/disable (je einfach/rekursiv/alle) | [default] |
| `gb` | Aktuellen-Buffer-Filter togglen (Beispiel-Action aus den Defaults) | [default] |
| `s` | Severity-Filter durchschalten (Beispiel-Action aus den Defaults) | [default] |

Deaktivierbar/überschreibbar über `opts.keys` im `setup()` — in dieser
Config nicht gesetzt, die Defaults gelten also unverändert.
