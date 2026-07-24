# mdview standalone

Initial:
  `npm run build` erfolgreich
  `npm run build:go` erfolgreich
  `standalone = { binary_path = "E:/repos/mdview.nvim/native/server/mdview-server.exe" }` gesetzt

1. **`:MDView detach`** auf einer .md-Datei — Browser-Tab öffnet sich? Dann `:qa` in der Ursprungsinstanz: läuft die Preview weiter?
  Startet, aber erst nach 10-15 Minuten öffnet sich das browser tab


2. **Danach editieren**: neue Instanz öffnen, dieselbe Datei ändern — kommt Live-Push und Scroll-Sync in der detachten Preview an? (Das ist der Kernunterschied zu standalone.)

3. **Preview-Tab schließen** → beendet sich die detachte nvim-Instanz von selbst? (`MDViewSessionEnded` → `qa!`). Prüf mit `tasklist | findstr nvim`, dass nichts unsichtbar zurückbleibt.

4. **`:MDView standalone`** *ohne* `--no-browser` — öffnet der Go-seitige Browser-Opener (`rundll32`) den Tab korrekt? Die URL enthält `&`, deshalb bewusst nicht `cmd /c start`.
  klappt,m browsertab ist aufgegenagen

5. **`scripts/mdview-bg.ps1 README.md`** aus einem Terminal, dann Terminal schließen — läuft die Preview weiter?
  Hat nicht geklappt
❯ .\scripts\mdview-bg.ps1 .\README.md
  mdview.nvim on  main via 🌙 v5.1.5 via  v26.2.0
  mdview: previewing README.md in the background (pid 12884)
  mdview: close the preview tab to stop it, or: Stop-Process -Id 12884

6. **Beides parallel**: normale Session (43219) + standalone (43319) gleichzeitig — stören sie sich?
  Nein sie intefereieren nicht,

7. **Alter-Binary-Pfad**: `standalone.binary_path` entfernen und `:MDView standalone` — kommt die klare v0.3.0-Fehlermeldung statt Stille?
  Notify:
       Error  20:20:08 notify.error [mdview] standalone: this relay binary has no --watch support.
    C:\Users\bartl\AppData\Local\nvim-data/mdview/bin/v0.2.0/mdview-server_windows_amd64.exe
    It needs mdview-server v0.3.0+. Either bump install.version, or point standalone.binary_path at a newer/locally built relay.

---

