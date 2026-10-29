# markdown.nvim — Live-Checks (Stand 2026-10-29)

Was in markdown.nvim headless und per Child-Editor getestet ist, aber nie in einem echten Fenster
gesehen wurde: Picker-Previews, Folds, Insert-Modus, Fenster mit unterschiedlicher Breite,
Tabellen-Kürzung und Zellen-Popup. Ist ein Abschnitt durch, die Task mit `done` schließen (oder
Bescheid geben). Ein Befund: **eigene `kind: bug`-Task** (nicht Text hier), hier unter "Befunde"
nur die Zeile mit Verweis.

**Vorher:** markdown.nvim aktuell (`:Lazy update markdown.nvim`, mindestens Stand `b2bcaa5`),
Neovim neu starten, `:checkhealth markdown` ohne Fehler. Für Abschnitt 1 pickers.nvim sowie
snacks und fzf-lua installiert. Für Abschnitt 2 render-markdown und/oder markview, falls
installiert (Kollisionstest).

Testmaterial: eine `.md`-Datei mit mindestens drei Tabellen, davon eine mit über-breiten Zellen
(> 40 Zeichen), eine mit einem Doppelbreite-Zeichen (z. B. CJK oder Emoji) in einer langen
Zelle, dazu Überschriften auf mehreren Ebenen, damit sich Folds bilden. Eine zweite `.md` im
selben Verzeichnis für den Scope `cwd`.

---

## 1. Live-Tests im echten Editor: Picker, Folds, Insert, zwei Fenster — offen

Task `markdown.nvim/live-tests-im-echten-editor-snacks-fzf-lua-folds-insert-modu`. Herkunft:
Handover `markdown.nvim/Backlog/TASKS/2026-10-15_markdown.nvim_HANDOVER_2026-10-14.md` (Abschnitt
"Offen / nicht gebaut"), Gegenprüfung von `2696980`. Raster (`table.render`) und Renderer sind
nur headless getestet. Claude kann dabei Messskripte liefern, falls etwas unklar ist.

### Picker-Previews (snacks und fzf-lua)

- [ ] Mit snacks als Picker: `:Markdown table list` in der Testdatei: Liste `file:line  header
      (n rows)` mit **Preview**, `<CR>` springt an die gewählte Tabelle
- [ ] Dasselbe mit fzf-lua als Picker (Konfiguration umstellen bzw. die Variante nutzen, die dein
      Setup bietet)
- [ ] `:Markdown table list scope=cwd`: Einträge aus beiden Dateien, Preview wechselt Datei bzw.
      Tabelle, Auswahl öffnet die richtige Datei an der richtigen Zeile
- [ ] Mit pickers.nvim: `<M-c>` schaltet die Preview um (laut `docs/BINDINGS.md`)

### Folds

- [ ] `:Markdown render on` (Raster und Renderer an, `<leader>mrr`), dann `zc` auf einer
      Überschrift, die eine Tabelle umfasst: kein Müll, keine verschobenen Zeilen
- [ ] Cursor in den gefalteten Bereich: die Cursorzeile zeigt sich sinnvoll
- [ ] `zo`: Raster und Renderer **zeichnen nach dem Aufklappen** korrekt (Tabelle als Raster,
      Überschrift mit Icon), keine Reste
- [ ] `zM` / `zR` in einer Datei mit mehreren Tabellen

### Insert-Modus

- [ ] In einer Tabellenzelle `i` / `A`, mehrere Zeichen tippen: kein Flackern, keine Verschiebung
      der Spalten oder des Cursors (die Cursor-Tabelle zeigt den echten Text, laut
      `table.render.cursor`)
- [ ] In einer Überschrift tippen (z. B. am Zeilenende `A`, Text eintippen, `<Esc>`): kein
      Flackern, Icon/Hintergrund bleiben stabil
- [ ] Schnell tippen und `<Esc>`: nach dem Verlassen ist das Raster wieder richtig

### Zwei Fenster, unterschiedliche Breite, ein Puffer

- [ ] `:vsplit`, ein Fenster mit `<C-w>|`/`:vertical resize` deutlich schmaler machen, beide zeigen
      denselben Puffer
- [ ] Tabellen-Raster und Überschrift-Regeln passen in **beiden** Fenstern zur jeweiligen Breite
      (nicht beide an der Breite des aktiven Fensters)
- [x] Fenster live verbreitern/verschmälern: das Raster legt sich neu aus (Resize) _(auto 2026-10-29: markdown.nvim/TESTS/table_render_screen_spec.lua grün)_
- [ ] `:close` des einen Fensters: das andere bleibt korrekt

### Falls rot

