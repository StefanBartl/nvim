# Tasks und Pläne (tasks.nvim)

Tasks sind Markdown-Dateien im Vault `$REPOS_DIR/tasks-vault/` (Repo `tasks-vault`, nicht WKDBooks): Frontmatter (Pflicht nur `title`, `status`) + Body (`## Kontext` / `## Akzeptanz` / `## Notizen`; mit `--lang=en` `Context` / `Acceptance` / `Notes`). Eine Task = ein Ergebnis.
Begriffe: `status` = open, doing, blocked, decision (wartet auf mich), parked (zurückgestellt, nicht anfassen), done (nur im `Backlog/`). `actor` = wer es erledigt: `cdx` = ein Agent (du), `me` = ich (Entscheidungen, Live-Tests, Konten, Veröffentlichen), `pair` = Entwurf von dir, Antwort von mir; leer = nicht eingeordnet. „Bereit“ = kein offener Blocker (`show` zeigt `readiness`).

**Zwei Vaults.** Arbeit bei Tricentis (Rückfragen, Folgearbeit aus Fällen, KB-Artikel, VDI/Horizon, Lernen, Zeit, Meetings) liegt in `$REPOS_DIR/tricentis-vault` (Areas `SAP-Support`, `CS`, `Horizon`, `Learning`, `Tricentis`, `Meetings`, `ALL`), die Entwicklung der Werkzeuge (Plugins, nvim-config, tasks-desktop, docmap-desktop) im `tasks-vault`. Die CLI ist dieselbe, nur `--vault=` wechselt. Bei casedesk: Arbeit **am Plugin** casedesk.nvim (Code, Bug, Feature, Doku) → `tasks-vault`, Area `casedesk.nvim`; Arbeit **aus einem Fall** (nächster Schritt, Rückfrage, Wiedervorlage) → `tricentis-vault`, Area `SAP-Support` bzw. `CS`, mit den Konventionen von `:Case task new` (`$REPOS_DIR/casedesk.nvim/docs/tasks.md`). Im tricentis-vault: ein Fall wird nie eine Task, der Fall-Bezug ist nur das Tag `sap-<nr>` / `cs-<nr>`, keine Kundendaten (Firma, Kontakt, Fall-Titel, Log-Inhalte). Details: `CLAUDE.md` im WKDBook-Tricentis.

## Erkennen

- Task: ID `<area>/<slug>` (z. B. `casedesk.nvim/ki-datenfreigabe-klaeren`) oder Pfad `…\<area>\ROADMAP\tasks\<slug>.md` (auch Ordner-Task `…\tasks\<slug>\<slug>.md`). Plan: `…\ROADMAP\plans\<slug>.md`. Erledigt: `…\<area>\Backlog\TASKS|FEATURES\<datum>_<slug>….md` (ID ohne Datum; nicht neu starten; lesen mit `list --done`, `show` findet sie nicht; ohne klaren Auftrag kurz zusammenfassen und nachfragen).
- `<area>` = Ordner im Vault: Plugin, `nvim-config`, `docmap-desktop`, `ALL` (plugin-übergreifend); `areas` listet sie. Unbekannte Area nicht anlegen, nachfragen.
- **Anlegen statt merken:** Lautet die Aufgabe „leg eine Task/einen Plan an“, „erfasse“, „merk vor“, „Roadmap-Eintrag“, oder fällt dir beim Arbeiten Restarbeit, ein Bug oder eine Idee auf, die du nicht sofort erledigst, wird sie eine Task (Trivialfixes im selben Bereich erledigst du direkt). Offene Arbeit steht nie als Absatz oder Liste in `ROADMAP.md`, `NOTES/`, Handover oder Chat, dort nur die Task-ID. Das Anlegen ersetzt kein `spawn_task`: erst die Task, dann nur auf Wunsch eine Chip-Task mit der ID im Prompt. Roadmap-Einträge nur im Vault, nie im Plugin-Repo.

## CLI (headless, ohne Editor)

