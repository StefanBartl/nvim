# casedesk — Konzept

> **Status: implementiert** unter [`lua/bindings/usrcmds/case/`](../../../lua/bindings/usrcmds/case/).
> Der reale Bestand (`C:/repos/WKDBook-Tricentis/Cases/SAP_Support/`) wurde
> auf die hier beschriebene flache Struktur migriert — Details und Zahlen in
> [MIGRATION.md](MIGRATION.md). Offene Ausbaustufen: [ROADMAP.md](ROADMAP.md).

Ein Modul der nvim-Config für den wiederkehrenden SAP-Support-Workflow:
Case in ServiceNow zuweisen → lokalen Case-Ordner anlegen → `Replies/`,
`Research/`, `Ressources/` befüllen → Research-Notes schreiben →
Kunden-Reply draften — plus den Querschnitt darüber: nach Company filtern,
alle offenen Cases sehen, eine Kurz-Infokarte pro Case.

Kein Einmal-Skript "lege 3 Ordner an", sondern ein **datengetriebener
Scaffolder**: die Struktur eines Cases steht als deklarative Tabelle
(Blueprint) in `config.lua`, jedes wiederkehrende Dokument ist eine echte
Markdown-Datei mit einem Tag (§4a), keine Inline-Strings im Lua-Code.

---

## 1. Zwei Verben

| Verb     | Gegenstand           | Beispiel                       |
| -------- | --------------------- | ------------------------------- |
| `:Case`  | **ein** Case (löst immer auf genau einen auf: Argument → Buffer → Auswahl) | `:Case info 1007631` |
| `:Cases` | **eine Menge** Cases  | `:Cases company Scan`           |

```
:Case new
   ┌ kit.form ────────────────────────────┐
   │ Case-Nr   › 1007631                  │  (kurz, Ordnername, Pflicht)
   │ Titel     › Restore deleted objects  │  (Pflicht, geht in jede Headline)
   │ Company   › Scania                   │  (optional)
   │ Name      › Anuhya                   │  (optional, Ansprechpartner)
   └──────────────────────────────────────┘
        ↓
   kit.viewer: Dry-Run-Plan
        mkdir  Cases/Open/1007631/Replies
        mkdir  Cases/Open/1007631/Research
        mkdir  Cases/Open/1007631/Ressources
        write  Cases/Open/1007631/Summary.md
        write  Cases/Open/1007631/Research/00_Research.md
        write  Cases/Open/1007631/Replies/00_PSO.md
        ↓ kit.confirm  [ Anlegen ] [ Abbrechen ]
   → angelegt + .case.json geschrieben, `00_Research.md` wird geöffnet
```

Jede erzeugte Markdown-File beginnt mit exakt einer Level-1-Headline:

```markdown
# 1007631 - `Restore deleted objects` - 00_Research
```

`apply.lua` (nicht das Template) setzt diese H1 zentral — gilt für **jeden**
Weg, auf dem eine Datei entsteht: Blueprint, `:Case add`, kopierte Dateien.

---

## 2. Die Case-Nummer

Die volle SNOW-Nummer ist rein **abgeleitet**, nie separat gepflegt:

```
SAP0000 {SHORT} {JAHR}   (konzeptionell)
SAP0000  940561   2026   →  SAP00009405612026   (render.to_snow, kompakt: URLs/Copy-Paste)
                          →  SAP0000 940561 2026 (render.to_snow_display, nur Anzeige in der Infokarte)
```

Gespeichert und getippt wird **nur die kurze Nummer** — Ordnername,
Headline-Token `{case}`, `.case.json`, jedes Command-Argument.

`render.to_short(raw)` normalisiert beides auf die kurze Form: tippst/
pastest du die volle SNOW-Nummer aus dem Ticket, wird `SAP0000`-Präfix und
das 4-stellige Jahres-Suffix abgeschnitten. Das macht die `CASE`-Argument-Typ
(`init.lua`, via `composer.register_type`) Validierung + `<Tab>`-Completion
gleichzeitig — jede Route mit `type = "CASE"` bekommt beides gratis.

---

## 3. Der Zustand IST der Ordner

Company als Ordnerebene war der ursprüngliche Fehler im Bestand (drei Cases
lagen eine Ebene tiefer als der Rest, ausschließlich wegen ihrer Company) —
siehe MIGRATION.md für die Details. Die flache Struktur trennt sauber:

```
Cases/SAP_Support/Cases/
  Open/         1007631/  859769/  …
  Closed/       862734/   …
  Reassigned/   (leer, s.u.)
```

`.case.json` bekommt **kein** `status`-Feld — wie die SNOW-Nummer aus
`case`+`year` abgeleitet wird, wird der Zustand aus dem Elternordner
abgeleitet. Ein Wert an zwei Stellen driftet; das ist im Bestand schon einmal
passiert (ein Ordner wurde umbenannt, ohne eine Notiz nachzuziehen, die
darauf verlinkte). Ein Umzug in einen anderen Zustand ist damit ein reiner
`fs_rename` — außer der einen Ausnahme, die keinen Zielordner hat:
permanentes Löschen (`:Case close`s Zielauswahl, s. u.).

**`Reassigned/`** ersetzt das frühere `OtherAgentTookIt/`: der eine Ordner,
in den ein Case geschoben wird, wenn ein anderer Agent ihn übernimmt — nicht
"noch niemandem zugewiesen", sondern "war meiner, ist es jetzt nicht mehr".

Die Zustände (und ihre `:Case <verb>`-Namen) stehen in `config.lua`:

```lua
M.states = { "Open", "Closed", "Reassigned" }
M.default_state = "Open"
M.state_verbs = { Closed = "close", Reassigned = "reassign" }
```

