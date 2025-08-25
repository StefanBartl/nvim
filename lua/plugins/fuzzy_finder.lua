---@module 'plugins.fuzzy_finder'
--- Fuzzy finding tools based on Telescope, fzf-lua, and optional tabbed UI (search.nvim)

---@type LazyPluginSpec[]
return {

  -- Telescope: Main fuzzy finder with extensions (history wrapped in a single block)
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "nvim-telescope/telescope-github.nvim",

      -- === HISTORY BLOCK (dependencies, optional but recommended) ===
      -- SQLite-backed prompt history (smart, per-cwd/picker aware).
      -- Remove these two lines if you prefer a plain text file backend.
      { "nvim-telescope/telescope-smart-history.nvim", lazy = true },
      { "kkharji/sqlite.lua", lazy = true },
      -- === END HISTORY BLOCK =======================================
    },
    cmd = "Telescope",
    opts = function(_, opts)
      opts = opts or {}
      opts.defaults = opts.defaults or {}

      -- === HISTORY BLOCK (begin) ===================================
      ---@class TelescopeHistoryBlock
      ---@field backend '"sqlite"'|'"file"'   -- Switch storage backend
      ---@field dir string                    -- Base directory for history files
      ---@field path string                   -- Concrete file path (resolved by ensure())
      ---@field limit integer                 -- Max history items
      ---@field extensions string[]           -- Extensions to load for this backend
      local HISTORY = (function()
        ---@class TelescopeHistoryBlock
        local H = {
          backend = "sqlite", -- "sqlite" or "file"
          dir = vim.fn.stdpath "data" .. "/databases",
          path = "",
          limit = 3000,
          extensions = {}, -- filled by ensure()
        }

        ---Ensure directories exist and compute final path per backend.
        ---@return string path
        function H.ensure()
          if H.backend == "sqlite" then
            -- Use XDG-like "databases" dir for the SQLite file
            if vim.fn.isdirectory(H.dir) == 0 then
              vim.fn.mkdir(H.dir, "p") -- no mode arg to keep LuaLS happy
            end
            H.path = H.dir .. "/telescope_history.sqlite3"
            H.extensions = { "smart_history" } -- load this extension for SQLite
          else
            -- Plain text file under picker-history/
            local pdir = vim.fn.stdpath "data" .. "/picker-history"
            if vim.fn.isdirectory(pdir) == 0 then
              vim.fn.mkdir(pdir, "p")
            end
            H.path = pdir .. "/_global.txt"
            H.extensions = {} -- no extra extension needed
          end
          return H.path
        end

        ---Defaults table to merge into Telescope's `defaults`.
        ---@return table
        function H.defaults()
          local actions = require "telescope.actions"
          return {
            -- Core persistent prompt history (Telescope built-in)
            history = {
              path = H.ensure(),
              limit = H.limit,
            },
            -- Insert-mode keymaps for cycling prompt history
            mappings = {
              i = {
                ["<C-p>"] = actions.cycle_history_prev,
                ["<C-n>"] = actions.cycle_history_next,
              },
            },
          }
        end

        return H
      end)()
      -- === HISTORY BLOCK (end) =====================================

      -- Your original defaults (kept) + history block merged in
      opts.defaults = vim.tbl_deep_extend("force", opts.defaults, {
        sorting_strategy = "ascending",
        layout_config = { prompt_position = "top" },
      })
      opts.defaults = vim.tbl_deep_extend("force", opts.defaults, HISTORY.defaults())

      -- Extensions to load; append history-specific ones from the block
      opts.extensions_list = { "fzf", "gh" }
      vim.list_extend(opts.extensions_list, HISTORY.extensions)

      return opts
    end,
    config = function(_, opts)
      local telescope = require "telescope"
      telescope.setup(opts)
      for _, ext in ipairs(opts.extensions_list or {}) do
        pcall(telescope.load_extension, ext)
      end
    end,
  },

  {
    "nvim-telescope/telescope-fzf-native.nvim",
    build = (function()
      if vim.fn.has "win32" == 1 or vim.fn.has "win64" == 1 then
        -- Windows: use CMake build
        return table.concat({
          "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release",
          "cmake --build build --config Release",
          "cmake --install build --prefix build",
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
      local search = require "search"
      local builtin = require "telescope.builtin"
      local all_drives = require("utils.search_all_drives").build_tabs(builtin) -- <-- NEW

      search.setup {
        mappings = { next = "<Tab>", prev = "<S-Tab>" },

        append_tabs = {
          {
            "Commits",
            builtin.git_commits,
            available = function()
              return vim.fn.isdirectory ".git" == 1
            end,
          },
        },

        tabs = vim.list_extend({
          {
            "Files",
            function(opts)
              opts = opts or {}
              if vim.fn.isdirectory ".git" == 1 then
                builtin.git_files(opts)
              else
                builtin.find_files(opts)
              end
            end,
          },
          { name = "All Files", tele_func = builtin.find_files, tele_opts = { no_ignore = true, hidden = true } },
          { name = "Grep", tele_func = builtin.live_grep },
          { name = "Buffers", tele_func = builtin.buffers },
        }, all_drives),

        collections = {
          git = {
            initial_tab = 1,
            tabs = {
              { name = "Branches", tele_func = builtin.git_branches },
              { name = "Commits", tele_func = builtin.git_commits },
              { name = "Stashes", tele_func = builtin.git_stash },
            },
          },
        },
      }
    end,
  },

  -- fzf-lua: Alternative fuzzy finder based on fzf
  {
    "ibhagwan/fzf-lua",
    lazy = true,
    opts = {
      keymap = {
        fzf = {
          ["ctrl-p"] = "next-history",
          ["ctrl-n"] = "prev-history",
        },
      },
      fzf_opts = {
        ["--history"] = vim.fn.stdpath "data" .. "/fzf-history",
      },
    },
  },
}