`nvim --headless -u NONE -l $REPOS_DIR/tasks.nvim/scripts/tasks.lua <befehl> … --vault=$REPOS_DIR/tasks-vault` (`--help` zeigt alles; `lib.nvim` über `LIB_NVIM_DIR`, sonst `$REPOS_DIR/lib.nvim`). Absoluter Pfad, nicht dafür in andere Repos `cd`en. In PowerShell `$env:REPOS_DIR`; Werte mit `[ ]` oder `,` in Anführungszeichen: `set <id> "blocked_by=[a/b,c/d]"`. Langtext nie durch die Shell (`HEREDOC.md`), sondern mit dem Edit-Tool in die Datei. Exit 0 / 1 (Fehler) / 2 (falsche Nutzung).

- Lesen: `show <id>`, `list [<area>] --status=open,doing --ready --actor=cdx --format=ids|tsv|json`, `next [<area>] --actor=cdx --n=3`, `plans`, `plan --plan=<id>|--for=<id>`, `areas`, `list --done`.
- Ändern: `set <id> key=value …` (leerer Wert entfernt den Key; ersetzt Listen komplett).
- Prüfen: `check [<area>]` (vor jedem Commit von Vault-Dateien; Warnungen ändern den Exit-Code nicht, eigene trotzdem beheben; fremde Befunde nicht beheben, in einer Zeile melden). `ROADMAP/TASKS.md` ist generiert (`new`/`set`/`done` schreiben es), nie von Hand.

## Task bearbeiten

1. `show <id>` und die Datei komplett lesen (`blocked_by`, `refs`, `## Plan`-Schritte). Ohne ID („nächste Task“): `next <area-des-Repos> --actor=cdx --n=1`; meldet es `empty:`, mir das sagen, keine fremden Tasks nehmen.
2. Nicht selbst starten, sondern Stand melden und nachfragen bei `actor=me`, `status=decision`, `parked`, offenem Blocker oder `doing` (arbeitet jemand daran?). `actor=pair`: Entwurf liefern, Antwort abwarten. Nennt der Auftrag die ID ausdrücklich und `actor` ist leer oder `cdx`, starten. `set status=doing` verweigert nichts, es warnt nur (`warn: … is for you`): Warnung ernst nehmen, zurücksetzen und melden. Trägt die Task `on-workstation` oder `not-on-workstation`: vorher die Maschine prüfen (`$env:NVIM_MACHINE_ROLE`: `workstation` = Tricentis-Workstation, sonst privater Rechner); passt sie nicht, nicht starten, nur vorbereiten und melden.
3. `set <id> status=doing`. Arbeiten; Body (Notizen, Akzeptanz abhaken) und Plan-Datei darfst du editieren, Frontmatter nur per `set`.
4. Code committen/pushen, dann `done <id> --commits=<repo>@<sha>,<repo>@<sha>` mit **allen** Commits, die für die Task entstanden sind (auch in anderen Repos und Fix-Commits nach einem Review; `<sha>` 7–40 Hex; die Vault-Commits der Task selbst gehören nicht dazu). `commits` ist ein Listenfeld: Commits schon während der Arbeit mit `set <id> "commits=[repo@sha,repo@sha]"` mitführen (ersetzt die Liste), `done --commits` ergänzt sie. `--done-in=` bleibt Freitext (z. B. „siehe Notizen“). Ohne Code: `--commits` weglassen, Ergebnis in `Notizen`. Nie `status=done` setzen oder Dateien von Hand verschieben. `done` meldet `freed:` (frei gewordene Tasks) und `next:`/`cdx:` (was als Nächstes ansteht): mir beides nennen. Waren frei gewordene Tasks noch `status=blocked`, `--unblock` nutzen oder `set <id> status=open`.
5. Vault-Änderungen (Task, Plan, `done`) sofort auf main committen und pushen (vorher pullen, kein PR), unabhängig vom Code-Commit; steht dann in der Commit-Liste mit Repo `tasks-vault`. Meldet `done` „changed while it was being finished“: Datei neu lesen, wiederholen.

