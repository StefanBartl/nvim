# Workflows: interaktive Bestätigung statt Notify-mit-Anleitung

Cross-Cutting-Task, quer über (fast) alle eigenen Plugins. Ausgangspunkt:
`fileops.nvim`s `:File delete` gibt bei ungespeicherten Änderungen nur eine
`notify.error("... use :File! delete ...")` aus — der Nutzer muss den
Befehl selbst nochmal mit `!` abschicken. Besser: sofort eine interaktive
Auswahl (`ui.kit.confirm`/`ui.kit.select`) anbieten, die den Vorgang direkt
mit der nötigen Option fortsetzt. Zweites Beispiel aus derselben Session:
`:MyPlugins`' destruktive Bestätigungen (`reclone` u. a.) laufen aktuell
über ein hand-geschriebenes `vim.fn.getcharstr()` + `print()`
(`lua/bindings/usrcmds/plugin_repos/confirm.lua`) statt über eine echte
UI — sieht wie eine reine Text-Notify aus, ist aber schon eine Ja/Nein-
Abfrage, nur ohne die gewohnte Optik.

Die beiden konkreten Beispiele (fileops.nvim `:File delete`, `:MyPlugins`
Confirm-Dialog) sind inzwischen umgesetzt und archiviert — Einzel-Befunde und
Umsetzungsdetails siehe `fileops.nvim/Backlog/FEATURES/delete-confirm-
instead-of-refuse.md` bzw. `nvim-config/Backlog/FEATURES/myplugins-confirm-
dialog.md` in `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/`. Der
ursprüngliche Sammel-Report (`ecosystem-small-tasks-2026-09.md`) ist nach
Abschluss aller 14 Punkte per Plugin dorthin aufgeteilt und gelöscht worden.
Diese Datei hier ist der übergreifende Rahmen für den noch offenen
Audit-Task (Punkt 15 des ehemaligen Reports), nicht die Einzelumsetzung.

Passende Regel im Kanon (neu angelegt in dieser Session): `UI-05` in
`$REPOS_DIR/WKDBooks\Development\wkdbook-Lua\Checklists\regeln\LUA_NVIM.md`,
Abschnitt "Notifications".

---

## Das Muster

Ein `notify.error`/`notify.warn`, dessen Text im Kern lautet "das ging
nicht, versuch's nochmal mit `<Flag>`/`<Argument>`", ist fast immer ein
Kandidat für eine echte interaktive Nachfrage statt einer Anleitung zum
Abtippen. Erkennungsmerkmale beim Durchsuchen einer Codebase:

- Fehlertext enthält `use ! to`, `use :X! `, `pass --force`, `retry with`,
  `run again with`, oder eine ähnliche "hier ist der Befehl, den du als
  Nächstes eintippen sollst"-Formulierung.
- Der Aufrufer hat bereits alle Informationen, um die Nachfrage sofort zu
  stellen (welche Datei, welcher Modus) — es gibt keinen Grund, den Nutzer
  den Kontext manuell neu eingeben zu lassen.
- `ui.kit` (aus `ui.nvim`) ist im jeweiligen Plugin bereits Soft-Dependency
  (Grep `require("ui.kit")` / `pcall(require, "ui.kit")`) — dann ist der
  Umbau eine lokale Änderung, kein neuer Unterbau.

## Bereits gefundene Fälle (2026-09-23, nicht vollständig)

| Plugin | Ort | Heutiges Verhalten |
| --- | --- | --- |
| `fileops.nvim` | `ops/file.lua:745-747` | `:File delete` bei modifiziertem Buffer → reiner Error, Hinweis auf `:File!` |
| `fileops.nvim` | `ops/file.lua:413,557` | Rename/Move/Copy/Duplicate bei existierendem Ziel → Hinweis auf `!` statt Nachfrage |
| nvim-config | `lua/bindings/usrcmds/plugin_repos/confirm.lua` | `:MyPlugins`-destruktive Aktionen (`reclone` etc.) → `getcharstr()`+`print()` statt `ui.kit.confirm` |

