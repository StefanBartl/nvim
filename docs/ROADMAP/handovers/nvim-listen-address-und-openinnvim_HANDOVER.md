# NVIM_LISTEN_ADDRESS (rpc_pipe), neotest-Listener und openinnvim (Übergabe)

Stand: 2026-10-02, aktualisiert in zwei Folgechats (Teil 5 und 6 neu; im zweiten: Tests grün, Filetree-Ordner umgesetzt,
"Offen" fortgeschrieben). Zum
Weiterreichen in einen neuen Chat. Quellen: die neotest-Aufgabe aus
[`startup-offene-entscheidungen-und-neotest-listener-2026-10-02.md`](../reports/startup-offene-entscheidungen-und-neotest-listener-2026-10-02.md)
(Aufgabe 1; Aufgabe 4 und der Punkt "neotest von Hand bedienen" hängen an derselben Testanordnung) und die Suche
nach dem Windows-Kontextmenü-Eintrag "In Neovim öffnen".

---

## Table of content

  - [Kurzfassung](#kurzfassung)
  - [Teil 1: wofür rpc_pipe die Variable exportiert](#teil-1-wofur-rpc_pipe-die-variable-exportiert)
  - [Teil 2: Messung mit UI](#teil-2-messung-mit-ui)
  - [Teil 3: Optionen und Empfehlung](#teil-3-optionen-und-empfehlung)
  - [Teil 4: openinnvim und das kaputte Kontextmenü](#teil-4-openinnvim-und-das-kaputte-kontextmenu)
  - [Teil 5: Reparatur und PID-Pipe-Suche (Folgechat)](#teil-5-reparatur-und-pid-pipe-suche-folgechat)
  - [Teil 6: Plan fuer openinnvim (Filetree, beide Eintraege, Setup-exe)](#teil-6-plan-fuer-openinnvim-filetree-beide-eintraege-setup-exe)
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

## Teil 5: Reparatur und PID-Pipe-Suche (Folgechat)

**Reparatur (erledigt, mit Zustimmung).**

- `C:\tools\OpenInNvim` war eine **Junction** (kein Symlink; braucht weder Admin noch Entwicklermodus, anders als in
  Teil 4 angenommen) auf das entfernte `E:\repos\Configs\Windows\Contextmenu\OpenInNvim`. Sie zeigt jetzt auf
  `E:\repos\openinnvim`. Alte Junction nur als Link gelöscht (`[IO.Directory]::Delete(pfad, $false)`).
- **Registry geprüft, keine Änderung nötig:** alle 6 Einträge (`*\shell`, `Directory\shell`,
  `Directory\Background\shell`, je `Open_in_Neovim_current` und `Open_in_Neovim_new`) zeigen schon auf
  `wscript.exe //nologo "C:\tools\OpenInNvim\open-in-nvim[-current].vbs" "%1"` (`%V` im Hintergrund).
- Skripte parsen fehlerfrei, die VBS-Zielpfade lösen über die Junction auf. **Nicht getestet:** der echte Klick
  bzw. `verify.ps1` (öffnet vier Fenster und schickt Dateien in die laufende Sitzung `nvim-bartl`).
- Nebenbefunde: User-Variable `NVIM_VBS=C:\tools\PowershellSkripte\open-in-nvim.vbs` zeigt auf ein nicht
  existierendes Verzeichnis, wird nirgends gelesen (kann gelöscht werden). `verify.ps1` benutzt `?:`, das in
  Windows PowerShell 5.1 nicht geht (README verspricht 5.1).
- **Außerhalb von `E:\repos` gesucht** (Teil 1, offener Punkt): User-/Maschinen-Umgebungsvariablen, PowerShell- und
  Bash-Profile, `.gitconfig` (kein `core.editor`), Windows-Terminal-Einstellungen. **Niemand benutzt
  `NVIM_LISTEN_ADDRESS` oder den Pipe-Namen.**
- openinnvim `b5aa51d`: README auf `E:\repos\openinnvim` umgestellt; der Deinstallationshinweis
  `Remove-Item -Recurse` auf eine Junction ersetzt (kann in PS 5.1 den Zielordner leeren).

**Befunde zum "current instance"-Ablauf (am Skript und an eigenen Wegwerf-Instanzen gemessen).**

1. **Jede laufende Neovim-Sitzung hat ohne jede Konfiguration eine Pipe `\\.\pipe\nvim.<pid>.<n>`.** `nvim --server
   <pipe> --remote <datei>` landet die Datei in genau dieser Instanz (per RPC nachgeprüft). `serverstart` in der
   `init.lua` und `nvr` sind dafür nicht nötig; der feste Name `nvim-<USERNAME>` (`rpc_pipe`) ist nur ein
   bequemer Zusatz.
2. **Unter Windows sind es zwei Prozesse je TUI-Sitzung:** der sichtbare `nvim.exe` (UI-Client, **ohne** Pipe) und sein
   Kind `nvim.exe --embed` (der Editorkern, **besitzt** die Pipe). Also nach Pipes suchen, nicht nach der PID des
   sichtbaren Fensters. GUIs (Neovide) starten ebenfalls `--embed`; Hilfsprozesse (neotests `--embed --headless`,
   Plugin-Jobs `--headless`, `-l`-Skripte) haben auch Pipes und müssen heraus gefiltert werden.
3. **Fehler im bestehenden Skript, behoben:** (a) `nvim --server … --remote -- <datei>` öffnet in diesem Neovim einen
   Buffer namens `--` (Exit 2); ohne `--` sauber. (b) `nvr --servername \\.\pipe\… --remote` **hängt unter Windows
   endlos**, das Skript probierte `nvr` vor `nvim --remote` und das unsichtbar. (c) `Start-Process … -ArgumentList
   @(…) + $args` wird als zwei Argumente gelesen ("kein Positionsparameter für '+'"): der Pfad "neue Instanz starten"
   (WezTerm, Windows Terminal) war kaputt. Zu (c) siehe "Offen".
4. Neovim-Client mit umgeleiteter Ausgabe schreibt Terminal-Escape-Müll auf stdout (`--remote-expr` ist so nicht
   lesbar); Ergebnisse stattdessen per RPC (`sockconnect`/`nvim_eval`) holen.

**Gebaut (openinnvim, noch nicht committet, Tests laufen):**

- `open-in-nvim.lib.ps1` (neu): Pipe-Aufzählung, Filter (`--headless`, `-l` raus; `--embed` allein bleibt),
  Sortierung `newest|oldest|ask`, kleiner msgpack-RPC-Client (`nvim_eval`) für das Instanz-Label, WinForms-Auswahl
  für `ask`.
- `open-in-nvim-current.ps1`: Reihenfolge `NVIM_SERVER` → fester Pipe-Name (falls vorhanden, `PREFER_STABLE_PIPE`) →
  PID-Pipes nach `INSTANCE_PICK` (Standard `newest`) → `nvr --serverlist` → Fallback neue Instanz. Alle externen
  Aufrufe mit Zeitlimit (`Invoke-Bounded`, tötet nur die eigene PID per `taskkill /T`); `nvr` nur noch als letzte
  Möglichkeit mit `--nostart`. Haken: `OPEN_IN_NVIM_ONLY_PIDS` (nur diese PIDs), `OPEN_IN_NVIM_DRYRUN=1` (Kandidaten
  ausgeben, nichts öffnen).
- `tests/run-tests.ps1` + `tests/fixture.lua`: starten eigene Wegwerf-Instanzen (TUI per Pseudo-Terminal, plus je eine
  `--headless` und `--embed --headless`), prüfen Filter, Reihenfolge, RPC-Label, Auswahlfenster, trockenen Lauf und
  das echte Öffnen (nur in eigenen Instanzen, `USERNAME` wird für den Launcher gefälscht, damit nie die echte Pipe
  `nvim-bartl` getroffen wird). Aufruf: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests\run-tests.ps1`.
- Stand der Tests bei Übergabe: Filter, Reihenfolge, trockener Lauf, Auswahlfenster **grün**; das RPC-Label liefert
  bei `--embed`-Instanzen noch `$null` (in einer `--headless`-Instanz funktioniert dieselbe Funktion; Ursache offen);
  die echten Öffnen-Tests waren am `Start-Process`-`+`-Fehler (c) und an `nvr` gescheitert und müssen nach den
  Korrekturen erneut laufen.

**Fortsetzung (Folge-Chat 2, 2026-10-02): Tests grün, committet und gepusht (`28d358c`, `41c399f`, `a8698cb`).**
42 von 42 Prüfungen, unter Windows PowerShell 5.1. Gefunden und behoben:

1. **Ursache "RPC-Label `$null` bei `--embed`" war nicht der Client, sondern die Fixture.** `Invoke-NvimEval` ist
   korrekt (gegen die echte Sitzung, gegen `--headless --listen` und gegen UI-angedockte Kerne antwortet es in 1-4 ms).
   Ein `nvim --embed`-Kern hinter einem TUI-Client auf einem **bloßen Pty** (`jobstart(..., {pty = true})`, auch mit
   `term = true`) wurde in 77 s nie ansprechbar: sein UI-Attach läuft nicht durch. Die Fixture startet deshalb jetzt
   `nvim --embed`-Kerne und dockt per `nvim_ui_attach` selbst an (das ist, was Neovide macht). Kein Produktfehler.
2. **Hit-Enter-Prompt nach `:cd` (echter Fehler im Launcher).** `:cd <pfad>` gibt den Pfad aus; ist er breiter als das
   Fenster, wartet die Instanz auf eine Taste und beantwortet kein RPC mehr, bis der nächste `--remote-send` mit
   `<C-\><C-n>` den Prompt wegräumt. Alle Befehle aus `Build-RemoteEditCommand` laufen jetzt mit `:silent`.
3. **`Start-Process -ArgumentList @(…) + $args` (c) behoben** (Liste vorher bauen) in WezTerm-, Windows-Terminal-Pfad.
4. `tests/fixture.lua`: `gui1` ohne `:Filetree`, `gui2` mit Attrappe, die ihre Argumente in `g:ft_args` ablegt.
5. `verify.ps1` (`?:`) und `install-context.ps1` (`"$key:"` ist in 5.1 eine ungültige Scope-Variable) parsen jetzt unter
   5.1; **alle** `*.ps1` im Repo parsen fehlerfrei. (Teil 5 hatte "parsen fehlerfrei" unter PowerShell 7 geprüft.)

**Wirkung auf die echte Sitzung:** `C:\tools\OpenInNvim` ist eine Junction auf das Repo, die Kontextmenü-Einträge
benutzen also **ab sofort den neuen Launcher** (`origin/main` von `openinnvim`). Der echte Klick ist weiterhin nicht von
Hand getestet; die Tests laufen nur gegen eigene Wegwerf-Instanzen und die echte Sitzung wurde nie angefasst (nur
lesende `1 + 2`-Abfragen).

---

## Teil 6: Plan fuer openinnvim (Filetree, beide Eintraege, Setup-exe)

Auftrag des Nutzers (2026-10-02):

1. **Zwei Kontextmenü-Einträge bleiben Pflicht, nicht nur "current session":** "Open with Neovim (current instance)"
   **und** "Open with Neovim (new instance)" müssen vom Setup angelegt werden (Datei, Ordner, Ordner-Hintergrund,
   also die bisherigen 6 Einträge).
2. **Ziel von "current":** eine Datei in der aktuell laufenden Sitzung öffnen. Dass diese Sitzung unter Windows ein
   Pseudo-Terminal-/`--embed`-Konstrukt ist, ist ein Implementierungsdetail der Suche, kein Ziel.
3. **Ordner im Filetree öffnen:** Rechtsklick auf einen Ordner soll in der laufenden Sitzung `filetree.nvim` auf
   diesen Ordner richten. **Machbar:** `filetree.nvim` hat `:Filetree open <dir-or-file>` ("Open the tree focused on
   a directory or file", `docs/BINDINGS/USERCOMMANDS.md`, Zeile 219), und von außen lässt sich jeder Ex-Befehl in eine
   laufende Sitzung schicken (`--remote-send` oder, robuster und modusunabhängig, RPC `nvim_command`). Umsetzung:
   per RPC prüfen, ob `exists(':Filetree') == 2`; wenn ja `:Filetree open <pfad>`, sonst `:edit <pfad>`. Dateien
   weiter per `:edit`/`--remote`. Gehört als Option in die Config (z. B. `FOLDER_OPENS_IN = 'filetree' | 'edit'`).
   Die Antwort auf "geht das, von außen einen Befehl zu senden?" ist ja. **Umgesetzt und geprüft (`41c399f`):**
   `FOLDER_OPENS_IN = 'filetree' | 'edit'` (Standard `filetree`); der Launcher fragt per RPC `exists(':Filetree') == 2`
   ab (nur bei `\\.\pipe\`-Adressen) und sendet `:silent execute 'Filetree open ' . fnameescape('<dir>')`, sonst
   Rückfall auf cd + `:edit .`. **Gegen die echte Config geprüft** (Wegwerf-Instanz mit UI-Attach, ohne die laufende
   Sitzung): aus einer Sitzung ohne Baum öffnet `:Filetree open <dir>` das neo-tree-Fenster, auf den Ordner gerichtet,
   und das cwd folgt; Pfade mit Leerzeichen laufen mit schlichtem `fnameescape` (`inner\ dir`) und mit
   Schrägstrich-Variante gleich. Nicht geprüft: Verhalten bei bereits offenem, anders gewurzeltem Baum (kein Fehler
   erwartet, `go_to` ruft `set_root`).
4. **Verteilung:** zunächst **kein** Release-Zip. Erst wenn alles fertig ist, ein **fertiger Setup-`.exe`-Installer**
   (Inno Setup, gebaut in GitHub Actions; Doppelklick, Eintrag unter "Apps", Deinstallation inklusive). Davor:
   `install.ps1`/`uninstall.ps1` (ohne Admin, nur `HKCU`, Installation nach `%LOCALAPPDATA%\OpenInNvim`, VBS finden ihr
   `.ps1` relativ zu sich selbst statt über das feste `C:\tools\OpenInNvim`; `nvim.exe` automatisch finden und in die
   Config schreiben; **keine** Änderung von Dateizuordnungen wie in `deploy-open-in-nvim.ps1`).
5. **Grenze:** Einträge unter `HKCU\...\shell` erscheinen unter Windows 11 nur im klassischen Menü ("Weitere Optionen
   anzeigen"); oberste Ebene bräuchte eine `IExplorerCommand`-Shell-Erweiterung (eigenes Projekt).
6. **Noch nicht verifiziert:** Fokus des Terminalfensters der gewählten Sitzung nach dem Öffnen (unter Windows bekommt
   ein Hintergrundprozess keinen Fokus; Terminalfenster gezielt aktivieren). Hinweis: im Claude-Memory liegt die Notiz
   "Windows: Fokus, detach, .COM-Kill, winget-PATH, shell-Quoting" (`windows-foreground-and-detach.md`).

---

## Offen und Nachfrage

- [ ] Entscheidung zum neotest-Listener: A, D (nach Test) oder weiter beobachten. Siehe Teil 3. **Ein Workflow testet
      gerade, ob `serverstop` auf den Listener (Option D) einen echten `<leader>nt*`-Lauf übersteht (Agent 1) und
      den positiven Fall des Attach-Fixes aus Aufgabe 4 (Agent 2).** Ergebnisse stehen noch aus und gehören hierher.
- [x] Symlink `C:\tools\OpenInNvim` reparieren (Teil 5; es war eine Junction, jetzt auf `E:\repos\openinnvim`).
      Registry war schon richtig. Der echte Klick-Test steht aus (macht der Nutzer selbst).
- [x] Prüfen, ob außerhalb von `E:\repos` etwas den Pipe-Namen oder die Variable benutzt: **nein** (Teil 5).
- [x] openinnvim: Tests grün (42/42), `Start-Process`-Fehler (c) behoben, `:Filetree open` für Ordner mit
      Konfig-Option `FOLDER_OPENS_IN`, `verify.ps1`/`install-context.ps1` unter PS 5.1 lauffähig (Teil 5, 6).
- [ ] openinnvim: VBS-Pfade relativ zur VBS (statt festem `C:\tools\OpenInNvim`), `install.ps1`/`uninstall.ps1` mit
      beiden Menüeinträgen, zuletzt Setup-`.exe` (Teil 6, Punkt 4). Das ändert den Installationsort; vorher Rückfrage.
- [ ] openinnvim: Fokus des Terminalfensters nach dem Öffnen (Teil 6, Punkt 6) ist ungelöst und ungetestet.
- [ ] openinnvim: echter Klick im Explorer durch den Nutzer (alle vier Fälle: Datei/Ordner, current/new). Hier ist der
      Launcher neu, siehe "Wirkung auf die echte Sitzung" in Teil 5.
- [ ] Die Messskripte (`NT_ALLOW`/`NT_DUMP`-Hilfsskript und Scratch-Projekte mit 9 bzw. 1000 Tests) bei Bedarf
      nach `WKDBooks/.../TOOLS/` legen; sie waren Wegwerf und liegen nur im Scratchpad. (Der Workflow baut ähnliche
      Skripte neu; danach entscheiden, was nach `TOOLS/` gehört.)
- [ ] Die Aufgabe 1 im Startup-Handover ist mit diesem Ergebnis beantwortet, aber nicht entschieden.

---

## Commits dieses Chats

| Repository | Commit | Beschreibung |
| --- | --- | --- |
| nvim-config | `afe3cee4` | docs(roadmap): Konkurrenzanalyse abgehakt, drei Reports verlinkt |
| Configs | `f02220f` | docs: Verweise auf das umbenannte Repo `openinnvim` |
| nvim-config | `0d3ba109` | docs(handover): NVIM_LISTEN_ADDRESS, neotest-Listener und openinnvim |
| openinnvim | `b5aa51d` | docs(readme): neuer Repo-Pfad, sichere Junction-Entfernung |
| nvim-config | `e5075b1d` | docs(handover): Reparatur, PID-Pipe-Suche, Filetree-Plan (Teil 5 und 6) |
| openinnvim | `28d358c` | feat(current): discover running instances via their default pipes (inkl. `:silent`, `(c)`, Tests) |
| openinnvim | `41c399f` | feat(current): open folders in filetree.nvim when the instance has it |
| openinnvim | `a8698cb` | fix(ps51): `?:` in verify.ps1 und `"$key:"` in install-context.ps1 |
| nvim-config | (dieser Commit) | docs(handover): Folge-Chat 2, Tests grün, Filetree umgesetzt |

Zusätzlich ohne Commit: GitHub-Repo `open-in-nvim` umbenannt in `openinnvim`, Klon nach `E:\repos\openinnvim`;
Junction `C:\tools\OpenInNvim` umgesetzt (kein Git).
Review durch `ultracode`: **für die drei openinnvim-Commits nicht erfolgt** (kein Haken); die Handover-Commits sind reine Doku.

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
