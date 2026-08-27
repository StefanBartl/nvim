---@module 'plugins.misc'
--- Small plugins with no group of their own: harpoon (+ its optional fzf/
--- telescope deps), mkdir.nvim, and whatever else lands here rather than
--- earning its own file. `plugins.control.mode` lets a repo be disabled
--- centrally instead of `enabled = false` scattered per-spec.

local machine = require("machine")
local plugins = require("plugins.control.mode").new()

-- Repos hier zentral deaktivieren (Basename -> "disabled"), statt weiter unten
-- im jeweiligen Spec `enabled = false` zu setzen.
plugins.modes({
  -- ["mkdir.nvim"] = "disabled",
})

plugins.add({

  -- Harpoon: Efficient file and terminal navigation system
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      -- "ibhagwan/fzf-lua", -- optional, recommended for the <C-h> FZF menu
      -- "nvim-telescope/telescope.nvim", -- optional, not required by the hardening layer
    },
    config = function()
      require("config.harpoon.hardening").setup({
        debounce_ms = 200, -- tweak if remote FS
        autocmd_events = { "BufLeave", "FocusLost" }, -- extend if nötig: "FocusGained", "WinLeave" etc.
      })
      local target_specs = {
        { vim.fn.stdpath("config"), "lua", "plugins", "personal", "init.lua" },
        { vim.fn.stdpath("config"), "docs", "ROADMAP", "ROADMAP.md" },
        { "$REPOS_DIR", "WKDBooks", "Spickzettel", "spickzettel.md" },
        { "$REPOS_DIR", "WKDBooks", "Development", "wkdbook-Lua", "Notes", "LuaNotes.md" },
        {
          "$REPOS_DIR",
          "WKDBooks",
          "Development",
          "wkdbook-Neovim",
          "Referenz_Notes",
          "98_cheatsheets",
          "tastaturkuerzel-konsolidiert.md",
        },
      }

      -- Work-specific Harpoon targets: only exist/matter on the workstation.
      if machine.is("workstation") then
        target_specs = {
          { "$REPOS_DIR", "WKDBook-Tricentis", "Cases", "Workflow", "Workflow.md" },
          {
            "$REPOS_DIR",
            "WKDBook-Tricentis",
            "Cases",
            "Workflow",
            "Templates",
            "FirstResponse_Rick.md",
          },
          {
            "$REPOS_DIR",
            "WKDBook-Tricentis",
            "Cases",
            "Workflow",
            "Templates",
            "SAP_TBox_RequestInfos.md",
          },
          {
            "$REPOS_DIR",
            "WKDBook-Tricentis",
            "Cases",
            "Workflow",
            "Templates",
            "RequestMoreInfo.md",
          },
          { "$REPOS_DIR", "WKDBook-Tricentis", "ToDo-Collection", "SAP_Support_ToDo.md" },
          target_specs[1],
          target_specs[2],
          target_specs[3],
        }
      end

      require("config.harpoon.persist_paths").setup({
        target_specs = target_specs,
      })
      require("config.harpoon.pin_marks").setup()
      require("config.harpoon.usrcmds").setup()
    end,
  },

  {
    "jghauser/mkdir.nvim",
    lazy = true,
  },
})

return plugins.export()
