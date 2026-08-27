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
- [ ] `TelemetryReport.md` neu generieren. **Braucht deine echte Nutzung, nicht meine.** Die Telemetrie-Zähler leben pro Session im Speicher; headless erzeugt der Report „nichts lief". Nach einer Weile normalem Arbeiten ist es ein Einzeiler:
      `:RATelemetry export C:/Users/StefanBartl/AppData/Local/nvim/docs/ROADMAP/TelemetryReport.md` (`.md` wählt Markdown, sonst JSON). Für mehrere Namespaces: `:RATelemetry export-all <dir>`. Danach kann ich das „und dann implementieren" übernehmen.

  Datensätze:
    1) Aus der workstation: C:\Users\bartl\AppData\Local\nvim\docs\Telemetry
    2) TelemetryReport von früheren Stadium: C:\Users\bartl\AppData\Local\nvim\docs\Telemetry\Reports
    3) Neuer Export:

- [ ] `<leader>wq`: alle damit auffindbaren Issues live durchgehen und beobachten. (Das Refactoring der `wq`-Logik nach `lib.nvim.ui` selbst ist delegierbar, siehe Liste B.)

### Sonstiges
- [ ] README.md mit Video-Demo oder GIF ausstatten (Aufnahme/Schnitt nur durch dich).
- [ ] Pro offenem ROADMAP-Punkt einen konkreten Umsetzungsplan ausarbeiten.

## Ganz zum Schluss erst erledigen - wenn alles fertig ist

- [ ] Merged_Finished.md in die Rules einbauen: Dsa sind alles Dinge, die wr gefixed haben, daher am besten in Regeln / Checklisten mitaufnehmen

### Git & Repo-Hygiene
- [ ] Alle Features/Bugfixes committen & pushen (Commit-Message ausgeben, falls Push nicht möglich). — **Zuletzt geprüft 2026-08-26: alle 31 Repos + Config sauber und gepusht; Claude-Branches und `.claude/worktrees/` überall abgeräumt (siehe `Merged_Finished.md`).** Wiederkehrend, bleibt daher stehen.
- [ ] Git-Release pro Repo, sobald fertig.

### lib.nvim shim zu bindings\

- [x] **Erledigt 2026-08-27, und ja: du hattest recht.** Die Shims sind weg,
      alle 30 Repos sind migriert, alle 29 Plugins laden ohne sie. Der Shim
      war als *Zwischen*stufe richtig -- die Reihenfolge des Nachziehens
      bestimmt der Plugin-Manager, nicht du -- aber seine eine Aufgabe ist
      erledigt, und pre-1.0 mit Breaking-Changes-Hinweis in Zeile 1 der README
      braucht keine Kompatibilitaetsschicht, die ihre eigene Migration
      ueberlebt. Details in `Merged_Finished.md`.

---

## Liste B — An Claude Code delegierbar

### Dokumentation & Cheatsheets
- [ ] UseCases/Workflow-Datei pro Plugin (typischer Workflow + Edge Cases); vorhandene auf Aktualität prüfen.

### Bindings, Keymaps & UI
- [x] **Alle Keymaps/Features zusätzlich via Usrcmd ausführbar machen —
      geprüft 2026-08-27, keine Lücke.** Über alle 29 Plugins ist jede
      deklarierte Keymap-Action über ein Kommando erreichbar; es gibt keinen
      Fall, für den ein "Grund, warum nicht" nötig wäre. Nachgemessen statt
      geschätzt: die Keymap-Registry kennt seit der Umstellung jede Action,
      der Composer jede Route. Kandidaten aus dem automatischen Abgleich
      waren alle falsch positiv, weil eine Route mit typisiertem Argument
      viele Actions abdeckt, ohne eine davon beim Namen zu nennen
      (`:Open firefox`, `:File next vsplit`, `:File! delete`). Report +
      wiederverwendbares Audit-Skript:
      `docs/NOTES/PersonelPlugins/BINDINGS/keymap-command-parity.md`.

#### Neues lib.nvim Modul für Keymaps + umbennenug

- [x] **Erledigt 2026-08-27.** `lua/lib/nvim/bindings/keymap` steht, ist eine
      Registry statt eines Wrappers, und 26 Plugins sind umgestellt; drei sind
      es bewusst nicht (gopath, runtime-analysis, documentation -- jeweils mit
      Grund). Deine Frage zur Schreibweise ist zugunsten von *Aktionsnamen*
      entschieden, weil `"[a": "]u"` nicht sagen kann, wessen `[a` gemeint ist.
      Umbenennung `autocmd`/`usercmd` nach `bindings/` inklusive.
      Vollstaendige Aufstellung -- Features, gefundene Bugs, was neu
      konfigurierbar wurde -- in `Merged_Finished.md`.

#### autocmds

- [ ] Autocmds aller Ordner in einem `bindings/autcmd`-Ordner zusammenführen, nach Events sortiert (Dispatch-Lib-Modul), Abgleich mit `/bindings`.

