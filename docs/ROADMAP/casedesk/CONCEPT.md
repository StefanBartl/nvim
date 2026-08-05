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
darauf verlinkte). `:Case close` ist damit ein reiner `fs_rename`.

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
`:Case reassign [nr]` — beide rufen denselben `ui.move_state(case, state)`
auf. Ein vierter Zustand ist eine Zeile in dieser Liste, kein neuer Code-Pfad.

---

## 4. Modulaufbau

```
lua/bindings/usrcmds/case/
  init.lua        enable() → CASE-Argtyp, :Case-Verb, :Cases-Verb
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
  doctor.lua      Bestands-Bericht (Findings mit sicherem Rename-Ziel), rein lesend
  normalize.lua   Fix-Teil zu doctor.lua — Plan/Dry-Run/Confirm/Apply
  linkcheck.lua   docs.tricentis.com-Links prüfen (lib.nvim.net.curl, async)
  migrate.lua     einmaliger Umzug von der alten Struktur (siehe MIGRATION.md)
  ui.lua          kit.form / kit.select / kit.viewer / kit.confirm / kit.menu-Verdrahtung
```

Statusline-Badge (aktueller Case, ROADMAP.md v7) liegt bewusst außerhalb
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
| `:Case similar [nr] [n]`    | ähnliche Cases per TF-IDF über Titel + `Summary.md`/`Notes.md` |
| `:Case copy <src>`          | Datei in den Case kopieren, Zielordner per Auswahl                  |
| `:Case sync [nr]`           | fehlende Blueprint-Teile nachziehen (nie überschreiben)              |
| `:Case close [nr]`          | generiert aus `config.states` — nach `Closed/` verschieben           |
| `:Case reassign [nr]`       | generiert aus `config.states` — nach `Reassigned/` verschieben       |
| `:Case snow [nr]`           | Ticket-ID öffnen (falls `snow_url_format` gesetzt) oder kopieren     |

### `:Cases` — der Querschnitt

| Command                  | Wirkung                                                    |
| ------------------------- | ------------------------------------------------------------ |
| `:Cases list`             | alle Cases, gruppiert nach Zustand                            |
| `:Cases company [pattern] [--exact\|-e] [--re\|-r]` | Substring (Default), volle Gleichheit oder Lua-Pattern; leer = "Company ist gesetzt" |
| `:Cases title/name/notes/priority/tosca_version [pattern] [--exact\|-e] [--re\|-r]` | dieselbe generische Filter-Route, ein Feld pro Zeile in `config.infocard_fields` |
| `:Cases find company=Scan year=2026 [--exact\|-e] [--re\|-r]` | Feld-Kombination via composer `kv` (bare `key=value`, kein `--`) |
| `:Cases grep <pattern> [--re\|-r]` | Volltextsuche über alle `.md`-Dateien aller Cases              |
| `:Cases recent [n]`       | die `n` (Default 10) zuletzt angefassten Cases, neueste zuerst |
| `:Cases stale [days]`     | offene Cases seit `days` (Default 7) Tagen nicht angefasst, älteste zuerst |
| `:Cases stats`            | Anzahl nach Zustand / Company / Jahr                          |
| `:Cases doctor`           | Bestands-Bericht, rein lesend (`doctor.lua`, §10)              |
| `:Cases normalize`        | behebt die von `doctor` gemeldeten Abweichungen (Dry-Run + Confirm) |
| `:Cases linkcheck [nr]`   | prüft `docs.tricentis.com`-Links auf tote Seiten (`linkcheck.lua`) |
| `:Cases pickers`          | `kit.menu`: Attachments / Links / Cases ohne `.case.json`      |

Ein Treffer öffnet direkt die Infokarte, mehrere gehen in `kit.select`.

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

## 9. Was aus lib.nvim benutzt wird

`ui.kit` (`form`/`select`/`viewer`/`confirm`/`input`/`menu`) für jede
Interaktion, `usercmd.composer` für `:Case`/`:Cases` inkl. `CASE`-Argtyp,
Flags und generierter Routen, `fs.mkdirp`/`write.to_file`/`read`/`json`/
`collect_recursive` fürs Dateisystem, `cross.open_default`/
`copy_to_clipboard` für `:Case snow` und die Attachment-/Links-Picker,
`net.curl` für `:Cases linkcheck` (einziges Modul hier mit echtem
Netzwerk-I/O — bewusst über den vorhandenen `vim.system`-Wrapper statt
eigenem Shell-Aufruf). Nichts davon shellt direkt aus — funktioniert
unabhängig vom Plugin-Modus (lokal/remote).

Optionale Integration über `pcall(require, …)`: `filetree.nvim` für
`:Case open`s Reveal (Fallback: netrw).

---

## 10. `:Cases doctor` (`doctor.lua`)

Reiner Bericht — liest, schreibt nie. `M.check()` scannt jeden Case auf fünf
Muster: Case-Notiz unter einem der vier bekannten Alias-Namen statt
`Summary.md`, `Research.md` als Flat-File statt `Research/`-Ordner,
`Solutions/`(Plural)/`Solution.md` statt `Solution/`, zwei bekannte
Tippfehler-Dateinamen (alle vier: MIGRATION.md §4), und fehlender
`NN_`-Präfix auf Dateien direkt in `Research/`/`Replies/`. `M.describe()`
rendert die Liste für `kit.viewer`.

Gegen den migrierten Bestand am 2026-08-04: **22 Findings über 8 Cases**
(genaue Aufschlüsselung in [ROADMAP.md](ROADMAP.md) v6) — die ersten 10
decken sich exakt mit der Analyse aus MIGRATION.md §4, die restlichen 12
kamen mit dem `NN_`-Präfix-Check dazu.

`:Cases normalize` (`normalize.lua`) ist der Fix-Teil und baut auf genau
diesen `DoctorFinding`-Einträgen auf — derselbe Plan → Dry-Run → Confirm → Apply-
Pfad wie `:Case new`, nur mit `rename` als Aktionstyp statt `write`.