`init.lua`s `state_verb_routes()` generiert daraus `:Case close [nr]` und
`:Case reassign [nr]`. `reassign` ruft weiterhin direkt `ui.move_state(case,
"Reassigned")` — sofortiger Umzug, ein `kit.confirm` y/n. `close` ist die
einzige Ausnahme in dieser generierten Schleife: statt fest nach `Closed/`
zu verschieben, öffnet `ui.close` erst `kit.select` über jeden
Nicht-Default-Zustand PLUS einen Sentinel-Eintrag "Delete permanently" —
"wohin soll der Case?" ist damit eine echte Frage, nicht impliziert vom
Verb-Namen. Ein vierter echter Zustand bleibt trotzdem eine Zeile in
`config.states`, kein neuer Code-Pfad — nur die Sonderbehandlung des
`"close"`-Verbs selbst ist hartcodiert (`init.lua`s `state_verb_routes()`,
`verb == "close"`).

`ui.lua`s `do_move` (der gemeinsame Kern hinter `move_state` UND `close`s
Zielauswahl) löscht nach jedem Umzug weg von `default_state` außerdem eine
eventuell gespeicherte Session zu diesem Case (`pcall(require,
"sessions")`, optional) — Details und Begründung: SESSIONS.md §6. `do_delete`
(der Sentinel-Zweig) tut dasselbe, da ein gelöschter Case dieselbe
Sicherheitsnetz-Logik braucht wie ein verschobener.

**Bulk-Variante `:Cases close`** — für mehrere Cases auf einmal, zwei Wege
zur Auswahl-Menge: bereits gesetzte Marks (`marks.lua`, `m`/Visual-`m` in
`:Cases list`, "wie in filetree.nvim" — ein flaches, session-globales Set
von Kurznummern, überlebt das Schließen der `:Cases list`-View) haben
Vorrang; ohne Marks öffnet sich `kit.select({multi = true, ...})` — dessen
nativer `<Tab>`-Toggle/`<CR>`-Bestätigen-Chooser deckt genau das ab, was
ROADMAP.md dafür vorsah, ganz ohne `pickers.nvim`. Beide Wege münden in
`close_many`, das EINMAL nach dem Ziel fragt und es auf jeden Case
anwendet — Löschen verlangt dabei `DELETE` tippen (statt pro Case die
Nummer, das wäre bei mehreren Cases unzumutbar), ein einzelner Case in
`:Case close` verlangt seine eigene Nummer zurückgetippt (kein bloßes
y/n — irreversibel).

---

## 4. Modulaufbau

```
lua/bindings/usrcmds/case/
  init.lua        enable() → CASE-/BLOCK-Argtyp, :Case-/:Cases-/:Tricentis-Verb
  config.lua      repo_root/cases_root, states, Headline-Format, Blueprints
  templates.lua   Tag → Datei-Pfad, Token-Rendering (§4a)
  templates/      Summary.md, Notes.md, Research.md, Reply.md — echte Markdown-Files
  blocks.lua      Reply-Bausteine aus dem Arbeits-Repo lesen (§8b)
  blueprint.lua   Zugriff auf config.blueprints + Datei-Verb-Erkennung
  render.lua      to_snow / to_short / headline — reine Funktionen
  plan.lua        Blueprint + Tokens → Aktionsliste (rein, nur fs_stat als I/O)
  apply.lua       Aktionsliste ausführen (mkdirp / write / copy)
  meta.lua        .case.json lesen/schreiben
  detect.lua      Auto-Befüllung: Titel/Name/Links aus dem Case-Inhalt
  registry.lua    Cases/{Open,Closed,Reassigned}/<nr> scannen, gecacht
  resolve.lua     "welcher Case?" — Argument > Buffer > Auswahl
  query.lua       :Cases-Feldfilter, -grep, -stale + Gruppierung nach Zustand
  similar.lua     TF-IDF-Ähnlichkeit über Titel + Summary/Notes, ohne KI
  timeline.lua    Zeitachse pro Case aus Datei-mtimes, ohne Logbuch (§8h)
  ki.lua          KI-Prompt bauen + Antwort aufteilen, kein API-Call (§8i)
  doctor.lua      Bestands-Bericht (Findings mit sicherem Rename-Ziel), rein lesend
  normalize.lua   Fix-Teil zu doctor.lua — Plan/Dry-Run/Confirm/Apply
  linkcheck.lua   docs.tricentis.com-Links prüfen (lib.nvim.net.curl, async)
  replygate.lua   Pre-Send-Checks: Emojis, Markdown-Überschriften, tote Links
  links.lua       Link-Index über den ganzen Arbeits-Repo (repo_root, nicht nur Cases)
  terminology.lua Terminologie-Einträge über den ganzen Arbeits-Repo sammeln
  export.lua      Case als ein PDF bündeln (pandoc + headless Browser)
  migrate.lua     einmaliger Umzug von der alten Struktur (siehe MIGRATION.md)
  ui.lua          kit.form / kit.select / kit.viewer / kit.confirm / kit.menu-Verdrahtung
```

Statusline-Badge (aktueller Case) liegt bewusst außerhalb
dieses Moduls, unter `lua/wkdnvchad/ui/statusline/modules/casedesk/` — casedesk
selbst hat keine Statusline-Abhängigkeit, die Statusline liest nur
`resolve.sync`/`meta.read` von außen.

`resolve.lua` beantwortet "welcher Case?" an einer Stelle — Argument
(schon durch `CASE` normalisiert) → Case des fokussierten Buffers
(Registry-Abgleich, kein Marker-File nötig) → `kit.select` über die offenen
Cases. Jede `:Case`-Route mit `[case]` benutzt sie.

