# Startup: offene Entscheidungen (Übergabe)

Stand: 2026-10-02 (neotest-Teile am 2026-10-03 ausgelagert). Zum Weiterreichen in einen neuen Chat.
**Alles zu neotest** (Aufgabe 1, Aufgabe 4, "neotest von Hand bedienen", die neotest-Szenarien)
steht in [`../handovers/neotest_HANDOVER.md`](../handovers/neotest_HANDOVER.md). Der Stand der
Startup-Arbeit steht in
[`startup-und-config-optimierung-analyse-konzept-2026-09-26.md`](./startup-und-config-optimierung-analyse-konzept-2026-09-26.md),
der volle Verlauf samt drei Reviews im Archiv
`$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/nvim-config/Backlog/TASKS/startup-und-config-optimierung-2026-09-26.md`.

---

## Table of content

  - [Vorgaben](#vorgaben)
  - [Aufgabe 1: neotest-Listener (Sicherheit)](#aufgabe-1-neotest-listener-sicherheit) (ausgelagert)
  - [Aufgabe 2: erster langsamer `<leader>`-Druck](#aufgabe-2-erster-langsamer-leader-druck)
  - [Aufgabe 3: sandbox-Hover](#aufgabe-3-sandbox-hover)
  - [Aufgabe 4: Auto-Attach meldet ohne laufenden Test](#aufgabe-4-auto-attach-meldet-ohne-laufenden-test) (ausgelagert)
  - [Aufgabe 5: weitere offene Punkte aus dem Report](#aufgabe-5-weitere-offene-punkte-aus-dem-report)
  - [Messen](#messen)

---

## Vorgaben

- Antworten auf Deutsch, Code und Kommentare auf Englisch. Nie mehr als ein
  Agent gleichzeitig. Immer sagen, was gerade passiert.
- Fertig heißt: direkt auf `main` committen, pushen, pullen. **Keine PRs, keine
  Co-Autorenschaft.** Code muss `luacheck` und `stylua` grün sein.
- Am Ende jeder Ausgabe die laufende Commit-Liste des Chats. Ein grüner Haken
  nur nach `ultracode`-Review (oder bei reiner Doku).
- **Prozesse nur über die eigene PID beenden**, nie `taskkill /IM nvim.exe` oder
  `Stop-Process -Name nvim`: der Nutzer hat eigene Sitzungen laufen.
- Im Worktree nie den nackten Pfad `C:\Users\bartl\AppData\Local\nvim` für
  Shell-Befehle nehmen (anderer Checkout). `Remove-Item` ist auf manchen Pfaden
  gesperrt: `[IO.File]::Delete` und `[IO.Directory]::Delete` verwenden.
- Zahlen nur mit UI messen (siehe unten), nie Einzelläufe vergleichen.

---

## Aufgabe 1: neotest-Listener (Sicherheit)

**Erledigt und ausgelagert (2026-10-03).** Befund, Messungen, Optionen A-D, der Umbau ("Option E":
kein Listener, kein Hilfsprozess) und die Belege stehen in [`../handovers/neotest_HANDOVER.md`](../handovers/neotest_HANDOVER.md).

---

## Aufgabe 2: erster langsamer `<leader>`-Druck

**Befund.** which-key lädt erst auf seinen Tasten (`keys` in
`lua/plugins/essentials.lua`, etwa Zeile 35–40). Ist `<Space>` die erste
Stub-Taste der Sitzung und kommt der Druck langsam, löst lazys Stub erst nach
`timeoutlen` aus, und es erscheint **kein Popup**; erst der zweite Druck zeigt
es. Kam ein anderer Stub vorher (`g`, `c`, `v`, `"`, `'`, `` ` ``, `<c-w>`),
lädt which-key sofort und der erste `<Space>`-Druck zeigt das Popup. Das war
schon vor dieser Arbeit so, belegt per pty-Lauf mit altem und neuem Stand.
Wer innerhalb von etwa 2 s weitertippt, bekommt das Mapping trotzdem.

| Option | Wirkung | Kosten |
| --- | --- | --- |
| A: `event = "VeryLazy"` an der which-key-Spec (`keys` und `cmd` bleiben) | Popup schon beim ersten Druck | gemessen 9–12 ms Laden, 15–19 ms mit Config, 22–27 ms bis die Trigger stehen, in der Welle nach dem ersten Frame; kehrt die dokumentierte Entscheidung in `lib.nvim` (`which_key.lua`, Kommentar `loaded_wk`: „lädt auf dem ersten `<leader>`") um; dann auch diesen Kommentar anpassen |
| B: lassen | nichts ändert sich | keine; den Hänger an der Spec dokumentieren |

Nicht versuchen, which-keys geplantes Laden aus lazys Stub heraus zu erzwingen:
Laden und Trigger-Anlage sind `vim.schedule`d, und Neovim führt geplante
Callbacks nicht aus, solange ein Mapping auf seine Fortsetzung wartet.

---

## Aufgabe 3: sandbox-Hover

**Stand.** `sandbox.nvim` lädt über `cmd = { "Sandbox", "Sbx" }`,
`ft = "dockerfile"` und Compose-Dateinamen
(`lua/plugins/personal/specs/project.lua`, `COMPOSE_FILES`). Neovim 0.12 gibt
Compose-Dateien den Typ `yaml` (ein `yaml.docker-compose` gibt es nicht), und
`yaml` als Auslöser kostete ≈ 110 ms plus eine zweite `FileType`-Runde bei der
ersten beliebigen YAML-Datei (CI, Kubernetes).

**Folge.** Die Hover-Vorschau für Image-Referenzen gibt es in k8s- und
Workflow-YAML, in `devcontainer.json`, Shell-Skripten und Markdown erst, wenn
das Plugin geladen ist (durch eines der Auslöser oder `:Sandbox`).

**Entscheiden:** so lassen, oder weitere Dateinamen als Auslöser (z. B.
`devcontainer.json`, `*.containerfile`, `docker-bake.hcl`), jeweils über
`event = "BufReadPost <Muster>"`. Jeder weitere Auslöser lädt das Plugin
(≈ 110 ms beim ersten Treffer). Danach prüfen, dass Dateien ohne Treffer es nicht
laden: Beispiel-Skript im Archiv (Abschnitt „Zweiter Review", `sandbox`-Zeilen)
beschreibt die Prüfung; `:checkhealth sandbox` braucht das geladene Plugin.

---

## Aufgabe 4: Auto-Attach meldet ohne laufenden Test

**Erledigt und ausgelagert (2026-10-03).** Das Gate (`attach` nur bei laufendem Test, der Client
startet weiter still) ist eingebaut und im positiven und negativen Fall geprüft; siehe
[`../handovers/neotest_HANDOVER.md`](../handovers/neotest_HANDOVER.md), Abschnitte 4 und 5.

---

## Aufgabe 5: weitere offene Punkte aus dem Report

Aus [Abschnitt 4 und 5 des Reports](./startup-und-config-optimierung-analyse-konzept-2026-09-26.md);
hier nur die Stichworte:

- **Checker:** Reicht `C` in `:Lazy` zwischen zwei Checks, oder soll die
  Update-Liste beim Öffnen von `:Lazy` automatisch berechnet werden (kostet dort
  ≈ 0,1 s)? Hinweis: Ein `last_check` in der Zukunft wird bewusst als „nicht
  fällig" behandelt (lazy plant davon aus; ein Anschalten würde bei jedem Start
  den `git log`-Durchgang laufen lassen, ohne je zu fetchen).
- **`filetree.nvim` ohne `neo-tree` beim Laden:** lohnt der Umbau für
  ≈ 50–70 ms? Der Adapter (`adapter/neotree.lua`, 1600+ Zeilen) hängt sich mit
  Reihenfolge-Annahmen in neo-tree-Interna.
- `gopath.nvim`: `load_from_disk` aus `setup()` nehmen (−30 ms).
- PATH-Suchen, Rest: `git` ×7 (`gitsigns.lua:237`) und `cygpath` ×2
  (fremder Code in gitsigns).
- Die `VeryLazy`-Welle in Scheiben laden, falls die obigen nicht reichen.
- `:StartupReport` zeigt nur Phasen-Bodies, nicht „Stöße und Belegung".
- `gitsigns` lädt vor `VimEnter` per `require`; NvChad-Probe in `lsp.nvim`.
- `Keymaps-Collisions.md` (WKDBooks, `wkdbook-myplugins/ALL/`) gegen die
  richtige Reihenfolge prüfen: ein Plugin auf `VeryLazy` überschreibt ein Mapping
  der `mappings`-Phase.
- `neotest` einmal von Hand bedienen: steht als Live-Tests in [`../handovers/neotest_HANDOVER.md`](../handovers/neotest_HANDOVER.md).
- `OHANA` (Neovim 0.11.4) mit `bench.lua 5 tui` neu messen; erst danach dort über
  die `runtimepath`-Neuberechnung entscheiden. Das kann nur der Nutzer.

---

## Messen

```bash
# Vergleichszahlen: 5 Läufe mit UI, Median / Min / Max
nvim --headless -l scripts/startup-probe/bench.lua 5 tui

# Wem gehört jeder Stoß, was lud wodurch (stdout und stdin umleiten)
PROBE=stall,where,lazy,marks nvim --headless -l scripts/startup-probe/tui.lua > /dev/null < /dev/null
```

Aus PowerShell: `cmd /c "nvim --headless -l scripts/startup-probe/tui.lua > NUL < NUL"`.
Extra-Argumente hinter `tui.lua` gehen an den gemessenen Neovim (`-S Session.vim`,
eine Testdatei, `--clean`).

- **Nie headless** für Aussagen nach `VimEnter`: lazy feuert `VeryLazy` erst nach
  `UIEnter`. Anleitung und Grenzen: `scripts/startup-probe/README.md`.
- Die Worktree-Config als Config laufen lassen: kurze Junction
  `%TEMP%\nvwt_X\nvim` auf den Worktree und `XDG_CONFIG_HOME=%TEMP%\nvwt_X`;
  danach `$env:XDG_CONFIG_HOME = $null` und die Junction mit
  `[IO.Directory]::Delete(pfad, $false)` entfernen, nie rekursiv.
- Der Stand vor einer Änderung als zweite Kopie: `git archive <commit>^ | tar -x`
  in ein kurzes Verzeichnis, dasselbe `XDG_CONFIG_HOME`-Verfahren. Danach dessen
  Dateisymlinks einzeln löschen (`git archive` bringt Links aus `docs/` mit).
- Zahlen schwanken mit der Last der Maschine (15 % und mehr): nur Läufe derselben
  Sitzung vergleichen, mindestens 5 Läufe, Median.
- Testanordnungen täuschen leicht: `badd` lädt keinen Buffer, ein Root-Plugin
  wechselt das Arbeitsverzeichnis (Pfade vorher absolut machen),
  `return require(x)` ist ein Tail-Call und löscht Frames.
- Die `neotest`-Szenarien und ihre Messskripte: [`../handovers/neotest_HANDOVER.md`](../handovers/neotest_HANDOVER.md) (Abschnitt 3 und Probe-Tool).
