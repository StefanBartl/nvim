Alle Befehle in deinem eigenen, nicht erhöhten PowerShell ausführen, nicht aus Claude heraus.

**tasks-desktop** (ersetzt die vorhandene Installation in place):
```powershell
cd E:\repos\tasks-desktop; cd ui; pnpm build; cd ..; cargo build --release --locked; .\target\release\tasks-hub.exe install --autostart --shortcut
```
Mit `tasks-hub install` aus dem lokalen Release-Build bekommst du den aktuellen `main`. Ein Release-Skript (`scripts\install.ps1`) installiert nur veröffentlichte Versionen. Der laufende Hub (PID 22568) sollte danach neu starten, sonst läuft die alte Binary weiter.

**rules-desktop** (laut README der Rolling-Build von `main`):
```powershell
cd E:\repos\rules-desktop; .\scripts\install.ps1 -Rolling -Autostart -Shortcut
```

**docmap-desktop** (kein frischer Installer vorhanden; die `.msi` im Repo ist 0.3.0, installiert ist 0.6.0, also nicht verwenden):
```powershell
cd E:\repos\docmap-desktop; cargo install tauri-cli; cargo tauri build
```
Danach den neu gebauten Installer aus `src-tauri\target\release\bundle` starten. Falls du `cargo tauri` schon hast, entfällt der erste Teil. Ob der Build ohne weitere Schritte durchläuft (z. B. das mitgelieferte `docmap.exe`), habe ich nicht geprüft.

**ai-desktop** (erst nach Prüfung nötig, die 11 Commits sind wohl nur Doku; sonst aus Quellen):
```powershell
cd E:\repos\ai-desktop; .\scripts\setup.ps1
```
`-InstallDeps -AddToPath` nur anhängen, wenn gcc/OpenSSL über MSYS2 noch fehlen bzw. der Pfad nicht gesetzt ist.