---

## 4a. Templates — feste Dateien mit Tag statt Inline-Text

Jedes wiederkehrende Dokument ist eine echte Markdown-Datei unter
`templates/`, ansprechbar über einen Tag statt einen hartcodierten Pfad:

```lua
-- templates.lua
M.SUMMARY = "$Summary"
M.RESEARCH = "$Research"
M.REPLY = "$Reply"
```

```lua
-- config.lua, Blueprint-Node
{ type = "file", path = "Summary.md", key = "summary", template = templates.SUMMARY }
```

`templates.render(tag, tokens)` liest die Datei, ersetzt `{name}`/`{case}`/
`{title}`/… und liefert Body-Zeilen zurück — die H1 kommt weiterhin zentral
aus `apply.lua`, ein Template enthält nur den Body. Der Gewinn: den Wortlaut
einer Reply-Vorlage ändern ist ein Markdown-Edit, kein Lua-Edit, und ein
neues wiederkehrendes Dokument ist `M.register(tag, "Datei.md")` plus eine
Blueprint-Zeile — nie ein zweiter Ort, an dem der Text gepflegt wird.

`templates/Reply.md`:
```markdown
Dear {name},


```

---

## 5. Blueprint

```lua
-- config.lua, Default-Blueprint
blueprints = {
  default = {
    { type = "dir",  path = "Replies" },
    { type = "dir",  path = "Research" },
    { type = "dir",  path = "Ressources" },  -- so geschrieben im gesamten Bestand

    { type = "file", path = "Summary.md",              key = "summary",  template = templates.SUMMARY },
    { type = "file", path = "Research/00_Research.md", key = "research", template = templates.RESEARCH, open = true },
    { type = "file", path = "Replies/00_PSO.md",        key = "reply",    template = templates.REPLY },
  },
}
```

Node-Eigenschaften: `template` (Tag, bevorzugt) oder `body` (Inline-Fallback,
für Sonderfälle) · `headline = false` unterdrückt die H1 · `overwrite = false`
(Default) — existierende Dateien werden nie angefasst · `key = "..."` macht
den Node als generiertes Datei-Verb verfügbar (§6) · `open = true` öffnet die
Datei nach `:Case new`.

Kein `README.md`-Node: keiner der Bestands-Cases hat je eine README gehabt,
wohl aber praktisch alle ein `Summary.md` auf Case-Root-Ebene — das Blueprint
folgt der tatsächlichen Konvention.

---

## 6. Command-Oberfläche

### `:Case` — ein Case

| Command                     | Wirkung                                                          |
| --------------------------- | ------------------------------------------------------------------- |
| `:Case new [nr]`            | Prompt-Kette + Scaffold (respektiert `config.company_blueprints`)     |
| `:Case info [nr]`           | Kurz-Infokarte — `e` edit · `s` summary · `o` open folder            |
| `:Case summary/research/reply [nr]` | generiert aus dem Blueprint (jeder Node mit `key`)          |
| `:Case open [nr]`           | Case-Ordner öffnen (Filetree-Reveal wenn verfügbar, sonst netrw)     |
| `:Case add <name> [suffix]` | neue Markdown-Datei; `reply [suffix]` nummeriert automatisch (`suffix` überschreibt den Namensteil, sonst `Reply`) |
| `:Case activity [nr]`       | Zwischenablage (SNOW Activity Stream) als neue nummerierte `Research/`-Datei |
| `:Case notes [nr]`          | `Notes.md` öffnen (Arbeitsnotizen, §8a) |
| `:Case template [name]`     | Reply-Baustein aus `Workflow/Templates/` an der Cursor-Position einfügen (§8b) |
| `:Case reply check`         | Pre-Send-Gate auf dem aktuellen Buffer: Emojis, Markdown-Überschriften, tote Links, `s` startet `language.nvim`s Spellcheck (§8c) |
| `:Case similar [nr] [n]`    | ähnliche Cases per TF-IDF über Titel + `Summary.md`/`Notes.md` |
| `:Case timeline [nr]`       | Sitzungen aus Datei-mtimes, älteste zuerst, mit Gesamtdauer (`timeline.lua`, §8h) |
| `:Case ki [nr]`             | KI-Analyse-Prompt aus dem Activity Stream (Zwischenablage) bauen, zurück in die Zwischenablage (`ki.lua`, §8i) |
| `:Case ki import [nr]`      | eingefügte KI-Antwort auf Research/Replies/Notes verteilen (`ki.lua`, §8i) |
| `:Case copy <src>`          | Datei in den Case kopieren, Zielordner per Auswahl                  |
| `:Case sync [nr]`           | fehlende Blueprint-Teile nachziehen (nie überschreiben)              |
| `:Case close [nr]`          | Zielauswahl (`kit.select`): jeder Nicht-Default-Zustand, oder "Delete permanently" (Nummer zurücktippen zum Bestätigen) |
| `:Case reassign [nr]`       | generiert aus `config.states` — nach `Reassigned/` verschieben       |
| `:Case snow [nr]`           | Ticket-ID öffnen (falls `snow_url_format` gesetzt) oder kopieren     |

### `:Cases` — der Querschnitt

