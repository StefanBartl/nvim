
Erledige fokgendes:

1. uncomittete änderungen in tasks-desktop comitten, die ommen sehr wrsch von hier:

```markdown
Jetzt verschiebe ich das Konzept per Skriptdatei (wegen der Backslash-Falle nicht über die Shell): Der Abschnitt wandert nach `ALL/`, die Task behält einen Verweis und bekommt die Plan-Schritte.

Die Warnung in `ALL` kommt nicht aus meiner Task, sondern von einer anderen, die auf eine geparkte Aufgabe wartet. In meiner Task behebe ich die Warnung jetzt, indem ich den Akzeptanzpunkten 1 und 2 (Konzept, Entscheidungen) einen erledigten Plan-Schritt zuordne.

Der Vault ist gepusht (`9de0db60`), Konzept und Bau-Task sind bereit. Jetzt gehe ich zu Etappe 1 und schaue mir die Plan-Ansicht sowie die Abhängigkeiten im Fixture für den Browser-Test an.

Jetzt der reine Kern: `lib/depGraph.ts` mit Reihen, Kanten, Reihenfolge per Baryzentrum und Kreuzungszählung. Erst prüfe ich, ob es den Namen schon gibt:

Die Unit-Tests für den Kern:

Der Kern ist grün (6 Tests). Jetzt der Zustand in der App, „Stufen“ oder „Graph“ im Browser gemerkt:

Ich erstelle jetzt die Komponente `PlanGraph.svelte`: Die Kacheln werden als fokussierbare HTML-Knöpfe umgesetzt, die Pfeile als SVG-Overlay darüber, das nach jedem Rendern und bei Größenänderung aus den Kachel-Positionen berechnet wird. Für die Tastaturbedienung nutze ich einen wandernden `tabindex`, ergänzt um eine Tabellen-Darstellung der Kanten darunter.

Jetzt die Einbindung in `PlanView`: Umschalter in der Toolbar, und im Graph-Modus `PlanGraph` statt der Stufen-Karten.

Ich übernehme den vorhandenen Stil aus `GraphPanel` (gedrückt = Akzent-Rand), statt eigene Farben zu erfinden:

Jetzt die Texte, Englisch und Deutsch:

Typprüfung ist grün. Jetzt teste ich im Browser gegen das Fixture (beta/iota warten auf alpha, cyc-a/cyc-b bilden einen Zyklus) und hänge kurz einen Screenshot an, um mir die Zeichnung selbst anzusehen.

Axe meldet im Dunkel-Modus zu wenig Kontrast (4,38 statt 4,5), vermutlich durch mein `opacity: 0.75` für wartende Tasks. Ich schaue mir zuerst den Screenshot an.
```


2. task hier offenes ereldogen:

```text
```markdown
Zuerst wird der Stand von tasks-desktop geprüft.

Es gibt nichts Uncommittetes (alle drei Repos sauber). Nun werden die Tasks aus dem anderen Branch geholt.

Zwischenstand: Es gab nichts zu committen. Der Prio-1-Bug (Bereich-Filter) wird gerade untersucht. Dazu wird geprüft, woher `app.areaNames` kommt.

Kurzer Zwischenstand: `pnpm install` scheitert am Abruf von appkit (403, Repo nicht im Session-Scope). Ich versuche, appkit per `add_repo` hinzuzufügen, damit Typecheck und Tests laufen können.

Ich habe die Ursache des Prio-1-Bugs gefunden: Die tasks-desktop-Tasks liegen im Bereich „wkdbook-tasks.nvim", der nur als „tasks.nvim" angezeigt wird, während der Hinweis auf tasks-desktop lediglich im Tooltip steckt. Jetzt setze ich eine sichtbare Beschriftung samt Test um.

Weiter mit Task 4 (Hilfe-Tab: „Über“ und „Fehler melden“).

Kurze Info: Hilfe-Dialog ist getrennt, jetzt werden Unit- und E2E-Tests angepasst.

Weiter mit Task 3 (Hover-Hinweise der Menü-Einträge).

Mir fehlt in appkit (`MenuBar`) das Feld `hint` für Menü-Einträge, und laut CLAUDE.md muss diese Änderung zuerst dort erfolgen. Ich prüfe jetzt, ob ich appkit mit Schreibrechten einbinden kann.

