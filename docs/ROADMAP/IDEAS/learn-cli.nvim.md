# `learn-cli.nvim`

Angelegt 2026-08-08 aus der Analyse von
`E:/repos/Notes/MyPlugin-Notes/nvim-train/train-notes.md`.

---

## Zuordnung

`nvim-train` war der Vorläufer dessen, was heute als `learn-cli.nvim` im
Repo-Bestand liegt (`E:/repos/learn-cli.nvim`, Modulwurzel `learn_cli`).
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
