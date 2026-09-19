---@module 'plugins.misc'
--- Small plugins with no group of their own: harpoon (+ its optional fzf/
--- telescope deps) and whatever else lands here rather than earning its own
--- file. `plugins.control.mode` lets a repo be disabled centrally instead of
--- `enabled = false` scattered per-spec.

local plugins = require("plugins.control.mode").new()

-- Disable repos centrally here (basename -> "disabled"), instead of setting
-- `enabled = false` in each individual spec below.
plugins.modes({})

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
        autocmd_events = { "BufLeave", "FocusLost" }, -- extend if needed: "FocusGained", "WinLeave" etc.
      })
      -- The default paths live in config.marks.defaults since 2026-09-19,
      -- shared with sessions.nvim's mark list (plugins/personal/init.lua),
      -- which runs in parallel to harpoon until the switch is decided.
      require("config.harpoon.persist_paths").setup({
        target_specs = require("config.marks.defaults"),
      })
      require("config.harpoon.pin_marks").setup()
      require("config.harpoon.usrcmds").setup()
    end,
  },
})

return plugins.export()
