# Native Apps bauen und installieren

Alles, was es braucht, um die nativen Apps (tasks-desktop, rules-desktop, docmap-desktop, ai-desktop) auf einem
Windows-Rechner aus dem Checkout zu bauen und für den eigenen Benutzer zu installieren, ohne ein heruntergeladenes
`setup.exe` (das SmartScreen auf der Workstation sperrt).

| Datei | Inhalt |
|---|---|
| [toolchain.md](toolchain.md) | Werkzeuge (Rust, MSVC, Node, Tauri CLI, CMake, MSYS2/MinGW-w64), erwartete Pfade, Umgebungsvariablen, Build-Ergebnis und Installationsort je App |
| [start.md](start.md) | Installierte Apps starten, stoppen und prüfen (Befehle je App) |
| [maintenance.md](maintenance.md) | Was hier und in der nvim-Config nachzuziehen ist, wenn sich in einem der nativen Repos etwas ändert |

## Der eine Befehl

In einem normalen nvim (nicht aus einer Claude-Sitzung heraus, die AppData und HKCU umleitet):

```vim
:MyNative clone       " fehlende Repos klonen
:MyNative install     " Werkzeuge prüfen/nachinstallieren, dann jede geklonte App bauen und installieren
```

`:MyNative install` richtet zuerst die Werkzeuge ein (`:MyNative deps`): rustup über winget, die Tauri CLI über
cargo und die MinGW-w64-Pakete über pacman von MSYS2. Für Node.js, CMake, die MSVC Build Tools und MSYS2 selbst
braucht es einen Administrator, die werden nur genannt. Eine App, deren Werkzeuge fehlen, wird übersprungen und mit
Grund genannt. Danach baut und installiert der Befehl jede App mit ihrem `scripts\build-install.ps1`. Die Ausgabe
landet in der Quickfix-Liste.

Weitere Befehle: `:MyNative list` (Git- und Build-Stand), `:MyNative build [name]` (nur bauen, die veralteten),
`:MyNative uninstall [name]`, `:MyNative deps [name]`. Hilfe: `lua/bindings/usrcmds/native_repos/README.md`.

**Auf der Workstation gesperrt:** Mit `NVIM_MACHINE_ROLE=workstation` (`lua/machine.lua`) brechen `:MyNative build`,
`install` und `deps` sowie `B` in `:MyPlugins machine` mit einer Fehlermeldung ab, weil CrowdStrike Falcon dort
eigene unsignierte Programme meldet. `list`, `clone`, `pull` und `uninstall` bleiben erlaubt. Auch die
lazy.nvim-`build`-Hooks bauen dort nichts Natives: telescope-fzf-native wird nicht gebaut (Telescope lädt dann die
`fzf`-Erweiterung nicht), mdview.nvim baut ohne `build:go` (kein Go-Server).

## Ohne nvim

In jedem App-Repo, in einem nicht erhöhten PowerShell:

```powershell
.\scripts\build-install.ps1 [-BuildOnly]   # bauen und installieren
.\scripts\uninstall.ps1                    # entfernen
```

Ohne Toolchain gibt es die Install-Zeile des Rolling-Builds der CI (`latest`, aus der README der App):

```powershell
powershell -ExecutionPolicy Bypass -c "irm https://github.com/WKDSteve/<app>/releases/download/latest/install.ps1 | iex"
```
