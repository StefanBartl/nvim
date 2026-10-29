# Bild-Viewport im Zen-Float — Live-Tests (Stand 2026-10-20)

> **Ergebnis 2026-10-21: alles bestanden.** Nach den Fixes `images.nvim@6efad7f` (Meldungs-Floats
> von noice beendeten die Auswahl bzw. rissen ein Loch ins Bild) und `@f5fe121` hat der Nutzer
> neu getestet: „jetzt funktioniert alles“. Die Tasks Maus, Ausschnitt-Float und
> Speichern/Kopieren sind abgeschlossen; offen im Plan nur noch die optionale hover-Etappe
> (`hover.nvim/zoom-mathematik-aus-images-viewport`).

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

- [x] Unten rechts im Rahmen steht `? help`.
- [x] `+` drücken: Titel wird `name.png · 1.5×`, **und das Bild ist danach wieder da**
      (jede Rahmenänderung lässt WezTerm das Bild verwerfen, es wird sofort neu gezeichnet).
- [x] `0`: Faktor verschwindet aus dem Titel, ganzes Bild.
- [ ] `?`: Bild verschwindet, Liste der Tasten erscheint (Gruppen Zoom / Move / Mouse / Window),
      Mausaktionen in Worten („Alt + wheel up: …“).
- [x] `?`, `q` oder `<Esc>` in der Liste: Liste zu, Bild wieder da, im selben Zoom.
- [x] `+?` sehr schnell hintereinander: das Bild darf **nicht** über der Liste landen.
- [ ] Liste offen, mit `<C-w>p` zurück ins Bild, `q`: Bild **und** Liste sind zu. -> <C-w>p funktnioert nicht

> **Claude, 2026-10-21:** `<C-w>p` war nur der Weg zum eigentlichen Fall („`q` im Bild bei
> offener Liste“), den deckt die Spec ab. Falls `<C-w>p` aus der Liste ins Bild wichtig ist,
> bitte sagen. Zeile `?` oben (Gruppen/Mausaktionen) ist nicht abgehakt: was fehlte dort?
- [x] Optional: in der Config `display.zen.keys.help = "g?"` → Fuß zeigt `g? help`, `g?` öffnet und schließt.

---

## 3. Maus: Alt+Mausrad und Ziehen mit der Mitteltaste — offen

`images.nvim@86bf8af`, Fix `@3615f09`. Task `images.nvim/zen-maus-zoom-und-pan`.

- [x] Alt+Mausrad hoch über einer bestimmten Stelle (z. B. ein Wort im Screenshot):
      es wird hineingezoomt, **die Stelle bleibt unter dem Zeiger** (kurze Pause pro Schritt, magick).
- [x] Alt+Mausrad runter: wieder heraus, bis zum ganzen Bild.
- [x] Alt+Mausrad über dem Rahmen: zoomt um die Mitte.
- [x] Alt+Mausrad über einem **anderen** Fenster: am Bild ändert sich nichts.
- [x] Gezoomt, Mitteltaste halten und ziehen: das Bild folgt der Hand (beim Ziehen ruckelig),
      nach dem Loslassen steht der Ausschnitt dort, wo man hingezogen hat.
- [x] **Mehrmals schnell hintereinander** greifen und ziehen (innerhalb einer halben Sekunde):
      jeder Zug verschiebt, und es taucht **nie** Text aus der Zwischenablage im Fenster auf
      (das war der Review-Bug mit `<2-MiddleMouse>`).
- [x] Mitteltaste halten, dabei Alt+Mausrad: der Zoom bleibt, das Ziehen hört auf
      (erst ein neuer Druck zieht wieder).
- [x] Ungezoomt ziehen: nichts passiert (und auch kein Einfügen).

---

## 3b. Ausschnitt in einen eigenen Float — offen

`images.nvim@916bee6`, Fix `@cb0af77`. Task `images.nvim/zen-ausschnitt-kind-float`.

- [ ] Links ziehen über einen Bereich: der Rahmen färbt sich (Warnfarbe), unten steht
      `selection 640×360 px at 120,80`; **auf dem Bild selbst wird nichts gemalt**.

