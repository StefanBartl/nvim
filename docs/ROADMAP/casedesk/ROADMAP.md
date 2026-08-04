# casedesk — Roadmap

Feature-Ideen zu [CONCEPT.md](CONCEPT.md). Reihenfolge ≈ Nutzen/Aufwand.
Der Bestandsumbau ist abgeschlossen: [MIGRATION.md](MIGRATION.md).

---

## v1 — Scaffolding ✅ implementiert

- [x] `:Case new` — Prompt-Kette (Nr, Titel, Company, Name) → Ordner + Dateien
- [x] Nur die **kurze** Nummer wird gespeichert; `SAP0000{short}{jahr}` abgeleitet
- [x] Level-1-Headline zentral in `apply.lua`, nicht in Templates
- [x] Dry-Run-Plan im `kit.viewer` + `kit.confirm` vor dem Schreiben
- [x] `.case.json` als Sidecar
- [x] Nie überschreiben — vorhandene Datei = übersprungene Aktion im Plan

## v2 — Nachschlagen & Navigieren ✅ implementiert

- [x] `CASE`-Argtyp: Completion über alle Case-Nummern, volle SNOW-Nr wird normalisiert
- [x] `:Case info [nr]` — Kurz-Infokarte, editierbar als `kit.form`
- [x] `detect.lua` — Auto-Befüllung aus H1, `Dear <X>,` und Links
- [x] Generierte Datei-Verben aus `key` im Blueprint: `:Case summary|research|reply [nr]`
- [x] `:Case open [nr]`, `:Case add`, `:Case copy`, `:Case sync`
- [x] `:Case snow [nr]` — Ticket-ID (URL sobald `snow_url_format` gesetzt ist)

## v3 — Flache Struktur ✅ implementiert (MIGRATION.md)

- [x] `config.states = { "Open", "Closed", "Reassigned" }`, Zustand = Ordner
- [x] `status` nicht in `.case.json` — wird aus dem Ordner abgeleitet
- [x] `registry.lua` auf drei flache Ordner vereinfacht
- [x] `migrate.lua`: Plan/Run/Cleanup, gegen Sandbox getestet, dann real ausgeführt
- [x] Echter Umzug: 20/20 Cases, Company aus Alt-Pfaden gerettet, 0 Fehler
- [x] `:Case close` / `:Case reassign` — generisch aus `config.states` erzeugt
- [x] Templates als echte Dateien mit Tag (`templates.lua` + `templates/*.md`)

## v4 — `:Cases` Querschnitt ✅ Basis implementiert

- [x] `:Cases` als zweites Verb, generischer Feld-Filter aus `infocard_fields`
- [x] `:Cases company Scan` — Substring, case-insensitive
- [x] Leeres Pattern = „Feld gesetzt"
- [x] `:Cases list` — gruppiert nach Zustand
- [x] Ein Treffer öffnet direkt, mehrere gehen in den Picker
- [ ] `--exact` / `--re` als Flags
- [ ] `key=value`-Kombination (`:Cases company Scan year 2026`) via `ctx.kv`
- [ ] `:Cases recent` / `grep` / `stats`

## v5 — Picker-Übersicht (CONCEPT §-Nachfolger)

- [ ] `:Cases pickers` — `kit.menu` als Entdeckungsoberfläche
- [ ] Backend-Kaskade `pickers.nvim` → `snacks.picker` → `kit.select`
- [ ] Anhänge-Picker (PNG/log/txt/PDF in `Ressources/`), nach Typ
- [ ] Links-Picker pro Case → `open.nvim`
- [ ] „Cases ohne `.case.json`"

## v6 — Aufräumen (Bestands-Inkonsistenzen, unabhängig von der Struktur-Migration)

- [ ] `:Cases doctor` — reiner Bericht, jederzeit gefahrlos
- [ ] `:Cases normalize` — Plan/Dry-Run/Confirm, Aktionstyp `rename`
- [ ] Case-Notiz vereinheitlichen (`Summary.md` vs. `ProblemSummary`/`WorkNote`/`CaseNote`/`TillNow`)
- [ ] `Research.md` → `Research/00_Research.md`; `Solution`-Schreibweisen
- [ ] Zwei Tippfehler-Dateinamen (`00_Initital.md`, `00_RequestInfrmations.md`)
- [ ] `NN_`-Präfix erzwingen — Suffix ausdrücklich **nicht**

## v7 — Komfort

