# OCR von strukturierten (JSON-)Log-Screenshots — Analyse aus Sicht von casedesk.nvim (2026-09-30)

> Ausschließlich die casedesk-Seite. Die Frage "sollte images.nvim ein
> anderes/zusätzliches OCR-Backend bekommen" ist ein separater Punkt, den der
> Nutzer eigenständig mitbringt — hier nur so weit erwähnt, wie es die
> Abgrenzung "was geht rein in casedesk, was nicht" braucht.

## Ausgangslage

Referenzbild: [`assets/Beispiel_failed_login_errorlog.png`](./assets/Beispiel_failed_login_errorlog.png)
(Original: `$REPOS_DIR/WKDBook-Tricentis/Cases/SAP_Support/Cases/Open/1201484/assets/fourth/failed_login_errorlog.png`).

Ein typischer Kunden-Screenshot dieser Art ist **kein Fließtext**, sondern
**NDJSON** (ein Serilog-artiges strukturiertes Log, eine vollständige
JSON-Zeile pro Eintrag: `Timestamp`/`Level`/`MessageTemplate`/`TraceId`/
`SpanId`), monospace gesetzt, mit sehr langen Zeilen, die im Screenshot am
rechten Rand umbrechen bzw. abgeschnitten sind. Vereinzelt sind
Stack-Traces eingebettet, deren `\r\n` als LITERALE Zeichenfolge innerhalb
eines JSON-String-Werts steht (kein echter Zeilenumbruch).

`$NVIM_CONFIG_DIR/docs/ROADMAP/reports/ocr.md` dokumentiert einen
Vergleich: Windows Snipping Tools "Text-Aktionen" (moderner
On-Device-Texterkenner) vs. `:Case ocr`/`images.nvim`s Standard-Tesseract-
Lauf. Befund dort: Snipping Tool nahezu fehlerfrei inkl. korrekter
Zeilen-/JSON-Struktur, Tesseract-Standardlauf zerlegt Zeilen in Spalten,
liest sie vertikal durcheinander, viele Zeichenfehler (`0`↔`@`, `d`↔`F`
u. Ä.).

## Ist-Zustand in casedesk.nvim

`lua/casedesk/ocr.lua` ist ein dünner Wrapper um `images.ocr` (Soft
Dependency, `pcall`-guarded):

```lua
images.run(path, { lang = opts.lang }, function(text, err) ... end)
```

Ergebnis landet unverändert (nur `images.ocr.to_lines` — Trailing
Whitespace/Leerzeilen bereinigt, sonst roh) als `<bild>.ocr.md`-Sidecar
neben dem Bild. **Keine** Nachbearbeitung, keine JSON-Rekonstruktion, keine
Validierung. `:Case ocr [--force] [--lang=<code>]` ist der einzige
Einstiegspunkt (`bindings/usrcmds.lua:509`).

Wichtig: `images.ocr.M.run` akzeptiert bereits `opts.args` (zusätzliche
Tesseract-CLI-Argumente, `images/ocr.lua:146`, Zeile 172-175) —
**casedesk reicht das heute nirgends durch.** `ocr.lua:222` gibt nur
`{ lang = opts.lang }` weiter. Das ist der günstigste, sofort nutzbare
Hebel, der aktuell brachliegt.

## Eigene empirische Nachprüfung

Tesseract lokal vorhanden (`v5.5.3`), direkt gegen das Referenzbild
getestet, `--psm` (Page Segmentation Mode) variiert — Tesseracts Standard
ist `--psm 3` ("fully automatic page segmentation"), genau das, was laut
`ocr.md` die Spalten/Zeilen durcheinanderbringt:

| PSM | Bedeutung | Ergebnis (Zeilenstruktur) |
| --- | --- | --- |
| 3 (Default) | Automatische Layout-Erkennung | Wie in `ocr.md` beschrieben: Zeilen in Blöcke zerschnitten, JSON-Struktur komplett verloren |
| 4 | Eine Spalte variabler Textgrößen | Identisch zu PSM 3 auf diesem Bild — keine Verbesserung |
| **6** | **Einheitlicher Textblock** | **Jede Ausgabezeile beginnt korrekt mit `{"Timestamp":...}`, 27 Zeilen Output ≈ die tatsächliche Zeilenzahl im Bild (inkl. Stack-Trace-Zeilen)** |
| 11 | Sparse Text, keine bestimmte Reihenfolge | Deutlich schlechter, Wörter isoliert |

PSM 6, erste Zeile (zum Vergleich mit dem Default-Ergebnis in `ocr.md`):

