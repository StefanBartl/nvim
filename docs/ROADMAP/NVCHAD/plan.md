# wkdnvchad Refactoring Checklist

## 🔴 Kritisch (Sofort)

| Status | Task | Details |
|--------|------|---------|
| `[ ]` | Zirkuläre Abhängigkeit fixen | Lazy-loading in lsp/init.lua implementiert |
| `[ ]` | chadrc.lua minimieren | Auf 20 Zeilen reduziert, Logik nach wkdnvchad/config/ |
| `[ ]` | Error Handling | Proper pcall + Fallback in chadrc.lua |
| `[ ]` | Type Guards | Alle vim.api Calls mit pcall wrappen |

## 🟡 Wichtig (Diese Woche)

| Status | Task | Details |
|--------|------|---------|
| `[ ]` | document_symbols.lua | Config lazy-loaden |
| `[ ]` | formatters.lua | String-Operationen via lib.strings |
| `[ ]` | paths.lua | Cross-platform via lib.cross |
| `[ ]` | highlighting.lua | Nutze lib.ui.hl wenn sinnvoll |

## 🟢 Optional (Nächste Woche)

| Status | Task | Details |
|--------|------|---------|
| `[ ]` | LSP Cache | Ersetze durch lib.memo.lru |
| `[ ]` | Module Loading | Nutze lib.lazy statt custom lazy-loading |
| `[ ]` | Safe Notifications | lib.notify.safe in Autocommands |
| `[ ]` | String Transform | lib.strings.transform in formatters |

## 🔍 Code Quality

| Status | Task | Details |
|--------|------|---------|
| `[ ]` | @nodiscard | Auf allen Pure Functions |
| `[ ]` | @param/@return | Vollständig dokumentiert |
| `[ ]` | Type Guards | Vor jedem vim.api Call |
| `[ ]` | Error Handling | Alle pcall mit sinnvollem Fallback |

## 🧪 Testing

| Status | Task | Details |
|--------|------|---------|
| `[ ]` | Load Test | `:lua require("wkdnvchad.ui.statusline.modules.lsp")` |
| `[ ]` | Circular Dep Check | Keine Fehler beim require |
| `[ ]` | Base Config Fallback | Funktioniert bei Fehler |
| `[ ]` | Statusline Render | Breadcrumbs werden angezeigt |

## 📚 Dokumentation

| Status | Task | Details |
|--------|------|---------|
| `[ ]` | README.md | Für wkdnvchad/ |
| `[ ]` | API Docs | Public functions dokumentiert |
| `[ ]` | Migration Guide | Von ui/ zu wkdnvchad/ |
| `[ ]` | Troubleshooting | Häufige Fehler dokumentiert |

## 🗑️ Cleanup

| Status | Task | Details |
|--------|------|---------|
| `[ ]` | custom/tabufline/ | Löschen (nach wkdnvchad/ui/tabufline/) |
| `[ ]` | mappings/nvchad.lua | Löschen (nach wkdnvchad/mappings/) |
| `[ ]` | ui/* | Umbenennen zu wkdnvchad/* |
| `[ ]` | Tote Imports | Grep nach alten Pfaden |

## ✅ Verifizierung

### 1. Module Loading
```lua
:lua require("wkdnvchad.ui.statusline.modules.lsp")
-- Sollte KEINE errors werfen
```

### 2. Config Loading
```lua
:lua = require("chadrc")
-- Sollte Table zurückgeben, nicht error
```

### 3. Statusline Render
```vim
:set statusline?
-- Sollte breadcrumbs zeigen
```

### 4. No Circular Deps
```lua
:lua package.loaded = {} vim.cmd("source ~/.config/nvim/init.lua")
-- Sollte sauber laden
```

## 🎯 Definition of Done

- [ ] Keine `loop or previous error loading module` Errors
- [ ] chadrc.lua < 30 Zeilen
- [ ] Alle @types korrekt
- [ ] README.md vorhanden
- [ ] Tests durchlaufen
- [ ] Statusline funktioniert
- [ ] Fallback zu base config funktioniert
