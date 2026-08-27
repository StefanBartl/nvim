# nvzone/menu — Keymaps

`nvzone/menu` ist eine "Baue dein eigenes Menü"-Bibliothek ohne eigene
Default-Keymaps. Das eigentliche Menü-System (Öffnen/Navigieren/Schließen,
Untermenüs via `items = "<name>"`) ist reines Library-Verhalten von
[nvzone/menu](https://github.com/nvzone/menu) selbst — hier dokumentiert wird
ausschließlich, **wie diese Config** das Menü aufhängt und befüllt.

Plugin-Spec: [lua/plugins/nvchad.lua](../../../../../lua/plugins/nvchad.lua)
(`event = "VeryLazy"`, ruft `config.menu.init.setup()` und danach
`config.menu.mappings.setup()`).

---

## Trigger-Keymaps

Registriert in
[lua/config/menu/mappings.lua](../../../../../lua/config/menu/mappings.lua)
(`M.setup()`).

| Mapping | Modus | Aktion | Herkunft |
|---|---|---|---|
| `<A-b>` | `n` | Öffnet das Top-Level-Menü. Markdown-Buffer bekommen zusätzlich die Einträge von `markdown.nvim` (Fold-on-Heading, TOC, Refs) vorangestellt, danach das custom Menü. Sonst: `custom`-Menü falls registriert (`vim.g._menu_custom_registered`), sonst `menu.open("default")`. | [custom] |
| `<RightMouse>` | `n`, `v` | Kontextabhängiges Menü an Mausposition. Repliziert zuerst das native `<RightMouse>` (Cursor/Fenster setzen), dann Routing nach Filetype: Markdown → wie `<A-b>`; `neo-tree`/`neo_tree` → `filetree.nvim`-Menü (falls vorhanden) sonst Legacy-Neo-tree-Menü (siehe unten); `NvimTree*` → `"nvimtree"`; sonst `custom` oder `"default"`. | [custom] |

Beide Maps nutzen `vim.g.__map_helper` (Fallback auf lokales `map`), nicht
`lib.nvim.bindings.keymap` direkt.

---

## Aufbau des `custom`-Menüs

[lua/config/menu/init.lua](../../../../../lua/config/menu/init.lua) registriert
das von
[lua/config/menu/custom_menu/init.lua](../../../../../lua/config/menu/custom_menu/init.lua)
gebaute Table unter `package.loaded["menus.custom"]`, damit `menu.open("custom")`
es findet (nvzone/menu requirt intern `menus.<name>`).

Einträge im `custom`-Menü (`config.menu.custom_menu`, Toggles per `opts.enable_*`,
alle Default `true` — gesetzt aus [lua/plugins/nvchad.lua](../../../../../lua/plugins/nvchad.lua)):

| Eintrag | Aktion | rtxt (Hinweis-Label) |
|---|---|---|
| Format Buffer | `conform.format({ lsp_fallback = true })`, sonst `vim.lsp.buf.format` | `<leader>fm` |
| Code Actions | `vim.lsp.buf.code_action` | `<leader>ca` |
| 󰅩 Lsp Actions | Untermenü `items = "lsp"` (`menus.lsp`) | — |
| Copy All (Buffer) | `%y+` | `<C-a>` |
| Copy Marked/Selected | Visual-Selection `gvy` yanken, sonst ganzen Buffer | `<C-c>` |
| Paste Content | Systemregister `+` einfügen | `<C-v>` |
| Delete Marked/Selected | Visual-Selection löschen (`gvd`) | `dm` |
| Delete All (Clear Buffer) | `%d` nach Bestätigungs-Dialog (`lib.nvim.ui.kit.confirm`) | `da` |
| 🗑️ Delete File | Datei von Disk löschen (Bestätigung) + `bdelete!` | `df` |
| 🖥️ Open in terminal | `nvchad.term.new` (Split, cd in Buffer-Verzeichnis) falls Base46 aktiv, sonst `:enew` + Terminal-Job | — |
| 🎨 Color Picker | `minty.huefy.open()` | — |
| 🔣 Unicode Table | `:UnicodeTable` (Floating Window, `unicode.vim`) | `uni` |
| 󰊢 Git Actions | Untermenü `items = "gitsigns"` (`menus.gitsigns`), nur wenn `enable_git_section` | — |

Vorangestellt wird immer der Original-Inhalt von `menus.default` (nvzone-Default-
Menü, unverändert übernommen).

---

## Neo-tree-Kontextmenü (Legacy-Fallback)

[lua/config/menu/neotree/init.lua](../../../../../lua/config/menu/neotree/init.lua)
baut ein gemergtes Neo-tree-Menü: Original `menus.neo-tree` (nvzone-Default) +
alle `enabled = true`-Einträge aus
[lua/config/menu/neotree/entries.lua](../../../../../lua/config/menu/neotree/entries.lua),
für die `config.neotree.keymaps().window()` tatsächlich einen Handler liefert.
Dieser Pfad wird von `config.menu.mappings` nur noch als **Fallback** benutzt,
wenn `filetree.integrations.menu` nicht verfügbar ist (`filetree.nvim`
übernimmt inzwischen die eigentlichen Neo-tree-Menüeinträge — siehe
[NeoTree.md](NeoTree.md)).

Die Entries in `entries.lua` sind reine **Labels/Icons für Keymaps, die in
Neo-tree selbst existieren** (z. B. `q`, `<CR>`, `a`, `d`, `r`, `gr`, …) — siehe
[NeoTree.md](NeoTree.md) für die eigentlichen Bindings. Als Menü-Einträge sind
sie [custom] (diese Config kuratiert Auswahl/Label/Icon), die zugrunde liegenden
Tasten selbst sind Neo-tree-Bindings, nicht Menu-Bindings.

---

## Fazit Default vs. Custom

- Öffnen/Navigieren/Schließen des Menüs (Pfeiltasten, `<CR>`, `<Esc>` im Menü-
  Fenster selbst): **[default]** — reines `nvzone/menu`-Bibliotheksverhalten,
  hier nicht erneut dokumentiert.
- `<A-b>`, `<RightMouse>` sowie sämtliche Menü-Einträge (Inhalt, Reihenfolge,
  Icons, Aktionen): **[custom]** — vollständig von dieser Config gebaut.
