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

- [ ] lib.nvim - alle module durcgehen und checken, ob docs, @types, als auch aggregatoren noch korrekt sind. Die lib.nvim ist für mich umso mehr wert, umso besser die docs sind. Dabei auch gleich feature ideen einbringenh, sprich bei jedem modul am ende auch checken "fehlt etwass sinnvolles?"
- [ ] Merged_Finished.md in die Rules einbauen: Dsa sind alles Dinge, die wr gefixed haben, daher am besten in Regeln / Checklisten mitaufnehmen
- [ ] nochmal alle keymaps checken, ob kein keymap doppelt vergeben ist, über alles repos hinweg + nvim-config

### Git & Repo-Hygiene
- [ ] Alle Features/Bugfixes committen & pushen (Commit-Message ausgeben, falls Push nicht möglich). — **Zuletzt geprüft 2026-08-26: alle 31 Repos + Config sauber und gepusht; Claude-Branches und `.claude/worktrees/` überall abgeräumt (siehe `Merged_Finished.md`).** Wiederkehrend, bleibt daher stehen.
- [ ] Git-Release pro Repo, sobald fertig.

### MISC

- [ ] claude: "Eine Sache habe ich ins Handover als Arbeitsregel geschrieben, weil sie mir zweimal passiert ist: stylua lua nie über die nvim-Config laufen lassen — sie ist nicht stylua-formatiert, ein Lauf formatiert 141 Dateien nebenbei um." - sollten sie aber schoin sein, also dem nachgehen

---

## Liste B — An Claude Code delegierbar

### Dokumentation & Cheatsheets
- [~] **UseCases/Workflow-Datei pro Plugin** — 32 von 33 Plugins haben eine
      `docs/WORKFLOW.md`; Die Aktualitätsprüfung ist gelaufen und hat die
      Drift woanders gefunden (16 von 18 neuen Config-Keys fehlten in der
      User-Doku, jetzt ergänzt — siehe `Merged_Finished.md`). Offen bleibt
      nur der *inhaltliche* Durchgang: liest sich jeder Workflow noch wie der
      Weg, den man heute tatsächlich geht? Das ist Lesearbeit, keine
      Messung.

### Healthchecks, Config & Defaults
- [~] **`lib.nvim` konsequent als Dependency nutzen** — die Konsistenz-Hälfte
      ist erledigt und nach `Merged_Finished.md` gewandert. Offen ist nur noch
      das **Deduplizieren**; die Analyse ist gelaufen, die Umsetzung nicht.

      Gesucht wurden *identische Funktionskörper* über alle Repos
      (`docs/ROADMAP/tools/duplicate_functions.py`), nicht gleiche Namen:
      gleich heißende Funktionen tun oft Verschiedenes, und die echten
      Duplikate heißen oft verschieden.

      **Zu tun, absteigend nach Wert:**

      - [~] **Markdown-Tabellen-Renderer nach lib** — *lib-Modul steht, die
            beiden Plugins sind noch nicht umgestellt.*

            Es waren nicht drei Funktionen, sondern **siebzehn geteilte**:
            vier byte-identisch, neun weitere nur in Zeilenumbrüchen
            verschieden. Das ist die komplette Parse-und-Render-Engine,
            zweimal.

            Und die vier, die *wirklich* abwichen, sind das eigentliche
            Argument — jede Kopie trug einen Fix, den die andere nicht hatte:

            | | wer war voraus |
            | --- | --- |
            | `parse_row` | buffer-ctx: `gmatch` statt Zeichen-für-Zeichen-`..`, das O(n²) in der Zeilenlänge ist |
            | `trim` | markdown: delegiert an `lib.lua.strings.core` |
            | `resolve_overrides` | buffer-ctx: sammelt Warnungen statt sie zu verschlucken |
            | `format_file` | markdown: beachtet `col_overrides` |

            `lib.nvim.markdown.table` nimmt je die bessere Hälfte, hat Typen
            und einen Spec (`TESTS/markdown_table_spec.lua`), meldet Warnungen
            zurück statt zu notifien und liest keine Config — deshalb konnten
            die Buffer- und File-Ebene mitkommen statt als dritte und vierte
            Kopie liegenzubleiben. Breite bleibt bewusst auf
            `vim.fn.strdisplaywidth`: `lib.lua.strings.width` misst
            ambivalente Zeichen anders, und diese Tabellen landen in echten
            Dateien.

            **Offen:** beide Plugins auf das Modul umstellen, plus
            Modul-README und Eintrag in der lib-Übersicht. Details im
            Handover (`docs/ROADMAP/personal/All/HANDOVER_dedup.md`).
      - [ ] **`deep_merge` + `config.get` in cascade.nvim ↔ spotlight.nvim**
            (12 bzw. 11 Zeilen) — Config-Maschinerie doppelt.
      - [ ] **Kleinkram, wenn ohnehin dort:** `health.check_require`
            (dap ↔ debugging), `version_ok` (documentation ↔
            runtime-analysis), HTML-Escaping, `spawn_env.array`.

      **Bewusst *nicht* zu tun, beides mit Begründung:**

      - `config.M.get` in 6 Plugins — 4 Zeilen Boilerplate. Der Import, die
        Indirektion und die zusätzliche Kopplung kosten mehr, als die vier
        Zeilen sparen.
      - `try_require` in 4 Plugins — hier spricht ein echter Grund dagegen:
        das ist der Soft-Dependency-Helfer. Er muss funktionieren, *ohne* dass
        lib da ist. Ihn nach lib zu ziehen wäre zirkulär.

