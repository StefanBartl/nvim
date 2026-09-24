# casedesk.nvim — Audit: Bugs, Security/Privacy, Performance

**Stand:** 2026-09-19 (Runde 1), aktualisiert 2026-09-19 (Runde 2, s. [H](#h--zweite-runde-der-gesamte-diff-seit-runde-1))
**Prüfstand:** `$REPOS_DIR/casedesk.nvim` @ `df5eae9` (~14.000 Zeilen, 76 Lua-Module)
**Abhängigkeiten mitgelesen:** `$REPOS_DIR/lib.nvim`, `$REPOS_DIR/ui.nvim`

---

## Table of content

  - [Methode](#methode)
  - [Der durchgehende Fehlertyp](#der-durchgehende-fehlertyp)
  - [Empfohlene Reihenfolge](#empfohlene-reihenfolge)
  - [A — Datenverlust](#a--datenverlust)
  - [B — Privacy](#b--privacy)
  - [C — Security](#c--security)
  - [D — Konfiguration](#d--konfiguration)
  - [E — SLA-Rechnung](#e--sla-rechnung)
  - [F — Korrektheit](#f--korrektheit)
  - [G — Performance](#g--performance)
  - [H — Zweite Runde: der gesamte Diff seit Runde 1](#h--zweite-runde-der-gesamte-diff-seit-runde-1)
  - [Verworfene Funde](#verworfene-funde)
  - [Geprüft und freigesprochen](#geprüft-und-freigesprochen)
  - [Grenzen dieses Audits](#grenzen-dieses-audits)

---

## Methode

Zwei Durchläufe mit je fünf parallelen Findern über getrennte Flächen, danach
Deduplizierung und pro Fund drei **unterschiedliche** Verifizierer-Linsen statt
drei identischer Skeptiker:

| Linse | Frage |
|---|---|
| Erreichbarkeit | Lässt sich der konkrete Aufrufpfad von einer echten Benutzeraktion bis hierher konstruieren? |
| Absichtlichkeit | Ist das Verhalten laut umgebendem Kommentar / `docs/` eine dokumentierte Entscheidung? |
| Konsequenz | Entsteht messbarer Schaden — falsches Ergebnis, Datenverlust, PII-Abfluss, spürbare Verlangsamung? |

Ein Fund gilt nur bei **2 von 3 Stimmen**. Voreinstellung der Verifizierer war
„widerlegt, wenn unsicher".

**Zahlen:** 58 Rohfunde → 48 verifiziert → **32 bestätigt** → 29 nach
Zusammenführung von Doppelmeldungen. 16 Funde sind in der Abstimmung gefallen.

Die Finder haben ihre Behauptungen überwiegend **empirisch** belegt (Module unter
`nvim --clean --headless -l` geladen und gegen echte Fixtures gefahren), nicht nur
argumentiert. Alle mit **[selbst verifiziert]** markierten Befunde habe ich
zusätzlich eigenhändig am Quelltext bzw. per Ausführung nachgeprüft.

### Bewertungsartefakte

Sechs Verifizierer-Läufe in Runde 2 sind an API-Schutzfiltern gestorben, nicht an
der Sache. Eine Bewertung ist dadurch verfälscht:

> **`ui/lifecycle.lua:628` steht in Runde 2 mit 1/1 in der Ablehnungsliste** —
> zwei seiner drei Prüfer sind ausgefallen, der Schwellwert verlangt zwei Stimmen.
> Derselbe Befund ist in Runde 1 mit **3/3 bestätigt** (→ CD-09). Er gilt.

---

## Der durchgehende Fehlertyp

Fast alle schweren Befunde sind derselbe Reflex:

> **Ein Fehlschlag oder eine Mehrdeutigkeit wird still in den Erfolgsfall gefaltet.**

- unlesbar → „existiert nicht" (CD-01)
- Ziel existiert → Markierung, die nie gesetzt wird (CD-03)
- kein Regex-Treffer → „nichts zu schwärzen" (CD-06, CD-07, CD-08)
- zwei Treffer → „keiner" (CD-19)
- Mark ohne Auflösung → verschwindet aus der Zählung (CD-09)
- falsche Einheit → Warnung unterbleibt (CD-15)
- kein Case-Match → Entwarnung (CD-17)

In jedem Fall **erkennt** der Code den Sonderfall — er meldet ihn nur nicht, und
die Rückmeldung an den Benutzer sagt „erledigt".

**Struktureller Hebel statt 29 Einzelfixes:** Überall dort, wo eine Funktion
„nichts gefunden" und „konnte nicht nachsehen" auf denselben Rückgabewert
abbildet, gehören die beiden getrennt. Das deckt CD-01, CD-03, CD-06/07/08,
CD-17 und die SLA-Schwellen in einem Zug ab.

---

## Empfohlene Reihenfolge

### Stand der Umsetzung

| Rang | IDs | Stand |
|---|---|---|
| 1 | CD-03, CD-04 | ✅ behoben, `2ee2541`, 4 Regressionstests |
| 2 | CD-01, CD-02 | ✅ behoben, `e5c13d3`, 3 Regressionstests |
| 3 | CD-05, CD-10 | ✅ behoben, `c196644`, 6 Regressionstests (neues `TESTS/copy_spec.lua`) |
| 4 | CD-06, CD-07, CD-08 | ✅ behoben, `b285e0f`, 11 Regressionstests + neuer `names_missed`-Zähler |
| 5 | CD-11 | ✅ behoben, `78962c5`, 7 Regressionstests (neues `TESTS/export_spec.lua`) — JS-Flag gemessen und verworfen, s. u. |
| 6 | CD-12, CD-13 | ✅ behoben, `ec0bad6`, 4 Tests |
| 7 | CD-14…CD-16, CD-18, CD-20 | ✅ behoben, `a1aba5c`, 4 Tests |
| — | CD-17, CD-19, CD-22, CD-26 | ✅ behoben, `6124427`, 4 Tests |
| — | CD-21, CD-23, CD-24, CD-25 | ✅ behoben, `bd51ea3`, 5 Tests |
| — | CD-28, CD-29 | ✅ behoben, `acbad1b`, gemessen 396→40 Syscalls/Fall |
| — | CD-09 | ✅ behoben, `07e9fac`, Marks nach Area+Nummer |
| — | CD-27 | ✅ bereits durch `f14249a` (parallele Sitzung) erledigt |
| — | **Gesamt** | **alle 29 Befunde geschlossen**; Suite 547 grün, luacheck/stylua sauber |
| — | Nachprüfung | ✅ `321cfb1` — Review der beiden Fixes: 14 Rohfunde, 1 bestätigt (O(n²) in der neuen Verschattungsprüfung), behoben; Details unten |

### Nachprüfung der Umsetzung (2026-09-19)

Beide Fix-Commits wurden nach demselben Verfahren gegengelesen (zwei Reviewer,
drei adversariale Linsen, 2 von 3 Stimmen). **14 Rohfunde, 1 bestätigt.**

**Bestätigt und behoben in `321cfb1`:** `shadowed_by_another_step` rief
`lib.nvim.fs.is_subpath`, das beide Argumente bei *jedem* Aufruf neu
normalisiert — bis zu 4n² `vim.fs.normalize`-Aufrufe über Pfade, die
`doctor.lua` ohnehin aus einem `entry.dir` zusammensetzt. Eigene Messung
(nvim 0.12.2/LuaJIT, alte gegen neue Form auf identischen Eingaben):
154 ms → 1,6 ms bei n=100, 2,7 s → 19 ms bei n=400, Faktor 96–145×.
Im eingeschwungenen Zustand irrelevant; der erste Lauf über ein Alt-Korpus
ist aber genau der Zweck des Kommandos.

**Mitgenommen:** Die Überschrift der Skip-Liste (`ui/cases.lua`) behauptete
„ambiguous — target exists". Es gibt drei Skip-Gründe; die Überschrift konnte
nur für einen stimmen — schon vor `2ee2541` beim Duplikat-Ziel-Fall.

**Verworfen, aber festgehalten:** `migrate.lua:124` enthält dieselbe
`meta.read(...) or {}` → `meta.write`-Kette, die CD-01/CD-02 geschlossen haben.
Zwei Reviewer meldeten es unabhängig, sechs Verifizierer-Stimmen verwarfen es:
`casedesk.migrate` hat **keinen Aufrufer** in `lua/` (nur `TESTS/migrate_spec.lua`
requiret es, `docs/map` führt es als `unreferenced-module`) und ist an kein
Kommando gebunden. Latent korrekt, aktuell unerreichbar — **zu beheben, bevor
`migrate` je verdrahtet wird.**

| Rang | IDs | Begründung |
|---|---|---|
| 1 | CD-03, CD-04 | Datenverlust an echten Falldokumenten, sechs Zeilen Aufwand |
| 2 | CD-01, CD-02 | Sidecar-Überschreibung, trifft jeden Fall |
| 3 | CD-05, CD-10 | `:Case copy` zerstört bzw. verfälscht Dateien |
| 4 | CD-06, CD-07, CD-08 | PII verlässt das Korpus, Report meldet Vollzug |
| 5 | CD-11 | Kundeninhalt im Headless-Browser mit JS + Netz |
| 6 | CD-12, CD-13 | Konfigurationsoptionen wirken nicht wie dokumentiert |
| 7 | CD-14…CD-18 | SLA-Rechnung und falsche Entwarnungen |
| 8 | CD-19…CD-25 | Korrektheit, einzeln klein |
| 9 | CD-26…CD-29 | Performance |

---

## A — Datenverlust

### CD-01 · `lua/casedesk/meta.lua:45` · CRITICAL · 3/3 · **[selbst verifiziert]** · ✅ **behoben in `e5c13d3`**

**Eine existierende, aber unlesbare `.case.json` wird als „noch keine Datei" eingestuft.**

`M.read` unterscheidet „fehlt" von „kaputt" per `not err:match("^read failed")`.
Die Kette dahinter macht diesen Test wirkungslos:

- `lib.nvim.fs.read` liefert `"open failed: …"` (ENOENT, EACCES, Sharing-Violation)
  bzw. `"read failed: …"`.
- `lib.nvim.fs.json.read` verpackt **jeden** dieser Fehler erneut:
  `return nil, "read failed: " .. tostring(read_err)`.

Der Präfixtest trifft damit nie einen I/O-Fehler, sondern ausschließlich einen
Decode-Fehler. `M.read` antwortet `nil, nil` = „noch keine Sidecar".

`M.patch` nimmt daraufhin exakt den Zweig, den sein eigener Kommentar als
verboten beschreibt („falling back to the 'no sidecar yet' stub there would
silently overwrite every other field already on disk"), schreibt
`{ case, year, links = {} }` plus das gepatchte Feld über die Datei und gibt
`ok = true` zurück.

**Auslöser:** Ein Virenscanner, OneDrive-Sync oder Indexer, der die Datei einen
Moment offen hält. Titel, Firma, Name, Notizen, Priorität, `routed_to` sind
danach weg — ohne Fehlermeldung.

**Fix:** Die Existenz vom Dateisystem erfragen statt aus dem Fehlertext zu raten:

```lua
-- in M.read, wenn json.read fehlschlägt:
if (vim.uv or vim.loop).fs_stat(path(case_dir)) then return nil, err end
```

---

### CD-02 · `lua/casedesk/ui/infocard.lua:122` · HIGH · 3/3 · ✅ **behoben in `e5c13d3`**

**`:Case info` → `e` umgeht den Schutz aus CD-01.**

`infocard.lua:58` verwirft den zweiten Rückgabewert von `meta.read`. Der
Bearbeiten-Pfad schreibt anschließend per `meta.write` einen 9-Feld-Stub über
eine Sidecar, die beim Parsen gescheitert ist — genau das, was `meta.patch`
verweigert.

**Auslöser:** Handgeeditierte `.case.json` mit nachgestelltem Komma. Die Warnung
„meta read: …" scrollt vorbei, die Karte rendert aus `detect.guess`, der Benutzer
korrigiert den Titel und speichert.

**Fix:** `local m, read_err = meta.read(entry.dir)` und das Formular bei gesetztem
`read_err` gar nicht erst öffnen — oder den Submit über `meta.patch` routen, das
bereits korrekt verweigert.

---

### CD-03 · `lua/casedesk/doctor.lua` · CRITICAL · 3/3 · **[selbst verifiziert]** · ✅ **behoben in `2ee2541`**

**`to = exists(to) and nil or to` liefert immer `to` — die „nicht automatisch
reparieren"-Markierung existiert nicht.**

In Lua ist `true and nil` → `nil`, und `nil or to` → `to`. Beide Zweige
evaluieren zum selben Wert. Nachgemessen:

```
cond=true   -> ergebnis=/case/Solution.md
cond=false  -> ergebnis=/case/Solution.md
```

`doctor.lua` markiert einen mehrdeutigen Befund per `to = nil`, und
`normalize.lua` baut seinen **gesamten Sicherheitsvertrag** darauf auf — der
Modulkopf sagt wörtlich, so markierte Befunde seien „never touched here".

**Betroffene Zeilen (sechs):** 279, 421, 439, 454, 469, 484.

**Bemerkenswert:** Zeile 349 derselben Datei trägt einen Kommentar, der die Falle
exakt beschreibt — „NOT `has_notes and nil or (...)`: that idiom breaks precisely
when the 'true' branch is nil … it would always evaluate to the fallback" — und
dort steht die korrekte Form. Das Wissen war da, es hat die anderen sechs
Stellen nicht erreicht.

**Fix:** Überall die Form aus Zeile 354 verwenden:

```lua
to = (not exists(to)) and to or nil,
```

**Siebte Fundstelle, kein aktueller Bug:** `solution.lua:247`
(`current_raw = current_key and nil or vim.trim(heading)`). `flush()` prüft
`current_key` zuerst und liest `current_raw` nur im `elseif`, wo der Ausdruck
ohnehin das Richtige liefert. Funktioniert durch die Reihenfolge, nicht durch
Absicht — beim Aufräumen mitnehmen.

---

### CD-04 · `lua/casedesk/normalize.lua:98` · CRITICAL · 3/3 · ✅ **behoben in `2ee2541`**

**Der Kollisionsschutz greift eine Ebene zu kurz: ein Schritt-Ziel darf innerhalb
des Ziels eines anderen Schritts liegen.**

> **Korrektur zur ursprünglichen Fassung dieses Befunds.** Hier stand zuerst
> „Ziel liegt in der *Quelle* eines späteren Schritts". Das ist falsch und fiel
> erst beim Schreiben des Regressionstests auf: die Quelle von Schritt 1 ist
> `Solutions/`, das Ziel von Schritt 2 ist `Solution/Solution.md` — die beiden
> sind Geschwister, `is_subpath` darauf ist korrekt `false`. Die gefährliche
> Beziehung ist **Ziel unter Ziel**. Der umgesetzte Fix prüft beide Richtungen.

`normalize.plan` zählt identische `to`-Werte, aber `<case>/Solution` und
`<case>/Solution/Solution.md` sind verschiedene Strings. `doctor.check()` gibt die
Befunde in Quellreihenfolge aus: erst die Ordner-Umbenennung `Solutions/` →
`Solution/` (doctor.lua:444-457), dann die Datei-Verschiebung `Solution.md` →
`Solution/Solution.md` (doctor.lua:459-471).

**Auslöser:** Ein Fall mit `Solutions/`-Ordner und einer flachen `Solution.md`.
Schritt 1 macht `Solutions/Solution.md` zu `Solution/Solution.md`. Schritt 2
schiebt die flache Datei per nacktem `uv.fs_rename` darüber. Das echte
Lösungsdokument ist vernichtet, gemeldet werden „2 items renamed".

**Zusammenhang mit CD-03:** CD-04 beschreibt eine Lücke in der zweiten
Verteidigungslinie. CD-03 zeigt, dass die **erste** nie scharf war. Zusammen ist
`:Cases normalize` derzeit ohne jeden Überschreibschutz.

**Fix:** Zwei Ebenen.

1. In `normalize.plan` zusätzlich jeden Kandidaten verwerfen, dessen `to` in
   (oder auf) einer anderen Kandidaten-`from` liegt.
2. In `normalize.run` unmittelbar vor dem Rename `uv.fs_stat(s.to)` prüfen und
   mit `false, "target appeared"` abbrechen, damit der Plan-Schnappschuss nicht
   veralten kann.

---

### CD-05 · `lua/casedesk/ui/copy.lua:48` · HIGH · 3/3 + 2/2 · ✅ **behoben in `c196644`**

**`:Case copy` schreibt nach `<case>/<basename>` ohne Existenzprüfung.**

`write_to_file` öffnet `"wb"` und trunkiert. Mit dem Ziel „(case root)" und einer
Quelle namens `Notes.md` oder `Summary.md` ist die eigene Falldatei weg — jene,
die `similar.lua` indiziert und `:Cases export` bündelt. Die Meldung lautet
„copied to <path>".

Das widerspricht der ausdrücklichen Richtlinie des Plugins („never overwrite an
existing file", `normalize.lua:6`, `plan.lua:4`). `ui/add.lua:76-79` macht es an
der gleichen Stelle richtig.

**Fix:** In `on_select` vor dem Schreiben:

```lua
if uv.fs_stat(dest) then
  notify.warn(dest .. " already exists — not overwritten")
  common.edit(dest)
  return
end
```

---

### CD-10 · `lua/casedesk/ui/copy.lua:48` · MEDIUM · 3/3 · ✅ **behoben in `c196644`** (auch in `apply.lua`)

**Jede kopierte Datei bekommt ein zusätzliches Newline-Byte.**

`M.copy` ist als read-whole-file → write-whole-file gebaut.
`lib.nvim.fs.write.to_file` ist per Vertrag ein **Text**-Primitiv:

```lua
if content ~= "" and not content:match("\n$") then content = content .. "\n" end
```

**Auslöser:** `:Case copy C:/…/screenshot.png` → Ziel `assets`. Die Kopie ist ein
Byte größer als das Original; jeder byte-genaue Vergleich (sha256, `fc /b`,
`cmp`) meldet Abweichung. Betrifft alle Binäranhänge — Screenshots, PDFs, ZIPs.

**Fix:** `require("lib.nvim.cross.fs.mutate").copy_file(source, dest)` verwenden
(wrapt `uv.fs_copyfile` inklusive der Transient-Lock-Wiederholung, die
`attachments.ingest` und `normalize.run` bereits nutzen). Gleiche Änderung im
`copy`-Zweig von `lua/casedesk/apply.lua:33-41`.

---

### CD-09 · `lua/casedesk/marks.lua:15` + `lua/casedesk/ui/lifecycle.lua:628` · MEDIUM · 3/3 · ✅ **behoben in `07e9fac`**

**Marks sind nur nach Fallnummer verschlüsselt, Areas sind aber getrennte
Nummernräume** (`registry.lua:106` sagt das ausdrücklich).

**Auslöser:** SAP/049885 und CS/049885 existieren beide. Ein `m` auf der CS-Zeile
markiert auch die SAP-Zeile. Bei `:Cases close` liefert `marks.list()` fünf
Nummern, `registry.find("049885")` findet zwei Einträge und gibt `nil` zurück —
vier Fälle werden verschoben, der Dialog sagt „Move 4 case(s)", und
`marks.clear()` wischt anschließend **alle fünf** Marks, auch den stillschweigend
übersprungenen.

**Fix:** Auf `area .. "/" .. short` verschlüsseln (denselben Schlüssel benutzt
`usage.lua:49` bereits) und Registry-Einträge statt nackter Nummern durchreichen:
`M.toggle(entry)`, `M.is_marked(entry)`, `M.list()` gibt `{area, short}`-Paare
zurück, `ui/lifecycle.lua:628` löst mit `registry.find(short, area)` auf.

---

## B — Privacy

Gemeinsamer Nenner der drei folgenden Befunde: **der Report lügt in die sichere
Richtung.** Nicht-Treffer werden als Null gezählt, und Null liest sich für den
Reviewer wie „nichts zu tun".

### CD-06 · `lua/casedesk/anonymize.lua:100` · CRITICAL · 3/3 · **[selbst verifiziert]** · ✅ **behoben in `b285e0f`**

**Namen, die mit einem Nicht-ASCII-Zeichen beginnen oder enden, werden nie
geschwärzt — und als Null gezählt.**

```lua
local pattern = "%f[%w]" .. vim.pesc(name) .. "%f[%W]"
```

Luas `%w` ist ASCII-`isalnum`. Jedes Byte eines UTF-8-Umlauts liegt außerhalb,
also scheitert die Frontier und `gsub` ersetzt **gar nichts** — nicht nur an
einer Stelle, sondern im ganzen Dokument. Weil `report.names` nur bei `n > 0`
hochzählt, fehlt der Name zusätzlich in der Zählung.

**Gemessen:** `("from: Ünal Demir schrieb."):gsub(pattern, "[Person 1]")` → `n=0`,
Text unverändert. Ebenso `Anna Weiß`. Die ASCII-Kontrollen `Anna Weiss` und
`Müller` (endet auf ASCII-`r`) → `n=1`.

**Besonders unangenehm:** `docs/EXTRACTION.md` §4 „Parser-Fallen" dokumentiert
genau diese Falle, verifiziert gegen den echten Stream `actsream4`:
*„Umlaut-Namen (Štefan Evin, Wolfgang Böhm) | Lua-Patterns mit `%w` greifen nicht
— Byte-Klassen bzw. `[^\n]` verwenden"*. Das Modul tut, wovor die eigene Doku warnt.

**Fix:** Zwei Teile.

1. Grenze aus einer Byte-Klasse bauen, die alles ≥ 0x80 als Wortzeichen behandelt:
   `"%f[%w\128-\255]" .. vim.pesc(name) .. "%f[^%w\128-\255]"`.
2. **Erkannte** Namen zusätzlich zu den **ersetzten** zählen und
   `detected - replaced > 0` laut melden, damit ein unerreichbarer Name nie als
   sauberes Null durchgeht.

---

### CD-07 · `lua/casedesk/anonymize.lua:106` · HIGH · 3/3 · ✅ **behoben in `b285e0f`**

**`_` fehlt in der E-Mail-Local-Part-Klasse.**

`[%w%.%%%+%-]+` — `%w` ist nur Buchstaben und Ziffern; Unterstrich ist
Interpunktion. Die sehr verbreitete Firmenform `vorname_nachname@firma.tld`
matcht erst ab dem Unterstrich.

**Gemessen:** `("Kontakt: hans_mueller@acme.co.uk"):gsub(…)` → `n=1`, Ergebnis
`"Kontakt: hans_[E-Mail]"`. Der Vorname bleibt stehen, `report.emails` zählt eine
vollständige Schwärzung. Gleiches gilt für `'`, `!`, `#`, `$`, `&`, `*`, `/`,
`=`, `?`, `^`, `` ` ``, `{`, `|`, `}`, `~`.

**Fix:** Klasse um die von RFC 5322 unquoted erlaubten Zeichen erweitern, plus
einen Spec-Fall für `hans_mueller@acme.de` — `TESTS/anonymize_spec.lua` prüft
bisher nur die gepunktete Form.

---

### CD-08 · `lua/casedesk/anonymize.lua:115` · MEDIUM · 2/3 · ✅ **behoben in `b285e0f`**

**Mehrzeilige Stammdaten-Werte matchen auf einem CRLF-Stream nie.**

`stammdaten` liefert den Wert mit `\n`-Trennern, gesucht wird im Originaltext mit
`\r\n`. Firmen- oder Kontaktname bleibt unredigiert.

**Auslöser:** Ein CRLF-Stream mit `Account / Big Customer GmbH / Country /
Germany / Contact / …`, wobei `Country` nicht in `stream_stammdaten_labels`
steht. `stammdaten.Account` wird zu `"Big Customer GmbH\nCountry\nGermany"`,
und der `gsub` darüber liefert `n=0`.

**Fix:** Einmal oben in `M.redact` normalisieren, so wie `lines_of` und
`candidate_names` es bereits tun: `text = text:gsub("\r", "")` **vor**
`local original = text`.

---

## C — Security

### CD-11 · `lua/casedesk/export.lua:158,168` · HIGH · 3/3 (zwei Finder unabhängig) · ✅ **behoben in `78962c5`**

**Kundengeschriebenes Markup wird in einem Headless-Browser mit JavaScript,
Netzwerkzugang und Default-Profil gerendert.**

Kette:

1. `ui/activity.lua:86` schreibt `Research/NN_ActivityStream.md` **wörtlich aus
   der Zwischenablage** — roher, kundengeschriebener ServiceNow-Text.
2. `bundle_markdown` (export.lua:71-108) verkettet `Summary.md`, `Notes.md` und
   jede `.md` aus `Research/` und `Replies/` in eine Temp-Datei.
3. `pandoc` läuft ohne `--from`, also mit Default-Reader — `raw_html` ist dort
   standardmäßig **an** und wird unverändert in die HTML-Ausgabe kopiert.
4. Der Browser läuft mit `--headless --disable-gpu --no-pdf-header-footer
   --print-to-pdf` — **ohne** `--disable-javascript`, **ohne** eigenes
   `--user-data-dir`, **ohne** Netzwerksperre. `--print-to-pdf` lädt und
   *führt die Seite vollständig aus*.

**Auslöser, harmlose Variante:** `<img src="https://tracker.example/p.png">` in
einer Kundenbeschreibung — laut `docs/EXTRACTION.md:409` real vorgekommen
(*„HTML-Reste im Description-Feld"*). Beim PDF-Druck geht ein ausgehender GET
raus und verrät einem Dritten, dass und von welcher IP aus dieser Fall geöffnet
wurde.

**Auslöser, bösartige Variante:** `<script>` mit `document.body.innerText` — und
das ist zu diesem Zeitpunkt das **gesamte Bündel**: Summary, Notes, alle
Research-Dateien und alle Reply-Entwürfe.

Die Kommentare an der Stelle argumentieren sorgfältig über `cwd` (SEC-02), sagen
aber nichts darüber, dass der Inhalt unvertraut ist.

**Fix:** An beiden Grenzen, nicht nur an einer.

> **Umsetzungsnotiz (gemessen, nicht übernommen).** Der unten vorgeschlagene
> Flag-Satz ist so **nicht** haltbar: `--blink-settings=scriptEnabled=false`
> lässt `--print-to-pdf` gar keine Datei mehr erzeugen — headless steuert den
> Druck selbst per Script. Einzeln gegen die anderen drei isoliert, die alle
> sauber drucken. Umgesetzt wurden daher zwei Schichten statt drei: Reader ohne
> `raw_html`/`raw_attribute` plus `--host-resolver-rules` und Wegwerf-Profil.
> `pandoc --sandbox` entfiel ebenfalls — hier ist kein pandoc installiert, und
> ein nicht prüfbares Flag, das im Zweifel jeden Export bricht, ist den Tausch
> nicht wert.

```lua
-- pandoc: rohes HTML gar nicht erst durchlassen
{ "pandoc", "--sandbox", "-f", "markdown-raw_html-raw_attribute-raw_tex",
  "-t", "html5", tmp_md, "-s", "-o", tmp_html }

-- Browser: Skripte aus, Wegwerf-Profil, kein Netz
"--blink-settings=scriptEnabled=false",
"--disable-extensions", "--no-first-run",
"--user-data-dir=" .. vim.fn.tempname(),
"--host-resolver-rules=MAP * ~NOTFOUND",
```

---

## D — Konfiguration

### CD-12 · `lua/casedesk/config/init.lua:114` · CRITICAL · 3/3 · **[selbst verifiziert]** · ✅ **behoben in `ec0bad6`**

**`default_area ≠ "SAP"` kollabiert beide Areas auf den SAP-Baum.**

```lua
local default = M.area(M.default_area)
default.dir = M.cases_root          -- <- unbedingt
default.states = M.states           -- <- unbedingt
default.default_state = M.default_state
if default.snow_prefix ~= nil or M.default_area == "SAP" then   -- <- geschützt
  default.snow_prefix = M.snow_prefix
end
```

Zeile 117 schützt `snow_prefix` genau gegen diesen Fall; die drei Zeilen darüber
nicht. `cases_root` ist unabhängig von `default_area` immer
`repo_root/Cases/SAP_Support/Cases`.

**Auslöser:** `require("casedesk").setup({ default_area = "CS" })` — eine
dokumentierte Option (`docs/configuration.md:98`). Beide Areas bekommen
denselben `dir`; `registry.list()` scannt den SAP-Baum doppelt und liefert jeden
SAP-Fall zweimal, der gesamte `Cases/CS`-Baum verschwindet. `ambiguous()` hält
danach **jede** Nummer für mehrdeutig, also schlägt jedes `:Case <nr>` mit
„exists in several areas" fehl.

**Fix:** Genauso schützen wie Zeile 117:

```lua
if M.default_area == "SAP" then
  default.dir = M.cases_root
  default.states = M.states
  default.default_state = M.default_state
end
```

Im Nicht-SAP-Fall ohne explizite `areas` stattdessen andersherum zuweisen —
`M.cases_root/states/default_state` aus dem Eintrag der Default-Area, wie es der
`explicit.areas`-Zweig bereits tut.

---

### CD-13 · `lua/casedesk/config/init.lua:152` · HIGH · 3/3 · ✅ **behoben in `ec0bad6`**

**`sla_business_hours` zu überschreiben wirkt nicht.**

`DEFAULTS.lua` aliast **dieselbe Tabelle per Referenz** an mehrere Stellen:
`M.sla["2"].fix_window` (Zeile 384), `M.sla["3"].window` (388),
`M.sla["4"].window` (396). `vim.tbl_deep_extend("force", M[k], v)` mutiert `M[k]`
nicht, sondern baut eine **neue** Tabelle und bindet `M.sla_business_hours` daran
— die Aliase zeigen weiter auf die alte.

`setup()` hat für genau diese Driftklasse bereits Nachbesserungs-Durchläufe
(`rebuild_derived`, `reconcile_areas`); keiner fasst `sla` an.

**Auslöser:** Vertrag wechselt auf 09:00–17:00, der Benutzer setzt es. `:Case sla`
rechnet weiter mit 08:00–18:00 — ein 08:10 eingegangenes Ticket bekommt sein
Budget ab 08:10 statt ab 09:00, die angezeigte Deadline ist 50 Minuten zu früh,
und nichts sagt, welches Fenster verwendet wurde.

**Fix:** Entweder ein `reconcile_sla(explicit)` neben `rebuild_derived`, das die
Aliase nach dem Merge neu setzt — oder, robuster und reihenfolgeunabhängig, die
Aliasierung explizit machen: das Sentinel `"business"` in der Level-Tabelle
speichern und in `sla/init.lua` beim Lesen auflösen.

---

## E — SLA-Rechnung

Der Zeit-Finder hat die Arithmetik selbst nachgerechnet und dabei DST,
Hinnants Kalenderalgorithmus und sämtliche Intervallgrenzen ausdrücklich
**freigesprochen** (Details unter [Geprüft und freigesprochen](#geprüft-und-freigesprochen)).
Was übrig bleibt, ist konsistenter: **Wall-Clock-Sekunden werden mit
Geschäftszeit-Sekunden verrechnet.**

### CD-14 · `lua/casedesk/sla/init.lua:250` · HIGH · 3/3 · ✅ **behoben in `a1aba5c`**

**Wall-Clock-Pausenzeit wird auf eine Geschäftszeit-Deadline addiert.**

`total_awaiting_seconds` (init.lua:103-112) summiert rohe Epoch-Differenzen
(`resumed_at - s.at`). Zeile 250 addiert diese Zahl auf eine Epoche, die
`clock.deadline` durch Ablaufen eines Geschäftszeitfensters erzeugt hat; Zeile
249 addiert sie auf ein in Geschäftssekunden ausgedrücktes Budget.

**Auslöser:** P2-Fall, „Awaiting User Info" Fr 17:00 → „Active" Mo 09:00. Real
verlorene Geschäftszeit: 1 h (Fr 17–18) + 1 h (Mo 08–09) = 7.200 s. Gezählt
werden 230.400 s Wall-Clock — das Wochenende zählt als 48 verlorene
Arbeitsstunden. Die Deadline rutscht um mehrere Tage zu weit nach hinten.

**Fix:** Pausenintervalle mit `clock.elapsed(s.at, resumed_at, window)` messen
statt als Epoch-Differenz, damit beide Summanden dieselbe Einheit haben.

---

### CD-15 · `lua/casedesk/sla/init.lua:299` · MEDIUM · 2/2 · ✅ **behoben in `a1aba5c`**

**Die Warnschwelle teilt Wall-Clock-Rest durch Geschäftszeit-Budget.**

`remaining = dl - now` ist Wall-Clock, `budget` steht in der Einheit des
Fensters. Weil der Wall-Clock-Rest immer ≥ dem Geschäftszeit-Rest ist, geht der
Fehler **immer in die stille Richtung**: die Warnung unterbleibt genau dann, wenn
die Deadline hinter einer Nacht oder einem Wochenende liegt.

**Auslöser:** P2, Deadline Mo 10:00, Budget 108.000 s. Am Fr 17:00 ist die echte
Restzeit 1 h + 2 h = 10.800 s = **10 %** — deutlich unter `sla_warn_at = 0.25`.
Gerechnet wird `234000 / 108000 = 2,17` → kein Statusline-Badge, keine
Benachrichtigung.

**Fix:** `remaining` für den Vergleich in Fenstereinheiten umrechnen
(`clock.elapsed(now, dl, window)`).

---

### CD-16 · `lua/casedesk/sla/init.lua:284` · HIGH · 2/3 · ✅ **behoben in `a1aba5c`**

**Eine erfüllte Erstreaktion gilt danach ewig als überfällig.**

`done` wird in Zeile 200 korrekt gesetzt und in Zeile 137 dokumentiert. Weder
`most_urgent` (284) noch `under_threshold` (299) liest es — beide arbeiten rein
über `remaining = dl - now`.

**Auslöser:** P1, Deadline 10:00, Antwort um 09:30 raus → SLA mit 30 Minuten
Reserve erfüllt. Eine Woche später wählt `most_urgent` immer noch diese Uhr
(`remaining = -604800`, der kleinste Wert) und `under_threshold` liefert `true`.

**Fix:** In beiden Funktionen erfüllte Uhren überspringen.

---

### CD-18 · `lua/casedesk/ui/sla.lua:64` · MEDIUM · 2/3 · ✅ **behoben in `a1aba5c`**

**`:Case sla` zeigt OVERDUE für eine erfüllte Erstreaktion.**

Der Ternär prüft `c.remaining < 0` **vor** `c.done`, also ist `done` unerreichbar,
sobald die Deadline vorbei ist. `extract/facts.lua:91` rendert dasselbe Feld mit
umgekehrter Reihenfolge — `:Case sla` und der `{facts}`-Block aus `:Case ki`
widersprechen sich über denselben Fall. `docs/SLA.md` §6B zeigt `Erstreaktion
erfüllt` als gewollte Darstellung.

**Fix:** An `facts.lua:91` angleichen:

```lua
local state = c.done and "erfüllt" or (c.remaining < 0 and "OVERDUE" or "fällig")
```

---

### CD-20 · `lua/casedesk/query.lua:272` · MEDIUM · 3/3 · ✅ **behoben in `a1aba5c`**

**`sla_report` wertet eine Antwort, die *vor* dem Anker liegt, als SLA-erfüllt.**

`met` prüft nur, ob `last_reply_sent` vor der Deadline liegt, nie ob sie nach dem
Anker der Uhr kam. `sla.status` rechnet genau diese Prüfung für dieselbe Uhr
(`done = last_reply_sent ~= nil and last_reply_sent >= anchor`), und `c.since`
steht in jeder Zeile des Reports zur Verfügung.

**Auslöser:** Zuweisung 10.08., Antwort 11.08., Neuzuweisung 20.08. ohne weitere
Antwort. Die Zeile „ab Zuweisung" meldet die zweite Erstreaktion als erfüllt.

**Fix:** `met` um `last_reply_sent >= since` ergänzen.

---

## F — Korrektheit

### CD-17 · `lua/casedesk/ui/cases.lua:564` · HIGH · 3/3 · ✅ **behoben in `6124427`**

**`:Cases linkcheck AREA/nr` matcht nie einen Fall und meldet Entwarnung.**

`M.linkcheck` ist die einzige `[case]`-Route des Moduls, die nicht über
`resolve.pick`/`resolve.sync` geht. Sie reicht das Rohargument an
`render.to_short` weiter, das nur eine volle `SAP0000<year>`-Id abstreift und die
qualifizierte `AREA/nummer`-Form nicht kennt. `linkcheck.targets` vergleicht das
Ergebnis dann mit `e.short`.

**Auslöser — und das ist das Perfide:** Existiert die Nummer in zwei Areas, lehnt
der Argument-Validator `:Cases linkcheck 940561` ab und **fordert den Benutzer
auf**, `SAP/940561` zu tippen. Genau diese Form matcht dann nichts, und der
Report meldet „keine Probleme".

**Fix:** `registry.split` verwenden (die eine Funktion, die die qualifizierte Form
versteht) bzw. über `resolve.sync` auflösen wie alle anderen Routen.

---

### CD-19 · `lua/casedesk/registry.lua:136` · MEDIUM · 2/3 · ✅ **behoben in `6124427`**

**`find()` verwechselt zwei Treffer *innerhalb* einer Area mit
Area-Mehrdeutigkeit.**

**Auslöser:** `Open/977392` und `Closed/977392` liegen beide im SAP-Baum.
`find("977392")` → `nil, {"SAP","SAP"}`. Der Fehlertext lautet dann *„case 977392
exists in several areas — use SAP/977392 or SAP/977392"*, und der vorgeschlagene
Ausweg scheitert genauso. Der Fall wird über jedes `:Case`-Verb unerreichbar.

**Fix:** `names` vor der Rückgabe deduplizieren. Bleibt genau ein Eintrag übrig,
ist die Nummer *innerhalb* einer Area doppelt — das braucht ein eigenes Signal,
damit die Meldung „exists in both Open/ and Closed/ of area SAP" lauten kann.

---

### CD-21 · `lua/casedesk/detect.lua:95` · HIGH · 2/2 · ✅ **behoben in `bd51ea3`**

**`M.name`s Begrüßungs-Pattern läuft über Leerzeilen hinweg und behält das CR.**

```lua
content:match("[Dd]ear%s+([%w%s]-)[,:]")
```

`%s` steht **innerhalb** der Capture-Klasse und matcht `\n`/`\r`. Das
nicht-gierige `[%w%s]-` ist damit nicht auf die Begrüßungszeile beschränkt,
sondern dehnt sich bis zum nächsten `,` oder `:` irgendwo im Text.

**Gemessen:** Bei `"Dear customer\r\n\r\nThanks for reaching out, we could
reproduce…"` liefert `detect.name(case_dir)` → `"customer\r\n\r\nThanks for
reaching out"` statt `"customer"`. `M.guess` reicht das direkt in die
Fall-Metadaten weiter.

**Fix:** Capture auf die Zeile begrenzen (`[^\r\n,:]-`) und das CR abstreifen,
wie es das Schwestermodul `M.title` bereits tut.

---

### CD-22 · `lua/casedesk/bindings/usrcmds.lua:681` · MEDIUM · 3/3 · ✅ **behoben in `6124427`**

**`enum` schlägt `type = "STRING"` und lehnt das freie Topic ab, das die Route als
unterstützt dokumentiert.**

`argtypes.validate` prüft `spec.enum` zuerst; `type = "STRING"` wird nie
konsultiert. Der Kommentar zwei Zeilen über der Route sagt das Gegenteil
(*„`topic` completes against `config.command_topics` but is NOT restricted to it"*).

**Auslöser:** `:Tricentis commands Emulator_AVD` — ein Pfad-Substring, den
`commands.lua`s eigener Doc-Kommentar als Beispiel nennt — bricht mit
„expected one of all|enginelab|mobile|…" ab. Betrifft `commands` und `cheatsheet`.

**Fix:** `enum` aus der Spec entfernen und die Vorschlagsliste über `complete`
anbieten, was der dokumentierten Absicht entspricht.

---

### CD-23 · `lua/casedesk/commands.lua:179` · MEDIUM · 3/3 · ✅ **behoben in `bd51ea3`**

**Überschriften werden auch innerhalb von Nicht-Shell-Fences geparst.**

Die Fence-Statemachine betritt `in_fence` nur für Sprachen aus
`SHELL_LANGUAGES` (Zeile 186). Ein ```` ```text ````-, ```` ```json ````- oder
```` ```output ````-Block wird gar nicht getrackt, sein Körper läuft durch den
Heading-Zweig.

**Auslöser:** Ein Notizdokument mit `## Geräte auflisten`, dann ein Bash-Block,
dann ein `text`-Block, dessen erste Zeile `# Ausgabe` lautet (eine völlig normale
Art, Beispielausgabe zu betiteln), dann wieder ein Bash-Block. Der zweite Treffer
bekommt `context = "Ausgabe"` statt `"Geräte auflisten"` — und das bleibt für
jeden weiteren Shell-Block der Datei so.

**Fix:** Jede Fence tracken, nicht nur die Shell-Fences: `in_fence` auch für
unbekannte Sprachen setzen und dort nur den Heading-Match überspringen.

---

### CD-24 · `lua/casedesk/terminology.lua:68` · MEDIUM · 2/3 · ✅ **behoben in `bd51ea3`**

**`parse_file` hat überhaupt keinen Fence-Zustand.**

`^##%s+` / `^###%s+` matcht auf jeder Zeile. Ein Codeblock mit einer `## `-Zeile
öffnet einen erfundenen Begriff **und** beendet den Körper des echten, weil
`flush()` an dieser Zeile läuft. Das Schwestermodul `commands.lua:155` trackt
Fences; dieses nicht, obwohl beide dasselbe Korpus handgeschriebener Notizen
durchlaufen.

**Gemessen:** Eine `Terminologie.md` mit zwei echten Begriffen und einem
Markdown-Beispielblock liefert **drei** Einträge.

**Fix:** `in_fence`-Flag analog `commands.lua:155-190`.

---

### CD-25 · `lua/casedesk/ui/ki.lua:250` · MEDIUM · 3/3 · ✅ **behoben in `bd51ea3`**

**`ipairs` über einen Tabellen-Konstruktor mit möglicherweise `nil` an Position 1.**

```lua
for _, text in ipairs({ sections.solution, sections.reply }) do
```

Ist `sections.solution` `nil`, bricht `ipairs` sofort ab — die Widerspruchsprüfung
läuft nie, `contradictions` bleibt leer, und die Antwort gilt als sauber.

**Fix:**

```lua
for _, key in ipairs({ "solution", "reply" }) do
  local text = sections[key]
  if text then … end
end
```

---

### CD-27 · `lua/casedesk/ui/reply_check.lua:109` · MEDIUM · 2/3 · ✅ **behoben in `f14249a`**

**Buffer-Handle wird vor einem asynchronen Link-Check gefangen, ohne
Gültigkeitsprüfung danach.**

**Auslöser:** `:Case reply check` auf einem Entwurf mit sechs Links auf einen
abgeschalteten Host — jeder HEAD läuft in den 5-Sekunden-Timeout. Währenddessen
`:bd`. Wenn der Report erscheint und der Benutzer `c` drückt, wirft
`nvim_buf_get_lines` „Invalid buffer id" aus dem Keymap-Callback.

**Fix:** Am Vertragsende absichern: `if not vim.api.nvim_buf_is_valid(bufnr) then
return nil, "buffer is gone" end` oben in `replygate.clear_emojis`
(`replygate.lua:142`) — behält die dokumentierte `nil, err`-Form und deckt alle
Aufrufer ab.

---

### CD-26 · `lua/casedesk/render.lua:17` · HIGH · 3/3 · **[selbst verifiziert]** · ✅ **behoben in `6124427`**

**`to_snow` liest immer das globale `snow_prefix` und nimmt kein Area-Argument.**

Die in `DEFAULTS.lua:311` und `docs/configuration.md:254` dokumentierte
Degradation — *„every other area leaves `snow_prefix` nil, and `:Case snow`
degrades to copying the plain case number"* — **existiert nicht**. Nachgeprüft:
Der einzige Leser des Feldes ist `render.lua`; `config/init.lua:117` ist der
einzige Schreiber.

**Auslöser:** CS-Fall 0501 → `render.to_snow("0501","2026")` liefert
`"SAP000005012026"`, obwohl `config.area("CS").snow_prefix == nil` ist. Das landet
über `:Case snow` in der Zwischenablage, über `:Case insert` in einer
**Kundenantwort** und über `:Case new` in der gescaffoldeten `Summary.md`.

**Fix:** Beiden Funktionen einen `area`-Parameter geben und
`config.area(area).snow_prefix` lesen, bei `nil` das nackte `short` zurückgeben.
Aufrufstellen haben den Registry-Eintrag jeweils schon zur Hand: `ui/snow.lua:22`,
`ui/insert.lua:61,63`, `ui/case_new.lua:135`, `ui/infocard.lua:28`,
`ui/template.lua:42`.

---

## G — Performance

### CD-28 · `lua/casedesk/detect.lua:25` · HIGH · 2/3 · ✅ **behoben in `acbad1b`**

**`table.sort` mit zwei `uv.fs_stat` im Komparator.**

`case_files` sortiert nach mtime, aber die Stat-Aufrufe stehen **in** der
Vergleichsfunktion. Jeder der rund `n·log₂n` Vergleiche setzt zwei frische
Syscalls ab; dieselbe Datei wird immer wieder gestattet. `M.last_touched` braucht
nur das Maximum, bezahlt aber die volle Sortierung und stattet den Gewinner
danach noch einmal.

**Rechnung:** 27 Fälle à ~40 Dateien, `:Cases recent`/`:Cases stale` rufen
`detect.last_touched` einmal pro Fall → **~11.500 `fs_stat`-Syscalls, wo 1.080
genügen**. `ui/cases.lua:458` macht dasselbe noch einmal für `:Cases history`.
Auf Windows mit Virenscanner im Pfad ist jeder dieser Syscalls teuer.

**Fix:** Decorate-Sort-Undecorate — einmal `n` Stats in eine Tabelle, dann nach
den zwischengespeicherten Zahlen sortieren. `last_touched` auf einen linearen
Maximum-Durchlauf umstellen.

---

### CD-29 · `lua/casedesk/sla/notify.lua:70` · HIGH · 2/3 · ✅ **behoben in `acbad1b`**

**Der Prioritätsfilter wird gebaut, aber erst nach der teuren Arbeit angewendet.**

`M.check` baut das `active`-Set aus `config.sla_active_priorities` (Zeilen 63-66)
und benutzt es erst in Zeile 71 — **nachdem** `sla.status(e)` bereits alles
gelesen hat. `sla.status` liest `.case.json`, macht ein `fs_scandir` auf
`Research/`, liest den neuesten Activity Stream **synchron und vollständig** und
jagt ihn durch den Parser.

**Rechnung:** 20 offene Fälle, davon 15 P3/P4, je ~100 KB Stream. Jedes
`FocusGained` blockiert den Main Loop auf 20 `fs_scandir`, ~2 MB Dateilesen, 20
`vim.split`s in zigtausende Zeilen und einige hunderttausend Pattern-Matches —
für 15 Fälle, die **nie** eine Benachrichtigung erzeugen können. Der Benutzer
wechselt beim SNOW-Arbeiten ein Dutzend Mal pro Stunde.

**Fix:** Die `active`-Prüfung vor den `sla.status`-Aufruf ziehen. Die Priorität
steht in `.case.json` bzw. ist über `level_of` billig zu bestimmen.

---

## H — Zweite Runde: der gesamte Diff seit Runde 1

**Stand:** 2026-09-19 · **Prüfstand:** `df5eae9..HEAD` (18 Commits, 66 Dateien,
~2.600 Zeilen), inklusive sechs Commits einer parallel laufenden Sitzung
(`17654e2`, `f14249a`, `d9552fd`, `b9b394b`, `44f77d7`, `6198ba2`), die zu
diesem Zeitpunkt noch nicht gegengelesen waren.

**Methode:** Sechs parallele Finder über getrennte Flächen
(`config-sla`, `plan-apply-templates`, `resolution-listing`, `parsers-async`,
`security-sensitive`, `performance`), max. 2 gleichzeitige Agenten,
anschließend Dedup und dieselbe 3-Linsen-Verifizierung wie in Runde 1
(Erreichbarkeit / Absichtlichkeit / Konsequenz, 2-von-3-Mehrheit).
**11 Rohfunde → 10 bestätigt.** Jeder bestätigte Fund wurde behoben, per
Regressionstest abgesichert (revert → Test schlägt fehl → restore → Test grün)
und einzeln committet/gepusht; die Beleg-Details stehen in den Commit-Messages,
hier nur die Kurzfassung.

Zusätzlich außerhalb dieser Runde behoben: der in Runde 1 unter „Verworfen,
aber festgehalten" notierte `migrate.lua:124`-Fund (`meta.read(...) or {}` →
stiller Stub über eine korrupte Sidecar) — `meta.lua` hat jetzt
`M.backup_corrupt`, das die Originaldatei vor dem Überschreiben nach
`<name>.corrupt` verschiebt; `migrate.lua` ruft es bei jedem Lesefehler auf.
Behoben in `a002923`, bevor `migrate` je verdrahtet wurde — genau die
Bedingung, unter der Runde 1 den Fund offen ließ.

### CD-30 · `lua/casedesk/sla/init.lua` (`fr_clock`) · HIGH · ✅ **behoben in `e56afb5`**

**Eine verspätete Antwort erfüllt ihre Uhr trotzdem.**

`fr_clock.done` prüfte nur `last_reply_sent >= anchor`, nie gegen die
Deadline, die zwei Zeilen darüber berechnet wird. Harmlos, solange `done`
rein kosmetisch war — CD-16 (Runde 1) machte es aber maßgeblich:
`live(c) = c ~= nil and not c.done` steuert seither `M.most_urgent` und
`M.under_threshold`, und `ui/sla.lua`/`extract/facts.lua` prüfen `c.done` vor
`c.remaining < 0`. Eine Erstreaktion, die die Deadline verstreichen ließ und
dann Tage später doch noch beantwortet wurde, fiel aus der Dringlichkeits-
Sortierung, aus der Warnschwelle, aus der Breach-Benachrichtigung — und zeigte
„erfüllt" für einen tatsächlich gerissenen SLA. `query.sla_report` verlangte
für dieselbe Frage bereits `>= since` **und** `<= deadline`.

**Fix:** `done = last_reply_sent ~= nil and last_reply_sent >= anchor and
last_reply_sent <= dl`.

---

### CD-31 · `lua/casedesk/config/init.lua` (`reconcile_sla`) · HIGH · ✅ **behoben in `e56afb5`**

**`sla`-Override schützt nur die explizit genannten Level, das Gate prüfte
aber die ganze Option.**

`reconcile_sla`s Gate war `if explicit.sla then return end` — ein Flag für
die GESAMTE `sla`-Option, obwohl die Aliasierung, gegen die CD-13 (Runde 1)
bereits einen Fix bekam, pro LEVEL passiert.
`setup({ sla_business_hours = {...}, sla = { ["1"] = {...} } })` benannte
Level „1" und sonst nichts, aber das Gate übersprang das Neuverdrahten der
Level „2"/„3"/„4" ebenfalls mit — reproduzierte CD-13 lautlos für jeden nicht
genannten Level. Verifiziert: `config.sla_business_hours.from` änderte sich,
`config.sla["3"].window.from` nicht.

**Fix:** `reconcile_sla(opts.sla)` nimmt die rohe Options-Tabelle und
überspringt nur die tatsächlich genannten Level-Ziffern.

---

### CD-32 · `lua/casedesk/plan.lua:58` · MEDIUM · ✅ **behoben in `11ec598`**

**ERR-11-Fehlermeldung behauptet „H1-only" auch für Knoten, die gar keine H1
schreiben.**

`plan.build`s Doc-Kommentar behauptete, die H1 werde bei einem defekten
Template-Tag „unconditionally" mitgeschrieben — das gilt nicht für einen
`headline = false`-Knoten, der dann komplett leer bleibt. Das ausgelieferte
`Summary.md` (die ServiceNow-facing Datei, wörtlich in die Kundenantwort
übernommen) ist genau so ein Knoten: ein kaputter `$SUMMARY`-Tag scaffoldete
eine echte 0-Byte-Datei, während `case_new.lua`/`sync.lua` pauschal „will be
H1-only" meldeten — lesbar als „hat wenigstens Fallnummer und Titel".

**Fix:** Jeder `template_errors`-Eintrag nennt jetzt seinen eigenen
Schweregrad (`"H1-only"` bzw. `"COMPLETELY EMPTY"` für `headline = false`).

---

### CD-33 · `lua/casedesk/ui/lifecycle.lua:494` (`close_many`) · MEDIUM · ✅ **behoben in `66942fe`**

**`marks.clear()` löscht auch Marks, die `close_many` nie verarbeitet hat.**

`close_many` (die gemeinsame Bulk-Logik von `:Cases close`) rief nach
Verschieben/Löschen unconditional `marks.clear()`. Zwei Fälle verloren ihre
Markierung, ohne angefasst worden zu sein: ein Mark, das `cases_close()`
bereits als „nicht auflösbar, unberührt gelassen" meldete (CD-09, Runde 1),
erreichte `close_many`s `entries` nie — wurde aber trotzdem gewischt; ein
Eintrag, dessen `do_move`/`do_delete` selbst fehlschlug (`n < #movable`),
ebenso.

**Fix:** Neues `marks.unmark(entry)` (idempotente Einzel-Entfernung, anders
als `toggle`), aufgerufen nur für tatsächlich erfolgreich verarbeitete
Einträge. **Keine Testabdeckung für `close_many` selbst** — das Modul hängt
komplett hinter `kit.confirm`/`kit.input`s interaktivem Dialog-Flow ohne
Test-Seam, wie jede andere Logik in dieser Datei; abgesichert ist nur die
wiederverwendbare Einheit `marks.unmark` selbst.

---

### CD-34 · `lua/casedesk/bindings/usrcmds.lua` (`register_case_type`) · MEDIUM · ✅ **behoben in `c89d0e2`**

**Ein Fall, der innerhalb EINER Area dupliziert ist, wird aufgefordert, sich
selbst erneut einzugeben.**

`registry.find`s Dedup (CD-19-Fix, Runde 1) liefert für eine Nummer, die INNERHALB
einer Area doppelt liegt (z. B. in `Open/` und `Closed/` zugleich), eine
`areas`-Liste der Länge 1 — unterscheidbar von echter Area-Mehrdeutigkeit
laut dem eigenen Doc-Kommentar. `register_case_type`s `validate`, der einzige
Produktionsleser dieses zweiten Rückgabewerts, prüfte die Länge nie und
rendert für beide Formen „exists in several areas — use AREA/NNNN". Für den
Intra-Area-Fall verweist das auf exakt die Eingabe, die gerade gescheitert
ist — der Fall bleibt dauerhaft unerreichbar, ohne je einen funktionierenden
Ausweg zu zeigen.

**Fix:** `#areas == 1` bekommt eine eigene Meldung, die `:Cases doctor` als
tatsächliche Abhilfe nennt.

---

### CD-35 · `lua/casedesk/ui/cases.lua` + `lua/casedesk/ui/similar.lua` · MEDIUM · ✅ **behoben in `c89d0e2`**

**Vier `on_select`-Handler verwerfen die Area der ausgewählten Zeile.**

`show_results`, `:Cases recent`, `:Cases stale`, `:Cases sla` (alle
`ui/cases.lua`) sowie `:Case similar` (`ui/similar.lua`) reichten nur
`entry.short` an `ui_infocard.info`/`ui_sla.sla` weiter. Beide lösen über
`registry.find(short, nil)` auf, das für eine mehrdeutige Nummer
absichtlich `nil` liefert — eine konkret ausgewählte Zeile öffnete dann „no
case to show", obwohl der Fall gerade angeklickt wurde. `ui/cases.lua` hat
mit `case_label` bereits die richtige Regel (an anderer Stelle in derselben
Datei genutzt); `ui/similar.lua` bekam dieselbe Ein-Zeilen-Regel neu.

**Fix:** Alle fünf Stellen reichen jetzt den area-qualifizierten Label durch.

---

### CD-36 · `lua/casedesk/ui/reply_check.lua:113,134` · MEDIUM · ✅ **behoben in `694ccdf`**

**Die Buffer-Gültigkeitsprüfung aus CD-27 (Runde 1) erkennt `:bdelete`/`:bunload`
nicht.**

Beide Keymaps (`c`, `s`) prüften nur `nvim_buf_is_valid(bufnr)` erneut vor
Gebrauch. Nach `:bdelete`/`:bunload` bleibt die Buffer-Nummer gültig (sie
wird nicht gewiped), nur „unloaded" — und `nvim_buf_get_lines` auf einem
unloaded Buffer liefert erfolgreich eine leere Liste statt eines Fehlers.
`replygate.clear_emojis` sah dadurch 0 Zeilen, „entfernte" 0 Emojis und
meldete Erfolg, während die eigentlichen Emojis nie angefasst wurden.
Empirisch verifiziert in einer Headless-Instanz: nach `bunload!` ist
`is_valid=true`, `is_loaded=false`, `get_lines` liefert `{}` ohne Fehler.

**Fix:** Beide Guards prüfen zusätzlich `nvim_buf_is_loaded(bufnr)`. **Keine
automatisierte Testabdeckung** — wie `close_many` (CD-33) liegt die Logik
komplett in Keymap-Closures ohne Test-Seam; abgesichert durch die zitierte
Headless-Verifikation der zugrunde liegenden Neovim-API.

---

### CD-37 · `lua/casedesk/sla/notify.lua:179` (`M.stop`) · MEDIUM · ✅ **behoben in `c4735f7`**

**PERF-82s `M.stop()` wird von keinem Produktionscode je aufgerufen.**

`bindings/usrcmds.lua`s `M.setup()` rief `sla.notify.setup()` allein —
genau das Muster, gegen das das `start()`/`stop()`-Paar existiert. Da
`usrcmds.lua`s eigenes `M.setup()` innerhalb einer Session mehrfach laufen
kann (z. B. eine "reload config"-Tastenbelegung), ohne dass
`casedesk.sla.notify` je aus `package.loaded` entfernt wird — exakt das
Muster, das `TESTS/bindings_usrcmds_spec.lua`s `fresh()`-Helfer bei jedem
einzelnen Testfall bereits durchläuft —, blieb ein zuvor gestarteter Timer
theoretisch neben einem frischen weiterlaufen.

**Einschränkung, selbst nachgeprüft:** Dieser Fix schließt NICHT das im
Doc-Kommentar von `M.stop()` beschriebene Vollbild (ein echtes `:Lazy reload`,
das `casedesk.sla.notify` selbst aus `package.loaded` entfernt) — eine dann
frisch geladene Modulinstanz kann den alten, verwaisten Timer grundsätzlich
nicht mehr erreichen, unabhängig davon, ob `.stop()` aufgerufen wird. Er
schließt die tatsächlich erreichbare Lücke: wiederholte `usrcmds.lua`-Setup-
Aufrufe innerhalb derselben Session.

**Fix:** `sla.notify.stop()` unmittelbar vor `sla.notify.setup()`, no-op-sicher
beim ersten Aufruf.

---

### CD-38 · `lua/casedesk/detect.lua:93` (`M.name`) · LOW/PERF · ✅ **behoben in `94b14c4`**

**`M.name` verwirft `case_files`s mtimes und stattet jede Replies/-Datei ein
zweites Mal.**

`case_files` (CD-28-Fix, Runde 1) liest jedes Datei-mtime bereits genau
einmal und gibt es als zweiten Rückgabewert zurück. `M.name` iterierte per
`ipairs(case_files(case_dir))` — verwarf diesen Wert — und rief für jede
`/Replies/`-Datei erneut `uv.fs_stat` auf, mit der alten
`mtime = st and ... or 0`-Fallback-Konvention, die `case_files` selbst
bereits durch `nil`-bei-Fehlschlag ersetzt hatte.

**Bemerkenswert, selbst nachgeprüft:** Trotz des Namens ist dies **keine
beobachtbare Verhaltensänderung** — `case_files`s eigener Sortier-Komparator
rundet ein fehlendes mtime für Vergleichszwecke ebenfalls auf 0, identisch
zum alten Fallback. Der ursprüngliche Verdacht auf einen 0-vs-nil-
Korrektheitsbug in `M.name`s Rückgabewert hält einer genauen Prüfung nicht
stand; es bleibt eine reine Redundanz-/Perf-Bereinigung. Belegt per
Stat-Zähl-Test (spy auf `uv.fs_stat`) statt per Output-Vergleich: alter Code
stattet 2 Replies-Dateien 4-mal, neuer Code 2-mal.

**Fix:** Ersten `/Replies/`-Treffer in `case_files`s bereits sortierter Liste
nehmen, statt eine eigene Rangfolge neu zu berechnen.

---

**Verifikation dieser Runde:** Jeder Fund einzeln committet und gepusht, mit
Regressionsbeweis (revert → Test schlägt fehl → restore) wo ein Test-Seam
existierte (CD-30–32, CD-34, CD-35, CD-37, CD-38), sonst per Code-Lesung plus
gezielter Headless-Verifikation (CD-33, CD-36). Suite danach **565 grün**,
`luacheck`/`stylua` sauber über 125 Dateien.

---

## Verworfene Funde

Dokumentiert, damit niemand sie erneut jagt. Alle haben die 2-von-3-Abstimmung
**nicht** überstanden.

| Fund | Stimmen | Warum verworfen |
|---|---|---|
| `attachments.lua:62` — PowerShell ohne `cwd`, entgegen SEC-02 | 0/3 | Verifizierer lasen `lib.nvim.cross.fs.lock` nach: Aufruf über `-File`/`-Path` als argv, keine Interpolation |
| `attachments.lua:95` — Ingest benennt auf unpüfbares Ziel um | 0/3, 0/2 | Ziel wird vorher geprüft |
| `redaction.lua:50` — Gate umgehbar durch Dateinamen auf `.redacted.<ext>` | 1/3 | Zu spekulativ; setzt kundenseitig gewählten Dateinamen voraus |
| `statusline.lua:159` — validiert/cached nach `buf`, löst aber aus Buffer 0 auf | 0/3 | Verhalten korrekt |
| `statusline.lua:87` — liest ganzen Stream für Fälle ohne Badge | 1/3 | Cache greift |
| `config/init.lua:158` — zweites `setup()` revertiert Pfade | 0/3 | Dokumentiertes Verhalten |
| `extract/stream.lua:127` — `attachments_snow` verschluckt Rest der Datei | 0/3 | Terminator korrekt behandelt |
| `extract/stream.lua:100` — KBA aus Fallnummer erfunden | 0/2 | Pattern greift nicht wie behauptet |
| `extract/stream.lua:156` — Byte-Klassen für En/Em-Dash | 0/2 | Kein Schaden im echten Format |
| `extract/stream.lua:185` — `error_codes` schneidet bei Kleinbuchstaben ab | 0/3 | Gewolltes Verhalten |
| `extract/facts.lua:127` — `:Case ki` läuft Verzeichnis ~10× ab | 1/3 | Einmalige, interaktive Aktion |
| `terminology.lua:89` — Walker steigt in `.git` ab | 0/3 | `ignore`-Predicate greift in `lib.nvim` |
| `bindings/usrcmds.lua:77` — BLOCK-Argtype läuft Baum bei jedem `<Tab>` ab | 0/3 | Gecacht |
| `resolve.lua:51` — Statusline-Redraw schreibt Usage-Journal | 0/3 | Throttle in `usage.lua` greift |

---

## Geprüft und freigesprochen

Wertvoll, weil es verhindert, dass diese Flächen erneut untersucht werden.

**Zeitrechnung** (vollständig händisch nachgerechnet):

- **DST in `clock.elapsed`/`clock.deadline`.** `midnight + DAY_SECONDS` ist am
  Umstellungstag zwar nicht die nächste lokale Mitternacht, aber beide Richtungen
  wurden durchgerechnet und heben sich auf. Zudem fallen EU- und US-Umstellungen
  auf einen Sonntag, den `days = {2..6}` ausschließt. Würde erst bei einem
  Fenster mit `from = 0` oder mit Wochenendtagen zum echten Bug.
- **`clock.utc`/`days_from_civil`** — Hinnants Algorithmus inklusive Schalttag-
  und Negativjahr-Zweig und der 719468-Verschiebung von Hand verifiziert.
- **Intervallgrenzen** — alle vier Vergleiche sind halboffen und konsistent; der
  dokumentierte Rundlauf `elapsed(from, deadline(from, b, w), w) == b` hält an
  den geprüften Rändern.
- **`isdst`-Gefahr** aus dem `clock.lua`-Kommentar — weder `sla/stream.lua` noch
  `stream_format.lua` reproduziert sie.

**Die Mehrfach-Rückgabewert-Klasse** aus dem Fix vom 2026-09-18
(`vim.list_extend(t, f())`): **beide Läufe unabhängig** über alle 17
`collect_recursive`-Aufrufstellen gesweept. Jede kürzt korrekt per `ipairs(…)`
oder Einzelzuweisung; `extract/doclinks.lua:98` ist die einzige Stelle und bereits
geklammert.

**Weiteres:** `lib.nvim.fs.is_valid_filename` blockiert Pfadseparatoren (kein
Traversal über `:Case add`); `cross.open_default` nutzt reines argv ohne Shell
(keine Metazeichen-Injektion aus Kunden-URLs); Neovims `tempname()` sitzt auf
einem 0700-`mkdtemp` (Temp-Pfade weder vorhersagbar noch wiederverwendet);
`linkcheck`s `^https?://docs%.tricentis%.com/`-Anker schließt Userinfo-Tricks aus;
`blocks.lua`s gsub-mit-Funktion reprozessiert `%` nicht; `similar.lua`s Tokenizer
ist solide.

**Bewusst nicht gemeldet, weil dokumentiert:** `:Case ki` schickt den rohen
Activity Stream mitsamt `{company}`/`{name}` an eine externe KI. `docs/CONCEPT.md`
§8i beschreibt das als Mechanisierung eines Copy-Paste, das der Bearbeiter ohnehin
von Hand macht. Das ist eine dokumentierte Entscheidung — erwähnt, weil es die
größte Privacy-Fläche des Plugins ist und eine bewusste bleiben sollte.

---

## Grenzen dieses Audits

- **Nicht geprüft:** `blueprint.lua`, `templates/`, `health.lua`, `migrate.lua`
  jenseits der Datenverlust-Linse, sowie die `lib.nvim`- und `ui.nvim`-Bäume
  selbst (dort nur Signaturen nachgeschlagen).
- **Keine echten Vendor-Dateien.** Kein Finder hatte eine reale 6500-Zeilen-
  Support-Info oder einen echten Activity Stream; die Parser-Fixtures waren
  synthetisch, nachgebaut aus den Formen der Doc-Kommentare und Specs.
- **Kein Vollständigkeits-Kritiker.** Die geplante dritte Runde entfiel wegen
  einer Staffelung nach einem Sitzungslimit.
- **Testabdeckung nicht bewertet.** Es wurde nicht ermittelt, welche der 29
  Befunde bereits einen Regressionstest hätten.
- Alle Zeilennummern beziehen sich auf `df5eae9`.