| Command                  | Wirkung                                                    |
| ------------------------- | ------------------------------------------------------------ |
| `:Cases list`             | alle Cases, gruppiert nach Zustand — auch die Mark-View: `m`/Visual-`m` markiert, `c` schließt die Marks |
| `:Cases close`            | mehrere Cases auf einmal: Marks (falls gesetzt) oder `kit.select({multi=true})`, dann EINE Zielauswahl für alle |
| `:Cases company [pattern] [--exact\|-e] [--re\|-r]` | Substring (Default), volle Gleichheit oder Lua-Pattern; leer = "Company ist gesetzt" |
| `:Cases title/name/notes/priority/tosca_version [pattern] [--exact\|-e] [--re\|-r]` | dieselbe generische Filter-Route, ein Feld pro Zeile in `config.infocard_fields` |
| `:Cases find company=Scan year=2026 [--exact\|-e] [--re\|-r]` | Feld-Kombination via composer `kv` (bare `key=value`, kein `--`) |
| `:Cases grep <pattern> [--re\|-r]` | Volltextsuche über alle `.md`-Dateien aller Cases              |
| `:Cases recent [n]`       | die `n` (Default 10) zuletzt angefassten Cases, neueste zuerst |
| `:Cases stale [days]`     | offene Cases seit `days` (Default 7) Tagen nicht angefasst, älteste zuerst |
| `:Cases history [company]` | alle Cases einer Company auf einen Blick, nach Zustand gruppiert; ohne Argument die Company des aktuellen Case-Buffers |
| `:Cases stats`            | Anzahl nach Zustand / Company / Jahr                          |
| `:Cases doctor`           | Bestands-Bericht, rein lesend (`doctor.lua`, §10)              |
| `:Cases normalize`        | behebt die von `doctor` gemeldeten Abweichungen (Dry-Run + Confirm) |
| `:Cases linkcheck [nr]`   | prüft `docs.tricentis.com`-Links auf tote Seiten (`linkcheck.lua`) |
| `:Cases pickers`          | `kit.menu`: Attachments / Links / Cases ohne `.case.json` / Terminology |
| `:Cases terminology`      | jeder Begriff aus jeder `Terminologie.md` im Arbeits-Repo (`terminology.lua`, §8f) |
| `:Cases export [nr]`      | Summary/Notes/Research/Replies als ein PDF bündeln (`export.lua`, §8g) |

Ein Treffer öffnet direkt die Infokarte, mehrere gehen in `kit.select`.

### `:Tricentis` — über SAP_Support hinaus, der ganze Arbeits-Repo

Eigener Verb, nicht `:Cases` — alles oben ist auf `config.root`
(`Cases/SAP_Support`) beschränkt, `:Tricentis` durchsucht `config.repo_root`
(`Notes/`, `Workflow/`, `Terminologie/`, `Tosca/` mit).

| Command                | Wirkung                                                    |
| ----------------------- | ------------------------------------------------------------ |
| `:Tricentis links [scope]`    | Link-Picker über den Bestand, `scope` narrowt auf `cases\|notes\|workflow\|terminologie\|tosca\|todo\|all` (`links.lua`) |

`[nr]` ist überall dieselbe optionale `CASE`-Arg mit `<Tab>`-Completion aus
der Registry.

---

## 7. Auto-Befüllung (`detect.lua`)

Beim Bearbeiten der Infokarte werden fehlende Felder vorgeschlagen, nie
still gespeichert:

| Feld    | Quelle                                                          |
| ------- | ------------------------------------------------------------------ |
| `title` | erste H1 über die Case-Dateien (neueste zuerst)                     |
| `name`  | `Dear <X>,` aus der neuesten Datei in `Replies/`                     |
| `links` | alle URLs über die Case-Dateien, dedupliziert                       |
| `notes` | nur manuell                                                          |

---

## 8. `.case.json` (Sidecar)

```json
{
  "case": "1007631",
  "year": "2026",
  "title": "Restore deleted objects",
  "company": "Scania",
  "name": "Anuhya",
  "notes": "wartet auf Rückmeldung seit 02.08.",
  "links": ["https://docs.tricentis.com/..."],
  "blueprint": "default",
  "created": "2026-08-04T09:12:00Z"
}
```

Kein `snow`-Feld (aus `case`+`year` berechnet), kein `status`-Feld (aus dem
Elternordner abgeleitet) — beides bewusst, siehe §3.

---

## 8a. `Summary.md` ≠ `Notes.md` — zwei Dokumente, zwei Adressaten

Die wichtigste inhaltliche Unterscheidung im Case-Ordner:

| Datei | Adressat | Form |
| ----- | -------- | ---- |
| `Summary.md` | **ServiceNow / Kunde** — wird ins Ticket kopiert | Festes Vier-Sektionen-Template aus `WKDBook-Tricentis/Workflow/Templates/SummaryTemplate.md`: `Problem statement`, `Case notes`, `Links`, `Solution or workaround`. **Keine Markdown-Syntax** — SNOW rendert sie nicht, ein `##` oder `**fett**` steht wörtlich im Ticket. |
| `Notes.md` | **du selbst, Coaches, Team** | Frei. Was versucht wurde, was im Coaching besprochen wurde, Tasks aus Meetings. |

`:Case new` legt beide an; `Summary.md` bekommt bewusst **keine** H1
(`headline = false` im Blueprint), weil das SNOW-Template direkt mit
`╓ Problem statement` beginnt und eine eingefügte Überschrift vor jedem
Einfügen ins Ticket wieder gelöscht werden müsste.

`:Cases doctor` prüft beides: `summary-not-snow` (fehlt ganz, oder eine der
vier Sektionen fehlt) und `summary-markdown` (Markdown-Syntax drin).
**Beide sind reine Berichte** — kein Rename kann Text erzeugen, den ein
Mensch schreiben muss, deshalb fasst `:Cases normalize` sie nie an.

