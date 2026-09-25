# Globale Claude-Code-Regeln (Stefan Bartl)

Diese Datei ist die Quelle der Wahrheit und wird per `setup-claude-code.ps1`
nach `~/.claude/CLAUDE.md` verlinkt (bzw. kopiert, falls kein Symlink möglich
ist). Änderungen hier -> committen/pushen -> auf den anderen Rechnern pullen
und Setup-Skript erneut laufen lassen (bei Symlink reicht sogar nur `git
pull`).

Diese Datei ist bewusst stack-neutral. Stack-spezifische Regeln (Lua/Nvim,
Rust, C++, Web/Tauri) stehen in der `CLAUDE.md` des jeweiligen Repos
(Vorlagen: `$NVIM_CONFIG/docs/NOTES/CDX/templates/`, ausrollen mit
`node new-project-claude.js <stack>`).

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
- `$NVIM_CONFIG` - `vim.fn.stdpath('config')`, also das nvim-Config-Repo. Wird
  vom Setup-Skript automatisch aus dessen eigenem Pfad ermittelt.

## Doku-Struktur (nicht verwechseln)

- Repo-Docs (README, Feature-Docs) -> für Endnutzer, im jeweiligen Repo.
- `$NVIM_CONFIG/docs` -> Reports, Handover-Files (Originale).
- `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/**` bzw.
  `.../Development/**` -> Backlogs, interne Notizen, Roadmaps, Features -
  alles was Endnutzer nicht betrifft. In den wkdbooks liegen dann Symlinks
  auf die Originale aus `$NVIM_CONFIG/docs`.
- Im Zweifelsfall nachfragen, es sind aber idR genug Files vorhanden, um
  Ableitungen zu treffen.
- `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/TOOLS/TOOL-PLACEMENT.md`
  beachten (Tool bauen vs. Wegwerf-Skript, wohin damit). Entsteht im Zuge
  einer Task ein wiederverwendbares Tool, an geeigneter Stelle in `TOOLS/`
  ablegen.
- `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/HEREDOC.md` beachten:
  keine großen/escape-haltigen Literale durch die Shell jagen.

## Docs/README-Pflege

- README/Docs aktualisieren, sofern es inhaltlich Sinn ergibt.

## Git

- Keine Co-Autorenschaft von Claude in Commits.
- Nach Abschluss einer Aufgabe sofort committen/pushen (und ggf. vorher
  pullen) im main branch, damit die Änderung sofort nutzbar ist.
