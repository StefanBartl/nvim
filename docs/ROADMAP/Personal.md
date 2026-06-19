# Roadmao: Personal Plugins

## `nvim-containers`

1. Neues feature testen usw...

---

## `gopath.nvim`

1. `gopath`: solte eigentlich diese Pfade öffnen können:

  1. Default`gf` funktionert, gopath.nvim aber nicht:

    ```lua
    ---@module 'custom.markdown.hl_options' -- <-- in diesem modul
    --- ...
    --- ...
    local blockquote = require("custom.markdown.hl_options.hl_groups.blockquote") -- <-- funktoinert `gF` nicht, aber `gf` schon
    ```

    1.  `.../AppData/Local/nvim/lua/config/neotree/commands/init.lua:13: module 'config.neotree.commads.markdown_links' not found:`

---

