# Wenn sich in einem nativen Repo etwas ändert

Die Fakten über die Apps stehen an mehreren Stellen. Diese Liste sagt, was bei welcher Änderung mitgezogen werden muss.
Nach jeder Änderung: `nvim -n -i NONE --headless -u NONE -l TESTS/run.lua native_repos` und einmal `:MyNative build <app>`.

| Stelle | Was dort steht |
|---|---|
| `lua/plugins/personal/core/natives.lua` | je App: Repo, Ordner, Artefakt, Quellen der Staleness-Regel, Werkzeuge (`needs`), Befehle `build`/`install`/`uninstall`, Hinweis |
| `lua/bindings/usrcmds/native_repos/toolchain.lua` | die Werkzeuge: Prüfung, Installationsbefehl, Hinweis |
| `scripts/sync-machine.ps1` (`$natives`) | dieselben Artefakte, Quellen und Build-Befehle für `:MyPlugins machine`, eine eigene Kopie |
| `TESTS/native_repos/native_repos_spec.lua` | prüft die Registry und die Pläne |
| `lua/bindings/usrcmds/native_repos/README.md` | Hilfe zu `:MyNative` |
| [toolchain.md](toolchain.md) | Werkzeuge, Pfade, Ergebnis und Installationsort je App |
| im App-Repo: `scripts/build-install.ps1`, `scripts/uninstall.ps1`, README | der Build- und Installationsweg ohne Setup |

## Fälle

**Neue App.** Im App-Repo `scripts/build-install.ps1` (`-BuildOnly`, Installieren in einer Claude-Sitzung verweigern)
und `scripts/uninstall.ps1` anlegen, beide in der README nennen. Dann ein `desktop({...})`-Eintrag in `natives.lua`
mit `artifact`, `sources` und `needs`, ein Eintrag in `$natives` von `sync-machine.ps1` (dort auch im Array `$extra`),
eine Zeile in den Tabellen von `toolchain.md` und der Name in der Schleife der Spec, die die drei Skripte jeder
Desktop-App prüft.

**Der Build ändert sich** (anderer Befehl, neuer Schritt in `rolling.yml`). `build-install.ps1` im Repo soll dieselben
Schritte gehen wie `rolling.yml`; also zuerst dort nachziehen. Ändert sich der Aufruf selbst, `natives.lua` und
`sync-machine.ps1` (`Command`, `Hint`).

**Das Artefakt wandert oder heißt anders** (neuer Paketname, anderer `target`-Ordner, Tauri `productName`).
`artifact` in `natives.lua`, `Artifact` in `sync-machine.ps1`, die Tabelle in `toolchain.md`. Bei docmap-desktop
hängt auch `uninstall.ps1` am `productName` (Anzeigename des Uninstall-Eintrags).

**Neue Quellen** (neuer Ordner, der ins Binary geht, eine neue Lock-Datei). `sources` in `natives.lua` und `Sources`
in `sync-machine.ps1`. Sonst gilt ein Build als aktuell, obwohl er es nicht ist.

**Neues Werkzeug oder neue Mindestversion** (z. B. eine andere pnpm-Version in der CI, eine neue MSYS2-Bibliothek).
Ein Eintrag in `toolchain.lua` (in Abhängigkeitsreihenfolge: was ein anderes braucht, steht danach), die Id in
`needs` der App, die Tabelle in `toolchain.md`. Die pnpm-Version steht zusätzlich in `build-install.ps1` von
tasks- und rules-desktop (`$pnpmVersion`, dieselbe wie in `ci.yml`). Neue MSYS2-Pakete: auch `$PacmanPackages` in
`setup.ps1` von ai-desktop.

**Installationsort oder Deinstallation ändert sich** (neuer Ordner, Inno-`AppId`, NSIS `installMode`).
`uninstall.ps1` im Repo (ai-desktop: der Schlüssel `{AppId}_is1`, nie die `AppId` selbst ändern), die Spalte
„Installiert nach“ in `toolchain.md`.

**Die Engine von docmap-desktop** (Release-Name, Dateinamen in `standalone-latest` von docmap.nvim). `$engineBase` und
die Dateinamen in `build-install.ps1` von docmap-desktop, zusammen mit `.github/actions/engine-sidecar`.

**Eine App wird ein Tauri-Programm mit Setup** (die Hubs mit ihrer Hülle). `build-install.ps1` baut dann das Setup und
führt es still aus wie bei docmap-desktop, `uninstall.ps1` ruft dessen Deinstaller; `needs` bekommt `tauri-cli`.
