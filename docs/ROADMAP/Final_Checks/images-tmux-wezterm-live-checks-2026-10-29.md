# images.nvim — Bilder in tmux unter WezTerm (Stand 2026-10-29)

Live-Check zu `images.nvim@3cf7dbc`: die OSC-1337-Nutzlast geht unter `$TMUX` jetzt in der
Passthrough-Hülle raus, Cursor-Sequenzen bleiben außen. Headless ist nur die Byte-Folge geprüft;
ob das Bild wirklich erscheint, sieht nur ein Mensch. Task
`images.nvim/bilder-in-tmux-live-in-wezterm-pruefen-allow-passthrough-on` (Priorität 2). Ist der
Abschnitt durch, die Task mit `done` schließen. Ein Befund: unter "Befunde" eine Zeile, daraus wird
eine `kind: bug`-Task.

Verwandte, bereits erledigte Dateien (nicht ändern): `bild-viewport-zen-live-tests-2026-10-20.md`
(Zen-Viewer ohne tmux), `image-redact-live-tests-2026-10-21.md`. Spezifikation und Messung zum
Passthrough: `terminal.nvim/NOTES/spike-uservars.md`. Fehlerbild: `images.nvim/docs/troubleshooting.md`
("A multiplexer is the other common cause").

**Vorher:** images.nvim aktuell (mindestens `3cf7dbc`), WezTerm, **tmux** (unter Windows: tmux in
WSL, Neovim *in* diesem tmux; das Windows-Neovim außerhalb von tmux testet den Pfad nicht), ImageMagick
(`magick`) auf PATH, `:checkhealth images` ohne Fehler. Hinweis: laut `Checks-Blocker_0610.md` (L9)
hatte die WSL-Instanz (`archlinux`) tmux 3.7c, aber kein Neovim; Neovim in WSL muss also vorher
vorhanden sein. Offene Frage: welches Neovim/Config läuft in der WSL für diesen Test?

Testbild: ein beliebiges PNG/JPG, plus ein Ordner mit 4 bis 6 Bildern für die Galerie.
In `~/.config/tmux/tmux.conf` steht `allow-passthrough` ggf. schon (Gegenstück in
`Configs/terminals/tmux/tmux.conf`); Wert prüfen mit `tmux show -g allow-passthrough`.

## 1. Mit `allow-passthrough on`

- [ ] `tmux set -g allow-passthrough on`, `tmux show -g allow-passthrough` zeigt `on`
- [ ] In tmux (in WezTerm) Neovim starten, `echo $TMUX` ist gesetzt
- [ ] `:Image <Pfad zum Testbild>`: das Bild erscheint **an der richtigen Stelle** (nicht am
      unteren Rand), die tmux-Statuszeile bleibt stehen, nichts scrollt
- [ ] Fenster wechseln/scrollen und zurück: Bild bleibt oder verschwindet sauber, kein Geisterbild
- [ ] Galerie: `:Image gallery` (auf einem Ordner bzw. mit einer markierten Zeilenauswahl
      `:'<,'>Image gallery`): **alle Kacheln** an ihren Positionen (`draw_many`), keine
      übereinanderliegenden oder fehlenden Kacheln
- [ ] `:checkhealth images` meldet unter tmux keinen Fehler (Passthrough erkannt)

## 2. Ohne `allow-passthrough`

- [ ] `tmux set -g allow-passthrough off`, Neovim neu starten
- [ ] `:Image <Pfad>`: **kein** Bild (oder der dokumentierte Fallback, siehe unten), kein
      kaputtes Zeichengewirr im Terminal
- [ ] `:checkhealth images` zeigt den **tmux-Hinweis** aus `capability()` (Text sinngemäß:
      `allow-passthrough on` setzen); Wortlaut notieren: ______
- [ ] Hinweis zur Erwartung: laut Task "kein Bild"; laut Doku fällt `:Image show`/hover ggf. auf
      den Blockzeichen-Fallback (`display.ascii_fallback`). Welches von beidem passiert, notieren:
      ______ (bei Abweichung zur Task: Doku oder Task nachziehen)
- [ ] Danach `allow-passthrough` wieder auf den gewünschten Dauerwert setzen

### Falls rot

Notieren: tmux-Version (`tmux -V`), WezTerm-Version, ob Neovim in WSL oder unter Windows läuft,
`:Image`-Ausgabe/`:messages`, wo das Bild landet (unterer Rand, versetzt, gar nicht), ob die
Statuszeile überschrieben wird. Abweichung = Bug-Task in images.nvim (Tag `tmux`, `terminal`); die
Byte-Folge liegt in der Passthrough-Hülle, Cursor-Sequenzen außen.

**Danach:** Task `images.nvim/bilder-in-tmux-live-in-wezterm-pruefen-allow-passthrough-on` mit
`done` schließen.

---

## Befunde

-
