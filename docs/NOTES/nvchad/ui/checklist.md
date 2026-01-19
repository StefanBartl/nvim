# Refactoring-Plan für ui/ und nvchad/-Modul-Integration

* `lsp_based/init.lua` < 200 Zeilen
* Alle Funktionen haben `@nodiscard`, `@param`, `@return`
* Keine direkten vim.api-Aufrufe ohne Guards in symbols.lua

`chadrc.lua` wird zum Thin-Wrapper, der nur Setup-Logik aus `nvchad/config/chadrc.lua` aufruft.

### lsp Modularisierung

| Status | Prüfschritt | Details |
|--------|-------------|---------|
| `[ ]` | symbols.lua erstellt | Alle TS/LSP-Funktionen verschoben |
| `[ ]` | formatters.lua erstellt | Ellipsize, Icon-Helfer extrahiert |
| `[ ]` | init.lua reduziert | < 200 Zeilen, delegiert an Submodule |
| `[ ]` | Type Guards vorhanden | pcall vor jedem vim.api-Aufruf |
| `[ ]` | @nodiscard auf allen Pure Functions | Keine fehlenden Annotationen |

### chadrc.lua Wrapper

| Status | Prüfschritt | Details |
|--------|-------------|---------|
| `[ ]` | base.lua mit Defaults | Deep-mergeable Struktur |
| `[ ]` | chadrc.lua als Setup-Funktion | User-Config via Parameter |
| `[ ]` | Statusline-Modul-Registrierung | Breadcrumbs, Cursor, Progress |
| `[ ]` | Public API exportiert | set/toggle/get_cursor_progress_mode |
| `[ ]` | lua/chadrc.lua < 30 Zeilen | Nur Thin-Wrapper |

### Tabufline + Mapping

| Status | Prüfschritt | Details |
|--------|-------------|---------|
| `[ ]` | nvchad/tabufline/init.lua | Buffer-Navigation ohne Centering |
| `[ ]` | nvchad/mappings/init.lua | Alle NvChad-Keymaps |
| `[ ]` | custom/tabufline/ gelöscht | |
| `[ ]` | mappings/nvchad.lua gelöscht | |

### Type-Konsolidierung

| Status | Prüfschritt | Details |
|--------|-------------|---------|
| `[ ]` | nvchad/@types/init.lua | Zentrale Public Types |
| `[ ]` | Submodul-@types/ lokal | Nur interne Types |
| `[ ]` | @module-Tags aktualisiert | 'nvchad.X' statt 'ui.X' |

### Clean-up

| Status | Prüfschritt | Details |
|--------|-------------|---------|
| `[ ]` | Keine toten Requires | Grep nach alten Pfaden |

## Vorteile der neuen Struktur

* **Single Point of Removal:** `rm -rf lua/nvchad/` entfernt alle NvChad-Abhängigkeiten
* **Explizite API:** `nvchad/config/chadrc.lua` als Setup-Funktion → User-Config via Parameter
* **Type-Safety:** Zentrale `@types/` + lokale Submodul-Types

