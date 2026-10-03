# openinnvim — Live-Test-Checkliste (Stand 2026-10-02)

Alles, was an `openinnvim` (Explorer-Kontextmenü für Neovim, Repo
`E:\repos\openinnvim`) und an den offenen Punkten der Handover
`E:\repos\openinnvim\docs\HANDOVER.md` **von Hand im echten System** geprüft
werden muss. Automatisiert läuft alles grün (`tests\run-tests.ps1`, 104 Prüfungen unter
Windows PowerShell 5.1, gegen Wegwerf-Instanzen) — diese Liste ist für das, was Tests nicht
zeigen: der **echte Klick im Explorer**, die echte Sitzung, die echte Config, Fokus,
Gefühl für die Geschwindigkeit.

**Wichtig:** Noch zeigen die Einträge über die alte Junction `C:\tools\OpenInNvim` auf das
Repo und benutzen deshalb **schon jetzt** den neuen Launcher. Mit **Teil G** installierst du
neu (`install.ps1`): danach laufen sie aus `%LOCALAPPDATA%\OpenInNvim`, die Junction wird
überflüssig. **Empfohlene Reihenfolge: erst Vorbereitung und Teil G, dann A–F.** Bis zum
Durchlauf ist alles ungeprüft.

**Status:** ❌ ungetestet · 🟡 teilweise · ✅ wie erwartet · 🔴 Fehler (Notiz ausfüllen!).
Ein gefundener Fehler gehört zusätzlich in
`WKDBooks/Development/wkdbook-myplugins/openinnvim/ROADMAP/ROADMAP.md` oder als
GitHub-Issue — nicht nur hierher.

## Inhalt