```text
{" Timestamp” :"2026-09-29T16: 48: 26. 2359416+02:00", "Level": "Error”,"MessageTemplate”:"User could not be associated with any of the existing connections.”,"Traceld":"c966fdda20deef6df6b771acS79CF
```

**Befund:** Die Zeilen-/Objektstruktur ist mit `--psm 6` schon massiv
näher an der Wahrheit — das ist exakt das Problem, das `ocr.md` als
Hauptunterschied zum Snipping Tool benennt ("Zerschneidet die Zeilen in
Spalten … Zusammenhang komplett verloren"). Was bei JEDER PSM-Einstellung
bestehen bleibt: **Zeichenfehler** — typografische Anführungszeichen
(`"`/`'` statt `"`), `0`↔`@`, `d`↔`F`/`ll` , `l`↔`1`-Verwechslungen. Das ist
eine reine Modell-/Font-Erkennungsgrenze von Tesseracts LSTM-Engine bei
dieser Schriftart/Auflösung, keine Segmentierungsfrage — hier hilft kein
`--psm`.

## Was rein casedesk-seitig erreichbar ist

Drei unabhängige, jede für sich sinnvolle Verbesserungsebenen, alle ohne
Eingriff in images.nvim:

### 1. `opts.args`/Preset durchreichen (klein, sofort machbar)

`ocr.lua`s `M.run` bekommt einen dritten Opt (`args`, oder ein benanntes
`preset`), reicht ihn an `images.run(path, { lang = ..., args = ... })`
durch. Ein neues `config.ocr_presets`-Table (analog zu
`config.solution_statuses` als benannte Liste) mit mindestens:

```lua
M.ocr_presets = {
  default = {},                    -- heutiges Verhalten, unverändert
  log = { "--psm", "6" },          -- strukturierte/monospace Logs, JSON-artig
}
```

`:Case ocr --preset=log` bzw. als eigener Flag. Aufwand: klein — im
Wesentlichen eine durchgereichte Option plus ein Config-Eintrag, keine neue
Architektur.

### 2. JSON-Reparatur-Heuristik + Validierungssignal (mittel)

Da der Inhalt *bekannt strukturiert* ist (NDJSON), kann casedesk das
gezielt ausnutzen, was ein generischer OCR-Wrapper nicht kann:

- **Anführungszeichen normalisieren** — typografische Quotes (`" " ' '`)
  vor jedem Decode-Versuch auf `"` zurückführen. Ein einzeiliger,
  risikoarmer `gsub`.
- **Pro Zeile `vim.json.decode` versuchen**, Fehlschläge zählen und
  melden. Liefert ein ehrliches, sofortiges Qualitätssignal ("14 von 18
  Zeilen valides JSON") statt der heutigen Blackbox — passt zur
  bestehenden Ehrlichkeits-Linie in `ocr.lua`s eigenem Kommentar ("Framed
  as machine-read rather than quoted as fact").
- **Gezielte Zeichen-Reparatur nur im validierten JSON-Kontext**, z. B.
  `@`→`0` ausschließlich innerhalb eines erkannten ISO-Timestamp- oder
  Hex-String-Musters (`TraceId`/`SpanId` sind immer 32-stellige Hex-Werte
  — eine Positions-/Zeichensatz-Prüfung ist hier eng genug, um sicher zu
  sein, ohne echten Text zu verfälschen). Nach jeder Korrektur erneut
  `vim.json.decode` versuchen.
- Wo eine Zeile durch Bildumbruch tatsächlich fragmentiert bleibt (siehe
  Snipping-Tool-Ergebnis in `ocr.md` — auch DORT sind Fortsetzungszeilen
  keine vollständigen JSON-Objekte): Fortsetzungszeilen (die nicht mit
  `{"`/`["` beginnen) an die vorherige Zeile ohne Objektstart anhängen,
  dann erneut zu parsen versuchen.

Das ist explizit **keine allgemeine OCR-Korrektur**, sondern eine auf die
bekannte Form ("Kunde schickt strukturiertes Log als Screenshot")
zugeschnittene Heuristik — deutlich enger und damit robuster als ein
Versuch, beliebigen Text zu reparieren. Mit synthetischen Fixtures
(abgeleitet aus den drei Dateien in `ocr.md`) gut automatisiert testbar,
ohne echte Kundendaten im Testcode zu brauchen.

### 3. Bild-Preprocessing als sekundärer Hebel (klein-mittel, unsicherer Ertrag)

`images.convert` existiert bereits (SVG→PNG-Pfad, von `images.ocr.run`
selbst schon genutzt). Ein zusätzlicher Preprocessing-Schritt (Hochskalieren
vor der Erkennung, Schwellwert/Kontrast) VOR dem Tesseract-Aufruf könnte
die Zeichenfehlerquote weiter senken — unklar wie stark, ohne konkreten
Test nicht seriös zu beziffern. Niedrigere Priorität als 1./2., da der
Ertrag hier reine Spekulation wäre, während 1. und 2. bereits am
Referenzbild nachgewiesen bzw. strukturell sicher sind.

## Was NICHT rein casedesk-seitig erreichbar ist

Die eigentliche Lücke zum Snipping-Tool-Ergebnis ist die **Engine
selbst** — Windows' modernes On-Device-Texterkennungsmodell (hinter den
Snipping-Tool-"Text-Aktionen") ist architektonisch stärker bei dichtem,
tabellarischem/monospace Layout als Tesseracts LSTM-Modell, unabhängig von
PSM-Tuning. Ein Zugriff darauf aus Neovim heraus wäre technisch denkbar
(Windows' `Windows.Media.Ocr`-API ist über PowerShell/WinRT-Interop
ansprechbar — derselbe Mechanismus, den `attachments.lua` bereits für den
nativen `OpenFileDialog` nutzt), ist aber ein **eigenständiges,
images.nvim-seitiges Vorhaben** (neues OCR-Backend, WinRT-Interop ist
erfahrungsgemäß fragil je nach PowerShell-Edition/Windows-Version) — genau
der andere, separat angekündigte Punkt zu images.nvim. casedesk kann davon
profitieren, sobald es existiert (derselbe `images.ocr.run`-Aufrufpunkt,
nur mit einem anderen Backend dahinter), muss es aber nicht selbst bauen.

## Vorschlag: `:Case image getText [nr] [preset]`

Ergänzt `:Case ocr` (Batch, alle Bilder, schreibt Sidecars), statt es zu
ersetzen — andere UX-Form, derselbe Unterbau:

- **Bild wählen:** `kit.select` über `ocr.images(entry)` — derselbe
  Bild-Picker, den `:Case attachments`/`pickers.lua` schon für andere
  Zwecke nutzen (kein neues UI-Muster).
- **`preset`** (`<Tab>`-vervollständigt aus `config.ocr_presets`, s. o.):
  `default` (heutiges Verhalten), `log` (`--psm 6`, für genau diese Art
  Screenshot).
- **Ergebnis:** read-only `kit.viewer` (wie `:Case solution`s Anzeige) mit
  der erkannten Rohausgabe UND, wenn Punkt 2 oben umgesetzt ist, der
  JSON-Validierungszeile ("N/M Zeilen valides JSON"). Von dort `y`
  kopiert, ein weiterer Key schreibt/aktualisiert den `.ocr.md`-Sidecar
  (dieselbe Datei, die `:Case ocr` auch anlegt — EIN Ergebnisort, kein
  Parallel-Datenhaltung).
- Ein drittes, nicht automatisierbares "Backend" (Snipping Tools
  Text-Aktionen) bleibt bewusst außen vor: das Feature ist rein
  GUI-interaktiv, ohne CLI/API — kein Picker-Eintrag möglich. Der Weg
  bleibt manuell: Nutzer macht es selbst, fügt das Ergebnis per Hand in
  den bereits frei editierbaren `.ocr.md`-Sidecar ein (funktioniert heute
  schon, keine Code-Änderung nötig).

## Empfehlung / Reihenfolge

1. **`opts.args`/Preset durchreichen** (Punkt 1) — kleinster Aufwand,
   sofort messbarer Effekt am Referenzbild, keine neue Architektur.
2. **JSON-Validierungssignal** (Teil von Punkt 2, ohne die
   Zeichen-Reparatur) — macht die heutige Blackbox ehrlich, unabhängig
   vom Rest umsetzbar.
3. **`:Case image getText`** — baut auf 1./2. auf, eigener UX-Nutzen
   (gezielt EIN Bild statt Batch) auch ohne die Reparatur-Heuristik.
4. **Gezielte Zeichen-Reparatur** (Rest von Punkt 2) — höchster Aufwand
   dieser Liste, lohnt sich am ehesten, nachdem 1.-3. zeigen, wie viel
   PSM-Tuning allein schon bringt.
5. Bild-Preprocessing (Punkt 3) — zurückgestellt, spekulativer Ertrag.

Punkt "Windows-eigene OCR-Engine" bewusst nicht in dieser Liste — gehört
in den separaten images.nvim-Punkt des Nutzers.
