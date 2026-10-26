# Toolchain der nativen Apps (Windows)

Stand 2026-10-26, auf der Workstation geprüft (alle vier Apps bauen mit `-BuildOnly`). Quelle der Wahrheit im Code:
`lua/bindings/usrcmds/native_repos/toolchain.lua` (Prüfung und Installation) und `lua/plugins/personal/core/natives.lua`
(welche App was braucht).

## Umgebungsvariablen

| Variable | Wofür | Standard |
|---|---|---|
| `REPOS_DIR` | Ordner mit den Checkouts (`$REPOS_DIR\<app>`) | muss gesetzt sein (hier `C:\repos`) |
| `MSYS2_ROOT` | MSYS2, mit dem ai-desktop baut | `C:\msys64` |
| `TASKS_DESKTOP_INSTALL_DIR`, `RULES_DESKTOP_INSTALL_DIR` | anderer Installationsort der Hubs (für Tests) | leer |

## Werkzeuge

| Id (`:MyNative deps`) | Werkzeug | Geprüft über | Installiert `:MyNative` es? | Von Hand |
|---|---|---|---|---|
| `rust` | rustup, cargo, rustc (stable, Ziel `x86_64-pc-windows-msvc`) | `cargo` auf PATH (`%USERPROFILE%\.cargo\bin`) | ja: `winget install -e --id Rustlang.Rustup --scope user` | <https://rustup.rs> |
| `msvc` | MSVC Build Tools (Linker für das msvc-Ziel) | `vswhere.exe` findet `Microsoft.VisualStudio.Component.VC.Tools.x86.x64` | nein (Administrator) | `winget install -e --id Microsoft.VisualStudio.2022.BuildTools`, Workload „Desktop development with C++“ |
| `node` | Node.js mit npm; pnpm 11.28.2 (die Version der CI) kommt über `npx`, wenn es fehlt | `npm` auf PATH | nein (Administrator) | `winget install -e --id OpenJS.NodeJS.LTS` |
| `tauri-cli` | Tauri CLI 2 (`cargo tauri`) | `cargo tauri --version` | ja: `cargo install tauri-cli --version ^2 --locked` (braucht `rust`) | gleich |
| `cmake` | CMake >= 3.20 | `cmake` auf PATH oder `%ProgramFiles%\CMake\bin\cmake.exe` | nein (Administrator) | `winget install -e --id Kitware.CMake` |
| `mingw64` | MinGW-w64 von MSYS2: g++, mingw32-make, objdump, OpenSSL | Dateien unter `%MSYS2_ROOT%\mingw64`: `bin\g++.exe`, `bin\mingw32-make.exe`, `bin\objdump.exe`, `include\openssl\ssl.h`, `lib\libssl.dll.a` | ja: `pacman -S --needed --noconfirm mingw-w64-x86_64-gcc mingw-w64-x86_64-make mingw-w64-x86_64-openssl` (binutils kommt mit gcc) | MSYS2 von <https://www.msys2.org>; bei 404 erst `pacman -Syu` in einer MSYS2-Shell |

Ohne Prüfung, weil auf Windows 11 immer vorhanden: WebView2 (für docmap-desktop), `tar.exe` (`%SystemRoot%\System32`),
PowerShell 7 (`pwsh`, sonst Windows PowerShell 5.1). NSIS lädt `cargo tauri build` beim ersten Lauf selbst herunter.

Fallen:
- **Ein g++ ohne OpenSSL auf PATH** (hier WinLibs von winget, `BrechtSanders.WinLibs…`): `setup.ps1` von ai-desktop
  nimmt seit 2026-10-26 die erste Toolchain mit OpenSSL, also die von MSYS2. Vorher brach der Build mit
  „OpenSSL dev files not found“ ab.
- **`C:\msys64` ist für normale Benutzer beschreibbar** (Authenticated Users: Modify), deshalb läuft pacman ohne Admin.
  Ist es anders installiert, braucht `pacman` einen Administrator.
- Ein Werkzeug, das `:MyNative` gerade installiert hat, steht erst in einem neuen Terminal auf PATH. Für cargo ergänzt
  `:MyNative` den PATH des laufenden nvim selbst.

