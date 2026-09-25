# `learn-cli.nvim`

Angelegt 2026-08-08 aus der Analyse von
`$REPOS_DIR/Notes/MyPlugin-Notes/nvim-train/train-notes.md`.
Ergänzt 2026-09-25 um Phase 0 (siehe unten): ein eigenständiger
Lernplan-Viewer, unabhängig von der offenen Grundsatzfrage zum Plugin selbst.

---

## Phase 0: Standalone-Lernplan-Viewer (umgesetzt)

Ursprung: `docs/ROADMAP/Lernplan_CLI.md` (12-Wochen-Plan, grep/find/head/tail,
Linux vs. PowerShell, Spaced-Repetition-Rhythmus). Der Plan selbst war
inhaltlich fertig, hatte aber keine Form in Neovim — nur eine Markdown-Datei
ohne Navigation, Fortschrittsanzeige oder Wiederholungs-Tracking.

**Bewusst getrennt von der Plugin-Frage unten:** `learn-cli.nvim` (das
Plugin) ist deaktiviert (`plugins/personal/source.lua`) und die
Grundsatzfrage "vielleicht doch?" ist offen. Dieser Viewer rührt den Plugin-
Code nicht an — er ist ein kleines, eigenständiges Feature direkt in dieser
Config, das schon jetzt nutzbar ist, ganz gleich wie die Plugin-Frage später
ausgeht. Falls `learn-cli.nvim` irgendwann doch reaktiviert wird, kann der
Lernplan hier als eigener Cycle re-exportiert werden (die Struktur pro Woche
— Themen, Beispiele, Linux/PowerShell — ist dafür bereits nah am
`learn-cli.nvim`-Cycle-Format aus `docs/DE/CLI/Zyklus-1.md` dort).

### Inhalt

- `docs/ROADMAP/CLI_Lernplan/week-01.md` … `week-12.md` — eine Seite pro
  Woche, aus `Lernplan_CLI.md` abgeleitet: Themen, Linux-/PowerShell-Befehl
  nebeneinander, pro Befehl 3 Wiederholungs-Checkboxen (`- [ ] Durchlauf N`)
  plus eine "Woche abgeschlossen"-Checkbox. Reine Markdown-Dateien — les- und
  editierbar auch außerhalb von Neovim.
- `lua/bindings/usrcmds/learn_plan_viewer/` — `:LearnPlanViewer [week N]`
  plus Buffer-lokale Keymaps in einer Wochen-Seite:
  `<leader>ln`/`<leader>lp` (nächste/vorige Woche), `<leader>lx` (Checkbox auf
  der aktuellen Zeile togglen), `<leader>lb` (aktuelle Woche im Browser
  öffnen). Merkt sich die zuletzt geöffnete Woche
  (`stdpath("data")/learn_plan_viewer_state.json`), damit der Command ohne
  Argument dort fortsetzt.

### Kreuzfeature-Audit (2026-09-25, alle ~35 eigenen Plugins geprüft)

Einzeln durchgesprochen und je mit Empfehlung entschieden, bevor etwas
geschrieben wurde:

| Plugin | Rolle | Entscheidung |
| --- | --- | --- |
| `mdview.nvim` | Browser-Vorschau der Wochen-Seiten (`:MDView start <datei>`) | **Übernommen** — explizite Anforderung |
| `lib.nvim` | `notify`, `fs.json` (State), `bindings.usercmd` | **Übernommen** — Baseline-Konvention dieser Config |
| `pickers.nvim` | Einheitliche `:Pickers`-Navigation statt Buffer-Keymaps | **Verworfen für v1** — einfache `<leader>ln`/`<leader>lp`-Keymaps reichen; Picker wäre spätere Komfort-Erweiterung, kein Kernbedarf |
| `ui.nvim` (Statusline-Badge) | Fortschritt/Woche ständig in der Statusline, nach dem `recommender_badge`/`github_stats_badge`-Muster | **Vertagt auf Phase 1** (siehe unten) — geringer Aufwand, aber kein Kernbestandteil eines ersten Viewers |
| `cmdlog.nvim` | Abgleich "wurde der Befehl wirklich in der Shell ausgeführt" statt reiner Checkbox-Selbsteinschätzung | **Verworfen** — Aufwand (History-Parsing, Abgleichslogik) steht in keinem Verhältnis zum Nutzen für v1 |
| `sessions.nvim`, `insights.nvim`, `documentation.nvim`, `data.nvim`, `spotlight.nvim`, `reposcope.nvim`, `rules.nvim`, `gitsuite.nvim` | — | **Geprüft, kein inhaltlicher Bezug** zu einem Lernplan-Viewer gefunden |

### Phase 1 (vorgemerkt, nicht umgesetzt)

