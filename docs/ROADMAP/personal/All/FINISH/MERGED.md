# Merged Roadmap — CDX.md + CHECKLIST.md + FINISH_ME.md + Meins.md

Zusammengeführt und dedupliziert aus den vier Ursprungslisten. Zwei Listen:

- **A — Braucht dich**: Claude Code kann höchstens zuarbeiten/vorschlagen, Entscheidung oder Durchführung liegt bei dir.
- **B — An Claude Code delegierbar**: kannst du als Auftrag geben, wenig bis nichts von dir nötig.

Innerhalb jedes Themenblocks sortiert nach vermutlichem Aufwand/Nutzen-Verhältnis (günstige Quick-Wins zuerst).

Gilt für "alle Plugins" = alle Einträge in `lua/plugins/personal/source.lua`.

---

## Liste A — Braucht dich

### Architektur-Entscheidungen (danach Umsetzung an Claude delegierbar)
- [ ] Priorisierungsfrage klären: wie entscheiden wir, welche `TO_CHECK_FEATURES`-Einträge wichtig sind — Einschätzung vs. `:RATelemetry`-Daten? Grundsatzentscheidung, danach kann Claude die Listen pro Plugin abarbeiten.
- [ ] `lua/config/menu` nach `lua/wkdnvchad`? — Namensentscheidung nötig, bevor irgendwer umbenennt.
- [ ] Welche Autocmds gehören stattdessen in ein eigenes Projekt unter `docs/ROADMAP/IDEAS`? (inhaltliche Zuordnung, nicht mechanisch entscheidbar)
- [ ] `docs/NEOTREE_FEATURES`-Ordner durchgehen und bewerten, was mit den Einträgen passiert.
- [ ] Bewertung, ob ein Plugin sich als "Source" für Neotree eignet (wie Tabliste im Filebrowser) — Architektur-Grundsatzentscheidung.
- [ ] Evaluieren, ob Plugin(-Teile) als kompilierte Binaries sinnvoll wären — Architekturentscheidung.
- [ ] Was fehlt, um nvchad komplett zu ersetzen? — strategische Bewertung; Claude kann zuarbeiten, Entscheidung bei dir.

### Live-Testing (braucht laufende, interaktive nvim-Session)
- [ ] CDX: jedes Keymap/Usrcmd/Autocmd in echter nvim-Instanz durchtesten, ob Fehler geworfen werden. (Claude kann einen Testrunner vorbereiten, das Beobachten in Echtzeit ist deine Domäne — außer wir bauen dafür einen headless-Test.)
- [ ] `:Recommender perf` durch alle Module laufen lassen und Ergebnisse sichten. (Ausführen + Sichten = du; die daraus resultierenden Fixes = delegierbar, siehe Liste B.)
- [ ] `<leader>wq`: alle damit auffindbaren Issues live durchgehen und beobachten. (Das Refactoring der `wq`-Logik nach `lib.nvim.ui` selbst ist delegierbar, siehe Liste B.)

### Sonstiges
- [ ] README.md mit Video-Demo oder GIF ausstatten (Aufnahme/Schnitt nur durch dich).

---

## Liste B — An Claude Code delegierbar

### Dokumentation & Cheatsheets
- [ ] `doc/{NAME}.txt` (vimdoc) pro Plugin erstellen.
- [ ] `docs/FEATURES.md` bzw. `docs/FEATURES/`-Ordner pro Plugin nach Format von `documentation.nvim/docs/FEATURES_FORMAT.md` befüllen.
- [ ] UseCases/Workflow-Datei pro Plugin (typischer Workflow + Edge Cases); vorhandene auf Aktualität prüfen.
- [ ] `TelemetryReport.md` neu generieren.

### Bindings, Keymaps & UI
- [ ] Alle Keymaps/Features zusätzlich via Usrcmd ausführbar machen.
- [ ] Keymaps user-seitig modifizierbar/deaktivierbar machen. (via installations spec)
- [ ] `lib.nvim.selection` (`reselect_lines`/`keep_lines`/`reselect_chars`/`keep_chars`) bei jedem Visual-Mode-Mapping anwenden, das die Selektion verliert.
- [ ] Autocmds pro Plugin und global (`nvim/lua/autocmds`) durchgehen und auf Optimierungspotential prüfen.
- [ ] Autocmds aller Ordner in einem `/autcmd`-Ordner zusammenführen, nach Events sortiert (Dispatch-Lib-Modul), Abgleich mit `/bindings`.

