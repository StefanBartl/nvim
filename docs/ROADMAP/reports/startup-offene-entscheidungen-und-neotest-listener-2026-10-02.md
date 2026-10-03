# Startup: offene Entscheidungen und neotest-Listener (Übergabe)

Stand: 2026-10-02. Zum Weiterreichen in einen neuen Chat. Der Stand der
Startup-Arbeit steht in
[`startup-und-config-optimierung-analyse-konzept-2026-09-26.md`](./startup-und-config-optimierung-analyse-konzept-2026-09-26.md),
der volle Verlauf samt drei Reviews im Archiv
`$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/nvim-config/Backlog/TASKS/startup-und-config-optimierung-2026-09-26.md`.

---

## Table of content

  - [Vorgaben](#vorgaben)
  - [Aufgabe 1: neotest-Listener (Sicherheit)](#aufgabe-1-neotest-listener-sicherheit)
  - [Aufgabe 2: erster langsamer `<leader>`-Druck](#aufgabe-2-erster-langsamer-leader-druck)
  - [Aufgabe 3: sandbox-Hover](#aufgabe-3-sandbox-hover)
  - [Aufgabe 4: Auto-Attach meldet ohne laufenden Test](#aufgabe-4-auto-attach-meldet-ohne-laufenden-test)
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

**Befund (Review, dritter Durchgang).** Beim Start des neotest-Clients öffnet
neotest selbst `serverstart("localhost:0")`, einen **unauthentifizierten
TCP-RPC-Listener** (`nvim-data/lazy/neotest/lua/neotest/lib/subprocess.lua:36`,
aufgerufen aus `client/init.lua:378-380`, ohne Option abschaltbar;
`discovery.concurrent` ändert daran nichts). Ein zweiter nvim hat sich ohne
Zugangsdaten verbunden und per `nvim_exec_lua` Lua in der Sitzung ausgeführt
(PID, Benutzername und Verzeichnis kamen zurück).

**Warum er hier ungenutzt offen bleibt.** Neotest startet danach einen
Hilfsprozess (`nvim --embed --headless -n -u NONE`) zum Parsen. Der scheitert mit
„address already in use": `lib.nvim` (`rpc_pipe`, Dateiname unter
`lua/lib/nvim/` suchen, Stichwort `NVIM_LISTEN_ADDRESS`) exportiert die Variable
an Kindprozesse. Das Parsen läuft deshalb auf dem Hauptthread, der Listener
bleibt offen und tut nichts.

**Wie oft.** Er war schon vor der Startup-Arbeit offen, nämlich beim ersten
Besuch eines Test-Buffers (Auto-Attach). Seit `87a29e20` startet der Client auch
beim verzögerten Laden für eine Testdatei als Startargument oder in einer
Session, also in manchen Sitzungen früher. Eine Sitzung ohne offenen Test-Buffer
hat keinen Listener. Der Kommentar in `lua/plugins/neotest.lua` (im `init`)
beschreibt das schon.

**Optionen (zu entscheiden und zu messen):**

| Option | Wirkung | Kosten und Risiko |
| --- | --- | --- |
| A: so lassen | Listener bleibt, wie er immer war | keine; Risiko besteht vor allem auf Rechnern mit mehreren lokalen Benutzern, sonst kann jeder Prozess des Nutzers ohnehin alles |
| B: `rpc_pipe` ändert den Export | Hilfsprozess startet, Listener wird genutzt (offen bleibt er trotzdem) | laut Review 110–140 ms synchron zur `VeryLazy`-Welle, ungemessen; berührt jedes Plugin, das sich auf die vererbte Variable verlässt |
| C: Client-Start nur auf Abruf | Listener erst bei `:Neotest …` oder `<leader>nt*` | neotest startet den Client sonst selbst über den Auto-Attach; die Signs auf offenen Test-Buffern entfielen bis zur ersten Benutzung (Verhalten ändert sich) |
| D: Listener nach dem Start schließen | `serverstop` für den `localhost:`-Eintrag aus `vim.fn.serverlist()` | nur sinnvoll, solange der Hilfsprozess nicht läuft (hier der Fall); fragil bei Upstream-Änderungen |

**Was zu tun ist:**

1. In `lib.nvim` herausfinden, wofür der Export an Kinder da ist und wer sich
   darauf verlässt (Grep über alle Repos in `E:\repos` und die nvim-config).
2. Mit UI messen: Start mit einer Testdatei als Argument und mit einer Session
   (zwei Test-Buffer, ein anderer aktuell), Stoß-Summe, längster Stoß, „loop busy",
   jeweils mit und ohne erlaubten Hilfsprozess. Prüfen, ob `serverlist()` den
   `localhost:`-Eintrag zeigt und ob der Hilfsprozess läuft.
3. Empfehlung berichten und erst nach Rückfrage Verhalten ändern, das andere
   Plugins betrifft.

**Ergebnis (2026-10-02, noch nicht entschieden).** Gemessen, bewertet und mit Empfehlung (A, oder D nach
Test, nicht B) in
`E:\repos\openinnvim\docs\HANDOVER.md`.
Kurz: niemand liest die Variable, openinnvim braucht nur den Pipe-Namen, der Hilfsprozess kostet +75 bis +150 ms
und hält den Listener offen.

**Chip-Prompt** (liegt als Chip `task_863fc24d` bereit; hier zum Kopieren, falls
er verschwunden ist):

```text
Kontext: nvim-config (C:\Users\bartl\AppData\Local\nvim, main, kein PR, direkt
committen und pushen, keine Co-Autorenschaft; Antworten Deutsch, Code und
Kommentare Englisch). Lies docs/ROADMAP/reports/startup-offene-entscheidungen-
und-neotest-listener-2026-10-02.md, Aufgabe 1, und die dort verlinkten Dateien.
Aufgabe: 1) in lib.nvim klären, wofür rpc_pipe NVIM_LISTEN_ADDRESS an
Kindprozesse exportiert und wer sich darauf verlässt, 2) mit UI messen, was es
kostet und ändert, wenn neotests Hilfsprozess starten darf, 3) die Optionen A-D
bewerten und eine Empfehlung berichten. Nicht ohne Rückfrage Verhalten ändern.
Regeln: Prozesse nur über die eigene PID beenden, [IO.File]::Delete statt
Remove-Item, luacheck und stylua grün, nur 1 Agent gleichzeitig.
```

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

**Befund.** `lua/config/neotest/core/init.lua` (BufEnter-Autocmd, Zeilen 64–71)
ruft bei jedem BufEnter eines Testbuffers `neotest.run.attach()`, auch wenn
nichts läuft. Das ergibt immer eine Meldung: „No running process found" (alter
Weg) oder, wenn der Auto-Attach der Discovery zuvorkommt (≥ 100 Testdateien,
3 von 9 Läufen bei 100 Specs), „No tests found". Die Zahl der Meldungen ist
gleich geblieben, nur der Text ist ein anderer.

**Vorgeschlagener Fix (im Review gezeigt, nicht eingebaut).** Den Attach nur
auslösen, wenn im Buffer etwas läuft:

```lua
local bufnr = vim.api.nvim_get_current_buf()   -- vor vim.schedule
-- im geplanten Callback:
local running = false
pcall(function()
  for _, id in ipairs(neotest.state.adapter_ids() or {}) do
    local c = neotest.state.status_counts(id, { buffer = bufnr })
    if c and (c.running or 0) > 0 then running = true; break end
  end
end)
if running then pcall(neotest.run.attach) end
```

In 9 von 9 Läufen (400 Specs, 100 Specs, kleines Projekt) war danach keine
Meldung mehr da, die Signs kamen weiter nach 1,8–2,9 s. **Ungeprüft ist der
positive Fall:** ein Lauf läuft in Datei A, dann wird Test-Buffer B geöffnet,
`attach` muss weiter feuern. Das zuerst testen (Echt-Config im TUI, siehe unten),
dann einbauen. Beachte: `core.is_test_file()` prüft den **aktuellen** Buffer,
nicht `ev.buf`.

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
- `neotest` einmal von Hand bedienen (`<leader>nt*` beim ersten Druck,
  Statuszeichen in Testdateien).
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
- Die `neotest`-Szenarien (Session mit zwei Test-Buffern und `notes.txt` aktuell,
  Testdatei als Argument, `edit E:/…` mit Schrägstrichen) und ihre Messskripte
  stehen im Archiv beschrieben; die Prüfung zählt Signs (`sign_getplaced`) je
  Buffer nach 5–7 s und sucht „No tests found" in `:messages`.
