# pdfport.nvim health.lua: unvollständige Migration & Ghostscript ohne `paths`

## ANALYSSE DES REPORTS

### Punkt 1: 13 Tools in `pdfport.nvim/health.lua` migrieren (+ images/mdview/migrate.nvim)

**Kosten:** ~1 Sitzung geschätzt (Report), aber mechanisch mit Sorgfaltsbedarf, weil sich die `h_info`/`h_warn`-Texte durch den generischen Reporter ändern — d.h. echter Testlauf nötig, nicht nur Diff lesen. Für alle 4 Plugins zusammen eher 2–4 Sitzungen, nicht eine.

**Nutzen:** Kein einziger bekannter oder gemessener Bug. Alle 13 Tools (pdftotext, tesseract, pandoc, magick, qpdf, pdftk, …) werden via scoop/choco/pip/cargo installiert, die PATH selbst erweitern — genau die Fälle, für die `check_exe` (reines PATH) korrekt funktioniert. Der einzige indirekte Nutzen: Single-Source-of-Truth-Konsistenz mit `docs/install.json`, und ein geschlossenes Drift-Risiko (falls später mal jemand einem dieser Tools ein `paths`-Fallback in `install.json` spendiert, ohne dass `health.lua` es automatisch mitbekäme — analog zum Chromium-Bug, aber spekulativ, kein akuter Fall).

**Einschätzung:** Kosten/Nutzen-Faktor schlecht — reale Entwicklungszeit gegen null User-Nutzen heute. Ich würde das **nicht** als eigene Sweep-Sitzung ansetzen. Sinnvoller: opportunistisch mitziehen, wenn man `health.lua` eines dieser Plugins ohnehin aus anderem Grund anfasst — nicht proaktiv jetzt.

### Punkt 2: Ghostscript `paths`/Wildcard-Problem

**Kosten:** Kein triviales Ein-Zeiler-Fix. `candidate_paths()` müsste Wildcard-Erkennung bekommen (`vim.fn.glob(..., true)` statt `vim.fn.expand()`), **plus** eine Versions-Auswahllogik bei mehreren Treffern — und lexikographisches Sortieren ist bei Ghostscript-Versionsnummern (`gs10.9.0` vs. `gs9.56.1`) nachweislich falsch, bräuchte also echten Semver-Vergleich. Das ist ein Core-Library-Change mit Edge-Cases, eher "klein bis mittel" plus Testaufwand als reines "klein".