> **Historie:** eine frühere `doctor`-Regel behandelte `ProblemSummary.md`,
> `WorkNote.md`, `CaseNote.md` und `TillNow.md` als *Aliase* von
> `Summary.md` und benannte sie dorthin um. Das war falsch — es sind
> Arbeitsnotizen, also `Notes.md`. Der Fehler hat in einem Case ein echtes
> SNOW-Summary überschrieben (aus Git wiederhergestellt, s. MIGRATION.md).
> Die Regel heißt jetzt `notes-alias` und zielt auf `Notes.md`.

---

## 8b. Reply-Bausteine (`blocks.lua`)

Unter `WKDBook-Tricentis/Workflow/Templates/` liegt eine gewachsene
Bibliothek fertiger Reply-Textbausteine (`RequestMoreInfo`, `CloseCase`,
`GermanSpeaker`, `Swarming/HandOverCase`, die `Wordings/`- und `CDX/`-Sätze
— aktuell 34). `:Case template [name]` fügt einen davon an der
Cursor-Position ein, mit `{case}`/`{name}`/`{title}`/`{today}`-Ersetzung aus
dem Case des aktuellen Buffers.

Nicht zu verwechseln mit `templates.lua`/`templates/` (§4a): das ist
casedesks *eigenes* Scaffolding-Material, liegt in der nvim-Config und
beschreibt, wie eine neue Case-Datei aussieht. `blocks.lua` liest fremdes,
im Arbeits-Repo gepflegtes Material, das in einen Text eingefügt wird.
Deshalb zwei Module statt einem.

Die Discovery ist rekursiv und dateibasiert: ein neuer Baustein ist eine
neue `.md`-Datei, kein Lua-Edit. Fehlt das Verzeichnis (Maschine ohne
ausgechecktes Arbeits-Repo), liefert `blocks.list()` eine leere Liste statt
eines Fehlers — `:Case template` sagt dann „no reply blocks found", der Rest
von casedesk läuft normal weiter.

---

## 8c. Reply-Gate (`replygate.lua`)

`:Case reply check` prüft den **aktuellen Buffer** vor dem Versand:

- **Emojis** — `require("emojis").ops().count()`/`.clear()`, die pure,
  skriptbare API (nicht das interaktive `:Emojis`-Kommando). `c` im Report
  löscht sie, Leerzeichen werden dabei sauber kollabiert (emojis.nvims
  eigene Garantie).
- **Markdown-Überschriften** — dieselbe `^#+%s`-Regel wie `doctor.lua`s
  `summary-markdown` (§8a): eine Reply ist Klartext, keine `##`.
- **Tote Links** — wiederverwendet `linkcheck.lua`s bereits generisches
  `M.run(targets, on_done)` direkt auf die im Buffer gefundenen URLs, statt
  die Curl-Logik zu duplizieren.
- **Grammatik/Rechtschreibung** — bewusst nicht neu gebaut. `s` im Report
  startet `language.nvim`s eigenes `:Spellcheck` auf dem Buffer
  (`language.spellcheck(nil, "buffer")`) — das Ergebnis ist natives
  Buffer-Highlighting, kein Datenwert, den `replygate.lua` sinnvoll
  zurückgeben könnte.

Jede Integration ist `pcall`-abgesichert und optional: ohne `emojis.nvim`
laufen Überschriften- und Link-Check trotzdem, nur ohne Emoji-Zeile.

Läuft absichtlich auf `bufnr = vim.api.nvim_get_current_buf()`, nicht über
`resolve.pick` auf "die neueste Reply" — der Punkt ist, das zu prüfen, was
gerade auf dem Schirm ist, nicht zwingend eine Reply (funktioniert genauso
auf `Notes.md`).

---

## 8d. Repo-weiter Link-Index (`links.lua`, `:Tricentis links`)

Einziges Modul in casedesk, das bewusst über `config.root`
(`Cases/SAP_Support`) hinausgeht — es liest `config.repo_root`: `Cases/`,
`Notes/`, `Workflow/`, `Terminologie/`, `Tosca/`, `ToDo-Collection/`. Deshalb
ein eigener `:Tricentis`-Verb statt einer weiteren `:Cases`-Route — eine
`:Cases`-Route hätte stillschweigend erweitert, was der Name des Verbs
verspricht (nur Cases).

`M.find(scope)` sammelt jeden `https?://`-Link aus jeder `.md`-Datei im
gewählten Bereich (oder überall, `scope = nil`/`"all"`), pro Datei
dedupliziert (dieselbe URL fünfmal in einer Datei ist ein Treffer, nicht
fünf — Cross-Datei-Duplikate bleiben, derselbe Link in zwei Cases ist zwei
nützliche Treffer). Ersetzt `Notes/Links.md`, die handgepflegte
Link-Sammlung — liest, was ohnehin schon überall steht, statt eine zweite
Kopie zu pflegen.

Gegen den realen Bestand gemessen: 617 einzigartige Links, 117 ms für den
vollen Scan. Kein Cache — ein Kommando, kein Hotpath (`PERFORMANCE.md`:
erst messen, dann optimieren). Sollte der Bestand deutlich wachsen, wäre
`lib.nvim.cache.memory.namespace(name, { ttl = … })` die nächste Stufe —
das Modul existiert schon, siehe `PERFORMANCE.md`s Cache-Regeln.

---

## 8e. Ähnliche Cases, ohne KI (`similar.lua`, `:Case similar`)

