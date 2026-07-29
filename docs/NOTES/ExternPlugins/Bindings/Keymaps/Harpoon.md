# Harpoon — Keymaps

Registriert in
[lua/bindings/mappings/harpoon.lua](../../../../../lua/bindings/mappings/harpoon.lua)
(aufgerufen aus `bindings.mappings.init`) und — für die Preview — in
[lua/config/harpoon/preview.lua](../../../../../lua/config/harpoon/preview.lua).

Jede Map ruft `config.harpoon.api` auf, also exakt dieselbe Funktion wie das
zugehörige `:Harpoon`-Subcommand; die Command-Entsprechung steht im `desc`.

| Mapping | Modus | Aktion | Command-Äquivalent |
|---|---|---|---|
| `<leader>h` | n | Aktuelle Datei ans **Ende** der Liste hängen. | `:Harpoon add` |
| `<leader>H` | n | Aktuelle Datei an den **Anfang** der Liste setzen. | `:Harpoon add --front` |
| `<C-e>` | n | Quick-Menu öffnen/schließen. | `:Harpoon menu` |
| `<leader>ht` | n | Liste als Telescope-Picker. | `:Harpoon menu telescope` |
| `<leader>hf` | n | Liste als fzf-lua-Picker. | `:Harpoon menu fzf` |
| `<M-1>` … `<M-9>` | n | Vollbild-Preview von Eintrag 1–9 (read-only, `q` schließt). | `:Harpoon preview <n>` |

Für einen permanenten Eintrag gibt es bewusst keine Map — das ist ein seltener,
zustandsverändernder Vorgang und läuft über `:HarpoonAddToListPermanent` bzw.
`:Harpoon add --front --permanent`.

## Im Quick-Menu selbst

Harpoon-Standardverhalten (`filetype=harpoon`, normaler Buffer): Zeilen wie Text
umsortieren, `dd` löscht einen Eintrag, `<CR>` öffnet den Eintrag unter dem
Cursor, Schließen persistiert. Mit 📌 markierte Zeilen sind dauerhafte Defaults
(`config.harpoon.pin_marks`) — nach einem `dd` holt `:Harpoon defaults sync` sie
zurück.

## In den Pickern (telescope / fzf)

| Taste | Aktion |
|---|---|
| `<CR>` | `edit` |
| `<C-v>` | `vsplit` |
| `<C-x>` | `split` |
| `<C-t>` | `tabedit` |

## Inaktiv

`<leader>1`–`<leader>4` für Direkt-Select sind nicht gemappt (Kollisionsgefahr);
stattdessen `:Harpoon select <n>`.
