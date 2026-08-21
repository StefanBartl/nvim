# casedesk — Artefakt-Extraktion (Konzept)

Was sich aus den beiden Artefakten holen lässt, die in fast jedem Case
liegen: `Ressources/ToscaSupportInfo*.txt` (vom Tosca Commander generiert)
und `Research/NN_ActivityStream.md` (aus SNOW kopiert).

> **Paket 1 steht** (2026-08-10): `:Case versions [component] [nr] [--all]
> [--raw]`, `extract/supportinfo.lua` (Kopf + Digest + Substring-Lookup),
> `config.version_components`/`version_watch`/`known_vendor_prefixes`.
> Gegen alle vier analysierten Support-Infos verifiziert (§1) — die
> Achmea-Custom-DLL wird korrekt als einziger "Auffällig"-Fund über alle
> vier gefunden, kein False Positive.
>
> **Paket 2 steht** (2026-08-10): `extract/stream.lua` — Versionen im
> Fließtext (Server/Commander), KBA-Nummern, Anhangsnamen, der
> Stammdaten-Schlussblock (`config.stream_stammdaten_labels`), und der
> Vollständigkeits-Check als neuer `:Cases doctor`-Fund `stream-incomplete`.
> `:Case activity` schreibt `sap_component`/`versions` jetzt automatisch
> nach `.case.json`, `:Case versions server` nutzt den Stream als Fallback
> (Paket 1 hatte das noch offen gelassen). Gegen den einen echten Stream im
> Bestand (Case 977392) verifiziert — dabei zwei echte Bugs gefunden und
> gefixt (s. §12): Attachments durch Leerzeilen getrennt statt terminiert,
> `error_codes` zu lockeres Pattern (`HEC_ABAP`/ein Dateiname-Fragment als
> falsche Treffer). `error_codes`/`doc_links`/`escalations` selbst kommen
> in diesem einen Stream nicht vor — Pattern gegen EXTRACTION.md §4s
> dokumentierte Beispiele gebaut, `doc_links` zusätzlich gegen echte
> `docs.tricentis.com`-Links aus anderen Case-Dateien verifiziert (nicht
> aus einem Stream), `error_codes`/`escalations` bleiben ungetestet gegen
> echten Treffer.
>
> **Paket 3 steht** (2026-08-10): `extract/doclinks.lua`, `:Case doclinks
> [nr]`, Einbau in `:Case reply check`. Kundenversion wird dreistufig
> aufgelöst (`.case.json` → Support-Info über `detect.tosca_version` →
> Stream-Commander-Version, zuverlässigste Quelle zuerst) und auf
> Doc-Link-Form normalisiert (`25.1.7`/`2026.1` beide → `2025.1`/`2026.1`).
> Gegen einen echten Fund verifiziert: Case 1041708 läuft laut
> Support-Info auf `25.1.2`, ein Reply verlinkt `tosca-2026.1` — genau der
> Fehler, den EXTRACTION.md §6 als Motivation nennt, real im eigenen
> Bestand gefunden, nicht nur im Worked Example nachgestellt.
>
> **Paket 4 steht** (2026-08-10): §11.1 war schon entschieden (Uhr
> pausiert), aber die tatsächliche Umsetzung betraf nur die Rückmeldung
> (SLA.md §3-Nachtrag, 2026-08-07) — Korrekturmaßnahme lief unverändert
> als Einmal-Deadline durch. Anders als bei der Rückmeldung ist ein
> **Reset kein passendes Modell** für Korrekturmaßnahme (eine einmalige,
> kumulative Frist würde bei mehrfachem Kunden-Hin-und-Her effektiv
> unbegrenztes Budget bekommen) — stattdessen eine echte **Pause**:
> `sla/init.lua`s neue `total_awaiting_seconds` summiert jedes
> Awaiting-User-Info-Intervall aus der vollen Zustandshistorie und
> verlängert Deadline UND effektives Budget um exakt diese Zeit. Isoliert
> getestet (kein echter Stream mit echter Awaiting-User-Info-Historie im
> Bestand): 2h Pause → 4h-Budget wächst auf 6h, ohne Pause bleibt es bei
> 4h. Details: SLA.md, zweiter Nachtrag zu §3. Dazu `:Case activity`
> erkennt jetzt auch `last_reply_sent` aus einem "Send to Customer"-Memo
> automatisch (§5s zweiter Fund) — regressiert dabei nie einen neueren
> manuellen Stempel aus `:Case reply check`.
>
> **Paket 5 steht** (2026-08-10, letztes Paket — Artefakt-Extraktion ist
> damit komplett fertig): `extract/facts.lua` rendert §7s "Ermittelte
> Fakten"-Block rein aus bereits gebauten Extraktoren (kein neues
> Parsing) — `{facts}`-Token in `KiPrompt.md`, gefüllt von `ui.lua`s
> `M.ki`. Gegen drei echte Cases verifiziert, kein Absturz, sinnvolle
> Degradation bei fehlenden Daten — und der Block fasst automatisch
> zusammen, was Paket 1/2/3 einzeln schon real gefunden hatten (996010s
> Custom-DLL, 1041708s Doku-Link-Mismatch, 977392s Impact-Feld) in
> **einer** Stelle. `:Case ki import` bekommt eine Widerspruchsprüfung
> (Richtung 2): zitiert die KI-Antwort einen `docs.tricentis.com`-Link
> auf einer anderen Version als der Kunde fährt, warnt es sofort beim
> Import, nicht erst beim nächsten `:Case reply check`. Richtung 3
> (zitierte Doku-Links als Referenzsammlung) ist nur teilweise gebaut —
> die Aggregation nach Version steckt in der Faktenblock-Zeile "Doku-Links
> im Case", aber keine Sammlung mit Zitat/Kontext pro Link (bräuchte
> Auszüge aus dem Case-Text um jeden Fund, ein eigenständig größeres
> Stück — s. ROADMAP.md's KI-Anbindung-Punkt).

Fertige Features sonst: [CONCEPT.md](CONCEPT.md). Der SLA-Teil des
Stream-Parsers (`sla/stream.lua`) steht bereits eigenständig, siehe
[SLA.md](SLA.md).

---

## Table of content

