| Repo | Reale Lücke | Infrastruktur | Aufwand |
|---|---|---|---|
| **pickers.nvim** | ~23 von 60 Dateien ungetestet, meist kleine Leaf-Module (`sources/*`, `error.lua`, `config/DEFAULTS.lua`, Command-Wiring). Harness existiert, funktioniert, muss nur erweitert werden. | ✅ vorhanden, gut | **6–10 h** |
| **dap.nvim** | ~35 von 40 Dateien ungetestet, aber 11 davon sind fast identische Sprach-Definitionstabellen (python/go/rust/...) — die lassen sich mit 1–2 generischen Spec-Dateien statt 11 einzelnen abdecken. Core-Logik (state/setup/breakpoints/registry) und utils/* sind gut testbar. | ✅ plenary, passt zum ui.nvim-Muster | **10–15 h** |
| **cmdlog.nvim** | ~29 von 39 Dateien ungetestet, größter Brocken `core/shell.lua` (432 LOC) + `core/favorites.lua` (252). Harness existiert (`check()`), ist aber bisher nur ein Smoke-Test. | ✅ vorhanden, aber kaum genutzt | **8–14 h** |

**Gesamt: ~24–39 Stunden**, also grob 3–5 fokussierte Sessions — wenn man sich (wie documentation.nvim/markdown.nvim es vormachen) auf Logik konzentriert und reine UI/Picker-Rendering-Wrapper (Telescope/fzf/snacks-Adapter, die ohne echten Picker-Backend kaum sinnvoll unit-testbar sind) bewusst ausklammert. Genau dieses Muster fahren die gut getesteten Geschwister auch — documentation.nvim und markdown.nvim testen mit einem eigenen leichten `H.eq/H.ok`-Harness, nicht plenary, und meiden ebenfalls reine Rendering-Pfade.

**Reihenfolge-Empfehlung:** pickers.nvim zuerst (kleinster Aufwand, größter Lücken-Fake-out), dann dap.nvim (Infra passt schon, viele Module lassen sich gebündelt testen), cmdlog.nvim zuletzt (größter echter Nachholbedarf, aber auch größter Einzelbrocken `shell.lua`).
