---@module 'plugins.fuzzy_finder'
--- Fuzzy finding tools based on Telescope, fzf-lua, and optional tabbed UI (search.nvim)

---@type LazyPluginSpec[]
return {

  -- Telescope: Main fuzzy finder with extensions
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "nvim-telescope/telescope-github.nvim",
    },
    cmd = "Telescope",
    opts = function(_, opts)
      opts = opts or {}
      opts.defaults = vim.tbl_deep_extend("force", opts.defaults or {}, {
        sorting_strategy = "ascending",
        layout_config = { prompt_position = "top" },
        mappings = {},
      })
      opts.extensions_list = { "fzf", "gh" }
      return opts
    end,
    config = function(_, opts)
      local telescope = require("telescope")
      telescope.setup(opts)
      for _, ext in ipairs(opts.extensions_list or {}) do
        pcall(telescope.load_extension, ext)
      end
    end,
  },

  {
    "nvim-telescope/telescope-fzf-native.nvim",
    build = (function()
      if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
        -- Windows: use CMake build
        return table.concat({
          "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release",
          "cmake --build build --config Release",
          "cmake --install build --prefix build"
        }, " && ")
      else
        -- POSIX: just use make
        return "make"
      end
    end)(),
  },

  -- search.nvim: Telescope UI
  {
    "FabianWirth/search.nvim",
    dependencies = { "nvim-telescope/telescope.nvim" },
    config = function()
      local search   = require("search")
      local builtin  = require("telescope.builtin")
      local all_drives = require("utils.search_all_drives").build_tabs(builtin)  -- <-- NEW

      search.setup({
        mappings = { next = "<Tab>", prev = "<S-Tab>" },

        append_tabs = {
          {
            "Commits",
            builtin.git_commits,
            available = function() return vim.fn.isdirectory(".git") == 1 end,
          },
        },

        tabs = vim.list_extend({
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
          { name = "All Files", tele_func = builtin.find_files, tele_opts = { no_ignore = true, hidden = true } },
          { name = "Grep",      tele_func = builtin.live_grep },
          { name = "Buffers",   tele_func = builtin.buffers },
        }, all_drives),

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
    lazy = true ,
  },

}