### Healthchecks, Config & Defaults
- [ ] Möglichst viele Features user-konfigurierbar machen, inkl. LuaLS-Typen/Aliases für jeden Config-Key.
- [ ] `lib.nvim` konsequent als Dependency nutzen: Funktionen migrieren/deduplizieren, inkl. Konsistenz-Fixes wie `notify` als Factory (`.create()`) korrekt verwenden.

### Security, Tests & CI/CD
- [ ] Plugins auf sicherheitsrelevante Aspekte prüfen und härten.
  - **Erste Runde erledigt (2026-08-25), siehe `Merged_Finished.md`.** Drei Klassen abgearbeitet, alle mit reproduziertem Befund: Ausführung beim *Preview* (cmdlog — beide Previewer führten den Eintrag unter dem Cursor aus, plus eine Vim-Command-Injection über `:help x | …`), Credentials in `argv` (`lib.nvim.net.curl`, reposcope — Token im Prozess-Listing nachgewiesen) und Credentials in Log/`:messages`/auf Platte (reposcope, `gh-debug.txt` schrieb bei *jedem* Request). Dazu Pfad-Sanitisierung für API-Felder, die zu Dateinamen werden (reposcope readme_cache).
  - **Offen: die übrigen Klassen.** Nicht systematisch durchgesehen: Pfad-Traversal in den Datei-Operationen (filetree trash/link/copy_move, pdfport), vorhersagbare Temp-Dateien (Symlink-Race), `expand()`/`glob()` mit Backticks auf Werten aus Datei-/Bufferinhalt, mdviews Relay-Oberfläche (laut eigener `SECURITY.md` gehärtet, aber nicht von mir gegengeprüft), und die Frage, ob persistierte Stores (github_stats, cmdlog, reposcope) je Secrets aufnehmen können, die die `redact_patterns` nicht fangen.

### Performance
- [ ] `nvim/init.lua` durchgehen und optimieren.
- [ ] Ergebnisse aus `:Recommender perf` (nachdem du sie erzeugt hast) in konkrete Fixes umsetzen.
- [ ] Module/Funktionen identifizieren, die von FFI/C profitieren würden (Startup, Runtime-Analysis, Docmap), und Umsetzung vorschlagen/implementieren.

### Architektur & Strategie (Umsetzung, keine Grundsatzentscheidung)
- [ ] Analyse: welche Plugin-Dependencies (z. B. nvzone menu) durch eigene `lib.nvim`-Module ersetzbar wären.
- [ ] Feature-Liste für `filetree.nvim` aus anderen Filetree-Plugins (Neotree/NvimTree/Netrw) ableiten, `docs/ROADMAP/NEOTREE_FEATURES.md` anlegen.
- [ ] Featureliste: welche bereits implementierten Features sind noch nicht user-seitig konfigurierbar? Auflisten, strittige Fälle markieren für Rückfrage.
- [ ] Pro offenem ROADMAP-Punkt einen konkreten Umsetzungsplan ausarbeiten.
- [ ] Alle Features eines Plugins den zugehörigen Usrcmds/Keymaps/Autocmds zuordnen, Analyse in `docs/NOTES/PersonelPlugins/TO_CHECK_FEATURES` pro Plugin ablegen (Sortierung nach Wichtigkeit erst nach Klärung der Priorisierungsfrage aus Liste A).

### Git & Repo-Hygiene
- [ ] Alle Claude-Branches in allen Plugins entfernen.
  - Stand 2026-08-25: 26 von 28 weg. Offen bleiben nur die zwei jüngeren als 3 Tage — `markdown.nvim/claude/busy-ardinghelli-d059d7` (+1) und `open.nvim/claude/cool-benz-a3f6a1` (+2), letzterer hat noch einen Worktree unter `.claude/worktrees/`. Sobald sie alt genug sind: gleiche Behandlung — Commits nach `main`, dann löschen.
- [ ] Alle Features/Bugfixes committen & pushen (Commit-Message ausgeben, falls Push nicht möglich).
- [ ] Git-Release pro Repo, sobald fertig.

---

*Quelldateien (CDX.md, CHECKLIST.md, FINISH_ME.md, Meins.md) bleiben unangetastet in diesem Ordner liegen — sag Bescheid, falls sie gelöscht/archiviert werden sollen.*
