# `open.nvim`

---

## Offen: Dateimanager-Fenster kommt nicht nach vorne (Windows)

Stand 2026-08-07. Betrifft `:Open filemanager` **und** filetree.nvims
`<leader>fm` gleichermassen, weil beide seit heute auf
`lib.nvim.cross.reveal_in_fm` laufen.

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

**Zu klaeren:**

- [ ] Warum uebernimmt das neue Explorer-Fenster den Fokus nicht? Verdacht:
      Windows' Foreground-Lock — ein Prozess, der selbst nicht im Vordergrund
      ist, darf keinen Fokus setzen; `jobstart` haengt explorer.exe unter
      nvim, das im Terminal-Host laeuft.
- [ ] Fix-Kandidaten, in dieser Reihenfolge testen:
      `AllowSetForegroundWindow` vor dem Spawn · `SetForegroundWindow` auf das
      neue Fenster nachziehen (die Logik existiert schon in filetrees
      `open_in_fm/reuse_win.lua`) · Start ueber
      `(New-Object -ComObject Shell.Application).Explore(path)` statt
      `explorer.exe`.
- [ ] Fix gehoert nach `lib.nvim.cross.reveal_in_fm`, damit beide Plugins ihn
      bekommen.

## Offen: Reveal-Pfade ausserhalb Windows ungeprueft

`reveal_in_fm` waehlt auf Linux jetzt gezielt select-faehige Manager
(nautilus, nemo, `dolphin --select`, thunar, caja) und haelt `xdg-open` von
Dateien fern (das startet sonst die Standard-App statt eines Dateimanagers).
Mangels Linux-/macOS-Host hier ist das **nur** aus der Doku der Manager
abgeleitet, nicht ausgefuehrt.

- [ ] Auf einem Linux-Host verifizieren, mindestens nautilus + dolphin.
- [ ] macOS `open -R` verifizieren.