- [1. Materialbasis](#1-materialbasis)
- [2. `ToscaSupportInfo.txt` — Aufbau](#2-toscasupportinfotxt--aufbau)
  - [Kopfblock](#kopfblock)
  - [Dateiliste](#dateiliste)
  - [Der eigentliche Befund: 1600 Zeilen, 4 Zahlen](#der-eigentliche-befund-1600-zeilen-4-zahlen)
  - [Parser-Fallen](#parser-fallen)
- [3. `:Case versions` — Design](#3-case-versions--design)
- [4. Activity Stream — was noch drinsteckt](#4-activity-stream--was-noch-drinsteckt)
  - [Struktur, bestätigt an vier Streams](#struktur-bestätigt-an-vier-streams)
  - [Extrahierbare Signale](#extrahierbare-signale)
  - [Parser-Fallen](#parser-fallen-1)
- [5. Rückwirkung auf das SLA-Konzept](#5-rückwirkung-auf-das-sla-konzept)
- [6. Die Doku-Versions-Prüfung](#6-die-doku-versions-prüfung)
- [7. KI-Anbindung mitgedacht](#7-ki-anbindung-mitgedacht)
- [8. Datenmodell](#8-datenmodell)
- [9. Modulaufbau](#9-modulaufbau)
- [10. Risiken](#10-risiken)
- [11. Offene Fragen](#11-offene-fragen)
- [12. Reihenfolge](#12-reihenfolge)
- [13. Zweite Quelle: SAP Resolve (Analyse, noch nicht gebaut)](#13-zweite-quelle-sap-resolve-analyse-noch-nicht-gebaut)
  - [Format, aus einem echten Export](#format-aus-einem-echten-export)
  - [Was schon funktioniert, ohne dass etwas gebaut wurde](#was-schon-funktioniert-ohne-dass-etwas-gebaut-wurde)
  - [Was fehlt, weil SNOW-strukturell](#was-fehlt-weil-snow-strukturell)
  - [Zwei echte Lücken — nicht durch Parsing lösbar](#zwei-echte-lücken--nicht-durch-parsing-lösbar)
  - [Architektur-Vorschlag: Format-Erkennung + Adapter](#architektur-vorschlag-format-erkennung--adapter)
  - [Reihenfolge-Vorschlag](#reihenfolge-vorschlag)
- [Literatur und Referenzen](#literatur-und-referenzen)

---

## 1. Materialbasis

Analysiert wurden vier Support-Infos und vier Activity Streams — bewusst
über verschiedene Tosca-Generationen und Kundeninstallationen hinweg, damit
sichtbar wird, was **stabil** ist und was variiert:

| Support-Info | Testsuite | TCSupportInfo | Install-Root | Zeilen | `Version:`-Zeilen |
| --- | --- | --- | --- | --- | --- |
| Case 859769 | `25.1.7` | 25.1.7.3594 | `C:\Program Files (x86)\…` | 6514 | 1588 |
| Case 996010 | `2026.1` | 26.1.0.3180 | `C:\Program Files (x86)\…` | 6754 | 1642 |
| Case CS0493217 | `24.2.1` | 24.2.1.1840 | `D:\Tosca Installation\…` | 5888 | 1375 |
| Case 1041708 | `25.1.2` | 25.1.2.3468 | `E:\Program Files (x86)\…` | 6521 | 1589 |

| Activity Stream | SNOW-Nummer | Case | Priorität | Account |
| --- | --- | --- | --- | --- |
| `actstream1` | SAP00009960102026 | 996010 | 4 - Low | Achmea Interne Diensten N.V. |
| `actstream2` | SAP00009895082026 | 989508 | 3 - Moderate | British American Shared Services |
| `actsream3` | SAP00009405612026 | 940561 | 3 - Moderate | Siemens Energy Global GmbH & Co. KG |
| `actsream4` | SAP00009083192026 | 908319 | 3 - Moderate | Böhm & Co |

Case 996010 hat **beides** — Support-Info und Stream. Das ist der Testfall,
an dem sich Querbezüge prüfen lassen.

## 2. `ToscaSupportInfo.txt` — Aufbau

### Kopfblock

Über alle vier Dateien identisch, Zeilen 1–12:

```
Tosca Support Info
==================

TCSupportInfo Version 25.1.7.3594
Report created 7/14/2026 12:38:47 PM
-------------------------------------------

Tosca Testsuite Version: 25.1.7
Entry Assembly: C:\…\ToscaCommander\TCSupportInfo.dll
Tricentis Home Directory: C:\…\Settings
Commander Home Directory: C:\…\ToscaCommander
Tbox Home Directory: C:\…\TBox
```

Das ist der einzige garantiert vorhandene, exakt positionierte Teil — alles
Weitere ist Liste. Der bereits gebaute `detect.tosca_version` liest genau
die `Tosca Testsuite Version:`-Zeile und ist damit auf dem stabilsten Anker
der Datei.

### Dateiliste

Ab `Files:` folgen abwechselnd **Verzeichnis-Header** (absoluter Pfad, keine
Einrückung) und **Einträge** (4 Leerzeichen Einrückung), wobei ein Eintrag
optional eine Versionszeile nachgestellt bekommt:

```
C:\Program Files (x86)\TRICENTIS\Tosca Testsuite\TBox
    Tricentis.AutomationBase.dll
    Version: 20.20.3348 (0)

    Tricentis.Automation.Agent.deps.json

    ExtensionManager.exe
    Version: 20.20.3348
```

Verzeichnisse in 996010: 40+ Sektionen (`Settings\XML`, `Settings\XSD`,
`TBox`, `TBox\DatabaseServer`, `TBox\MobileServer`, `TBox\ExecutionRecorder`,
`TBox\PowerBuilder`, `TBox\opencv`, `TBox\tessdata`, dazu ~15
Sprach-Ressourcen-Ordner `de`/`es`/`fr`/`ja`/`ko`/`ru`/`zh-Hans`/…).

`.json`/`.txt`/`.config`/`.xml`-Einträge haben **keine** Versionszeile.

### Der eigentliche Befund: 1600 Zeilen, 4 Zahlen

Das ist die wichtigste Erkenntnis für das Kommando-Design. Ein Picker über
1588 Versionseinträge ist unbenutzbar — und wäre auch sinnlos, weil die
Zahlen **fast alle voneinander abhängen**:

| Komponente | 24.2.1 | 25.1.7 | 2026.1 |
| --- | --- | --- | --- |
| `Tricentis.AutomationBase.dll` | 20.19.3088 | 20.20.3348 | 20.21.8011 |
| `Tricentis.Automation.SapEngine.dll` | 20.19.3088 | 20.20.3348 | 20.21.8011 |
| `Tricentis.Automation.SAP.SAPUI5.dll` | 20.19.3088 | 20.20.3348 | 20.21.8011 |
| `Tricentis.Automation.ChromeEngine.dll` | 20.19.3088 | 20.20.3348 | 20.21.8011 |
| `Tricentis.Automation.Api.Core.dll` | 24.2.116 | 25.1.203 | 26.1.241 |
| `Tesseract.dll` | 3.3.0.0 | 3.3.0.0 | **5.2.0** |
| `WebDriver.dll` | 4.0.0.0 | 4.0.0.0 | 4.0.0.0 |

Praktisch **alle** `Tricentis.Automation.*`-Engines tragen dieselbe
TBox-Build-Nummer. Es gibt also im Kern vier unabhängige Zahlen —
Testsuite-Version, TBox-Build, Api-Core-Linie, plus die Handvoll
Drittanbieter-Libs, die sich davon lösen (Tesseract springt zwischen 25.1
und 2026.1 von 3.3.0.0 auf 5.2.0 — bei einem OCR-Case ist genau das die
relevante Zeile).

Daraus folgt: `:Case versions` ohne Argument darf **nicht** alles auflisten,
sondern muss ein **Digest** zeigen. Die Vollliste ist die Ausnahme
(`--all`), nicht der Default.

**Und ein zweiter Fund derselben Logik:** filtert man die TBox-Wurzel gegen
die bekannten Hersteller-Präfixe, bleibt in 996010 genau **eine** Datei
übrig:

```
Achmea_Tosca_Custom_Controls.dll        Version: 2023.2.1.1
```

Ein kundeneigenes Custom-Control-DLL — bei den anderen drei Installationen:
nichts. Das ist ein Support-Signal ersten Ranges (Custom Controls ändern den
Scope und sind häufige Fehlerursache) und fällt bei einer Vollliste
niemandem auf, weil es zwischen 1600 Zeilen steht. Ein Digest, der
„Fremdkörper" aktiv hervorhebt, findet es sofort. Die Account-Zeile im
zugehörigen Stream (`Achmea Interne Diensten N.V.`) bestätigt die Zuordnung.

### Parser-Fallen

| Falle | Belegt an | Konsequenz |
| --- | --- | --- |
| **`Report created` hat zwei Formate**: `7/14/2026 12:38:47 PM` (12h) vs. `7/30/2026 13:02:24` (24h) | 859769 vs. 1041708 | Locale-abhängig. Nur als Anzeigetext übernehmen, **nicht** als Zeitanker parsen — dafür gibt es die mtime der Datei |
| **Testsuite-Version bricht das `X.Y.Z`-Schema**: `2026.1` neben `25.1.7` | 996010 | Kein `%d+%.%d+%.%d+`-Pattern. Alles bis Zeilenende nehmen, trimmen |
| **TCSupportInfo-Version ≠ Testsuite-Version**: `26.1.0.3180` ↔ `2026.1` | 996010 | Nie die Kopfzeile 4 als „die" Version ausgeben |
| **Install-Root variiert**: `C:`, `D:`, `E:`, und `Tosca Installation` statt `TRICENTIS\Tosca Testsuite` | alle vier | Sektionen nie über einen festen Pfad erkennen, sondern über „Zeile ohne Einrückung, die auf `<Buchstabe>:\` beginnt" |
| **Versionsformate uneinheitlich**: `34.8.0.280 (280)`, `2, 8, 0`, `3.3.0` | überall | Als **String** führen, nie als Zahl parsen. Vergleiche nur auf Gleichheit, nicht auf Ordnung |
| Dateien ohne Versionszeile | überall | Eintrag = Name + optionale Version; Abwesenheit ist normal |

## 3. `:Case versions` — Design

```
:Case versions [component] [nr] [--all] [--raw]
```

- **`:Case versions`** — Digest in `kit.viewer`:

  ```
  1041708 · ToscaSupportInfo (1).txt · report 7/30/2026 13:02:24

    Testsuite        25.1.2
    TBox build       20.20.3228          (alle Automation-Engines)
    Api Core         25.1.174
    Install-Root     E:\Program Files (x86)\TRICENTIS\Tosca Testsuite

    Auffällig
      (keine kundeneigenen DLLs im TBox-Wurzelverzeichnis)

    Ausgewählt        DevExpress 24.2.5.0 · Tesseract 3.3.0.0
                      WebDriver 4.0.0.0 · Newtonsoft.Json 13.0.3.27908
  ```

- **`:Case versions commander`** — genau das, was du beschrieben hast:
  ein Name rein, eine Nummer raus, in die Zwischenablage. `component`
  wird `<Tab>`-vervollständigt aus `config.version_components` (siehe
  unten) **plus** — das ist der Trick für Erweiterbarkeit — jedem
  Substring-Treffer im Dateinamen. `:Case versions tesseract` findet
  `Tesseract.dll`, ohne dass das je in einer Liste stand.
- **Mehrdeutig → `kit.select`.** `:Case versions sap` trifft SAPUI5,
  SAPNW, SAPCRM, SapEngine … also Auswahlliste statt Rateversuch.
- **`--all`** — die Vollliste, gruppiert nach Verzeichnis, für den
  seltenen Fall, dass man wirklich blättern will.
- **`--raw`** — öffnet die Support-Info-Datei selbst.

Die kuratierte Namensauflösung als Config, nicht als Code:

```lua
--- Friendly name -> the entry that actually answers "which version is X?".
--- The list only shortcuts the common questions; any substring of any file
--- name in the report works as `component` too, so an entry missing here
--- is a missing convenience, never a missing capability.
M.version_components = {
  commander   = { header = "Tosca Testsuite Version" },
  testsuite   = { header = "Tosca Testsuite Version" },
  tbox        = { file = "Tricentis.AutomationBase.dll" },
  api         = { file = "Tricentis.Automation.Api.Core.dll" },
  sap         = { file = "Tricentis.Automation.SapEngine.dll" },
  sapui5      = { file = "Tricentis.Automation.SAP.SAPUI5.dll" },
  html        = { file = "Tricentis.Automation.HtmlEngine.dll" },
  chrome      = { file = "Tricentis.Automation.ChromeEngine.dll" },
  edge        = { file = "Tricentis.Automation.EdgeEngine.dll" },
  uia         = { file = "Tricentis.Automation.UiaEngine.dll" },
  mobile      = { file = "Tricentis.Automation.Mobile30Engine.dll" },
  webdriver   = { file = "WebDriver.dll" },
  excel       = { file = "Tricentis.Automation.ExcelEngine.dll" },
  pdf         = { file = "Tricentis.Automation.PdfEngine.dll" },
  database    = { file = "Tricentis.Automation.DatabaseEngine.dll" },
  ocr         = { file = "Tesseract.dll" },
  licensing   = { file = "CloudLicensingIntegrationService.dll" },
}
```

**`server` fehlt in dieser Liste — mit Absicht.** Siehe §4: die
Server-Version steht *nicht* in der Support-Info, sie kommt nur aus dem
Activity Stream. `:Case versions server` muss deshalb dort nachsehen, und
das ist genau der Grund, warum die beiden Extraktoren zusammengehören.

**Performance:** die Datei ist ~6500 Zeilen / ~250 KB. Einmal je Aufruf
streamen und die interessanten Zeilen mitschneiden reicht — kein Index,
kein Cache. Aber: **nie** die ganze Datei in eine Lua-Tabelle mit 1600
Einträgen ziehen, wenn nur eine Zahl gefragt ist; der `component`-Pfad
bricht beim ersten Treffer ab.

## 4. Activity Stream — was noch drinsteckt

### Struktur, bestätigt an vier Streams

Kopf: `Activity` / `<N>` / `<N> total activities.`

Dann Blöcke, jeder mit einem Typ-Label in eigener Zeile: `Comment`,
`Field changes` oder `Work notes`. **Die Blockzahl stimmt exakt mit der
Kopfzahl überein** (15/15, 25/25, 26/26, 22/22) — ein kostenloser
Vollständigkeits-Check: weichen sie ab, wurde die Ansicht in SNOW nicht
ganz aufgeklappt („Show less"/„Show more") und der Stream ist unvollständig.
Das ist ein `:Cases doctor`-Fund wert.

Actor steht **doppelt** über dem Block (`Stefan Bartl` / `Stefan Bartl`,
bzw. `SR` / `SAP Resolve` für das System).

Memo-Typen über alle vier Streams (31 Kunden-, 8 Partner-, 8 SAP-interne,
4 „Send to Customer", 4 „Memo to Customer", 4 Attachment-Meldungen):

| Zeile | Bedeutung |
| --- | --- |
| `Customer added a memo` | Kunde hat geschrieben |
| `Send to Customer, updates that transfer case ownership to the customer` | **meine** Antwort raus, Ball beim Kunden |
| `Memo to Customer, visible to SAP and customer.` | meine Antwort, ohne Ownership-Übergang |
| `SAP added a memo for the partner` | SAP an mich |
| `SAP adds memo for the customer, not visible to the customer` | SAP-intern |
| `New attachment(s) added…` | Anhänge, Dateinamen folgen |

### Extrahierbare Signale

Alles Folgende ist an den vier Streams belegt, nicht vermutet:

1. **Versionen im Fließtext.** `Tosca server version - 25.1.2`,
   `Tosca commander version - 25.1.7`,
   `Product version incl. patch level-2025 1.7 Version`. Die
   **Server-Version gibt es nirgends sonst** — die Support-Info kennt nur
   den Commander, weil `TCSupportInfo.dll` im Commander läuft. Für einen
   Server-Case ist das die entscheidende Zahl.
2. **Zustandswechsel.** `State` gefolgt von `<neu> was <alt>`:
   `Active was New`, `Awaiting User Info was Active`,
   `Active was Awaiting User Info`. Daraus fällt die komplette
   Ping-Pong-Historie des Cases — siehe §5.
3. **Eskalation / Swarming.** `Work notes` mit
   `Case Task SWTASK0019690 state has been updated from Awaiting T1 to
   Awaiting T2`. Tier-Wechsel und Task-IDs, sauber parsebar. In
   `actstream1`/`actsream4` je ein solcher Task mit mehreren Übergängen.
4. **SAP-KBA-Nummern.** `3193320 - How to collect different logs in TOSCA`,
   `3572390 - Required information when opening case…`,
   `3428281`, `3594534`. Wiederkehrende Referenzen — Kandidaten für die
   Terminologie-/Link-Sammlung.
5. **Doku-Links mit Versionsangabe im Pfad**:
   `docs.tricentis.com/tosca-2026.1/…` vs. `…/tosca-2025.1/…` — §6.
6. **Fehlercodes.** `TRICENTIS_ERROR_CALL_PROVISIONING` (`actsream4`),
   Screaming-Snake-Case, gut greifbar. Wertvoll für `:Case similar`:
   ein Fehlercode ist ein weit besseres Ähnlichkeitsmerkmal als Prosa.
7. **Stammdaten** im Schlussblock: `Account`, `Assignment group`, `Contact`,
   `Impact`, `Priority`, `Number`, `SAP Component`, `Title`, `Cloud System
   Type`, `Business Impact`. `Number` → `render.to_short` liefert die
   Case-Nummer zurück (`SAP00009960102026` → `996010`, verifiziert).
   `SAP Component` unterscheidet Produktlinien (`XX-PART-TRI-ECT` vs.
   `XX-PART-TRI-TTA-CLD`) — ein besserer Kategorie-Kandidat als alles, was
   ROADMAP.md bisher für `:Cases category` vorgeschlagen hat, weil er
   ohne Pflegeaufwand aus dem Stream fällt.
8. **Anhangsnamen**, u. a. `ToscaSupportInfo.txt` selbst — der Stream sagt
   also, ob eine Support-Info *existieren müsste*. Fehlt sie in
   `Ressources/`, ist das ein Hinweis, sie aus SNOW nachzuladen.
9. **Kontaktdaten**: E-Mail, S-User-Nummern (`S0028044575`), Zeitzonen
   (`10:00 A.m-19:00 P.M [IST]`). Die Zeitzone ist für die SLA-Praxis
   relevant — ein Rückruf um 17:00 CET erreicht IST niemanden mehr.

### Parser-Fallen

| Falle | Belegt an | Konsequenz |
| --- | --- | --- |
| **`X was Y` ist mehrdeutig** — `There was a change in the case` matcht dasselbe Muster wie `Active was New` (5 Vorkommen!) | alle Streams | Nur ausgewertet, wenn die **Vorzeile** das Feldlabel ist (`State`, `Assigned to`). Das macht `sla/stream.lua` bereits richtig |
| **7-stellige `3xxxxxx` ist nicht immer eine KBA** — `customerNumber=3171302` | `actsream4` | KBA nur erkennen, wenn ein `-`/`—` und Text folgt, oder in einer bekannten Link-/Referenzumgebung |
| Zwei Zeitstempel je Comment (lokal + `at: … GMT`) | alle | GMT bevorzugen; `Field changes`/`Work notes` haben **nur** lokal |
| `Show less`/`Show more`-Artefakte im kopierten Text | alle | Als Rauschen verwerfen, aber als Signal für Vollständigkeit lesen (s. o.) |
| HTML-Reste im Description-Feld (`<ol><li>`, `&#34;`, `<a href=…>`) | `actsream3` | Beim Einlesen der Description entschärfen, sonst landet Markup in `Summary.md` |
| Umlaut-Namen (`Štefan Evin`, `Wolfgang Böhm`, `Böhm & Co`) | `actsream4` | Lua-Patterns mit `%w` greifen nicht — Byte-Klassen bzw. `[^\n]` verwenden |

## 5. Rückwirkung auf das SLA-Konzept

Der wichtigste inhaltliche Fund aus den Streams — und er korrigiert
[SLA.md](SLA.md) an einer Stelle, die die Zahlen materiell verändert:

**Cases stehen regelmäßig auf `Awaiting User Info`.** In `actstream2` und
`actsream3` je zweimal hin und zurück. Solange der Case dort steht, liegt
der Ball beim Kunden — und die **Rückmeldungs-Uhr sollte pausieren**. Sonst
zeigt das Tool eine gerissene Frist an, obwohl korrekt gearbeitet wurde,
und wird binnen zwei Wochen ignoriert.

Das ist genau das Alarm-Müdigkeits-Risiko aus SLA.md §8, nur mit einer
konkreten Ursache. Die Konsequenz für `sla/clock.lua`:

```
Uhr läuft   in State = New | Active
Uhr pausiert in State = Awaiting User Info
```

Die Zustandshistorie dafür ist vollständig im Stream vorhanden (§4.2), also
rein ableitbar — kein neues Pflegefeld. `sla/stream.lua` braucht dazu eine
`states`-Liste analog zu `customer`/`assignments`, und `clock.elapsed`
einen optionalen Parameter „nur diese Intervalle zählen".

Zweiter, kleinerer Fund: `Send to Customer, updates that transfer case
ownership to the customer` ist **der** Marker für „Antwort ist raus". Damit
lässt sich `last_reply_sent` (SLA.md §2, bisher nur manuell über
`:Case reply check`) in vielen Fällen **automatisch** aus dem Stream
belegen. Der manuelle Stempel bleibt trotzdem nötig — der Stream ist nur so
aktuell wie sein letztes Einfügen —, aber als Rückfall-Quelle ist er
deutlich besser als nichts.

## 6. Die Doku-Versions-Prüfung

In `actsream3` (Case 940561) stehen **8** Links auf
`docs.tricentis.com/tosca-2026.1/…` und **1** auf `…/tosca-2025.1/…`. Der
Kunde fährt laut eigener Angabe im selben Stream **25.1.2 / 25.1.7**. Der
SAP-Kollege bemerkt es im Fließtext („I can see you are on 2025.1.2 version
but following 2026.1 article"), und meine eigene Antwort korrigiert es
dann manuell („Please refer to the 2025.1 (25.1) guides matching your
installed version").

Das ist eine Prüfung, die eine Maschine besser macht als ein Mensch unter
Zeitdruck:

```
:Case doclinks
```

Vergleicht jede `docs.tricentis.com/tosca-<ver>/`-URL im Case (Stream **und**
Replies) gegen die ermittelte Kundenversion und meldet Abweichungen.
Besonders wertvoll **vor** dem Senden — also als zusätzliche Prüfung in
`:Case reply check`, das ohnehin schon Links auf Erreichbarkeit testet
(CONCEPT.md §8c). Ein toter Link ist peinlich; ein lebender Link auf die
falsche Produktversion ist schlimmer, weil der Kunde ihm folgt.

## 7. KI-Anbindung mitgedacht

Die Frage aus ROADMAP.md („nur Heuristik oder KI?") beantwortet sich hier
nicht als Entweder-oder. Die deterministische Extraktion und eine
KI-Analyse sind **komplementär**, und zwar in beide Richtungen:

**Richtung 1 — Extraktion füttert den Prompt.** Genau die Dinge, die
LLMs zuverlässig falsch machen (Versionsnummern verwechseln, Daten
halluzinieren, Prioritäten raten), sind hier exakt parsebar. Also gehören
sie nicht als Rohtext in den Prompt, sondern als **Faktenblock**:

```markdown
## Ermittelte Fakten (maschinell, nicht raten)

- Case: 940561 · Priorität 3 - Moderate · Impact 2 - Medium
- SAP Component: XX-PART-TRI-ECT
- Tosca Commander: 25.1.7 · Tosca Server: 25.1.2
- TBox-Build: 20.20.3348 · Api Core: 25.1.203
- Custom Controls: keine
- Zustand: Active (seit 2026-08-06), 2× Awaiting User Info in der Historie
- SLA: Erstreaktion erfüllt · Rückmeldung fällig 07.08. 09:58
- Doku-Links im Case: 8× tosca-2026.1, 1× tosca-2025.1  ⚠ Version passt nicht
```

`KiPrompt.md` bekommt dafür ein `{facts}`-Token. Das ist zugleich die
Antwort auf das Problem aus §3 der bisherigen Prompt-Fassung: die
6500-Zeilen-Support-Info darf **nie** roh in einen Prompt — das ist
Token-Verschwendung und Rauschen. Der 15-Zeilen-Digest ist der Ersatz.

**Richtung 2 — Extraktion validiert die Antwort.** Wenn die KI in ihrer
Analyse eine Version, eine Frist oder eine Priorität nennt, lässt sich das
gegen die geparsten Werte prüfen. `:Case ki import` bekommt damit eine
zweite Verteidigungslinie neben dem Prompt-Wächter, den wir letzte Woche
eingebaut haben: nicht nur „ist das überhaupt eine Antwort?", sondern
„widerspricht diese Antwort den Fakten?". Ein Entwurf, der dem Kunden
2026.1-Doku empfiehlt, obwohl 25.1.2 läuft, wird abgefangen, bevor er in
`Replies/` landet.

**Richtung 3 — Doku-Referenzen (der Punkt aus ROADMAP.md).** Der Wunsch,
zu jedem Case „passende Referenzen aus den Tricentis-Docs mit Link,
Überschrift und wörtlichem Abschnitt" gesammelt zu bekommen, hat hier eine
deterministische Vorstufe: die im Stream **bereits zitierten** Links
(`Steering Tables`, `Identify controls by anchor`, `Settings - XBrowser`,
`Use Report Designer`, …) sind schon Belege — sie stehen im Stream, samt
Kontext, in dem sie empfohlen wurden. Eine Sammlung daraus kostet keinen
KI-Aufruf und ist per Konstruktion korrekt zitiert. Erst *darüber hinaus*
neue Referenzen zu finden, ist eine KI-Aufgabe.

Reihenfolge daraus: **erst extrahieren, dann prompten.** Jede Zeile, die
der Parser liefert, ist eine Zeile, die die KI nicht erfinden kann.

## 8. Datenmodell

`.case.json` bekommt einen optionalen, rein abgeleiteten Block. Alle Felder
sind Cache — löschbar, jederzeit aus den Artefakten neu herstellbar
(CONCEPT.md §3: der Zustand ist der Ordner):

```jsonc
{
  "versions": {
    "commander": "25.1.7",        // Support-Info
    "server": "25.1.2",           // NUR aus dem Stream
    "tbox": "20.20.3348",
    "api_core": "25.1.203",
    "source": "ToscaSupportInfo.txt",
    "detected": "2026-08-06T14:12:00Z"
  },
  "sap_component": "XX-PART-TRI-ECT",
  "custom_dlls": ["Achmea_Tosca_Custom_Controls.dll 2023.2.1.1"]
}
```

Wie bei den SLA-Feldern: `:Cases doctor` policiert davon **nichts**.
Fehlen heißt „nicht ermittelt", nicht „Fehler".

## 9. Modulaufbau

Neben dem bestehenden `sla/`:

```
lua/bindings/usrcmds/case/
  extract/
    supportinfo.lua    -- Paket 1 (steht): ToscaSupportInfo*.txt — Kopf, Digest, Lookup
    stream.lua         -- Paket 2: Stream-Signale JENSEITS der SLA-Uhr
    doclinks.lua       -- Paket 3: docs.tricentis.com-URLs + Versionsabgleich
  ui.lua                -- M.versions — Digest/`--all`-Rendering (kein eigenes extract/render.lua)
```

Kein `extract/init.lua`/`render.lua` geworden — Paket 1 brauchte weder eine
Fassaden-API (`ui.lua` ruft `supportinfo.lua` direkt) noch ein separates
Render-Modul (`M.versions` in `ui.lua` rendert selbst, derselbe
Datensammlung/Rendering-Split wie `sla/`s Report, CONCEPT.md §4). Ob
Paket 5 (KI-Faktenblock) einen eigenen `render.lua` braucht, entscheidet
sich, wenn `{facts}` mehr als `:Case versions`s Digest zusammenfasst.

`sla/stream.lua` bleibt, wo es ist, und wird **nicht** verschmolzen: es hat
einen anderen Vertrag (nur was die Uhr braucht, garantiert fehlertolerant)
und einen anderen Aufrufpfad (Statusline, jede Minute). `extract/stream.lua`
darf teurer sein, weil es nur auf Kommando läuft. Gemeinsam genutzt wird
die Zeitstempel-Erkennung — die wandert nach `extract/` und wird von `sla/`
importiert, nicht umgekehrt.

## 10. Risiken

| Risiko | Gegenmaßnahme |
| --- | --- |
| **Format ändert sich mit der nächsten Tosca-Version** — 2026.1 hat bereits neue Einträge (`Tricentis.AI.SDK.dll`, `ModelContextProtocol.dll`) | Nur auf den Kopfblock hart verlassen; Listen-Parsing rein strukturell (Einrückung), nie über Dateinamen-Whitelists |
| Digest zeigt das Falsche | „Auffällig"-Sektion ist der Kern, nicht die Zahlenliste. Custom-DLLs und Versionskonflikte nach oben |
| Support-Info ist **Momentaufnahme** — Kunde patcht, Datei bleibt alt | `detected`-Zeitstempel + `Report created` immer mit anzeigen; nie als „aktuelle Version" behaupten, immer als „laut Report vom …" |
| Mehrere Support-Infos im Case (`ToscaSupportInfo (1).txt`) | Neueste nach `Report created` bzw. mtime; bei Abweichung beide melden — zwei Reports können zwei *Maschinen* sein, nicht zwei Zeitpunkte |
| Cross-Referenz Commander↔Server suggeriert Genauigkeit, die nicht da ist | Quelle je Zahl mitführen (`source`), im Digest sichtbar |
| Scope-Creep Richtung „SNOW-Parser für alles" | Nur Signale aufnehmen, für die es ein konkretes Kommando gibt |

## 11. Offene Fragen

1. ~~Pausiert die SLA-Uhr bei `Awaiting User Info` wirklich?~~
   **Entschieden (2026-08-10): ja, pausieren.** Sonst zeigt das Tool eine
   gerissene Frist an, obwohl korrekt gearbeitet wurde — Alarm-
   Müdigkeits-Risiko aus SLA.md §8. Damit ist Paket 4 entsperrt.
2. **Ist `SAP Component` als Kategorie brauchbar?** Bei vier Streams:
   3× `XX-PART-TRI-ECT`, 1× `XX-PART-TRI-TTA-CLD`. Über 20 Cases erst zu
   beurteilen — aber es kostet nichts, es schon mal mitzuschreiben.
   `:Case activity` schreibt es seit Paket 2 automatisch nach
   `.case.json`.
3. ~~Soll `:Case versions` ohne Support-Info auf den Stream
   zurückfallen?~~ **Gebaut (Paket 2, 2026-08-10):** ja, mit sichtbarer
   Quellenangabe (`(copied, from NN_ActivityStream.md)`) — jetzt gegen
   einen echten Stream ohne Support-Info verifiziert (Case 977392).
4. Sollen Custom-DLLs in `Summary.md` einfließen (SNOW-sichtbar) oder nur
   in `Notes.md` (intern)?
5. ~~`:Case doclinks` eigenständig oder nur als Prüfschritt in `:Case
   reply check`?~~ **Entschieden (Paket 3): beides.** Eigener Befehl für
   den gezielten Check, plus eine zusätzliche Zeile im bestehenden
   `:Case reply check`-Report — kein Entweder-oder.

## 12. Reihenfolge

**Paket 1 — `:Case versions` (steht, 2026-08-10):** `extract/supportinfo.lua`
(Kopf + Digest + Substring-Lookup) · `config.version_components` ·
Digest-Viewer · `--all`/`--raw`. Stream-Fallback für `server` kam mit
Paket 2 nach, nicht hier — s. u.

**Paket 2 — Stream-Signale (steht, 2026-08-10):** `extract/stream.lua`
(Versionen im Text, KBA-Nummern, Anhangsnamen, Stammdaten-Schlussblock) ·
`sap_component`/`versions` nach `.case.json` (`:Case activity`) ·
`:Case versions server`-Fallback (schließt §11 Frage 3) ·
Vollständigkeits-Check als `:Cases doctor`-Fund `stream-incomplete`.
**Nicht gebaut/nicht verdrahtet:** Zustandshistorie (steckt bereits in
`sla/stream.lua`, nicht dupliziert), Eskalation/Swarming (`SWTASK…`,
kein reales Vorkommen zum Prüfen), `custom_dlls` nach `.case.json`
(Paket 1s Digest berechnet es live, schreibt aber noch nichts weg).

**Paket 3 — Doku-Versionsprüfung (steht, 2026-08-10):**
`extract/doclinks.lua` · `:Case doclinks [nr]` · Einbau in `:Case reply
check`. Kundenversion dreistufig aufgelöst (`.case.json` →
`detect.tosca_version` → Stream-Commander), beide Versionsformate
(`25.1.7`/`2026.1`) auf Doc-Link-Form normalisiert. Realer Fund: Case
1041708 läuft auf `25.1.2`, ein Reply verlinkt `tosca-2026.1`.

**Paket 4 — SLA-Korrektur (steht, 2026-08-10):** `states` in
`sla/stream.lua` (stand schon, Paket 1 der SLA.md-eigenen Zählung) ·
Pausen-Intervalle für `fix` in `sla/init.lua`s neuer
`total_awaiting_seconds` (Pause, nicht Reset — anderes Modell als
`cadence` mit Absicht, s. SLA.md) · `last_reply_sent` aus dem „Send to
Customer"-Marker (`extract/stream.lua`s `M.last_reply_sent_at`, via
`:Case activity`).

**Paket 5 — KI-Kopplung (steht, 2026-08-10):** `extract/facts.lua` ·
`{facts}`-Token in `KiPrompt.md` · Widerspruchsprüfung in `:Case ki
import`. **Teilweise:** zitierte Doku-Links stecken nur als
Versions-Aggregat im Faktenblock, keine eigenständige
Zitat-mit-Kontext-Sammlung (bräuchte Textauszüge um jeden Fund, ein
eigenes, größeres Stück — s. ROADMAP.md's KI-Anbindung-Punkt).

Paket 1 und 2 sind unabhängig voneinander nützlich. Paket 5 setzte 1–3
voraus — genau deshalb stand es hinten: der Faktenblock ist nur so gut
wie die Extraktoren darunter.

## 13. Zweite Quelle: SAP Resolve (Analyse, noch nicht gebaut)

`sla/stream.lua` und `extract/stream.lua` sind komplett auf SNOWs
Copy-Paste-Format zugeschnitten (§4 oben). Für den SAP-Bereich gibt es
daneben **SAP Resolve** — ein eigenes Portal mit klarerer UI, in dem der
Case ebenfalls beschrieben ist, mit einem eigenen "Conversations"-Reiter.
Ein Tampermonkey-Script formatiert diesen Reiter beim Kopieren in die
Zwischenablage. `:Case activity` soll auch das annehmen, nicht nur SNOW.

### Format, aus einem echten Export

Ein Eintrag, gekürzt (Original: 19 Einträge, ein reales Case):

```
[2/19] 8/17/26 at 3:52 PM | Integration API | Returned Case to Customer
Dear <Name>,

Thank you for your update.

Please note that we conduct our technical investigations directly
within the ticket [...]

Links:
- Properties for XModules: https://docs.tricentis.com/tosca-2024.2/…
- Import and export subsets: https://docs.tricentis.com/tosca-2024.2/…

----------------------------------------
```

Struktur pro Eintrag: `[Index/Gesamt] M/D/YY at H:MM AM/PM | <Akteur> |
<Aktionstyp>`-Kopfzeile, Body bis zur nächsten Trennzeile aus 40
Bindestrichen. Absteigend nummeriert wie SNOW (`[1/N]` = neuester Eintrag,
`[N/N]` = Case-Erstellung), aber ohne SNOWs zweite Ebene ("Comment"/"Field
changes"/"Work notes" + separates Memo-Untertyp-Label) — der Aktionstyp
steht direkt, semantisch klarer, in der Kopfzeile selbst:

| Aktionstyp (real gesehen) | SNOW-Äquivalent |
| --- | --- |
| `Added a memo for Everyone` | `Comment` (allgemein) |
| `Returned Case to Customer` | `Send to Customer, updates that transfer case ownership…` |
| `Information from Customer` | `Customer added a memo` |
| `Business Impact` | Teil des Stammdaten-Schlussblocks |
| `Added a memo for Customer`/`…for Partner` | `SAP adds/added a memo for…` |
| `Described the problem` | der allererste Eintrag (`N/N`), inkl. `--- Description ---`/`--- Steps to Reproduce ---` |

Akteur ist entweder der echte Kundenname, `SAP`, oder — bei über eine
Schnittstelle gesendeten Partner-Antworten — `Integration API` statt des
Namens der Support-Person, die tatsächlich geantwortet hat.

### Was schon funktioniert, ohne dass etwas gebaut wurde

Gegen den echten Export laufen lassen (nicht nur überflogen): zwei der
sieben `extract/stream.lua`-Funktionen finden etwas, weil sie ohnehin nur
generische Substring-/Regex-Muster über den Rohtext ziehen, unabhängig von
SNOWs Block-Struktur:

- **`M.kbas`** — `3193320 - How to collect different logs in Tosca` taucht
  wortgleich in einer SAP-Memo-Passage auf und matcht `M.kbas`s
  `<7 Ziffern> <Trenner> <Text>`-Muster wie im SNOW-Fall.
- **`M.doc_links`** — die `docs.tricentis.com/tosca-<version>/…`-URLs
  stehen sowohl in Fließtext als auch in expliziten `Links:`-Abschnitten
  am Ende eines Eintrags (sogar sauberer als SNOW: `- Label: URL` statt
  freier Prosa) — `M.doc_links`s reiner URL-Scan greift unverändert.

### Was fehlt, weil SNOW-strukturell

Alles andere hängt an exakten SNOW-Textmustern und liefert für diesen
Export ein leeres/neutrales Ergebnis (kein Absturz — beide Parser sind
laut eigener Doku darauf ausgelegt, „nie zu werfen"; aber eben auch keine
Daten):

| Signal | Warum es an SNOWs Form hängt |
| --- | --- |
| `sla/stream.lua` — `priority`/`impact` | sucht `Priority`/`Impact` als **alleinstehende** Zeile, gefolgt von der Werte-Zeile — kommt in diesem Format so nicht vor |
| ~~`sla/stream.lua` — `customer`~~ | **Gelöst, Paket 6a:** `Information from Customer`/`Business Impact` sind das Signal, Datum aus der `[N/Total]`-Kopfzeile statt `at: … GMT` |
| `sla/stream.lua` — `assignments` | kein Äquivalent im Export — SAP Resolves Conversations-Ansicht zeigt keine Zuweisungshistorie; bleibt leer |
| ~~`sla/stream.lua` — `states`~~ | **Gelöst, Paket 6a:** `Returned Case to Customer`/`Information from Customer` inhaltlich fast dasselbe Signal wie SNOWs `State`-Block, nur anders benannt — als dieselben Strings (`"Awaiting User Info"`/`"Active"`) synthetisiert, `sla/init.lua`s `awaiting_customer()` braucht dafür keine Änderung |
| `extract/stream.lua` — `M.attachments` | braucht `New attachment(s) added` + Dateinamen-Zeilen; dieses Format sagt nur `Attachment uploaded`, **ohne** Dateinamen daneben |
| `extract/stream.lua` — `M.stammdaten` (→ `sap_component`, `case_short`) | braucht SNOWs Label-Value-Dump am Streamende (`Account`/`Number`/`SAP Component`/…) — kommt in diesem Export gar nicht vor |
| `extract/stream.lua` — `M.completeness` | braucht `<N> total activities.`-Kopfzeile; dieses Format zählt anders (`[N/Total]` pro Zeile) — **harmlos**: `doctor.lua`s Aufrufer prüft `if declared and …`, ein `nil` triggert keinen Fehlalarm, nur keinen Check |
| `extract/stream.lua` — `M.last_reply_sent_at` | braucht den exakten SNOW-Satz „Send to Customer, updates that transfer case ownership…" + `at: … GMT`; `Returned Case to Customer` ist das gleiche Signal, aber anderer Wortlaut und Zeitformat |

### Zwei echte Lücken — nicht durch Parsing lösbar

Zwei Felder kommen im Tampermonkey-Export **überhaupt nicht** vor, in
keiner Form — das ist keine Parser-Schwäche, das Datum steht schlicht
nicht im kopierten Text:

1. **Priorität/Impact.** SNOW liefert das über den Stammdaten-Dump am
   Streamende; SAP Resolves Conversations-Reiter enthält das nicht. Die
   gespeicherte SAP-Resolve-Seite (Screenshot dieser Analyse) zeigt aber
   Prioritäts-Kacheln auf einer Case-Übersicht — die Information *existiert*
   im Portal, nur nicht im "Conversations"-Export. Zwei Wege: das
   Tampermonkey-Script um einen zweiten, kleinen Export für die
   Kopfdaten der Case-Detailseite erweitern (Priorität/Impact/SAP-Ticket-
   Nummer stehen dort vermutlich beisammen), oder `:Case activity` fragt
   bei einem erkannten SAP-Resolve-Format aktiv nach der Priorität nach,
   statt sie zu erraten.
2. **SNOW-Ticketnummer / `Number`.** Genau wie oben — kein `SAP0000…`-Feld
   im Export. Muss entweder weiterhin manuell bei `:Case new` eingetippt
   werden (Status quo — `render.to_short` akzeptiert schon die volle ID
   oder die kurze Nummer), oder kommt aus einem erweiterten
   Tampermonkey-Export.

### Architektur-Vorschlag: Format-Erkennung + Adapter

Kein Format-Flag, das der Nutzer setzen muss — die beiden Formate sind an
der ersten nicht-leeren Zeile zuverlässig unterscheidbar:

```lua
-- SNOW:        "Activity" gefolgt von einer Zahl auf eigener Zeile
-- SAP Resolve: "[<Zahl>/<Zahl>] <Datum> at <Zeit>… | … | …"
local function detect_stream_format(text)
  local first = vim.trim((text or ""):match("^%s*(.-)\n") or text or "")
  if first:match("^%[%d+/%d+%]") then return "saperesolve" end
  if first == "Activity" then return "snow" end
  return nil -- unbekannt, kein Absturz — degradiert wie bisher zu leer
end
```

Zwei Wege, das auf `sla/stream.lua`/`extract/stream.lua` zu verdrahten:

**A — Getrennte Parser, gleiche Ausgabeform (kleinerer Eingriff).** Ein
neues `sla/stream_saperesolve.lua` + `extract/stream_saperesolve.lua`
(oder ein gemeinsames `extract/sources/saperesolve.lua`), das exakt
dieselben `Lib.Case.SlaStreamData`/`Lib.Case.StreamSignals`-Formen
zurückgibt wie die bestehenden SNOW-Parser. `:Case activity` (bzw. eine
kleine gemeinsame Dispatch-Funktion, die beide Aufrufer teilen) wählt
per `detect_stream_format` den richtigen Parser. Die beiden bestehenden,
bereits gegen echte Streams verifizierten SNOW-Parser bleiben unangetastet
— kein Regressionsrisiko für das, was heute funktioniert.

**B — Gemeinsame Zwischenform (sauberer, größerer Eingriff).** Beide
Formate erst auf eine gemeinsame Liste normalisierter Ereignisse
(`{ at, actor, kind, body }`) abbilden, dann EINE Auswertungsschicht
(Priorität-Erkennung, Customer/Assignment/State-Ableitung,
KBA/Doclink/Attachment-Scan) über dieser Zwischenform statt zweimal über
Rohtext. Setzt voraus, `sla/stream.lua` und `extract/stream.lua`
umzubauen — mehr Aufwand, aber ein dritter Quellformat-Adapter (denkbar:
Jira, eine andere Kundenplattform) würde dann nur noch die
Normalisierungsfunktion brauchen, keine zweite Kopie der
Auswertungslogik.

**Empfehlung: A zuerst.** Bei genau zwei Formaten lohnt sich die
Abstraktion aus B noch nicht (drei Kopien vs. eine Zwischenform ist eine
Abwägung, die sich erst ab dem dritten Format lohnt — bis dahin bloße
Vorwegnahme). B bleibt eine saubere Migration, falls ein drittes Format
kommt.

### Reihenfolge-Vorschlag

> **Paket 6a steht** (2026-08-21): `stream_format.lua` (Format-Erkennung
> an der ersten nicht-leeren Zeile, `"Activity"` vs. `"[N/N]..."`) ·
> `sla/stream.lua`s `parse_saperesolve` (`customer`/`states`, Priorität/
> Impact bleiben `nil` — Lücke 1, wie geplant). Ein echter Export reichte
> als Testgrundlage (User-Entscheidung) — gegen die realen 19 Einträge
> verifiziert: Format-Erkennung, alle Zeitstempel (inkl. 12-PM-Randfall),
> `customer`-Zählung (9, `Information from Customer` + `Business Impact`),
> `states`-Zählung (13, 5×`Returned Case to Customer` + 8×`Information
> from Customer`), und — end-to-end ohne jede Änderung an `sla/init.lua`
> — `awaiting_customer` korrekt `true` (jüngstes Ereignis: Agent hat
> geantwortet) bzw. `false` mit korrekt reset-etem `cadence.since`
> (jüngstes Ereignis: Kunde hat geantwortet). SNOW-Pfad per Regressionstest
> unverändert bestätigt. **`sla/stream_saperesolve.lua` wurde NICHT als
> eigene Datei angelegt** — die Vokabular-Wiederverwendung (`"Awaiting
> User Info"`/`"Active"`, identisch zu SNOWs eigenen Strings) machte einen
> privaten `parse_saperesolve` direkt in `sla/stream.lua` einfacher als
> ein zweites Modul, ohne den Dispatch-Vorteil zu verlieren. Paket 6b/6c
> weiterhin offen.

**Paket 6a — Format-Erkennung + minimale Abdeckung (steht):** `stream_
format.lua`, `sla/stream.lua`s `parse_saperesolve` (Priorität/Impact
**nicht** lösbar — Lücke 1, s. o. — aber `customer`/`states` aus
`Information from Customer`/`Returned Case to Customer` ableitbar, mit
Datum direkt aus der `[N/Total]`-Kopfzeile statt `at: … GMT`).

**Paket 6b — `extract`-Signale:** `extract/stream.lua` um denselben
Dispatch erweitern, für `attachments` (falls das Tampermonkey-Script um
Dateinamen erweitert wird) und `last_reply_sent_at` aus `Returned Case to
Customer`. `M.kbas`/`M.doc_links` brauchen keine Anpassung (funktionieren
bereits, s. o.).

**Paket 6c — Die zwei echten Lücken:** entweder Tampermonkey-Script-
Erweiterung (Case-Kopfdaten: Priorität, SNOW-Nummer) besprechen, oder
`:Case activity` fragt bei erkanntem SAP-Resolve-Format aktiv nach.
Reihenfolge bewusst zuletzt — ohne 6b lässt sich noch nicht beurteilen,
ob die Lücke in der Praxis überhaupt stört.

## Literatur und Referenzen

- Analysierte Artefakte:
  `Cases/SAP_Support/Cases/Open/{859769,996010,1041708}/Ressources/ToscaSupportInfo*.txt`,
  `Cases/NOT_SAP/Assigned/CS0493217/Attachments/ToscaSupportInfo.txt`,
  vier Activity-Stream-Exporte (Cases 996010, 989508, 940561, 908319),
  ein SAP-Resolve-Conversations-Export via Tampermonkey (19 Einträge, §13)
- [SLA.md](SLA.md) — §2 (Datenlage), §8 (Alarm-Müdigkeit), §9 (offene
  Fachfragen); §5 dieses Dokuments korrigiert dessen Uhr-Modell
- [CONCEPT.md](CONCEPT.md) §3 (Zustand = Ordner), §7 (`detect.lua`),
  §8c (Reply-Gate), §8e (kein-KI-Begründung), §8i (KI-Runde)
- [ROADMAP.md](ROADMAP.md) — „KI-Einbindung + Referenzen", `:Cases category`
- [Workflow.md](../../NOTES/casedesk/Workflow.md) — „Auto-detected fields"
- `docs.tricentis.com/tosca-<version>/` — versionsgebundene Produktdoku,
  Grundlage der Prüfung in §6
