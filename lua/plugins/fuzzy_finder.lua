---@module 'plugins.fuzzy_finder'
--- Fuzzy finding tools based on Telescope, fzf-lua, and optional tabbed UI (search.nvim)

---@type LazyPluginSpec[]
return {

  -- Telescope: Main fuzzy finder with extensions
  {
    "nvim-telescope/telescope.nvim",
    lazy = false,
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope-github.nvim",
    },
    cmd = "Telescope",
    config = function(_, opts)
      -- Load cached telescope highlights (if present)
      dofile(vim.g.base46_cache .. "telescope")

      local telescope = require("telescope")
      telescope.setup(opts)

      -- Load extensions declared in `opts.extensions_list`
      for _, ext in ipairs(opts.extensions_list or {}) do
        telescope.load_extension(ext)
      end
    end,
  },

  -- Search.nvim: Tab-based UI wrapper for Telescope
  {
    "FabianWirth/search.nvim",
    dependencies = { "nvim-telescope/telescope.nvim" },
    config = function()
      local builtin = require("telescope.builtin")

      require("search").setup({
        mappings = {
          next = "<Tab>",
          prev = "<C-p>",
        },
        append_tabs = {
          {
            "Commits",
            builtin.git_commits,
            available = function()
              return vim.fn.isdirectory(".git") == 1
            end,
          },
        },
        tabs = {
          {
            "Files",
            function(opts)
              opts = opts or {}
              if vim.fn.isdirectory(".git") == 1 then
                builtin.git_files(opts)
              else
                builtin.find_files(opts)
              end
            end,
          },
          {
            name = "All Files",
            tele_func = builtin.find_files,
            tele_opts = { no_ignore = true, hidden = true },
          },
          {
            name = "Grep",
            tele_func = builtin.live_grep,
          },
          {
            name = "Buffers",
            tele_func = builtin.buffers,
          },
        },
        collections = {
          git = {
            initial_tab = 1,
            tabs = {
              { name = "Branches", tele_func = builtin.git_branches },
              { name = "Commits",  tele_func = builtin.git_commits },
              { name = "Stashes",  tele_func = builtin.git_stash },
            },
          },
        },
      })
    end,
  },

  -- fzf-lua: Alternative fuzzy finder based on fzf
  {
    "ibhagwan/fzf-lua",
    lazy = false,
  },

}
