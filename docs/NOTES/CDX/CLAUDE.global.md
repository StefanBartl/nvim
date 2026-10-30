# Globale Claude-Code-Regeln (Stefan Bartl)

Diese Datei ist die Quelle der Wahrheit und wird per `setup-claude-code.ps1`
nach `~/.claude/CLAUDE.md` verlinkt (bzw. kopiert, falls kein Symlink möglich
ist). Änderungen hier -> committen/pushen -> auf den anderen Rechnern pullen
und Setup-Skript erneut laufen lassen (bei Symlink reicht sogar nur `git
pull`).

Diese Datei ist bewusst stack-neutral. Stack-spezifische Regeln (Lua/Nvim,
Rust, C++, Web/Tauri) stehen in der `CLAUDE.md` des jeweiligen Repos
(Vorlagen: `$NVIM_CONFIG_DIR/docs/NOTES/CDX/templates/`, ausrollen mit
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
- Geteilte Checkouts: In den Repos unter `$REPOS_DIR` arbeiten oft mehrere
  Sitzungen gleichzeitig. Fremde uncommittete Änderungen nie committen,
  stashen, zurücksetzen oder formatieren; nur eigene Dateien mit Pfad stagen
  (nie `git add -A`/`.`, `commit -a`). Änderungen über viele Repos nur auf
  sauberem Baum, je Repo Suite grün vor dem Commit; schmutzige Repos
  auslassen, in der Task notieren und später nachziehen.

## Env-Variablen

Werden von `setup-claude-code.ps1` pro Maschine gesetzt (User-Scope):

- `$REPOS_DIR` - Wurzel aller Repos (u.a. alle eigenen `.nvim`-Plugins unter
  `$REPOS_DIR/repos`). Wert ist pro Maschine unterschiedlich.
- `$NVIM_CONFIG_DIR` - `vim.fn.stdpath('config')`, also das nvim-Config-Repo. Wird
  vom Setup-Skript automatisch aus dessen eigenem Pfad ermittelt (der alte Name
  `$NVIM_CONFIG` wird mit demselben Wert weiter gesetzt).
- `$RULES_VAULT` - Wurzel des Repos `rules-vault` (die Regelwerke: `rulesets/lua`
  mit `regeln/`, `gates/`, `belege/`, `nachschlagen/` und `rulesets/native`). Wird
  gesetzt, wenn `$REPOS_DIR/rules-vault` existiert; sonst Repo klonen und das
  Setup-Skript erneut laufen lassen.
- `$TESTING_TRUST_ROOTS` - Wurzeln, unter denen testing.nvim Projekten vertraut
  (Default `$REPOS_DIR`). Ohne sie enden lokale Läufe (`scripts/test.sh`,
  `:Testing`) mit Exit 2, weil `.testing.lua` erst nach Vertrauen ausgeführt
  wird; die CI vertraut über `CI=true`.
- `$NVIM_MACHINE_ROLE` - `workstation` auf der Tricentis-Workstation, sonst
  nicht gesetzt (= privater Rechner). Dieselbe Variable liest `lua/machine.lua`
  der nvim-Config. Das Setup-Skript setzt sie nie, es zeigt sie nur an: auf einer
  (neuen) Workstation einmal von Hand setzen (`setx NVIM_MACHINE_ROLE workstation`,
  siehe `WORKFLOW.md` Abschnitt 4) und die App neu starten.

## Maschine: Workstation oder privater Rechner

- `$NVIM_MACHINE_ROLE` (dieselbe Variable wie in `lua/machine.lua` der
  nvim-Config): `workstation` = Tricentis-Workstation (dort darf nichts
  Unsigniertes gebaut, installiert oder gestartet werden, EDR/Falcon; auch kein
  Runner); nicht gesetzt oder `default` = privater Rechner (`STEVESPC`: Builds,
  Tests, Runner). Groß-/Kleinschreibung egal. Lesen in PowerShell mit
  `$env:NVIM_MACHINE_ROLE`, in Bash mit `$NVIM_MACHINE_ROLE` (`$env:…` gibt es in
  Bash nicht, dort kommt das Literal `:NVIM_MACHINE_ROLE` heraus). Jeder andere
  Wert als `workstation`, `default` oder leer: falsch gelesen oder Tippfehler,
  nachfragen. Nicht aus dem Rechnernamen raten. Ist sie nicht gesetzt, aber
  `USERDOMAIN` ist `AzureAD` oder der Rechnername (`COMPUTERNAME`) beginnt mit
  `TRI-`: unklar, nachfragen, bevor etwas gebaut oder gestartet wird (die App
  kennt eine neu gesetzte Variable erst nach einem Neustart).
- Tags an Tasks: `on-workstation` = nur dort ausführbar (Handläufe,
  Messungen auf der Workstation); `not-on-workstation` = nie dort (native
  Programme bauen/installieren/starten, Runner, Tests und Builds der nativen
  Apps). Ohne Tag: Code-Arbeit, läuft auf dem privaten Rechner.
- Vor dem Bearbeiten einer Task mit einem dieser Tags (und bei Aufträgen, die
  Workstation, Falcon oder EDR betreffen) zuerst `NVIM_MACHINE_ROLE` lesen (wie
  oben) und in einer Zeile nennen („Maschine: privat“ bzw. „Workstation“). Passt der
  Rechner nicht zum Tag: nichts ausführen, nur vorbereiten und mir Bescheid
  geben. Fällt beim Arbeiten ein Workstation-Bezug auf, den die Task nicht
  kennzeichnet, den Tag nachziehen.

## Doku-Struktur (nicht verwechseln)

- Repo-Docs (README, Feature-Docs) -> für Endnutzer, im jeweiligen Repo.
- `$REPOS_DIR/tasks-vault/<area>` -> Reports und Handover-Files (Originale);
  in `$NVIM_CONFIG_DIR/docs` liegen nur Symlinks darauf.
- `$REPOS_DIR/tasks-vault/**` bzw.
  `.../Development/**` -> Backlogs, interne Notizen, Roadmaps, Features -
  alles was Endnutzer nicht betrifft.
- Im Zweifelsfall nachfragen, es sind aber idR genug Files vorhanden, um
  Ableitungen zu treffen.
- `$REPOS_DIR/tasks-vault/TOOLS/TOOL-PLACEMENT.md`
  beachten (Tool bauen vs. Wegwerf-Skript, wohin damit). Entsteht im Zuge
  einer Task ein wiederverwendbares Tool, an geeigneter Stelle in `TOOLS/`
  ablegen.
- `$REPOS_DIR/tasks-vault/HEREDOC.md` beachten:
  keine großen/escape-haltigen Literale durch die Shell jagen.

## Docs/README-Pflege

- README/Docs aktualisieren, sofern es inhaltlich Sinn ergibt.

## Git

- Keine Co-Autorenschaft von Claude in Commits.
- Nach Abschluss einer Aufgabe sofort committen/pushen (und ggf. vorher
  pullen) im main branch, damit die Änderung sofort nutzbar ist.
- Am Ende jeder Ausgabe gibst du eine laufende Liste aller Commits des Chats aus mit kurzer Beschreibung + welches Repository. Jedes bekomtm einen grünen Haken, wenn das Commit durch einen `ultracode`-Agenten reviewd wurden.
