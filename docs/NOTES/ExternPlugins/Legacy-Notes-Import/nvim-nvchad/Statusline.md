==============================================================================
4. Statusline                                                  *nvui.statusline*

NvChad's statusline is minimal & customizable with less abstraction
for custom modules, it has 4 themes.

Managing modules example: ~
>lua
```lua
 M.ui = {
   statusline = {
     theme = "default",
     separator_style = "default",
     order = { "mode", "f", "git", "%=", "lsp_msg", "%=", "lsp", "cwd", "xyz", "abc" },
     modules = {
       abc = function()
         return "hi"
       end,

       xyz =  "hi",
       f = "%F"
     }
   },
 }
```

<
Above modules field shows how you can add custom modules to the statusline

Note:  The |"%F"| is a stl modifier, check `stl` to know list of modifiers
 - The module can be a string/function
 - |"%="| is a separator, modules before 1st separator will be on the left
        and after the last separator on the right

theme: ~
   |values| = default, vscode, vscode_colored, minimal

separator_style: ~
   |values| = default, round, block, arrow
   Note: the style wont work for vscode themes

Order: ~
  - The order can be found at
    `https://github.com/NvChad/ui/blob/v3.0/lua/nvchad/stl/utils.lua`








M.ui = {
  statusline = {
    theme = "default",
    separator_style = "default",
    order = {
      "mode", "file", "git", -- linke Seite
      "%=",                  -- Mitte trennt
      "position", "encoding", "filetype", "|", -- mittlere Infos
      "%=",                  -- rechte Seite
      "lsp_msg", "diagnostics", "lsp", "cwd",
    },
    modules = {
      -- Zeigt den vollständigen Dateipfad
      file = function()
        return " " .. vim.fn.expand("%:~:.") .. " "
      end,

      -- Git (aus deiner gefixten Version)
      git = function()
        local gitsigns = vim.b.gitsigns_status_dict
        if not gitsigns then return "" end

        local added = gitsigns.added and gitsigns.added > 0 and ("  " .. gitsigns.added) or ""
        local changed = gitsigns.changed and gitsigns.changed > 0 and ("  " .. gitsigns.changed) or ""
        local removed = gitsigns.removed and gitsigns.removed > 0 and ("  " .. gitsigns.removed) or ""
        local branch = gitsigns.head and (" " .. gitsigns.head) or ""

        return " " .. branch .. added .. changed .. removed
      end,

      -- Cursorposition: Ln 23, Col 42
      position = function()
        return string.format(" Ln %d, Col %d ", vim.fn.line("."), vim.fn.col("."))
      end,

      -- Encoding (z. B. UTF-8)
      encoding = function()
        return " " .. (vim.bo.fenc ~= "" and vim.bo.fenc or vim.o.enc) .. " "
      end,

      -- Dateityp (lua, ts, etc.)
      filetype = function()
        return " " .. vim.bo.filetype .. " "
      end,

      -- Trenner
      ["|"] = function()
        return " | "
      end,

      -- LSP-Meldung
      lsp_msg = function()
        local msg = require("nvchad.stl.utils").state.lsp_msg
        return vim.o.columns > 100 and (" " .. msg) or ""
      end,

      -- Diagnostics von null-ls, etc.
      diagnostics = require("nvchad.stl.utils").diagnostics,

      -- LSP aktiv/inaktiv
      lsp = require("nvchad.stl.utils").lsp,

      -- Arbeitsverzeichnis
      cwd = require("nvchad.stl.utils").cwd,
    },
  },
}