## Task anlegen

`new <area> "<Titel>" [--slug=] [--kind=bug|feature|task] [--prio=1..3] [--effort=XS..XL|0.5d] [--value=1..5] [--actor=cdx|me|pair] [--tags=a,b] [--category=bug,security,performance,docs,ruleset] [--severity=low..critical] [--after=<id>,<id>] [--plan=<plan-id> --phase=<wort>] [--refs=pfad,repo@sha] [--summary="…"] [--lang=de|en] [--folder]` (Rest: `new --help`). Die ID steht in der `created`-Zeile (bei Slug-Kollision `-2`).

- Nur der Titel ist Pflicht; `prio`/`effort`/`actor` nicht raten (`actor` nur, wenn ich es sage oder es offensichtlich ist). Bug: `--kind=bug` mit Fundstelle (Datei, `repo@sha`) im Kontext.
- Danach die Datei ausfüllen: erste Textzeile = Zusammenfassung (landet im Index; oder `--summary`), dann `Kontext` / `Akzeptanz` (Checkboxen) / `Notizen`. `--lang` setzt du selbst (Default `de`, keine Erkennung): bei englischen Areas `--lang=en`. Frontmatter-Keys und Statuswerte immer Englisch.
- **Reihenfolge ist Daten, nie Fließtext** („siehe Task X“): `blocked_by` per `set` (hart, geht sonst nicht, auch Area-übergreifend; setzt auch `status=blocked`) oder `--after` (weich, geht auch ohne). Im Zweifel weich. Referenzierte IDs müssen existieren (sonst `check`-Fehler): erst die Tasks ohne Abhängigkeit anlegen, dann die abhängigen. Mehrere Punkte (Brain-Dump): jeder eine eigene Task, Titel reicht, Sortieren später.
- Braucht ein Punkt meine Entscheidung: eigene Task `status=decision actor=me` (Frage, Optionen, Empfehlung im Kontext); die Umsetzung nennt sie in `blocked_by`.
- Teilschritte ohne eigenen Abnahmetest/Blocker: Checkboxen `## Plan` im Task-Body (`- [ ] 1. Schritt -- Acceptance 2`). Mit eigenem Test oder Blocker: eigene Task.
- Anhänge: `attach <id> <datei>` (macht aus einer einfachen Task selbst eine Ordner-Task, Pfad ändert sich) und den ausgegebenen Link in den Body setzen.

## Plan anlegen

Nur für ein Vorhaben aus mehreren Tasks in Etappen mit eigenem Ziel (nicht für eine Task oder einen Brain-Dump). Etappen/Ziel aus der Aufgabe ableiten; sind sie nicht ableitbar, mir einen Vorschlag machen, bevor `plan-new` läuft.

1. `plan-new <area> "<Titel>" --phases=a,b,c [--areas=a,b] [--target=<id>] [--gate=hard] [--summary="…"]` legt `ROADMAP/plans/<slug>.md` an. Plugin-übergreifend: Area `ALL` und `--areas=`. `--gate=hard` (Etappe wartet auf die vorige) nur, wenn ich harte Reihenfolge will.
2. Die Plan-Datei hält nur, was ein Mensch begründet (Ziel, Abgrenzung, Definition of done, Entscheidungen), **keine Task-Liste**.
3. Tasks liegen in der Area ihres Plugins und tragen `plan=<area>/<slug> phase=<wort>` (volle ID aus `plans`/`created`, Plan muss vorher existieren, `phase` aus `--phases`). `plan --plan=<id>` zeigt Etappen, Bereites, kritischen Pfad; `plan --for=<id>` „was brauche ich vor X“.

## Verboten

- Nicht aus einer Claude-Sitzung: `tasks-hub install|start|autostart` (die Claude-App leitet AppData und HKCU um, ich sehe nichts davon).
- Kein `status=done`/Verschieben von Hand, kein `TASKS.md` von Hand, keine Roadmap-Einträge im Plugin-Repo.
