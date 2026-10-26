# Native Apps starten, stoppen, prüfen

Die Befehle für die installierten Apps, in einem normalen PowerShell (nicht aus einer Claude-Sitzung, die AppData
und HKCU umleitet). Installationsorte und Bauen: [toolchain.md](toolchain.md). Kurze Befehle wie `tasks-desktop status`
und ein Startmenü-Eintrag mit dem App-Namen sind geplant (Vault: `ALL/native-apps-startmenue-path-status`).

## tasks-desktop

Installiert über `install.ps1` oder `scripts\build-install.ps1` nach `%LOCALAPPDATA%\tasks-desktop\bin`.

```powershell
& "$env:LOCALAPPDATA\tasks-desktop\bin\tasks-hub.exe" start --open      # im Hintergrund starten, Browser öffnen
& "$env:LOCALAPPDATA\tasks-desktop\bin\tasks-hub.exe" open --launch     # Kopplungs-Link für den laufenden Hub öffnen
& "$env:LOCALAPPDATA\tasks-desktop\bin\tasks-hub.exe" stop              # stoppen
& "$env:LOCALAPPDATA\tasks-desktop\bin\tasks-hub.exe" autostart status  # startet er mit der Anmeldung? (on|off|status)
& "$env:LOCALAPPDATA\tasks-desktop\bin\tasks-hub.exe" --version
```

Einen Befehl `status` gibt es nicht. Läuft der Hub: `Get-Process tasks-hub`.

## rules-desktop

Installiert nach `%LOCALAPPDATA%\rules-desktop\bin`, dieselben Befehle wie tasks-desktop.

```powershell
& "$env:LOCALAPPDATA\rules-desktop\bin\rules-hub.exe" start --open
& "$env:LOCALAPPDATA\rules-desktop\bin\rules-hub.exe" open --launch
& "$env:LOCALAPPDATA\rules-desktop\bin\rules-hub.exe" stop
& "$env:LOCALAPPDATA\rules-desktop\bin\rules-hub.exe" autostart status
& "$env:LOCALAPPDATA\rules-desktop\bin\rules-hub.exe" --version
```

Läuft er: `Get-Process rules-hub`.

## Auf der Workstation (CrowdStrike Falcon)

Auf der Workstation endet `<hub> start` still, ohne Ausgabe, mit Exit `0xE0000027` (-536870873), und es läuft kein
Hub. `start` startet den Hub über `wscript.exe` und ein Skript `start-hub.vbs`, und diese Kette aus einem
unsignierten Programm wird dort (vermutlich von Falcon) beendet. Betroffen sind auch der Autostart (der Run-Key ruft
`start`), der Doppelklick, `install --shortcut` und das Entfernen des Links in `uninstall`. Bug im Vault:
`appkit/start-ueber-wscript-von-edr-beendet`.

Bis zum Fix einer der beiden Wege, für rules-desktop mit `rules-hub` und `rules-desktop`:

```powershell
# a) im Vordergrund, das Terminal bleibt offen (Ctrl-C stoppt den Hub); im zweiten Terminal `open --launch`
& "$env:LOCALAPPDATA\tasks-desktop\bin\tasks-hub.exe" serve

# b) im Hintergrund: start legt das Skript an (und wird beendet), dann das Skript von Hand ausführen
& "$env:LOCALAPPDATA\tasks-desktop\bin\tasks-hub.exe" start
wscript.exe "$env:APPDATA\tasks-desktop\start-hub.vbs"
Get-Process tasks-hub
```

`stop` und `open --launch` gehen normal. Der Autostart nach der Anmeldung startet hier keinen Hub.

## docmap-desktop

Das NSIS-Setup (auch still über `install.ps1`) installiert nach `%LOCALAPPDATA%\docmap-desktop`.

```powershell
& "$env:LOCALAPPDATA\docmap-desktop\docmap-desktop.exe"   # App-Fenster öffnen
Get-Process docmap-desktop                                # läuft sie?
Stop-Process -Name docmap-desktop                         # beenden (normal: Fenster schließen)
```

## ai-desktop

Zwei Orte, je nach Weg der Installation:

- Setup des Release (auch über `install.ps1`): `%LOCALAPPDATA%\Programs\ai-desktop\app\ai-desktop.exe`
- `scripts\build-install.ps1`: Starter `%LOCALAPPDATA%\ai-desktop\ai-desktop.cmd`, der Ordner liegt auf dem
  Benutzer-PATH (in einem neuen Terminal reicht `ai-desktop`)

```powershell
& "$env:LOCALAPPDATA\Programs\ai-desktop\app\ai-desktop.exe"   # Server starten (Setup-Installation)
ai-desktop                                                     # Server starten (build-install-Installation)
Invoke-RestMethod http://127.0.0.1:8080/health                 # antwortet er?
Stop-Process -Name ai-desktop                                  # beenden
```
