
Ok, weiter.

Noch mitplanen, as einen anderen chat:

Ich habe alle Arbeit eingestellt und pushe nichts mehr.

## Zielname klären

Ich habe überall `docmap.nvim` verwendet, so heißt das Repo laut GitHub. In der Nachricht steht `docmap-nvim`. Falls das gewollt ist, stimmt mein Stand nicht. Dann bräuchte man einen anderen Namen für Repo-URL, Lua-Namespace (`require("docmap")` bliebe vermutlich), Hilfe-Tags und Env-Variablen. Bitte kurz bestätigen.

## Kollision mit den lokalen Änderungen

Alles liegt auf dem Branch `claude/docmap-nvim-plugin-analysis-7s3a0v` und nirgends auf `main`. Eigene lokale Änderungen und mein Stand überschneiden sich fast vollständig, ein Merge würde also in vielen Dateien kollidieren. Zwei saubere Wege:

- Man nimmt die eigene lokale Umbenennung und verwirft meine Branches. Die Branches dienen dann nur zum Vergleichen, etwa mit `git diff main..origin/claude/docmap-nvim-plugin-analysis-7s3a0v`.
- Man nimmt meine Branches und verwirft die lokale Umbenennung. Sie sind in `docmap.nvim` vollständig getestet.

## Was ich gemacht habe

- **`docmap.nvim`** (Commit `48a9493`, 341 Dateien): `lua/documentation` ist jetzt `lua/docmap`, die Typen heißen `Docmap.*`, die Hilfe liegt in `doc/docmap.txt`, und es gibt kein Shim. `docs/map` ist neu erzeugt und die README hat einen Hinweis auf die Umbenennung. Auf dieser Struktur laufen stylua, luacheck, Map-Gate, Standalone-Build und alle 131 Specs grün.
- **`docmap-desktop`:** die neuen Prüfungen (`engine.lock`, die Zeile "Vertrag" im Engine-Bereich, CI-Job `engine`) und die Umbenennung der Verweise. Lock und `contract/` bleiben bewusst auf dem alten Commit.
- **Weitere 45 Repos** haben je einen Commit: Verweise, `scripts/gen_map.lua`, Specs, CI-Pfade und Prosa. In `lsp.nvim`, `testing.nvim`, `runtime-analysis.nvim` und `wkd` waren Handarbeiten nötig.
- **Datum `nvim`** (persönliche Konfiguration): Nur die Plugin-Spezifikationen, die Binding-Explorer-Texte und die Repo-Docs sind angepasst. Historische Roadmap-Notizen und die aufgezeichneten GitHub-Statistiken habe ich bewusst nicht angefasst.

## Reihenfolge beim Mergen

Die Konsumenten checken die Engine mit `ref: ci-verified` aus. Das ist ein beweglicher Ref, den erst die CI der Engine nach einem grünen Lauf auf `main` setzt. Deshalb:

1. Zuerst `docmap.nvim` auf `main` mergen und abwarten, bis `ci-verified` auf den neuen Commit gewandert ist.
2. Danach die übrigen Repos, `docmap-desktop` zuletzt (dort `engine.lock` mit `python tools/check-engine-lock.py --write --commit <sha>` verschieben).

Bis alle gemergt sind, sind die Map-Gates der Konsumenten rot. Das ist erwartet.

## Aufgaben

Ich habe 14 Aufgaben im Format von `tasks.nvim` angelegt: Reihenfolge beim Mergen, glibc-Problem, Typen aus Schema, Pin des Sidecars, Join-Route in der Engine, Öffnen in der laufenden Instanz, Deep-Link, `consumers`-Quelle und einige Aufräumarbeiten. Ablage unter `/tmp/claude-0/-home-user/1718db4b-c888-5cc8-ae36-65b688376bb1/scratchpad/tasks/`, mit je einem Ordner `docmap-desktop/ROADMAP/tasks/` und `docmap.nvim/ROADMAP/tasks/`. In den Vault kopieren und `:Tasks check` laufen lassen, die Dateien habe ich nicht gegen den Parser geprüft.

## Nicht erledigt

- Die Repos `spotlight.nvim`, `appkit` und `loomAI` hatten keine Verweise.
- Die Aufgabe `rename-local-followups` betrifft nur den eigenen Rechner: Remotes, Ordnernamen, lazy-lock, MCP-Eintrag und die Telemetrie-Datei im Neovim-Cache.
- Ob der neue CI-Job `engine` und die Workflows der Konsumenten auf GitHub grün laufen, habe ich nicht abgewartet.
