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

Dene ausgabe:

```text
Wichtige Entscheidung, die ich getroffen habe: die alten Pfade funktionieren weiter. Es sind 809 Aufrufstellen in 30 Repos — ohne Shim wäre der Umzug ein Flag Day: wer lib.nvim aktualisiert, bevor die Plugins nachgezogen sind, hat alles kaputt, und die Reihenfolge bestimmt der Plugin-Manager. Jetzt leiten die alten Pfade weiter und melden einmalig vim.deprecate. Verifiziert für alle sechs tatsächlich benutzten Einstiegspunkte: alt und neu liefern dasselbe Modul-Table. Die Shims fliegen raus, sobald die Repos migriert sind.
```

Eigentlch nicht notwednig, wenn alle 809 aufrustlelne der require pfad angepast weird, waws mti grep bzw cli tols zum rena ing eigentlich kein großer aufewand sein dürft. Da lalle meine repos, auch die lib.nvim  - npoch im development mode ist und auch in der ersten zeile der dere nreadme steht, das breaking changes sehr wahrscheinlich sind an diesen pujnkt der entwicklung, halte ich einen shim für nicht notwenidig. siehst du das anders?

---

## Liste B — An Claude Code delegierbar

### Dokumentation & Cheatsheets
- [ ] UseCases/Workflow-Datei pro Plugin (typischer Workflow + Edge Cases); vorhandene auf Aktualität prüfen.

### Bindings, Keymaps & UI
- [ ] Alle Keymaps/Features zusätzlich via Usrcmd ausführbar machen. Es kann natürlich sein, dass bei iningen dass nicht möglich oder sinnvoll ist. das ist nicht als MUSS gemeint, sondern einfach als qualitätsmerkaml der plugins - als solches soll es behandlet werden. also nicht zwingend, aber einen grund wenn nicht.

#### Neues lib.nvim Modul für Keymaps + umbennenug

1. Wie für autocmds und usrcmds wil ich auch eine lib.nvim modul für keymaps haben. Aber wekchen Zweck hätte das? Nur ein wrapper über nvim_create_keymap?

  Für usrcmds und autocmds gibt es eine lib.nvim modul um deren umsetzung einfacher zu machen und zu standardisieren, zb autocompletion bei usrcmds oder dispatcher bei den autocmds. Für keymaps könnte es sein:
  - Keymaps user-seitig modifizierbar (anderes mapping ermöglchen)/deaktivierbar machen. (via installations spec).
  also, ein Modul, dass automatisch eine tabel oder ähnliches hinterlegt und via key in der user spec modifizierbar macht, die der user via spec ansteuern kann, zb.:

    ```lua
    {
      keymaps = {
        "[a": "]u", -- das mapping des plugins, dass `[a` ist soll auf `]u` umgeschrieben werden
      }
    }
    ```

