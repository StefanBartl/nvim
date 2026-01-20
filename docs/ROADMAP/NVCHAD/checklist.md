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