- [ ] `ui.nvim`-Statusline-Badge: `learn_plan_viewer/statusline.lua` mit
      `status()` (z. B. `"Woche 3/12 · 5 Checks"`), plus ein
      `learn_plan_viewer_badge`-Modul in `ui.nvim` nach dem Muster von
      `ui/statusline/modules/recommender_badge/init.lua` (dünnes
      `package.loaded[...]`-Require, leer wenn das Feature nicht geladen ist).
- [ ] Optional: Fortschritt pro Woche (wie viele der 3 Durchläufe erledigt)
      statt nur "Woche abgeschlossen ja/nein" in einer Übersichtsseite
      zusammenfassen.

---

## Zuordnung

`nvim-train` war der Vorläufer dessen, was heute als `learn-cli.nvim` im
Repo-Bestand liegt (`$REPOS_DIR/learn-cli.nvim`, Modulwurzel `learn_cli`).
Struktur: `core/{cycle_manager,exercise_runner,scorer,scoring,validator}.lua`,
`state/{init,progress}.lua`, `ui/{dashboard,exercise_view,info_reader}.lua`,
`data/{exercises/grep.lua,persistence.lua}`.

**Status laut `docs/ROADMAP/ROADMAP.md` der Config: „`learn-cli.nvim` vielleicht
doch?"** — das Plugin ist in `plugins/personal/source.lua` deaktiviert. Die
Punkte unten sind deshalb erst dann relevant, wenn diese Grundsatzfrage mit „ja"
beantwortet ist. Vorher lohnt keine Zeile Code.

**Alle Punkte sind ungeprüfte Übernahmen aus den Notizen** — sie beziehen sich
auf den `nvim-train`-Stand, nicht auf den heutigen Code. Vor der Umsetzung
jeweils gegenprüfen (siehe die Warnung in `All/Roadmap-Effort-Overview.md`).

---

## 1. Zustandsanzeige: läuft gerade ein Training?

Der zentrale Mangel der Notiz: Man sieht nicht, ob man sich noch im Training
befindet. Alles Weitere hängt daran.

- [ ] Kleines Float-Fenster, solange ein Modul läuft.
- [ ] Laufende Uhr darin statt einer Zeit, die erst am Ende erscheint.

**Aufwand:** Quick Win
**Nutzen:** hoch — ohne das ist der Rest der Session-Bugs gar nicht
diagnostizierbar.

## 2. Session-Lebenszyklus abdichten

Vier Notizpunkte, die alle dasselbe Problem beschreiben: Es gibt keinen sauber
definierten Sitzungszustand.

- [ ] Training explizit beenden können (Command + Keymap).
- [ ] Start eines Trainings blockieren, solange ein Modul läuft — oder das
      laufende sauber abbrechen und das erst bestätigen lassen.
- [ ] Trainings-Buffer während der Session gegen Löschen schützen
      (`bufhidden`/`nomodifiable` + `BufDelete`-Guard).
- [ ] Beim Anzeigen der Summary die zugehörigen Trainings-Buffer schliessen.

**Aufwand:** Mittel (als ein zusammenhängender Umbau, nicht als vier Einzelfixes)
**Nutzen:** hoch.

## 3. Auswertung

- [ ] Check automatisch ausführen statt manuell anstossen.
- [ ] Summary wieder öffnen können, nachdem man sie geschlossen hat.
- [ ] Pro Modul automatisch eine Tabelle erzeugen: erreichbare Punkte und
      Zielzeiten. `core/scoring.lua` + `state/progress.lua` sind die Andockpunkte.

**Aufwand:** Quick Win je Punkt
**Nutzen:** mittel-hoch.

## 4. Dashboard-Darstellung

Aus dem Refactoring-Abschnitt der Notiz:

- [ ] Gesamtpunktzahl anzeigen.
- [ ] Farbwechsel, wenn ein Kapitel ≥ 50 % **und** jedes Modul darin ≥ 50 %
      erreicht ist; eigene Farbe bei 100 %.
- [ ] Statuszeichen vereinheitlichen: `✔ 80/100`, `✘ 40/100`, `❍ noch offen`.

**Aufwand:** Quick Win
**Nutzen:** mittel.

## 5. „generell viele Errors"

So notiert, nicht verwertbar. Vor allem anderen:

- [ ] Einmal durchlaufen lassen und die tatsächlichen Fehler protokollieren.
      Erst danach entscheiden, ob die Punkte oben noch stimmen.

**Aufwand:** Quick Win
**Nutzen:** hoch — Voraussetzung dafür, dass diese Liste überhaupt belastbar ist.

## 6. Kosmetik / später

- Logo für die README: Zug mit nvim-Aufdruck.
- Modul-UI blinkt in Farben, wenn ein Modul geschafft ist.

**Aufwand:** Quick Win
**Nutzen:** niedrig.
