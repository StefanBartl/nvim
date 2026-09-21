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
| `<leader>bp` | Aktuellen Tab pinnen/entpinnen (`toggle_pin`) |
| `<leader>bu` | Zuletzt geschlossenen Tab wieder öffnen (`reopen_closed`) |

### Tabs

| Mapping | Aktion |
|---|---|
| `<leader>tr` | Aktuellen Tab nach rechts verschieben (`nvchad.tabufline.move_buf(1)`) |
| `<leader>tl` | Aktuellen Tab nach links verschieben (`nvchad.tabufline.move_buf(-1)`) |
| `<leader>tt` | Aktuellen Buffer in neuen Tab verschieben (`lib.nvim.buf_win_tab.move_buffer_to_tab`) |

Alle Handler sind `pcall`-abgesichert; schlägt der zugrunde liegende Aufruf
fehl, kommt eine `notify.warn` statt eines rohen Fehlers.

### Pinnen und "Tab wieder öffnen" (ui.nvim)

Ein gepinnter Tab steht immer vor den ungepinnten (Invariante in
`vim.t.bufs`), bleibt bei Overflow sichtbar und ist von jedem Sammel-Close
ausgenommen (`<leader>bq`, sowie „Close others“/„to the left“/„to the
right“/„saved“ im Tab-Menü). Statt „x“/Modified-Punkt zeigt ein gepinnter
Chip ein Pin-Glyph; ein Klick darauf entpinnt. Mittelklick und ein
Linksklick auf „x“ schließen einen gepinnten Tab **nicht** (Hinweis statt
Aktion) — nur das Menü-„Close“ oder Entpinnen kommt durch. Pin-Status ist
tab-lokal und überlebt keinen Neustart.

„Tab wieder öffnen“ merkt sich die letzten 20 geschlossenen echten Dateien
(keine Scratch-/Terminal-/Quickfix-Buffer), neueste zuerst, dedupliziert
nach Pfad. `<leader>bu` öffnet den zuletzt geschlossenen wieder (`:edit` +
Cursor-Wiederherstellung + Einsortieren an den gemerkten Slot im aktuellen
Tab); das Tab-Menü listet den ganzen Ring über „Reopen closed tab ▸“.

### Maus auf der Tableiste (ui.nvim)

Keine Keymaps im engeren Sinn: `ui.tabline` bekommt vom Tabline-Klickprotokoll
den Button und den Buffer des Chips mitgeliefert (siehe ui.nvim
`docs/BINDINGS.md` → „Tabline mouse"). `context_menu`, `drag` und
`middle_click_close` in der Tabline-Config schalten je eine Geste ab; der
Pin-Schutz hat keinen Opt-out.

| Geste | Auf | Aktion |
|---|---|---|
| Linksklick | Chip | Zum Buffer wechseln |
| Linksklick halten + ziehen | Chip | Chip entlang der Leiste verschieben (live); am Rand halten scrollt die Ansicht automatisch weiter |
| Rechtsklick | Chip oder dessen „x“/Pin-Glyph | Tab-Kontextmenü (`ui.tabline.menu`) |
| Mittelklick | Chip | Buffer schließen — bei einem gepinnten Tab abgelehnt |
| Linksklick | „x“ des Chips | Buffer schließen — bei einem gepinnten Tab abgelehnt |
| Linksklick | Pin-Glyph eines gepinnten Chips (dessen „x“-Slot) | Entpinnen |

Das Tab-Kontextmenü enthält nur Aktionen auf genau diesen Tab: Save (nur bei
Änderungen), Pin/Unpin, Close, Close others / to the left / to the right /
saved (alle drei ohne gepinnte Tabs im Close-Set), Move to position… (`3`
absolut, `+2`/`-1` relativ), Move left / right / to start / to end, Copy
path, Open in split / vertical split, Move to new tab page, Reopen closed
tab ▸ (ein Eintrag pro Ring-Slot, fehlt bei leerem Ring).

Der globale `<RightMouse>`-Dispatcher in
[lua/config/menu/mappings.lua](../../../../../lua/config/menu/mappings.lua)
spielt den Klick nach (`normal! <RightMouse>`), wodurch der Chip-Handler
feuert, und kehrt danach zurück, wenn
`require("ui.tabline.menu").pointer_on_tabline()` wahr ist — sonst würde das
allgemeine Menü über dem Tab-Menü aufgehen.

## Changelog

- 2026-09-21: Abschnitt „Pinnen und 'Tab wieder öffnen'“ ergänzt
  (`<leader>bp`/`<leader>bu`, Pin-Glyph, Close-Schutz, Reopen-Ring,
  Auto-Scroll beim Ziehen).
- 2026-09-21: Abschnitt „Maus auf der Tableiste“ (Rechtsklick-Menü, Ziehen,
  Mittelklick) ergänzt; `<RightMouse>`-Dispatcher tritt auf der Tableiste zurück.
