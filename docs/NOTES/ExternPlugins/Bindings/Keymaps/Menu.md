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
`<RightMouse>`-Bindung — siehe [NeoTree.md](NeoTree.md) — daher landet
`<RightMouse>` dort nie bei diesem Dispatcher. `<A-b>` ist nicht
buffer-lokal geshadowed, erreicht diesen Dispatcher also auch mit dem
Cursor im Tree-Fenster.

Seit 2026-09-21 prüft `<RightMouse>` nach dem Replay zusätzlich
`ui.statusline.menu.pointer_on_statusline()` (analog zum bestehenden
`ui.tabline.menu.pointer_on_tabline()`-Check direkt darüber) und bricht ab,
wenn der Zeiger auf einem tatsächlichen Statuszeilen-Modul saß (nicht bloß
irgendwo auf der Zeile — Padding einer `%=`-Lücke zählt bewusst nicht, dort
gäbe es ohnehin keine Click-Region zum Abfangen) — sonst poppt dort das
eigene Rechtsklick-Menü der Statuszeile (Modul entfernen/hinzufügen, siehe
`ui.nvim`s `docs/modules.md`, Abschnitt "Hover tooltip and the 'manage this
module' menu") zusammen mit diesem allgemeinen Menü auf. Die Statuszeile
selbst bindet dafür kein eigenes `<RightMouse>` — jedes Statuszeilen-Modul
bekommt stattdessen eine native Click-Region (`%N@Func@…%X`), die vor jedem
Keymap-Dispatch feuert; nur der Hover-Tooltip braucht ein echtes globales
Keymap (`<MouseMove>`, Modi `n`/`i`/`v`, registriert von `ui.nvim` selbst
sobald eine Statuszeile aktiviert wird — kein Eintrag in dieser Config).

Seit 2026-09-09 (`contributed_submenus()` in `mappings.lua`) hängt hinter
den Fly-outs zusätzlich eine flache Zeile von filetree.nvim
(`filetree.integrations.menu.window_entry()`): "Open filetree" in jedem
normalen Buffer (revealt dessen Datei im Tree), "Close filetree" wenn der
Tree gerade offen ist — inkl. mit Cursor im Tree-Fenster selbst über
`<A-b>`. Kein eigener Fly-out, weil die übrigen 18 Tree-Node-Aktionen
(rename/trash/copy/…) außerhalb des Trees nichts zum Wirken haben.

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
| 🔣 Unicode Table | `:Emojis unicode table` (Floating Window, `emojis.nvim`; war `:UnicodeTable`/`unicode.vim`) | `uni` |
| 󰊢 Git Actions ▸ | Untermenü aus `gitsuite.integrations.menu` (`E:/repos/gitsuite.nvim`, GS-09), `pcall`-geguardet -- jede Zeile geht über `:Git hunk\|blame\|diff *`, nicht mehr über rohe `gitsigns.<fn>()`-Aufrufe; nur die gitsigns-exklusiven Zeilen (Stage/Reset Hunk, Stage/Reset Buffer, Toggle Deleted) blenden ohne gitsigns.nvim aus, Blame/Diff/Preview Hunk bleiben (Preview fällt auf `:Git diff head` zurück) | — |

Weggefallen gegenüber dem alten Stand:

- **`menus.default`** wurde vorangestellt — tatsächlich aber in eine lokale
  Tabelle gehängt, die nie zurückgegeben wurde. Toter Code, und inhaltlich
  eine Dopplung der Hälfte der Einträge darunter.
- **„Lsp Actions" (`items = "lsp"`)** kommt jetzt als Contributor von
  `lsp.nvim` aus dessen aufgelöstem Keymap-Katalog.
- **`menus.gitsigns`** war eine Datendatei von nvzone/menu; die Git-Sektion
  war danach `config/menu/git.lua` (126 Zeilen, rohe `gitsigns.<fn>()`-Aufrufe)
  und ist seit `GS-09` (2026-09-22) `gitsuite.integrations.menu` --
  `config/menu/git.lua` ist gelöscht.
- **Das Legacy-Neo-tree-Menü** (`lua/config/menu/neotree/`) ist gelöscht;
  filetree.nvim macht das.

---

## Fazit Default vs. Custom

- Öffnen/Navigieren/Schließen im Menü-Fenster: **[default]** —
  `lib.nvim.ui.kit.chooser`.
- `<A-b>`, `<RightMouse>`, Zusammenstellung und Inhalt der Einträge:
  **[custom]** — vollständig von dieser Config gebaut.