- [ ] Clipboard-Node: Activity-Stream aus SNOW direkt als `Research/01_ActivityStream.md`
- [ ] Statusline-Badge: aktueller Case + Company + offene Replies
- [ ] Case-Templates pro Company (jetzt als Feld, nicht als Ordner)
- [ ] Infokarte: Feld `Priority` / `Tosca-Version` (eine Zeile `infocard_fields`)
- [ ] `:Cases stale 7` — offen und seit 7 Tagen nicht angefasst
- [ ] Link-Check: melden, wenn ein `docs.tricentis.com`-Link tot ist
- [ ] `:Case add reply` — Namen beim Anlegen überschreibbar (`00_AskForPDF.md`)

## v8 — Weiter gedacht

- [ ] Dashboard beim Start: offene Cases nach Liegezeit
- [ ] "Ähnliche Cases" beim Anlegen vorschlagen
- [ ] Company-Historie: "was hatten wir mit Scania schon"
- [ ] Reply-Gate vor dem Versand (Emojis raus, Grammatik, Links leben)
- [ ] Terminologie-Sammler: verstreute `Terminologie.md` → `Terminologie/`
- [ ] `:Cases export <nr>` — Case als ein PDF bündeln (`pdfport.nvim`)
- [ ] Zeitachse pro Case aus mtime, ohne separates Logbuch
- [ ] Templates aus den vorhandenen `Summary.md`-Dateien lernen

---

## Plugin-Check — was die eigenen Plugins beisteuern könnten

Durchgegangen: alle Repos in `C:/repos/*.nvim` bzw. der Spec aus
`lua/plugins/personal/list.lua` + `source.lua`.

### Hoher Nutzen — dafür lohnt sich eine echte Integration

| Plugin              | Beitrag                                                                                                                                                   |
| ------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **language.nvim**   | Rechtschreib-/Grammatikprüfung **und** Übersetzung. Kunden-Replies sind englisch, geschrieben von einem deutschen Muttersprachler — `:Case reply check` als Pflicht-Gate vor dem Versand. |
| **emojis.nvim**     | `:Emojis remove` scope-basiert. Research-Notes und LLM-Output enthalten regelmäßig Emojis, Kunden-Replies dürfen keine haben. |
| **open.nvim**       | `:Case snow` (Ticket im Browser), Doku-Links aus Replies (`docs.tricentis.com`).             |
| **pickers.nvim**    | Case-Picker statt `kit.select`, sobald die Case-Zahl weiter wächst — inkl. Preview der `.case.json`.                                                        |
| **fileops.nvim**    | Copy/Move/Rename inkl. Windows-Lock-Absicherung — `:Case copy`/`close`/`reassign` sollten darauf laufen statt eigene `uv`-Aufrufe. |
| **sessions.nvim**   | Eine Session pro Case: Case wieder aufmachen = Buffer-Layout von letzter Woche zurück. |

### Mittlerer Nutzen

**gopath.nvim** (Sprung Research ↔ Replies ↔ Ressources), **cascade.nvim**
(durch Case-Dateien zyklen), **buffer-ctx.nvim** (Case-Kontext am Buffer),
**filetree.nvim** (Case-Ordner nach `:Case new` revealen — bereits als
optionale Integration in `ui.open_dir` verdrahtet), **markdown.nvim/
mdview.nvim** (Reply-Preview), **pdfport.nvim** (Case-Export), **replacer.nvim**
(Platzhalter über einen Case ersetzen), **diff.nvim** (Reply-Drafts diffen).

### Geringer / kein Bezug

`insights.nvim`, `github_stats.nvim`, `reposcope.nvim`, `sandbox.nvim`,
`dap.nvim`, `debugging.nvim`, `lsp.nvim`, `documentation.nvim`,
`color_my_ascii.nvim`, `spotlight.nvim` (Ausnahme: Log-Highlighting für
Tosca-Logfiles in `Ressources/`, v5-Idee), `cmdlog.nvim`, `recommender.nvim`
(Ausnahme: Grundlage für "ähnliche Cases", v8).

### Abhängigkeits-Politik

casedesk hängt hart **nur** an `lib.nvim`. Jede Plugin-Integration oben ist
optional über `pcall(require, ...)` mit Fallback (siehe `ui.open_dir`'s
`filetree.nvim`-Reveal mit netrw-Fallback als Muster) — sonst wäre das Modul
auf der Workstation (remote-Modus, andere Plugin-Auswahl) kaputt.
