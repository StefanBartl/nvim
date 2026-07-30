# Vim-Visual-Multi — Keymaps

Registriert im Lazy-Spec (`init`-Funktion, läuft vor dem eigentlichen Laden)
in [lua/plugins/ui.lua](../../../../../lua/plugins/ui.lua):

```lua
vim.g.VM_default_mappings = 0
vim.g.VM_maps = {
  ["Find Under"] = "<C-n>",
  ["Find Subword Under"] = "<C-n>",
  ["I BS"] = "", -- disable conflicting insert backspace
}
```

`vim-visual-multi` bringt selbst einen kompletten Satz "permanenter" (immer
aktiver) und "buffer-lokaler" (nur während einer laufenden VM-Session
aktiver) Default-Mappings mit (`doc/vm-mappings.txt`). Diese Config schaltet
mit `VM_default_mappings = 0` **alle permanenten** Defaults ab und setzt per
`VM_maps` nur die drei Einträge oben gezielt neu bzw. explizit leer.

---

## Permanente Mappings (global, außerhalb einer VM-Session)

| Mapping | Aktion | Status |
|---|---|---|
| `<C-n>` | Wort unter Cursor selektieren / weiteres Vorkommen hinzufügen (`Find Under`) | [default] |
| `<C-n>` (Visual) | Ohne Wortgrenzen, aus Visual-Mode (`Find Subword Under`) | [default] |
| `<BS>` (Insert, VM-Session) | *deaktiviert* (`I BS` → `""`) | [custom] |

`<C-n>` ist laut Plugin-Doku (`vm-mappings.txt`, Abschnitt "Default
Mappings") die **einzige** permanente Mapping, die `VM_default_mappings = 0`
gar nicht abschalten kann ("Permanent mappings, except `<C-n>`, can be
disabled"). Der explizite Eintrag in `VM_maps` ist hier also redundant zur
Werkseinstellung — schreibt aber den bereits aktiven Default noch einmal
selbst fest, statt sich implizit auf das Verhalten zu verlassen. Wertung:
**[default]**, weil Taste und Funktion exakt der Plugin-Vorgabe entsprechen.

`I BS` ist im Original **kein** in `vm-mappings.txt` dokumentierter Eintrag
der öffentlichen Tabelle, sondern ein interner Default aus
`autoload/vm/maps/all.vim` (`"I BS": ['<BS>', 'i']` — Insert-Mode-Backspace
*innerhalb* einer aktiven VM-Multi-Cursor-Session). Diese Config deaktiviert
ihn explizit (Leerstring), laut Kommentar wegen Konflikts mit einer anderen
Insert-Backspace-Mapping in diesem Setup. Status: **[custom]**.

### Durch `VM_default_mappings = 0` deaktivierte Plugin-Defaults

Alle übrigen permanenten Default-Mappings aus `vm-mappings.txt` sind in
dieser Config **nicht** verfügbar (bewusst abgeschaltet, keine Ersatzbindung
in `VM_maps`):

| Default-Mapping (Plugin) | Aktion |
|---|---|
| `<Esc>` | VM verlassen (`Exit`) |
| `<C-Down>` | Cursor vertikal nach unten hinzufügen (`Add Cursor Down`) |
| `<C-Up>` | Cursor vertikal nach oben hinzufügen (`Add Cursor Up`) |
| `\\A` | Alle Vorkommen eines Worts selektieren (`Select All`) |
| `\\/` | Regex-Suche als Selektion starten (`Start Regex Search`) |
| `\\\` | Einzelnen Cursor an aktueller Position hinzufügen (`Add Cursor At Pos`) |
| `\\gS` | Regionen der letzten VM-Session wiederherstellen (`Reselect Last`) |
| `<C-LeftMouse>` u. a. | Maus-Mappings (zusätzlich über `VM_mouse_mappings` gated, hier nicht aktiviert) |

---

## Buffer-lokale Mappings (nur während einer laufenden VM-Session)

`VM_default_mappings` betrifft laut Doku ausdrücklich nur die **permanenten**
Mappings — Buffer-Mappings, die erst nach dem Start einer VM-Session (z. B.
via `<C-n>`) aktiv werden, bleiben unangetastet. Diese Config überschreibt
keine davon, sie gelten also alle unverändert als **[default]**:

| Mapping | Aktion |
|---|---|
| `n` / `N` | Nächstes / vorheriges Vorkommen finden |
| `]` / `[` | Zur nächsten / vorherigen selektierten Region springen |
| `<C-f>` / `<C-b>` | Schneller Sprung zur nächsten/vorherigen Seite |
| `q` / `Q` | Region überspringen / Region entfernen |
| `g/` | Cursor per `/`-Suche erweitern/bewegen |
| `R` | Ersetzen in Regionen / Replace-Modus |
| `M` | Multiline-Modus umschalten |
| `S` | Surround (benötigt `vim-surround`) |
| `<M-S-Right>` / `<M-S-Left>` | Alle Selektionen nach rechts/links verschieben |
| `<Tab>` / `<S-Tab>` | Zum nächsten/vorherigen Cursor springen (Insert/Single-Region-Modus) |
| `s` / `m` | Select-/Find-Operator |
| `<C-A>` / `<C-X>` | Zahlen erhöhen/verringern |
| `\\t`, `\\a`, `\\<`, `\\>`, `\\s`, `\\f`, `\\e`, `\\r`, `\\m`, `\\d`, `\\-`, `\\+`, `\\L`, `\\n`, `\\N` | diverse Region-/Transform-Commands (Transpose, Align, Split, Filter, Merge, Duplicate, Numbers, …) |
| `\\z`, `\\v`, `\\x`, `\\Z`, `\\V`, `\\X`, `\\@` | Run Normal/Visual/Ex (auch "Last") und Macro |
| `` \\` ``, `\\C`, `\\"`, `\\w`, `\\c`, `\\<Space>`, `\\<CR>` | Tools-/Case-Menü, Register anzeigen, Whole-Word/Case umschalten, Mappings/Single-Region toggeln |

Vollständige Referenz: `doc/vm-mappings.txt` im Plugin
(`nvim-data/lazy/vim-visual-multi/doc/vm-mappings.txt`).

---

## Offene Fragen

- Ob `<C-n>` in diesem Setup mit einer anderen Plugin-Map (z. B.
  Telescope/Snacks-History) kollidiert, wurde hier nicht geprüft — nur der
  VM-eigene Anteil ist Gegenstand dieses Dokuments.
