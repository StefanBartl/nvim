# Aufschlüsselung

**Nutzen plenary.nvim tatsächlich als eigenen Test-Harness** (Busted-Stil `describe`/`it`, `PLENARY_DIR`/`PLENARY_PATH` nötig zum Laufen) — **11 Repos**:
`ai.nvim`, `casedesk.nvim`, `dap.nvim`, `data.nvim`, `github_stats.nvim`, `gitsuite.nvim`, `hover.nvim`, `lsp.nvim`, `my.nvim`, `rules.nvim`, `sandbox.nvim`

**Erwähnen "plenary" im Testbaum, aber aus anderen Gründen** (kein eigener Harness — eigener Runner/Dialekt A) — **7 Repos**:
| Repo | Grund |
|---|---|
| `documentation.nvim` | `plenary.async`/`plenary.job` tauchen nur als **Fixture-Inhalt** auf (Testdaten für die eigene Call-Graph-Extraktion, simuliert ein fremdes Projekt) |
| `filetree.nvim` | prüft, ob `plenary.nvim` als **neo-tree's eigene** Dependency als Sibling-Checkout vorhanden ist (Integrationstest für den neo-tree-Adapter) |
| `fileops.nvim` | gleiches Muster — Dependency-Check für neo-tree, nicht für den eigenen Harness |
| `pickers.nvim` | prüft, dass **telescopes eigener** generierter Plugin-Spec `plenary` korrekt als Dependency listet |
| `cmdlog.nvim` | prüft optional, ob **telescopes eigene** plenary-Dependency auf dem rtp verfügbar ist (Smoke-Test, framework-frei) |
| `runtime-analysis.nvim` | "plenary" steht nur in einem **Fixture-String**, der eine echte Neovim-Startup-Log-Zeile simuliert |
| `media.nvim` | nur ein Kommentar, der erklärt, dass der Harness bewusst **kein** plenary nutzt |

Sechs weitere Repos (`gopath.nvim`, `images.nvim`, `mdview.nvim`, `pdfport.nvim`, `replacer.nvim`, `spotlight.nvim`) hatten in meiner ersten groben Suche nur false positives — dort steht nur "kein plenary/busted" in der Doku, keine tatsächliche Nutzung.
