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

## v4 — `:Cases` Querschnitt ✅ implementiert

- [x] `:Cases` als zweites Verb, generischer Feld-Filter aus `infocard_fields`
- [x] `:Cases company Scan` — Substring, case-insensitive
- [x] Leeres Pattern = „Feld gesetzt"
- [x] `:Cases list` — gruppiert nach Zustand
- [x] Ein Treffer öffnet direkt, mehrere gehen in den Picker
- [x] `:Cases find company=Scan year=2026` — Feld-Kombination via `ctx.kv` (composer)
- [x] `:Cases recent [n]` — nach mtime der zuletzt angefassten Datei je Case
- [x] `:Cases stats` — Anzahl nach Zustand/Company/Jahr
- [x] `:Cases doctor` — Bericht (reale Zahlen: 10 Findings über 8 Cases, siehe unten)
- [x] `--exact` / `--re` als Flags — `query.lua`s `matches()`, geteilt von
      `by_field`/`by_fields`/`grep`. `--exact`/`-e`: volle Gleichheit statt
      Substring, weiterhin case-insensitive. `--re`/`-r`: `pattern` als
      Lua-Pattern — bewusst **case-sensitiv**, weil ein Klein-Schreiben des
      Patterns Klassen wie `%A`/`%D`/`%S` (Groß-/Kleinschreibung ändert die
      Bedeutung) zerstören würde. Composer-Flags auf `:Cases <field>` und
      `:Cases find` verdrahtet (`init.lua`s `MATCH_FLAGS`).
- [x] `:Cases grep <pattern> [--re|-r]` — Volltextsuche über die `.md`-Dateien
      aller Cases (Anhänge in `Ressources/` bewusst ausgeklammert, s.
      Doctor/v5), Ergebnis als `kit.viewer`-Bericht wie `doctor`/`stats`,
      bei >500 Treffern gekappt mit Hinweiszeile. Gegen den realen Bestand
      getestet: 547 Treffer für „the", 38 für `[Ee]rror` (`--re`).
- [x] `:Cases normalize` — die von `doctor` gemeldeten Abweichungen beheben

## v5 — Picker-Übersicht (CONCEPT §-Nachfolger)

- [x] `:Cases pickers` — `kit.menu` als Entdeckungsoberfläche mit drei
      Einträgen: Attachments, Links, „Cases ohne `.case.json`"
- [ ] Backend-Kaskade `pickers.nvim` → `snacks.picker` → `kit.select` —
      **zurückgestellt**: `pickers.nvim`s `actions/files.lua` erwartet ein
      internes `Source`+`engine_mod`-Objekt aus seiner eigenen
      Config-/Engine-Auflösung, keinen trivialen „Picker über diese
      Pfad-/String-Liste"-Einstieg — eine echte Integration wäre ohne
      Live-Test im echten Plugin zu riskant für einen Uncommitted-Merge.
      `:Cases pickers` läuft deshalb komplett auf `kit.select`, demselben
      Backend, das der Rest von `ui.lua` (`show_results`, `:Cases recent`,
      …) schon überall benutzt — konsistent, aber ohne die Kaskade.
- [x] Anhänge-Picker (`Ressources/`, rekursiv) — Text-Erweiterungen
      (`md`/`txt`/`log`/`json`/`csv`) im Buffer geöffnet, alles andere
      (PNG/PDF/Video/…) extern über `cross.open_default` (System-Standard-App).
      Gegen den realen Bestand getestet (u. a. 711373: 9 Dateien inkl.
      `image (28).png`; 859769: `Logs/ToscaCommander-....log` — verschachtelte
      Pfade werden relativ zu `Ressources/` korrekt angezeigt).
- [x] Links-Picker pro Case — `meta.links` falls gepflegt, sonst
      `detect.links` als Fallback; Auswahl öffnet extern über
      `cross.open_default` (Standard-Browser), fällt bei Fehlschlag auf
      Zwischenablage zurück (dasselbe Muster wie `:Case snow`). Kein
      `open.nvim` — `cross.open_default` deckt denselben Fall schon ab, eine
      zweite optionale Abhängigkeit dafür wäre unnötig.
- [x] „Cases ohne `.case.json`" — aktuell 0 im realen Bestand (alle 20
      Cases haben durch `migrate.lua` ein Sidecar bekommen).

