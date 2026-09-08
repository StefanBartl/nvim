# Handover — Rechtsklick-Menü auf `lib.nvim.ui.kit.menu`

Stand 2026-09-08. Erledigt. Diese Datei hält fest, was ein Nachfolger wissen
muss, bevor er am Menü oder an `nvzone/menu` weiterarbeitet.

Commits: `lib.nvim@8023d5b`, `nvim@49c270930`.
WKDBooks: `ALL/replaceable-dependencies.md` (nvzone/menu-Abschnitt).

---

## Was gemacht wurde

`lua/config/menu/**` öffnet sein Menü nicht mehr über `require("menu")`,
sondern über `lib.nvim.contextmenu.open`. Gerendert wird von
`lib.nvim.ui.kit.menu` (`renderer = "kit"`, gesetzt in `init.lua`s neuer
`UIReady`-Phase `menu`).

Damit sind aus der Config verschwunden: `menu.state`, `menu.utils`,
`menus.default`, `menus.gitsigns`, `menus.custom`, `menus.nvimtree` und das
Flag `vim.g._menu_custom_registered`.

In `lib.nvim` dafür entstanden:

- `contextmenu.setup{ renderer }` + `contextmenu.open(items, opts)` — der
  einzige Ort, an dem überhaupt ein Renderer angefasst wird.
- `ui.kit.menu` versteht jetzt die nvzone-Itemform (`name`/`cmd`, Trenner,
  `rtxt`, `hl`, verschachtelte `items` inkl. `items = "gitsigns"`) und
  verankert mit `mouse = true` am Zeiger.
- `ui.kit.chooser`: `selectable = false` für Rich Items (Trenner werden
  übersprungen, `<CR>` darauf ist wirkungslos), `row`/`col` durchgereicht.

## Die drei Dinge, die man wissen muss

1. **Submenüs klappen in place auf, nicht daneben.** Der Chooser ist eine
   Single-Instance; daher kommen sein Theming und sein Fenster-Lebenszyklus.
   `<BS>` geht zurück. Wer die nvzone-Optik zurückwill, schaltet
   `renderer = "nvzone"` — nicht: baut ein zweites Chooser-Fenster.
2. **`nvzone/menu` ist weiterhin installiert.** `lua/plugins/nvchad.lua` ist
   auf eine reine Spec ohne `config`-Hook geschrumpft und hält das Plugin nur
   noch, weil `volt` und `minty` (Color-Picker im Menü) daran hängen. Die
   Deinstallation ist NvChad-Abkopplung, keine Menü-Arbeit.
3. **Der allgemeine Abschnitt wird bei jedem Öffnen neu gebaut.**
   `config.menu.custom_menu` ist eine *Funktion*, kein Table. „Copy
   Marked/Selected", „Delete Marked/Selected" und „Delete File" lesen die
   Live-Selection bzw. den Buffernamen; ein einmal registriertes Table hat
   das nie gesehen — es fiel nur nicht auf, weil die Einträge intern noch
   einmal prüfen.

## Zwei Funde unterwegs

- **`menus.default` war toter Code.** `custom_menu` lud das nvzone-Default-
  Menü, hängte es an eine lokale Tabelle `menu` — und gab `composed` zurück.
  Es war nie im Menü. Inhaltlich war es zur Hälfte eine Dopplung der eigenen
  Einträge darunter (Format Buffer, Code Actions, Copy Content, Open in
  terminal, Color Picker).
- **Die `contextmenu`-README hatte eine falsche Begründung.** Sie schrieb,
  `ui.kit.menu` sei „not a fit", weil es keine Maus-Verankerung biete.
  `relative = "mouse"` ist ein normaler `nvim_open_win`-Wert und wurde von
  der Surface immer schon durchgereicht — die Option war nie probiert worden.
  Die Korrektur steht offen in der README, weil die Behauptung als Argument
  gedient hatte.

## Offen

- `volt`/`minty` ablösen, dann `nvzone/menu` entfernen.
- Der alte ROADMAP-Punkt „manchmal bleibt ein leeres Contextmenu-Fenster
  offen" betraf nvzone's Fenster-Lebenszyklus. Der Chooser schließt sich
  selbst (`WinClosed`). In `lua/config/menu/docs/ROADMAP.md` als geschlossen
  vermerkt, mit der Bitte, es einmal im echten Betrieb gegenzuprüfen.