- [Vorbereitung](#vorbereitung)
- [Teil A — "Open with Neovim (current instance)"](#teil-a--open-with-neovim-current-instance)
- [Teil B — Ordner und Filetree](#teil-b--ordner-und-filetree)
- [Teil C — Mehrere Instanzen](#teil-c--mehrere-instanzen)
- [Teil D — Keine Instanz erreichbar (neue Instanz)](#teil-d--keine-instanz-erreichbar-neue-instanz)
- [Teil E — "Open with Neovim (new instance)"](#teil-e--open-with-neovim-new-instance)
- [Teil F — Grenzfälle der laufenden Sitzung](#teil-f--grenzfälle-der-laufenden-sitzung)
- [Teil G — Installation, Deinstallation, Registry](#teil-g--installation-deinstallation-registry)
- [Teil H — Diagnose-Schalter und Tests](#teil-h--diagnose-schalter-und-tests)
- [Teil I — Default-Apps (nur wenn du es nutzt)](#teil-i--default-apps-nur-wenn-du-es-nutzt)
- [Teil J — Doku auf GitHub](#teil-j--doku-auf-github)
- [Teil K — neotest-Listener (Entscheidung A oder D)](#teil-k--neotest-listener-entscheidung-a-oder-d)
- [Nach dem Durchlauf](#nach-dem-durchlauf)

---

## Vorbereitung

**Stand holen.** Beide Repos pullen, Neovim in der Sitzung, in der du testest, **neu
starten** (der feste Pipe-Name `nvim-<USER>` kommt aus `rpc_pipe` beim Start):

```powershell
git -C E:\repos\openinnvim pull
git -C E:\repos\WKDBooks pull
Test-Path E:\repos\openinnvim\install.ps1   # muss True sein
```

Dann **`install.ps1` ausführen — Teil G, G1 und G2** — und erst danach die Teile A–F. Die
Konfiguration, die du in den Teilen A–F änderst (`INSTANCE_PICK` usw.), liegt in der
installierten Config unter `%LOCALAPPDATA%\OpenInNvim\open-in-nvim.config.ps1`.

Testdateien anlegen (einmalig, auf dem Desktop):

```powershell
$t = "$env:USERPROFILE\Desktop\oin-test"
New-Item -ItemType Directory -Force "$t\My Dir (1) #2 [x] 'q' %p & more" | Out-Null
New-Item -ItemType Directory -Force "$t\einfach" | Out-Null
Set-Content "$t\einfach\plain.txt" 'plain'
Set-Content "$t\My Dir (1) #2 [x] 'q' %p & more\note #1 [a].txt" 'special'
Set-Content "$t\datei mit leerzeichen.txt" 'space'
```

| # | Was testen | Erwartung | Status | Notizen |
| --- | --- | --- | --- | --- |
| V1 | Rechtsklick auf `plain.txt` → "Weitere Optionen anzeigen" | Beide Einträge "Open with Neovim (new instance)" und "(current instance)" sind da, mit Neovim-Icon | ❌ | |
| V2 | `:echo v:servername` in der Test-Sitzung | `\\.\pipe\nvim-<USER>` (fester Name) oder `\\.\pipe\nvim.<pid>.0` | ❌ | |
| V3 | Dry-Run: `$env:OPEN_IN_NVIM_DRYRUN='1'; powershell -NoProfile -ExecutionPolicy Bypass -File "$env:LOCALAPPDATA\OpenInNvim\open-in-nvim-current.ps1" "$env:USERPROFILE\Desktop\oin-test\einfach\plain.txt"` | Gibt `candidate:`-Zeilen aus, die Test-Sitzung steht drin, **ohne** dass etwas geöffnet wird | ❌ | |

---

## Teil A — "Open with Neovim (current instance)"

Eine einzelne Neovim-Sitzung läuft (TUI im Terminal, wie du sie sonst benutzt).

| # | Was testen | Erwartung | Status | Notizen |
| --- | --- | --- | --- | --- |
| A1 | Klick **current** auf `plain.txt` | Datei erscheint **in der laufenden Sitzung**, kein neues Fenster, kein Konsolen-Flackern | ❌ | |
| A2 | Geschwindigkeit des Klicks | Gefühlt unter einer Sekunde (gemessen ca. 0,5 s inkl. PowerShell-Start; früher ca. 1,1 s) | ❌ | |
| A3 | Klick **current** auf `datei mit leerzeichen.txt` | Öffnet, Puffername mit Leerzeichen korrekt | ❌ | |
| A4 | Klick **current** auf `note #1 [a].txt` (Ordner `My Dir (1) #2 [x] 'q' %p & more`) | Öffnet, Pfad unverändert (`#`, `%`, `[`, `(`, `'`, `&`) — früher ein Risiko | ❌ | |
| A5 | Dieselbe Datei **zweimal** klicken | Kein zweiter Buffer; das vorhandene Fenster wird wiederverwendet (`:drop`) | ❌ | |
| A6 | Eine Datei öffnen, deren Buffer **geändert, ungespeichert** ist, danach eine andere klicken | Neue Datei kommt (Split oder Fehlermeldung `E37`), **nichts geht verloren**, Neovim hängt nicht | ❌ | |
| A7 | Während du im **Insert-Modus** tippst, klicken | Datei öffnet; notiere, in welchem Modus du danach bist und ob der Text im Buffer unverändert ist | ❌ | |
| A8 | Während du `:` (Kommandozeile) offen hast, klicken | Datei öffnet oder der Klick wartet kurz; Neovim friert nicht ein | ❌ | |
| A9 | Fokus: kommt das Terminalfenster mit Neovim nach dem Klick **nach vorn**? | Offen/bekannt: unter Windows bekommt ein Hintergrundprozess keinen Fokus. Notiere, was passiert (Taskleiste blinkt?) | ❌ | |
| A9b | `FOCUS_TERMINAL = $true` in der **installierten** Config (`%LOCALAPPDATA%\OpenInNvim\open-in-nvim.config.ps1`), ein anderes Fenster im Vordergrund, dann klicken | Das Terminalfenster der Sitzung kommt nach vorn (auch aus der Taskleiste, wenn minimiert). Notiere die Dauer (erwartet ca. 0,3-0,5 s mehr) und ob bei **mehreren Terminalfenstern** das richtige kommt (bekannte Grenze: es kann das falsche sein). Danach entscheiden: opt-in lassen oder Standard? | ❌ | |
| A10 | Ein langer Pfad (> Fensterbreite), z. B. tief verschachtelte Datei | Öffnet ohne Hit-Enter-Prompt in Neovim (früher `:cd` mit langem Pfad → Instanz hing) | ❌ | |
| A11 | Neovim hat ein **Terminal-Buffer** im aktiven Fenster, dann klicken | Datei öffnet in einem normalen Fenster, das Terminal läuft weiter | ❌ | |

---

## Teil B — Ordner und Filetree

| # | Was testen | Erwartung | Status | Notizen |
| --- | --- | --- | --- | --- |
| B1 | Klick **current** auf Ordner `einfach` (Sitzung hat `:Filetree`, **kein** Baum offen) | Der Baum (neo-tree) öffnet **auf diesem Ordner**; das Arbeitsverzeichnis folgt (`:pwd`) | ❌ | |
| B2 | Dasselbe mit **bereits offenem**, anders gewurzeltem Baum | Baum springt auf den Ordner, kein Fehler, kein zweiter Baum (offen in der ROADMAP: ungetestet) | ❌ | |
| B3 | Ordner `My Dir (1) #2 [x] 'q' %p & more` | Baum öffnet auf genau diesem Ordner (früher: still ohne Wirkung) | ❌ | |
| B4 | Rechtsklick auf den **Hintergrund** eines Explorer-Fensters → current | Baum/Arbeitsverzeichnis = der Ordner dieses Fensters (`%V`) | ❌ | |
| B5 | `FOLDER_OPENS_IN = 'edit'` in `open-in-nvim.config.ps1`, dann Ordner klicken | Arbeitsverzeichnis wechselt, **Verzeichnisansicht** (`:edit .`), **kein** Baum. Danach **zurück auf `'filetree'`** | ❌ | |
| B6 | Sitzung **ohne** filetree.nvim (`nvim --clean`), Ordner klicken | Verzeichnisansicht + Arbeitsverzeichnis, keine Fehlermeldung | ❌ | |
| B7 | Laufwerks-Root als Ordner (Rechtsklick auf Hintergrund von `C:\`) | Öffnet, kein Quoting-Fehler | ❌ | |

---

## Teil C — Mehrere Instanzen

Starte **zwei** Neovim-Sitzungen (A zuerst, B danach) in getrennten Fenstern.

| # | Was testen | Erwartung | Status | Notizen |
| --- | --- | --- | --- | --- |
| C1 | `INSTANCE_PICK = 'newest'` (Standard): Klick auf eine Datei | Landet in **B** (zuletzt gestartet) — außer A besitzt den festen Namen `nvim-<USER>` und `PREFER_STABLE_PIPE` ist an: dann in **A**. Notiere, welcher Fall gilt | ❌ | |
| C2 | `PREFER_STABLE_PIPE = $false` | Reihenfolge nur nach `INSTANCE_PICK` (jetzt sicher B) | ❌ | |
| C3 | `INSTANCE_PICK = 'oldest'` (mit `PREFER_STABLE_PIPE = $false`) | Landet in **A** | ❌ | |
| C4 | `INSTANCE_PICK = 'ask'` | Auswahlfenster "Open in Neovim - choose instance" mit Arbeitsverzeichnis, Datei, PID, Startzeit je Instanz | ❌ | |
| C5 | `ask`: Eintrag wählen + Enter / Doppelklick | Datei landet in der gewählten Instanz | ❌ | |
| C6 | `ask`: Escape | Fenster schließt, es wird **nichts** geöffnet, keine neue Instanz | ❌ | |
| C7 | `ask` mit nur **einer** Instanz | Kein Fenster, direkt geöffnet | ❌ | |
| C8 | Ein `nvim --headless --listen \\.\pipe\oin-headless` im Hintergrund + normaler Klick | Der Headless-Server wird **nie** gewählt (Dry-Run: nicht unter den Kandidaten) | ❌ | |
| C9 | Ein Plugin-Job/neotest-Hilfsprozess läuft (z. B. `<leader>nt*` ausführen) und gleichzeitig klicken | Landet in der Hauptsitzung, nicht im Hilfsprozess | ❌ | |
| C10 | Einstellungen am Ende **zurücksetzen** (`newest`, `$true`, `'filetree'`) | Config-Datei wieder im Standard (`git -C E:\repos\openinnvim diff` leer) | ❌ | |

---

## Teil D — Keine Instanz erreichbar (neue Instanz)

Alle Neovim-Fenster **schließen**.

| # | Was testen | Erwartung | Status | Notizen |
| --- | --- | --- | --- | --- |
| D1 | Klick **current** auf `plain.txt` | Neues Terminal (WezTerm) startet Neovim **mit der Datei geöffnet** und dem Ordner als Arbeitsverzeichnis. (Früher ging die Datei hier verloren: `$args`-Fehler.) | ❌ | |
| D2 | Danach **zweiter** Klick **current** auf `datei mit leerzeichen.txt` | Landet in der gerade gestarteten Instanz (sie lauscht auf `\\.\pipe\nvim-<USER>`), kein weiteres Fenster | ❌ | |
| D3 | Klick **current** auf einen Ordner ohne laufende Instanz | Neues Terminal, Neovim im Ordner, ohne Datei | ❌ | |
| D4 | Pfad mit Leerzeichen und Sonderzeichen (`note #1 [a].txt`) als Startdatei | Neues Neovim zeigt genau diese Datei, Arbeitsverzeichnis = ihr Ordner | ❌ | |
| D5 | WezTerm **nicht** verfügbar (`WEZTERM_BIN` in der Config auf einen falschen Pfad **und** wezterm nicht im PATH — oder Dry-Run: `$env:OPEN_IN_NVIM_SPAWN_DRYRUN='1'`) | Windows Terminal (`wt`) wird genommen; ohne `wt` zuletzt `cmd.exe`. Der `cmd start`-Pfad lief vorher **nie** (Fehler in 5.1): einmal real prüfen | ❌ | |
| D6 | Das neue Fenster: bleibt der Launcher-Prozess im Hintergrund hängen? (`Get-Process powershell` direkt danach) | Kein verwaister versteckter PowerShell-Prozess (früher blockierte der WezTerm-Aufruf, bis das Terminal geschlossen wurde) | ❌ | |

---

## Teil E — "Open with Neovim (new instance)"

| # | Was testen | Erwartung | Status | Notizen |
| --- | --- | --- | --- | --- |
| E1 | Klick **new** auf `plain.txt` **bei laufender Sitzung** | **Immer** ein neues Terminal mit neuem Neovim **und der Datei** (früher: Datei ging verloren, `$args`-Fehler) | ❌ | |
| E2 | Klick **new** auf `datei mit leerzeichen.txt` | Neues Fenster, Datei korrekt, Arbeitsverzeichnis = Ordner der Datei | ❌ | |
| E3 | Klick **new** auf `note #1 [a].txt` | Datei korrekt geöffnet | ❌ | |
| E4 | Klick **new** auf einen Ordner / Ordner-Hintergrund | Neues Neovim im Ordner, ohne Datei | ❌ | |
| E5 | Klick **new** auf `C:\` (Hintergrund eines Laufwerks) | Startet, Quoting korrekt (früher brach `"C:\"`) | ❌ | |
| E6 | Das alte Fenster wird **nicht** angefasst | Laufende Sitzung unverändert | ❌ | |
| E7 | `OPEN_IN_NVIM_DEBUG=1` und `NVIM_BIN` auf einen falschen Pfad | Popup "Neovim not found" (nur "new instance"); danach **zurücksetzen** | ❌ | |

---

## Teil F — Grenzfälle der laufenden Sitzung

| # | Was testen | Erwartung | Status | Notizen |
| --- | --- | --- | --- | --- |
| F1 | In der Sitzung `:sleep 20` laufen lassen, in dieser Zeit klicken | Der Launcher gibt nach wenigen Sekunden auf und startet eine **neue** Instanz (oder öffnet nach dem Sleep) — kein dauerhaft hängender PowerShell-Prozess | ❌ | |
| F2 | In der Sitzung einen **Hit-Enter-Prompt** erzeugen (`:echo repeat("x\n", 40)`), dann klicken | Sitzung wird nicht dauerhaft blockiert; notiere, was passiert | ❌ | |
| F3 | Neovim mit `NVIM_APPNAME`/anderer Config (`nvim --clean`) als einzige Sitzung | Wird gefunden (hat ein UI) und beliefert | ❌ | |
| F4 | Neovide/anderes GUI, falls benutzt | Wird gefunden und beliefert (`--embed` mit UI) | ❌ | |
| F5 | Datei, die gerade in einer **anderen** Sitzung offen und gesperrt/Swap-Datei ist | Neovim zeigt seinen üblichen Swap-Dialog/-Hinweis; der Launcher bleibt nicht hängen | ❌ | |
| F6 | Sehr langer Pfad (> 200 Zeichen) | Öffnet oder liefert eine klare Fehlermeldung, keine Hänger | ❌ | |

---

## Teil G — Installation, Deinstallation, Registry

| # | Was testen | Erwartung | Status | Notizen |
| --- | --- | --- | --- | --- |
| G1 | `powershell -NoProfile -ExecutionPolicy Bypass -File E:\repos\openinnvim\install.ps1 -DryRun` | Listet Kopieren, Config, 6 `Write HKCU\...`-Zeilen und "Dry run, nothing was changed"; verändert nichts (`Get-ItemProperty -LiteralPath 'HKCU:\Software\Classes\*\shell\Open_in_Neovim_current\command'` zeigt weiter die alte Junction) | ❌ | |
| G2 | Echte Installation: `... install.ps1` (ohne `-DryRun`) | Meldet `Neovim: <Pfad>` (richtig erkannt), kopiert nach `%LOCALAPPDATA%\OpenInNvim`, "Installed:" mit beiden Einträgen, keine Fehler. **Hinweis:** der Ordner enthält schon die alten Exe/VBS der Default-App-Variante; die VBS werden durch die neuen (relativen) ersetzt | ❌ | |
| G3 | Inhalt von `%LOCALAPPDATA%\OpenInNvim` | `open-in-nvim.vbs`, `open-in-nvim-current.vbs`, `open-in-nvim.ps1`, `open-in-nvim-current.ps1`, `open-in-nvim.lib.ps1`, `open-in-nvim.config.ps1`, `install.manifest.txt`; in der Config steht dein `NVIM_BIN` | ❌ | |
| G4 | `Get-ItemProperty -LiteralPath 'HKCU:\Software\Classes\*\shell\Open_in_Neovim_current\command'` | `wscript.exe //nologo "C:\Users\...\OpenInNvim\open-in-nvim-current.vbs" "%1"` (nicht mehr `C:\tools`) | ❌ | |
| G5 | Alle **6** Schlüssel vorhanden (`*`, `Directory`, `Directory\Background` je `_new`/`_current`), Hintergrund nutzt `%V` | Siehe `docs/BINDINGS.md` | ❌ | |
| G6 | Rechtsklick auf eine Datei: Einträge **nicht doppelt** | Je ein "new" und "current" (alte Einträge früherer Versionen wurden entfernt) | ❌ | |
| G7 | **Danach Teile A–F durchklicken** (jetzt über die installierte Kopie) | Wie dort beschrieben | ❌ | |
| G8 | Erneut `install.ps1` ausführen | Läuft ohne Fehler; "Config kept" — deine Änderungen an der Config bleiben | ❌ | |
| G9 | Verschiebe/benenne `E:\repos\openinnvim` **nicht** um und klicke: läuft aus der Kopie | Klick funktioniert unabhängig vom Repo-Ort (die alte Junction wird nicht mehr gebraucht) | ❌ | |
| G10 | `install.ps1 -InstallDir E:\repos\openinnvim` (in place, Entwicklung) | Einträge zeigen auf das Repo, die Repo-Config bleibt unverändert (`git -C E:\repos\openinnvim status` sauber). **Danach wieder `install.ps1` ohne Parameter**, damit der normale Zustand gilt | ❌ | |
| G11 | `uninstall.ps1 -DryRun`, dann `uninstall.ps1` (nur Einträge) | Alle 6 Einträge weg, Dateien und Config bleiben; Klick im Explorer zeigt keine Neovim-Einträge mehr. **Danach `install.ps1` erneut** | ❌ | |
| G12 | `uninstall.ps1 -RemoveFiles` (nur testen, wenn du die Default-App-Exes **nicht** brauchst, sonst überspringen: deren VBS lägen in demselben Ordner) | Löscht genau die Manifest-Dateien, Config bleibt; der Ordner bleibt, solange er nicht leer ist | ❌ | |
| G13 | Alte Junction entfernen (nur den Link!): `[IO.Directory]::Delete('C:\tools\OpenInNvim', $false)` — **erst nach G7** | Klicks funktionieren weiter; das Repo `E:\repos\openinnvim` ist unversehrt | ❌ | |
| G14 | `verify.ps1` aus dem **Repo** (öffnet **echte Fenster** und schickt Dateien in die laufende Sitzung): `powershell -NoProfile -ExecutionPolicy Bypass -File E:\repos\openinnvim\verify.ps1`. Es wird nicht in den Installationsordner kopiert und prüft die VBS **im Repo** (jede findet ihr `.ps1` daneben), nicht die installierte Kopie | Vier Läufe ohne Fehler (`?:` war unter 5.1 kaputt) | ❌ | |
| G15 | Windows 11: stehen die Einträge **nur** unter "Weitere Optionen anzeigen"? | Ja — bekannte Grenze (oberste Ebene bräuchte eine Shell-Erweiterung) | ❌ | |
| G16 | User-Variable `NVIM_VBS` (zeigt auf nicht existierendes `C:\tools\PowershellSkripte\...`) | Wird nirgends gelesen; kann gelöscht werden (`[Environment]::SetEnvironmentVariable('NVIM_VBS',$null,'User')`) | ❌ | |

--- | --- | --- | --- | --- |
| G1 | `powershell -NoProfile -ExecutionPolicy Bypass -File C:\tools\OpenInNvim\install-context.ps1` (idempotent, schreibt `HKCU`) | Läuft ohne Fehler (PS 5.1; früher Parser-Fehler in Zeile 29), meldet beide Einträge. Danach alle Teile A–E nochmal kurz anklicken | ❌ | |
| G2 | `Get-ItemProperty -LiteralPath 'HKCU:\Software\Classes\*\shell\Open_in_Neovim_current\command'` | `wscript.exe //nologo "C:\tools\OpenInNvim\open-in-nvim-current.vbs" "%1"` | ❌ | |
| G3 | Alle **6** Schlüssel vorhanden (`*`, `Directory`, `Directory\Background` je `_new`/`_current`) | Siehe `docs/BINDINGS.md`; Hintergrund-Einträge nutzen `%V` | ❌ | |
| G4 | Junction nach Neustart des Rechners | `C:\tools\OpenInNvim` löst noch auf | ❌ | |
| G5 | `verify.ps1` (öffnet **echte Fenster** und schickt Dateien in die laufende Sitzung): `powershell -NoProfile -ExecutionPolicy Bypass -File C:\tools\OpenInNvim\verify.ps1` | Vier Läufe ohne Fehler (`?:` war unter 5.1 kaputt); Hinweis am Ende | ❌ | |
| G6 | Windows 11: stehen die Einträge **nur** unter "Weitere Optionen anzeigen"? | Ja — bekannte Grenze (oberste Ebene bräuchte eine Shell-Erweiterung) | ❌ | |
| G7 | User-Variable `NVIM_VBS` (zeigt auf nicht existierendes `C:\tools\PowershellSkripte\...`) | Wird nirgends gelesen; kann gelöscht werden (`[Environment]::SetEnvironmentVariable('NVIM_VBS',$null,'User')`) | ❌ | |

---

## Teil H — Diagnose-Schalter und Tests

| # | Was testen | Erwartung | Status | Notizen |
| --- | --- | --- | --- | --- |
| H1 | `$env:OPEN_IN_NVIM_DRYRUN='1'` + current-Skript | Druckt die geordneten Kandidaten, öffnet nichts, Dauer ca. 0,5 s | ❌ | |
| H2 | `$env:OPEN_IN_NVIM_SPAWN_DRYRUN='1'` ohne laufende Instanz | Druckt **eine** `spawn:`-Zeile mit `"--listen" "\\.\pipe\nvim-<USER>"` und `"--" "<Datei>"`, startet nichts | ❌ | |
| H3 | `$env:OPEN_IN_NVIM_NO_SPAWN='1'` ohne laufende Instanz | Meldet `no reachable instance`, Exit-Code 3, **kein** Fenster | ❌ | |
| H4 | `$env:OPEN_IN_NVIM_ONLY_PIDS='999999'` | Keine Kandidaten außer dem Fallback-Namen im Dry-Run; echte Sitzung wird nie erreicht | ❌ | |
| H5 | `powershell.exe -NoProfile -ExecutionPolicy Bypass -File E:\repos\openinnvim\tests\run-tests.ps1` | `passed: 104  failed: 0`, anschließend **keine** übrigen `nvim`-Prozesse außer deinen eigenen | ❌ | |
| H6 | Während die Tests laufen: deine eigene Sitzung | Bleibt unberührt (kein neuer Buffer, kein Verzeichniswechsel) | ❌ | |
| H7 | `stylua --check E:\repos\openinnvim\tests\fixture.lua` und `luacheck E:\repos\openinnvim\tests\fixture.lua` | Beide sauber | ❌ | |

---

## Teil I — Default-Apps (nur wenn du es nutzt)

Optionaler Weg über zwei Exe-Launcher (`docs/FEATURES/DEFAULT-APPS.md`). Überspringen, wenn
du nur das Kontextmenü brauchst.

| # | Was testen | Erwartung | Status | Notizen |
| --- | --- | --- | --- | --- |
| I1 | Doppelklick auf eine `.md`-Datei | Öffnet im gewählten Modus (new/current) | ❌ | |
| I2 | Einstellungen → Apps → Standard-Apps: "Neovim (new instance)" / "(current instance)" | Beide mit Logo und korrektem Text (offener Bug: "Microsoft Windows Based Script Host" statt Name/Logo bei "new") | ❌ | |
| I3 | Die read-only-Prüfbefehle aus `docs/FEATURES/DEFAULT-APPS.md` | Beide ProgIDs mit Icon, Open-Command, Capabilities | ❌ | |
| I4 | Der Exe-Launcher ruft die VBS neben sich auf, diese das `.ps1` daneben | Funktioniert, wenn `deploy-open-in-nvim.ps1` die `.ps1`/Lib mitkopiert hat (neu): nach dem Deploy Doppelklick auf eine Datei prüfen | ❌ | |
| I5 | `register-nvim-default-app.ps1` starten (nur wenn du den Weg nutzt) | Abfrage und Meldungen jetzt **englisch** und ohne Zeichensalat; die Dateitypen kommen aus `file-extensions.ps1` (eine Liste, 79 Einträge): in den Standard-Apps erscheinen sie wie zuvor | ❌ | |

---

## Teil J — Doku auf GitHub

| # | Was testen | Erwartung | Status | Notizen |
| --- | --- | --- | --- | --- |
| J1 | `https://github.com/StefanBartl/openinnvim` | README rendert: Status-Blockquote, ASCII-Art (OPENINNVIM, nicht verschoben), Badges, Dokuliste | ❌ | |
| J2 | Alle Links der Dokuliste anklicken | Keine 404 (lokal bereits geprüft: keine toten relativen Links) | ❌ | |
| J3 | Alte Adresse `StefanBartl/open-in-nvim` | Leitet auf `openinnvim` weiter | ❌ | |
| J4 | GitHub-Beschreibung und Topics | Noch **nicht** gesetzt (`NEW-04`, `NEW-05`): `gh repo edit StefanBartl/openinnvim --description "..." --add-topic neovim,windows,powershell` | ❌ | |
| J5 | Texte in `docs/` quergelesen | Stimmen mit dem überein, was du in den Teilen A–E gesehen hast (v. a. `FEATURES/CURRENT-INSTANCE.md`, `troubleshooting.md`) | ❌ | |

---

## Teil K — neotest-Listener (Entscheidung A oder D)

Gehört zur selben Handover, hat aber mit dem Kontextmenü nichts zu tun. **Entschieden ist
nichts.** Hintergrund und Messwerte: WKDBooks `openinnvim/Backlog/TASKS/2026-10-02_neotest-listener-messung.md`.

| # | Was testen | Erwartung | Status | Notizen |
| --- | --- | --- | --- | --- |
| K1 | Neovim starten, `:echo serverlist()` | Enthält `nvim.<pid>.0`, `localhost:<port>` (der neotest-Listener) und die fzf-lua-Pipe | ❌ | |
| K2 | Option D probeweise: den `localhost:<port>`-Eintrag mit `:call serverstop('127.0.0.1:<port>')` schließen, dann einen Testlauf `<leader>nt*` ausführen | Ergebnisse **und** Signs kommen wie sonst. Wenn ja → D ist machbar; wenn nein → A (lassen, dokumentieren) | ❌ | |
| K3 | Bei K2: `:echo serverlist()` danach | Der Listener-Eintrag fehlt; die Kontextmenü-Klicks (Teil A) funktionieren weiter (sie brauchen nur die Pipe) | ❌ | |
| K4 | Entscheidung festhalten | A oder D im Handover eintragen; bei D die Änderung in `lua/plugins/neotest.lua` als eigener Task | ❌ | |

---

## Nach dem Durchlauf

- Gefundene Fehler: `WKDBooks/Development/wkdbook-myplugins/openinnvim/ROADMAP/ROADMAP.md`
  (Abschnitt Verhalten) oder GitHub-Issue; bei Fehlern im Review-Pfad zusätzlich ein Hinweis
  in der Backlog-Datei `TASKS/2026-10-02_openinnvim-review.md`.
- Alles ✅ → in der ROADMAP den Punkt "Echter Klick im Explorer" abhaken und diese Datei
  nach `WKDBooks/.../openinnvim/Backlog/TASKS/` verschieben.
- Einstellungen, die du zum Testen geändert hast (`INSTANCE_PICK`, `PREFER_STABLE_PIPE`,
  `FOLDER_OPENS_IN`, `FOCUS_TERMINAL`, `NVIM_BIN`), auf den Standard zurück — jetzt in der
  **installierten** Config `%LOCALAPPDATA%\OpenInNvim\open-in-nvim.config.ps1` (die Repo-Config
  bleibt unberührt; `git -C E:\repos\openinnvim diff` darf nichts zeigen).
- Testordner löschen: `Remove-Item "$env:USERPROFILE\Desktop\oin-test" -Recurse`.
