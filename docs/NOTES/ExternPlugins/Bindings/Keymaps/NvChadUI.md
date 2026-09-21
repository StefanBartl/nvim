# nvchad/ui — Keymaps

**Repo:** `NvChad/ui` — gelesen von `:Bindings check`, weil das Repo schlicht `ui` heißt.

`nvchad/ui` selbst (Statusline/Tabufline/Base46) bringt in dieser Config keine
verwendeten Default-Keymaps mit — sie sind entweder deaktiviert oder durch
eigene Mappings ersetzt. Alle folgenden Einträge sind **[custom]**.

## Theme-Switcher

| Mapping | Aktion | Quelle |
|---|---|---|
| `<leader>nvt` | `require("nvchad.themes").open({ icon = "", style = "compact", border = false })` — interaktiver Theme-Picker (NvChad-eigenes UI-Widget) | [lua/bindings/mappings/nvchad.lua](../../../../../lua/bindings/mappings/nvchad.lua) |

Ergänzt die commandbasierte Steuerung `:UI theme`/`:Theme` (siehe
[Usercmds/NvChadUI.md](../Usercmds/NvChadUI.md)) um einen visuellen Picker.

## Tabufline (Buffer-/Tab-Navigation)

Registriert in [lua/wkdnvchad/mappings/init.lua](../../../../../lua/wkdnvchad/mappings/init.lua),
aufgerufen aus `wkdnvchad.setup({ all = true })` in
[lua/chadrc.lua](../../../../../lua/chadrc.lua). Nutzt `lib.nvim.bindings.keymap` sowie
lazy-geladene Helper aus [lua/wkdnvchad/mappings/tabufline/init.lua](../../../../../lua/wkdnvchad/mappings/tabufline/init.lua).

### Buffer

| Mapping | Aktion |
|---|---|
| `<Tab>` | Nächster Buffer, unterstützt Count (`v:count1` × `move_next_n`) |
| `<S-Tab>` | Vorheriger Buffer, unterstützt Count (`move_prev_n`) |
| `<leader>bc` | Buffer schließen, unterstützt Count (`close_n_buffers`) |

### Tabs

| Mapping | Aktion |
|---|---|
| `<leader>tr` | Aktuellen Tab nach rechts verschieben (`nvchad.tabufline.move_buf(1)`) |
| `<leader>tl` | Aktuellen Tab nach links verschieben (`nvchad.tabufline.move_buf(-1)`) |
| `<leader>tt` | Aktuellen Buffer in neuen Tab verschieben (`lib.nvim.buf_win_tab.move_buffer_to_tab`) |

Alle Handler sind `pcall`-abgesichert; schlägt der zugrunde liegende Aufruf
fehl, kommt eine `notify.warn` statt eines rohen Fehlers.

### Maus auf der Tableiste (ui.nvim)

Keine Keymaps im engeren Sinn: `ui.tabline` bekommt vom Tabline-Klickprotokoll
den Button und den Buffer des Chips mitgeliefert (siehe ui.nvim
`docs/BINDINGS.md` → „Tabline mouse"). `context_menu`, `drag` und
`middle_click_close` in der Tabline-Config schalten je eine Geste ab.

| Geste | Auf | Aktion |
|---|---|---|
| Linksklick | Chip | Zum Buffer wechseln |
| Linksklick halten + ziehen | Chip | Chip entlang der Leiste verschieben (live) |
| Rechtsklick | Chip oder dessen „x“ | Tab-Kontextmenü (`ui.tabline.menu`) |
| Mittelklick | Chip | Buffer schließen |
| Linksklick | „x“ des Chips | Buffer schließen |

Das Tab-Kontextmenü enthält nur Aktionen auf genau diesen Tab: Save (nur bei
Änderungen), Close, Close others / to the left / to the right / saved,
Move to position… (`3` absolut, `+2`/`-1` relativ), Move left / right / to
start / to end, Copy path, Open in split / vertical split, Move to new tab
page.

Der globale `<RightMouse>`-Dispatcher in
[lua/config/menu/mappings.lua](../../../../../lua/config/menu/mappings.lua)
spielt den Klick nach (`normal! <RightMouse>`), wodurch der Chip-Handler
feuert, und kehrt danach zurück, wenn
`require("ui.tabline.menu").pointer_on_tabline()` wahr ist — sonst würde das
allgemeine Menü über dem Tab-Menü aufgehen.

## Changelog

- 2026-09-21: Abschnitt „Maus auf der Tableiste“ (Rechtsklick-Menü, Ziehen,
  Mittelklick) ergänzt; `<RightMouse>`-Dispatcher tritt auf der Tableiste zurück.
