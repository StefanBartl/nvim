# images.nvim — Keymaps Cheatsheet

Buffer-lokal registriert für die Filetypes aus `keymaps.filetypes`
(default: `markdown`, `vimwiki`, `norg`, `text`).
Source: `lua/images/bindings/keymaps.lua`

| Key | Mode | Effect | Option |
| --- | --- | --- | --- |
| `<leader>im` | n | Bild unter dem Cursor anzeigen | `keymaps.show` |
| `<leader>ig` | n | Alle Bilder des Buffers nebeneinander | `keymaps.gallery` |
| `<leader>in` | n | Nächstes Bild | `keymaps.next` |
| `<leader>ip` | n | Vorheriges Bild | `keymaps.prev` |
| `<leader>iv` | n | Bild aus der Zwischenablage einfügen | `keymaps.paste` |
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
    double_click = true,
    filetypes = { "markdown", "vimwiki", "norg", "text" },
  },
})
```

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
