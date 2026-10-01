# `data.nvim` — Konzept

> Arbeitstitel, vom Nutzer selbst vorgeschlagen. Auslöser: als Support-
> Spezialist bekommt man Logs oft als ein einziges, minifiziertes JSON-Objekt
> mit vielen Keys ("in einer Wurst") und will es lesbar machen, umformen und
> gezielt filtern — direkt im Editor, ohne Umweg über einen Browser-Formatter.

## Table of content

- [Problem](#problem)
- [Idee in einem Satz](#idee-in-einem-satz)
- [Ist-Zustand: was schon da ist](#ist-zustand-was-schon-da-ist)
- [Bewertung: sinnvoll? umsetzbar?](#bewertung-sinnvoll-umsetzbar)
- [Eigenes Plugin oder bestehendes?](#eigenes-plugin-oder-bestehendes)
- [Bedienung](#bedienung)
  - [Usercommand](#usercommand)
  - [Scope: Buffer, Selektion, Register](#scope-buffer-selektion-register)
  - [Render-Modi](#render-modi)
- [Filter-UI über `pickers.refine`](#filter-ui-über-pickersrefine)
- [Architektur-Skizze](#architektur-skizze)
  - [Modulbaum](#modulbaum)
  - [Gemeinsames Zwischenformat (IR)](#gemeinsames-zwischenformat-ir)
- [Was in `lib.nvim` fehlt und ergänzt werden müsste](#was-in-libnvim-fehlt-und-ergänzt-werden-müsste)
- [Wiederverwendung: `lib.nvim` und eigene Plugins](#wiederverwendung-libnvim-und-eigene-plugins)
- [Feature-Brainstorm](#feature-brainstorm)
  - [Kern (sollte rein)](#kern-sollte-rein)
  - [Stark, aber Phase 2+](#stark-aber-phase-2)
  - [Spielwiese / später prüfen](#spielwiese--später-prüfen)
- [Phasen](#phasen)
- [Risiken / Komplexitätstreiber](#risiken--komplexitätstreiber)
- [Offene Fragen](#offene-fragen)
- [Literatur und Referenzen](#literatur-und-referenzen)

---

## Problem

Support-Logs (Tickets, API-Responses, Fehlerdumps) kommen fast immer als
minifiziertes JSON auf einer einzigen Zeile, oft mit vielen — teils tief
verschachtelten — Keys. Zum Lesen muss man das aktuell entweder in ein
externes Tool (Browser, `jq`) kopieren oder mühsam von Hand umbrechen. Beides
reißt aus dem Editor raus, und externe Tools sind für sensible Ticket-Daten
ohnehin nicht ideal. Dasselbe Problem existiert, seltener, für YAML- und
XML-Payloads.

Zusätzlich zum reinen Reformatieren fehlt ein Weg, **gezielt zu filtern** —
bei einem Log mit 60 Keys interessieren oft nur 5 (`level`, `message`,
`trace_id`, `user.id`, `error.stack`), der Rest ist Rauschen.

## Idee in einem Satz

Ein Neovim-Plugin, das JSON/YAML/XML-Inhalte (Buffer, Selektion oder
Register) über `:JSON`, `:YAML`, `:XML` in mehrere lesbare Formen bringt
(pretty, compact, ein `key: value` je Zeile, nur Struktur) und den Inhalt
über eine Picker-gestützte Filter-UI auf die relevanten Keys reduziert.

## Ist-Zustand: was schon da ist

Vor dem Konzept kurz geprüft, was `lib.nvim` und `pickers.nvim` bereits
mitbringen — wichtig, weil ein neues Plugin hier überwiegend **Verdrahtung**
sein sollte, kein Neubau:

| Baustein | Modul | Stand |
| --- | --- | --- |
| JSON-String → Lua-Value | `lib.nvim.json.decode` | fertig (`vim.json` + `value, err`-Contract) |
| Lua-Value → JSON-String | `lib.nvim.json.encode` → `lib.lua.json.encode` | fertig, pure Lua, deterministisch |
| JSON Pretty-Print | `lib.lua.json.encode.pretty` | fertig — Indent konfigurierbar (Zahl oder String), `sort_keys` |
| JSON Compact | `lib.lua.json.encode` (ohne `indent`) | fertig |
| Dekodiertes Objekt → `"key: value"`-Zeilen | `lib.lua.json.decode.table_to_string_array` | fertig, aber **eine Ebene flach** — verschachtelte Werte landen als `vim.inspect`-Blob in einer Zeile, kein rekursives Path-Flattening |
| JSON-Datei lesen/schreiben | `lib.nvim.fs.json` | fertig, atomar |
| YAML-Text → Lua-Value | `lib.lua.yaml.simple_parse` | fertig, aber **nur ein Subset** (kein Flow-Style, keine Anchors, keine Block-Scalars) |
| Lua-Value → YAML-Text | — | **fehlt komplett** |
| XML | — | **fehlt komplett**, weder Decode noch Encode |
| Filter-Stack (Include/Exclude, Substring/Regex, Prompt) | `pickers.refine` | fertig, engine-agnostisch — genau der Baustein für die Key-Filter-UI |

Fazit: Für JSON ist der Formatier-Teil zu vielleicht 70 % schon vorhanden,
für YAML nur das Parsen, für XML nichts. Das rekursive Path-Flattening
(`user.address.city: Wien`) für den `lines`-Modus fehlt für alle drei Formate
und ist der eigentliche neue Kern.

## Bewertung: sinnvoll? umsetzbar?

**Sinnvoll: ja.** Trifft einen echten, wiederkehrenden Arbeitsschritt im
Support-Alltag, nicht ein hypothetisches Feature. Der Filter-Teil ist der
Unterschied zu "kopier's halt in einen Online-JSON-Formatter" — den bietet
kein Browser-Tool in der Form (Editor-nativ, ohne Daten zu verlassen).

**Umsetzbar: ja**, mit der Einschränkung, dass YAML-Encoder und XML komplett
neu sind (siehe [Was fehlt](#was-in-libnvim-fehlt-und-ergänzt-werden-müsste)).
JSON allein ist praktisch nur Verdrahtung bestehender `lib.nvim`-Bausteine
plus dem neuen Flatten-Modul — realistisch ein kleines MVP.

## Eigenes Plugin oder bestehendes?

**Eigenes Plugin — `data.nvim`.** Geprüfte Alternativen und warum sie
ausscheiden:

- **`casedesk.nvim`** — passt thematisch (Support-Workflow), ist aber
  Case-*Scaffolding* (Ordner pro Ticket, SLA, Tricentis-Mining), kein
  generisches Daten-Tooling. Ein Format-Kommando dort würde fachfremd wirken
  und wäre nutzlos außerhalb eines Case-Kontexts.
- **`pickers.nvim`** — liefert mit `refine` einen wichtigen Baustein, ist
  aber selbst ein generisches Picker-Framework, kein Ort für
  Format-Kommandos.
- **`lib.nvim`** — reine Library ohne Commands/Bindings/UI. Die neuen
  JSON/YAML/XML-Bausteine (Flatten, YAML-Encoder, XML) gehören trotzdem
  **dorthin**, nicht in `data.nvim` selbst — genau wie `lib.lua.json.encode`
  heute schon dort liegt. `data.nvim` bleibt die dünne Editor-Schicht
  darüber (Commands, Scope-Handling, Filter-UI-Wiring).

`casedesk.nvim` kann `data.nvim` später als weiche Schwester referenzieren
("Log aus dem aktuellen Case aufbereiten"), ohne dass eine Abhängigkeit in
die andere Richtung entsteht.

## Bedienung

### Usercommand

Drei Top-Level-Commands statt einem gemeinsamen, weil der Nutzer sie so
angefragt hat und weil Format-Erkennung bei reingepasteten Log-Fragmenten
(kein Dateiname, oft kein passender `filetype`) unzuverlässig ist — explizit
ist hier besser als "erraten". Aufbau nach Hausregel über
`lib.nvim.bindings.usercmd.composer` (Completion auf allen Ebenen):

```
:JSON [action] [opts]
:YAML [action] [opts]
:XML  [action] [opts]

:JSON                    -- Default-Action (pretty), ganzer Buffer
:JSON pretty             -- Standard-Pretty-Print
:JSON pretty 4           -- Indent explizit (Default: 2)
:JSON compact            -- eine Zeile, für zurück ins Ticket
:JSON lines              -- ein "key: value" je Zeile, verschachtelt als Pfad
:JSON lines --sep=/      -- Pfad-Trennzeichen überschreiben (Default ".")
:JSON keys               -- nur Struktur: alle (Pfad-)Keys, ohne Werte
:JSON sort               -- Keys alphabetisch, sonst wie eingelesen
:JSON filter             -- pickers.refine-UI über die Key-Pfade öffnen
:JSON ndjson              -- Zeile-für-Zeile parsen statt ein Objekt
```

`:YAML` und `:XML` spiegeln dieselben Actions, soweit sinnvoll (`ndjson`
z. B. nur bei `:JSON`).

### Scope: Buffer, Selektion, Register

Wie bei `replacer.nvim`/`markdown.nvim` Range-fähig:

- **Kein Range** → ganzer Buffer.
- **Visual-Range** (`:'<,'>JSON lines`) → nur die Selektion wird geparst und
  ersetzt. Der typische Fall: eine JSON-Spalte mitten in einem längeren
  Ticket-Text markieren.
- **Register** (`:JSON pretty --reg=+`) → Inhalt aus einem Register (Default
  `"`/System-Clipboard `+`) parsen, Ergebnis in einen neuen Scratch-Split
  statt in den Buffer zu schreiben — für den Fall, dass man aus einem
  Ticket-Tool kopiert hat und den Quellbuffer gar nicht anfassen will.

Ergebnis-Ziel per Flag steuerbar: `--inplace` (ersetzt Buffer/Range,
Default bei Buffer/Selektion-Scope), `--split` (neuer vertikaler Split,
Default bei Register-Scope), `--reg=<name>` (Ergebnis in ein Register
schreiben statt anzuzeigen).

### Render-Modi

| Modus | Beispiel-Output für `{"user":{"id":1,"name":"Ana"},"level":"error"}` |
| --- | --- |
| `pretty` | Standard-JSON, mehrzeilig, eingerückt (2 Spaces) |
| `compact` | `{"user":{"id":1,"name":"Ana"},"level":"error"}` |
| `lines` | `level: error` / `user.id: 1` / `user.name: Ana` (Keys sortiert) |
| `keys` | `level` / `user.id` / `user.name` |

## Filter-UI über `pickers.refine`

`pickers.refine` ist bereits genau das Modell dafür: ein Filter-Stack
(Include/Exclude-Klauseln, Substring oder `/regex/`) plus `vim.ui`-Prompt,
engine-agnostisch, aktuell schon von `replacer.nvim` als `<C-f>` verdrahtet.
`data.nvim` muss dafür nur:

1. Das geparste Objekt via Flatten in `{path, value}`-Items umwandeln
   (dasselbe Flatten-Modul wie für `lines`).
2. `pickers.refine.new` mit zwei Feldern füttern: `path` und `value` — der
   Nutzer kann dann sowohl nach Key-Pfad (`user.*`) als auch nach Wert
   (`error`) filtern.
3. Die verbleibenden Items nach Auswahl wieder zu einem (verschachtelten
   oder flachen) Objekt zusammensetzen und rendern — Include-Modus als
   Default (nur was matcht bleibt), Exclude als Flag (`:JSON filter
   --exclude` — "alles außer Rauschen-Keys wie `_internal.*` raus").

Kein eigener Picker nötig — `refine` selbst öffnet keinen, das bleibt bei
`data.nvim`s eigener, dünner Listen-UI (`lib.nvim.ui.kit.select` als
Fallback, `pickers.nvim`-Engine wenn vorhanden — für ein simples
Auswahl-Menü aus Key-Pfaden reicht das, ohne dass `pickers.nvim`
Hard-Dependency wird).

## Architektur-Skizze

### Modulbaum

```
data.nvim/
  lua/data/
    init.lua                -- setup()
    config/
      init.lua
      DEFAULTS.lua
    bindings/
      usrcmds.lua            -- :JSON / :YAML / :XML via composer
      keymaps.lua             -- optional, deaktivierbar
    core/
      flatten.lua            -- ⭐ Objekt -> {path, value}[], rekursiv, Trennzeichen konfigurierbar
      unflatten.lua           -- Rückrichtung, für Filter-Ergebnis -> Objekt
      ndjson.lua               -- zeilenweises Parsen statt ein Objekt
    format/
      json.lua                -- dünner Adapter auf lib.nvim.json / lib.lua.json.encode
      yaml.lua                -- dünner Adapter auf lib.lua.yaml (+ neuem Encoder)
      xml.lua                 -- dünner Adapter auf neues lib.lua.xml
      detect.lua               -- Heuristik: erstes Nicht-Whitespace-Zeichen, filetype-Fallback
    scope/
      resolve.lua              -- Buffer/Range/Register -> Text + Ziel-Handler
    render/
      pretty.lua  compact.lua  lines.lua  keys.lua  sort.lua
    filter/
      items.lua                -- Flatten-Ergebnis -> pickers.refine-Items
      ui.lua                    -- Prompt + Ergebnis-Anzeige
    @types/init.lua
    health.lua
  doc/data.txt
  docs/{ROADMAP,BINDINGS}.md
```

### Gemeinsames Zwischenformat (IR)

Kein eigenes IR nötig — anders als bei `spec.nvim` (mehrere Sprach-Dialekte)
gibt es hier nur **eine** Zwischenform: die dekodierte Lua-Table selbst
(`vim.json.decode`-Ergebnis, `yaml.simple_parse`-Ergebnis, künftiges
`xml.decode`-Ergebnis — alle drei liefern Lua-Tables/Scalars). `render/*` und
`core/flatten.lua` arbeiten ausschließlich gegen diese Lua-Value-Form, nie
gegen den ursprünglichen Text. Das ist der Grund, warum `:JSON lines` und
`:YAML lines` denselben `flatten.lua` benutzen können.

## Was in `lib.nvim` fehlt und ergänzt werden müsste

Bewusst **nicht** in `data.nvim` selbst gebaut, sondern als Erweiterung von
`lib.nvim` — wie im Ist-Zustand oben beschrieben, ist das die Stelle, wo
JSON/YAML/XML-Grundfunktionen ohnehin schon liegen:

| Baustein | Neues Modul | Umfang |
| --- | --- | --- |
| YAML-Encoder | `lib.lua.yaml.encode` (+ `.pretty`) | Analog zu `json.encode`: Lua-Value → YAML-Text, dasselbe Subset wie der Decoder abdeckend |
| XML-Decoder | `lib.lua.xml.decode` | pure Lua, minimaler XML-Parser (Elemente, Attribute, Text-Content — kein DTD/Namespaces-Vollsupport) |
| XML-Encoder | `lib.lua.xml.encode` (+ `.pretty`) | Gegenstück, deterministisch wie der JSON-Encoder |
| Rekursives Path-Flattening | `lib.lua.json.decode` erweitern, oder neues `lib.lua.tables.flatten` | Fehlt aktuell für alle drei Formate — `table_to_string_array` flacht nur eine Ebene |

`lib.lua.tables.flatten` als eigenständiges, formatunabhängiges Modul ist
wahrscheinlich der sauberere Schnitt als eine JSON-spezifische Erweiterung —
es ist reine Lua-Table-Arbeit, kein JSON-Wissen nötig, und dann von `data.nvim`
für alle drei Formate gleich nutzbar.

## Wiederverwendung: `lib.nvim` und eigene Plugins

| Bedarf | Modul |
| --- | --- |
| JSON decode/encode/pretty | `lib.nvim.json`, `lib.lua.json.encode` |
| YAML decode | `lib.lua.yaml` |
| Filter-Stack (Include/Exclude, Regex) | `pickers.refine` |
| Auswahl-UI ohne Picker-Engine | `lib.nvim.ui.kit.select` (hover_select) |
| Compound-Command + Completion | `lib.nvim.bindings.usercmd.composer` |
| Meldungen | `lib.nvim.nvim.notify` |
| Register lesen/schreiben | `lib.nvim.nvim.register` (falls vorhanden, sonst `vim.fn.getreg`/`setreg` direkt gekapselt) |
| Scratch-Split | `lib.nvim.nvim.window`/`buffer`-Helfer |

Sinnvolle Anschlüsse an eigene Plugins, alle optional:

- **`pickers.nvim`** — bessere Filter-Auswahl-UI als reiner
  `vim.ui.select`-Fallback, wenn installiert.
- **`casedesk.nvim`** — später ein `:Case log` o. Ä., das intern `data.nvim`
  aufruft, um ein Log im aktuellen Case-Ordner aufzubereiten. Richtung:
  casedesk nutzt data, nie umgekehrt.
- **`diff.nvim`** — "vorher/nachher"-Diff zeigen, wenn `filter` viele Keys
  entfernt hat, bevor in-place ersetzt wird.
- **`markdown.nvim`** — JSON/YAML-Fenced-Code-Blöcke in Markdown-Notizen
  direkt formatieren, über dessen Fenced-Scope-Feature (siehe
  `docs/ROADMAP` Fenced-Scope-Notiz) — der Cursor steht im Block, `:JSON
  pretty` wirkt nur auf den Block-Inhalt.

## Feature-Brainstorm

### Kern (sollte rein)

- `pretty` / `compact` / `lines` / `keys` / `sort` für JSON — das MVP.
- Scope-Handling Buffer/Selektion/Register.
- `:checkhealth data` — prüft, ob `lib.nvim` die benötigten Module hat
  (insbesondere während YAML-Encoder/XML noch fehlen, klar melden statt
  stumm zu scheitern).

### Stark, aber Phase 2+

- YAML `pretty`/`compact`/`lines` (braucht YAML-Encoder in `lib.nvim`).
- XML `pretty`/`compact`/`lines` (braucht XML-Modul komplett neu).
- `filter`-UI über `pickers.refine`.
- `ndjson`-Modus für zeilenweise Support-Logs.
- Format-Konvertierung zwischen den drei (`:JSON to yaml`,
  `:YAML to json`) — kommt "gratis", sobald alle drei über dieselbe
  Lua-Value-IR laufen.

### Spielwiese / später prüfen

- Auto-Erkennung des Formats bei generischem `:Data`-Alias-Command, wenn der
  Buffer weder `.json`/`.yaml`/`.xml`-Filetype noch eine klare erste
  Zeichenfolge hat (heuristisch, nie Pflichtpfad).
- Schema-/Typ-Ableitung aus einem Beispiel-Log (`:JSON infer` → grobe
  Struktur-Zusammenfassung: welche Keys, welche Werttypen, Nullable ja/nein)
  — nützlich, um schnell zu verstehen, was ein unbekanntes Log-Format
  überhaupt enthält.
- JMESPath/jq-ähnliche Ausdrücke statt nur Key-Pfad-Substring-Filter — deutlich
  mehr Aufwand, erst wenn der einfache Filter zu grob wird.

## Phasen

**Phase 0 — MVP (JSON only)**
`lib.lua.tables.flatten` in `lib.nvim` bauen · `data.nvim`-Repo anlegen ·
`:JSON pretty/compact/lines/keys/sort` · Scope Buffer + Selektion ·
`:checkhealth` · README/vimdoc/BINDINGS.

**Phase 1 — Register-Scope + Filter**
`--reg=`/Scratch-Split · `pickers.refine`-Wiring für `:JSON filter` ·
Include/Exclude-Flag.

**Phase 2 — YAML**
`lib.lua.yaml.encode` bauen · `:YAML` mit denselben Actions wie `:JSON`.

**Phase 3 — XML**
`lib.lua.xml` (Decode + Encode) bauen · `:XML` nachziehen.

**Phase 4 — Ökosystem**
`ndjson`-Modus · Format-Konvertierung zwischen JSON/YAML/XML ·
`markdown.nvim`-Fenced-Scope-Integration · `diff.nvim`-Vorher/Nachher bei
`filter`.

## Risiken / Komplexitätstreiber

| Risiko | Gegenmaßnahme |
| --- | --- |
| YAML-Encoder muss zum bestehenden, absichtlich unvollständigen Decoder-Subset passen — sonst decode→encode→decode nicht stabil | Encoder von Anfang an gegen dieselben Testfälle wie der Decoder prüfen |
| XML ist deutlich mehr Fläche (Attribute, Namespaces, CDATA, Self-closing Tags) als JSON/YAML | Subset explizit dokumentieren, wie beim YAML-Decoder — kein Anspruch auf volle Spec-Konformität |
| `lines`-Flattening bei sehr tiefen/zyklischen Strukturen | Tiefenlimit + klare Fehlermeldung statt Endlosschleife (analog zum Cycle-Check im JSON-Encoder) |
| Filter-UI wird nur dann benutzt, wenn sie schneller ist als "schau ich halt drüber" | Erst nach MVP bauen, Nutzung real beobachten statt vorab zu optimieren |
| Scope-Creep Richtung generischem Daten-Transformations-Tool (jq-Ersatz) | Phasen einhalten, JMESPath/jq-Ausdrücke bewusst in "Spielwiese" |

## Offene Fragen

1. **Name.** `data.nvim` ist sehr generisch (Namenskollision auf GitHub
   wahrscheinlich) — Alternativen: `structured.nvim`, `logfmt.nvim` (trifft
   den Hauptanwendungsfall enger), `wurst.nvim` (Insider-Name, unklar ob
   ernsthaft gemeint 🙂).
2. **`:Data`-Sammelcommand.** Zusätzlich zu `:JSON`/`:YAML`/`:XML` ein
   format-übergreifendes `:Data` mit Auto-Erkennung, oder bewusst nur die
   drei expliziten Commands, wie ursprünglich gewünscht?
3. **Wohin das rekursive Flatten genau?** `lib.lua.json.decode` erweitern
   (naheliegend, aber JSON-benannt für etwas Format-Unabhängiges) vs. neues,
   generisches `lib.lua.tables.flatten` (sauberer geschnitten, aber ein
   weiteres kleines Modul in `lib.nvim`).
4. **`filter`-Ergebnis:** immer flach zurückgeben (einfacher, aber nicht
   mehr valides JSON zum Zurückkopieren) oder wieder zu verschachteltem
   Objekt zusammensetzen (nützlicher, aber `unflatten.lua` zusätzlich nötig)?
   Tendenz: verschachtelt, weil das Ergebnis oft zurück ins Ticket soll.

## Literatur und Referenzen

- Eigene Plugins: [`lib.nvim`](https://github.com/StefanBartl/lib.nvim) ·
  [`pickers.nvim`](https://github.com/StefanBartl/pickers.nvim) ·
  [`casedesk.nvim`](https://github.com/StefanBartl/casedesk.nvim) ·
  [`markdown.nvim`](https://github.com/StefanBartl/markdown.nvim) ·
  [`diff.nvim`](https://github.com/StefanBartl/diff.nvim)
- Bereits vorhandene Bausteine, direkt im Repo gelesen (2026-09-15):
  `lib.nvim/lua/lib/lua/json/`, `lib.nvim/lua/lib/lua/yaml/`,
  `lib.nvim/lua/lib/nvim/json/`, `lib.nvim/lua/lib/nvim/fs/json/`,
  `pickers.nvim/lua/pickers/refine/init.lua`
- Prior Art zum Abgrenzen: `jq` (CLI), `gennaro-tedesco/nvim-jqx`,
  Online-JSON-Formatter (genau das, was dieses Plugin im Editor ersetzen
  soll)
