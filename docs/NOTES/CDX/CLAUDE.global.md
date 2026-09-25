# Globale Claude-Code-Regeln (Stefan Bartl / Nvim-Plugin-Dev)

Diese Datei ist die Quelle der Wahrheit und wird per `setup-claude-code.ps1`
nach `~/.claude/CLAUDE.md` verlinkt (bzw. kopiert, falls kein Symlink möglich
ist). Änderungen hier -> committen/pushen -> auf den anderen Rechnern pullen
und Setup-Skript erneut laufen lassen (bei Symlink reicht sogar nur `git
pull`).

## Sprache

- Antworte immer auf Deutsch.
- Im Quellcode (Code, Kommentare, Commit-Message-Body etc.) immer Englisch
  verwenden.

## Arbeitsweise

- Nie mehr als 1 Agent gleichzeitig starten; werden mehrere gebraucht,
  mehrere Runden mit je maximal 1 Agent fahren.
- Immer ausgeben, was du gerade machst bzw. ob es etwas Interessantes gab,
  damit ich Bescheid weiß.
- Chip-/Background-Tasks (spawn_task) ebenfalls auf Deutsch anlegen.

## Env-Variablen

Werden von `setup-claude-code.ps1` pro Maschine gesetzt (User-Scope):

- `$REPOS_DIR` - Wurzel aller Repos (u.a. alle eigenen `.nvim`-Plugins unter
  `$REPOS_DIR/repos`). Wert ist pro Maschine unterschiedlich.
- `$NVIM_CONFIG` - `vim.fn.stdpath('config')`, also dieses Repo. Wird vom
  Setup-Skript automatisch aus dessen eigenem Pfad ermittelt.

## Plugin-Dev-Konventionen

- Installations-Specs meiner Plugins:
  `$NVIM_CONFIG/lua/plugins/personal/init.lua`
- Alle eigenen `.nvim`-Plugin-Repos liegen unter `$REPOS_DIR/repos`.
- Code muss luacheck- und stylua-clean sein, bevor er als fertig gilt (wird
  zusätzlich per Hook erzwungen, siehe `settings.global.json`).
- Neue Features nach Möglichkeit im plugin-eigenen `/TESTS/`-Ordner testen.

## Doku-Struktur (nicht verwechseln)

- Plugin-Repo-Docs (README, Feature-Docs) -> für Endnutzer, im jeweiligen
  Plugin-Repo.
- `$NVIM_CONFIG/docs` -> Reports, Handover-Files (Originale).
- `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/**` bzw.
  `.../Development/**` -> Backlogs, interne Notizen, Roadmaps, Features -
  alles was Endnutzer nicht betrifft. In den wkdbooks liegen dann Symlinks
  auf die Originale aus `$NVIM_CONFIG/docs`.
- Im Zweifelsfall nachfragen, es sind aber idR genug Files vorhanden, um
  Ableitungen zu treffen.
- `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/TOOLS/TOOL-PLACEMENT.md`
  beachten (Tool bauen vs. Wegwerf-Skript, wohin damit); ebenso
  `.../TOOLS/lua-plugin-tools.md`. Entsteht im Zuge einer Task ein
  wiederverwendbares Tool, an geeigneter Stelle in `TOOLS/` ablegen.
- `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/HEREDOC.md` beachten:
  keine großen/escape-haltigen Literale durch die Shell jagen.

## Bindings

- Wird ein Keybinding geändert/hinzugefügt, ggf.
  `$NVIM_CONFIG/docs/NOTES/BINDINGS` aktualisieren.

## Docs/README-Pflege

- README/Docs aktualisieren, sofern es inhaltlich Sinn ergibt.

## Git

- Keine Co-Autorenschaft von Claude in Commits.
- Nach Abschluss einer Aufgabe sofort committen/pushen (und ggf. vorher
  pullen) im main branch, damit die Änderung sofort nutzbar ist.
