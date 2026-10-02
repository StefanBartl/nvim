# casedesk.nvim — Live-Test-Checkliste (Stand 2026-10-02)

Alles, was `casedesk.nvim` kann, zum Durchtesten im echten Neovim mit dem echten
Case-Bestand — **ausführlich für alles, was in der Sitzung vom 2026-10-02 neu
gebaut wurde** (Teil A), danach die noch ungetesteten Punkte der Vorsitzung
(Teil B), dann ein Smoke-Inventar über **jede** Route (Teil C) und über
Keymaps, Autocmds und Health (Teil D). Automatisiert läuft alles grün (846
Specs, `stylua`/`luacheck`/`gen_docs`) — diese Liste ist für das, was Tests nicht
zeigen: echtes Verhalten an echten Daten, UX, Timing, Dinge, die nur beim Tippen
auffallen.

**Status:** ❌ ungetestet · 🟡 teilweise · ✅ wie erwartet · 🔴 Fehler (Notiz
ausfüllen!). Ein gefundener Fehler gehört zusätzlich als `RM-nn` in
`WKDBooks/Development/wkdbook-myplugins/casedesk.nvim/ROADMAP/ROADMAP.md` oder
als GitHub-Issue — nicht nur hierher.

## Inhalt

- [Vorbereitung](#vorbereitung)
- [Teil A — neu am 2026-10-02](#teil-a--neu-am-2026-10-02)
- [Teil B — aus der Vorsitzung (2026-09-30) noch ungetestet](#teil-b--aus-der-vorsitzung-2026-09-30-noch-ungetestet)
- [Teil C — Smoke-Inventar aller Routen](#teil-c--smoke-inventar-aller-routen)
- [Teil D — Keymaps, Autocmds, Health](#teil-d--keymaps-autocmds-health)
- [Nach dem Durchlauf](#nach-dem-durchlauf)

---

## Vorbereitung

**Stand holen und neu starten.** Das Plugin kommt aus dem lokalen Checkout
(`C:/repos/casedesk.nvim`, `lazy = false`), aber `hover.nvim` und `pdfport.nvim`
haben heute ebenfalls Änderungen bekommen — alle drei pullen, dann **Neovim neu
starten** (kein `:Lazy reload`: `casedesk` registriert Routen und Autocmds beim
Start).

```bash
git -C C:/repos/casedesk.nvim pull
git -C C:/repos/hover.nvim pull
git -C C:/repos/pdfport.nvim pull
```

```vim
:checkhealth casedesk
```

| # | Was testen | Erwartung | Status | Notizen |
| --- | --- | --- | --- | --- |
| V1 | Neovim startet | Keine Fehlermeldung beim Start, `:Case <Tab>` vervollständigt | ❌ | |
| V2 | `:checkhealth casedesk` | Alles grün bzw. klar benannte Warnung (welches Binary fehlt), **kein Abbruch** — der Browser-Check läuft jetzt über `lib.nvim.deps` | ❌ | |
| V3 | `:Case <Tab>` | Neue Verben tauchen auf: `imp`, `preflight`, `spotlight`, `jql`, `image`, `translate` | ❌ | |

**Testdaten, die es im Bestand gibt:**

| Fall | Wofür |
| --- | --- |
| `977392` (Solved, Siemens Energy) | hat `Research/01_ActivityStream.md` — Stream-Befehle (`spotlight`, `jql suggest`, `translate stream`, `anonymize`); die Firma hat zwei weitere Cases (`1229161`, `1244211`) — Firmen-Verlauf |
| `1195796` | hat `Research/NN_ActivityStream.md` — zweiter Stream-Fall |
| `1226959` | DEX-Fall, Titel "…Team Agent" — Preflight-Hinweis, Ähnlichkeits-Cluster mit `948965` und `1004926` |
| `1201484` | `assets/fourth/failed_login_errorlog.png` — der NDJSON-Log-Screenshot |
| Wegwerf-Case | für alles, was schreibt: `:Case new 999001`, am Ende `:Case delete 999001` (Nummer eintippen). **Nie** eine Testnotiz zu einem echten Kunden stehen lassen — `Cases/Important.jsonl` ist echter Bestand |

---

## Teil A — neu am 2026-10-02

### A1 · `:Case anonymize`: Telefonnummern und Arbeitszeiten (`50c828d`)

Zwischenablage mit diesem Text füllen, in einem Wegwerf-Case `:Case activity`,
dann `:Case anonymize`:

```text
Please call me. Contact number: 0176 1234567
Alternatively +49 30 12345678 or 0049 30 12345678.
Available 10:00 A.m-19:00 P.M [IST] and 9am - 5pm CET.
Case 1201484, ticket SAP0000123456, tel 2026-09-30, phone: 12345.
Log at 2026-09-24 12:01:51 - 12:05:00, meeting at 3:52 PM.
```

| # | Was testen | Erwartung | Status | Notizen |
| --- | --- | --- | --- | --- |
| 1 | Viewer-Kopfzeile | Zählt `N Telefonnummer(n) · N Arbeitszeit(en)` mit; Erwartung hier: 3 Telefonnummern, 2 Arbeitszeiten | ❌ | |
| 2 | Text darunter | `Contact number: [Telefon]`, `[Telefon]` für `+49…` und `0049…`, `[Arbeitszeit]` für beide Zeitbereiche samt `[IST]`/`CET` | ❌ | |
| 3 | `1201484`, `SAP0000123456` | **Bleiben stehen** (nackte Ziffernfolge ist keine Nummer) | ❌ | |
| 4 | `tel 2026-09-30`, `phone: 12345` | **Bleiben stehen** (Datum bzw. zu kurz) | ❌ | |
| 5 | Zeitstempel `12:01:51 - 12:05:00` und `3:52 PM` | **Bleiben stehen** (Log-Zeitstempel, einzelne Uhrzeit) | ❌ | |
| 6 | Warntext im Viewer | Nennt Telefonnummern "mit Label oder +/00-Präfix" und dass Nummern ohne Label **nicht** erkannt werden | ❌ | |
| 7 | Regression: Namen, E-Mails, S-User, Account/Contact | Weiterhin geschwärzt wie vorher | ❌ | |

### A2 · Synonyme für `:Case similar` / `:Cases solutions` (`e466407`)

| # | Was testen | Erwartung | Status | Notizen |
| --- | --- | --- | --- | --- |
| 1 | `:Case similar 948965` | `1226959` und `1004926` stehen auf Platz 1 und 2 (Scores um 0,27–0,30); Trefferwörter enthalten `distributed` | ❌ | |
| 2 | `:Case similar 1004926` | `1226959` Platz 1, `948965` Platz 2 (ohne Synonyme wäre es Platz 3) | ❌ | |
| 3 | `:Cases solutions dex agent` und `:Cases solutions team agent` | **Dieselben** Treffer in derselben Reihenfolge | ❌ | |
| 4 | Optional: `synonyms = {}` in der Plugin-Spec, neu starten, Test 1 wiederholen | Scores etwas niedriger, Reihenfolge ähnlich; danach wieder zurücknehmen | ❌ | |
| 5 | Kein Tempo-Einbruch bei `:Case similar` | Antwortet so schnell wie vorher (rund 47 Cases) | ❌ | |

### A3 · Tosca-Schreibweise bei `:Case ki import` (`df33234`)

Zum Einfügen aus der Zwischenablage:

```markdown
## 1. Activity Stream Analysis
The execution list contains the failing test case and a test step value.
Siehe https://docs.tricentis.com/x/test-case.htm und `execution list`.

## 3. Solution
Re-create the Execution-List. Several test cases are affected.
```

| # | Was testen | Erwartung | Status | Notizen |
| --- | --- | --- | --- | --- |
| 1 | `:Case ki import` im Wegwerf-Case | `Research/NN_KiAnalysis.md`: `` `ExecutionList` ``, `` `TestCase` ``, `` `TestStepValue` `` in Backticks | ❌ | |
| 2 | Die URL | **Unverändert** (`test-case.htm`) | ❌ | |
| 3 | `` `execution list` `` in Backticks | Bleibt wie geschrieben | ❌ | |
| 4 | "Several test cases" (Plural) | Bleibt unverändert | ❌ | |
| 5 | `:Case clean` auf derselben Datei | Fasst die Schreibweise **nicht** an (nur Paste-Artefakte) | ❌ | |

### A4 · Unausgefüllte Templates: `docs-thin` (`4ceb659`)

| # | Was testen | Erwartung | Status | Notizen |
| --- | --- | --- | --- | --- |
| 1 | Wegwerf-Case frisch anlegen, `:Case solved` (oder `:Case close`), `:Cases doctor` | `docs-thin` meldet `Summary.md` **trotz** 400 Zeichen Gerüst; Meldung sagt "of own text" | ❌ | |
| 2 | Echten Closed-/Solved-Case mit ordentlicher Doku | **Kein** `docs-thin` | ❌ | |
| 3 | Dieselbe `Summary.md` des Wegwerf-Cases um 3–4 Sätze ergänzen, `:Cases doctor` | Fund verschwindet | ❌ | |
| 4 | Anzahl `docs-thin`-Funde im echten Bestand | Plausibel (mehr als vorher ist möglich: Gerüst zählt nicht mehr); keine offensichtlich falschen Funde bei gut dokumentierten Cases | ❌ | |

### A5 · Engine-Steckbrief im Faktenblock (`86d418b`)

| # | Was testen | Erwartung | Status | Notizen |
| --- | --- | --- | --- | --- |
| 1 | Wegwerf-Case `:Case new 999001` mit Titel `Appium session fails on Android 14`, Stream in die Zwischenablage, `:Case ki`, Prompt irgendwo einfügen | Im Block "Ermittelte Fakten" eine Zeile `Engine-Steckbrief: EngineLab/Engines/Mobile/00_Engine.md` | ❌ | |
| 2 | Titel mit `Fiori` und `Excel` | Zwei Steckbriefe, alphabetisch (`Excel`, `SAP`), nie mehr als zwei | ❌ | |
| 3 | Titel ohne Stichwort (z. B. `Grid stays red`) | **Keine** Steckbrief-Zeile | ❌ | |
| 4 | Titel mit `Therapist` oder `index` | Keine Zeile (nur ganze Wörter) | ❌ | |
| 5 | Die genannte Datei | Existiert tatsächlich unter `C:/repos/WKDBook-Tricentis/EngineLab/Engines/…` | ❌ | |

### A6 · `:Case spotlight` (`165ce12`) — braucht `spotlight.nvim`

| # | Was testen | Erwartung | Status | Notizen |
| --- | --- | --- | --- | --- |
| 1 | `:Case spotlight 977392` | Stream öffnet sich, Fehlercodes/KBA-Nummern/Versionen/Anhangsnamen sind farbig markiert, jede in eigener Farbe | ❌ | |
| 2 | Mehr als 8 Tokens im Stream | Warnung nennt die nicht untergebrachten (Anhänge zuletzt) samt Hinweis `:Spotlight clear` | ❌ | |
| 3 | Vorher eigenen Spotlight setzen (`:Spotlight add foo`), dann `:Case spotlight` | Eigener Spotlight bleibt **bestehen**, wird nicht gelöscht | ❌ | |
| 4 | `:Case spotlight` ein zweites Mal | Keine Doppelmarkierung, Meldung zu "bereits markiert" | ❌ | |
| 5 | Case ohne Stream | Warnung "no Activity Stream found", nichts passiert | ❌ | |
| 6 | Stream ohne Token | Meldung "nothing to spotlight", Datei öffnet sich trotzdem | ❌ | |
| 7 | `spotlight.nvim` deaktivieren | Warnung "spotlight.nvim not installed", kein Fehler | ❌ | |

### A7 · Browser-Suche über `lib.nvim.deps` (`432e601`, hover `d17d610`, pdfport `a10c464`)

Reines Refactoring — es darf sich **nichts** ändern. Prüfen, dass die drei
Plugins ihren Browser noch finden.

| # | Was testen | Erwartung | Status | Notizen |
| --- | --- | --- | --- | --- |
| 1 | `:checkhealth casedesk` | Zeile `chrome found (<Pfad>) — :Cases export printing to PDF` | ❌ | |
| 2 | `:Cases export 977392` | PDF entsteht wie vorher | ❌ | |
| 3 | `:checkhealth hover` | Browser für Seiten-Screenshots gefunden (Hinweis "found off PATH" ist ok) | ❌ | |
| 4 | Mauszeiger/Cursor auf einen `https://docs.tricentis.com/…`-Link, `hover` auslösen | Screenshot-Vorschau erscheint wie vorher | ❌ | |
| 5 | `:checkhealth pdfport` | `chromium producer: ready (… browser: <Pfad>)` | ❌ | |
| 6 | Browser temporär umbenennen oder PATH/`paths` verbiegen (nur wenn leicht machbar) | Klare Meldung "no Chromium browser found", **kein Absturz** von `:checkhealth casedesk` | ❌ | |

### A8 · `:Case imp` — Notizen zu Case, Firma, Kontakt (`159d545`, `ba528a7`)

**Wichtig:** Das schreibt nach `C:/repos/WKDBook-Tricentis/Cases/Important.jsonl`.
Zum Testen **neutrale** Texte verwenden und am Ende alles mit `:Case imp done`
wieder entfernen (Test 17). Eine echte Notiz zu einem echten Kunden ist
gewollt — nur Testnotizen dürfen nicht übrig bleiben.

| # | Was testen | Erwartung | Status | Notizen |
| --- | --- | --- | --- | --- |
| 1 | `:Case imp 977392` ohne Notizen | Info "no notes on file — `:Case imp add` writes one" | ❌ | |
| 2 | `:Case imp add 977392` | Erst Auswahl "Note for": **Case 977392**, **Company: Siemens Energy …**, **Contact: …** (Firma/Kontakt nur, wenn das Sidecar sie kennt) | ❌ | |
| 3 | Company wählen → Level wählen (`Hinweis`/`Eskalation`) → Formular | Formular fragt Text und "Valid until (YYYY-MM-DD)" | ❌ | |
| 4 | Eskalation `TEST: Manager urgiert First Response`, kein Datum, speichern | Meldung "saved: [ESKALATION · Firma: …] …" | ❌ | |
| 5 | `Cases/Important.jsonl` im Editor öffnen | **Eine** JSON-Zeile pro Notiz, lesbar | ❌ | |
| 6 | `:Case imp 977392` | Viewer zeigt die Notiz | ❌ | |
| 7 | `:Case info 977392` | Notiz steht **in der Karte** (unter den Feldern) | ❌ | |
| 8 | `:Case open 977392` | Hinweis erscheint **als Warnung** (wegen Eskalation), bevor die Datei aufgeht | ❌ | |
| 9 | `:Case imp 1229161` (andere Case, **dieselbe Firma**) | Dieselbe Notiz erscheint — Match über das Sidecar-Feld `company` | ❌ | |
| 10 | `:Case imp 1195796` (andere Firma) | Keine Notiz | ❌ | |
| 11 | Firmen-Match mit anderer Schreibweise (im Sidecar `company` kurz groß/klein ändern, danach zurück) | Match bleibt (Groß-/Kleinschreibung egal), aber **kein** Match bei ähnlichem anderem Namen | ❌ | |
| 12 | Notiz mit "Valid until" in der Vergangenheit (z. B. `2020-01-01`) | Erscheint nicht in `:Case imp`/Info/Open; `:Cases imp` zeigt sie als `abgelaufen 2020-01-01` | ❌ | |
| 13 | Ungültiges Datum `morgen` | Fehler "valid_until must be YYYY-MM-DD", nichts gespeichert | ❌ | |
| 14 | Leerer Text | Fehler, nichts gespeichert | ❌ | |
| 15 | `:Case new 999001` mit derselben Firma wie die Testnotiz (Company-Feld beim Anlegen) | Direkt nach dem Anlegen **eine** Meldung: "<Firma> hatte schon N Case(s): …" **und** die Notiz — nicht zwei getrennte Meldungen; Warnstufe wegen Eskalation | ❌ | |
| 16 | `:Case new` für eine Firma ohne frühere Cases/Notizen | **Keine** Meldung | ❌ | |
| 17 | `:Case imp done 977392` → Notiz wählen → bestätigen; auch Abgelaufene (Test 12) entfernen | "note retired"; `Important.jsonl` ist wieder leer bzw. ohne Testzeilen; `:Cases imp` meldet "no notes on file" | ❌ | |
| 18 | `:Case imp done`, Rückfrage mit **Nein** | Notiz bleibt | ❌ | |
| 19 | `:Cases imp` mit mehreren Notizen | Alle gelistet, Abgelaufene markiert | ❌ | |
| 20 | Eine Zeile in `Important.jsonl` von Hand kaputt machen (`{kaputt`) | `:Case info`/`:Case open` laufen **weiter** (Hinweis "teilweise unlesbar"); `:Case imp add` verweigert das Schreiben mit klarer Meldung; danach Zeile reparieren | ❌ | |
| 21 | `<Tab>` nach `:Case imp <Tab>` | `add` und `done` erscheinen neben den Case-Nummern | ❌ | |
| 22 | Git: `Important.jsonl` im Status von `WKDBook-Tricentis` | Tauchen als Änderung auf; nach `done` wieder sauber (nicht committen, solange Testzeilen drin sind) | ❌ | |

### A9 · `:Case preflight` und Hinweise (`1717d44`)

| # | Was testen | Erwartung | Status | Notizen |
| --- | --- | --- | --- | --- |
| 1 | `:Case preflight <Tab>` | Schlägt `dex` vor | ❌ | |
| 2 | `:Case preflight dex 1226959` | Legt `Research/DEX_Preflight.md` an und öffnet sie: **Abschnitt 1 ist GPO/Anmeldung**, dann Gruppen, Logs, Tosca-Konfiguration; Checkboxen, Links klickbar | ❌ | |
| 3 | Erneut ausführen | Öffnet die vorhandene Datei, **überschreibt nichts** (vorher ein Häkchen setzen und prüfen) | ❌ | |
| 4 | `:Case new 999001` mit Titel `Unattended run stops after reboot` | Hinweis: `DEX (Stichwort „unattended“): … — :Case preflight dex` | ❌ | |
| 5 | `:Case activity` mit einem Stream, der "DEX agent"/"Distributed Execution" enthält | Derselbe Hinweis nach dem Einfügen (solange `DEX_Preflight.md` fehlt) | ❌ | |
| 6 | Nach `:Case preflight dex` im selben Case `:Case activity` erneut | **Kein** Hinweis mehr | ❌ | |
| 7 | `:Case new` mit Titel `How does the Execution List folder structure work?` | Scope-Frage "Consulting/Enablement statt Defekt?" samt zwei Wiki-Links | ❌ | |
| 8 | Titel `How to fix the error on startup` und `Unmapped Control after Fiori update` | **Kein** Scope-Hinweis | ❌ | |
| 9 | Titel ohne Stichwort (`Grid stays red`) | Gar kein Hinweis | ❌ | |
| 10 | `:Case preflight nope` | Warnung "unknown preflight topic", nichts angelegt | ❌ | |
| 11 | Gefühl: Nerven die Hinweise? | Nicht bei normalen Cases; nur wenn sie passen | ❌ | |

### A10 · `:Case image getText` (`7717d0c`) — braucht `images.nvim` + `tesseract`

| # | Was testen | Erwartung | Status | Notizen |
| --- | --- | --- | --- | --- |
| 1 | `:Case image getText 1201484` | Picker mit den Bildern aus `assets/` (mit Marker, ob ein Sidecar existiert) | ❌ | |
| 2 | `failed_login_errorlog.png` wählen, **ohne** Preset | Viewer: Kopfzeile `preset default`, Text zerrissen (≈51 Zeilen), **keine** JSON-Zeile | ❌ | |
| 3 | `:Case image getText 1201484 --preset=log` | `preset log`, ≈27 Zeilen, Zeile `JSON-Validierung: N/M Zeile(n) valide` (erwartet 1/24) | ❌ | |
| 4 | `y` im Viewer | Text in der Zwischenablage ("copied") | ❌ | |
| 5 | Vor `w` den Ordner prüfen | **Kein** `*.ocr.md` entstanden, nur durch Ansehen | ❌ | |
| 6 | `w` im Viewer | `failed_login_errorlog.png.ocr.md` entsteht; öffnen: H1, Bildlink, Warnhinweis, JSON-Zeile, Text | ❌ | |
| 7 | `:Cases grep` auf ein Wort aus dem OCR-Text | Findet jetzt die Sidecar-Datei | ❌ | |
| 8 | Case mit **einem** Bild | Wird ohne Auswahl direkt gelesen | ❌ | |
| 9 | Case ohne Bilder | Warnung "no images in assets/" | ❌ | |
| 10 | `<Tab>` nach `--preset=` | `default`, `log` | ❌ | |
| 11 | `tesseract` nicht erreichbar (nur wenn leicht machbar) | Klare Meldung mit Installationshinweis, kein Absturz | ❌ | |
| 12 | Dasselbe Bild danach mit `:Case ocr 1201484` | Sidecar ist "current", wird übersprungen | ❌ | |

### A11 · `:Case translate` — Fix und `stream` (`9f104ba`) — braucht `language.nvim`, Internet

Der Fix ist wichtig: **vorher hat `:'<,'>Case translate` immer den ganzen Puffer
übersetzt.**

| # | Was testen | Erwartung | Status | Notizen |
| --- | --- | --- | --- | --- |
| 1 | Puffer mit mehreren Absätzen, **einen** visuell markieren, `:'<,'>Case translate EN` | Popup übersetzt **nur die Auswahl** | ❌ | |
| 2 | Dasselbe ohne Auswahl | Der ganze Puffer | ❌ | |
| 3 | Auswahl über zwei, drei Zeilen (V-Modus) | Genau diese Zeilen | ❌ | |
| 4 | `:Case translate` ohne `[lang]` | Übersetzt nach `DE` | ❌ | |
| 5 | `:Case translate stream 977392` | Öffnet den Stream, Popup mit deutscher Übersetzung, Buffer unverändert | ❌ | |
| 6 | `:Case translate stream 977392 --to=FR` | Französisch | ❌ | |
| 7 | `:Case translate stream` im Case-Buffer ohne Nummer | Nimmt den Case des aktuellen Buffers | ❌ | |
| 8 | Case ohne Stream | Warnung "no Activity Stream found" | ❌ | |
| 9 | Ohne Internet | Klarer Fehler von `language.nvim`, kein Hänger | ❌ | |
| 10 | `<Tab>` nach `:Case translate <Tab>` | `stream` taucht auf | ❌ | |
| 11 | `language.nvim` deaktiviert | Warnung "language.nvim not installed" für beide Formen | ❌ | |

### A12 · `:Case jql suggest` (`10ababe`)

| # | Was testen | Erwartung | Status | Notizen |
| --- | --- | --- | --- | --- |
| 1 | `:Case jql suggest 977392` | `Research/JQL.md` öffnet sich mit dem Block "Aus den Fakten": eine Suche je Fehlercode/KBA, ggf. "Fehlercode in Version …", ggf. "SAP Component …, letzte 180 Tage" | ❌ | |
| 2 | Jede Suche als `jql`-Fence, in Jira einfügen | Gültige Syntax, liefert Treffer oder sinnvoll "keine" | ❌ | |
| 3 | Gerüst darüber (Platzhalter-Erklärung, eigener Text) | **Unverändert** | ❌ | |
| 4 | Erneut ausführen | **Ein** Block (ersetzt, nicht verdoppelt); Datum aktualisiert | ❌ | |
| 5 | Text unterhalb des Blocks von Hand ergänzen, erneut ausführen | Dein Text bleibt | ❌ | |
| 6 | Die Suchen enthalten **nie** den Case-Titel; kein `project =` | ✔ | ❌ | |
| 7 | Case ohne Stream | Warnung "`:Case activity` first" | ❌ | |
| 8 | Stream ohne Fehlercode/KBA/Component | Info "nothing to search for", nichts geschrieben | ❌ | |
| 9 | Plain `:Case jql 977392` | Öffnet weiterhin nur die Datei | ❌ | |

### A13 · Ablage und Doku

| # | Was testen | Erwartung | Status | Notizen |
| --- | --- | --- | --- | --- |
| 1 | `docs/ROADMAP/Casedesk/` in der nvim-Config | Nur `IMPLEMENTIERUNGSPLAN.md` und `Tasks.md` | ❌ | |
| 2 | `IMPLEMENTIERUNGSPLAN.md` dort öffnen | Auf dieser Maschine nur eine Textzeile mit dem Zielpfad (`E:/…`) — **echten Symlink anlegen** (erhöhte PowerShell, Befehl in §6 des Plans); danach zeigt die Datei den Plan | ❌ | |
| 3 | Plan lesen: `WKDBooks/Development/wkdbook-myplugins/casedesk.nvim/IMPLEMENTIERUNGSPLAN.md` | Stand, Stufen, was offen ist, stimmt mit dem überein, was du erlebst | ❌ | |
| 4 | `ROADMAP/ROADMAP.md` lesen | Nur Offenes, keine erledigten Punkte | ❌ | |
| 5 | `:help casedesk` / `CHEATSHEET.md` | Neue Befehle (`imp`, `preflight`, `jql suggest`, `image getText`, `spotlight`, `translate stream`) stehen im Cheatsheet; `doc/casedesk.txt` ist **noch nicht** nachgezogen (Lücke, ggf. eigener Punkt) | ❌ | |

---

## Teil B — aus der Vorsitzung (2026-09-30) noch ungetestet

Die ausführlichen Zeilen mit Erwartungen stehen in
`WKDBooks/Development/wkdbook-myplugins/ALL/manual-test-checklists/casedesk-neu-2026-09-30.md`
(dort 51 Zeilen offen) — hier nur die Blöcke und was bei jedem **zuerst**
zu prüfen ist. Status bitte in **dieser** Datei führen und in der anderen
nachziehen, wenn du magst.

| # | Block (Commit) | Zuerst prüfen | Status | Notizen |
| --- | --- | --- | --- | --- |
| B1 | SNOW-Aliase `:Cases account`/`contact`, `find account=` (`7222d0c`) | `:Cases account <Firma>` liefert dasselbe wie `:Cases company <Firma>` | ❌ | |
| B2 | `:Case open` → `Summary.md` (`a929e1c`, `c67f99f`) | Öffnet `Summary.md` direkt, **danach** Reveal im Filetree; Case ohne Summary öffnet neueste Datei | ❌ | |
| B3 | `:Case attachments find`/`insert` (`0e5fae0`) | `find` zeigt Anhänge **aller** Cases; `insert` öffnet den nativen Dateidialog und verschiebt nach `assets/` | ❌ | |
| B4 | Filetree-Reveal (`e6f5163`) | Kein Fehler "reveal nicht vorhanden", Baum zeigt die Datei | ❌ | |
| B5 | `:Case clean` und Auto-Cleanup in `:Case ki import` (`978fd82`) | `utm_source=gemini` und `$\rightarrow$` verschwinden; `clean cwd` fragt vor dem Schreiben | ❌ | |
| B6 | `:Case swat` und `:Case sync` (`042e8a1`) | `SWAT/Technicals.md` bei neuem Case; bei altem Warnung, nach `:Case sync` vorhanden | ❌ | |
| B7 | **`:Cases doctor` gegen den echten Bestand** (`204ccd0`, `ccfcef7`) | Funde `stale-unconfirmed`; **`:Cases normalize` verschiebt echte Ordner `Open` → `Closed`** — erst mit Wegwerf-Case, dann Trockenlauf-Viewer genau lesen. Das ist der offene Handgriff `RM-05` c | ❌ | |
| B8 | `docs-thin` (`f116ab8`) | Siehe A4 oben | ❌ | |
| B9 | `:Case ocr --preset=log` und JSON-Zeile im Sidecar (`eb61531`, `5998c00`) | `--preset=log` liefert Zeilenstruktur; Sidecar enthält die JSON-Validierungszeile | ❌ | |
| B10 | `:Case insert asset` setzt den Cursor in den Link (`dd58bc1`) | Nach dem Einfügen steht der Cursor im Linktext | ❌ | |
| B11 | `:Case translate` Grundfunktion (`f7cffee`) | Siehe A11 | ❌ | |

---

## Teil C — Smoke-Inventar aller Routen

Eine Zeile je Route aus `docs/commands.md`: einmal ausführen, prüfen, dass sie
tut, was die Beschreibung sagt, und **nichts wirft**. Detail-Erwartungen für die
älteren Befehle: `ALL/manual-test-checklists/casedesk.md` (81 Zeilen, alle noch
❌). Mit ★ markiert: neu oder geändert am 2026-10-02 (Details in Teil A).

Wegwerf-Case benutzen für alles, was schreibt, verschiebt oder löscht.

### `:Case` — ein Case

| # | Route | Smoke | Status | Notizen |
| --- | --- | --- | --- | --- |
| C1 | `:Case` | Infocard des aktuellen Buffers, sonst Auswahl | ❌ | |
| C2 | `:Case new [nr]` ★ | Fragt fehlende Felder, Vorschau, Bestätigung, legt an; danach ggf. Firmen-/Notiz-/Preflight-Hinweis (A8, A9) | ❌ | |
| C3 | `:Case info [nr]` ★ | Karte mit Feldern; Notizen erscheinen (A8); `e`/`s`/`o` | ❌ | |
| C4 | `:Case open [nr]` ★ | Öffnet `Summary.md`, Reveal; Notiz-Hinweis (A8) | ❌ | |
| C5 | `:Case summary` / `notes` / `research` / `reply` / `task` / `swat` / `jql` | Öffnet jeweils die Datei; fehlend → Hinweis auf `:Case sync` | ❌ | |
| C6 | `:Case sync [nr]` | Legt fehlende Blueprint-Dateien an, überschreibt nichts | ❌ | |
| C7 | `:Case activity [nr]` ★ | Zwischenablage als `Research/NN_ActivityStream.md`; Priorität/Komponente/Versionen werden erkannt; Preflight-Hinweis (A9) | ❌ | |
| C8 | `:Case add <name> [suffix]` | Neue Markdown-Datei, `reply [suffix]` nummeriert | ❌ | |
| C9 | `:Case copy [src]` | Kopiert Datei in den Case, Zielordner wählbar | ❌ | |
| C10 | `:Case attachments [nr]` | Liste der Anhänge, Öffnen | ❌ | |
| C11 | `:Case attachments find` / `insert` | Siehe B3 | ❌ | |
| C12 | `:Case files [nr]` / `:Case grep [nr]` | Picker bzw. Live-Grep im Case-Ordner (pickers.nvim) | ❌ | |
| C13 | `:Case insert [field] [nr]` | Fügt Token am Cursor ein und kopiert; `asset` setzt Cursor in den Link (B10) | ❌ | |
| C14 | `:Case template [name]` | Fügt Reply-Block aus `Workflow/Templates` ein | ❌ | |
| C15 | `:Case reply check` | Gate: Emojis, Überschriften, tote Links; `c`/`s` im Viewer | ❌ | |
| C16 | `:Case links [nr]` | Doku-Links mit falscher Tosca-Version | ❌ | |
| C17 | `:Case versions [component] [nr] [--all] [--raw]` | Versions-Digest aus ToscaSupportInfo | ❌ | |
| C18 | `:Case snow [nr]` | Öffnet bzw. kopiert die SNOW-Ticket-ID | ❌ | |
| C19 | `:Case sla [nr] [--doc]` | Drei Uhren mit Restzeit; `--doc` öffnet die Vereinbarung | ❌ | |
| C20 | `:Case timeline [nr]` | Arbeitssitzungen; Pull-Stempel als "nicht messbar" | ❌ | |
| C21 | `:Case similar [nr] [n]` ★ | Ähnliche Cases mit Trefferwörtern; Synonyme (A2) | ❌ | |
| C22 | `:Case diff stream\|solution <andere> [nr]` | diff.nvim vergleicht (A: Stream oder Lösung) | ❌ | |
| C23 | `:Case solution [nr] [--edit]` | Lösungs-Viewer, `e`/`y`; ohne Lösung Angebot zum Anlegen | ❌ | |
| C24 | `:Case ki [nr]` ★ | Prompt in die Zwischenablage, Faktenblock inkl. Engine-Steckbrief (A5) | ❌ | |
| C25 | `:Case ki import [nr]` ★ | Teilt die Antwort in Analyse/Reply/Notiz; Schreibweise (A3), Paste-Cleanup (B5) | ❌ | |
| C26 | `:Case anonymize [nr]` ★ | Siehe A1 | ❌ | |
| C27 | `:Case clean [cfile\|cwd\|path=…]` | Siehe B5 | ❌ | |
| C28 | `:Case ocr [nr] [--force] [--lang] [--preset]` | Sidecars für alle Bilder (nur bei neuem/geändertem Bild) | ❌ | |
| C29 | `:Case image getText [nr] [--preset] [--lang]` ★ | Siehe A10 | ❌ | |
| C30 | `:Case spotlight [nr]` ★ | Siehe A6 | ❌ | |
| C31 | `:Case jql suggest [nr]` ★ | Siehe A12 | ❌ | |
| C32 | `:Case translate [lang]` ★ / `translate stream` ★ | Siehe A11 | ❌ | |
| C33 | `:Case preflight <topic> [nr]` ★ | Siehe A9 | ❌ | |
| C34 | `:Case imp` / `imp add` / `imp done` ★ | Siehe A8 | ❌ | |
| C35 | `:Case route [nr]` | Fragt Abteilung (`config.routing_targets`), schreibt `routed_to` | ❌ | |
| C36 | Zustandswechsel `:Case solved` / `t2` / `assigned` / `unassigned` / `reassign` / `otheragent` | Verschiebt in den Zustandsordner; bei CS-Case kein `t2` | ❌ | |
| C37 | `:Case close [nr]` | Zielauswahl; bei Solved/Closed Angebot zur Lösung und ggf. Abteilung | ❌ | |
| C38 | `:Case reopen [nr]` | Zurück nach `Open` | ❌ | |
| C39 | `:Case delete [nr]` | Verlangt die Case-Nummer als Bestätigung; löscht wirklich (nur Wegwerf-Case!) | ❌ | |

### `:Cases` — der Querschnitt

| # | Route | Smoke | Status | Notizen |
| --- | --- | --- | --- | --- |
| C40 | `:Cases` / `:Cases list` | Alle Cases nach Zustand; `m` markiert, `c` schließt Markierte | ❌ | |
| C41 | `:Cases recent [n]` / `stale [days]` | Zuletzt benutzt bzw. lange unberührt | ❌ | |
| C42 | `:Cases stats` | Zähler nach Bereich/Zustand/Firma/Jahr | ❌ | |
| C43 | `:Cases area [SAP\|CS]` | Cases eines Bereichs, ohne Argument mit Zählern | ❌ | |
| C44 | `:Cases company\|name\|account\|contact\|title\|notes\|priority\|tosca_version\|outcome\|routed_to <pattern> [--exact] [--re]` | Filtert; Aliase (B1) | ❌ | |
| C45 | `:Cases find key=value …` | AND-Verknüpfung | ❌ | |
| C46 | `:Cases history [company]` | Alle Cases einer Firma nach Zustand | ❌ | |
| C47 | `:Cases grep <pattern> [--re]` / `livegrep` / `files` | Volltext über alle Cases; OCR-Sidecars werden gefunden | ❌ | |
| C48 | `:Cases insert [pattern]` | Token eines **anderen** Cases einfügen | ❌ | |
| C49 | `:Cases sla` / `sla report [--year]` | Dashboard bzw. Bericht | ❌ | |
| C50 | `:Cases solutions [pattern]` ★ | Suche über alle Lösungen; Synonyme (A2) | ❌ | |
| C51 | `:Cases terminology` | Alle Begriffe aller `Terminologie.md` | ❌ | |
| C52 | `:Cases doctor` ★ / `normalize` | Funde (u. a. `docs-thin` mit eigenem Text, `stale-unconfirmed`); `normalize` mit Trockenlauf (B7) | ❌ | |
| C53 | `:Cases links check [nr]` | Prüft docs.tricentis.com-Links auf tote Seiten | ❌ | |
| C54 | `:Cases export [nr]` ★ | PDF aus Summary/Notes/Research/Replies (A7) | ❌ | |
| C55 | `:Cases close` | Mehrere Cases schließen (Markierungen oder Multi-Select) | ❌ | |
| C56 | `:Cases pickers` | Menü: Anhänge, Links, Cases ohne Sidecar, Terminologie, Befehle, Lösungen | ❌ | |
| C57 | `:Cases imp` ★ | Alle Notizen (A8) | ❌ | |

### `:Tricentis` — über den Case-Baum hinaus

| # | Route | Smoke | Status | Notizen |
| --- | --- | --- | --- | --- |
| C58 | `:Tricentis` / `links [scope]` | Links aus dem ganzen Arbeits-Repo | ❌ | |
| C59 | `:Tricentis commands [topic]` | Picker, Auswahl landet in der Zwischenablage; `enginelab` ist ein Topic | ❌ | |
| C60 | `:Tricentis cheatsheet [topic]` | Gruppierter Scratch-Puffer aller Befehle | ❌ | |

---

## Teil D — Keymaps, Autocmds, Health

| # | Was testen | Erwartung | Status | Notizen |
| --- | --- | --- | --- | --- |
| D1 | Globale Keymaps | **Keine** — `:verbose map <leader>` zeigt nichts von casedesk | ❌ | |
| D2 | `:Cases list` Viewer | `m` (n/x) markiert, `c` schließt Markierte, `q`/`Esc` schließt | ❌ | |
| D3 | `:Case info` Viewer | `e` Formular, `s` Summary, `o` Ordner | ❌ | |
| D4 | `:Case reply check` Viewer | `c` (nur bei Emojis) entfernt sie, `s` Spellcheck | ❌ | |
| D5 | `:Case solution` Viewer | `e` bearbeiten, `y` kopiert den Abschnitt `## Lösung` | ❌ | |
| D6 | **neu:** `:Case image getText` Viewer ★ | `y` kopiert Text, `w` schreibt Sidecar, `q` schließt (A10) | ❌ | |
| D7 | **neu:** `:Case imp` / `:Cases imp` Viewer ★ | Schließt mit `q`/`Esc`, bei Fokusverlust | ❌ | |
| D8 | Autocmd `FocusGained` (`CasedeskSlaNotify`) | Zurück zu Neovim mit überfälligem P1/P2-Case offen → Warnung | ❌ | |
| D9 | Autocmd `BufEnter`/`BufWinEnter`/`WinEnter` (`CasedeskPin`) | Zwischen zwei Case-Buffern wechseln → Pin-Chip zeigt den neuen Case sofort | ❌ | |
| D10 | `:Case imp` im **Pin-Chip** | Noch **nicht** gebaut (Folgepunkt) — nichts erwarten | ❌ | |
| D11 | `:checkhealth casedesk` | Siehe V2 | ❌ | |
| D12 | `:Lib deps show casedesk.nvim` | Zeigt die deklarierten Werkzeuge (pandoc, Chromium, tesseract, curl, ripgrep) mit Status | ❌ | |
| D13 | Statusline | SLA-Badge und Case-Label arbeiten weiter | ❌ | |

---

## Nach dem Durchlauf

- [ ] Gefundene Fehler als `RM-nn` in die Roadmap oder als GitHub-Issue
      (`StefanBartl/casedesk.nvim`) — nicht nur hier.
- [ ] Alle **Testnotizen** aus `Cases/Important.jsonl` entfernt, alle
      Wegwerf-Cases (`999001`) gelöscht, `git status` in `WKDBook-Tricentis` sauber.
- [ ] Diese Datei committen (`docs(casedesk): live-test results …`), damit der
      Stand über Sitzungen hinweg erhalten bleibt.
- [ ] Wenn ein Block ✅ ist: Zeile in `ALL/manual-test-checklists/casedesk-neu-2026-09-30.md`
      bzw. `casedesk.md` mit abhaken, damit die beiden Listen nicht auseinanderlaufen.