appkit ist mit Schreibzugriff angehängt. Ich klone es und baue die appkit-Änderung (Hint an Menü-Einträgen) auf dem Session-Branch.

Zwischenstand: appkit-Änderung (Hint an Menü-Einträgen) ist umgesetzt, Test grün. Jetzt Sabotage-Probe, Kit-Prüfungen und Doku.

Zwischenstand: Tasks 5, 4 und 3 sind committet (3 wartet auf ein appkit-Tag). Jetzt Task 2: Verbindungen-Graph als eigene, größenveränderliche Kachel.

Kurz: Ich baue gerade die eigene Kachel „Netz der Bereiche“ in der Verbindungen-Ansicht (größenveränderlich, Größe wird gespeichert).

Task 1 (Ordner-Dialog): Ein Browser kann keinen nativen Ordner-Dialog öffnen, also muss der Hub ihn aufmachen. Ich schaue mir die bestehende Vault-Route und das „Reveal“ im Hub an.

Kurz: Rust baut hier. Ich implementiere den Ordner-Dialog im Hub (Route `vault_pick`, plattformspezifische Auswahl per Windows-PowerShell/macOS-osascript/zenity-kdialog).

Kurz: Hub-Teil für den Ordner-Dialog ist grün. Als Nächstes folgt die Oberfläche (Knopf im Vault-Dialog), danach Clippy und Fmt.

Kurz: Ich verdrahte den Ordner-Dialog jetzt von der API über den State bis zum Knopf im Vault-Dialog.

Alle drei Pushes sind durch. Ich prüfe noch, ob die CI auf dem Branch läuft.

Es gibt keine CI-Läufe auf dem Branch (die Workflows laufen vermutlich nur auf `main` und bei PRs).

## Stand

Uncommittete Änderungen gab es zu Beginn in keinem der drei Repos. Von den fünf Tasks sind vier fertig committet und gepusht. Die Hover-Hinweise für Menü-Einträge brauchen noch ein appkit-Tag, bevor tasks-desktop sie bauen kann.

- **Nicht gelaufen:** Die Browser-Tests (`pnpm e2e`) liefen hier nicht, weil `nvim` fehlt. Die neuen und geänderten E2E-Tests sind nur geschrieben, nicht ausgeführt.
- **Grün gelaufen:** `pnpm check`, `pnpm test` (668), `cargo fmt`, `clippy -D warnings`, `cargo test --workspace` und beide Hygiene-Skripte.
- **Typecheck-Einschränkung:** `pnpm check` lief gegen einen lokalen Link auf appkit, nicht gegen das gepinnte Tag.
- **Sabotage-Probe:** Ich habe sie nur für die appkit-Änderung gemacht, nicht für die tasks-desktop-Fixes. Die neuen Tests rufen aber neue Funktionen oder Routen auf und wären ohne den Fix schon deshalb rot.
- **Branch statt `main`:** Alles liegt auf dem Session-Branch `claude/tasks-desktop-vault-ui-0d62rk`, nicht auf `main`.
- **CI:** Auf diesem Branch läuft keine.

## Die Tasks

| Task | Ergebnis |
|---|---|
| Bereich-Filter (Prio 1) | Die Tasks von tasks-desktop liegen im Bereich `wkdbook-tasks.nvim`, der als „tasks.nvim“ angezeigt wird. Der Filter listet nur Bereiche mit Tasks, und der Hinweis „auch tasks-desktop“ stand nur im Tooltip und in der Suche. Jetzt steht „tasks.nvim (tasks-desktop)“ sichtbar in der Liste (`areaOptions` in `filter.ts`, mit Unit-Test). Ein eigener Bereich oder ein `extra_areas`-Eintrag ist nicht nötig. |
| Hilfe-Tab | „Über“ zeigt nur Version, Build und Engine. „Fehler melden“ zeigt nur das Formular und verlinkt die Issues von tasks-desktop, tasks.nvim und appkit. |
| Verbindungen-Kachel | Der Kreisgraph ist eine eigene Kachel „Netz der Bereiche“ mit Größen-Griff. Die Größe bleibt unter `cross-net` erhalten, und die Zeichnung wächst mit der Kachel. |
| Ordner-Dialog | Neuer Hub-Endpunkt `POST /api/tasks/vault_pick`. Er öffnet auf dem Rechner des Hubs PowerShell (Windows), `osascript` (macOS) oder `zenity`/`kdialog` (Linux). Im Vault-Dialog steht neben dem Pfadfeld ein Knopf „Auswählen ...“. Das Feld bleibt von Hand änderbar. Die Sicherheitsdoku ist ergänzt. |
| Hover-Hinweise | Alle Einträge aller Menüs haben jetzt Hinweise auf Deutsch und Englisch. appkit kannte bisher nur Hinweise an den Menüs selbst, nicht an Einträgen. Ich habe das dort ergänzt (`hint` an Menü-Einträgen, mit Test, Commit `e990d93`, Branch `claude/tasks-desktop-vault-ui-0d62rk`). |

