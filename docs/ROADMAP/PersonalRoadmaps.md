# Personal Roadmaps — Audit aller nvim-Plugins (E:\repos)

> Wenn eine Task erledigt ist, dann hier ersatzlos entfernen und ggf. nach `docs/Features` schreiben!

## Roadmaps mit echtem Restaufwand (M/L, größter zuerst)

| Repo | Offen | Erledigt | Aufwand | Wichtigste offene Punkte |
|---|---:|---:|---|---|
| `lib.nvim` | 18 | 26 | **L** | `autocmd.dispatcher`-Factory (noch nicht begonnen); `kit.dashboard` + generisches Jump-Target-Konzept (nur Analyse); Linux/macOS-Verifikation für `cross.*`; `fs.collect_recursive`-Lücke; deps.health-Migration + Windows-Elevation-Tests |
| `spotlight.nvim` | 9 | 56 | **M** | Benannte "Spotlight-Sets"; Density-Map in Sign-Column/Scrollbar; Per-Window-Opt-out; Match-Zählung über alle Buffer; Statusline-Komponente |

---

## IDEAS-Backlogs (separat gezählt, wie gewünscht)

| Repo | Offen | Erledigt | Aufwand | Wichtigste offene Punkte |
|---|---:|---:|---|---|
| `documentation.nvim` | ~52 | 10 | **XL** | Multi-Language-Backend-Support (Python/Rust/Go/C, allein ~20 Checklist-Punkte); ~30 verstreute Ideen (Drift-Checks, OpenAPI-Generierung, GitHub-Pages-Publishing, generisches CLI, Telemetry-Mode); Lua/LuaCATS "Reference Tab"; Desktop/Web-App-Produktform (größtenteils zurückgestellt); Checklist/Task-Runner-Syntax mit Dashboard (kalkuliert, nicht entschieden) |
| `runtime-analysis.nvim` | 15 | 4 | **L** | Churn×Call-Count Refactor/Delete-Queue; Auto-Coverage×Telemetry Hot-Untested-Queue; ein "Runtime"-Tab im ausgelieferten Artefakt von documentation.nvim; Preview-Tab als Report-Stil; gemeinsamer Project-Key über alle drei Plugins |

---