## Je App

| App | braucht | Build (`-BuildOnly`) | Ergebnis | Installiert nach | Entfernen |
|---|---|---|---|---|---|
| tasks-desktop | rust, msvc, node | `pnpm --dir ui install/build`, `cargo build --release --locked -p tasks-hub` | `target\release\tasks-hub.exe` | `%LOCALAPPDATA%\tasks-desktop\bin\tasks-hub.exe` (über `tasks-hub install`), Einstellungen `%APPDATA%\tasks-desktop` | `scripts\uninstall.ps1 [-PurgeSettings]` |
| rules-desktop | rust, msvc, node | wie tasks-desktop, Paket `rules-hub` | `target\release\rules-hub.exe` | `%LOCALAPPDATA%\rules-desktop\bin\rules-hub.exe`, Einstellungen `%APPDATA%\rules-desktop` | `scripts\uninstall.ps1 [-PurgeSettings]` |
| docmap-desktop | rust, msvc, tauri-cli | Engine aus `standalone-latest` von docmap.nvim nach `src-tauri\binaries` und `src-tauri\resources\grammars`, dann `cargo tauri build --bundles nsis` | `src-tauri\target\release\docmap-desktop.exe` und `src-tauri\target\release\bundle\nsis\docmap-desktop_<version>_x64-setup.exe` | NSIS-Setup still (`/S`) für den Benutzer, `%LOCALAPPDATA%\docmap-desktop` (Standard von Tauri für `installMode: currentUser`) | `scripts\uninstall.ps1` (Deinstaller still) |
| ai-desktop | cmake, mingw64 | `scripts\setup.ps1 -SkipInstall`: `third_party\` holen (SHA-256 geprüft), CMake „MinGW Makefiles“ nach `build\` | `build\ai-desktop.exe` | `%LOCALAPPDATA%\ai-desktop\app` und Starter `%LOCALAPPDATA%\ai-desktop\ai-desktop.cmd`, der Ordner kommt auf den Benutzer-PATH; das Setup des Release installiert dagegen nach `%LOCALAPPDATA%\Programs\ai-desktop` | `scripts\uninstall.ps1` (entfernt beide) |

takt (noch ein Gerüst) und appkit (Bibliothek der Apps) werden nicht gebaut. appkit kommt über die Pins in
`Cargo.toml` und `ui/package.json` der Apps von GitHub.

Alle `build-install.ps1` und `uninstall.ps1` verweigern das Installieren und Entfernen in einer Claude-Sitzung
(`CLAUDECODE`). `build-install.ps1` verweigert das Installieren auch in einer erhöhten Sitzung, weil die App sonst
im Profil des Administrators landen kann (`-AllowElevated` für eine Build-Maschine). `:MyNative uninstall` fragt
vorher nach. Die Engine von docmap-desktop kommt wie in der CI ohne Prüfsumme über HTTPS aus `standalone-latest`,
denn dieses Release veröffentlicht keine `SHA256SUMS`.

## Was es im Release gibt (zum Vergleich)

| App | Rolling `latest` | Versions-Tag `vX.Y.Z` |
|---|---|---|
| tasks-desktop, rules-desktop | `<hub>-windows-x86_64.exe` (ein Doppelklick richtet den Hub ein), `.tar.gz` für Linux, `install.ps1`/`.sh`, `uninstall.ps1`/`.sh`, `SHA256SUMS` | Draft mit `.zip`/`.tar.gz` und denselben Skripten |
| docmap-desktop | NSIS-`setup.exe`, AppImage, `install.ps1`/`.sh`, `SHA256SUMS` | Draft mit den Installern aller Plattformen |
| ai-desktop | Inno-`setup.exe`, `install.ps1`, `SHA256SUMS` | Draft mit dem Setup |

Ein echtes `setup.exe` für die Hubs kommt mit der Tauri-Hülle: `tasks-desktop/tasks-desktop-installer-als-github-release-setup-exe-dmg-lin`
und `rules-desktop/tauri-huelle` im tasks-vault.
