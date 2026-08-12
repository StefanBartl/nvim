# Personal Roadmaps — Audit aller nvim-Plugins (E:\repos)

Stand: 2026-08-11. Alle 33 Neovim-Plugin-Repos unter `E:\repos` durchgegangen: `docs/ROADMAP` (Datei oder Ordner)
komplett gelesen, offene vs. erledigte Punkte gezählt, grober Aufwand geschätzt. IDEAS-Backlogs (wo vorhanden)
separat gezählt, nicht in die Roadmap-Zahlen gemischt.

## Kennzahlen

- **79** offene Roadmap-Tasks über 30 Repos mit `docs/ROADMAP`
- **15 von 30** Repos stehen bei **0** offenen Punkten
- **67** offene IDEAS-Punkte (separat, nur 2 Repos betroffen)
- **3** Repos ganz ohne Roadmap-Doc: `learn-cli.nvim`, `lsp.nvim`, `neotree-fs-refactor.nvim`
- `dm-scratch-out2` ist ein leeres Verzeichnis, nicht mitgezählt

---

## Roadmaps mit echtem Restaufwand (M/L, größter zuerst)

| Repo | Offen | Erledigt | Aufwand | Wichtigste offene Punkte |
|---|---:|---:|---|---|
| `lib.nvim` | 18 | 26 | **L** | `autocmd.dispatcher`-Factory (noch nicht begonnen); `kit.dashboard` + generisches Jump-Target-Konzept (nur Analyse); Linux/macOS-Verifikation für `cross.*`; `fs.collect_recursive`-Lücke; deps.health-Migration + Windows-Elevation-Tests |
| `images.nvim` | 8 | 29 | **L** | Echte Terminal-Capability-Erkennung via XTVERSION; Sixel-Backend; Kitty-APC Inline-Rendering; OCR via `language.nvim`; Flamegraph-Rendering für `runtime-analysis.nvim`; Chart-Rendering für `github_stats.nvim` |
| `filetree.nvim` | 4 | 23 | **L** | Markdown-Link-Bridge zu `markdown.nvim`; buffers-source `dd`=delete Port; mehr Verhaltens-Testabdeckung; Debounce für `get_visible_nodes` bei großen Trees |
| `cascade.nvim` | 1 | 1 | **L** | Renumbering-Marker-Ankersystem (persistente, editor-unabhängige Anker via Extmarks + Fingerprint-Persistenz + JSON-Store) — zurückgestellt bis realer Bedarf |
| `spotlight.nvim` | 9 | 56 | **M** | Benannte "Spotlight-Sets"; Density-Map in Sign-Column/Scrollbar; Per-Window-Opt-out; Match-Zählung über alle Buffer; Statusline-Komponente |
| `cmdlog.nvim` | 9 | 0 | **M** | Notes-per-Favorite Feature (Add/Edit/Delete/Anzeige); Notes-System-Aufbau (Config, Path-Resolution, Buffer-Lifecycle); Bug — nvim-Log wird nicht persistiert; PowerShell-History-Testing |
| `mdview.nvim` | ~4 | ~30 | **M** | Windows Detach/Browser-Tab-Timing-Bug (größter Einzelposten); offene Code-TODOs; Diff-Testing-Task. **Hinweis:** laut eigenem Doc liegt der wirkliche priorisierte Backlog in einer separaten, hier nicht gesichteten `TASKS.md` |
| `diff.nvim` | 4 | 1 | **M** | Directory/Recursive-Diff mit Per-File-Summary; Quickfix/Loclist-Integration; `git:<rev>..<rev>` Range-Spec; UTF-8-codepoint-genauer Word-Diff (niedrige Priorität) |

---

## Kleine, begrenzte Backlogs (S/XS mit offenen Punkten)

| Repo | Offen | Erledigt | Aufwand | Wichtigste offene Punkte |
|---|---:|---:|---|---|
| `documentation.nvim` | 7 | 37 | **S** | Kein luacheck/CI-Lint-Pipeline; Testability-/Automated-Suite-Lücken; einige ❌/🟡 Checklist-Zeilen (viel größerer IDEAS-Backlog separat unten) |
| `migrate.nvim` | 5 | — | **S** | Kein CI-Workflow; rohes `nvim_create_user_command` statt `lib.nvim.usercmd`; keine Migration-Modul-Registry; dünne `@types`-Abdeckung; neue Neovim-Deprecations laufend nachziehen |
| `github_stats.nvim` | 3 | 0 | **S** | Kein CI für stylua/luacheck; `@types/` nach Arch&Coding-Konvention restrukturieren; busted/plenary-Runner tatsächlich zum Laufen bringen |
| `color_my_ascii.nvim` | 2 | 5 | **S** | Weitere eingebaute Color-Schemes; tiefere lib.nvim-Integration (wartet auf API-Stabilisierung) |
| `fileops.nvim` | 2 | 0 | **S** | `git_aware`/`on_hold` Git-Shell-outs auf async `vim.system` umstellen; Integrationstest gegen echte neo-tree/nvim-tree-Instanz in CI |
| `markdown.nvim` | 2 | ~15 | **XS** | Mehr Testabdeckung in `docs/TESTS/`; Handler-`ctx`-Helper-Refactor (bewusst zurückgestellt, geringer Wert) |
| `pdfport.nvim` | 1 | ~6 | **XS** | Kein einheitlicher Window-Lifecycle-Helper — zurückgestellt, nur relevant falls ein 4. fenster-basierter Renderer dazukommt |

---

## IDEAS-Backlogs (separat gezählt, wie gewünscht)

| Repo | Offen | Erledigt | Aufwand | Wichtigste offene Punkte |
|---|---:|---:|---|---|
| `documentation.nvim` | ~52 | 10 | **XL** | Multi-Language-Backend-Support (Python/Rust/Go/C, allein ~20 Checklist-Punkte); ~30 verstreute Ideen (Drift-Checks, OpenAPI-Generierung, GitHub-Pages-Publishing, generisches CLI, Telemetry-Mode); Lua/LuaCATS "Reference Tab"; Desktop/Web-App-Produktform (größtenteils zurückgestellt); Checklist/Task-Runner-Syntax mit Dashboard (kalkuliert, nicht entschieden) |
| `runtime-analysis.nvim` | 15 | 4 | **L** | Churn×Call-Count Refactor/Delete-Queue; Auto-Coverage×Telemetry Hot-Untested-Queue; ein "Runtime"-Tab im ausgelieferten Artefakt von documentation.nvim; Preview-Tab als Report-Stil; gemeinsamer Project-Key über alle drei Plugins |

Sonst hat kein weiteres Repo einen IDEAS-Ordner — case-insensitiv über alle 33 Repos nach `*idea*` gesucht
(ohne `node_modules`, `.git`, `.claude/worktrees`), nur diese beiden Treffer.

---

