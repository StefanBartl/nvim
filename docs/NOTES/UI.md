Verstanden: `_` ist die Toggle-Taste für **Slots**, die Marks bleiben unverändert. So ist es auch gemappt, es ist nichts zu ändern.

## Marks (sessions.nvim, `<leader>` = Space)

| Taste | Aktion |
| --- | --- |
| `<leader>ha` | aktuelle Datei markieren (hinten) |
| `<leader>hA` | aktuelle Datei **vorne** markieren |
| `<leader>h1` … `<leader>h9` | zu Mark 1–9 springen |
| `<leader>hm` | Marks-Menü (Picker) |
| `<C-e>` | Marks-Menü (wie harpoons Quick-Menu) |
| `<leader>hE` | Mark-Liste editieren |
| `<leader>hp` | Datei pinnen |
| `<leader>hd` | Markierung der Datei entfernen |
| `<leader>hs` | fehlende Default-Marks ergänzen |
| `<leader>hD` | Mark-Liste dumpen (Debug) |
| `<M-1>` … `<M-9>` | Vollbild-Preview von Mark 1–9 |
| `<M-s>` | Chip-Sichtbarkeit umschalten |
| `q` / `<Esc>` / `<C-e>` | im Marks-Menü: schließen |

## Slots (ui.nvim)

| Taste | Aktion |
| --- | --- |
| `_` | Slot-Leiste ein/aus |
| `<leader>_1` … `<leader>_9` | Slot 1–9 ausführen |
| `<leader>_a` | aktuelle Datei in den nächsten freien Slot |
| `<leader>_p` | Slot-Panel öffnen |

**Im Slot-Panel**: `<CR>` ausführen, Ziffern springen (`1`, dann `2` = Slot 12), `e` editieren, `a` hinzufügen, `dd` löschen, `y` kopieren, `<C-j>`/`<C-k>` verschieben, `K` Preview, `q`/`<Esc>` schließen.

**Auf der Leiste**: Klick führt aus, Rechtsklick öffnet das Menü, das Mausrad scrollt.

**Befehle**: `:UI slots [n|add|yank|clear|move|toggle|open|close|panel|edit]` und `:Session marks`.
