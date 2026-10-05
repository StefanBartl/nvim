# Handover - Task-System: Erledigen-Kette, Schätzung, Akteur, `tasks.nvim`

> **Stand 2026-10-05.** Implementierungsplan für sechs Wünsche zum Tasks-Modul der nvim-config
> (`lua/tasks/`, Frontends in `lua/bindings/usrcmds/plugin_repos/tasks_*.lua`). **Nichts davon ist gebaut**;
> dieses Dokument ist die Planung. Es ergänzt, ersetzt nicht:
>
> - [Task-System_HANDOVER.md](Task-System_HANDOVER.md) - was am Task-System noch offen ist (Phasen 0-5 sind fertig),
> - [Task-Plan-Konzept-2026-10-05.md](../reports/Task-Plan-Konzept-2026-10-05.md) - die Phasen A-E des gezogenen Plans (R13-R18, PQ1-PQ11),
> - [Task-Plan-Workflow-2026-10-05.md](../reports/Task-Plan-Workflow-2026-10-05.md) - Szenarien dazu,
> - `lua/tasks/README.md` - die Engine, wie sie heute ist.
>
> Die neun Plan-Tasks (`nvim-config/tasks-plan-engine` bis `tasks-plan-ai-triage`) existieren bereits im Vault; diese
> Runde hängt sich an sie an, statt eine zweite Planwelt zu bauen.

## Inhalt