```vim
```
1:36:59 PM msg_show.echo selection: drag further (a click selects nothing)
1:36:59 PM msg_show.echo selection 177×96 px at 1214,998
1:36:59 PM msg_show.echo selection 177×143 px at 1214,998
1:36:59 PM msg_show.echo selection 199×143 px at 1214,998
1:37:01 PM msg_show.echo selection: drag further (a click selects nothing)
1:37:12 PM msg_show.echo selection: drag further (a click selects nothing)
1:37:13 PM msg_show.echo selection 89×96 px at 1699,95
1:37:29 PM msg_show.echo selection: drag further (a click selects nothing)
1:37:29 PM msg_show.echo selection 67×96 px at 0,95
1:37:29 PM msg_show.echo selection 89×96 px at 0,95
1:37:36 PM msg_show.echo selection: drag further (a click selects nothing)
1:37:36 PM msg_show.echo selection 112×96 px at 220,903
1:37:36 PM msg_show.echo selection 200×143 px at 220,903
1:37:36 PM msg_show.echo selection 310×191 px at 220,903
1:37:36 PM msg_show.echo selection 465×286 px at 220,903
1:37:36 PM msg_show.echo selection 641×333 px at 220,903
1:37:36 PM msg_show.echo selection 796×428 px at 220,903
1:37:41 PM msg_show.echo selection: drag further (a click selects nothing)
1:37:41 PM msg_show.echo selection 45×96 px at 1214,427
1:37:41 PM msg_show.echo selection 68×96 px at 1191,427
1:37:41 PM msg_show.echo selection 68×144 px at 1191,427
1:37:45 PM msg_show.echo selection: drag further (a click selects nothing)
1:37:46 PM msg_show.echo selection: drag further (a click selects nothing)
1:37:47 PM msg_show.echo selection: drag further (a click selects nothing)
1:37:48 PM msg_show.echo selection: drag further (a click selects nothing)
1:37:49 PM msg_show.echo selection: drag further (a click selects nothing)
1:37:51 PM msg_show.echo selection: drag further (a click selects nothing)
1:37:53 PM msg_show.echo selection: drag further (a click selects nothing)
1:37:53 PM msg_show.echo selection 46×96 px at 1478,332
1:37:53 PM msg_show.echo selection 68×144 px at 1456,332
1:37:54 PM msg_show.echo selection: drag further (a click selects nothing)
1:37:55 PM msg_show.echo selection: drag further (a click selects nothing)

es ist aber nichts aufgegangen, kein float oder ähnlches

> **Claude, 2026-10-21:** Ursache gefunden und behoben in `images.nvim@6efad7f`. noice öffnet
> für jede `selection …`-Zeile einen eigenen Float, das löste `WinResized` aus, und der
> Zen-Float hielt das für seine eigene Größenänderung und beendete die Auswahl vor dem
> Loslassen. Jetzt zählt nur noch ein Resize des Zen-Fensters selbst. **Bitte Abschnitt 3b
> ab hier neu testen** (Neovim neu starten).

- [ ] Loslassen: kurz `cutting the selection …`, dann öffnet der Bereich in einem eigenen Float,
      Titel `name.png · 2/2`, scharf (volle Auflösung).
- [x] Im Ausschnitt noch einmal markieren → dritte Ebene `3/3`; **der richtige Bereich** des
      Originals ist zu sehen (Versatz stimmt), nicht ein verschobener. _(auto 2026-10-29: images.nvim/TESTS/zen_select_spec.lua grün)_
- [ ] Zoom/Verschieben im Ausschnitt funktioniert wie im ersten Float.
- [ ] `<BS>`: eine Ebene zurück, das vorige Bild ist wieder da, im Zoom von vorher.
- [x] `q` in der tiefsten Ebene: alle Ebenen sind zu. _(auto 2026-10-29: images.nvim/TESTS/zen_select_spec.lua grün)_
- [x] Ein Klick (ohne Ziehen) öffnet nichts. _(auto 2026-10-29: images.nvim/TESTS/zen_select_spec.lua grün)_
- [x] Tastatur: `v`, dann `lll jj` (oder `L`/`J` für 5er-Schritte), `<CR>` → Ausschnitt;
      `v` … `<Esc>` verwirft nur die Auswahl, der Float bleibt. _(auto 2026-10-29: images.nvim/TESTS/zen_select_spec.lua grün)_
