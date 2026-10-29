# filetree.nvim — Live-Checks (Stand 2026-10-29)

Drei Beobachtungen aus `filetree.nvim`, die nur in echtem Neovim mit neo-tree prüfbar sind, weil die
bisherigen Belege headless entstanden (Redraw-Zählung, Stub-Adapter). Jeder Abschnitt gehört zu einer
Task im `tasks-vault` (Area `filetree.nvim`); ist ein Abschnitt durch, die Task mit `done` schließen
(oder Bescheid geben). Ein Befund: unter „Falls rot“ eine Zeile, daraus wird eine `kind: bug`-Task.
Die vierte offene Task der Area (Trash-Batch auf Linux und macOS) steht in
`filetree-trash-batch-performance-2026-09-26.md` im Abschnitt „Neue Live-Checks (Stand 2026-10-29)“.

**Vorher:** Windows-Maschine, echtes Terminal-Neovim (kein headless), neo-tree als Backend,
`filetree.nvim` aktuell (Commit notieren: ______), `:checkhealth filetree` ohne Fehler. Abschnitte 1
und 2 sind Dauerbeobachtungen (Abschnitt 2 eine Woche, Abschnitt 3 einige Wochen) und können parallel
zur normalen Arbeit laufen; hier nur Datum und Ergebnis nachtragen.

---

## 1. Blinken des „modified“-Icons beim Einklappen — offen

Task `filetree.nvim/collapse-blink-live-check`. Code: `adapter.redraw_soon()` (Redraw-Bündelung),
`filetree.nvim@04be623`, `@bb65e90`, Fixes `@0f0274f`, `@c914ed8`. Bisher nur durch Zählen der
Redraws belegt (`TESTS/neotree_collapse_redraw_coalesce.lua`). Die Quellen widersprechen sich: der
UX-Report vom 2026-09-29 nennt das Blinken ein bestätigtes neo-tree-Limit, die Collapse-Blink-Notiz
hält den echten Test offen; dieser Check entscheidet.

Szenario (das Original):

1. Zwei verschachtelte Ordner im Baum offen (`A/B/`), im inneren `A/B/` eine Datei mit
   ungespeicherten Änderungen (Buffer ist modified, Icon im Baum sichtbar).
2. Den äußeren Ordner `A` einklappen.

- [ ] Original-Szenario nachgestellt in einem echten Terminal-Neovim mit neo-tree
- [ ] Beobachtung: blinkt das „modified“-Icon beim Einklappen noch? (ja / nein / manchmal): ______
- [ ] Mehrfach wiederholen (mindestens 5 Mal, auch mit größerem Baum), damit „manchmal“ erkennbar wird

Falls es blinkt:

- [ ] Aufnehmen (Bildschirmaufnahme, Einzelbilder auswerten, siehe die Memory-Notiz zu
      Bildschirmaufnahmen) und festhalten, wie viele Frames das Icon weg ist
- [ ] Entscheiden: weiterer Fix möglich oder Limit endgültig; im zweiten Fall die Plugin-Doku
      anpassen (Limitierung dokumentieren)

Falls es nicht blinkt: Ergebnis festhalten, Task schließen (R6).

Danach: Task `collapse-blink-live-check` mit `done` schließen bzw. Ergebnis in die Task-Notizen.
Hinweis: `Final_Checks/Running-Tasks_Checklist.md` nennt das Blinken ein dokumentiertes Limit ohne
Testbedarf; wenn der Check hier „kein Blinken“ ergibt, diese Zeile entsprechend berichtigen.

---

## 2. Verschwinden die W:/E:-Diagnostik-Badges noch? — offen (frühestens seit 2026-10-26)

