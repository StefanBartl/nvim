# Kontextmenü — Keymaps

> **Nicht mehr nvzone/menu.** Das Menü wird seit 2026-09-08 von
> `lib.nvim.ui.kit.menu` über `lib.nvim.contextmenu` gezeichnet, und
> `nvzone/menu` ist seither **deinstalliert**
> (`lua/plugins/nvchad.lua` schaltet NvChads Spec dafür ab). Die Datei liegt
> nur noch aus Link-Stabilität unter `ExternPlugins/`. Zum Renderer-Wechsel
> siehe [lua/config/menu/README.md](../../../../../lua/config/menu/README.md).

Aufgesetzt wird es aus der `UIReady`-Startup-Phase `menu` in
[init.lua](../../../../../init.lua) — nicht mehr aus dem lazy-`config`-Hook
von `nvzone/menu`.
[lua/plugins/nvchad.lua](../../../../../lua/plugins/nvchad.lua) besteht nur
noch aus dem `enabled = false` dafür. `volt` (Theme-Picker von `nvchad/ui`)
und `minty` (Color Picker) hingen nie an dieser Spec, sondern an NvChads
eigener Liste, und bleiben installiert.

---

## Trigger-Keymaps

Registriert in
[lua/config/menu/mappings.lua](../../../../../lua/config/menu/mappings.lua)
(`M.setup()`), beide über `lib.nvim.bindings.keymap`.

| Mapping | Modus | Aktion | Herkunft |
|---|---|---|---|
| `<A-b>` | `n` | Öffnet dasselbe Menü am **Cursor** (`mouse = false`). | [custom] |
| `<RightMouse>` | `n`, `v` | Repliziert zuerst das native `<RightMouse>` (Cursor/Fenster setzen), baut dann das Menü für den Buffer **unter dem Zeiger** und öffnet es dort (`mouse = true`). | [custom] |

Kein Filetype-Routing mehr auf `neo-tree`/`NvimTree` und keine benannten
Menüs (`"custom"`, `"default"`, `"nvimtree"`): beide Maps bauen dieselbe
Item-Liste, die sich über ihre Contributor-Gates selbst auf den Buffer
zuschneidet. In neo-tree greift ohnehin filetree.nvims eigene buffer-lokale
`<RightMouse>`-Bindung — siehe [NeoTree.md](NeoTree.md).

---

## Navigation im Menü

Bewusst als Liste, nicht als Tabelle: das sind buffer-lokale Bindings des
Chooser-Fensters, keine Bindings dieser Config — eine Spalte `Taste` würde
sie dem Bindings-Explorer als dokumentierte Config-Keymaps unterschieben
(siehe `bindings_explorer/drift.lua`).

- `j`/`k`, Pfeile — Eintrag wechseln; Trenner werden übersprungen
- `<CR>` — Eintrag auslösen; auf einem `▸`-Eintrag: eine Ebene hinein
- `<BS>` — eine Ebene zurück
- `<Esc>`, `q` — schließen

Untermenüs klappen **in place** auf (Drill-down), nicht als zweites Fenster
neben dem Elternmenü — das ist der eine sichtbare Unterschied zu nvzone/menu.
Das Verhalten ist [default] des `lib.nvim.ui.kit.chooser`, nicht hier gebaut.

---

## Inhalt

Das Menü hat zwei Teile, in dieser Reihenfolge:

**1. Ein Fly-out je zutreffendem Plugin.** `CONTRIBUTORS` in `mappings.lua`
listet die "Pattern-B"-Plugins — solche, die nur
`<plugin>.integrations.menu` mitbringen und keinen eigenen Trigger.
Aktuell: `markdown`, `open`, `wkddap`, `cascade`, `fileops`, `images`,
`spotlight`, `color_my_ascii`, `lsp`. Die Einträge selbst sind [custom] des
jeweiligen Plugins, nicht dieser Config.

**2. Der allgemeine Abschnitt**, unter einem Trenner — gebaut von
[lua/config/menu/custom_menu/init.lua](../../../../../lua/config/menu/custom_menu/init.lua)
bei **jedem Öffnen** neu, weil mehrere Einträge von der aktuellen
Visual-Selection und dem Buffernamen abhängen. Toggles per `opts.enable_*`,
Default `true`, gesetzt in der `menu`-Phase in `init.lua`.

| Eintrag | Aktion | rtxt |
|---|---|---|
| Format Buffer | `conform.format({ lsp_fallback = true })`, sonst `vim.lsp.buf.format` | `<leader>fm` |
| Code Actions | `vim.lsp.buf.code_action` | `<leader>ca` |
| Copy All (Buffer) | `%y+` | `<C-a>` |
| Copy Marked/Selected | Visual-Selection `gvy` yanken, sonst ganzen Buffer | `<C-c>` |
| Paste Content | Systemregister `+` einfügen | `<C-v>` |
| Delete Marked/Selected | Visual-Selection löschen (`gvd`) | `dm` |
| Delete All (Clear Buffer) | `%d` nach Bestätigung (`lib.nvim.ui.kit.confirm`) | `da` |
| 🗑️ Delete File | Datei von Disk löschen (Bestätigung) + `bdelete!` | `df` |
| 🖥️ Open in terminal | `nvchad.term.new` (Split, cd ins Buffer-Verzeichnis) falls Base46 aktiv, sonst `:enew` + Terminal-Job | — |
| 🎨 Color Picker | `minty.huefy.open()` | — |
| 🔣 Unicode Table | `:UnicodeTable` (Floating Window, `unicode.vim`) | `uni` |
| 󰊢 Git Actions ▸ | Untermenü aus [lua/config/menu/git.lua](../../../../../lua/config/menu/git.lua), nur wenn gitsigns.nvim da ist | — |

Weggefallen gegenüber dem alten Stand:

- **`menus.default`** wurde vorangestellt — tatsächlich aber in eine lokale
  Tabelle gehängt, die nie zurückgegeben wurde. Toter Code, und inhaltlich
  eine Dopplung der Hälfte der Einträge darunter.
- **„Lsp Actions" (`items = "lsp"`)** kommt jetzt als Contributor von
  `lsp.nvim` aus dessen aufgelöstem Keymap-Katalog.
- **`menus.gitsigns`** war eine Datendatei von nvzone/menu; die Git-Sektion
  ist jetzt `config/menu/git.lua`.
- **Das Legacy-Neo-tree-Menü** (`lua/config/menu/neotree/`) ist gelöscht;
  filetree.nvim macht das.

---

## Fazit Default vs. Custom

- Öffnen/Navigieren/Schließen im Menü-Fenster: **[default]** —
  `lib.nvim.ui.kit.chooser`.
- `<A-b>`, `<RightMouse>`, Zusammenstellung und Inhalt der Einträge:
  **[custom]** — vollständig von dieser Config gebaut.
