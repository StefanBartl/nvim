# Featurelist  WKD-`harpoon2`-Config

1. **Eine globale Harpoon-Liste:** `settings.key` ist fest auf `config.harpoon.persist_paths.PINS_KEY` (= `stdpath("config")`) verdrahtet (in `bindings/mappings/harpoon.lua`), statt auf Harpoons Default `vim.loop.cwd()`. Dieselbe Liste ist damit in JEDEM Projekt/Verzeichnis sichtbar — kein „leeres“ Quick-Menu mehr, wenn der cwd von dem Ort abweicht, an dem Marks gesetzt wurden.
2. Umsortieren/Löschen von Einträgen in der UI persistiert projektübergreifend über Neustarts hinweg (Harpoon-Autosave + explizites Save der Persist-Path-Kommandos)
3. Autosave auf Quick-Menu-Close sowie zusätzlich auf `BufLeave`/`FocusLost` (deferred, race-frei)
4. Persistenz ohne Reibung: Autosave beim Schließen des Quick-Menus sowie auf `BufLeave`/`FocusLost`
5. **Persistente Startpfade (Bootstrap):** definierbare Zielpfade (`config.harpoon.persistpaths`) werden in ein festes PINS_KEY-Bucket (`stdpath("config")`, stabil unabhängig vom ambienten `cwd`) einmalig beim allerersten Start auf einer Maschine eingefügt (Marker unter `stdpath("state")`); danach bleibt das Bucket vollständig user-owned - Umsortieren/Löschen in der UI persistiert normal über Neustarts hinweg und wird NICHT automatisch zurückgesetzt. `:HarpoonPersistPaths` fügt fehlende Default-Pfade nachträglich an (Rest bleibt unangetastet), `:HarpoonSetDefaultPaths` setzt das Bucket hart auf `target_specs` zurück. Robuste Sanitize/Dedup-Logik, plattformübergreifend (inkl. Windows/UNC); Variablen wie `$REPOS_DIR`, `$NVIM_HOME`, `$HOME` werden unterstützt.
6. Persistente Startpfade (Bootstrap) mit Variablen-Support (`$REPOS_DIR`, `$NVIM_HOME`, `$HOME`); manuelle Kontrolle via `:HarpoonPersistPaths` (top up) und `:HarpoonSetDefaultPaths` (hard reset)
6a. **`:HarpoonPin [path]` / `:HarpoonUnpin [path]`:** aktuelle Datei (oder Pfad-Argument, mit Datei-Completion) als *dauerhaften* Default aufnehmen bzw. entfernen. Ergänzt die im Code fixen `target_specs` (misc.lua) um maschinenlokale Pins, gespeichert als JSON-Array unter `stdpath("state")/harpoon_user_pins.json` (bewusst NICHT git-getrackt). Gepinnte Datei erscheint sofort in der Liste und zählt danach zu den Defaults, die `:HarpoonSetDefaultPaths` wiederherstellt.
6b. **Pin-Marker im Quick-Menu (`config.harpoon.pin_marks`):** jede Zeile, die einem Default-Pin (statisch + user) entspricht, bekommt einen eol-Marker `📌 pin` (Highlight `HarpoonPinMark`, verlinkt auf `DiagnosticVirtualTextWarn`) — so ist vor dem Umsortieren/`dd` sofort sichtbar, welche Einträge geschützte Defaults sind. Live aktualisiert bei Änderungen im Menü (`TextChanged`).
7. Sanitize der Items: Vereinheitlichung auf `{ value=..., context={row, col} }`, Legacy-Formate werden übernommen
8. Dedup ohne Full-Replace: Duplikate per `fs_realpath`/Pfad-Normalisierung erkennen und sicher entfernen
9. Kein hartes Überschreiben von `list.items` mehr; UI-/Persistenz-Kohärenz bleibt erhalten
10. Start-Up-Reihenfolge abgesichert: Setup → Load → Sanitize/Dedup → Save (deferred)
11. Defensive Fehlerbehandlung/Type-Guards (`safe_call`), keine stillen Fehler im Low-Level
12. Optionale Helfer/Entries für spätere Erweiterungen (z. B. eigener `:HarpoonNormalize`, alternativer Project-Key via LSP)
13. Plattformübergreifende, gekürzte Pfad-Labels für die UI (Home/Unix/Windows-Laufwerk/UNC), z. B. `C:/..../parent/file.ext`, `~/..../p/file`
14. Windows- und UNC-Support: Drive-Letter-Normalisierung, `//SERVER/Share/...` als Root korrekt behandelt
15. Harpoon Quick-Menu inklusive Löschen einzelner Einträge aus der UI
16. FZF-basiertes Harpoon-Menü auf `<C-h>` mit denselben Items/Labels
17. Direktsprünge per `<leader>1`…`<leader>9` auf den n-ten Harpoon-Eintrag
18. Vollbild-Preview per `Alt+1`…`Alt+9`: schreibgeschützt, scroll- und navigierbar, Cursor an letzter bekannter Position, Schließen mit `q`
19. Debug-Kommando `:HarpoonDebug` (Momentaufnahme der Liste inkl. gekürzter Labels)
20. Debug-Snapshot des aktuellen Zustands via `:HarpoonDebug`

---

