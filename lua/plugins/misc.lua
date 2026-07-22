---@module 'plugins.misc'

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
      require("config.harpoon.persist_paths").setup({
        target_specs = {
          { vim.fn.stdpath("config"), "lua", "plugins", "personal", "init.lua" },
          { vim.fn.stdpath("config"), "docs", "ROADMAP", "ROADMAP.md" },
          { "$REPOS_DIR", "Notes", "spickzettel", "spickzettel.md" },
        },
      })
      require("config.harpoon.preview").install_alt_number_maps()
      require("config.harpoon.health")
    end,
  },

  {
    "jghauser/mkdir.nvim",
    lazy = true,
  },
})

return plugins.export()
