# Featurelist  WKD-`harpoon2`-Config

1. Stabiler Project-Key pro Projekt (Git-Root → `cwd`, normalisiert), verhindert „leere“ Listen bei `:cd`/Rooter-Wechseln
2. Autosave auf Quick-Menu-Close sowie zusätzlich auf `BufLeave`/`FocusLost` (deferred, race-frei)
3. Sanitize der Items: Vereinheitlichung auf `{ value=..., context={row, col} }`, Legacy-Formate werden übernommen
4. Dedup ohne Full-Replace: Duplikate per `fs_realpath`/Pfad-Normalisierung erkennen und sicher entfernen
5. Plattformübergreifende, gekürzte Pfad-Labels für die UI (Home/Unix/Windows-Laufwerk/UNC), z. B. `C:/..../parent/file.ext`, `~/..../p/file`
6. FZF-basiertes Harpoon-Menü auf `<C-h>` mit denselben Items und Labels; Fallback auf Harpoon-Quick-Menu ohne FZF
7. FZF-Aktionen: Enter (edit), Ctrl-v (vsplit), Ctrl-x (split), Ctrl-t (tab); Preview via `bat` oder `cat`
8. Windows- und UNC-Support: Drive-Letter-Normalisierung, `//SERVER/Share/...` als Root korrekt behandelt
9. Debug-Kommando `:HarpoonDebug` (Momentaufnahme der Liste inkl. gekürzter Labels)
10. Defensive Fehlerbehandlung/Type-Guards (`safe_call`), keine stillen Fehler im Low-Level
11. Kein hartes Überschreiben von `list.items` mehr; UI-/Persistenz-Kohärenz bleibt erhalten
12. Start-Up-Reihenfolge abgesichert: Setup → Load → Sanitize/Dedup → Save (deferred)
13. Optionale Helfer/Entries für spätere Erweiterungen (z. B. eigener `:HarpoonNormalize`, alternativer Project-Key via LSP)
14. **Persistente Startpfade (Bootstrap):** definierbare Zielpfade werden über `config.harpoon.persistpaths` bei jedem Neovim-Start automatisch (idempotent) in die aktive Harpoon-Liste injiziert, falls die Datei existiert; Einträge sind in der UI normal löschbar, erscheinen beim nächsten Start wieder; robuste Sanitize/Dedup-Logik, plattformübergreifend (inkl. Windows/UNC); Variablen wie `$REPOS_DIR`, `$NVIM_HOME`, `$HOME` werden unterstützt; manuelle Aktualisierung via `:HarpoonPersistPathsReload`.

-