das schaut zwar schräh aus mit diesen key, aber ich hab keine gute idee für eine alternative. man müsste mit dieser schreibwei´ße abe sicherstellen, dass nur das [a mapüpjg aus diesem einen repo geändert werden würde, wenn [a nicht gemppt ist opder von einen anderen feature eines anderen plugins, dann dürfte es nicht überschierben. abe vl fält dir noch ein besseres optionm. ein. Natülch könnte man auch Bezeichnungen nemmen, wie "copy_absolute_path" -was wsrch sinnvoller ist, aber danmn muss jedes mappng einen sionnvolen namen erhalten ka wie aufwendig da swöre

- Der Pfad soll sein: E:\repos\lib.nvim\lua\lib\nvim\bindings\keymap
- Docs mpüssen geschreiben werden
- Brainstorming nach weoiteren Feature ideen für diese modul: Was könnten wir anbeiten, dwo user sich denken "Dieses fetaure ist toll und bringt mir mehrwert"
- Alle meine .nvim Plugins auf dieses Modul umstellen

#### Umbennenung + Pfad Update

Die bisherigen Module:
  E:\repos\lib.nvim\lua\lib\nvim\autocmd
  E:\repos\lib.nvim\lua\lib\nvim\usercmd
auf
  E:\repos\lib.nvim\lua\lib\nvim\bindings\autocmd
  E:\repos\lib.nvim\lua\lib\nvim\bindings\usercmd
umbennen

- Alle meine .nvim Plugins updaten, die eines der beiden Module implementieren

#### autocmds

- [ ] Autocmds aller Ordner in einem `bindings/autcmd`-Ordner zusammenführen, nach Events sortiert (Dispatch-Lib-Modul), Abgleich mit `/bindings`.

### Healthchecks, Config & Defaults
- [ ] Möglichst viele Features user-konfigurierbar machen, inkl. LuaLS-Typen/Aliases für jeden Config-Key.
- [ ] `lib.nvim` konsequent als Dependency nutzen: Funktionen migrieren/deduplizieren, inkl. Konsistenz-Fixes wie `notify` als Factory (`.create()`) korrekt verwenden.

### Performance
- [ ] **Startup optimieren — erledigt bis auf `lsp.setup()`, siehe `Merged_Finished.md`.** ~1300ms → ~942ms (−27%), eager geladene Plugins 44 → 28. Drei Ursachen, alle gemessen: neo-tree `lazy = false` (zog neotest samt acht Adaptern mit), ein fehlschlagendes `vim.fn.executable("pwsh")` in `options.lua` (~44ms, jede Startup), und `trouble.nvim` `lazy = false` (~79ms + 71ms devicons).
  - **Offen und bewusst separat: `lsp.setup()` ~288ms.** Der mit Abstand größte verbleibende Posten, aber korrektheitskritisch — die Capabilities müssen global stehen, bevor der erste Client attached, und bei `nvim datei.lua` passiert das *während* des Startups. Das Fehlerbild bei einem Fehler ist „Completion ist manchmal kaputt", also subtil und teuer.
    - Aufgeschlüsselt (`lsp.nvim`s `step()` temporär mit Zeitmessung versehen): `build_capabilities` **84ms** — zieht `blink.cmp` beim Start hoch, nur um dessen Capability-Tabelle zu lesen; `languages` **66ms**; Rest verteilt.
    - Ansatz wäre, die blink-Capabilities auf `LspAttach` zu verschieben statt sie beim Start zu holen. Braucht einen Test, der beweist, dass ein Client, der während des Startups attached, die vollen Capabilities bekommt.
  - **Nebenbefund, nicht angefasst:** der WORKSTATION-FREEZE-FIX in `lua/options.lua` (PSModulePath von OneDrive-Pfaden befreien) ist **auskommentiert**. Laut dem Kommentar dort hing daran ein 60-90s-Freeze. Entweder ist er nicht mehr nötig oder er ist versehentlich deaktiviert — das ist deine Entscheidung, nicht meine.
  - **Generelle Erkenntnis, gilt config-weit:** ein *fehlschlagendes* `vim.fn.executable()` läuft unter Windows jeden PATH-Eintrag gegen jede PATHEXT-Endung ab — hier 67 × 11 = 737 Stats, ~44ms — und wird **nicht** gecacht. Ein *erfolgreiches* stoppt beim ersten Treffer (~0.2ms). Jede Probe auf ein nicht installiertes Tool im Startpfad kostet also 44ms. `lib.nvim.core.has_exec` memoisiert, aber nur pro Session, hilft dem ersten Aufruf also nicht.

### Architektur & Strategie (Umsetzung, keine Grundsatzentscheidung)
- [ ] Featureliste: welche bereits implementierten Features sind noch nicht user-seitig konfigurierbar? Auflisten, strittige Fälle markieren für Rückfrage.
- [ ] Alle Features eines Plugins den zugehörigen Usrcmds/Keymaps/Autocmds zuordnen, Analyse in `docs/NOTES/PersonelPlugins/TO_CHECK_FEATURES` pro Plugin ablegen (Sortierung nach Wichtigkeit erst nach Klärung der Priorisierungsfrage aus Liste A).

---