1. [Kurzfassung und Reihenfolge](#1-kurzfassung-und-reihenfolge)
2. [Ausgangslage - was schon da ist](#2-ausgangslage---was-schon-da-ist)
3. [Wunsch 1: Erledigt wirkt auch in Plänen](#3-wunsch-1-erledigt-wirkt-auch-in-plänen)
4. [Wunsch 2: Popup mit der nächsten Task](#4-wunsch-2-popup-mit-der-nächsten-task)
5. [Wunsch 3: Aufwand und Nutzen, Summen je Plan](#5-wunsch-3-aufwand-und-nutzen-summen-je-plan)
6. [Wunsch 4: Akteur - CDX oder nur ich](#6-wunsch-4-akteur---cdx-oder-nur-ich)
7. [Wunsch 5: Ideensammlung](#7-wunsch-5-ideensammlung)
8. [Wunsch 6: Auslagerung zu `tasks.nvim`](#8-wunsch-6-auslagerung-zu-tasksnvim)
9. [Kreuzfeatures-Check über die Plugins](#9-kreuzfeatures-check-über-die-plugins)
10. [Task-Zuschnitt und Wellen](#10-task-zuschnitt-und-wellen)
11. [Entscheidungen (D1-D9)](#11-entscheidungen-d1-d9)
12. [Risiken, Verifikation, Arbeitsregeln](#12-risiken-verifikation-arbeitsregeln)

---

## 1. Kurzfassung und Reihenfolge

| # | Wunsch | Kern der Lösung | Hängt an |
|---|---|---|---|
| 1 | Erledigt wirkt auch in Plänen | **Ein** Einstieg `tasks.done_flow` statt dreier Aufrufer von `mutate.done`; er liefert ein Ergebnis mit allem, was sich durch das Erledigen geändert hat (Plan-Schritte abgehakt, Plan fertig, frei gewordene Tasks, erneuerte Marker-Blöcke) | Naht sofort; Plan-Dateien brauchen Phase C |
| 2 | Popup mit nächster Task | Reine Auswahl `tasks.next.pick` (frei gewordene zuerst, dann gleicher Plan, gleicher Bereich, Vault); der Editor zeigt ein nicht-blockierendes Popup mit "Öffnen"; leer = ehrliche Erfolgsmeldung | `plan.ready` (Phase A) |
| 3 | Aufwand/Nutzen | `effort` gibt es schon; neu `value` (1-5) und die Rechnung `tasks.estimate` (Summen, ROI, Anteil je Akteur, Fortschritt je Plan) | `value`: nichts; Plan-Summen: Phase A |
| 4 | CDX oder nur ich | **Neues Feld `actor`** (`cdx` / `me` / `pair`), orthogonal zu `category`; abgeleitet aus altem `needs-user`-Tag und `status: decision`, damit nichts migriert werden muss | nichts |
| 5 | Ideensammlung | Abschnitt 7, mit Aufwand/Nutzen in der neuen Skala (Eigentest) | - |
| 6 | `tasks.nvim` | erst in der Config entkoppeln, dann `rules.nvim`-Ruleset abarbeiten, dann Repo anlegen (**öffentlich = erst auf dein Ja**) | Wellen 1-3 empfohlen |

Reihenfolge in Wellen (jede Welle ist eine oder mehrere Runden mit **höchstens einem Agenten**):

1. **Welle 1, unabhängig, sofort:** done-Naht (Refactor ohne Verhaltensänderung), `value`-Feld, `actor`-Feld, Entkopplung für die Auslagerung.
2. **Welle 2, nach `tasks-plan-engine`:** `tasks.estimate` mit Plan-Summen, `tasks.next`, CLI-Verben.
3. **Welle 3, nach Phase C:** Popup im Editor, Kette in Plan-Dateien und Marker-Blöcke.
4. **Welle 4:** Ruleset-Gate, Repo anlegen, Umzug, Shim.

Warum so: Welle 1 bringt sofort Wert (`value`, `actor` sind reine Felder), und die Naht in Welle 1 verhindert, dass
Wunsch 1 und 2 später dreimal gebaut werden müssen. Die Auslagerung kommt zuletzt, weil die Engine UI-frei ist: alle
Features der Wellen 1-3 liegen in `lua/tasks/` und ziehen kostenlos mit; nur die Editor-Teile (Popup, Dashboard) sind
Frontend und werden beim Umzug ohnehin neu verdrahtet.

## 2. Ausgangslage - was schon da ist

Geprüft am 2026-10-05 im Quelltext, nicht aus der Erinnerung:

- **`done` hat drei Aufrufer**, die alle `mutate.done` direkt nutzen: der Editor-Befehl (`tasks_cmd.lua`, `finish_task`,
  um Zeile 734), das Dashboard (`tasks_dash.lua` / `tasks_dash_core.lua`, `core.apply_done`, danach der Callback
  `after(#res.done > 0)`) und die CLI (`lua/tasks/cli.lua`, Verb `done`). Heute geben alle drei nur "done X -> Pfad" aus.
  Genau hier setzen Wunsch 1 und 2 an, deshalb braucht es **eine** Stelle.
- **`mutate.done` ist schon rückrollbar** (`lib.nvim.checkpoint`, Datei wird vor dem Verschieben erneut geprüft). Alles,
  was die Kette an Dateien schreibt, muss denselben Weg nehmen oder getrennt und ehrlich scheitern (siehe 3.4).
- **Aufwand gibt es:** `effort: XS|S|M|L|XL|<n>d`, `model.effort_days` (XS 0,25 · S 0,5 · M 1 · L 3 · XL 5, "nur zum
  Ordnen, kein Versprechen"), Filter `--effort=<=M`, Sortierung `prio-effort`. **Nutzen fehlt.** Summen gibt es nirgends.
- **`category` ist die falsche Achse für Wunsch 4:** `bug`, `security`, `performance`, `docs`, `ruleset` sind
  Sachgebiete, mehrwertig, und die effektive Menge enthält schon jeden Tag, der wie eine Kategorie heißt
  (`model.categories`). Wer `cdx`/`me` dort einreiht, mischt "worum geht es" mit "wer macht es".
- **Der Vault hat die Achse schon als Tag, informell:** `needs-user` steht an **31** Tasks (von 469), `agent` an 13,
  `needs-live-test` an 41. Das ist der Migrationsbestand für `actor` (6.3). `status: decision` heißt immer "wartet auf dich".
- **Das Plan-Konzept ist entworfen und in Tasks zerlegt** (Phase A bis E, 9 Tasks, alle `open`/`blocked`). Es kennt
  schon: `plan.ready` als **einen** Bereitschaftsbegriff, "frei geworden" bei `done`, Plan-Dateien mit eigenem `status`
  (`planning|doing|parked|done`), Marker-Blöcke (`GENERATED:plan`), `phase`, `order`. Wunsch 1-3 setzen darauf auf.
- **Die Engine liefert Daten, keine Meldungen** (UI-frei, R12/E4). Alles Neue folgt dem: Funktionen geben Tabellen oder
  `nil, err` zurück, die Frontends entscheiden über Lautstärke. Das ist auch die Voraussetzung für Wunsch 6.
- **Der Index `ROADMAP/TASKS.md` ist eingefroren** (eine Spalte mehr macht jeden Index auf einmal `index-stale`).
  `value`, `actor`, ROI erscheinen deshalb **nicht** im Index, nur in Dashboard, Plan, CSV und Sortierungen - wie `severity`.
- **`ui.nvim` hat einen eigenen Parser** (`tasks_counter/source.lua`, liest `TASKS.md` oder die Task-Dateien selbst, ohne
  `require("tasks")`). Neue Felder brechen ihn nicht (unbekannte Keys), aber ein `ready`/`me`-Zähler wäre dort ein
  eigener Umbau (siehe Abschnitt 9, Zeile `ui.nvim`).

## 3. Wunsch 1: Erledigt wirkt auch in Plänen

> "wenn eine Task erledigt ist, dann soll dies auch in Plänen automatisch erledigt sein"

### 3.1 Was "Plan" hier heißt - drei Dinge

| Ding | Wo es steht | Was "automatisch erledigt" bedeutet |
|---|---|---|
| **Gezogener Plan** (`task plan`) | wird berechnet, steht nirgends | nichts zu tun - ein erledigter Task ist beim nächsten Ziehen weg, seine Nachfolger sind frei. **Gratis**, solange R14 gilt |
| **Schritte im Task** (`## Plan`, `- [ ] 1. ...`) | im Body der Task-Datei (Phase B) | beim Erledigen werden offene Schritte abgehakt (3.3 a) |
| **Plan-Datei** (`ROADMAP/plans/<slug>.md`, Phase C) und **Marker-Blöcke** in handgeschriebenen Dokumenten | eigene Datei / Block in `IMPLEMENTIERUNGSPLAN.md` | der Plan geht auf `done`, sobald kein Mitglied mehr offen ist; Marker-Blöcke werden neu gezogen (3.3 b, c) |

Der wichtigste Satz: **Je mehr ein Plan berechnet wird, desto weniger muss "automatisch erledigt" werden.** Die Kette
betrifft nur die drei gespeicherten Artefakte der rechten Spalte. Deshalb ist der Wunsch klein, solange man Pläne nicht
von Hand pflegt (R14). Handgeschriebene Plan-Dokumente (`IMPLEMENTIERUNGSPLAN.md` je Plugin) werden erst über Marker-Blöcke
erreichbar; bis dahin altert dort die Handschrift weiter (D7: kein Abhaken per Textsuche nach Task-Ids).

### 3.2 Die Naht: `tasks.done_flow`

Neues Modul `lua/tasks/done_flow.lua` (rein, UI-frei):

```lua
---@param id string
---@param opts { done_in?: string, date?: string, chain?: boolean }  -- chain default true
---@return Tasks.DoneFlow|nil res, string|nil err
function M.run(id, opts) end
```

`Tasks.DoneFlow` = `{ done = <Ergebnis von mutate.done>, steps_ticked = n, freed = {id...}, plans_closed = {id...},
docs_refreshed = {pfad...}, notes = {string...}, next = Tasks.NextPick|nil }`.

- Alle drei Aufrufer (Editor-Befehl, Dashboard-`apply_done`, CLI) rufen **nur noch** `done_flow.run`. Das ist Schritt 1
  und **ändert kein Verhalten** (`chain = false`-gleich): erst die Naht, dann die Kette. Regression-Spec: die
  bestehenden `tasks_mutate*`/`tasks_dash*`/`tasks_cli`-Specs bleiben unverändert grün.
- `res.done.already` (zweiter Aufruf) läuft **nicht** durch die Kette: ein bereits erledigter Task ändert nichts.
- Ein Fehler **nach** erfolgreichem `mutate.done` macht das Erledigen **nie** rückgängig; er landet in `notes` (der Task
  ist fertig, die Kette hat einen Schritt nicht geschafft - das ist die ehrliche Meldung, nicht ein halber Rollback).

### 3.3 Die Kette (jeder Schritt unabhängig, jeder berichtet)

a. **Eigene Schritte abhaken (Phase B, `## Plan`).** Alle `- [ ]` im Plan-Abschnitt werden `- [x]`. Ausnahme-Vorschlag:
   ein Schritt mit dem Zusatz `(entfällt)` bleibt unberührt. Geschrieben **als Teil des `done`-Schreibens** (Textumformung
   vor dem Schreiben der Backlog-Kopie), damit das vorhandene Checkpoint-Rollback sie abdeckt. Voraussetzung:
   `tasks-task-plan-section`. Vorher: Schritt entfällt, kein Befund.
b. **Plan-Datei (Phase C).** Tasks tragen `plan: <id>`. Nach dem Erledigen: gibt es noch ein offenes Mitglied? Nein ->
   Plan `status: done`, Datei nach `Backlog/` (R6 sinngemäß), Bericht `plans_closed`. Ja -> nur der Fortschritt ändert sich
   (abgeleitet, wird nicht gespeichert). `plan.status: planning` -> `doing` beim ersten Mitglied auf `doing` ist ein
   **Folgepunkt** (Idee, nicht Teil hiervon).
c. **Marker-Blöcke.** Dokumente, die `<!-- GENERATED:plan scope=... -->` tragen, werden neu gezogen - **nur** die in der
   Config genannten (`chain.marker_docs = { "<pfad>", ... }`, Standard leer). Kein Scannen der Platte, kein Stolpern über
   fremde Dateien. Nicht Teil von `check`/CI (PQ5).
d. **Frei geworden.** `freed` = Tasks, deren letzter offener Blocker der gerade erledigte war (Phase A,
   `tasks-plan-cli`). Der Status wird **nie ungefragt** geändert (PQ2); die Frontends bieten `blocked -> open` an.
e. **Nächste Task** (Wunsch 2): `res.next = tasks.next.pick(...)`.

### 3.4 Atomik und Reihenfolge

Der Plan-Zustand wird aus Dateien abgeleitet, also ist die Reihenfolge wichtig: **erst** `mutate.done` (die Wahrheit
ändert sich), **dann** a (Teil davon), b, c, d, e (alles *Folgen* der neuen Wahrheit, jeder darf einzeln scheitern).
Schreibende Schritte (b, c) laufen über `fsio.write_atomic` mit vorherigem Snapshot (`lib.nvim.checkpoint`) und prüfen
vor dem Schreiben, ob sich die Zieldatei seit dem Lesen geändert hat (derselbe Schutz wie in `done`, Review-Befund
2026-10-05). Eine Plan-Datei, die sich währenddessen änderte, wird nicht überschrieben, sondern in `notes` gemeldet.

### 3.5 Konzept-Nachzug

`Task-Plan-Konzept` §15 sagt "keine automatische Änderung von Prio oder Status ohne Rückfrage". Wunsch 1 ist eine
bewusste Ausnahme für **abgeleitete** Zustände (Plan-Schritte und Plan-Status folgen den Tasks); Prio und der Status
*anderer* Tasks bleiben Handarbeit. Beim Bau den Satz im Konzept anpassen (D3).

### 3.6 Umgekehrte Richtung (Kreuzfeature, klein)

Wird der **letzte** Schritt eines `## Plan` abgehakt (Markdown-Checkbox, `markdown.nvim`-Toggle), fragt das Task-Buffer:
"Alle Schritte erledigt - Task abschließen?" Dasselbe Popup wie bei `:MyPlugins task done`. Hört auf
`TextChanged` nur in Task-Buffern (`tasks_view`). Aufwand S, Nutzen 3; erst nach Wunsch 1.

## 4. Wunsch 2: Popup mit der nächsten Task

> "wenn man eine Task auf erledigt setzt, dann ein kleines Popup, das auf die nächste offene Task aufmerksam macht und
> ob man da gleich reinspringen will - bzw. wenn nichts offen, eine kleine Erfolgsmeldung"

### 4.1 Auswahl (rein): `tasks.next.pick(done_task, ctx)`

Kandidaten = **bereite** Tasks (`plan.ready`: Status `open`/`doing`/`decision`, kein offener harter Blocker). Der
Bereitschaftsbegriff kommt ausschließlich aus `plan.ready` - keine zweite Auslegung hier (Konzept §9, Risiken). Deshalb
ist `tasks.next` **von `tasks-plan-engine` abhängig**; ein Vorabstand mit eigener Prüfung ist verboten (er würde die Zählung
des Dashboards ein drittes Mal anders deuten).

Rangfolge (feste, dokumentierte Reihenfolge, wie die Tiebreaker in Konzept §6.2):

1. **frei geworden** durch diesen Task (`freed`) - das ist die natürliche Fortsetzung
2. **gleicher Plan** (`plan:`), dann **gleicher Bereich**, dann **Vault**
3. Status: `doing` vor `open` vor `decision`
4. **Akteur-Passung** (Wunsch 4): für das Popup zuerst `me`/`pair`/unbestimmt - das Popup spricht den Nutzer an;
   `cdx`-Tasks erscheinen getrennt als Hinweis ("CDX könnte gleich: ...", 6.4), nicht als "nächste Aufgabe für dich"
5. effektive Prio, dann **ROI** (Wunsch 3), dann Aufwand aufsteigend, dann Slug

Ergebnis: `{ task, reason = "freed"|"plan"|"area"|"vault", alternatives = {t2, t3}, cdx = {t...}, scope_left = {...} }`.
Alles in einer Tabelle, damit CLI (`next:`-Zeile), Popup und Dashboard dieselbe Antwort sehen.

### 4.2 Popup (Editor, `tasks_cmd.lua` + Dashboard-Callback)

- **Nicht-blockierend**, kleines Float am Rand, **kein Fokusraub**: `<CR>` springt zur Task (Datei öffnen, Frecency
  zählen wie im Dashboard), `n` zeigt die nächste Alternative, `q`/`<Esc>` schließt. Kein Timer als Standard.
  Aufbau über `ui.kit` bzw. die vorhandene `confirm`-Abstraktion; **die Schnittstelle vorher lesen** (`confirm.yesno` kann
  nur ja/nein; drei Tasten brauchen die Float-Variante des Kits oder `lib.nvim.ui`).
- Inhalt (drei Zeilen): "Erledigt: `<id>` · frei geworden: a, b" / "Als Nächstes: `<id>` - Titel (P2 · S · Nutzen 4)" /
  "Grund: frei geworden | gleicher Plan | ...". Ein erledigter Task, der einen Plan **abschließt**, bekommt die Überschrift
  "Plan `<id>` fertig" (3.3 b).
- **Dashboard-Stapel:** mehrere Tasks auf einmal erledigt (`D`) -> **ein** Popup nach dem Stapel (der bestehende
  `after(#res.done > 0)`-Haken), mit dem Ergebnis des letzten Tasks, nicht n Popups.
- **CLI/headless:** kein Popup; eine Zeile `next: <id>\t<title>` und `freed: ...` auf stdout; `--no-next` schaltet ab.
- **Konfiguration:** `tasks.next = { popup = true, scope_order = { "freed", "plan", "area", "vault" }, cdx_hint = true }`.
  `--yes` (Befehl ohne Rückfrage) unterdrückt das Popup **nicht**: es ist eine Anzeige, keine Rückfrage.

### 4.3 Der leere Fall - ehrlich, nicht gefeiert

"Nichts offen" ist mehrdeutig; das Popup unterscheidet, statt blind zu jubeln:

| Lage | Meldung |
|---|---|
| Plan gerade fertig | "Plan `<id>` abgeschlossen: 12 Tasks, Richtwert 9,5 d, erledigt in 14 Tagen" (aus `created`/`done`-Datum, Aufwand aus 5) |
| Bereich leer | "Keine offene Task mehr in `<area>`" |
| Vault ohne **bereite** Tasks, aber Offenes | "Nichts mehr startbar. Es warten noch: 4 auf dich (decision/me), 6 blockiert, 3 geparkt" - **nie** "alles erledigt", wenn nur Wartendes bleibt |
| wirklich nichts offen | "Alles erledigt." |

Der dritte Fall ist der häufigste und der, bei dem eine Erfolgsmeldung lügen würde.

### 4.4 Spec

Pure Auswahl mit Fixture-Vault (frei geworden gewinnt, Plan vor Bereich, `decision` zuletzt, Akteur-Trennung, leere
Fälle alle vier); Popup im Editor headless über den Kern (wie `tasks_dash_spec.lua`: Zustand testen, Float nur im echten
Picker-Lauf); Stapel-Fall mit zwei erledigten Tasks = ein Popup.

## 5. Wunsch 3: Aufwand und Nutzen, Summen je Plan

> "Aufwand-Schätzung / Nutzen-Schätzung in den Tasks implementieren + wenn man einen Plan hat, kann es daraus für den
> Plan errechnen"

### 5.1 Felder

| Feld | Wert | Status |
|---|---|---|
| `effort` | `XS S M L XL` oder `0.5d`, `3d` | **besteht** (Skala in `model.lua`: 0,25/0,5/1/3/5 Tage) |
| `value` | ganze Zahl **1-5** (5 = größter Nutzen) | **neu**, optional, in `mutate.SETTABLE`, `new --value=`, `set value=`, `check`: `bad-value` (Fehler) |

Warum Zahlen und keine T-Shirt-Wörter: `S`/`M` stünden sonst für Aufwand *und* Nutzen und würden verwechselt; und eine
Zahl rechnet direkt. **`value` ist nicht `prio`:** `prio` ist die Reihenfolge-Entscheidung (Dringlichkeit, vom Menschen
gesetzt), `value` der **erwartete Nutzen**, unabhängig von der Zeit. Beides darf auseinanderfallen (hoher Nutzen, aber
gerade nicht dringend). Steht beides in der Doku, ist der Streit zwischen "zwei Wichtigkeitsfeldern" entschärft (D2).

**Abgeleitet, nie gespeichert:** `roi = value / max(effort_days, 0.25)`. Ein Task ohne Aufwand oder ohne Nutzen hat **kein**
ROI (nicht 0, nicht geschätzt) und bleibt in jeder Ansicht sichtbar, in einer Gruppe "ungeschätzt".

### 5.2 Rechnung: `tasks.estimate` (rein)

`estimate.rollup(tasks, scope_opts)` liefert für einen Umfang (Bereich, `--plan=`, `--for=`, Filter - dieselben Umfänge wie
`task plan`):

- `effort_days_known`, `n_without_effort` - die Summe nennt **immer**, wie viele Tasks fehlen ("22 d aus 17 von 20")
- `value_sum`, `n_without_value`
- `roi` (Σ Nutzen / Σ Tage über die vollständig geschätzten Tasks) und die Liste "**Quick wins**" (Nutzen ≥ 4, Aufwand ≤ S)
- Aufteilung **nach Akteur** (6): "Du: 8,5 d · CDX: 13,5 d · gemeinsam: 2 d · offen: 3 Tasks" - das beantwortet "wie viel
  Zeit muss *ich* einplanen"
- **Fortschritt:** erledigte Tasks (Backlog) mit demselben Plan zählen mit: "62 % (7,5 von 12 d)". `scan.backlog` hat
  `effort` und `plan` der erledigten Tasks.
- aus Phase A: `critical_path_days` (Aufwand-gewichtet, unverändert aus dem Plan)

Der Vorbehalt bleibt wörtlich in jeder Ausgabe: **"Richtwert (Skala, kein Versprechen)"** (Konzept PQ8). Die Summe von
T-Shirt-Größen ist grob; deshalb zusätzlich eine **Spanne** (Σ mit XS=0,15/S=0,35/M=0,7/L=2/XL=3 bis Σ mit
0,35/0,8/1,5/5/8 ist ein Vorschlag, D2b) - ohne Spanne wirkt die Zahl genauer, als sie ist.

### 5.3 Anzeige

- **Plan-Kopf** (`task plan`): "20 Tasks · Richtwert 22 d (17 von 20 geschätzt) · Nutzen 61 · ROI 2,8 · Du 8,5 d / CDX 13,5 d".
- **Dashboard:** Spalte `ROI`, Sortierschlüssel `--sort=roi`, Chip `[unestimated]`, Kopfzeile mit Σ der **gefilterten** Sicht.
- **`list --sort=roi`**, `--value=>=4`; TSV-Spalten von `list` unverändert (Skripte), neue Information nur über `--format=`.
- **CSV-Export** bekommt `value`/`roi`/`actor` am Ende (Spalten anhängen, nicht einfügen).

### 5.4 Schätz-Hilfe (klein, wichtig)

Felder, die keiner pflegt, sind wertlos. `task estimate [<area>]` geht die Tasks ohne Aufwand/Nutzen der Reihe nach durch
(Picker mit Vorschlägen `XS S M L XL` / `1-5`, ein Tastendruck je Feld, `task set` im Batch, Index je Bereich einmal).
Eine **KI-Schätzung** (`ai.nvim`) ist Phase E und kommt später; das Handwerk muss ohne KI vollständig sein (R18).
`check`-Hinweis `no-estimate` ist **opt-in** (`check --estimates`), nie ein Fehler und nie Teil von CI - ein Task ohne
Schätzung ist "ungeschätzt", nicht fehlerhaft.

## 6. Wunsch 4: Akteur - CDX oder nur ich

> "Task-Kategorien einfügen, ob die Task eine KI (CDX) oder nur ich machen kann"

### 6.1 Feld

`actor: cdx | me | pair` (optional):

- `cdx` - CDX kann sie allein (Code, Doku, Refactor, Specs, Recherche im Repo).
- `me` - nur du: Entscheidungen, Live-/GUI-Tests (z. B. `needs-live-test`), Geld/Konten/Zugänge, Force-Push,
  Veröffentlichen, Dinge außerhalb der Reichweite der Sitzung.
- `pair` - CDX entwirft, du nimmst ab oder entscheidest den Rest (Migration mit Abnahme, Entwurf + Review).
- ungesetzt - "ungeklärt" (nicht fehlerhaft; so bleibt `task new` ein Aufruf mit Titel).

Eigenes Feld statt Wert in `category` (D1): `category` ist mehrwertig und filtert nur ("Categories narrow a list"), `actor`
ist einwertig, **steuert Auswahl** (Popup, `task next`) und gehört in Summen (5.2). `ai` als Wert wird vermieden:
`ai.nvim` ist ein Bereich und das Tag `ai` steht an 11 Tasks.

### 6.2 Abgeleiteter Akteur (keine Migration nötig)

Wie bei `model.categories` ("so filterbar, ohne etwas anzufassen"): `model.actor(task)` = geschriebener Wert, sonst
`me` bei `status: decision` oder Tag `needs-user`, sonst `nil`. Die 31 `needs-user`-Tasks und alle `decision`-Tasks sind
damit sofort filterbar. Das Tag `agent` (13 Tasks) wird **nicht** automatisch gedeutet: es bezeichnet teils
"Agent-Hinweis in rules.nvim", nicht "CDX macht es" - Liste zur Durchsicht, keine Automatik.

### 6.3 Bestand überführen (optional, danach)

`task migrate-actor` (Trockenlauf Standard, `--write` schreibt): schlägt für jeden Task ohne `actor` einen Wert vor
(`needs-user`/`decision` -> `me`) und **lässt alles andere leer**. Die Rate der leeren Tasks ist die ehrliche Zahl.
Geschrieben wird über `task set` (Roundtrip, `updated`), nie per Textersetzung.

### 6.4 Nutzen im Alltag

- `list --actor=cdx` und `task next --actor=cdx --n=5`: die **CDX-Warteschlange**, `--format=ids` für Skripte,
  `--to=clipboard` als Arbeitsauftrag für eine Claude-Sitzung (Idee `task brief`, 7).
- `task next --actor=me`: "was kann nur ich, und was ist davon startbar?" - die Liste für dich, wenn CDX gerade läuft.
- Dashboard: Chip `[cdx]`/`[me]`/`[pair]`, Filter `f > actor`, Statuszeile `me:N` (9, `ui.nvim`).
- Wartende Hebel: ein `cdx`-Task, der an einer **`me`-Entscheidung** hängt, ist "wartet auf dich" - `check`-Hinweis
  `actor-cdx-waits-on-me` (Warnung) und im Plan eine eigene Zeile "CDX wartet auf: ...", sortiert nach Hebel. Das ist der
  Mehrwert gegenüber einem Etikett.
- **Leitplanke für headless Claude-Sitzungen:** `task set <id> status=doing` auf einem `actor: me`-Task gibt auf stderr
  eine Warnung aus (keine Sperre; R18: kein Befehl verweigert etwas wegen Plan-/Meta-Angaben).

### 6.5 Spec

Ableitung (Feld > `decision` > Tag > nil), Filter, Roundtrip (`set actor=` und leer löschen), `bad-actor` (Fehler),
Regression (Task ohne Feld unverändert), Index bytegleich, `migrate-actor` Trockenlauf schreibt nichts.

## 7. Wunsch 5: Ideensammlung

Aufwand und Nutzen in der neuen Skala (Einschätzung von mir, Eigentest für Wunsch 3). **Sortiert nach ROI, nicht nach
Bauchgefühl.** Keine davon ist beschlossen; angelegt wird nur, was du auswählst.

| Idee | Aufwand | Nutzen | Kurz |
|---|---|---|---|
| **Handover ziehen:** `task handover <area\|plan>` erzeugt "Nur Offenes" aus dem Vault (Marker-Block) | M | 5 | `Task-System_HANDOVER.md` ist heute handgepflegt und altert; genau R14 ("ziehen, nicht schreiben") |
| **CDX-Arbeitsauftrag:** `task brief <id>` baut den Auftrag für eine Sitzung (Titel, Kontext, Akzeptanz, `refs`-Dateien, Regel-Ids aus `rules:` mit Regeltext, Repo-Pfad, Commit-Regeln) | M | 5 | macht `actor: cdx` ausführbar; Kreuz zu `rules.nvim` (9) |
| **`task split <id>`:** Schritte aus `## Plan` mit eigenem Abnahmetest werden eigene Tasks mit Kante | S | 4 | R17 ("ein Plan-Schritt ist kein Task") als Werkzeug |
| **Abhängigkeitsgraph:** `--format=mermaid`, Vorschau über `mdview` | S | 4 | fällt aus `plan.build` heraus, fast gratis |
| **`task review`** (Wochenrückblick): geparkte, veraltete (`--stale=refs`), `needs-verification` der Reihe nach | M | 4 | die Backlog-Hygiene, die heute von Hand passiert |
| **`snooze: <datum>`** für `parked`: taucht danach in `task next` wieder auf | S | 3 | **kein** `due:` - Termine sind Nicht-Ziel des Konzepts (§15); eine Wiedervorlage ist keiner |
| **Ist-Aufwand:** `done --spent=2d`, daraus `task stats` (Schätzgenauigkeit je Größe) | M | 3 | kalibriert die Skala; nur wenn die Schätzungen (Wunsch 3) wirklich gepflegt werden |
| **WIP-Limit:** Warnung bei mehr als N Tasks auf `doing` | XS | 3 | Statuszeile oder `check`-Hinweis |
| **`task undo`** der letzten Mutation (Checkpoint liegt schon) | M | 3 | Absicherung für die neue Kette (3) |
| **Wiederkehrende Tasks:** `every: 30d` legt nach `done` einen neuen an | M | 3 | Bereinigungsarbeit (`stale-worktree-and-merged-branch-cleanup` u. ä.) |
| **Vorlagen je `kind`** (`bug` mit Repro-Abschnitt, `decision` mit Optionen) | S | 2 | `task template --kind=` gibt es, der Inhalt wäre neu |
| **JSON-Export** (`--format=json`, `tasks.api`) für CI und fremde Werkzeuge | S | 3 | Voraussetzung für ein öffentliches `tasks.nvim`, das andere anbinden |
| **Mehrere Vaults / Vault im Repo** (`.tasks/` neben dem Code) | L | 4 (für `tasks.nvim`) / 1 (für dich) | nur relevant, wenn andere das Plugin nutzen sollen (8, D6) |
| **GitHub-Issues synchronisieren** (Import/Export) | L | 2 | nur für ein öffentliches Plugin; `reposcope`/`gh` liegen nahe |

Abgelehnt, mit Grund: **Fälligkeitsdatum/Kalender** (Konzept §15, "kein Projektmanagement-Werkzeug"); **Gantt/Kanban**
(zweites Datenformat, §15); **Zeit pro Person/Kapazität** (§15).

## 8. Wunsch 6: Auslagerung zu `tasks.nvim`

> "Auslagerung zu einem eigenen Plugin: tasks.nvim erledigen -> gh repo öffentlich anlegen, rules.nvim Ruleset im
> wkdbook abarbeiten"

Die Auslagerung war von Anfang an vorgesehen (Konzept E4: "config first, plugin later"; `lua/tasks/README.md`: der
Ordner kann ohne Umbau wandern). Die Engine ist UI-frei, hat einen eigenen Namensraum und kennt `:MyPlugins` nicht.

### 8.1 Entscheidungen vor dem ersten Handgriff

- **Name des Moduls:** `tasks` oder `tasks_nvim` (D5). Das README der Engine nennt die Kollisionsregel selbst: `tasks`
  ist ein generisches Wort, ein fremdes Plugin mit `lua/tasks/` würde es verdecken; für ein **veröffentlichtes** Plugin
  ist das ein reales Risiko (`dap.nvim` -> `wkddap` ist derselbe Fall). Empfehlung: **`tasks_nvim`**, wie `fileops_nvim`,
  `diff_nvim`. Der Umbau ist billig: Aufrufe von `require("tasks.*")` stehen nur in `scripts/`, `TESTS/tasks/` und
  `plugin_repos/tasks_*.lua`. **Billiger jetzt als nach dem Veröffentlichen.**
- **`lib.nvim` bleibt harte Abhängigkeit** (Memory: bewusst; `lib.nvim.markdown.frontmatter`, `fs`, `checkpoint`,
  `harvest`, `system.env`). Die Engine funktioniert heute ohne `ui.nvim`.
- **Lizenz/README-Konvention** wie die anderen Repos: `README.md` deutsch, `doc/<name>.txt` englisch (Vimdoc),
  `docs/ROADMAP.md`, `:checkhealth`, `config/DEFAULTS.lua` + `config/init.lua`, `@types`, MIT.

### 8.2 Entkoppeln, **bevor** etwas bewegt wird (in der Config)

1. **Persönliche Vault-Voreinstellung heraus.** `vault.root()` fällt heute auf `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins`
   zurück - das ist *dein* Layout. Im Plugin: `setup({ vault = "..." })`, `$TASKS_VAULT`, sonst **klare Meldung "kein Vault
   konfiguriert"** und keine stille Annahme. Deinen Pfad setzt `lua/plugins/personal/specs/...` (oder `my.nvim`).
2. **Das Format ist festgelegt, der Ort nicht.** Ordnernamen (`ROADMAP/tasks/`, `Backlog/`, Bereichsliste mit `ALL`,
   `nvim-config`, `docmap-desktop`, `migrate.nvim` in `vault.lua`) sind teils persönlich. Die **Bereichsliste** und die
   Kinds-zu-Bucket-Zuordnung (`BUCKET_OF_KIND`) in die Config; ein Beispiel-Vault `examples/vault/` zum Ausprobieren.
3. **Frontends umsiedeln.** Aus `plugin_repos/tasks_*.lua` wird die Bedienung des Plugins mit **eigenem** Befehl
   (`:Tasks <verb>` über `lib.nvim.usercmd.composer`, wie `:Rules`); `:MyPlugins tasks|task|open` bleibt in der Config als
   dünne Weiterleitung (Abwärtskompatibilität deiner Tasten und Gewohnheiten).
4. **Dokumentationsgrenze** (Vault-Regel): Nutzerdoku (README, Verben, Format-Referenz) in das Repo; Konzept
   (`Task-System-Konzept.md`, Plan-Konzept, Entscheidungen) bleibt im Vault und wird nur verlinkt.
5. **Kopplung zu `ui.nvim`:** `tasks_counter` liest die Dateien selbst und bleibt unabhängig; kein `require("tasks")`
   in `ui.nvim`. Eine spätere API `tasks.counts()` wäre eine **optionale** Abkürzung, nie Voraussetzung.
6. **Spezielle Windows-Fallen** vorab prüfen: Namensraum-Kollision (`tasks_nvim` löst sie), lazy-Trigger nur auf `cmd`.
   Ein Release-Test auf Linux/macOS fehlt heute ganz (Handover: "Nicht getestet") - vor dem öffentlichen Repo in die CI.

### 8.3 `rules.nvim`-Ruleset abarbeiten (Voraussetzung, nicht Nachsatz)

Dein `rules.nvim` ist in der Config so verdrahtet (`lua/plugins/personal/specs/inspect.lua`, um Zeile 1437):
`rulesets = { $REPOS_DIR/WKDBooks/Development/wkdbook-Lua/Checklists }`, Gates `new_project = {"NEW"}`,
`release = {"REL"}`, `review = {"ERR","LUA","UI","CMT","SEC","PRIN","PERF"}`. Geladen sind (Stand heute, gezählt):
`NEW` 50, `REL` 34, `LUA` 61, `LLS` 37, `ERR` 35, `PERF` 70, `PRIN` 37, `SEC` 29, `UI` 42, `CMT` 16, `XP` 7, `DEP` 7, `TS` 5.

**Wichtige Lücke:** `gates/REVIEW.md` hat **0** `rule`-Blöcke. `:Rules gate review` prüft also die *Familien* (ERR, LUA, ...),
nicht den Schnell-Check der Datei; und die Familie `LLS` fehlt im Gate. Vorher klären, ob das Absicht ist (D8b), statt
ein grünes Gate zu melden, das den Schnell-Check nie gesehen hat.

Vorgehen (jeder Schritt ein Häppchen, ein Agent, Befund -> Fix -> Spec):

1. `:Rules check --family=LUA|LLS|ERR|SEC|UI|CMT|XP` auf `lua/tasks/` (nicht auf der ganzen Config - der Scan über die
   Config wäre ein Mehrstundenlauf, den das Plugin selbst ablehnt) und auf den Frontends. Jede Familie einzeln.
2. `:Rules gate new_project` gegen das **neue** Repo, sobald es existiert (NEW-01 .. NEW-50: `.luarc.json`, `TESTS/`
   mit lautem Runner, Nullmessung vor dem ersten Push - `NEW-36 .. NEW-46` sind der Teil, der sich am spätesten rächt).
3. `:Rules gate review --diff=main` vor dem Merge des Umzugs.
4. `:Rules gate release` (REL-01 .. REL-34) **vor** dem Öffentlichmachen.
5. Findings, die ein Fehler im Ruleset sind (nicht im Code), gehen als Befund an `wkdbook-Lua`, nicht als Waiver.
   Waiver nur mit Begründung, einzeln.

Dazu die Lehre aus `LLS-45/46` und `Module-Audit-Findings.md`: **vor jedem Docs/`@types`-Durchgang
`ALL/Module-Audit-Findings.md` lesen**; LuaLS-Befunde sind oft **ein** Fehler mit vielen Symptomen.

### 8.4 Repo anlegen und umziehen

**Das öffentliche Anlegen (`gh repo create StefanBartl/tasks.nvim --public`) ist eine nach außen sichtbare, schwer
zurückzunehmende Handlung. Sie geschieht erst auf dein ausdrückliches Ja im Chat, zu diesem Zeitpunkt.** Bis dahin:
Repo **privat** oder lokal anlegen und alle Schritte durchspielen. (Ein Veröffentlichen ist auch dann nicht
rückholbar, wenn man es löscht: Inhalte werden gecached und indexiert.) Im Repo darf bis dahin nichts stehen, was nicht
öffentlich sein darf - kein Vault-Inhalt, keine Kundenbezüge, keine persönlichen Pfade (`E:\repos\...`, Mail-Adressen).

Reihenfolge:

1. Lokales Repo `E:\repos\tasks.nvim` (STEVESPC; `$REPOS_DIR/tasks.nvim` auf den anderen Rechnern), Struktur nach
   `NEW_PROJECT.md` und `plugin-extraction-pattern`: `lua/tasks_nvim/`, `plugin/` (nur Befehl), `config/`, `bindings/`, `doc/`,
   `docs/`, `TESTS/`, `scripts/` (`tasks.lua`, `tasks-ci.lua`), `examples/vault/`, `.luarc.json`, `stylua.toml`, CI
   (stylua **v2.5.2**, luacheck **1.2.0**, `checkout@v5` - die Flotten-Konvention).
2. Umzug mit `git mv`-Äquivalent (Verlauf mitnehmen, wenn billig: `git filter-repo` auf `lua/tasks`, `TESTS/tasks`,
   `scripts/tasks*.lua` - **sonst** sauberer Neuanfang mit einem Verweis auf den Ursprungs-Commit im README).
3. Config verdrahten: `lua/plugins/personal/core/source.lua` (Modus `disabled|dir|remote`, Schlüssel = Repo-Basisname),
   Spec in `lua/plugins/personal/specs/<kategorie>.lua`, **alle Optionen aufgelistet** (Memory: personal specs layout),
   lazy auf `cmd`. Den alten Ordner `lua/tasks/` danach **`git rm -r`** (nicht nur auskommentieren) - wie bei den früheren
   Auslagerungen.
4. `:MyPlugins`-Weiterleitung, Statuszeilen-Zähler (`ui.nvim`) und `scripts/tasks.lua`-Pfade in der Config prüfen.
5. Tasks, die auf `lua/tasks/...` zeigen (`refs:`), nachziehen: **`--stale=refs` meldet sie sonst alle** (Pfad weg).
   Der Vault-Bereich für das Plugin heißt dann `tasks.nvim` (neuer Bereich mit `ROADMAP/` und `Backlog/{FEATURES,TASKS}`);
   die Tasks der Plan-Phasen A-E werden dorthin **verschoben**, nicht kopiert (`task set` kennt keinen Bereichswechsel
   - Werkzeug-Lücke, vor dem Umzug klären).
6. Nach dem Öffentlich-Machen: `github_stats.nvim` die neue Repo-Zeile geben (Traffic-Sammlung), `reposcope`-Favoriten
   nach Bedarf, `:DocMap` für das Repo (Release-Artefakte `docs/map/`), Vault-Notiz in `Backlog/README.md` der `nvim-config`.

### 8.5 Was **nicht** mit ausgelagert wird

Der Vault selbst (WKDBooks), `:MyPlugins`, das CI-Template `docs/TEMPLATES/wkdbooks-tasks-ci.yml` (bleibt in der Config,
das Plugin liefert `scripts/tasks-ci.lua`), und `ui.nvim/tasks_counter` (eigener Parser, bewusst entkoppelt).

## 9. Kreuzfeatures-Check über die Plugins

Gelesen: `README`/`doc/*.txt`-Köpfe aller 39 Repos unter `$REPOS_DIR` (`E:\repos`), dazu gezielt die Verzeichnisse von
`ai.nvim`, `gitsuite.nvim`, `sessions.nvim`, `casedesk.nvim`, `ui.nvim`, `lib.nvim`, `rules.nvim`. Gesucht: wo ein Plugin
**bereits** einen Haken hat (Event, API, Parser), an den ein Task-Feature sinnvoll andockt. Die Schnittstellen sind nur
so weit geprüft, wie unten steht; **vor dem Bauen jeweils die echte API lesen** (Roadmap-Punkt-Beschreibungen veralten
still).

### 9.1 Sinnvoll - bauen (nach Nutzen)

| Plugin | Kreuzfeature | Haken, der schon da ist | Aufwand / Nutzen |
|---|---|---|---|
| **rules.nvim** | **Befund -> Task -> automatisch erledigt.** `:Rules check` findet Regelverstöße; je Verstoß ein Task `category: ruleset` mit `rules: [LLS-45]` und `refs` (Duplikate über Regel-Id + Datei erkannt); besteht die Regel später, schlägt `tasks` das Erledigen **vor** (Beleg statt Behauptung). Umgekehrt zieht `task brief` den Regeltext der `rules:`-Ids dazu | Kategorie `ruleset` und Feld `rules:` **gibt es schon**; Regeln haben `id`, `text`, `source_file/line` und `--format=json` | M / 4 |
| **ai.nvim** | Phase E ist schon geplant (Entwurf `## Plan`, Triage). Dazu: **Schätzvorschlag** für `effort`/`value` und der **CDX-Auftrag** (`task brief`). Alles hinter `ai.nvim/provider-policy-allowed`, Datenklasse intern | `ai.ask(req, cb)` / `ai.stream`, `policy.lua`, `context/` | M / 4 |
| **gitsuite.nvim** | Branch `task/<slug>` setzt `status: doing`; ein Commit mit Trailer `Task: <id>` trägt `done_in=<repo>@<sha>` ein; `GitsuiteBranchSwitched` zeigt den aktiven Task | `events.lua` feuert `User GitsuiteBranchSwitched` (u. a.); **ein Commit-Event fehlt** unter den bei der Durchsicht gesehenen - nachrüsten, nicht raten | M / 4 |
| **documentation.nvim / buffer-ctx.nvim / hover.nvim** | **"Tasks zu dieser Datei"**: Rückwärtsindex `refs` -> offene Tasks; Hover/Float am Cursor ("2 offene Tasks nennen diese Datei"), `:Tasks here`. Nutzt die vorhandene `--stale=refs`-Pfadauflösung | `staleness.lua` löst `refs` schon gegen Repos auf; `hover` zeigt "whatever the cursor is resting on" | S / 4 |
| **markdown.nvim** | Checkbox-Toggle im `## Plan` -> letzter Schritt = Rückfrage "Task abschließen?" (3.6); Vorschau-Tabelle über `mdview` existiert | Toggle-Funktion in `markdown.nvim`, Preview-Weg `tasks_preview.lua` | S / 3 |
| **mdview.nvim** | Mermaid-Graph (`--format=mermaid`) als Vorschau; Frontmatter-Tabelle gibt es (`ec4092a`, erst nach neuem WASM-Release sichtbar) | `task preview`, `--to=mdview` | S / 3 |
| **gopath.nvim** | Task-Id unter dem Cursor (`ai.nvim/provider-policy-allowed`, auch in Prosa/Markdown) öffnet die Task-Datei | `gp`-Auflösung für Pfade/URLs; Resolver-Erweiterung nötig | S / 3 |
| **sessions.nvim** | aktive Task je Branch/Sitzung merken; beim Wiederherstellen "Weiter mit: `<id>`"; ein Chip in der Statuszeile | `chip.lua`, `chip_text.lua`, `git.lua` (Branch-bewusst) | S-M / 3 |
| **ui.nvim** | Statuszeilen-Zähler um `ready` und `me`/`cdx` erweitern; Popup-Bausteine (`ui.kit`) für Wunsch 2 | `tasks_counter` (eigener Parser, `source.lua`), `ui.kit` | S / 3 |
| **cascade.nvim** | `status`, `prio`, `effort`, `value`, `actor` in Task-Frontmatter per Taste durchschalten ("context-aware lists & cycling"); `done` darf **nicht** per Textänderung gesetzt werden (verschiebt die Datei) - das Durchschalten muss über `task set` laufen, nie über den Buffer-Text | `cascade` ist genau diese Funktion | S / 3 |
| **insights.nvim / spotlight / runtime-analysis / lsp.nvim** | **Befunde in Tasks überführen** (Stapel mit Dedupe): TODO/FIXME-Kommentare, Diagnostik-Läufe (die luals-scan-Runde 2026-09-05 hat 75 Funde von Hand verarbeitet), Runtime-Befunde als `kind: bug` | `insights` (Symbole/Metriken), `runtime-analysis`, `lsp` | M / 3 |
| **pickers.nvim** | Task-Quelle für den globalen Picker ("Task öffnen"); der offene Task `pickers.nvim/generic-items-source` ist genau diese Brücke | Handover "Als Nächstes bauen" | M / 3 |
| **filetree.nvim / fileops.nvim** | Kontextmenü-Eintrag "Task hier anlegen" (`refs=<Pfad>`); Badge am Knoten "n offene Tasks" aus dem Rückwärtsindex | `lib.nvim.contextmenu`, Knotenkontext | S / 3 |
| **images.nvim** | Bild aus der Zwischenablage in einen Folder-Task (`assets/`) einfügen (`attach` gibt es) | `paste`-Weg in `images.nvim`; offener Task `paste-powershell-quote-escape` vorher beheben | S / 2 |
| **lib.nvim** | `lib.nvim.frecency` hat keine injizierbare Uhr und keine Halbwertszeit; die Task-Engine hat deshalb **eine eigene** Frecency. Beim Umzug klären: lib-Variante erweitern und die Kopie streichen (Duplikat-Falle, `lib.nvim`-Audit) | `tasks/frecency.lua` benennt den Grund | M / 2 |
| **github_stats.nvim / reposcope.nvim** | beim Öffentlich-Machen von `tasks.nvim`: Repo in die Traffic-Sammlung aufnehmen; Task -> GitHub-Issue nur für ein öffentliches Plugin | Config-Zeile | XS / 2 |

### 9.2 Nein oder nur mit Vorsicht

| Plugin | Urteil und Grund |
|---|---|
| **casedesk.nvim** | **Vorsicht, nicht verknüpfen.** Support-Fälle enthalten Kundendaten; der Task-Vault ist intern und wird mit `tasks.nvim` zum öffentlichen Plugin. Höchstens eine Fall-**Nummer** als `refs`, nie Inhalt. (Casedesk hat ein eigenes `plan.lua`/`timeline`/`sla` - die sind **nicht** das Task-Plan-Konzept; nicht zusammenlegen.) |
| **replacer.nvim** | Massenänderung von Tags geht schon über `task set` im Batch bzw. `migrate-actor`; ein Umweg über Suchen/Ersetzen würde den Roundtrip (Frontmatter, `updated`) umgehen. |
| **language.nvim, emojis.nvim, color_my_ascii.nvim, cmdlog.nvim** | kein tragfähiger Haken; ein Emoji als Akteur-Symbol (🤖/🧑) ist Anzeige und gehört in die Dashboard-Konfiguration, nicht in ein Kreuzfeature. |
| **dap.nvim, debugging.nvim, sandbox.nvim, data.nvim, diff.nvim, media.nvim, pdfport.nvim, recommender.nvim, my.nvim** | keine Schnittstelle zur Aufgabenverwaltung; `my.nvim` (privates Repo) ist der Platz für die **persönliche** Vault-Voreinstellung nach der Auslagerung, kein Feature. |

**Querschnitt:** die stärksten drei sind `rules.nvim` (Beleg statt Behauptung beim Erledigen), "Tasks zu dieser Datei"
(billig, täglich nützlich) und `gitsuite.nvim` (`done_in` ohne Tippen). Alle drei nutzen **vorhandene** Haken; keine
verlangt einen Umbau am Task-Format.

## 10. Task-Zuschnitt und Wellen

Vorschlag, **noch nicht angelegt** (Anlegen = ein Aufruf je Task, Bereich `nvim-config`, nach dem Umzug `tasks.nvim`;
Schätzung `effort`/`value` mit den neuen Feldern gleich eingetragen). `blocked_by` verweist auf die bestehenden
Plan-Tasks.

| Slug (Vorschlag) | Welle | Aufwand | Nutzen | actor | blocked_by |
|---|---|---|---|---|---|
| `tasks-done-flow-seam` (`done_flow.run`, drei Aufrufer, kein Verhaltenswechsel) | 1 | S | 4 | cdx | - |
| `tasks-effort-value-fields` (`value`, `bad-value`, Filter, `--sort=roi`, CSV, Doku) | 1 | M | 4 | cdx | - |
| `tasks-actor-field` (`actor`, Ableitung, Filter, Dashboard-Chip, `migrate-actor`) | 1 | M | 4 | cdx | - |
| `tasks-extract-prepare` (Vault-Voreinstellung/Bereichsliste in die Config, Frontend-Schnitt, Namensraum) | 1 | M | 3 | cdx | - |
| `tasks-estimate-rollup` (`estimate.rollup`, Spanne, Akteur-Aufteilung, Plan-Kopf, Dashboard-Σ, `task estimate`) | 2 | M | 4 | cdx | `tasks-plan-engine`, `tasks-effort-value-fields`, `tasks-actor-field` |
| `tasks-next-pick` (`next.pick`, `task next --actor`, CLI-Zeilen) | 2 | M | 4 | cdx | `tasks-plan-engine`, `tasks-done-flow-seam` |
| `tasks-done-popup` (Popup + vier Leer-Fälle, Dashboard-Stapel, Konfiguration) | 3 | M | 5 | pair | `tasks-next-pick` |
| `tasks-done-chain` (a-d: Schritte, Plan-Datei, Marker-Blöcke, Konzept-Nachzug) | 3 | M | 4 | cdx | `tasks-done-flow-seam`, `tasks-plan-files`, `tasks-task-plan-section` |
| `tasks-nvim-rules-sweep` (Ruleset-Familien und Gates, Befunde fixen) | 4 | L | 4 | pair | `tasks-extract-prepare` |
| `tasks-nvim-extract` (Repo **privat** anlegen, Umzug, Verdrahtung, `git rm`, Shim) | 4 | L | 4 | pair | `tasks-nvim-rules-sweep`, Wellen 1-3 empfohlen (D6) |
| `tasks-nvim-publish` (`gh repo` öffentlich, `REL`-Gate, `github_stats`-Zeile) | 4 | S | 3 | **me** | `tasks-nvim-extract` - braucht dein Ja |
| `tasks-ideas-pick` (Abschnitt 7 durchgehen, auswählen, anlegen) | - | S | 3 | **me** | - |

Zuschnitt-Regeln: **ein Task = ein Ergebnis** (R5), jede Welle ist unabhängig prüfbar, Welle 1 hat keine Kante auf die
Plan-Engine (so liefert sie, ohne zu warten). Reihenfolge innerhalb einer Welle nach ROI. Die Kreuzfeatures aus 9.1
werden **erst** Tasks, wenn du sie auswählst (`tasks-ideas-pick`).

Bau-Reihenfolge Welle 1 (jeweils ein Agent, ein Häppchen, Spec zuerst):

1. `tasks-done-flow-seam` - klein, ohne Verhaltensänderung, entsperrt zwei Wellen.
2. `tasks-effort-value-fields` und `tasks-actor-field` - reine Felder; **zuerst die Muster lesen**, die es gibt: `severity`
   (`model.SEVERITIES`, `bad-`/`unknown-severity`, Filter, Sortierung, "nicht im Index") und `category`
   (`model.categories`, abgeleitete Menge). Beide Felder folgen exakt diesem Vorbild.
3. `tasks-extract-prepare`.

## 11. Entscheidungen (D1-D9)

Nicht selbst entscheiden; mit Empfehlung.

| # | Frage | Empfehlung |
|---|---|---|
| **D1** | Akteur als eigenes Feld oder als Wert in `category`? | **Eigenes Feld `actor`** (`cdx`/`me`/`pair`); `category` bleibt Sachgebiet. Bestand über Ableitung aus `needs-user`/`decision` |
| **D2** | `value` als Zahl 1-5 oder T-Shirt-Wörter? Wie zu `prio`? | **Zahl 1-5**; `prio` = Reihenfolge, `value` = erwarteter Nutzen, ROI abgeleitet. **D2b:** Summe als **Spanne** ausweisen (Vorschlag in 5.2), nicht als Punktwert |
| **D3** | Plan-Schritte und Plan-Status beim Erledigen **automatisch** ändern (dein Wunsch) - obwohl das Konzept §15 "keine automatische Statusänderung ohne Rückfrage" sagt? | **Automatisch** für abgeleitete Zustände (Schritte, Plan-Status), mit Bericht in `notes`; **gefragt** bleibt `blocked -> open` (PQ2) und alles, was Prio/Status *anderer* Tasks ändert. Konzept §15 entsprechend präzisieren |
| **D4** | Popup: modal oder nicht-blockierend, Standard an? | **Nicht-blockierendes Float**, an, nur im Editor; CLI druckt Zeilen. Einstellung `tasks.next.popup` |
| **D5** | Modulname im Plugin: `tasks` oder `tasks_nvim`? | **`tasks_nvim`** (Kollisionsregel; billiger vor dem Veröffentlichen) |
| **D6** | Auslagern **vor** oder **nach** den Features? | **Nach Welle 1-3** (Engine zieht kostenlos mit, keine `refs`-Umzüge der neuen Tasks). Alternative: vorher auslagern, wenn du jetzt schon ein öffentliches Repo brauchst - dann Wellen 1-3 im Plugin bauen, Kosten: die offenen `refs:` zeigen sofort ins Leere |
| **D7** | Handgeschriebene Plan-Dokumente per Task-Id-Suche abhaken? | **Nein** (R14); nur Marker-Blöcke, sonst bleibt Handschrift Handschrift |
| **D8** | Verlauf mit umziehen (`filter-repo`) oder sauberer Neuanfang? **D8b:** `:Rules gate review` um `LLS` erweitern bzw. `REVIEW.md` migrieren? | Verlauf **nur wenn** `filter-repo` ohne Handarbeit läuft, sonst Neuanfang mit Verweis auf den Ursprungs-Commit. REVIEW: erst klären, ob die 0 Blöcke Absicht sind |
| **D9** | Wo liegt dieses Handover? | Hier (Original, `docs/ROADMAP/handovers/`), Symlink im Vault (`ALL/handovers/`) wie bei den übrigen Originalen - noch nicht angelegt, Vault-Commit nur mit expliziten Pfaden |

## 12. Risiken, Verifikation, Arbeitsregeln

**Risiken**

| Risiko | Gegenmaßnahme |
|---|---|
| Die Kette lässt einen Plan "fertig" werden, obwohl ein Mitglied nur umgezogen oder umbenannt wurde | Mitgliedschaft nur über `plan:`-Id, nie über Textähnlichkeit; `plans_closed` steht im Bericht und `task plan reopen` macht es rückgängig |
| Popup nervt (Stapel, Skripte) | ein Popup je Stapel, nie in CLI/headless, abschaltbar; nur eine Anzeige |
| "Nichts offen" lügt, wenn nur Wartendes bleibt | vier getrennte Meldungen (4.3), der dritte Fall ist Spec |
| `value`/`actor` bleiben leer, Summen täuschen Genauigkeit vor | Summen nennen **immer** die Zahl der fehlenden Schätzungen; Spanne statt Punkt; `task estimate` macht das Pflegen billig |
| Zwei Wichtigkeitsfelder (`prio`, `value`) widersprechen sich | Doku-Satz "Reihenfolge vs. Nutzen"; ROI ist abgeleitet und ändert nie `prio` |
| `ready` an drei Stellen verschieden gedeutet | **nur** `plan.ready`; `tasks.next` hängt an der Plan-Engine, kein Vorabstand |
| Frontmatter-Roundtrip verliert `value`/`actor` in einer älteren Werkzeugversion | unbekannte Keys bleiben erhalten (Konzept §3); Engine zuerst ausrollen, dann Felder nutzen |
| Index/CI werden rot, weil neue Felder auftauchen | Index bleibt bytegleich; neue `check`-Codes sind Warnungen/opt-in außer `bad-value`/`bad-actor` (echte Format-Fehler) |
| Umzug lässt `refs:` ins Leere zeigen | `--stale=refs` nach dem Umzug einmal laufen lassen, Tasks nachziehen (8.4 Punkt 5) |
| Öffentliches Repo enthält Persönliches | Vorabprüfung auf `E:\repos`, Mail-Adressen, Vault-Inhalte; `REL`-Gate; Veröffentlichen nur auf dein Ja |
| Linux/macOS ungetestet (heute nur Windows 11) | CI-Matrix **vor** dem Öffentlichmachen; bis dahin im README als "nur Windows getestet" ausweisen |

**Verifikation je Häppchen** (die Form der bestehenden Arbeit):

```
nvim -n -i NONE --headless -u NONE -l TESTS/run.lua tasks_<name>     # eine Spec
nvim -n -i NONE --headless -u NONE -l TESTS/run.lua                  # alle (TESTS/tasks/ ist die Engine)
nvim --headless -u NONE -l scripts/tasks-ci.lua --vault=<wkdbooks>/Development/wkdbook-myplugins
```

Specs laufen gegen ein **Fixture-Vault** (`TESTS/tasks/fixture.lua`), nie gegen den echten. Pro Feature mindestens: der
Normalfall, jeder Fehlerpfad, **Regression** ("ein Task ohne die neuen Felder verhält sich exakt wie heute", Index bytegleich).
Das KI-Provider-Set (20 Tasks, Konzept §11) ist der vorhandene Anschauungsbestand für Stufen, Hebel und kritischen Pfad.

**Arbeitsregeln für die Umsetzung**

- **Vor jeder Phase die echte Quelle lesen**, nicht diesen Plan: `mutate.lua` um `M.done` (Zeile ~919) und `SETTABLE`
  (~366), `model.lua` (`CATEGORIES` ~40, `SEVERITIES` ~44, `EFFORTS` ~54, `effort_days` ~163),
  `tasks_dash_core.lua` (Zählung ~283), `tasks_dash.lua` (`apply_done`/`after` ~292). Zeilennummern altern; die Namen nicht.
- **Eine Engine, drei Frontends:** Verhalten in `lua/tasks/` (rein), Anzeige in den Frontends. Kein `vim.notify`, kein
  Float in der Engine (R12/E4) - sonst stirbt die Auslagerbarkeit.
- **In dieser Config: Worktree vs. Hauptcheckout.** Sitzungen in einem Worktree lesen/lintens/testen nur dort; ein `cd` zum
  nackten nvim-Pfad prüft die **falsche** Dateiversion (Memory `nvim-worktree-vs-main-checkout-trap`).
- **Vault:** WKDBooks ist **ein** Repo mit fremden ungetrackten Ordnern (`wkdbook-takt/`, `TOOLS/scripts/tui-spike/`);
  Commits dort **nur mit expliziten Pfaden**, nie `git add -A`/`git clean -d`.
- **Review:** jeder Code-Commit bekommt einen `ultracode`-Review-Pass; keine Agenten gleichzeitig; Reviewer dürfen **nicht**
  per Image-Name Prozesse beenden (`taskkill /IM nvim.exe` kann fremde Instanzen treffen) und nicht committen/pushen
  (Memory `workflow-agents-can-commit-push-unprompted`).
- **Kommentare laufend**, Plugin-Docs und `lua/tasks/README.md` mitpflegen, kein Co-Autor-Trailer, danach sofort auf `main`.
- **Konzept nachziehen:** neue Regeln gehören in `Task-System-Konzept.md`/`Task-Plan-Konzept` (Vorschlag: **R19** "Akteur
  ist Metadatum, kein Tor"; **R20** "Schätzung ist optional und trägt ihre Lücken in jeder Summe"; **R21** "eine
  Erledigen-Kette, ein Einstieg `done_flow`").

## Was du entscheiden oder tun musst

1. **D1-D9 durchgehen** (11) - vor allem **D3** (automatisch vs. fragen) und **D5/D6** (Namensraum, Reihenfolge der Auslagerung).
2. **Ideen auswählen** (7) und **Kreuzfeatures** (9.1), die Tasks werden sollen.
3. **Schätzskala von `value`** bestätigen (1-5; Spanne ja/nein).
4. **Öffentliches Repo:** dein ausdrückliches Ja, **erst** wenn Ruleset-Durchgang und `REL`-Gate grün sind.
5. **Symlink im Vault** für dieses Handover (D9) - sag Bescheid, dann lege ich ihn mit explizitem Pfad an.