### Performance
- [ ] **Startup optimieren — erledigt bis auf `lsp.setup()`, siehe `Merged_Finished.md`.** ~1300ms → ~942ms (−27%), eager geladene Plugins 44 → 28. Drei Ursachen, alle gemessen: neo-tree `lazy = false` (zog neotest samt acht Adaptern mit), ein fehlschlagendes `vim.fn.executable("pwsh")` in `options.lua` (~44ms, jede Startup), und `trouble.nvim` `lazy = false` (~79ms + 71ms devicons).
  - **Offen und bewusst separat: `lsp.setup()` ~288ms.** Der mit Abstand größte verbleibende Posten, aber korrektheitskritisch — die Capabilities müssen global stehen, bevor der erste Client attached, und bei `nvim datei.lua` passiert das *während* des Startups. Das Fehlerbild bei einem Fehler ist „Completion ist manchmal kaputt", also subtil und teuer.
    - Aufgeschlüsselt (`lsp.nvim`s `step()` temporär mit Zeitmessung versehen): `build_capabilities` **84ms** — zieht `blink.cmp` beim Start hoch, nur um dessen Capability-Tabelle zu lesen; `languages` **66ms**; Rest verteilt.
    - Ansatz wäre, die blink-Capabilities auf `LspAttach` zu verschieben statt sie beim Start zu holen. Braucht einen Test, der beweist, dass ein Client, der während des Startups attached, die vollen Capabilities bekommt.
  - **Nebenbefund, nicht angefasst:** der WORKSTATION-FREEZE-FIX in `lua/options.lua` (PSModulePath von OneDrive-Pfaden befreien) ist **auskommentiert**. Laut dem Kommentar dort hing daran ein 60-90s-Freeze. Entweder ist er nicht mehr nötig oder er ist versehentlich deaktiviert — das ist deine Entscheidung, nicht meine.
  - **Generelle Erkenntnis, gilt config-weit:** ein *fehlschlagendes* `vim.fn.executable()` läuft unter Windows jeden PATH-Eintrag gegen jede PATHEXT-Endung ab — hier 67 × 11 = 737 Stats, ~44ms — und wird **nicht** gecacht. Ein *erfolgreiches* stoppt beim ersten Treffer (~0.2ms). Jede Probe auf ein nicht installiertes Tool im Startpfad kostet also 44ms. `lib.nvim.core.has_exec` memoisiert, aber nur pro Session, hilft dem ersten Aufruf also nicht.

### Architektur & Strategie (Umsetzung, keine Grundsatzentscheidung)
- [ ] Alle Features eines Plugins den zugehörigen Usrcmds/Keymaps/Autocmds zuordnen, Analyse in `docs/NOTES/PersonelPlugins/TO_CHECK_FEATURES` pro Plugin ablegen (Sortierung nach Wichtigkeit erst nach Klärung der Priorisierungsfrage aus Liste A).

---

