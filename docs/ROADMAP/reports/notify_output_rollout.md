# Notify/Output-Rollout — offene Aufgaben

Stand: 2026-09-27 · Historie, Architektur-Entscheidungen und Erledigtes:
[WKDBooks `lib.nvim/Backlog/TASKS/notify-output-rollout-2026-09-25.md`](https://github.com/StefanBartl/WKDBooks/blob/main/Development/wkdbook-myplugins/lib.nvim/Backlog/TASKS/notify-output-rollout-2026-09-25.md)

Diese Datei ersetzt die frühere Report-Serie `00`-`06` in diesem Ordner
(sieben Zwischendateien, die zunehmend auseinanderdrifteten — ins Archiv
verdichtet, siehe Link oben). Ab hier steht nur noch **offene** Arbeit,
gepflegt als einzige lebende Datei statt als Plan+Worklist-Paar.

## Status

| Phase | Inhalt | Status |
|---|---|---|
| P0 | `lib.nvim.notify.popup` erweitern (Kappung, `toast_min_level`, globaler Default, `expand_last`, `:Lib notify`) | ✅ erledigt (`80bdc3d`, `a60c481`) |
| P1 | `lib.nvim.echo`, `lib.nvim.output`-Fassade, `output.viewer` | ✅ erledigt |
| P2 | Progress-Style `echo`, Style-Liste | ✅ erledigt |
| P3 | Aktivierung in der Installations-Spec | ✅ erledigt |
| P4 | Wrapper-Repos umstellen | ✅ erledigt — 11/12 echte Fixes, pickers.nvim korrekt als Nicht-P4-Fall erkannt (dessen P6-Anteil ist jetzt auch erledigt) |
| P5 | Load-Time-Bindungen | ✅ erledigt — 1 echter Bugfix, 2 als Fehlalarm bestätigt, 1 ignoriert (siehe Archiv) |
| P6 | `print`-Dumps auf `output.viewer.show_lines` | ✅ erledigt (siehe Archiv) |

## Abschluss

Alle sechs Phasen sind erledigt — Details, Fehlalarm-Reklassifizierungen und
die vollständige Repo-für-Repo-Historie stehen im WKDBooks-Archiv (Link
oben). Diese Kampagne ist damit geschlossen; diese Datei bleibt als
Ablagepunkt für den Link, falls Notify/Output-Themen erneut aufkommen.