## Offen

- **appkit-Tag für die Hover-Hinweise:** tasks-desktop nutzt das neue `hint`-Feld, aber gepinnt ist noch `v0.19.1`. Mit dem Pin schlägt dort der Typecheck fehl. appkit wird nur nach `docs/RELEASING.md` veröffentlicht (CI grün auf `main`, dann Tag). Ich habe weder Tag noch Merge nach `main` gemacht. Danach wären Tag-Bump, `cargo update -p appkit-hub`, `pnpm install` und `check-appkit-pin.py` in tasks-desktop nötig.
- **Tasks abschließen:** Die fünf Tasks sind noch nicht auf `done` gesetzt, weil hier kein `nvim` für die CLI vorhanden ist. Befehl, wenn gewünscht: `done <id> --commits=tasks-desktop@<sha>` mit den Commits aus der Tabelle unten. Die Hover-Task erst nach dem Tag.
- **Windows-Test:** Der Ordner-Dialog ist unter Windows nur über die Planfunktion getestet, nicht mit einem echten Dialog. Das Pfadfeld füllt sich, aber ob das Fenster vorne erscheint, sollte jemand dort einmal prüfen.

## Neue Commits

| Haken | Repo | Commit | Beschreibung |
|---|---|---|---|
| – | tasks-desktop | 243af3f | Bereich-Filter nennt tasks-desktop sichtbar |
| – | tasks-desktop | 3db0519 | Hilfe: „Über“ und „Fehler melden“ getrennt, Repo-Links |
| – | tasks-desktop | 4c364cc | Hover-Hinweise an allen Menü-Einträgen (wartet auf appkit-Tag) |
| – | tasks-desktop | 41f9e36 | Netz der Bereiche als eigene, größenveränderliche Kachel |
| – | tasks-desktop | 343c98f | Ordner-Dialog für den Vault-Pfad (Hub-Route plus Knopf) |
| – | appkit | e990d93 | `hint` an Menü-Einträgen |
| – | tasks-vault | (Merge) | die fünf Tasks aus `claude/dependencies-view-component-awj4tk` auf diesen Branch geholt |

Keiner der Commits wurde mit höherem Reasoning-Faktor geprüft, also gibt es keine grünen Haken oder Sterne.```


```markdown
# Vorgaben/Richtlinien/Guiding

## Allgemeines Verhalten

- Nie mehr als 1 Agent gleichzeitig starten; werden mehrere benötigt, nacheinander in mehreren Runden ausführen, die nie mehr als diese Anzahl an Agents verwenden.
- Immer auf Deutsch antworten; im Quellcode (Code, Kommentare usw.) immer Englisch verwenden.
- Immer ausgeben, was gerade gemacht wird / ob es etwas Interessantes gab – damit ich Bescheid weiß.
- Wenn Chip-Tasks angelegt werden, diese bitte ebenfalls auf Deutsch verfassen.

## Tasks und Pläne (tasks.nvim)

