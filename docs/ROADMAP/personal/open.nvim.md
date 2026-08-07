# `open.nvim`

---

## Erledigt: Dateimanager-Fenster kommt nicht nach vorne (Windows)

Gefixt 2026-08-07 in `lib.nvim.cross.reveal_in_fm`. Betraf `:Open filemanager`
**und** filetree.nvims `<leader>fm` gleichermassen, weil beide auf demselben
Modul laufen.

**Symptom:** Beide melden `Opening in file manager: <pfad>`, augenscheinlich
passiert nichts.

**Befund:** Es passiert doch etwas — die Fenster werden erzeugt. Nachweis per
COM-Enumeration direkt nach zwei Fehlversuchen:

```powershell
$shell = New-Object -ComObject Shell.Application
$shell.Windows() | ForEach-Object { "{0} :: {1}" -f $_.LocationName, $_.LocationURL }
# WKDBook-Tricentis :: file:///C:/repos/WKDBook-Tricentis
# WKDBook-Tricentis :: file:///C:/repos/WKDBook-Tricentis
```

Ein direkter `jobstart({ "explorer.exe", "/select,<datei>" }, { detach = true })`
aus headless nvim liefert eine gueltige Job-ID und erzeugt ebenfalls ein
Fenster (Exit-Code 1 ist bei explorer.exe normal und kein Fehlersignal). Das
Fenster oeffnet also — nur im Hintergrund, hinter Neovim. Der Bug ist
**Fokus**, nicht Start.

**Ursache (bestaetigt):** Windows' Foreground-Lock. `SetForegroundWindow` darf
nur der Prozess, dem das Vordergrundfenster gehoert — im Terminal ist das der
Terminal-Host (WindowsTerminal.exe, wezterm.exe), nicht `nvim.exe`. Also
werden nvim *und* der von ihm gestartete Explorer abgewiesen, und das Fenster
entsteht hinter allem anderen. Unter einem GUI-Neovim (Neovide, nvim-qt) *ist*
`nvim.exe` der Vordergrundprozess — derselbe Code funktionierte dort. Genau das
war das "mal geht's, mal nicht" ueber Monate: es haing am Frontend, nicht an
diesem Modul.

Messung, die es festnagelt: Vordergrundfenster vor und nach dem Spawn per
`GetForegroundWindow()` verglichen — blieb unveraendert Chrome, waehrend
`Shell.Application.Windows()` von 2 auf 3 Fenster ging.

**Fix:** `reveal_in_fm/win_reveal.ps1` startet explorer.exe, sucht das
entstandene Fenster ueber COM und hebt es per `AttachThreadInput`-Sequenz nach
vorne (dieselbe Mechanik, die `WScript.Shell`s `AppActivate` intern nutzt).
Ein blankes `SetForegroundWindow` reicht nicht — genau daran scheiterte auch
die alte `reuse_win.lua`, die deshalb ersatzlos entfaellt.

**Stolperstein dabei, der die erste Fix-Version still verschluckt hat:**
`jobstart(argv, { detach = true })` fuehrt auf Windows **kein Konsolenprogramm**
aus. libuvs DETACHED_PROCESS laesst das Kind ohne Standard-Handles zurueck,
powershell.exe beendet sich vor der ersten Anweisung — die Job-ID ist trotzdem
gueltig, es sieht also nach Erfolg aus. GUI-Prozesse wie explorer.exe stoert
das nicht. Der Helper laeuft deshalb ueber `vim.system(argv, {})` ohne Warten.
Notiert an `lib.nvim.cross.run.run_detached`.

- [x] Ursache bestaetigt, Fix in `lib.nvim.cross.reveal_in_fm`, beide Plugins
      bekommen ihn.
- [x] Verifiziert auf diesem Host: Datei-Reveal, Ordner-Ziel, Pfade mit
      Leerzeichen und `&`, sowie `reuse` — jedes Mal kam das Fenster nach
      vorn, der Lua-Aufruf kehrt in ~16 ms zurueck.
- [ ] Auf der Workstation gegenpruefen (dort trat es ebenfalls auf).

## Offen: Reveal-Pfade ausserhalb Windows ungeprueft

`reveal_in_fm` waehlt auf Linux jetzt gezielt select-faehige Manager
(nautilus, nemo, `dolphin --select`, thunar, caja) und haelt `xdg-open` von
Dateien fern (das startet sonst die Standard-App statt eines Dateimanagers).
Mangels Linux-/macOS-Host hier ist das **nur** aus der Doku der Manager
abgeleitet, nicht ausgefuehrt.

- [ ] Auf einem Linux-Host verifizieren, mindestens nautilus + dolphin.
- [ ] macOS `open -R` verifizieren.
