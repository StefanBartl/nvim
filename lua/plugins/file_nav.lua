---@module 'plugins.file_nav'
--- File navigation tools, including Harpoon for fast file and terminal switching.

---@type LazyPluginSpec[]
return {

  -- Harpoon: Efficient file and terminal navigation system
  {
    "ThePrimeagen/harpoon",
    lazy = false,
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "nvim-lua/plenary.nvim",
    },
    config = function()
      require("harpoon").setup()

      -- Load harpoon extension into telescope
      require("telescope").load_extension("harpoon")

      -- Custom configuration file (if present)
      require("configs.harpoon_config")
    end,
  },

}

