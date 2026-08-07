# `lib.nvim`

## Neue Features implementieren

> alle Cross-Platform!
> Alle neuen features in die `docs/lib.txt` `vimdoc` sowie die `@types/all_functions` sowie die `init.lua` eintragen

- Installer modul, dass bei der isntallation der tools für das lugin unterstützt. Beispiel: pdfport.nvim braucht für die funkton api das es markdown files oder images in pdf wasndelt, ein externes pttols zb pandoc, img2pdf, tectponic usw... man kann pdfport.nvim zwar ohne die verwenden, aber dann sin die features halt nicht vollständig oder diabled. Cooö wäre e wenn wir ein modul hätten, dass der user ausführen kann und die für sein os korrekten tools installiert, ähnlich wie mason oder lazyvim das macht. Wennman dies so abtarhieren könnte, dass wir das modul dann in mehrren pluigins verwendnkönnten, perfekt. wenne s z uspeziell ist, dann nicht, dann in kedem plugin ehre einzeln lösen.

---

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
- [ ] **Offen:** Linux-/macOS-Zweige sind aus der Manager-Doku abgeleitet,
      nicht ausgefuehrt. Auf einem Linux-Host verifizieren.

### `usercmd.composer.complete` — Root-Route neben Literal-Kindern (gefixt, 2026-08-07)

`:Open <Tab>` hat nur `viewer` angeboten und keinen einzigen Handler-Namen:
`complete.candidates` gab bei einem Node mit Literal-Kindern **ausschliesslich**
die Kinder zurueck und kam nie zur eigenen Route (`path = {}`). Jetzt kommen
erst die Literale, dann das erste Positional der Root-Route. Spec-Abdeckung in
`docs/TESTS/composer_spec.lua`.

- [ ] Gegenpruefen, ob andere Verbs mit dieser Form (Root-Route + Subcommands)
      dasselbe Problem hatten und die Completion jetzt wie erwartet aussieht.

---