TF-IDF-gewichtete Kosinus-Ähnlichkeit über Titel + `Summary.md` + `Notes.md`
jedes Cases — bewusst kein Embedding-Modell, s. u. Begriffe, die in fast
jedem Case vorkommen („SAP", „Tosca", „customer"), zählen fast nichts;
seltene, diagnostische Begriffe (Fehlermeldungen, Komponentennamen)
dominieren den Score. Jeder Treffer zeigt die Begriffe, die ihn verursacht
haben — bei einem rein lexikalischen Verfahren muss sichtbar sein, *warum*
etwas matcht, nicht nur *dass*.

**Drei Bugs, die erst der Test gegen den echten Bestand zeigte** (2026-08-05):

1. Box-Zeichen (`╓`, `╙───────`, in vielen Summaries als Trennlinien
   verwendet) landeten als Top-„Begriffe" → ein Token braucht jetzt
   mindestens einen ASCII-Buchstaben.
2. Zwei fast leere Summaries mit genau einem gemeinsamen Wort („Research")
   ergaben 87 % — zwei 1-Term-Vektoren sind zwangsläufig parallel → eine
   Mindest-Dokumentlänge (8 Begriffe) und eine Mindest-Überlappung
   (2 gemeinsame Begriffe), bevor überhaupt gewertet wird.
3. Lineare Termfrequenz ließ ein 20× wiederholtes Wort ein selteneres,
   diagnostisch wichtigeres überstimmen → sublinear (`1 + log(tf)`).

**Nachtrag (2026-08-07): Titel-Gewichtung.** Ein Wort, das im Titel steht
(einem Satz, den man selbst als Zusammenfassung gewählt hat), sagt mehr
über das eigentliche Thema aus als dasselbe Wort irgendwo in drei Absätzen
Korrespondenz mit Grußformeln und SNOW-Boilerplate. `term_counts` zählt
Titel-Begriffe deshalb `TITLE_BOOST = 2`-fach zusätzlich zu ihrem
natürlichen Vorkommen im Volltext — die sublineare TF-IDF-Gewichtung
verhindert, dass das den Score dominiert, hebt Titel-Begriffe aber
sichtbar an. Ergänzt die bereits vorhandene zweisprachige Stopwortliste
(Artikel, Füllwörter), die genau denselben „Menge schlägt Relevanz
nicht"-Zweck schon für häufige Funktionswörter erfüllt.

**Ehrlicher Stand danach:** die Reihenfolge der Treffer wirkt plausibel
(913070 ↔ 948965, beide DEX/Distributed Execution, 19 %; 711373 ↔ 859769,
beide SAP-Fiori-Elementidentifikation, 12 % nach Einbeziehung von
`Notes.md`), aber die Scores sind niedrig und mehrere Cases fallen ganz
raus, weil ihre `Summary.md`/`Notes.md` zu dünn sind — kein
Algorithmus-Problem, ein Bestands-Befund: das Verfahren kann nur so gut
sein wie der Text, den es vergleicht. ~14 ms pro Aufruf gemessen, kein
Cache (Kommando, kein Hotpath).

**Warum (noch) keine KI:** ein Embedding-Modell würde den echten
Schwachpunkt lösen — zwei Cases mit demselben Problem, aber komplett
anderen Worten, ergeben hier Score 0 — kostet aber eine echte Abhängigkeit
(lokales Modell oder API), Latenz und Nicht-Determinismus. Zwei billigere
Stellschrauben stehen davor: bessere Summaries (der größte Hebel) und
`Research/` mit einbeziehen. Die Entscheidung "reicht das, oder braucht es
KI" ist offen — siehe [ROADMAP.md](ROADMAP.md).

---

## 8f. Terminologie-Sammler (`terminology.lua`, `:Cases terminology`)

Sammelt jeden `## `/`### `-Begriff aus jeder `Terminologie.md` im ganzen
Arbeits-Repo (`config.repo_root` — Cases, `Tosca/Onboarding/`,
`Tosca/Notes/`, jede Company-Terminologie …) in einen durchsuchbaren Index,
statt sie in den geteilten `Terminologie/`-Ordner zu verschieben: ein
Begriff, den du lokal in einem Case erklärst, ist damit sofort aus jedem
anderen Case heraus auffindbar, ohne dass du ihn irgendwohin verschieben
musst. Erreichbar über `:Cases terminology` und `:Cases pickers` →
Terminology — beide rufen denselben `ui.terminology()` auf.

Zwei Eigenheiten, die erst der Lauf gegen den echten Bestand zeigte
(2026-08-06):

- **Nicht jede Datei ist flach.** Die meisten haben H1-Titel + H2-Begriffe,
  aber mindestens eine (ein Tosca-Onboarding-Dokument) gruppiert Begriffe
  unter einer nummerierten H2 (`## 1. Kernkonzepte & Infrastruktur`) mit
  den eigentlichen Begriffen eine Ebene tiefer als H3. `parse_file()`
  behandelt deshalb **sowohl** `## ` **als auch** `### ` als
  Begriff-Grenze — eine reine Gruppen-Überschrift hat keinen Fließtext vor
  ihrem ersten H3-Kind, fällt also automatisch durch den ohnehin
  vorhandenen „leerer Body" Filter raus, ohne eigene Sonderlogik.
- **Manche Überschriften sind selbst Markdown-Links** —
  `## [Completed Scenario](https://docs.tricentis.com/...)`, durchgängig in
  `Tosca/Notes/OSV/Terminologie.md`. `clean_heading()` extrahiert nur den
  Linktext als Begriff.

Ein Begriff, der in mehreren Dateien unterschiedlich erklärt wird,
erscheint absichtlich mehrfach — eine „Gewinner"-Deduplizierung würde genau
die Nuance verstecken, die der zweite Eintrag hinzufügt. Gegen den echten
Bestand gemessen: 122 Einträge, 27 ms.

---

## 8g. PDF-Export (`export.lua`, `:Cases export`)

`pdfport.nvim` war das Plugin, das ROADMAP.md ursprünglich dafür vorsah —
geprüft und verworfen: seine API liest/öffnet nur *bestehende* PDFs
(`M.open`/`M.extract`), keine Erzeugungsfunktion. Stattdessen zwei externe
Tools, keins davon neu implementiert:

1. **`pandoc`** wandelt das gebündelte Markdown (`Summary.md`, `Notes.md`,
   `Research/*.md`, `Replies/*.md`, sortiert) in eigenständiges HTML —
   Tabellen, verschachtelte Listen, Links, alles, was ein selbstgebauter
   Konverter falsch machen würde.
2. Ein **headless Chrome/Edge** (auf dieser Maschine bereits installiert)
   druckt dieses HTML per `--print-to-pdf` zu PDF — keine LaTeX-Engine
   (`pdflatex`, mehrere GB) nötig, die `pandoc` für den direkten
   Markdown→PDF-Weg verlangen würde.

`pandoc` war auf dieser Maschine nicht vorinstalliert — per `winget install
--id JohnMacFarlane.Pandoc` nachinstalliert (Nutzer-Bestätigung vorher
eingeholt, s. Commit-Historie). `M.export()` prüft beide Werkzeuge zur
Laufzeit (`vim.fn.executable("pandoc")`, dann eine feste Liste üblicher
Chrome-/Edge-Installationspfade) und meldet **welches** fehlt, statt eines
generischen Fehlers — „pandoc fehlt" und „kein Browser gefunden" brauchen
unterschiedliche Abhilfe.

Läuft komplett async (`vim.system`, zwei verkettete Prozessaufrufe) und
schreibt nach `<case-dir>/Export.pdf` — Case-Root, nicht `Ressources/`,
dieselbe Ebene wie `Summary.md`/`Notes.md`, weil es ein abgeleitetes
Artefakt des Cases ist, kein eingehender Anhang. Isoliert gegen ein
Scratch-Case getestet (nicht den echten Bestand): 46 KB PDF, Summary/
Notes/Research korrekt zusammengeführt.

---

## 8h. Zeitachse pro Case (`timeline.lua`, `:Case timeline`)

„Wann und wie lange wurde an diesem Case gearbeitet?" — rein aus den
mtimes der Case-Dateien rekonstruiert, kein separates Logbuch, das aus dem
Takt geraten könnte (dieselbe Begründung wie `detect.last_touched` und §3s
„der Zustand IST der Ordner": ableiten statt eine zweite Kopie pflegen).

`M.sessions(case_dir)` sammelt jede Datei-mtime unter dem Case-Ordner
(`.case.json` eingeschlossen — ein Infokarten-Edit ist echte Aktivität) und
gruppiert sie nach demselben Prinzip, mit dem ein Kalender aus reinen
Klick-Zeitstempeln „wie lange ging dieses Meeting" ableitet: zwei Touches
innerhalb von `config.timeline_session_gap_minutes` (Default 120) gelten
als dieselbe Sitzung, ein größerer Abstand eröffnet eine neue. `:Case
timeline [nr]` zeigt das chronologisch (älteste zuerst), pro Sitzung
Zeitspanne, Dauer und die einzelnen Datei-Touches, plus eine Gesamtsumme.

**Ehrlich benannte Grenze:** eine Sitzungsdauer ist eine **untere
Schranke**. Eine mtime markiert den Speicherzeitpunkt, nicht den
Bearbeitungsbeginn — eine Sitzung mit genau einem Touch zeigt „touched"
(Dauer 0), obwohl davor real gearbeitet wurde. Für die grobe Frage „wann
war ich an diesem Case dran, wie viele Sitzungen waren das" reicht das;
für eine belastbare Stundenzahl bräuchte es echtes Fokus-Tracking (Buffer-
Enter/Leave-Autocmds über die Case-Lebensdauer) — genau das separate
Logbuch, das dieser Ansatz bewusst vermeidet.

---

## 8i. KI-Analyse-Runde (`ki.lua`, `:Case ki` / `:Case ki import`)

Bisheriger Ablauf (`WKDBook-Tricentis/Workflow/CDX/StartChat.md`): vor
jedem KI-Chat von Hand den Rollen-/Task-Block plus drei Policy-Pfade
kopieren, den Activity Stream dazu, und die Antwort danach von Hand in
Reply-Entwurf/interne Notiz/Rest aufteilen — fehleranfällig (ein Pfad
vergessen) und für jeden Case neu getippt. `ki.lua` macht aus beiden
Enden dieses Copy-Paste-Vorgangs ein Kommando, **ohne** selbst mit einer
KI zu sprechen — bewusst kein API-Call, dieselbe Begründung wie bei
`:Case similar` (§8e): keine externe Abhängigkeit, keine Latenz, kein
Nicht-Determinismus im Modul selbst. Der Nutzer postet weiter in den
Chat seiner Wahl (Gemini, Claude, …) und pastet die Antwort zurück; das
Modul sorgt nur dafür, dass Prompt-Aufbau und Antwort-Aufteilung an
beiden Enden gleich bleiben.

**`:Case ki [nr]`** liest den Activity Stream aus der Zwischenablage
(dieselbe Quelle wie `M.activity`), rendert `templates/KiPrompt.md`
(Rollenblock, Case-Kontext, Policy-Pfade, ein fest vorgegebenes
Antwortformat) über `templates.render` — derselbe Mechanismus wie
`Summary.md`/`Reply.md` (§4a) — legt das Ergebnis als
`Research/NN_KiPrompt.md` ab und kopiert es zurück in die
Zwischenablage, einfügefertig für den Chat.

**`:Case ki import [nr]`** liest eine eingefügte KI-Antwort aus der
Zwischenablage und verteilt sie:

| Abschnitt der Antwort | Ziel |
| --- | --- |
| 1. Activity Stream Analysis, 2. Difficulty Assessment, 3. Solution/Next Steps | zusammen in `Research/NN_KiAnalysis.md` |
| 4. Reply Draft (English) | neuer `Replies/NN_Reply.md` — Entwurf, läuft wie jeder andere Reply durch `:Case reply check`, geht nie automatisch raus |
| 5. Internal Notes (German) | an `Notes.md` angehängt, mit Zeitstempel-Trenner |

`M.parse_response()` matcht **nur auf die führende Ziffer** einer
`## N. …`-Überschrift, nicht auf den genauen Wortlaut danach — ein LLM
hält eine durchnummerierte Gliederung deutlich zuverlässiger ein als
einen exakten Überschriftentext, also stützt sich der Parser auf die
billigere Invariante. Eine fehlende Sektion (z. B. keine Notiz) wird
einfach ausgelassen, kein Fehler.

**Ein echter Bug im ersten Testlauf:** `{activitystream}` (ursprünglich
mit Unterstrich `{activity_stream}`) wurde nicht ersetzt — `templates.lua`s
Substitutions-Pattern `%{(%w+)%}` matcht nur alphanumerische Zeichen,
`%w` schließt in Lua keinen Unterstrich ein. Statt das geteilte Pattern
anzufassen (Blast Radius: jedes Template) heißt der Token jetzt
`activitystream`, ohne Unterstrich. Isoliert gegen einen Scratch-Case
getestet (nicht den echten Bestand): beide Kommandos fehlerfrei, alle
drei Zieldateien korrekt befüllt.

---

## 9. Was aus lib.nvim benutzt wird

`ui.kit` (`form`/`select`/`viewer`/`confirm`/`input`/`menu`) für jede
Interaktion, `usercmd.composer` für `:Case`/`:Cases`/`:Tricentis` inkl.
`CASE`-/`BLOCK`-Argtyp, Flags, `enum` und generierter Routen,
`fs.mkdirp`/`write.to_file`/`read`/`json`/`collect_recursive` fürs
Dateisystem, `cross.fs.mutate.rename_file`/`.retry` für jedes Rename UND
jedes Löschen mit Windows-Lock-Retry (`normalize.lua`, `:Case(s) close`/
`reassign` — s. u.),
`cross.open_default`/`copy_to_clipboard` für `:Case snow` und die
Attachment-/Links-Picker, `net.curl` für `:Cases linkcheck` (einziges Modul
hier mit echtem Netzwerk-I/O — bewusst über den vorhandenen
`vim.system`-Wrapper statt eigenem Shell-Aufruf). Nichts davon shellt
direkt aus — funktioniert unabhängig vom Plugin-Modus (lokal/remote).

Optionale Integrationen über `pcall(require, …)`, mit Fallback statt hartem
Fehler, wenn das Plugin fehlt: `filetree.nvim` (`:Case open`s Reveal),
`emojis.nvim` und `language.nvim` (`:Case reply check`, §8c).

Optionale Integration über `pcall(require, …)`: `filetree.nvim` für
`:Case open`s Reveal (Fallback: netrw).

---

## 10. `:Cases doctor` (`doctor.lua`)

Reiner Bericht — liest, schreibt nie. `M.check()` scannt jeden Case auf
sechs Muster: Case-Notiz unter einem der vier bekannten Alias-Namen statt
`Summary.md`, `Research.md` als Flat-File statt `Research/`-Ordner,
`Solutions/`(Plural)/`Solution.md` statt `Solution/`, zwei bekannte
Tippfehler-Dateinamen (alle vier: MIGRATION.md §4), fehlender `NN_`-Präfix
auf Dateien direkt in `Research/`/`Replies/`, und (SESSIONS.md §6, Paket 3)
eine gespeicherte `sessions.nvim`-Session zu einem Case, der nicht mehr
`config.default_state` ist (`stale-session`). `M.describe()` rendert die
Liste für `kit.viewer`.

Gegen den migrierten Bestand am 2026-08-04: **22 Findings über 8 Cases**
— die ersten 10 decken sich exakt mit der Analyse aus MIGRATION.md §4, die
restlichen 12 kamen mit dem `NN_`-Präfix-Check dazu. Ablauf und Ergebnis
des realen `:Cases normalize`-Laufs: [MIGRATION.md](MIGRATION.md)s
„Namens-Aufräumen".

`:Cases normalize` (`normalize.lua`) ist der Fix-Teil und baut auf genau
diesen `DoctorFinding`-Einträgen auf — derselbe Plan → Dry-Run → Confirm → Apply-
Pfad wie `:Case new`, nur mit `rename` als Aktionstyp statt `write`. Ein
Finding trägt entweder `to` (Rename-Ziel, `from -> to`) ODER `action`
(eine `fun(): ok, err`-Closure für einen Fix, der kein Rename ist) — nie
beide. `stale-session` ist der erste `action`-Finding-Typ: `action` ruft
`sessions.delete(name)` statt `mutate.rename_file(from, to)`. Damit ein
Finding zum `Lib.Case.NormalizeStep` wird (statt in `skipped` zu landen),
reicht entweder `to` oder `action`; die Kollisions-Prüfung ("zwei Findings
zielen auf denselben `to`") betrifft nur `to`-Findings — `action`-Findings
haben nichts, worauf sie kollidieren könnten.
