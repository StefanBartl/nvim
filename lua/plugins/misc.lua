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
          { "$REPOS_DIR", "Notes", "spickzettel", "spickzettel.md" },
          { vim.fn.stdpath("config"), "docs", "ROADMAP", "ROADMAP.md" },
          { "$REPOS_DIR", "Notes", "MyNotes", "Notes.md" },
          { "$REPOS_DIR", "Notes", "MyNotes", "Checklists", "Lua", "Arch&Coding-Regeln.md" },
        },
      })
      require("config.harpoon.preview").install_alt_number_maps()
      require("config.harpoon.health")
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