Tasks sind Markdown-Dateien im Vault `$REPOS_DIR/tasks-vault/` (Repo `tasks-vault`, nicht WKDBooks): Frontmatter (Pflicht nur `title`, `status`) + Body (`## Kontext` / `## Akzeptanz` / `## Notizen`; mit `--lang=en` `Context` / `Acceptance` / `Notes`). Eine Task = ein Ergebnis.
Begriffe: `status` = open, doing, blocked, decision (wartet auf mich), parked (zurückgestellt, nicht anfassen), done (nur im `Backlog/`). `actor` = wer es erledigt: `cdx` = ein Agent (du), `me` = ich (Entscheidungen, Live-Tests, Konten, Veröffentlichen), `pair` = Entwurf von dir, Antwort von mir; leer = nicht eingeordnet. „Bereit“ = kein offener Blocker (`show` zeigt `readiness`).

**Zwei Vaults.** Arbeit bei Tricentis (Rückfragen, Folgearbeit aus Fällen, KB-Artikel, VDI/Horizon, Lernen, Zeit, Meetings) liegt in `$REPOS_DIR/tricentis-vault` (Areas `SAP-Support`, `CS`, `Horizon`, `Learning`, `Tricentis`, `Meetings`, `ALL`), die Entwicklung der Werkzeuge (Plugins, nvim-config, tasks-desktop, docmap-desktop) im `tasks-vault`. Die CLI ist dieselbe, nur `--vault=` wechselt. Bei casedesk: Arbeit **am Plugin** casedesk.nvim (Code, Bug, Feature, Doku) → `tasks-vault`, Area `casedesk.nvim`; Arbeit **aus einem Fall** (nächster Schritt, Rückfrage, Wiedervorlage) → `tricentis-vault`, Area `SAP-Support` bzw. `CS`, mit den Konventionen von `:Case task new` (`$REPOS_DIR/casedesk.nvim/docs/tasks.md`). Im tricentis-vault: ein Fall wird nie eine Task, der Fall-Bezug ist nur das Tag `sap-<nr>` / `cs-<nr>`, keine Kundendaten (Firma, Kontakt, Fall-Titel, Log-Inhalte). Details: `CLAUDE.md` im WKDBook-Tricentis.

### Erkennen

- Task: ID `<area>/<slug>` (z. B. `casedesk.nvim/ki-datenfreigabe-klaeren`) oder Pfad `…\<area>\ROADMAP\tasks\<slug>.md` (auch Ordner-Task `…\tasks\<slug>\<slug>.md`). Plan: `…\ROADMAP\plans\<slug>.md`. Erledigt: `…\<area>\Backlog\TASKS|FEATURES\<datum>_<slug>….md` (ID ohne Datum; nicht neu starten; lesen mit `list --done`, `show` findet sie nicht; ohne klaren Auftrag kurz zusammenfassen und nachfragen).
- `<area>` = Ordner im Vault: Plugin, `nvim-config`, `docmap-desktop`, `ALL` (plugin-übergreifend); `areas` listet sie. Unbekannte Area nicht anlegen, nachfragen.
- **Anlegen statt merken:** Lautet die Aufgabe „leg eine Task/einen Plan an“, „erfasse“, „merk vor“, „Roadmap-Eintrag“, oder fällt dir beim Arbeiten Restarbeit, ein Bug oder eine Idee auf, die du nicht sofort erledigst, wird sie eine Task (Trivialfixes im selben Bereich erledigst du direkt). Offene Arbeit steht nie als Absatz oder Liste in `ROADMAP.md`, `NOTES/`, Handover oder Chat, dort nur die Task-ID. Das Anlegen ersetzt kein `spawn_task`: erst die Task, dann nur auf Wunsch eine Chip-Task mit der ID im Prompt. Roadmap-Einträge nur im Vault, nie im Plugin-Repo.

### CLI (headless, ohne Editor)

`nvim --headless -u NONE -l $REPOS_DIR/tasks.nvim/scripts/tasks.lua <befehl> … --vault=$REPOS_DIR/tasks-vault` (`--help` zeigt alles; `lib.nvim` über `LIB_NVIM_DIR`, sonst `$REPOS_DIR/lib.nvim`). Absoluter Pfad, nicht dafür in andere Repos `cd`en. In PowerShell `$env:REPOS_DIR`; Werte mit `[ ]` oder `,` in Anführungszeichen: `set <id> "blocked_by=[a/b,c/d]"`. Langtext nie durch die Shell (`HEREDOC.md`), sondern mit dem Edit-Tool in die Datei. Exit 0 / 1 (Fehler) / 2 (falsche Nutzung).

