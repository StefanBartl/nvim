# NVIM_LISTEN_ADDRESS (rpc_pipe), neotest-Listener und openinnvim (Übergabe)

Stand: 2026-10-02. Zum Weiterreichen in einen neuen Chat. Quellen: die neotest-Aufgabe aus
[`startup-offene-entscheidungen-und-neotest-listener-2026-10-02.md`](../reports/startup-offene-entscheidungen-und-neotest-listener-2026-10-02.md)
(Aufgabe 1) und die Suche nach dem Windows-Kontextmenü-Eintrag "In Neovim öffnen".

---

## Table of content

  - [Kurzfassung](#kurzfassung)
  - [Teil 1: wofür rpc_pipe die Variable exportiert](#teil-1-wofur-rpc_pipe-die-variable-exportiert)
  - [Teil 2: Messung mit UI](#teil-2-messung-mit-ui)
  - [Teil 3: Optionen und Empfehlung](#teil-3-optionen-und-empfehlung)
  - [Teil 4: openinnvim und das kaputte Kontextmenü](#teil-4-openinnvim-und-das-kaputte-kontextmenu)
  - [Offen und Nachfrage](#offen-und-nachfrage)
  - [Commits dieses Chats](#commits-dieses-chats)
  - [Messen: Wiederholung](#messen-wiederholung)

---

## Kurzfassung

- **Niemand liest `NVIM_LISTEN_ADDRESS`.** Weder `lib.nvim`, noch ein anderes Repo unter `E:\repos`, noch die
  Config. Drei Stellen **entfernen** die Variable sogar bewusst für Kinder (`scripts/run_all_tests.sh`,
  `temporary/example-plugin/scripts/tests/minimal_init.lua`, ein alter gitsigns-Patch in WKDBooks).
- **Das Kontextmenü-Tool (`openinnvim`) hängt am Pipe-Namen, nicht am Export.** Es nutzt
  `\\.\pipe\nvim-%USERNAME%` (Heuristik, oder `nvr --serverlist`) und startet sonst eine neue Instanz mit
  `--listen` auf diesem Namen. Den Namen legt `serverstart(pipe)` in `rpc_pipe.lua` an, das Setzen von
  `vim.env.NVIM_LISTEN_ADDRESS` ist dafür nicht nötig.
- **Neotests Hilfsprozess starten zu lassen kostet etwa +75 bis +150 ms Stoßsumme** (mit UI, Median), bringt in
  den gemessenen Projekten keinen sichtbaren Gewinn und **schließt den Listener nicht**: der Hilfsprozess
  verbindet sich an ihn (TCP `Established`).
- **Empfehlung:** Option A (lassen, dokumentiert) oder Option D (Listener nach dem Start schließen, solange
  der Hilfsprozess ohnehin nicht läuft). Nichts davon wurde geändert.
- **Nebenbefund:** `C:\tools\OpenInNvim` ist ein toter Symlink (siehe Teil 4). Das ist der Grund, warum der
  Kontextmenü-Eintrag nicht mehr funktioniert.

---

## Teil 1: wofür rpc_pipe die Variable exportiert

`lua/lib/nvim/system/rpc_pipe.lua` (lib.nvim, eingeführt mit `17fae31`, seither nur Doku-Commits):

1. `vim.fn.serverstart(\\.\pipe\nvim-<USERNAME>)` startet einen **vorhersagbaren** Server.
2. `vim.env.NVIM_LISTEN_ADDRESS = pipe` exportiert den Namen. Neovim liest die Variable beim Start eines
   Kindes als dessen Serveradresse: ein Kind-nvim versucht deshalb dieselbe Pipe zu belegen und scheitert
   mit "address already in use". So scheitert neotests Hilfsprozess (`nvim --embed --headless -n -u NONE`).
3. Aktiviert wird es in `init.lua:126` (`rpc_pipe = true`). Ausnahmen im Modul: nicht Windows, Testumgebung
   (`NEOTEST_RUNNING`, Plenary, `nvim-test`), schon gesetzte Variable (`allow_override`).

Der Modul-Titel nennt "neotest compatibility", gemeint ist offenbar nur die Test-Ausnahme, nicht der Export.
Wer sich auf die Variable verlässt: **kein Fund**. Das README sagt als Zweck "external tools can always reach
Neovim at `\\.\pipe\nvim-<USERNAME>`", das ist der Name, nicht die Variable.

Nicht geprüft: Skripte und Einstellungen **außerhalb** von `E:\repos` (Benutzer-Umgebungsvariablen,
`git config core.editor`, Shell-Profile, Terminal-Einstellungen). Dort könnte noch jemand `nvim --server
\\.\pipe\nvim-...` benutzen. Das wäre vom Export ebenfalls unabhängig.

---

## Teil 2: Messung mit UI

Methode: `scripts/startup-probe/bench.lua 5 tui` (5 Läufe plus Aufwärmlauf, Median / Min / Max), echte TUI
über Pseudo-Terminal, Neovim 0.12.2, Windows 11. Der "erlaubte Hilfsprozess" kommt ohne Config-Änderung von
einem Wegwerf-Skript, das bei `VimEnter` `vim.env.NVIM_LISTEN_ADDRESS = nil` setzt (der Listener
`localhost:<port>` und die Pipe bleiben, nur die Vererbung entfällt). Die Skripte lagen im Scratchpad des Chats
und sind **nicht** abgelegt (siehe "Offen").

| Szenario | Stoßsumme | längster Stoß | Belegung gesamt |
| --- | ---: | ---: | ---: |
| ohne Testdatei (neotest bleibt ungeladen) | 606 (546-673) | 374 | 1010 |
| 1 Testdatei (9 Tests), Listener wie bisher | 1073 (975-1176) | 596 | 1553 |
| 1 Testdatei (9 Tests), Hilfsprozess erlaubt | 1148 (1139-1298) | 734 | 1640 |
| 100 Specs (1000 Tests), Listener wie bisher | 1128 (1036-1257) | 578 | 1755 |
| 100 Specs (1000 Tests), Hilfsprozess erlaubt | 1277 (1227-1400) | 696 | 1828 |

Einheit: ms, Median (Min-Max). Differenz durch den Hilfsprozess: **+75 / +149 ms Stoßsumme**,
+138 / +118 ms längster Stoß, +87 / +73 ms Belegung (klein / 100 Specs). Die Bereiche überlappen leicht, die
Richtung ist in beiden Projekten gleich. Laut Review wurden 110-140 ms erwartet; das passt grob.

Verifikationsläufe mit Dump (5,5 s bzw. 8 s nach `VimEnter`, spawnt Prozesse, nicht für Zeiten benutzt):

| | Hilfsprozess läuft | Verbindung am Listener | `serverlist()` |
| --- | --- | --- | --- |
| Standard | nein | nur `Listen`, kein Client | `nvim.<pid>.0`, `localhost:<port>`, fzf-lua-Pipe |
| erlaubt | ja (`nvim.exe --embed --headless -n -u NONE`) | `Established` zu einem Client, plus `Listen` | gleich |

- Signs und Discovery: im 9-Test-Projekt je 7 Signs in beiden Varianten, neotest findet die Tests in beiden.
- `rpc_pipe` ist mit `vim.env.NVIM_LISTEN_ADDRESS = nil` im Hauptprozess leer, die Pipe
  `\\.\pipe\nvim-bartl` wurde vorher angelegt und bleibt.

**Grenzen:** synthetische Projekte (Scratch, nicht Echtprojekte), eine Maschine, Last schwankt (15 % und mehr),
die Bereiche überlappen. **Nicht gemessen:** Zeit bis die Signs erscheinen (mit/ohne Hilfsprozess), ob der
Hilfsprozess bei großen Echtprojekten das Parsen vom Hauptthread nimmt (bei 100 Specs war die Belegung
trotzdem höher), ein tatsächlicher Testlauf (`<leader>nt*`) ohne Listener.

---

## Teil 3: Optionen und Empfehlung

| Option | Wirkung | Befund |
| --- | --- | --- |
| A: lassen und dokumentieren | Listener bleibt offen, wie immer | kostet nichts; Kommentar in `lua/plugins/neotest.lua` besteht schon. Restrisiko: jeder lokale Prozess kann per `localhost:<port>` Lua in der Sitzung ausführen |
| B: `rpc_pipe` vererbt nicht mehr | Hilfsprozess startet, nutzt den Listener | **+75 bis +150 ms**, kein gemessener Gewinn, und der Listener ist dann **in Benutzung** (offen, verbunden), `serverstop` geht nicht mehr. Kompatibel mit openinnvim (es braucht nur den Pipe-Namen). Berührt die Test-Skripte nicht (sie entfernen die Variable selbst) |
| C: Client nur auf Abruf | Listener erst bei `:Neotest ...` | Signs auf offenen Test-Buffern entfallen bis zur ersten Benutzung (Verhalten ändert sich), Listener öffnet sich dann trotzdem |
| D: Listener nach dem Start schließen | `serverstop` für den `localhost:`-Eintrag | **einzige Option, die die Fläche entfernt**, ohne etwas zu kosten, **solange der Hilfsprozess nicht läuft** (hier der Fall). Ungeprüft: ob neotest den Listener später für etwas anderes braucht; fragil bei Upstream-Änderungen |

**Empfehlung:** A, falls das Risiko (nur ein Nutzer auf der Maschine) vertretbar ist; sonst D, aber erst nach
einem Test: Listener schließen, dann `<leader>nt*` einen Lauf ausführen und prüfen, dass Ergebnisse und Signs
kommen. B nicht: es kostet Zeit und hält den Listener offen. Zusätzlich möglich: Upstream-Issue oder PR an
`nvim-neotest/neotest`, die `serverstart` abschaltbar zu machen (`lib/subprocess.lua:36`).

Nicht entschieden, nichts geändert: **Rückfrage an den Nutzer.**

---

## Teil 4: openinnvim und das kaputte Kontextmenü

**Was es ist.** Eine C#-App ("TinyLauncher", `.csproj`) plus PowerShell- und VBS-Skripte, die einen
Explorer-Kontextmenü-Eintrag "In Neovim öffnen" bedienen: die Datei geht an eine **laufende** Instanz
(`nvr --remote` oder `nvim --server <pipe> --remote`), sonst startet eine neue mit `--listen`.
Adressfolge: `NVIM_SERVER` aus der Config, dann `nvr --serverlist`, dann `\\.\pipe\nvim-%USERNAME%`
(`open-in-nvim-current.ps1`, Abschnitte 5 und 7). Passt zum Namen in `rpc_pipe.lua`.

**Wo es liegt (neu).**

| Was | Ort |
| --- | --- |
| Repo | `E:\repos\openinnvim`, GitHub `StefanBartl/openinnvim` |
| Alter Name | `StefanBartl/open-in-nvim` (GitHub leitet den alten Namen weiter) |
| Installierte Binaries und VBS | `C:\Users\bartl\AppData\Local\OpenInNvim` (`tiny-launcher-*.exe`, `*.vbs`, `Logos/`), kein Repo, 131 MB, **nicht angefasst** |
| Skript-Pfad aus den VBS | `C:\tools\OpenInNvim\open-in-nvim*.ps1` |
| Linux-Varianten (Nautilus, Dolphin, Nemo, `.desktop`) | `Configs/Linux/Contextmenu/OpenInNvim` |

**Befund: der Eintrag funktioniert nicht mehr, weil `C:\tools\OpenInNvim` ein toter Symlink ist.** Er zeigt auf
`E:\repos\Configs\Windows\Contextmenu\OpenInNvim`. Das Verzeichnis wurde beim Aufteilen des Configs-Repos
(`docs/RESTRUCTURE.md`, `git rm`) entfernt; `Windows/Contextmenu/` enthält nur noch `MyScripts` (leer). Die VBS rufen
`C:\tools\OpenInNvim\open-in-nvim.ps1` auf, und `Test-Path` darauf ist `False`.

**Zur Registry:** die Einträge unter `HKCU:\Software\Classes\...\shell` habe ich nicht auswerten können (die
Abfrage lief in ein Zeitlimit, Ergebnis leer). Ob und was dort noch eingetragen ist, ist **ungeprüft**. Das Repo
bringt `add-current.reg`, `add-new.reg`, `remove-old.reg`, `install-context.ps1`, `verify.ps1` und
`deploy-open-in-nvim.ps1` mit.

**Was getan wurde.** Repo nach `E:\repos\openinnvim` geklont, auf GitHub nach `openinnvim` umbenannt, `origin`
neu gesetzt, in `Configs/docs/RESTRUCTURE.md` und `docs/checklisten/regeln/DOTFILES.md` die Verweise
angepasst (die Datei- und Skriptnamen `open-in-nvim.*` blieben, sie stehen in der installierten Kopie).

**Was zu tun ist (nicht getan, braucht Zustimmung):**

1. Symlink `C:\tools\OpenInNvim` auf `E:\repos\openinnvim` umsetzen (Löschen und Neuanlegen eines Symlinks in
   `C:\tools`; unter Windows braucht das Entwicklermodus oder Administrator).
2. Mit `verify.ps1` und `install-context.ps1` aus dem Repo prüfen, was in der Registry steht, und den Eintrag
   neu setzen.
3. Prüfen, dass `nvim` beim Start `\\.\pipe\nvim-bartl` belegt (ist durch `rpc_pipe` der Fall), dann eine Datei
   aus dem Explorer öffnen: sie muss in der laufenden Sitzung landen.
4. Repo-README und die Repo-Beschreibung auf GitHub auf den neuen Namen prüfen (nur Verweise geprüft, nicht
   inhaltlich gelesen).

---

## Offen und Nachfrage

- [ ] Entscheidung zum neotest-Listener: A, D (nach Test) oder weiter beobachten. Siehe Teil 3.
- [ ] Symlink `C:\tools\OpenInNvim` reparieren und Kontextmenü wieder eintragen (Teil 4).
- [ ] Prüfen, ob außerhalb von `E:\repos` etwas den Pipe-Namen oder die Variable benutzt (Teil 1).
- [ ] Die Messskripte (`NT_ALLOW`/`NT_DUMP`-Hilfsskript und Scratch-Projekte mit 9 bzw. 1000 Tests) bei Bedarf
      nach `WKDBooks/.../TOOLS/` legen; sie waren Wegwerf und liegen nur im Scratchpad.
- [ ] Die Aufgabe 1 im Startup-Handover ist mit diesem Ergebnis beantwortet, aber nicht entschieden.

---

## Commits dieses Chats

| Repository | Commit | Beschreibung |
| --- | --- | --- |
| nvim-config | `afe3cee4` | docs(roadmap): Konkurrenzanalyse abgehakt, drei Reports verlinkt |
| Configs | `f02220f` | docs: Verweise auf das umbenannte Repo `openinnvim` |
| nvim-config | (dieser Commit) | docs(handover): NVIM_LISTEN_ADDRESS, neotest-Listener und openinnvim |

Zusätzlich ohne Commit: GitHub-Repo `open-in-nvim` umbenannt in `openinnvim`, Klon nach `E:\repos\openinnvim`.
Review durch `ultracode`: nicht erfolgt (reine Doku).

---

## Messen: Wiederholung

```bash
# Szenario: Testdatei, Hilfsprozess erlaubt (Skript setzt bei VimEnter NVIM_LISTEN_ADDRESS = nil)
cd <Projekt mit lua/ und tests/*_spec.lua>
NT_ALLOW=1 PROBE_MS=8000 nvim --headless -l scripts/startup-probe/bench.lua 5 tui \
  --cmd "luafile <nt_probe.lua>" <Testdatei> > /dev/null < /dev/null
```

`neotest-plenary` findet Tests nur unter einem Verzeichnis mit `lua/` (`root = match_root_pattern("lua")`).
Neotests Signs sieht `sign_getplaced` (und, in 0.12, auch `nvim_buf_get_extmarks` mit `sign_text`). Eine Spec ohne
`it`-Blöcke (z. B. `pickers_spec.lua`) bekommt keine Signs: für Messungen eigene Scratch-Specs benutzen.
