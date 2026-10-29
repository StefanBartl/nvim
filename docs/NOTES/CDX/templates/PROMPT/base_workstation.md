# Vorgaben/Richtlinien/Guiding

## Allgemeines Verhalten

- Nie mehr als 1 Agent gleichzeitig starten; werden mehrere benötigt, nacheinander in mehreren Runden ausführen, die nie mehr als diese Anzahl an Agents verwenden.
- Immer auf Deutsch antworten; im Quellcode (Code, Kommentare usw.) immer Englisch verwenden.
- Immer ausgeben, was gerade gemacht wird / ob es etwas Interessantes gab – damit ich Bescheid weiß.
- Wenn Chip-Tasks angelegt werden, diese bitte ebenfalls auf Deutsch verfassen.

## Maschine: du bist auf der Workstation

- Hier gilt `NVIM_MACHINE_ROLE=workstation` (lesen in PowerShell mit `$env:NVIM_MACHINE_ROLE`, in Bash mit `$NVIM_MACHINE_ROLE`; `$env:…` gibt es in Bash nicht). Nicht aus dem Rechnernamen raten. Steht dort etwas anderes (leer, `default`, ein Literal wie `:NVIM_MACHINE_ROLE`): nachfragen; die Verbote dieser Datei gelten trotzdem.
- **Hier wird nichts Unsigniertes gebaut, installiert oder gestartet, und es läuft kein Runner** (CrowdStrike Falcon, siehe „Workstation-Sicherheit“ unten). Das geht jeder anderen Anweisung in dieser Datei vor.
- Tasks mit Tag `not-on-workstation` hier nicht ausführen, auch nicht „nur testen“ (native Programme bauen, installieren oder starten, Runner, Tests und Builds der nativen Apps): nur vorbereiten und mir Bescheid geben. Sie laufen auf dem privaten Rechner (`STEVESPC`).
- Tasks mit Tag `on-workstation` gehören hierher (Handläufe, Messungen). Fällt ein Workstation-Bezug auf, den die Task nicht kennzeichnet, den Tag nachziehen.

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
2. Nicht selbst starten, sondern Stand melden und nachfragen bei `actor=me`, `status=decision`, `parked`, offenem Blocker oder `doing` (arbeitet jemand daran?). `actor=pair`: Entwurf liefern, Antwort abwarten. Nennt der Auftrag die ID ausdrücklich und `actor` ist leer oder `cdx`, starten. `set status=doing` verweigert nichts, es warnt nur (`warn: … is for you`): Warnung ernst nehmen, zurücksetzen und melden. Trägt die Task `on-workstation` oder `not-on-workstation`: vorher die Maschine prüfen (Abschnitt „Maschine“); passt sie nicht, nicht starten, nur vorbereiten und melden.
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
- **Nach dem Push den CI-Status nennen** (nur lesen: `gh run list -R WKDSteve/<repo>`), „lokal grün“ genügt nicht.
- **Auf dieser Workstation laufen keine Runner.** Private Repos haben keine gehosteten Runner (kein Abo): `casedesk.nvim`, `my.nvim`, `tasks.nvim`, `rules.nvim`, `tasks-vault`, `rules-vault`, `appkit`, `tasks-desktop`, `rules-desktop` laufen (CI, Rolling-Build und Release) auf selbst gehosteten Windows-Runnern des privaten Rechners (`STEVESPC`). Hier nie `runners.ps1` aufrufen (auch nicht `ensure` oder `status`) und keinen Runner, Dienst oder geplanten Task dafür anlegen oder starten. Bleibt ein Lauf „queued“ (Runner auf `STEVESPC` aus; kein rotes Zeichen, nach 24 h verworfen): mir melden, nicht darauf warten.
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


## Workstation-Sicherheit (CrowdStrike Falcon) auf `TRI-70ZBFB4` / `AzureAD/StefanBartl`