- Lesen: `show <id>`, `list [<area>] --status=open,doing --ready --actor=cdx --format=ids|tsv|json`, `next [<area>] --actor=cdx --n=3`, `plans`, `plan --plan=<id>|--for=<id>`, `areas`, `list --done`.
- Ändern: `set <id> key=value …` (leerer Wert entfernt den Key; ersetzt Listen komplett).
- Prüfen: `check [<area>]` (vor jedem Commit von Vault-Dateien; Warnungen ändern den Exit-Code nicht, eigene trotzdem beheben; fremde Befunde nicht beheben, in einer Zeile melden). `ROADMAP/TASKS.md` ist generiert (`new`/`set`/`done` schreiben es), nie von Hand.

### Task bearbeiten

1. `show <id>` und die Datei komplett lesen (`blocked_by`, `refs`, `## Plan`-Schritte). Ohne ID („nächste Task“): `next <area-des-Repos> --actor=cdx --n=1`; meldet es `empty:`, mir das sagen, keine fremden Tasks nehmen.
2. Nicht selbst starten, sondern Stand melden und nachfragen bei `actor=me`, `status=decision`, `parked`, offenem Blocker oder `doing` (arbeitet jemand daran?). `actor=pair`: Entwurf liefern, Antwort abwarten. Nennt der Auftrag die ID ausdrücklich und `actor` ist leer oder `cdx`, starten. `set status=doing` verweigert nichts, es warnt nur (`warn: … is for you`): Warnung ernst nehmen, zurücksetzen und melden.
3. `set <id> status=doing`. Arbeiten; Body (Notizen, Akzeptanz abhaken) und Plan-Datei darfst du editieren, Frontmatter nur per `set`.
4. Code committen/pushen, dann `done <id> --commits=<repo>@<sha>,<repo>@<sha>` mit **allen** Commits, die für die Task entstanden sind (auch in anderen Repos und Fix-Commits nach einem Review; `<sha>` 7–40 Hex; die Vault-Commits der Task selbst gehören nicht dazu). `commits` ist ein Listenfeld: Commits schon während der Arbeit mit `set <id> "commits=[repo@sha,repo@sha]"` mitführen (ersetzt die Liste), `done --commits` ergänzt sie. `--done-in=` bleibt Freitext (z. B. „siehe Notizen“). Ohne Code: `--commits` weglassen, Ergebnis in `Notizen`. Nie `status=done` setzen oder Dateien von Hand verschieben. `done` meldet `freed:` (frei gewordene Tasks) und `next:`/`cdx:` (was als Nächstes ansteht): mir beides nennen. Waren frei gewordene Tasks noch `status=blocked`, `--unblock` nutzen oder `set <id> status=open`.
5. Vault-Änderungen (Task, Plan, `done`) sofort auf main committen und pushen (vorher pullen, kein PR), unabhängig vom Code-Commit; steht dann in der Commit-Liste mit Repo `tasks-vault`. Meldet `done` „changed while it was being finished“: Datei neu lesen, wiederholen.

### Task anlegen

`new <area> "<Titel>" [--slug=] [--kind=bug|feature|task] [--prio=1..3] [--effort=XS..XL|0.5d] [--value=1..5] [--actor=cdx|me|pair] [--tags=a,b] [--category=bug,security,performance,docs,ruleset] [--severity=low..critical] [--after=<id>,<id>] [--plan=<plan-id> --phase=<wort>] [--refs=pfad,repo@sha] [--summary="…"] [--lang=de|en] [--folder]` (Rest: `new --help`). Die ID steht in der `created`-Zeile (bei Slug-Kollision `-2`).

