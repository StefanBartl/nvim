# Mögliche Ursachen — kurze Übersicht

* Unterschiedliche **Neovim-Version** (z. B. Neovim ≥ 0.10 hat `vim.system`; ältere nur `jobstart`).
* Unterschiedliche **Laufzeitumgebung**: echtes Windows vs. WSL / MSYS / Git-Bash. In WSL ist `explorer.exe` nicht direkt verfügbar oder Pfade müssen konvertiert werden.
* Unterschiedliche **PATH / ausführbare Dateien**: auf dem Bruder-PC ist `explorer.exe` ggf. nicht erreichbar (unwahrscheinlich, aber prüfbar) oder `cmd.exe` verhält sich anders.
* **Quoting / Leerzeichen**: Pfade mit Leerzeichen werden falsch übergeben — `start` in `cmd.exe` benötigt einen leeren Title-Parameter: `cmd /C start "" "C:\path with spaces"`.
* **Conceal / Unicode / Normalisierung**: wenn der Pfad ungewöhnliche Zeichen enthält (Unicode, NTFS-Alternate Data Streams), kann `explorer` fehlschlagen.
* **Berechtigungen / UAC / AV**: restriktive Policies oder Antivirus blockieren child processes oder verhindern spawn.
* Unterschiedliche **Neovim-Laufart** (GUI vs. Terminal) — einige GUIs behandeln child processes anders.
* **Jobstart / vim.system API usage**: Auf manchen Systemen liefert `jobstart` sofort `0`/`-1` und fehlschlägt ohne brauchbare Fehlermeldung; `vim.system` liefert detailliertere Resultate.

## Diagnoseschritte (was man auf beiden PCs ausführen sollte)

1. Neovim-Version prüfen:

```vim
:echo v:version
:lua print(vim.version().major, vim.version().minor, vim.version().patch)
```

2. Prüfen, ob `vim.system` vorhanden ist:

```lua
:lua print(vim.inspect({has_vim_system = vim.system ~= nil}))
```

3. Prüfen, ob `explorer.exe` und `cmd.exe` erreichbar sind:

```vim
:echo executable('explorer.exe')
:echo executable('cmd.exe')
```

`1` heißt ausführbar, `0` heißt nicht gefunden.

4. Prüfen, ob Neovim unter WSL läuft:

```lua
:lua print(vim.loop.os_uname().version)
-- oder
:lua print(os.getenv("WSL_DISTRO_NAME"))
```

Wenn `version` oder `WSL_DISTRO_NAME` Hinweise auf "Microsoft" oder WSL zeigt, ist die Umgebung WSL.

5. Direkter Test aus Neovim: (führt die gleichen Befehle wie das Modul aus — gibt Debug-Ausgabe)

```lua
:lua vim.system({'explorer.exe','/select,C:\\Windows\\notepad.exe'}, {text=true}, print)
:lua vim.fn.jobstart({'explorer.exe','C:\\'}, {detach=true})
```

6. Test der `cmd start`-Form mit Leerzeichen-Pfad:

```lua
:lua vim.system({'cmd.exe','/C','start','','C:\\Program Files'}, {text=true}, print)
```

7. Einfache Fehlerlogs aktivieren: temporär `vim.notify`-Ausgaben bei Fallbacks aktivieren (siehe unten).

### Weitere Härtungs- und Maintenance-Tipps

* Logging: temporär `vim.notify` auf `INFO`/`DEBUG`-Level nutzen, um stderr/code aus `vim.system` zu sehen.
* Unit/Integration-Test: kleine Lua-Skripte erstellen, die `explorer.exe` und `cmd.exe` mit Beispielpfaden starten; diese auf beiden Rechnern ausführen.
* WSL-spezifisch: wenn Bruder Neovim in WSL betreibt, empfiehlt sich das Verwenden von `wslview` (falls installiert) oder `wslpath -w` zur Konvertierung; alternativ `powershell.exe`-Aufrufe prüfen.
* Rechte: prüfen, ob Neovim als Administrator läuft (anderses Verhalten), oder ob Gruppenrichtlinien/AV child processes einschränken.
* Fallback-Strategien erweitern: zusätzlich `powershell.exe -NoProfile -Command Start-Process -FilePath explorer.exe -ArgumentList <...>` als weitere Option verwenden.
* Versionskompatibilität: optional Feature-Flags im Modul (`prefer_vim_system = true/false`) anbieten, damit man auf älteren Neovim gezielt `jobstart` erzwingen kann.

### Konkrete Debug-Kommandos (einfach kopieren & ausführen)

```vim
" show neovim version and vim.system availability
:lua print(vim.inspect({version = vim.version(), has_vim_system = vim.system ~= nil}))

" test explorer directly (should open or return diagnostic)
:lua vim.system({'explorer.exe','C:\\Windows'}, {text=true}, print)

" test cmd start with spaced path
:lua vim.system({'cmd.exe','/C','start','','C:\\Program Files'}, {text=true}, print)

" check for explorer and cmd presence
:echo executable('explorer.exe')  " 1 or 0
:echo executable('cmd.exe')       " 1 or 0
```

---
