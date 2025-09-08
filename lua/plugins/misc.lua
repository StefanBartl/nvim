---@module 'plugins.misc'

---@type LazyPluginSpec[]
return {

  -- Harpoon: Efficient file and terminal navigation system
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

  {
		"axieax/urlview.nvim",
		lazy = true,
		cmd = { "UrlView" },
		config = function()
			require("config.urlview.open_in_browser_integration").setup()
		end,
	},

  {
    "jghauser/mkdir.nvim",
    lazy = true,
  },
}