`fileops.nvim`s eigene `health.lua:50-52` nennt "the modified-buffer
confirm" bereits als erwarteten Punkt — die Erwartung war im Projekt selbst
also schon vorhanden, nur für `delete` nicht umgesetzt. Das ist ein starkes
Indiz, dass es an weiteren Stellen im selben Repo (und in Schwester-
Repos mit ähnlicher Architektur) noch mehr davon gibt.

## Verwandt, aber ein eigenes Muster: "Vorschlag ablehnen ≠ Aktion ablehnen"

Zweiter, eng verwandter Fund aus derselben Session, diesmal in
`gopath.nvim`: Lehnt der Nutzer eine automatisch vorgeschlagene Alternative
ab (z. B. "meintest du `00_toCustomer.md`?"), wird das aktuell als
"gesamten Vorgang abbrechen" gewertet — es gibt keine nachgelagerte Chance
mehr, die *ursprünglich* gemeinte Aktion (hier: `01_toCustomer.md` neu
anlegen) noch auszuführen. Siehe Report, Abschnitt 5, für den exakten
Codepfad (`gopath/alternate/init.lua`, `on_done(true)` bei Cancel).

Das ist dasselbe Grundproblem wie oben, nur einen Schritt weiter gedacht:
nicht nur "biete eine Nachfrage an, statt zu scheitern", sondern auch
"eine abgelehnte Option darf keine ANDERE, unabhängige Option automatisch
mit wegnehmen". Beide gehören unter dieselbe Regel (UI-05), weil beide
densel­ben Nutzer-Frust vermeiden: einen Vorgang zweimal von vorne starten
zu müssen, obwohl das System nach der ersten Ablehnung genug wüsste, um
selbst weiterzumachen.

## Folge-Task: systematischer Audit

Wie in der Session angefragt ("check ob ein ähnliches Szenario in anderen
Bindings Sinn macht"): dieser erste Fund war nur der `gF`/`gC`-Fall in
`gopath.nvim`, gefunden weil ein Screenshot ihn zeigte — kein systematischer
Sweep. Als eigene, spätere Aufgabe:

1. Pro Plugin-Repo (`$REPOS_DIR/repos/*.nvim`) nach demselben
   Notify-mit-Anleitung-Muster grep­pen (siehe Erkennungsmerkmale oben als
   Startpunkt für die Suchbegriffe).
2. Pro Fund entscheiden: verdient das eine interaktive Nachfrage (Kandidat
   für UI-05), oder ist die Anleitung hier bewusst richtig (z. B. weil die
   Aktion so selten/riskant ist, dass ein zweiter bewusster Tastendruck
   Absicht signalisieren soll — nicht jeder Fall ist automatisch ein Bug)?
3. Separat: jede mehrstufige Auswahl/Vorschlag-Flow (nicht nur
   `gopath.alternate`) daraufhin prüfen, ob ein Cancel versehentlich eine
   unabhängige Folgeaktion mit-canceled, statt nur die abgelehnte Option
   selbst zu verwerfen.

Ergebnis dieses Audits: eine Fundliste analog zur Tabelle oben, dann
priorisiert nach Plugin/Aufwand — kein Big-Bang-Umbau in einem Rutsch.

## Nicht Teil dieses Tasks

- Kein neues UI-Primitive nötig — `ui.kit.confirm`/`ui.kit.select` decken
  jeden bisher gefundenen Fall ab.
- Keine Änderung an Plugins, die `ui.nvim` nicht als (Soft-)Dependency
  führen — dort bleibt der bisherige Notify-Weg der einzig sinnvolle,
  solange kein `vim.ui.select`-Fallback sauber greift (siehe
  `gopath.create.ask()` als Referenz für den Fallback-Stil).
