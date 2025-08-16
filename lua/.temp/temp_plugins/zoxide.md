Voraussetzungen

* Zoxide muss installiert und im `$PATH` verfügbar sein (`zoxide query …`). Ohne Zoxide funktioniert das Plugin nicht. ([GitHub][1])

Installation mit lazy.nvim

```lua
-- telescope + zoxide extension
return {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "jvgrootveld/telescope-zoxide",
    },
    config = function()
      local t = require("telescope")
      t.setup({
        extensions = {
          zoxide = {
            -- Optional: eigene Prompt-Überschrift
            prompt_title = "[ Zoxide List ]",
            -- Optional: Mappings erweitern/überschreiben (siehe unten)
          },
        },
      })
      -- Extension nach telescope.setup() laden
      t.load_extension("zoxide")  -- zwingend nötig, sonst kein :Telescope zoxide …
    end,
  },
}
```

Hinweis: Das Laden der Extension nach `telescope.setup()` ist Pflicht. ([GitHub][1])

Schnellstart (Kommandos)

* Liste öffnen: `:Telescope zoxide list`
* In Lua: `require("telescope").extensions.zoxide.list()`
* Praktische Keymap:

```lua
-- open zoxide list via <leader>cd
vim.keymap.set("n", "<leader>cd", require("telescope").extensions.zoxide.list, { desc = "Zoxide list" })
```

([GitHub][1])

Standardverhalten & Default-Mappings

* Enter: wechselt `:cd` in das gewählte Verzeichnis
* `<C-t>`: `:tcd` (nur aktueller Tab)
* `<C-s>` / `<C-v>` / `<C-e>`: split/vsplit/edit mit Pfad
* `<C-f>`: öffnet `telescope.builtin.find_files({ cwd = selection.path })`
  Diese Defaults kann man überschreiben/erweitern. ([GitHub][1])

Eigene Mappings (empfohlen)

```lua
-- extend/override default actions for the zoxide picker
local t = require("telescope")
local z_utils = require("telescope._extensions.zoxide.utils")
local builtin = require("telescope.builtin") -- needed for <C-f> action

t.setup({
  extensions = {
    zoxide = {
      mappings = {
        default = {
          -- on <CR>: change cwd (this mirrors the default)
          action = function(selection)
            vim.cmd.cd(selection.path)
          end,
          after_action = function(selection)
            vim.notify("Directory changed to " .. selection.path)
          end,
        },
        -- open selection in a horizontal split
        ["<C-s>"] = { action = z_utils.create_basic_command("split") },
        -- open selection in a vertical split
        ["<C-v>"] = { action = z_utils.create_basic_command("vsplit") },
        -- open selection in current window
        ["<C-e>"] = { action = z_utils.create_basic_command("edit") },
        -- jump into another picker showing files of that directory
        ["<C-f>"] = {
          keepinsert = true, -- keeps insert mode in the next picker
          action = function(selection)
            builtin.find_files({ cwd = selection.path })
          end,
        },
        -- optionally: change only the tab's directory
        ["<C-t>"] = {
          action = function(selection)
            vim.cmd.tcd(selection.path)
          end,
        },
      },
    },
  },
})

t.load_extension("zoxide")
```

Die Struktur und die Hilfsfunktion `z_utils.create_basic_command` sind so vom Plugin vorgesehen. ([GitHub][1])

Optional: Integration mit Telescope File Browser

```lua
-- requires 'telescope-file-browser.nvim' installed
["<C-b>"] = {
  keepinsert = true,
  action = function(selection)
    require("telescope").extensions.file_browser.file_browser({ cwd = selection.path })
  end,
}
```

([GitHub][1])

Typische Workflows

* Projektwechsel + Files anzeigen:

  1. `<leader>cd` → zoxide-Picker
  2. tippen, Ordner wählen, `<C-f>` → `find_files` im gewählten Ordner
* CWD/TAB-CWD setzen:

  1. `<leader>cd` → `<CR>` für `:cd`, oder `<C-t>` für `:tcd`

Troubleshooting

* `:Telescope zoxide list` nicht gefunden → prüfen, ob `require("telescope").load_extension("zoxide")` nach `telescope.setup()` aufgerufen wird. ([GitHub][1])
* Keine Treffer oder Fehler → `zoxide` muss installiert sein; `zoxide query -ls` wird vom Plugin verwendet. ([GitHub][1])

Kurzreferenz

```
Aktion                 Taste im Picker     Effekt
Öffnen (cwd ändern)    <CR>                :cd <path>
Tab-CWD setzen         <C-t>               :tcd <path>
In Split öffnen        <C-s>               :split <path>
In VSplit öffnen       <C-v>               :vsplit <path>
In aktuellem Win       <C-e>               :edit <path>
Files im Ordner suchen <C-f>               Telescope find_files cwd=<path>
```

([GitHub][1])

[1]: https://github.com/jvgrootveld/telescope-zoxide "GitHub - jvgrootveld/telescope-zoxide: An extension for telescope.nvim that allows you operate zoxide within Neovim."

