## 1. Begriffe aus Lazy.nvim Startup

| Begriff                    | Erklärung                                                                                                                                                                |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **start**                  | Plugins, die direkt beim Start geladen werden. Sie stehen sofort zur Verfügung, erhöhen aber die Startup-Zeit.                                                           |
| **lazy**                   | Plugins, die auf bestimmte Events, Commands oder FileTypes verzögert geladen werden. Reduziert die anfängliche Startup-Zeit.                                             |
| **very lazy (`VeryLazy`)** | Plugins, die extrem verzögert geladen werden – z. B. erst nach mehreren Sekunden, wenn die UI vollständig geladen ist oder bei bestimmten Benutzeraktionen.              |
| **after**                  | Plugins, die geladen werden, nachdem andere Plugins (meist dependencies) initialisiert wurden. Wird oft für Konfigurationen verwendet, die auf anderen Plugins aufbauen. |
| **rtp plugins**            | Runtime-Path Plugins, also kleine Plugins oder Runtime-Skripte, die in Neovim standardmäßig geladen werden.                                                              |
| **UIEnter**                | Zeitpunkt, an dem die UI fertig gerendert ist. Alles davor zählt zu Startup/Plugin-Ladezeit.                                                                             |

---

## 2. Analyse deiner Plugins

### Plugins mit hoher Ladezeit

| Plugin              | Ladezeit | Kommentar                                   | Optimierung                                                         |
| ------------------- | -------- | ------------------------------------------- | ------------------------------------------------------------------- |
| `neo-tree.nvim`     | 29.38 ms | Dateibrowser, oft direkt beim Start geladen | **lazy/very lazy**: nur bei Command oder File Explorer öffnen laden |
| `vim-wakatime`      | 17.86 ms | Analytics, selten beim Start nötig          | **very lazy**: nur bei Events wie BufRead oder Timer laden          |
| `trouble.nvim`      | 9.78 ms  | Issue/Diagnostics Panel                     | **lazy**: nur bei `:TroubleToggle` oder BufRead geladen werden      |
| `nvim-web-devicons` | 7.57 ms  | Icons für viele Plugins                     | **lazy**: nur zusammen mit Plugins laden, die Icons nutzen          |
| `vim-matchup`       | 6.68 ms  | Syntax-Matching                             | **lazy**: nur bei TextEditing FileTypes                             |
| `translate.nvim`    | 5.89 ms  | Übersetzungstool                            | **very lazy**: nur bei Command verwenden                            |
| `gopath.nvim`       | 6.13 ms  | GOPATH Management                           | **very lazy**: nur bei Go-Projekten laden                           |
| `nvim-dap`          | 12.31 ms | Debug Adapter Protocol                      | **lazy/very lazy**: nur bei Debug-Befehlen laden                    |
| `nvim-containers`   | 6.86 ms  | Container Management                        | **very lazy**: nur bei Container-Commands laden                     |

### Kleine Plugins (<5 ms)

Plugins wie `harpoon`, `snacks.nvim`, `todo-comments.nvim`, `plenary.nvim` verursachen kaum Verzögerung und können sofort geladen bleiben.

---

## 3. Empfehlung für Lazy-Strategie

### Start sofort laden

* Plugins, die essentiell für Editor-Funktionalität sind:

  * `plenary.nvim`
  * `vim-visual-multi` (falls aktiv benötigt)
  * `cmp-nvim-lsp` (wenn Auto-Completion beim Start gebraucht wird)

### Lazy-Load (bei FileType, Commands, Events)

* `neo-tree.nvim` → nur wenn Explorer geöffnet wird (`:Neotree` Command)
* `trouble.nvim` → nur bei `:TroubleToggle` oder BufRead
* `vim-matchup` → nur bei Editing-Events, z. B. `BufRead`
* `nvim-dap` → nur wenn Debugging gestartet wird
* `nvim-treesitter-context` → optional, nur bei Code-Editing aktiv

### Very Lazy (extrem verzögert)

* `vim-wakatime` → Timer/Event-basiert laden
* `translate.nvim` → nur wenn Übersetzungscommand aufgerufen wird
* `gopath.nvim` → nur bei Go-Projekten
* `nvim-containers` → nur wenn Container-Commands genutzt werden
* `snacks.nvim` → selten genutzte Utilities

---

## 4. After-Verwendung

* Nutze `after/plugin/xyz.lua` für Plugins, die auf andere Plugins aufbauen:
  Beispiel: `after/plugin/cmp_nvim_lsp.lua` stellt sicher, dass `cmp` erst konfiguriert wird, nachdem `nvim-lsp` geladen ist.
* `after` erhöht nicht die Startup-Zeit, sondern steuert nur die Reihenfolge der Konfiguration.

---

## 5. Potenzial für Startup-Optimierung

* Mit Lazy-Loading der größten Zeitfresser (`neo-tree`, `vim-wakatime`, `trouble.nvim`) kann man die **Startzeit von ~658 ms auf ~500–550 ms** drücken, je nach Nutzungsmuster.
* Plugins <5 ms sofort laden, spart kaum Zeit.
* VeryLazy-Plugins verschieben nicht kritische Funktionalität weit nach hinten, UI wird schneller verfügbar.

---
