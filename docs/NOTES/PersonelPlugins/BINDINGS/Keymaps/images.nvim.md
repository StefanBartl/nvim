# images.nvim — Keymaps Cheatsheet

Buffer-lokal registriert für die Filetypes aus `keymaps.filetypes`
(default: `markdown`, `vimwiki`, `norg`, `text`).
Source: `lua/images/bindings/keymaps.lua`
Cross-reference: `docs/BINDINGS.md` (current, includes autocmds/usercmds too).

| Key | Mode | Effect | Option |
| --- | --- | --- | --- |
| `<leader>im` | n | Bild unter dem Cursor anzeigen | `keymaps.show` |
| `<leader>ig` | n | Alle Bilder des Buffers nebeneinander | `keymaps.gallery` |
| `<leader>in` | n | Nächstes Bild | `keymaps.next` |
| `<leader>ip` | n | Vorheriges Bild | `keymaps.prev` |
| `<leader>iv` | n | Bild aus der Zwischenablage einfügen | `keymaps.paste` |
| `<leader>is` | n | Bildschirmausschnitt aufnehmen und einfügen | `keymaps.screenshot` |
| `<2-LeftMouse>` | n | Doppelklick auf einen Markdown-Link zeigt das Bild | `keymaps.double_click` |

Jeder Eintrag akzeptiert `false` zum Abschalten der einzelnen Bindung.

```lua
require("images").setup({
  keymaps = {
    show = "<leader>im",
    gallery = "<leader>ig",
    next = "<leader>in",
    prev = "<leader>ip",
    paste = "<leader>iv",
    screenshot = "<leader>is",
    double_click = true,
    filetypes = { "markdown", "vimwiki", "norg", "text" },
  },
})
```

## which-key

`<leader>i` — **hergeleiteter**, nicht fest konfigurierter Präfix: die
Gruppe ergibt sich aus dem längsten gemeinsamen Präfix der tatsächlich
konfigurierten `keymaps.*`-Werte, nicht aus einer eigenen
`which_key.prefix`-Option — ein vollständig umgemapptes Set gruppiert
also weiterhin korrekt. Übersprungen, wenn weniger als zwei Keys einen
Präfix teilen, oder wenn der Präfix selbst einer der gemappten Keys wäre
(sonst zeigte which-key an derselben Taste sowohl eine Aktion als auch
eine Gruppe). Nur mit which-key.nvim installiert, sonst kein Effekt.

## Notes

- **Der `i`-Präfix war komplett frei**: Vor der Vergabe gegen den gesamten
  `nvim/config`-Baum, beide BINDINGS-Sammlungen und alle eigenen Plugins in
  `E:\repos` geprüft — kein einziges `<leader>i…` existierte.

- **Doppelklick schluckt nichts**: Trifft der Klick keinen Bildlink, fällt die
  Bindung auf die normale Wortauswahl (`viw`) zurück. Ein gewöhnlicher
  Doppelklick verhält sich also unverändert.

- **`<leader>iv` statt `<leader>ip` für paste**: `ip` ist bereits die
  Rückwärts-Navigation, und `v` liegt näher an „einfügen" als das doppelt
  belegte `p`.

- **Nur sechs Keymaps trotz vielen Subcommands**: `:Image replace/export/
  redact/orphans/pickers/compare/zen/check` sind bewusst nicht verdrahtet —
  seltener gebrauchte oder Argument-tragende Befehle (Pfad/Scope) eignen
  sich schlecht für eine feste Taste; sie bleiben Usercommand-only (siehe
  Usercmds-Sheet). `screenshot` dagegen ist genauso alltäglich wie `paste`
  und braucht kein Argument, deshalb eine Bindung. `:Image redact` hat
  zusätzlich eigene, aber *fensterlokale* Tasten (`w`/`u`, Visual-Mode
  `<CR>`) innerhalb des Zensur-Fensters selbst — die stehen nicht hier,
  sondern im Usercmds-Sheet, weil sie nicht über `keymaps.*`/
  `keymaps.filetypes` laufen wie der Rest dieser Tabelle.

## Changelog

- 2026-08-06: bei der Checklisten-Runde gegengeprüft — Inhalt stimmt weiterhin
  mit `bindings/keymaps.lua` überein, keine Änderung nötig.
- 2026-08-06 (2): `<leader>is` für `:Image screenshot` ergänzt.
- 2026-08-06 (3): `:Image export` ergänzt (Usercommand-only, siehe oben) —
  kein neues Keymap nötig, keine Änderung an dieser Datei sonst.
- 2026-08-06 (4): `:Image redact` ergänzt (Usercommand-only, mit
  fensterlokalen Tasten statt `keymaps.*`, siehe oben) — kein neues
  `keymaps.*`-Feld.
- 2026-08-06 (5): `## which-key`-Abschnitt ergänzt und Changelog in eine
  eigene Überschrift gezogen, per `docs/NOTES/BINDINGS-FORMAT.md` (erste
  Korrektur nach dessen Regeln).
