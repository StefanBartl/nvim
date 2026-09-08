# Task — Optik des Kontextmenüs an nvzone/menu angleichen

**Status: analysiert, nicht umgesetzt** (2026-09-08, auf Ansage).
Betrifft `lib.nvim.ui.kit.menu` + `ui.kit.chooser`; wandert mit dem Kit
später nach `ui.nvim` (siehe
`WKDBooks: wkdbook-myplugins/ui.nvim/PLAN-ui-kit-migration.md`) — die
Änderungen hier sind so klein, dass sie den Umzug nicht behindern.

Vorlage ist das deinstallierte `nvzone/menu`. Gelesen wurden dort
`lua/menu/ui.lua` (der eigentliche Renderer), `lua/menu/init.lua`
(Fenster-Optionen) und `lua/menu/mappings.lua` (Maus).

---

## Was nvzone anders macht — Datei für Datei

| Detail | nvzone | wir heute |
|---|---|---|
| Padding links | `" " .. item.name` — jede Zeile beginnt mit einem Leerzeichen (`ui.lua:69`) | Label klebt an der Border |
| Breite | `get_width(items) + item_gap` (`item_gap` default **5**, `init.lua:36`) | `content_width + 2` aus `make_scratch` — kein Luftraum |
| Padding rechts | `(item.rtxt or "") .. " "` (`ui.lua:69`) | `rtxt` endet an der Border |
| Trenner | `" " .. rep("─", w - 2)`, Gruppe `LineNr` (`ui.lua:8`) — eingerückt, endet vor dem Rand | volle Breite, Rand zu Rand |
| Label-Default | `ExLightGrey` (`ui.lua:22`) — gedämpft, nicht `Normal` | ungesetzt, also `KitNormal` |
| `rtxt`-Default | `LineNr` (`ui.lua:25`) | `KitMuted` — gleichwertig |
| Fenster | `border = "single"`, `winhl = Normal:ExBlack2Bg,FloatBorder:ExBlack2Border` (`init.lua:76-79`) — **dunkler als der Editor**, hebt sich ab | Kit-Theme (`rounded`, `KitNormal` = `NormalFloat`) |
| Maus-Hover | `vim.g.nvmark_hovered` → ganze Zeile `ExBlack3Bg` (`ui.lua:36-38`), von volt getrieben | nichts |
| Einfacher Klick | volt-`click`-Action je Zeile (`ui.lua:44`) | nur `<2-LeftMouse>` (Doppelklick), `chooser.lua` |
| Klick daneben | `auto_close()` schließt das Menü (`mappings.lua:53`) | Menü bleibt offen |
| Direkttasten | `rtxt` wird als Keymap registriert (`mappings.lua:7-24`): `df` löscht die Datei direkt aus dem offenen Menü | `rtxt` ist reine Anzeige |

## Was der Screenshot zusätzlich zeigt

- **Der gelbe Block links oben ist der Cursor**, nicht die Auswahl-Zeile.
  nvzone versteckt ihn, wir nicht. Das ist der auffälligste Unterschied und
  der billigste Fix (`guicursor`-Ersatz über `winhighlight`: `Cursor:` auf
  eine Gruppe ohne Farbe, oder `vim.wo.winhl` + `vim.o.guicursor` im
  Menü-Buffer).
- **Die Auswahl-Zeile ist kaum sichtbar.** `CursorLine:KitSelection` ist
  gemappt (`chooser.lua:356`), aber ohne `hl_eol`-Wirkung endet die Färbung
  am Textende. Bei nvzone deckt die Hover-Färbung die ganze Zeilenbreite.
- **Die Nerd-Font-Icons einiger Einträge rendern als Leerraum**
  (`  Open in terminal`, `  Color Picker`, `󰊢  Git Actions`), während
  `🗑️ Delete File` sichtbar ist. Zu klären, ob das am Font im Terminal liegt
  oder an den Codepoints in `custom_menu/init.lua`; **vor** dem Rest prüfen,
  sonst poliert man um ein Loch herum.

## Vorschlag, in dieser Reihenfolge

1. **Cursor im Menü verstecken** und die Auswahl-Zeile über die volle Breite
   ziehen. Größter sichtbarer Gewinn, betrifft `ui.kit.chooser` und damit
   auch `select`/`picker`/`compare` — deshalb hinter einer Option, nicht
   pauschal.
2. **Padding**: ein Leerzeichen links, `rtxt`-Spalte endet eine Spalte vor
   dem Rand, plus Mindestluft zwischen Label und `rtxt` (nvzone nimmt 5).
   Rein in `kit/menu.lua` (`row_of`/`measure`), kein Fremdmodul betroffen.
3. **Trenner einrücken** statt Rand-zu-Rand.
4. **Einfacher Linksklick wählt aus**, und ein Klick außerhalb schließt.
   `lib.nvim.window.close_on_focus_lost` existiert schon (`kit/viewer.lua`
   benutzt es) — für den Chooser ist es eine Option, kein neues Modul.
5. **Optional, danach zu bewerten:** Maus-Hover-Markierung (braucht
   `mousemoveevent` und einen `MouseMove`-Autocmd) und `rtxt` als
   Direkttaste im offenen Menü. Beides ist Verhalten, nicht Optik — erst
   entscheiden, ob es gewollt ist.

## Was bewusst nicht übernommen wird

Der dunklere Fensterhintergrund (`ExBlack2Bg`). Das ist eine base46-Gruppe
und damit NvChad-gebunden; das Kit-Theme setzt seine Flächen selbst und soll
mit jedem Colorscheme funktionieren. Wenn das Menü sich stärker abheben
soll, gehört das in ein Kit-Preset, nicht in `menu.lua`.