- Nur der Titel ist Pflicht; `prio`/`effort`/`actor` nicht raten (`actor` nur, wenn ich es sage oder es offensichtlich ist). Bug: `--kind=bug` mit Fundstelle (Datei, `repo@sha`) im Kontext.
- Danach die Datei ausfüllen: erste Textzeile = Zusammenfassung (landet im Index; oder `--summary`), dann `Kontext` / `Akzeptanz` (Checkboxen) / `Notizen`. `--lang` setzt du selbst (Default `de`, keine Erkennung): bei englischen Areas `--lang=en`. Frontmatter-Keys und Statuswerte immer Englisch.
- **Reihenfolge ist Daten, nie Fließtext** („siehe Task X“): `blocked_by` per `set` (hart, geht sonst nicht, auch Area-übergreifend; setzt auch `status=blocked`) oder `--after` (weich, geht auch ohne). Im Zweifel weich. Referenzierte IDs müssen existieren (sonst `check`-Fehler): erst die Tasks ohne Abhängigkeit anlegen, dann die abhängigen. Mehrere Punkte (Brain-Dump): jeder eine eigene Task, Titel reicht, Sortieren später.
- Braucht ein Punkt meine Entscheidung: eigene Task `status=decision actor=me` (Frage, Optionen, Empfehlung im Kontext); die Umsetzung nennt sie in `blocked_by`.
- Teilschritte ohne eigenen Abnahmetest/Blocker: Checkboxen `## Plan` im Task-Body (`- [ ] 1. Schritt -- Acceptance 2`). Mit eigenem Test oder Blocker: eigene Task.
- Anhänge: `attach <id> <datei>` (macht aus einer einfachen Task selbst eine Ordner-Task, Pfad ändert sich) und den ausgegebenen Link in den Body setzen.

### Plan anlegen

Nur für ein Vorhaben aus mehreren Tasks in Etappen mit eigenem Ziel (nicht für eine Task oder einen Brain-Dump). Etappen/Ziel aus der Aufgabe ableiten; sind sie nicht ableitbar, mir einen Vorschlag machen, bevor `plan-new` läuft.

1. `plan-new <area> "<Titel>" --phases=a,b,c [--areas=a,b] [--target=<id>] [--gate=hard] [--summary="…"]` legt `ROADMAP/plans/<slug>.md` an. Plugin-übergreifend: Area `ALL` und `--areas=`. `--gate=hard` (Etappe wartet auf die vorige) nur, wenn ich harte Reihenfolge will.
2. Die Plan-Datei hält nur, was ein Mensch begründet (Ziel, Abgrenzung, Definition of done, Entscheidungen), **keine Task-Liste**.
3. Tasks liegen in der Area ihres Plugins und tragen `plan=<area>/<slug> phase=<wort>` (volle ID aus `plans`/`created`, Plan muss vorher existieren, `phase` aus `--phases`). `plan --plan=<id>` zeigt Etappen, Bereites, kritischen Pfad; `plan --for=<id>` „was brauche ich vor X“.

### Verboten

- Nicht aus einer Claude-Sitzung: `tasks-hub install|start|autostart` (die Claude-App leitet AppData und HKCU um, ich sehe nichts davon).
- Kein `status=done`/Verschieben von Hand, kein `TASKS.md` von Hand, keine Roadmap-Einträge im Plugin-Repo.

## Git-Workflow

- Wenn eine Aufgabe fertig ist: sofort committen / pushen / pullen im main-Branch, sodass ich es gleich verwenden kann - explizit keine Pull Requests (PR)!
- Keine Co-Autorenschaft von Claude in den Commits.
- Am Ende jeder Ausgabe gibst du eine laufende Liste aller Commits des Chats aus mit kurzer Beschreibung + welches Repository. Jedes bekommt einen grünen Haken, wenn das Commit durch einen höheren Reasoning-Faktor als `normal` reviewed wurde. `ultracode`-Agenten oder explizit durch mich auf ultracode gestelltes reasoning bekommt einen Stern als Symbol. Ausgenommen sind Commits, die reine Dokumentationen upgedatet haben - diese bekommen einen grünen Haken auch ohne review. Bereitws reviewed commits - sog. Fix-Committs -  werden normalerweiße nicht nochmals reviewed aßer es ist explizit angegeben.

## Code-Qualität

- Implementierter Code muss luacheck / stylua-grün sein.
- Neue Features ggf. im plugin-eigenen `/TESTS/`-Ordner testen.
- Warnungen von Lintern (`luacheck`, `clippy`, `svelte-check` ...) vor dem Commit auf null bringen, nicht nur ansehen. Eine Warnung, die ich sehe und stehen lasse, macht die CI rot.
- Jeder Fix bekommt einen Test, der **ohne** den Fix rot wird: Fix herausnehmen, Test laufen lassen, Fix zurücksetzen. Nach einem Rebuild prüfen, dass die Sabotage wirklich gebaut wurde (sonst bleibt der Test grün und beweist nichts).

