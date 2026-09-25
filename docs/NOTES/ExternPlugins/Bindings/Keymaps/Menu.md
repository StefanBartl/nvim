# Kontextmenü — Keymaps

> **Nicht mehr nvzone/menu, und nicht mehr aus dieser Config.** Seit
> 2026-09-25 kommt das Menü aus ui.nvim (`ui.menu`, gezeichnet von
> `ui.contextmenu`); `lua/config/menu/` ist gelöscht. `nvzone/menu` ist seit
> 2026-09-08 deinstalliert (`lua/plugins/nvchad.lua` schaltet NvChads Spec dafür
> ab). Die Datei liegt nur noch aus Link-Stabilität unter `ExternPlugins/`.
> Die vollständige Beschreibung steht in ui.nvims
> `lua/ui/menu/README.md`.

Konfiguriert wird es im `ui.setup`-Aufruf von
[lua/config/ui_statusline/init.lua](../../../../../lua/config/ui_statusline/init.lua)
(`menu = { ... }`), aufgerufen aus der `UIReady`-Startup-Phase
`ui_statusline` in [init.lua](../../../../../init.lua).

---

## Trigger-Keymaps

Registriert von `ui.menu.setup()` (`vim.keymap.set`).

| Mapping | Modus | Aktion | Herkunft |
|---|---|---|---|
| `<RightMouse>` | `n`, `v` | Öffnet das Menü am **Zeiger**, für den Buffer darunter. Innerhalb einer Visual-Selection bleibt sie erhalten; sonst wird der Cursor mit einem Linksklick zum Zeiger gesetzt. Klick auf Tabline/Statuszeile: nur der native Rechtsklick (deren eigene Menüs). Klick auf die Winbar: nativer Rechtsklick, danach das Menü für den Buffer des Fensters. | [custom] |
| `<A-b>` | `n`, `v` | Dasselbe Menü am **Cursor** (auch aus Visual, damit "Copy/Delete Marked" wirken). In dieser Config über `menu.key = "<A-b>"` gesetzt — ui.nvim bindet von sich aus keine Taste. | [custom] |

Beides ist nicht buffer-lokal: in neo-tree/filetree greift filetree.nvims eigene
buffer-lokale `<RightMouse>`-Bindung (siehe [NeoTree.md](NeoTree.md)), `<A-b>`
erreicht das Menü auch mit dem Cursor im Tree-Fenster.

**Warum Linksklick statt Replay des Rechtsklicks:** mit `'mousemodel' = "extend"`
(setzt `ui.contextmenu.setup`) startet ein nativer Rechtsklick im Normal-Modus
eine Visual-Selection vom alten Cursor bis zum Zeiger — das Menü hätte dann
diese Fremd-Selection kopiert oder gelöscht.

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

Untermenüs klappen **in place** auf (Drill-down), nicht als zweites Fenster.
Das Verhalten ist [default] von `ui.kit.menu`, nicht hier gebaut.

---

## Inhalt

Reihenfolge, von oben nach unten (Überschriften erscheinen nur, wenn die
Sektion mindestens einen Eintrag hat):

**1. Integrations** — ein Fly-out je Schwesterplugin. Ein Plugin erscheint,
wenn es installiert ist, `menu.integrations.<name>` nicht `false` ist und das
Plugin sich nicht selbst abgeschaltet hat (`submenu()` liefert nil). Bekannt:
`markdown`, `open`, `dap`, `cascade`, `fileops`, `images`, `spotlight`,
`color_my_ascii`, `lsp`, `gopath`, dazu die flache Zeile "Open/Close filetree"
von filetree.nvim. Die Einträge sind [custom] des jeweiligen Plugins.

**2. Eigene Zeilen** (`menu.extra`) — hier keine gesetzt.

**3. Allgemeine Sektionen**, bei **jedem Öffnen** neu gebaut. Die
Visual-Selection wird dabei festgehalten, weil ein Eintrag erst nach dem
Schließen des Menüs läuft — da ist Visual längst vorbei.

| Sektion | Eintrag | Aktion | rtxt |
|---|---|---|---|
| Code | Format Buffer | `conform.format({ lsp_fallback = true })`, sonst `vim.lsp.buf.format` | `<leader>fm` |
| Code | Code Actions | `vim.lsp.buf.code_action` | `<leader>ca` |
| Code | Inspect | `:Inspect` | — |
| Clipboard | Copy All (Buffer) | `%y+` (Fehler ohne Clipboard-Provider werden gemeldet) | `<C-a>` |
| Clipboard | Copy Marked/Selected | die beim Öffnen markierte Selection; ohne Selection der ganze Buffer | `<C-c>` |
| Clipboard | Paste Content | Systemregister `+` einfügen | `<C-v>` |
| File | Save | `:write`, Fehler werden gemeldet statt geworfen | — |
| File | Save All | alle geänderten, benannten Buffer einzeln schreiben; meldet Anzahl/Fehler | — |
| Delete | Delete Marked/Selected | die festgehaltene Selection löschen | `dm` |
| Delete | Delete All (Clear Buffer) | `%d` nach Bestätigung — **hier per `entries.delete_all = true` an** | `da` |
| Delete | Delete File | Datei von Disk löschen (Bestätigung) + `bdelete!` — **hier per `entries.delete_file = true` an** | `df` |
| Tools | Open in terminal | `:enew` + Terminal-Job mit `cwd` = Verzeichnis des Buffers | — |
| Tools | Color Picker | `ui.colorpicker` | — |
| Tools | Unicode Table | `emojis.unicode` (nur mit `emojis.nvim`) | `uni` |
| Tools | Git Actions ▸ | Untermenü aus `gitsuite.integrations.menu` (nur mit `gitsuite.nvim`) | — |

Die `rtxt`-Spalte sind `menu.hints` aus dieser Config, keine ui.nvim-Defaults.
Delete All/Delete File sind in ui.nvim standardmäßig **aus** (destruktiv über
die Selection hinaus) und werden hier bewusst eingeschaltet.

Das erste Öffnen lädt die lazy Schwesterplugins (dap, filetree ≈ 0,4 s je
Plugin); `menu.prewarm` (Default an) macht das schon im Leerlauf nach dem
Start, sodass der erste Rechtsklick ≈ 80 ms braucht statt ≈ 1,1 s.

---

## Fazit Default vs. Custom

- Öffnen/Navigieren/Schließen im Menü-Fenster: **[default]** — `ui.kit.menu`.
- `<RightMouse>`, Zusammenstellung und Inhalt der Einträge: **[default]** von
  `ui.menu`; **[custom]** sind nur `key`, die Hints und die eingeschalteten
  Delete-Einträge in dieser Config.
