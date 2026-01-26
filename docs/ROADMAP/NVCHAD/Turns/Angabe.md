# Optmierung wkdnvchad als kritisches nvim UI modul

## checklist 1

# 🎯 Optimization Checklist
## Table of content
- [🎯 Optimization Checklist](#optimization-checklist)
  - [High Priority (Apply Now)](#high-priority-apply-now)
  - [Medium Priority (This Week)](#medium-priority-this-week)
  - [Low Priority (Nice to Have)](#low-priority-nice-to-have)
  - [🔴 Kritisch (Sofort)](#kritisch-sofort)
  - [🟡 Wichtig](#wichtig)
  - [🔍 Code Quality](#code-quality)
  - [📚 Dokumentation](#dokumentation)
  - [🎯 Definition of Done](#definition-of-done)
---
## High Priority (Apply Now)
| Status | Optimization | File | Gain |
|--------|-------------|------|------|
| `[ ]` | Local function calls | tabufline/init.lua | 70% |
| `[ ]` | Memoize display_path | lsp/helpers/path.lua | 80% |
| `[ ]` | Cache devicons | file_icons/devicons.lua | 60% |
| `[ ]` | Lazy-load utils | All statusline modules | 50% |
---
## Medium Priority (This Week)
| Status | Optimization | File | Gain |
|--------|-------------|------|------|
| `[ ]` | lib.lazy for nvchad modules | mappings/init.lua | 40% |
| `[ ]` | Debounce statusline updates | lsp/init.lua | 30% |
| `[ ]` | Cache mode_band_group | highlighting.lua | 20% |
| `[ ]` | Pool string operations | formatters.lua | 15% |
---
## Low Priority (Nice to Have)
| Status | Optimization | File | Gain |
|--------|-------------|------|------|
| `[ ]` | lib.memo for LSP symbols | document_symbols.lua | 10% |
| `[ ]` | Inline hot functions | cursor_ctl/renderer.lua | 5% |
| `[ ]` | Remove debug checks | All modules | 3% |
---
## 🔴 Kritisch (Sofort)
| Status | Task | Details |
|--------|------|---------|
| `[ ]` | Zirkuläre Abhängigkeit fixen | Lazy-loading in lsp/init.lua implementiert |
| `[ ]` | Error Handling | Proper pcall |
| `[ ]` | Type Guards | Alle vim.api Calls mit pcall wrappen |
---
## 🟡 Wichtig
| Status | Task | Details |
|--------|------|---------|
| `[ ]` | document_symbols.lua | Config lazy-loaden |
| `[ ]` | formatters.lua | String-Operationen via lib.strings |
| `[ ]` | paths.lua | Cross-platform via lib.cross |
| `[ ]` | highlighting.lua | Nutze lib.ui.hl wenn sinnvoll |
| `[ ]` | LSP Cache | Ersetze durch lib.memo.lru |
| `[ ]` | Module Loading | Nutze lib.lazy statt custom lazy-loading |
| `[ ]` | Safe Notifications | lib.notify.safe in Autocommands |
| `[ ]` | String Transform | lib.strings.transform in formatters |
---
## 🔍 Code Quality
| Status | Task | Details |
|--------|------|---------|
| `[ ]` | @nodiscard | Auf allen Pure Functions |
| `[ ]` | @param/@return | Vollständig dokumentiert |
| `[ ]` | Type Guards | Vor jedem vim.api Call |
| `[ ]` | Error Handling | Alle pcall mit sinnvollem Fallback |
---
## 📚 Dokumentation
| Status | Task | Details |
|--------|------|---------|
| `[ ]` | README.md | Für wkdnvchad/ |
| `[ ]` | API Docs | Public functions dokumentiert |
| `[ ]` | Troubleshooting | Häufige Fehler dokumentiert |
---
## 🎯 Definition of Done
- [ ] Keine `loop or previous error loading module` Errors
- [ ] chadrc.lua < 30 Zeilen
- [ ] Alle @types korrekt
- [ ] README.md vorhanden
- [ ] Statusline funktioniert
- [ ] Fallback zu base config funktioniert


## checklist 2

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

### Vorteile der neuen Struktur
 **Single Point of Removal:** `rm -rf lua/nvchad/` entfernt alle NvChad-Abhängigkeiten
 **Explizite API:** `nvchad/config/chadrc.lua` als Setup-Funktion → User-Config via Parameter
 **Type-Safety:** Zentrale `@types/` + lokale Submodul-Types


## Checkliststs usual

Beachte dabei die ausgearbeiteten Regeln & Leitlinien zu den Themem
- Architektur
- Clean Code
- Sicherheit
- Performance
- uvm...
welche in den Projektdateien  Arch&Coding-Regeln.md & Checklist.md & Zentrale-Prinzipien.md festgehalten sind und in den in den Projektdateien anhängig sind.

## Ziel

1. Überprüfe das modul, ob alles eingehalten wurde
2. Solltest du noch weitere Performance kritische oder Sircherheits relavante optimierungen haben, gerne. Schlag sie einfach vor und rbeite sie aus.
3. Die Typdatei für alle Funktnionen aus meinem Custom nvim/lua/lib moduls ist angehängt. Gerne mit einbeziehen in das refactoring.

