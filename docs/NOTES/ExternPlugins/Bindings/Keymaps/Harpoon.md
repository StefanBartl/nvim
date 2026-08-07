# Harpoon — Keymaps

Registriert in
[lua/bindings/mappings/harpoon.lua](../../../../../lua/bindings/mappings/harpoon.lua)
(aufgerufen aus `bindings.mappings.init`).

Zwei Regeln gelten hier **by construction**, nicht per Disziplin:

1. **Jede Map ist ein Usercmd-Aufruf.** Die rhs ist immer ein
   `<cmd>Harpoon …<cr>` — eine Keymap ohne Command-Entsprechung kann es also gar
   nicht geben, und beide Wege können nicht auseinanderlaufen.
2. **Alles steht in einem which-key-Spec** (`M.spec`, `wk.add`-Form). Derselbe
   Table erzeugt die Keymaps *und* wird an `wk.add()` übergeben.

Zwei Details zur which-key-Anbindung:

- Die Keymaps werden **immer selbst** gesetzt (`lib.nvim.map`) und nie which-key
  überlassen: `wk.add` legt in der gepinnten Version nur einen Eintrag in
  which-keys eigenem Baum an, es passiert **kein** `vim.keymap.set`. Wer sich
  darauf verlässt, hat ohne which-key gar keine Mappings.
- which-key wird nie extra geladen (es ist lazy, Trigger `<leader>`): ist es
  noch nicht da, wird das Spec erst beim `User LazyLoad` von `which-key.nvim`
  nachgereicht. Das braucht es nur für das Gruppen-Label — die Beschreibungen
  liest which-key ohnehin aus dem `desc` der bestehenden Keymaps.

---

**Status: durchgehend [custom]**, keine Zeilen-Markierung nötig — anders als
bei den meisten anderen Extern-Sheets bringt `harpoon.nvim` selbst keine
Leader-Keymaps mit, die hier überschrieben werden könnten (Regel 1 oben:
jede Map ist ein eigener `<cmd>Harpoon …<cr>`-Wrapper). Es gibt also nichts,
wogegen "custom" hier kontrastieren würde.

## Gruppe `<leader>h` — "Harpoon"

| Mapping | Aktion | = Command |
|---|---|---|
| `<leader>ha` | Aktuelle Datei ans **Ende** der Liste | `:Harpoon add` |
| `<leader>hA` | Aktuelle Datei an den **Anfang** | `:Harpoon add --front` |
| `<leader>hp` | Aktuelle Datei an den Anfang **+ dauerhafter Pin** | `:Harpoon add --front --permanent` |
| `<leader>hd` | Aktuelle Datei aus der Liste entfernen | `:Harpoon remove` |
| `<leader>hm` | Quick-Menu | `:Harpoon menu` |
| `<leader>ht` | Telescope-Picker | `:Harpoon menu telescope` |
| `<leader>hf` | fzf-lua-Picker | `:Harpoon menu fzf` |
| `<leader>hs` | Fehlende Default-Pfade nachziehen | `:Harpoon defaults sync` |
| `<leader>hD` | Liste in Scratch-Buffer dumpen | `:Harpoon debug` |

## Außerhalb der Gruppe

| Mapping | Aktion | = Command |
|---|---|---|
| `<C-e>` | Quick-Menu öffnen/schließen | `:Harpoon menu` |
| `<M-1>` … `<M-9>` | Vollbild-Preview von Eintrag 1–9 (read-only, `q` schließt) | `:Harpoon preview <n>` |

`<leader>h` ist **reine Gruppe** — die frühere Doppelrolle (eigene Aktion *und*
Prefix) ist weg, damit kein `timeoutlen`-Warten und kein which-key-Overlap mehr
entsteht (`:checkhealth which-key` → "No overlapping keymaps found").

Nur per Command, bewusst ohne Keymap (selten und zustandsverändernd):
`:Harpoon unpin`, `:Harpoon defaults reset`, `:Harpoon select <n>`,
`:Harpoon health`.

---

## Im Quick-Menu selbst

Harpoon-Standardverhalten (`filetype=harpoon`, normaler Buffer): Zeilen wie Text
umsortieren, `dd` löscht einen Eintrag, `<CR>` öffnet den Eintrag unter dem
Cursor, Schließen persistiert. Mit 📌 markierte Zeilen sind dauerhafte Defaults
(`config.harpoon.pin_marks`) — nach einem `dd` holt `<leader>hs` sie zurück.

## In den Pickern (telescope / fzf)

| Taste | Aktion |
|---|---|
| `<CR>` | `edit` |
| `<C-v>` | `vsplit` |
| `<C-x>` | `split` |
| `<C-t>` | `tabedit` |
