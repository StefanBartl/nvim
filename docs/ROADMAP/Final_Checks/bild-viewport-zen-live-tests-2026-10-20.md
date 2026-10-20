# Bild-Viewport im Zen-Float — Live-Tests (Stand 2026-10-20)

Was aus dem Plan `ALL/bild-viewport-zoom-pan-ausschnitt-float-und-speichern-im-zen`
(tasks-vault) gebaut ist und nur am echten Terminal geprüft werden kann. Headless
lösen Mausereignisse keine Mappings aus, und ob WezTerm ein OSC-1337-Bild stehen
lässt, sieht nur ein Mensch.

**Vorher:** Neovim neu starten (neuer Stand von images.nvim und lib.nvim), WezTerm,
`:set mouse?` muss `n` oder `a` enthalten (`:checkhealth images` sagt es).
Testbild: ein großer Screenshot, z. B. 1920×1080; im filetree mit `<CR>` öffnen
(das ist `images.zen`, derselbe Float wie `:Image zen <pfad>`).

---

## 1. Zoom und Verschieben per Tastatur — ✅ bestätigt (2026-10-20)

`images.nvim@6130056`, Fix `@564222d`. Steht nur zur Vollständigkeit hier.

---

## 2. Legende im Rahmen und `?`-Liste — offen (nur „weiter“, nicht ausdrücklich bestätigt)

`images.nvim@56f50e1`, Fix `@91b3333`. Task `images.nvim/zen-legende-und-cheatsheet`.

- [ ] Unten rechts im Rahmen steht `? help`.
- [ ] `+` drücken: Titel wird `name.png · 1.5×`, **und das Bild ist danach wieder da**
      (jede Rahmenänderung lässt WezTerm das Bild verwerfen, es wird sofort neu gezeichnet).
- [ ] `0`: Faktor verschwindet aus dem Titel, ganzes Bild.
- [ ] `?`: Bild verschwindet, Liste der Tasten erscheint (Gruppen Zoom / Move / Mouse / Window),
      Mausaktionen in Worten („Alt + wheel up: …“).
- [ ] `?`, `q` oder `<Esc>` in der Liste: Liste zu, Bild wieder da, im selben Zoom.
- [ ] `+?` sehr schnell hintereinander: das Bild darf **nicht** über der Liste landen.
- [ ] Liste offen, mit `<C-w>p` zurück ins Bild, `q`: Bild **und** Liste sind zu.
- [ ] Optional: in der Config `display.zen.keys.help = "g?"` → Fuß zeigt `g? help`, `g?` öffnet und schließt.

---

## 3. Maus: Alt+Mausrad und Ziehen mit der Mitteltaste — offen

`images.nvim@86bf8af`, Fix `@3615f09`. Task `images.nvim/zen-maus-zoom-und-pan`.

- [ ] Alt+Mausrad hoch über einer bestimmten Stelle (z. B. ein Wort im Screenshot):
      es wird hineingezoomt, **die Stelle bleibt unter dem Zeiger** (kurze Pause pro Schritt, magick).
- [ ] Alt+Mausrad runter: wieder heraus, bis zum ganzen Bild.
- [ ] Alt+Mausrad über dem Rahmen: zoomt um die Mitte.
- [ ] Alt+Mausrad über einem **anderen** Fenster: am Bild ändert sich nichts.
- [ ] Gezoomt, Mitteltaste halten und ziehen: das Bild folgt der Hand (beim Ziehen ruckelig),
      nach dem Loslassen steht der Ausschnitt dort, wo man hingezogen hat.
- [ ] **Mehrmals schnell hintereinander** greifen und ziehen (innerhalb einer halben Sekunde):
      jeder Zug verschiebt, und es taucht **nie** Text aus der Zwischenablage im Fenster auf
      (das war der Review-Bug mit `<2-MiddleMouse>`).
- [ ] Mitteltaste halten, dabei Alt+Mausrad: der Zoom bleibt, das Ziehen hört auf
      (erst ein neuer Druck zieht wieder).
- [ ] Ungezoomt ziehen: nichts passiert (und auch kein Einfügen).

---

## 4. Bild in die Zwischenablage (lib.nvim) — offen

`lib.nvim@bc8acf6`, Fix `@8e0dbc4`. Noch ohne Taste im Zen-Float (`gy` kommt mit
`images.nvim/zen-ausschnitt-speichern-kopieren`), deshalb per Befehl:

```vim
:lua require("lib.nvim.cross.copy_image_to_clipboard")(vim.fn.expand("C:/repos/Notes/testbild.png"), function(ok, err) print(ok, err) end)
```

- [ ] Ausgabe `true nil`.
- [ ] In Paint (`Strg+V`) und in Teams einfügen: das Bild erscheint (Transparenz geht unter
      Windows verloren, ist bekannt und dokumentiert).

---

## Danach

Ergebnisse (oder „passt“) an Claude geben; die Tasks werden dann abgeschlossen. Als
Nächstes im Plan: Ausschnitt per Links-Ziehen in einen Kind-Float
(`images.nvim/zen-ausschnitt-kind-float`), dann Speichern/Kopieren (`gs`/`gy`).