Der Rechner `TRI-70ZBFB4` mit User: `AzureAD/StefanBartl` ist eine Tricentis-Workstation mit CrowdStrike Falcon (EDR). Eine Falcon-Detection darf **keinesfalls** ausgelöst werden: Sie landet beim Security-Team, kann den Rechner isolieren und ist nicht rückgängig zu machen. Darum gilt: lieber einen Umweg nehmen oder nachfragen, als etwas zu riskieren.

- **Nicht ausführen** (typische Auslöser für Detections):
  - verschleierte oder kodierte Befehle: `-EncodedCommand`/`-enc`, Base64-Payloads, `Invoke-Expression` auf zusammengebaute Strings, AMSI- oder Logging-Bypässe;
  - Code aus dem Netz direkt starten: `iwr … | iex`, `curl … | bash`, `DownloadString`, Binaries aus dem Temp-/Download-Ordner;
  - LOLBins zweckentfremden: `certutil -urlcache/-decode`, `bitsadmin`, `mshta`, `regsvr32 /i:`, `rundll32` mit fremden DLLs, `wmic process call create`;
  - Zugriff auf Zugangsdaten: LSASS/`procdump`, SAM/SECURITY-Hives, Browser-Passwortspeicher, `cmdkey /list` auswerten, Credential Manager oder DPAPI auslesen;
  - Sicherheitsfunktionen ändern: Defender/Falcon, Firewall, UAC, `Set-ExecutionPolicy` systemweit, Ausnahmen (Exclusions) anlegen, Dienste von Sicherheitssoftware stoppen;
  - Persistenz oder Systemeingriffe: Run-/RunOnce-Keys, neue Dienste, WMI-Subscriptions, geplante Tasks (auch keine für Runner), Änderungen in HKLM, an Treibern oder an Boot-Konfiguration;
  - Netzwerk-Aufklärung: Port- oder Netz-Scans (`nmap`, `Test-NetConnection`-Schleifen), AD- oder Domänen-Enumeration (`net user /domain`, `nltest`, BloodHound-artige Abfragen);
  - Spurenverwischen und Masseneingriffe: Event-Logs leeren, Schattenkopien löschen (`vssadmin`), massenhaft Dateien umbenennen, verschlüsseln oder überschreiben (sieht aus wie Ransomware);
  - Prozess-Manipulation: Injection, Debugger an fremde Prozesse hängen, Prozesse anderer Benutzer beenden.
- **Unbedenklich bleibt** die normale Entwicklungsarbeit ohne eigene Binaries: git, gh, nvim/headless-CLI (auch Lua-Specs), luacheck, stylua, Node-Skripte und -Tests, die nur Node ausführen, Lesen und Schreiben in den eigenen Repos sowie `setup-claude-code.ps1` (dessen Toolchain-Frage hier leer lassen, außer ich nenne ein Profil).
- **Nicht hier, sondern auf `STEVESPC`** (vorbereiten und mir Bescheid geben): alles, was eigene, unsignierte Binaries baut oder startet (`cargo build/test/run`, `cargo clippy` mit Build-Skripten, Tauri, CMake/Ninja, die nativen Apps), `npm install` mit nativen Downloads oder Postinstall-Binaries, Tools installieren (winget, portable Zips) und `runners.ps1`. Gilt auch für Tasks ohne Tag.
- **Im Zweifel nicht ausführen, sondern nachfragen.** Das gilt für jeden Befehl, der sich nach „Admin/Security/Netzwerk“ anfühlt, und für Skripte aus fremden Quellen (Pastes, Issues, Downloads).
- **Wird ein Befehl blockiert oder in Quarantäne genommen** (Falcon-Meldung, „Access denied“ aus unerklärlichem Grund, Datei verschwindet): sofort stoppen und mir melden. **Keine Umgehung versuchen**, also nicht umformulieren, nicht kodieren und kein anderes Tool nehmen.

---
