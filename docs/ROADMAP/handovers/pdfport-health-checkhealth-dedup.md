# pdfport.nvim & Geschwister: doppelte `:checkhealth`-Zeilen (lib.nvim.deps)

**Status:** Phase A umgesetzt und live (3 von 4 Repos gepusht). Phase B bewusst offen.
**Ausgangspunkt:** `docs/ROADMAP/personal/All/FINISH/ERLEDIGT/2026-09-12-pdfport-health-und-ghostscript-paths.md`
(dorthin verschoben, dort steht die ursprüngliche, mittlerweile veraltete Analyse).

## Was die alte Analyse falsch eingeschätzt hat

Der Report vom 2026-09-12 behauptete: in `pdfport.nvim/health.lua` seien nur
Chrome+soffice auf `lib.nvim.deps` migriert, 13 weitere Tools liefen noch
über das alte, handgeschriebene `check_exe` — reine Architektur-Hygiene ohne
Nutzen, images.nvim/mdview.nvim/migrate.nvim ungeprüft.

Beim genauen Lesen des aktuellen Quelltexts (nicht nur des Reports) stellte
sich heraus: das stimmte nicht (mehr). Bereits seit Commit `8b1c9c5`
(2026-08-09, über einen Monat vor dem Report) hatte `pdfport.nvim/health.lua`
zusätzlich einen `check_deps()`-Aufruf, der über
`lib.nvim.deps.health.report_for("pdfport.nvim")` **alle** in
`docs/install.json` deklarierten Tools generisch durchmeldet — **additiv**
zu den längst bestehenden handgeschriebenen Einzel-Checks für exakt
dieselben Tools. Ergebnis: `:checkhealth pdfport` zeigte jedes Tool
**zweimal** mit unterschiedlichem Wortlaut (z.B. "pandoc producer: ready
(engine: xelatex)" UND separat "pandoc found").

Dasselbe Muster bestand, verifiziert im Quelltext, in allen drei anderen
Plugins, die `lib.nvim.deps.health`s eigener Modul-Docstring als Ziel-
Konsumenten nennt:

| Plugin | dupliziertes Tool(s) |
|---|---|
| pdfport.nvim | alle 15 aus `docs/install.json` |
| images.nvim | magick, tesseract, pdftoppm |
| mdview.nvim | curl |
| migrate.nvim | rg |

`report_for()` deckte in keinem der vier Fälle auch nur ein einziges Tool
ab, das nicht schon handgeschrieben geprüft wurde — reine Dopplung, kein
Migrations-Rückstand. Referenz für die saubere Lösung: `casedesk.nvim`
filtert die an `from_tools()` übergebene Liste (Chrome raus, weil es einen
eigenen, spezifischeren Check bekommt) und vermeidet dadurch jede Dopplung.

## Schlachtplan (wie umgesetzt)

**Phase A — Duplikate entfernen.** Neue, schmale Funktion
`lib.nvim.deps.health.pointer_for(plugin_name)`: gleiche Lookup-/No-op-Logik
wie `report_for`, aber ohne die Tool-Schleife — druckt nur die
"Run :Lib deps show ..."-Zeile. Die vier Plugins rufen jetzt `pointer_for`
statt `report_for` auf.

- Aufwand real: ~1 Sitzung (kleiner als die alte ~1-Sitzung-pro-Plugin-
  Schätzung, weil kein Tool migriert werden musste — nur eine Zeile pro
  Plugin plus eine neue lib.nvim-Funktion).
- Verifiziert per Headless-Probe (`vim.health` gestubbt, `require("<plugin>.health").check()`
  direkt aufgerufen, vor/nach Diff verglichen) gegen die tatsächlich unter
  `nvim-data/lazy/` installierten Kopien — keine doppelten Zeilen mehr, der
  Hinweis-Satz bleibt erhalten.
- luacheck + `stylua --check` grün auf allen geänderten Dateien.

**Phase B — Ghostscript `paths`/Wildcard.** Unverändert offen, im alten
Report akkurat beschrieben und gegengeprüft (`gs` hat weiterhin kein
`paths` in `docs/install.json`). Empfehlung bleibt: nichts tun (Option 3),
bis ein zweiter Fall mit demselben Muster (versionierter Windows-
Installpfad) auftaucht — dann als generisches Feature in `lib.nvim.deps`,
nicht nur für `gs`.

## Fortschritt

| Repo | Datei(en) | Status |
|---|---|---|
| lib.nvim | `lua/lib/nvim/deps/health.lua`, `@types/init.lua`, `README.md`, `docs/API/commands-and-infra.md` | ✅ gepusht (`71e6d77`), lazy-Install per Fast-Forward aktualisiert |
| pdfport.nvim | `lua/pdfport/health.lua` | ✅ gepusht (`3eac716`), lazy-Install auf diesen Stand zurückgesetzt |
| images.nvim | `lua/images/health.lua` | ✅ gepusht (`ba880ee`), lazy-Install auf diesen Stand zurückgesetzt |
| mdview.nvim | `lua/mdview/health.lua` | ✅ gepusht (`29d7de4`), lazy-Install auf diesen Stand zurückgesetzt |
| migrate.nvim | `lua/migrate/health.lua` | ⚠️ Fix lokal committet (`0ad9967` in `nvim-data/lazy/migrate.nvim`), **Push schlug fehl: Repo ist auf GitHub archiviert (403, read-only)**. Vom Nutzer bestätigt: bewusst gestrichen/archiviert, kein Fehler. Keine weitere Aktion nötig — der lokale Commit bleibt harmlos ungepusht in einem ohnehin nicht mehr in `lua/plugins/personal/init.lua` deklarierten, verwaisten Lazy-Ordner liegen. |

## Nebenbefund beim Sync (erledigt, informativ)

Die lazy-installierten Kopien von pdfport.nvim/images.nvim/mdview.nvim
hatten stark divergierte, überholte Historien (`git pull` erzeugte
"add/add"-Konflikte auf fast jeder Datei). Ursache: ein History-Rewrite
auf GitHub zu einem früheren Zeitpunkt — dieselben Commit-Messages
(z.B. "fix(luals): pdfport.nvim to zero -- 61 -> 0") existieren in
`E:\repos\<plugin>` unter anderen Hashes. Kein Code-Verlust; nach
Rückfrage per `git merge --abort` + `git reset --hard origin/main`
bereinigt. Falls das bei einem künftigen Sync wieder auftritt: derselbe
Griff ist sicher, weil `E:\repos\<plugin>` die autoritative, bereits
gepushte Quelle ist und diese Lazy-Ordner reine Laufzeit-Deployments sind.

## Offene Punkte für die nächste Sitzung

- Phase B (Ghostscript) bleibt bewusst liegen — kein Zeitdruck.
- Kein weiterer Handlungsbedarf bei migrate.nvim.
