# Featurelist  WKD-`harpoon2`-Config

1. Stabiler Project-Key pro Projekt (Git-Root → `cwd`, normalisiert), verhindert „leere“ Listen bei `:cd`/Rooter-Wechseln
2. Projektbezogene Listen mit stabilem Project-Key (Git-Root → `cwd`), dadurch keine „leeren“ Listen bei `:cd`/Rooter-Wechseln
3. Autosave auf Quick-Menu-Close sowie zusätzlich auf `BufLeave`/`FocusLost` (deferred, race-frei)
4. Persistenz ohne Reibung: Autosave beim Schließen des Quick-Menus sowie auf `BufLeave`/`FocusLost`
5. **Persistente Startpfade (Bootstrap):** definierbare Zielpfade werden über `config.harpoon.persistpaths` bei jedem Neovim-Start automatisch in die aktive Harpoon-Liste injiziert, falls die Datei existiert; Einträge sind in der UI normal löschbar, erscheinen beim nächsten Start wieder; robuste Sanitize/Dedup-Logik, plattformübergreifend (inkl. Windows/UNC); Variablen wie `$REPOS_DIR`, `$NVIM_HOME`, `$HOME` werden unterstützt; manuelle Aktualisierung via `:HarpoonPersistPathsReload`.
6. Persistente Startpfade (Bootstrap) mit Variablen-Support (`$REPOS_DIR`, `$NVIM_HOME`, `$HOME`) und Reload via `:HarpoonPersistPathsReload`
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