## v6 — Aufräumen (Bestands-Inkonsistenzen, unabhängig von der Struktur-Migration)

- [x] `:Cases doctor` — reiner Bericht, `doctor.lua` (nur lesend)
      Reale Zahlen (2026-08-04, gegen den migrierten Bestand): **10 Findings
      über 8 Cases** — 4× Summary-Alias (`CaseNote.md`×1 in 711373,
      `TillNow.md`×1 in 711373, `ProblemSummary.md` in 859769 neben einem
      bestehenden `Summary.md`, `WorkNote.md` in 888622), 2× `Research.md`
      als Flat-File (977283, 996010), 1× `Solutions/` (913070), 1×
      `Solution.md` als Flat-File (968475), 2× Tippfehler (941543, 977283).
- [x] `:Cases normalize` — Plan/Dry-Run/Confirm, Aktionstyp `rename`, auf
      genau den Findings von `doctor.check()` aufbauend. Jede Finding trägt
      jetzt ein sicheres Ziel `to` (oder `nil` bei Mehrdeutigkeit, z. B.
      Zieldatei existiert schon). `normalize.plan()` erkennt zusätzlich
      Ziel-Kollisionen zwischen zwei Findings desselben Cases (z. B. 711373:
      `CaseNote.md` UND `TillNow.md` gleichzeitig vorhanden, beide würden
      auf `Summary.md` zeigen) und stuft dann beide als mehrdeutig zurück,
      statt eines beim Anwenden das andere stillschweigend zu überschreiben.
      Anfangs 8 von 10 Findings automatisch normalisierbar, die 2 aus
      711373 blieben mehrdeutig (`CaseNote.md`/`TillNow.md`, beide hätten
      auf `Summary.md` gezeigt) — von Hand entschieden (MIGRATION.md):
      `TillNow.md` → `Summary.md`, `CaseNote.md` → `Notes.md`.
- [x] `NN_`-Präfix erzwingen — Suffix ausdrücklich **nicht**. Neuer
      Finding-Typ `missing-nn-prefix` in `doctor.lua`, nur für direkte
      Dateien in `Research/`/`Replies/` (nicht `Ressources/` — Anhänge
      behalten ihren Namen). Nummern werden fortlaufend ab dem höchsten
      bereits vergebenen `NN_` vergeben (alphabetisch unter den
      unpräfigierten Dateien derselben Fund-Runde), dasselbe „scan +
      max+1"-Prinzip wie `:Case add reply`. `normalize.lua` brauchte dafür
      **keine** Änderung — läuft rein über `from`/`to` der Findings, inkl.
      der schon vorhandenen Kollisions-Absicherung.
- [x] **`:Cases normalize` real gegen den Bestand ausgeführt (2026-08-05)**
      — 22 Findings insgesamt (10 aus v6 + 12 `NN_`-Präfix), 20 automatisch,
      2 (711373) von Hand wie oben. Zwei Durchgänge: der erste (20 Renames)
      erzeugte durch seinen eigenen `Research.md`→`Research/Research.md`-Schritt
      (977283, 996010) selbst eine neue `NN_`-Abweichung — vom zweiten
      Durchgang (2 Renames) aufgefangen. `doctor.check()` meldet danach
      **0 Findings**. Details: MIGRATION.md.

## v7 — Komfort ✅ implementiert

- [x] Clipboard-Node: Activity-Stream aus SNOW direkt als `Research/NN_ActivityStream.md`
      — `:Case activity [nr]` liest `vim.fn.getreg("+")`, schreibt mit
      Standard-Headline und automatischer `NN_`-Nummerierung
      (`next_nn_prefix()`, jetzt geteilt mit `:Case add reply`, s. u.).
      Isoliert gegen ein Scratch-Verzeichnis getestet (nicht den echten
      Bestand): Inhalt landet byte-exakt in der neuen Datei.
- [x] Statusline-Badge: aktueller Case + Company + Anzahl Replies —
      `lua/wkdnvchad/ui/statusline/modules/casedesk/init.lua`, verdrahtet in
      `custom.lua` (`order`/`modules`, wiederverwendete Highlight-Gruppe
      `St_Lsp`, keine neue Theme-Farbe). Nach Buffername gecacht wie
      `plugin_summary` — kein `.case.json`-Read/Directory-Scan bei jedem
      Redraw, nur beim Buffer-Wechsel. Getestet: innerhalb eines
      Case-Ordners `"1007631 · 0 replies"`, außerhalb leerer String.