- [x] Klick in ein **anderes** Fenster, während der Zen-Float fokussiert ist: Fokus wechselt dorthin
      wie gewohnt (Klick wird durchgereicht). _(auto 2026-10-29: images.nvim/TESTS/zen_select_spec.lua grün)_
- [x] Während „cutting the selection …“ sofort ein zweites Mal ziehen: es entsteht **kein**
      zweiter Float. _(auto 2026-10-29: images.nvim/TESTS/zen_select_spec.lua grün)_
- [ ] Nachmessen der Treffgenauigkeit: einen kleinen, klar abgegrenzten Bildteil (ein Icon)
      markieren — er muss im Ausschnitt vollständig sein (Toleranz ±1 Zelle, dokumentiert).

---

## 3c. Speichern (`gs`) und Kopieren (`gy`) — offen

`images.nvim@85f04b5`, Fix `@152174e`. Task `images.nvim/zen-ausschnitt-speichern-kopieren`.

- [x] Ungezoomt im ersten Float `gs`: Meldung „this is the whole original“, keine Datei.
- [x] Gezoomt `gs`: Meldung `saved …/name.crop-<x>-<y>-<w>x<h>.png`, die Datei liegt neben dem
      Original und zeigt **genau** den sichtbaren Ausschnitt, scharf.
- [x] `gs` zweimal schnell hintereinander: zwei Dateien (`…` und `…-2`), keine überschrieben.
- [x] In einem Ausschnitt-Float (2/2) `gs`: die Datei zeigt diesen Ausschnitt, an der richtigen
      Stelle des Originals (Koordinaten im Namen = Position im Original).
- [x] `gy` gezoomt, dann in Paint `Strg+V`: der sichtbare Ausschnitt erscheint.
- [ ] `gy` ungezoomt auf einer PNG: das ganze Bild erscheint in Paint.

nach `gy` ist![die untere  hälfte des bildes im float verscwhunden]($NVIM_CONFIG_DIR/docs/ROADMAP/Final_Checks/assets/bild-viewport-zen-live-tests-2026-10-20-1792582929.png) aber nur wenn man vorher gezoomt hat

> **Claude, 2026-10-21:** Die Meldung „copied …“ legte (über noice) einen Float über einen
> Teil des Bildes; WezTerm verwirft dort die Bildzellen, und beim Schließen zeichnete niemand
> nach. Behoben in `images.nvim@6efad7f`: schließt ein Float, der das Bild überdeckt, wird das
> Bild neu gezeichnet. Dein Bild ist eine JPG, deshalb wurde auch ungezoomt erst geschnitten.
> **Bitte `gy` (gezoomt und ungezoomt) und `gs` noch einmal prüfen:** das Bild muss nach der
> Meldung vollständig bleiben bzw. wiederkommen.

- [ ]
- [x] - [ ] Optional: eine animierte GIF öffnen, zoomen, `gs`/`gy` → erster Frame, keine Fehlermeldung.
- [x] Optional: `display.zen.save = { ask = true }` → `gs` fragt nach dem Namen; ein vorhandener
      Name wird abgelehnt („exists, not overwritten“).

---

## 4. Bild in die Zwischenablage (lib.nvim) — offen

`lib.nvim@bc8acf6`, Fix `@8e0dbc4`. Noch ohne Taste im Zen-Float (`gy` kommt mit
`images.nvim/zen-ausschnitt-speichern-kopieren`), deshalb per Befehl:

```vim
:lua require("lib.nvim.cross.copy_image_to_clipboard")(vim.fn.expand("C:/repos/Notes/testbild.png"), function(ok, err) print(ok, err) end)
```

- [x] Ausgabe `true nil`.
- [x] In Paint (`Strg+V`) und in Teams einfügen: das Bild erscheint (Transparenz geht unter
      Windows verloren, ist bekannt und dokumentiert).

---

## Danach

Ergebnisse (oder „passt“) an Claude geben; die Tasks werden dann abgeschlossen. Als
Nächstes im Plan: Ausschnitt per Links-Ziehen in einen Kind-Float
(`images.nvim/zen-ausschnitt-kind-float`), dann Speichern/Kopieren (`gs`/`gy`).