Task `filetree.nvim/diag-badges-vanish-live-check`. Code: Feature `lsp_diagnostics`
(`lua/filetree/features/lsp/lsp_diagnostics/`), Fix `filetree.nvim@6707760` (Abo auf
`adapter.on_render`, auf `/` normalisierte Zählschlüssel), Test `TESTS/gaps.lua` (nur Stub-Adapter,
nicht gegen echtes neo-tree). Ausgangsbeobachtung 2026-10-12: beim Fokussieren des Baums erschienen
`W:4` / `W:1` an manchen Nodes und verschwanden wieder.

Vorbereitung: Projekt mit Dateien, die LSP-Warnungen und -Fehler haben (z. B. Lua mit LuaLS und
unbenutzten Variablen), Baum fokussieren. Dann eine Woche normal arbeiten.

- [ ] Eine Woche normal arbeiten (Baum fokussieren, Dateien öffnen und speichern, Ordner auf- und
      zuklappen), Dateien mit Warnungen dabei: die Badges (`E:2 W:1`) bleiben stehen und flackern nicht
      (Zeitraum: von ______ bis ______)
- [ ] **Datei-Nodes** (nicht nur Ordner) zeigen ihre eigenen `E:`/`W:`-Zähler (unter Windows traf das
      vor dem Fix nicht, wegen nicht normalisierter Schlüssel)

Falls es weiter auftritt: Zeitpunkt und Auslöser notieren (Fokuswechsel, Speichern, LSP-Neustart?),
danach `lsp_diagnostics._render` und die neo-tree-Redraw-Wege (`adapter/neotree.lua`, `on_render`)
prüfen. Unterscheiden: ein Diagnostics-Count, der selbst auf 0 springt (LuaLS räumt stale Diagnostics
ab), ist ein anderer Befund als ein gewischter Extmark.

Falls es nicht auftritt: Ergebnis festhalten, Task schließen (R6).

Danach: Task `diag-badges-vanish-live-check` mit `done` schließen bzw. Notiz in der Task.

---

## 3. Stoppt `handle_guard` die Windows-EPERM-Sperre? — Beobachtung läuft

Task `filetree.nvim/handle-guard-eperm-observation` (Art: `research`). Hintergrund
(`docs/FEATURES/BACKENDS.md`): neo-tree lässt Verzeichnis-Watcher-Handles offen, die den Zielpfad
halten; Rename und Move scheitern gelegentlich mit EPERM. `handle_guard` schließt die Handles vor der
Operation. Das Feature ist standardmäßig aus (`opts.features.handle_guard.enabled`, Default `false`)
und in deiner Install-Spec als Experiment eingeschaltet (`Backlog/TASKS/install-spec-history.md`).

Vorbereitung: prüfen, dass es wirklich an ist (Konfiguration von `filetree.nvim`: `handle_guard = {
enabled = true }`), Beobachtungsbeginn eintragen: ______

- [ ] Nach einigen Wochen normaler Nutzung: trat bei Rename oder Move **irgendein** EPERM auf?
      (ja / nein, Anzahl und Datum: ______)
- [ ] Falls ja: **sofort** (solange es hängt) `:Filetree handles` ausführen, die Ausgabe sichern
      (listet getrackte Handles und markiert solche, die auf einen nicht mehr existierenden Pfad
      zeigen, die „Leak-Signatur“), Bug mit dieser Ausgabe anlegen
- [ ] Falls nein: Beobachtung festhalten, Task schließen (R6) und überlegen, `handle_guard` unter
      Windows mit neo-tree standardmäßig einzuschalten (eigene Entscheidung, eigene Task)

Offene Fragen: Die Task nennt keine Mindestdauer außer „a few weeks“; ein Enddatum für die
Beobachtung festlegen, sonst bleibt sie ewig offen. Außerdem: `watcher_quarantine` blendet laut Task
nur die Fehlermeldung aus; ist es parallel aktiv, kann ein EPERM unsichtbar bleiben, das Ergebnis
„keine Fehlermeldung“ ist dann nicht dasselbe wie „keine Sperre“.

Danach: Task `handle-guard-eperm-observation` mit `done` schließen bzw. Beobachtung in den Notizen.