- [x] Case-Templates pro Company (jetzt als Feld, nicht als Ordner) —
      `config.company_blueprints` (Company-Name → Blueprint-Key), von
      `:Case new` vor dem Fallback auf `default_blueprint` konsultiert.
      Bewusst leer: kein Case braucht bisher ein anderes Blueprint, ein
      neues ist ab jetzt `M.blueprints.<name>` + eine Zeile in
      `company_blueprints`, kein Code.
- [x] Infokarte: Feld `Priority` / `Tosca-Version` — beide in
      `infocard_fields` (macht automatisch `:Cases priority`/
      `:Cases tosca_version` als Filter-Routen), plus manuell in
      `infocard_lines`/`edit_info`s `kit.form` ergänzt (die Anzeige/Edit-Form
      ist nicht generisch über `infocard_fields`, anders als die Filter-Routen).
- [x] `:Cases stale [days]` (Default 7) — offene Cases seit `days` Tagen
      nicht angefasst (`detect.last_touched`), älteste zuerst. Gegen den
      realen Bestand getestet: **7 stale Cases bei 7 Tagen** (933790: 19
      Tage, 968475: 18, 904938: 15, 977283: 13, 859769: 11, …).
- [x] Link-Check: `linkcheck.lua`, `lib.nvim.net.curl.fetch_raw` (HEAD,
      max. 4 gleichzeitig, 5 s Timeout), bewusst nur `docs.tricentis.com`
      (die Doku-Seiten, die tatsächlich verschoben/entfernt werden — nicht
      jeder Link, den ein Case zufällig erwähnt). 401/403/405 zählen
      **nicht** als tot (Auth-Wall bzw. HEAD nicht erlaubt, Seite existiert).
      `:Cases linkcheck [nr]`. **Test-Hinweis**: der `ok=false`-Pfad
      (Netzwerkfehler → „dead") ist headless bestätigt; der `alive`-Pfad
      (echtes 200) ließ sich in dieser Sandbox nicht sauber gegenprüfen —
      `vim.system`-Aufrufe über `lib.nvim.net.curl` liefen in denselben
      Requests konsequent in einen Timeout, während dieselbe URL per rohem
      `curl` (Git-Bash **und** natives `C:\Windows\System32\curl.exe`)
      sofort mit `200` antwortete. Deckt sich mit dem seit dieser Session
      wiederkehrenden `runtime-analysis.nvim`-Stack-Overflow-Bug (unabhängig
      von diesem Feature) — vor dem ersten echten Einsatz im Alltag einmal
      gegenprüfen.
- [x] `:Case add reply [suffix]` — Namen beim Anlegen überschreibbar
      (`:Case add reply AskForPDF` → `NN_AskForPDF.md`, ohne Argument weiter
      `NN_Reply.md`). Isoliert getestet: `00_AskForPDF.md` dann `01_Reply.md`
      — Nummerierung korrekt fortlaufend, keine Kollision.

## v8 — Weiter gedacht

- [ ] Dashboard beim Start: offene Cases nach Liegezeit
- [ ] "Ähnliche Cases" beim Anlegen vorschlagen
- [ ] Company-Historie: "was hatten wir mit Scania schon"
- [ ] Reply-Gate vor dem Versand (Emojis raus, Grammatik, Links leben, keine markdown headlines (`##`))
- [ ] Terminologie-Sammler: verstreute `Terminologie.md` → `Terminologie/`; Terminologie könnte ein wissespeicher werden, der mit einen picker dursuchbar ist: also das man hgezielt die einträge in allen Terminologie.md files innerhalb des repos zusammenholt und mit picker durchsuchbar macht. `:Cases terminology` bzw `:Cases pickers terminology` beide sollten gehen.
- [ ] `:Cases export <nr>` — Case als ein PDF bündeln (`pdfport.nvim`)
- [ ] Zeitachse pro Case aus mtime, ohne separates Logbuch; Das wäre super cool, wenn ich sowas wie eine aufzeichnug hötte, wie lange ich und wann buffers innerhalb eines cases foksuiert hatte

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