- Pro Befund eine eigene `kind: bug`-Task mit `refs:` auf diesen Abschnitt. Notieren: Picker
  (snacks/fzf-lua/pickers.nvim), Modus (Normal/Insert), Fensterbreiten, Fold-Zustand, Screenshot,
  falls nötig. Bei Unklarheit Claude um ein Messskript bitten.

### Danach

- [ ] Task `markdown.nvim/live-tests-im-echten-editor-snacks-fzf-lua-folds-insert-modu` mit
      `done` schließen; Bug-Tasks sind angelegt

---

## 2. Tabellen-Kürzung und Zellen-Popup im echten Fenster — offen

Task `markdown.nvim/tabellen-kuerzung-und-zellen-popup-im-echten-fenster-pruefen`. Code:
`core/table_truncate.lua` (`:Markdown table truncate`, `<leader>mtu`) und `core/table_popup.lua`
(`<leader>mtp`, `CursorHold`), nur headless geprüft (`markdown.nvim@b2bcaa5`). Hintergrund:
`docs/commands.md` (Abschnitt `truncate`) und `docs/table-wrap.md`. Defaults: `table.truncate.max
= 40` Spalten, Marker `…`, Popup an (`table.popup`).

```vim
:Markdown table truncate on
```

### Kürzung und Cursorzeile

- [x] Zellen über 40 Spalten werden mit `…` gekürzt dargestellt, die Spalten bleiben ausgerichtet;
      die Datei selbst ist unverändert (`:w` und `git diff` zeigen keine Änderung) _(auto 2026-10-29: markdown.nvim/TESTS/table_truncate_spec.lua grün)_
- [ ] Die **Cursorzeile** zeigt den vollen Text (solange `concealcursor` den aktuellen Modus nicht
      enthält); Bewegung mit `h`/`l` über den verdeckten Text ist brauchbar (kein Springen)
- [ ] Mit gesetztem `concealcursor` (z. B. `:set concealcursor=nvic`): Verhalten ist brauchbar
- [ ] Einfügemodus in einer gekürzten Zelle: Tippen funktioniert, danach wird neu berechnet
      (leicht verzögert), keine Fehlmeldung
- [ ] Scrollen und Fenster verändern: die Kürzung wird nachgezeichnet
- [ ] `<leader>mtu` schaltet die Kürzung aus und wieder an

### Popup mit dem vollen Zellentext

- [ ] Cursor in eine gekürzte Zelle, `updatetime` abwarten (`CursorHold`): ein Popup mit dem
      vollen Zellentext erscheint, schließt bei der **nächsten Bewegung**
- [ ] `<leader>mtp` öffnet das Popup auf Abruf
- [ ] Zelle ganz rechts im Fenster: das Popup ist **vollständig sichtbar** (springt nicht über den
      Rand)
- [ ] Zelle in der untersten Zeile des Fensters: das Popup ist vollständig sichtbar
- [ ] Sehr lange Zelle (mehrere Zeilen Text): Popup bleibt im Fenster lesbar

### Kollision und Sonderfälle

- [ ] Falls render-markdown oder markview installiert ist: Tabellen werden nicht doppelt oder
      fehlerhaft gezeichnet, keine Fehlermeldungen
- [x] Doppelbreite-Zeichen (CJK/Emoji) am Schnitt einer gekürzten Zelle: die Zeile ist
      **höchstens eine Spalte schmaler** als die anderen, keine kaputten Zeichen _(auto 2026-10-29: markdown.nvim/TESTS/table_truncate_spec.lua grün)_

### Falls rot

- Fehler werden **eigene Bug-Tasks**, nicht Text hier. Notieren: Fensterbreite, Zellenposition,
  `concealcursor`, `conceallevel`, ob ein Render-Plugin aktiv ist, Screenshot.

### Danach

- [ ] Task `markdown.nvim/tabellen-kuerzung-und-zellen-popup-im-echten-fenster-pruefen` mit `done`
      schließen
- [ ] Entscheidung: Die Defaults (`max = 40`, `<leader>mtu`) sind laut Task eine Einordnung von
      Claude, nicht deine Entscheidung; bei Bedarf anpassen. Soll das Popup stattdessen über
      hover.nvim laufen (ein einziges Popup-System)?

---

## Offene Fragen

- Abschnitt 1: Welcher Picker ist bei dir Standard (snacks oder fzf-lua)? Wie schaltest du
  zwischen beiden um? Die Task nennt nur "snacks und fzf-lua" ohne Weg.
- Abschnitt 1: Die Task nennt "Folds", aber nicht, ob `foldmethod=expr` per Treesitter oder
  Marker gemeint ist; Annahme: dein Standard-Fold.

---

## Befunde

<!-- eine Zeile pro Befund: Abschnitt, was passiert ist, was erwartet war, Bug-Task -->