**Nutzen:** `gs` ist laut `install.json`s eigenem `why`-Text explizit der am wenigsten kritische der drei Producer (`pdfport.merge()` Fallback #3, "last resort"). Kein gemessener Fall, dass das je gebraucht wurde.

**Einschätzung:** Kosten/Nutzen-Faktor ebenfalls schlecht — Fix für ein rein hypothetisches Problem an einem Low-Priority-Producer. Report-Empfehlung (Option 3: nichts tun, bis ein zweiter Fall mit demselben Muster auftaucht) ist genau richtig — dann lohnt sich die generische Lösung in `lib.nvim.deps`, weil sie mehreren Plugins nutzt statt nur `gs`.

### Fazit

Beide Punkte: **nicht aktiv angehen.** Punkt 1 nur opportunistisch mitnehmen, wenn eine der vier `health.lua`-Dateien ohnehin aus anderem Grund geändert wird. Punkt 2 erst, wenn ein zweiter Fall mit versioniertem Windows-Installpfad auftaucht — der Report dokumentiert das sauber genug, um es einfach liegen zu lassen.

## Intro

**Datum:** 2026-09-12
**Auslöser:** Nachfrage im Chat zur Chrome/soffice-`paths`-Session (siehe
`project_lib_nvim_deps_paths` im Claude-Memory) — zwei Punkte, die dabei
bewusst *nicht* umgesetzt wurden, hier kurz dokumentiert statt nur im
Chat-Verlauf zu stehen.

Betroffene Repos: `pdfport.nvim`, `lib.nvim`. Keine Code-Änderung in diesem
Report — reine Bestandsaufnahme + Einschätzung, falls das mal angegangen
werden soll.

---

## 1. `pdfport.nvim/lua/pdfport/health.lua`: nur Chrome + soffice migriert

Im Rahmen der Chrome/soffice-Session wurden in `health.lua` genau zwei
Stellen auf `lib.nvim.deps.detect` umgestellt (Commit
[`25e77af`](https://github.com/StefanBartl/pdfport.nvim/commit/25e77af)):
der Chromium-Browser-Check und der `soffice`-Check. Alles andere in dieser
Datei läuft weiterhin über die alte, hausgemachte `check_exe(name,
required)`-Hilfsfunktion (Zeile 21), die nur `platform.has(name)` — also
reines PATH — probiert:

| Zeile | Tool | Aufruf |
|---|---|---|
| 116 | `pdftotext` | `check_exe("pdftotext", false)` |
| 146 | `marker_single` | `check_exe("marker_single", false)` |
| 162 | `ollama` | `check_exe("ollama", false)` |
| 177 | `tesseract` | `check_exe("tesseract", false)` |
| 191 | `curl` | `check_exe("curl", false)` |
| 224 | `img2pdf` | `check_exe("img2pdf", false)` |
| 230 | `magick` | `check_exe("magick", false)` |
| 236 | `pandoc` | `check_exe("pandoc", false)` |
| 238 | PDF-Engine-Kette | `platform.first_available({"tectonic","typst","xelatex","lualatex","pdflatex"})` |
| 251 | `weasyprint` | `check_exe("weasyprint", false)` |
| 279 | `qpdf` | `check_exe("qpdf", false)` |
| 285 | `pdftk` | `check_exe("pdftk", false)` |
| 291 | `gs`/`gswin64c`/`gswin32c` | `platform.first_available({...})` (siehe Abschnitt 2) |
| 324 | `pdftoppm` | `check_exe("pdftoppm", false)` |
| 333 | `chafa` | `check_exe("chafa", false)` |

**Warum bewusst nicht angefasst:** Der Auftrag war explizit "weitere Plugins
mit Chrome/soffice-Abhängigkeit prüfen" — für alle 13 Tools oben gibt es
keinen bekannten oder gemessenen "installiert, aber PATH fehlt"-Fall (das
sind CLI-Tools, die normalerweise via scoop/choco/pip/cargo installiert
werden und PATH selbst erweitern). Eine Migration wäre hier reine
Architektur-Hygiene, kein Bugfix.

**Was eine volle Migration bedeuten würde:** `lib.nvim.deps.health` wurde
laut eigenem Modul-Docstring genau für diesen `check_exe`/`probe`-Ersatz
gebaut ("hand-rolled in every consuming plugin's own health.lua today —
pdfport.nvim, images.nvim, mdview.nvim, migrate.nvim, …"). `casedesk.nvim`
nutzt das bereits (`deps_health.from_tools(...)` in seiner eigenen
`health.lua`, mit Chrome als Sonderfall für eine spezifischere Meldung —
exakt das Muster, das man auch hier übernehmen könnte). Für pdfport.nvim
hieße das:

- `check_exe` komplett entfernen.
- Alle o.g. Tools (bis auf `gs`, `chrome`/Chromium, `pdf-engine`-Kette und
  `marker_single`/Python-Sachen, die Sonderfälle bleiben) aus
  `docs/install.json` einlesen und über `require("lib.nvim.deps.health"
  ).from_tools(...)` reporten lassen — eine Zeile statt ~13
  Einzel-`if`-Blöcken.
- `marker_single`, die PDF-Engine-Kette (5 Alternativen) und der
  Python-Modul-Check (`platform.has_python_module`) bräuchten eigene
  `Lib.Deps.HealthEntry`-Einträge (`python_module`-Feld gibt es dafür schon)
  bzw. blieben Sonderfälle, weil `docs/install.json` sie so nicht 1:1
  abbildet.
- **Geschätzter Aufwand:** klein bis mittel (~1 Sitzung) — mechanisch,
  aber mit sorgfältigem Testlauf, weil die Wortwahl der Meldungen sich
  ändert (`h_info`/`h_warn`-Texte sind aktuell hand-formuliert, der
  generische Reporter hat sein eigenes Format).
- **Gleiches gilt für `images.nvim`, `mdview.nvim`, `migrate.nvim`** —
  laut `lib.nvim.deps.health`s eigenem Docstring dieselbe unmigrierte
  Situation, nicht im Rahmen dieser Session geprüft.

## 2. Ghostscript (`gs`) bekam bewusst kein `paths`

`docs/install.json` deklariert `gs` mit `bin_alternatives: ["gswin64c",
"gswin32c"]` (Windows-Namensvarianten), aber **kein** `paths`-Fallback —
im Unterschied zu `chrome`/`soffice`, die beide jetzt einen haben.

**Das Problem:** Ghostschrifts Standard-Installationspfad unter Windows ist
**versioniert**: `C:\Program Files\gs\gs10.03.1\bin\gswin64c.exe` (die
genaue Versionsnummer ändert sich mit jedem Ghostscript-Release und ist
nicht vorhersagbar).

**Warum der aktuelle `paths`-Mechanismus das nicht sicher kann:**
`lib.nvim.deps.detect.candidate_paths()` ruft für jeden deklarierten Pfad
`vim.fn.expand(path)` auf (siehe
[`detect.lua`](https://github.com/StefanBartl/lib.nvim/blob/main/lua/lib/nvim/deps/detect.lua)).
Das funktioniert für feste `$ENVVAR`-Platzhalter einwandfrei — aber
`vim.fn.expand()` behandelt einen Pfad mit Wildcard (`*`) standardmäßig als
Glob und gibt bei **mehreren Treffern einen einzigen, durch Newline
verketteten String** zurück, keine Liste. Ein Pfad wie
`"$PROGRAMFILES\\gs\\gs*\\bin\\gswin64c.exe"` würde also bei zwei
installierten Ghostscript-Versionen zu einem String wie
`"C:\...\gs10.02.0\...\nC:\...\gs10.03.1\..."` expandieren — und
`vim.fn.executable()` auf diesen kaputten String angewendet liefert `0`
(nicht gefunden), *still* falsch statt sauber fehlzuschlagen. Genau die Art
Bug, die dieses Ecosystem sonst vermeidet ("measured rather than assumed").

**Mögliche Lösungswege** (keiner davon umgesetzt, nur skizziert):

1. `candidate_paths()` in `lib.nvim.deps.detect` um Wildcard-Erkennung
   erweitern: enthält ein deklarierter Pfad `*`, `vim.fn.glob(path, false,
   true)` (mit `list = true`) statt `vim.fn.expand()` verwenden, das
   korrekt eine Lua-Liste aller Treffer liefert. Erfordert zusätzlich eine
   Entscheidung, welcher Treffer bei mehreren installierten Versionen
   gewinnt (neueste Version? erster alphabetisch/lexikographisch? — bei
   Ghostscript-Versionsnummern wie `gs10.9.0` vs. `gs9.56.1` ist rein
   lexikographische Sortierung z.B. bereits falsch).
2. Alternative ohne Kern-Änderung: `gs`s eigener Producer
   (`producers/ghostscript.lua`) bekommt einen kleinen, hausgemachten
   Versions-Scan (`vim.fn.glob` direkt, neueste Version wählen) — analog zu
   dem, was für Chrome/soffice jetzt zentral in `lib.nvim.deps` sitzt, aber
   diesmal bewusst lokal, weil die Versionierung ein Ghostscript-Spezifikum
   ist, kein allgemein wiederverwendbares Muster.
3. Nichts tun (aktueller Stand): `gs` bleibt PATH-only. Nutzer, die
   Ghostscript nicht selbst zu PATH hinzufügen, sehen weiterhin
   "ghostschrift producer: no gs/gswin64c/gswin32c on PATH", obwohl es
   installiert ist — bei `gs` ist das laut `docs/install.json`s eigenem
   `why`-Text ohnehin nur "pdfport.merge() fallback #3 (last resort)",
   also der am wenigsten kritische der drei Producer.

**Empfehlung:** Option 3 (nichts tun) bleibt vertretbar, solange niemand
den Ghostschrift-Fallback tatsächlich braucht und er fehlschlägt. Option 1
lohnt sich erst, wenn ein zweiter Fall mit demselben Muster (versionierter
Windows-Installpfad) auftaucht — dann als generisches Feature in
`lib.nvim.deps`, nicht nur für `gs`.

---

## Kurzfassung

| Was | Repo | Status |
|---|---|---|
| Chrome + soffice in `health.lua` migriert | pdfport.nvim | ✅ erledigt (`25e77af`) |
| 13 weitere Tools in `health.lua` noch auf altem `check_exe` | pdfport.nvim | Offen, kein Bug — reine Architektur-Hygiene, ~1 Sitzung geschätzt |
| Gleiches Muster vermutlich auch hier | images.nvim, mdview.nvim, migrate.nvim | Offen, nicht geprüft |
| Ghostscript ohne `paths` (versionierter Pfad) | pdfport.nvim | Bewusst ausgelassen, drei Lösungswege skizziert, keiner umgesetzt |
