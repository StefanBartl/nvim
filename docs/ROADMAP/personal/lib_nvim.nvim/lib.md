# `lib.nvim`

- [ ]  Markdown File mit Übersicht überstellen, welche alle in lib.nvim verfügbaren ApiS7mODULE7fuNKTOINEN AUFGTEILET NACH THEMA; ALSO SORTIERT BZW IN VERSCHEDENE FILES AUSGELAGERT; ALSO EINE FILE FÜR X; ANDERE FILE FÜR Y

## Neue Features implementieren

> alle Cross-Platform!
> Alle neuen features in die `docs/lib.txt` `vimdoc` sowie die `@types/all_functions` sowie die `init.lua` eintragen


---

nvim.copmposer hat als prefix immer lib.nvim.composer bei den notifyes, danbei wäre es aber gt wenn das plugin das die lib odul benutzt hier genangt weren würde

## Bestehende Module

### `cross.reveal_in_fm` (neu, 2026-08-07)

Zusammengelegte Dateimanager-Dispatch aus open.nvim (`handlers/filemanager`)
und filetree.nvim (`features/system/open_in_fm`). Dabei zwei Bugs gefixt, die
je nur in einer Kopie steckten: Forward-Slashes an `explorer.exe /select,`
(oeffnet still den falschen Ordner) und `xdg-open` auf eine Datei beim Reveal
(startet die Standard-App der Datei statt eines Dateimanagers).

- [x] **Gefixt:** Auf Windows oeffnete das Fenster ohne Fokus. Ursache war
      Windows' Foreground-Lock, nicht der Start; Analyse in
      [open.nvim.md](../open.nvim.md). Das Modul startet auf Windows/WSL jetzt
      `win_reveal.ps1`, das explorer.exe aufruft, das entstandene Fenster ueber
      COM sucht und per `AttachThreadInput` nach vorne holt. Faellt auf den
      blanken explorer.exe-Spawn zurueck, wenn PowerShell oder das Skript
      fehlen. Neue Option `reuse` (Windows/WSL) ersetzt filetrees
      `reuse_win.lua`.
      Wichtig fuer kuenftige Module: `run.run_detached` taugt **nur** fuer
      GUI-Prozesse — ein detached gestartetes Konsolenprogramm
      (powershell.exe) laeuft auf Windows gar nicht erst an, meldet aber eine
      gueltige Job-ID.

Linux-/macOS-Verifikationsstatus steht nicht mehr hier, sondern in lib.nvims
eigener [`CROSS_PLATFORM_CHECKLIST.md`](https://github.com/StefanBartl/lib.nvim/blob/main/docs/ROADMAP/CROSS_PLATFORM_CHECKLIST.md)
— dort auch fuer kuenftige `cross.*`-Module.