## Immer wieder passiert (Fallen dieser Umgebung)

- **Backslashes gehen verloren**, in der Shell, in Heredocs und in Python-Strings darin (`\n`, `\u`, `\\`; das Ergebnis läuft ohne Fehler durch und ist still falsch). Alles, was `\` enthält, nur mit dem Edit- oder Write-Tool schreiben. Patch-Skripte als Datei ablegen, nie durch die Shell schicken; Zeichen aus `chr(92)` bauen. Siehe `$REPOS_DIR/tasks-vault/HEREDOC.md`.
- **Skripte im Temp-Ordner mit neuem, eindeutigem Namen anlegen.** `Write` auf eine schon vorhandene Datei scheitert mit „has not been read“, und das alte Skript läuft dann mit altem Inhalt weiter.
- **Vor jedem `git push`: `git log origin/main..HEAD`.** Im geteilten Checkout liegen oft Commits einer anderen Sitzung; ein `git push` veröffentlicht sie mit. Gepinnte Commits (`engine.lock`, Submodule, Versionen) nie aus `rev-parse HEAD` nehmen, sondern nur einen Commit, der auf `origin` ist.
- **Nach dem Push die CI abwarten** (Status nennen), „lokal grün“ genügt nicht.
- **Windows-Pipes:** `cmd | tail -0` beendet den Prozess per SIGPIPE (ein Build wird abgebrochen, die Sabotage bleibt grün); nimm `tail -1`. Aus Python startet `subprocess.run(['bash', ...])` die WSL-Bash; nimm `C:/Program Files/Git/bin/bash.exe`. Siehe `$REPOS_DIR/tasks-vault/TOOLS/windows-spec-and-encoding-traps.md`.
- **Ein Detektor, der „nichts“ meldet, ist erst nach einem Positivtest etwas wert** (gleiche Datei, eine Stelle, die einen Treffer haben muss).

## Dokumentation

- Docs / README.md aktualisieren, sofern es Sinn ergibt.
- Wird ein Binding aktualisiert, ggf. auch `vim.fn.stdpath('config') .. /docs/NOTES/BINDINGS` aktualisieren.
- Feature-/Backlog-/Roadmap-Notizen (alles, was Endnutzer nicht betrifft) gehören nach `$REPOS_DIR/tasks-vault/`.
- Reports sowie Original-Handover-Files kommen immer nach `$REPOS_DIR/tasks-vault/<plugin>`; in `$NVIM_CONFIG_DIR/docs` liegen dann nur Symlinks darauf.
- Die Plugin-Repo-Docs (README, Feature-Beschreibungen für Endnutzer usw.) bleiben für die echte Endnutzer-Dokumentation reserviert. Im Zweifelsfall nachfragen – es sind aber bereits genug Dateien vorhanden, um Ableitungen zu treffen.

## Pfade

- Installations-Specs meiner Plugins: `vim.fn.stdpath('config') .. /lua/plugins/personal/init.lua`
- Alle `.nvim`-Plugins (falls nötig): `$REPOS_DIR/repos`

## Regeln

- Tool bauen vs. Wegwerf-Skript, Ablageort: `$REPOS_DIR/tasks-vault/TOOLS/TOOL-PLACEMENT.md` und `$REPOS_DIR/tasks-vault/TOOLS/lua-plugin-tools.md`
  - Wird im Zuge einer Task ein Tool gebaut, das für künftige User/Devs/Agents interessant sein könnte: an geeigneter Stelle im `TOOLS/`-Ordner sichern.
- Keine großen/escapehaltigen Literale durch die Shell schleusen: `$REPOS_DIR/tasks-vault/HEREDOC.md`
- Performance-Optimierungen: `$RULES_VAULT/rulesets/lua/regeln/PERFORMANCE.md`
- Lua-Projekte für Neovim: `$RULES_VAULT/rulesets/lua/regeln/LUA_NVIM.md`
- `$REPOS_DIR/lib.nvim` verwenden, wo möglich und simnnvoll. Dies ist wichtig, um maintainance für mich zu ermöglichen.

---
```
