# search.nvim — Keymaps

Plugin-Spec in
[lua/plugins/telescope.lua](../../../../../lua/plugins/telescope.lua),
Setup ausgelagert nach
[lua/config/search/init.lua](../../../../../lua/config/search/init.lua)
(`M.setup()`, aufgerufen aus dem `config`-Block des Specs).

`FabianWirth/search.nvim` ist ein schlanker Tabbed-UI-Wrapper um Telescope —
es liefert selbst **keine** vorgeschlagenen Default-Keymaps für den
Öffnen-Trigger (laut README muss der Aufrufer `require("search").open()`
selbst binden). Einzig die Tab-Navigation *innerhalb* der UI hat einen
Default (`<Tab>`/`<S-Tab>`), der hier unverändert übernommen wird.

---

## Öffnen-Trigger (custom)

| Mapping | Modus | Aktion | = Lua |
|---|---|---|---|
| `<leader>s` | Normal | Tabbed-Search-UI öffnen (Default-Tab = erster Tab, `Files`) | `require("search").open()` |

**[custom]** — in `lua/plugins/telescope.lua` als lazy.nvim-`keys`-Eintrag
gesetzt (`desc = "Search (tabbed UI)"`). Ohne Argumente startet `open()` auf
dem ersten konfigurierten Tab.

## Tabs (Konfiguration, kein Keymap)

Aus [lua/config/search/init.lua](../../../../../lua/config/search/init.lua),
`search.setup({ tabs = {...}, collections = { git = {...} } })`:

| Tab | Telescope-Funktion |
|---|---|
| `Files` | `git_files` (im Git-Repo) sonst `find_files` |
| `All Files` | `find_files` mit `no_ignore = true, hidden = true` |
| `Grep` | `live_grep` |
| `Buffers` | `buffers` |

Collection `git` (separater Tab-Satz, per `open({ collection = "git" })`
erreichbar — dafür ist kein Keymap gesetzt, nur die Öffnen-Funktion ist
konfiguriert): `Branches` (`git_branches`), `Commits` (`git_commits`),
`Stashes` (`git_stash`).

---

## Innerhalb der Tabbed-UI

| Taste | Modus | Aktion | Herkunft |
|---|---|---|---|
| `<Tab>` | Normal + Insert | Nächster Tab | **[custom]** — explizit in `mappings.next` gesetzt (entspricht dem Plugin-Default, aber hier bewusst re-deklariert statt implizit übernommen) |
| `<S-Tab>` | Normal + Insert | Vorheriger Tab | **[custom]** — dito, `mappings.prev` |

Alles andere in der UI (Navigation innerhalb der Liste, `<CR>`, Insert vs.
Normal Mode etc.) ist unverändertes Telescope-Verhalten — search.nvim öffnet
lediglich ein normales Telescope-Picker-Fenster pro Tab und fügt die
Tab-Bar/-Navigation obendrauf.
