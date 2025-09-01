---@module 'plugins.misc'

---@type LazyPluginSpec[]
return {

  -- Harpoon: Efficient file and terminal navigation system
  -- plugins/misc.lua
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim", -- optional
    },
    config = function()
      local harpoon = require "harpoon"
      ---@diagnostic disable-next-line: redundant-parameter
      pcall(function()
        harpoon:setup {}
      end)

      require("config.harpoon") -- set file presets
    end,
  },

  -- https://github.com/axieax/urlview.nvim
  { "axieax/urlview.nvim", lazy = true },

  -- https://github.com/jghauser/mkdir.nvim
  {
    "jghauser/mkdir.nvim",
    lazy = true,
  },

  {
    "NStefan002/screenkey.nvim",
		cmd = "Screenkey",
    lazy = true,
    version = "*",
  },

}