### Healthchecks, Config & Defaults
- [~] **Möglichst viele Features user-konfigurierbar machen, inkl.
      LuaLS-Typen — erster Durchgang erledigt 2026-08-27.** Alle 21 klaren
      Fälle aus der Featureliste sind umgesetzt: 12 Plugins, jeder neue Key
      mit unverändertem Default und LuaLS-Typ. Dabei fiel auf, dass
      `github_stats.setup()` **jede** Option außer `repos` still verwarf,
      sobald eine config.json existierte (die das Plugin selbst schreibt) —
      ohne diesen Fix wären die neuen Keys dort unerreichbar geblieben.
      Die 4 strittigen Fälle, die dir vorlagen, sind entschieden und
      umgesetzt (Sparklines über `nerd_font.chars`, reposcope bleibt,
      sandbox bekommt `max_error_length`, der Logger nimmt die Kappungen
      pro Aufruf).

      **Durchgang zwei ist ebenfalls durch** (2026-08-27): 43 Zahlen ohne
      Namen, 47 Plattform-Verzweigungen. Ergebnis war nicht "43 neue Keys" —
      26 der 43 sind Float-Größen (`vim.o.columns * 0.8`) in neun Plugins,
      also *eine* Entscheidung. Gelöst in `lib.nvim`s `make_scratch`, das
      jetzt Bruchteile nimmt (`width = 0.8`); die Konvention stand bereits in
      `kit.layout`. Die Plattform-Verzweigungen sind fast durchweg Tatsachen
      über das OS, keine Präferenzen — dafür steckte in ihnen ein echter Bug
      (`du -sb` ist GNU-only, auf macOS/BSD blieb die Größenspalte still
      leer). Report: `docs/NOTES/PersonelPlugins/zahlen-ohne-namen.md`.

      Offen und bewusst niedrig priorisiert: die 26 Aufrufstellen auf die
      kurze Form umstellen (rein mechanisch, funktionieren unverändert
      weiter) und zwei Timeout-Paare zusammenführen, die denselben Wert
      doppelt führen.
- [ ] `lib.nvim` konsequent als Dependency nutzen: Funktionen migrieren/deduplizieren, inkl. Konsistenz-Fixes wie `notify` als Factory (`.create()`) korrekt verwenden.

### Performance
- [ ] **Startup optimieren — erledigt bis auf `lsp.setup()`, siehe `Merged_Finished.md`.** ~1300ms → ~942ms (−27%), eager geladene Plugins 44 → 28. Drei Ursachen, alle gemessen: neo-tree `lazy = false` (zog neotest samt acht Adaptern mit), ein fehlschlagendes `vim.fn.executable("pwsh")` in `options.lua` (~44ms, jede Startup), und `trouble.nvim` `lazy = false` (~79ms + 71ms devicons).
  - **Offen und bewusst separat: `lsp.setup()` ~288ms.** Der mit Abstand größte verbleibende Posten, aber korrektheitskritisch — die Capabilities müssen global stehen, bevor der erste Client attached, und bei `nvim datei.lua` passiert das *während* des Startups. Das Fehlerbild bei einem Fehler ist „Completion ist manchmal kaputt", also subtil und teuer.
    - Aufgeschlüsselt (`lsp.nvim`s `step()` temporär mit Zeitmessung versehen): `build_capabilities` **84ms** — zieht `blink.cmp` beim Start hoch, nur um dessen Capability-Tabelle zu lesen; `languages` **66ms**; Rest verteilt.
    - Ansatz wäre, die blink-Capabilities auf `LspAttach` zu verschieben statt sie beim Start zu holen. Braucht einen Test, der beweist, dass ein Client, der während des Startups attached, die vollen Capabilities bekommt.
  - **Nebenbefund, nicht angefasst:** der WORKSTATION-FREEZE-FIX in `lua/options.lua` (PSModulePath von OneDrive-Pfaden befreien) ist **auskommentiert**. Laut dem Kommentar dort hing daran ein 60-90s-Freeze. Entweder ist er nicht mehr nötig oder er ist versehentlich deaktiviert — das ist deine Entscheidung, nicht meine.
  - **Generelle Erkenntnis, gilt config-weit:** ein *fehlschlagendes* `vim.fn.executable()` läuft unter Windows jeden PATH-Eintrag gegen jede PATHEXT-Endung ab — hier 67 × 11 = 737 Stats, ~44ms — und wird **nicht** gecacht. Ein *erfolgreiches* stoppt beim ersten Treffer (~0.2ms). Jede Probe auf ein nicht installiertes Tool im Startpfad kostet also 44ms. `lib.nvim.core.has_exec` memoisiert, aber nur pro Session, hilft dem ersten Aufruf also nicht.

### Architektur & Strategie (Umsetzung, keine Grundsatzentscheidung)
- [x] **Featureliste "implementiert, aber nicht konfigurierbar" — erstellt
      2026-08-27.** 45 Kandidaten in 15 Repos, sortiert in *klar
      konfigurierbar machen* (21), *bleibt Konstante, mit Grund* (9, u. a.
      Base64-Alphabet, `MIN_NVIM`, Telemetrie-Fingerprint) und **strittig,
      Rückfrage (6)**. Die sechs stehen im Report und warten auf deine
      Antwort — es sind Geschmacks-/Zielgruppenfragen, keine technischen.
      Report + Skript:
      `docs/NOTES/PersonelPlugins/nicht-konfigurierbare-features.md`.
      Ehrlich dazugesagt, was der Scan *nicht* sieht: Zahlen ohne Namen
      (`vim.defer_fn(fn, 60)`) und Plattform-Verzweigungen ohne Opt-out.
- [ ] Alle Features eines Plugins den zugehörigen Usrcmds/Keymaps/Autocmds zuordnen, Analyse in `docs/NOTES/PersonelPlugins/TO_CHECK_FEATURES` pro Plugin ablegen (Sortierung nach Wichtigkeit erst nach Klärung der Priorisierungsfrage aus Liste A).

---

