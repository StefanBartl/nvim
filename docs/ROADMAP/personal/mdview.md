# `mdview.nvim`



## var resolution
**Das Problem:** In `mdview.nvim` gab es zwei Stellen, an denen `~`/`$VAR`/`%VAR%` in Pfaden nicht aufgelöst wurden, bevor sie tatsächlich verwendet wurden:

1. **`server_cwd`-Config und `cwd=`-Argument** (`:MDView start file.md cwd=$REPOS_DIR/proj`): Die Funktion `resolve_spawn_cwd()` in `adapter/runner.lua` hat den rohen, unexpandierten String direkt an `uv.spawn()` als Arbeitsverzeichnis für den Server-Prozess übergeben. Ein `$REPOS_DIR` im Pfad wäre also nie aufgelöst worden — der Server wäre mit einem ungültigen Arbeitsverzeichnis gestartet.

2. **`browser_cmd`-Config** — hier war es sogar ein doppelter Bug: Die Prüfung, ob der Browser-Pfad ausführbar ist (`is_executable()`), hat intern zwar normalisiert, aber das Ergebnis wurde nirgends gespeichert. Der tatsächlich gespeicherte Wert `resolved_browser_cmd` (der später zum Starten des Browsers benutzt wird) blieb der **rohe, unexpandierte** String. Sprich: Selbst wenn die Prüfung "ist ausführbar" zufällig durchgelaufen wäre, hätte der spätere Spawn-Aufruf trotzdem den falschen (unexpandierten) Pfad bekommen.

**Warum nicht der vom Roadmap vorgeschlagene Fix-Punkt (`helper/normalize.lua:path()`)?** Diese Funktion wird im ganzen Plugin auch auf bereits aufgelöste Buffer-Namen angewendet (echte Dateipfade von offenen Buffern). Hätte ich dort pauschal `expand_path` reingehängt, hätte das theoretisch eine reale Datei mit einem `$`-Zeichen im Namen (z.B. `notes$backup.md`) verfälschen können, falls `$backup` zufällig ein gesetzter Env-Var-Name ist. Stattdessen habe ich die Fixes gezielt an den beiden echten Problemstellen (`runner.lua`, `config/browser.lua`) gemacht — sicherer und trifft den Bug direkter.

---

## Table of content

  - [var resolution](#var-resolution)
  - [FINISH](#finish)
  - [Workflow Doc](#workflow-doc)
  - [Bugs](#bugs)

---

## FINISH

- Alle features durchgehjen und die perform,anteste, ideale DEFAULT config zusammenstellen

---

## Workflow Doc

Szenario: In nvim eine markdown file offen, dann `MDViewStart`:
  1. Was passiert dann genau?
2. Was passiert, damit die file das erste Mal im Browser aufgebaut wird?
  1. Was assiert, wenn sich die Datei ändert? Wie wird gesynced (Prozess)?
  2. Welche Protkolle machen wann was?
Zusätzlich anhand von praxis use cases die jeweiligen Prozesse beschreiben, also zb.: Welcher Prozess läuft bei den einzelnen usercommands ab?

---

## Bugs

nvim/logs/debuglog ausschalten und als switch implementieren

---

