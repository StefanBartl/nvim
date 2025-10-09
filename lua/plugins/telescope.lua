---@module 'plugins.telescope'

---@return boolean
local function has_sqlite()
  -- Prefer hard check: only true if the Lua module is loadable (shared lib present)
  local ok = pcall(require, "sqlite")
  return ok
end

return {

  ------------------------------------------------------------------------------
  -- Telescope core
  ------------------------------------------------------------------------------
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope", -- ensures lazy load on :Telescope
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter", -- not loaded at startup; only when telescope loads

      -- Optional: smart_history (only if sqlite is really available)
      {
        "kkharji/sqlite.lua",
        cond = has_sqlite,
      },
      {
        "nvim-telescope/telescope-smart-history.nvim",
        cond = has_sqlite,
      },

      -- Optional GH extension: do not auto-load to avoid extra cost
      { "nvim-telescope/telescope-github.nvim", lazy = true },
    },

    opts = function(_, opts)
      opts = opts or {}

      -- History backend: prefer sqlite smart_history if available, else text fallback
      local HISTORY = {
        limit = 250, ---@type integer
        path = nil   ---@type string|nil
      }

      local using_sqlite = has_sqlite()
      if using_sqlite then
        local dir = vim.fn.stdpath("state") .. "/telescope"
        if vim.fn.isdirectory(dir) == 0 then vim.fn.mkdir(dir, "p") end
        HISTORY.path = dir .. "/history.sqlite3"
      else
        local dir = vim.fn.stdpath("data") .. "/picker-history"
        if vim.fn.isdirectory(dir) == 0 then vim.fn.mkdir(dir, "p") end
        HISTORY.path = dir .. "/_global.txt"
      end

      -- Defaults: small but effective perf tweaks (ascending + prompt on top)
      local actions = require("telescope.actions")
      opts.defaults = vim.tbl_deep_extend("force", opts.defaults or {}, {
        history = { path = HISTORY.path, limit = HISTORY.limit },
        sorting_strategy = "ascending",
        layout_config = { prompt_position = "top" },
        mappings = {
          i = {
            ["<C-p>"] = actions.cycle_history_prev,
            ["<C-n>"] = actions.cycle_history_next,
            ["<PageUp>"] = actions.preview_scrolling_up,
            ["<PageDown>"] = actions.preview_scrolling_down,
          },
          n = {
            ["<PageUp>"] = actions.preview_scrolling_up,
            ["<PageDown>"] = actions.preview_scrolling_down,
          },
        },
      })

      -- Configure extensions in one place to avoid multiple telescope.setup() calls
      opts.extensions = vim.tbl_deep_extend("force", opts.extensions or {}, {
        file_browser = {
          path = "%:p:h",    -- start at current file's directory
          cwd_to_path = true,
          select_buffer = true,
          hidden = true,
          respect_gitignore = false,
          follow_symlinks = true,
          display_stat = { date = true, size = true, mode = false },
          use_fd = true,
          git_status = true,
          prompt_path = true,
        },

        smart_history = using_sqlite and { limit = HISTORY.limit } or nil,
      })

      -- Choose which extensions to load when Telescope initializes
      ---@type string[]
      local exts = { "fzf" }
      if using_sqlite then table.insert(exts, "smart_history") end
      opts.extensions_list = exts

      return opts
    end,

    -- One clean setup() and extension loading
    config = function(_, opts)
      local telescope = require("telescope")
      telescope.setup(opts)
      for _, ext in ipairs(opts.extensions_list or {}) do
        pcall(telescope.load_extension, ext)
      end
    end,
  },

  ------------------------------------------------------------------------------
  -- fzf-native: compiled sorter (loaded only when telescope loads its extension)
  ------------------------------------------------------------------------------
  {
    "nvim-telescope/telescope-fzf-native.nvim",
    build = (function()
      if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
        return table.concat({
          "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release",
          "cmake --build build --config Release",
          "cmake --install build --prefix build",
        }, " && ")
      else
        return "make"
      end
    end)(),
    lazy = true,
  },

  ------------------------------------------------------------------------------
  -- Telescope File Browser extension
  ------------------------------------------------------------------------------
  {
    "nvim-telescope/telescope-file-browser.nvim",
    dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
    keys = {
      {
        "<leader>,",
        function()
          local ok, telescope = pcall(require, "telescope")
          if not ok then
            vim.notify("telescope.nvim not available", vim.log.levels.WARN)
            return
          end
          pcall(telescope.load_extension, "file_browser")
          telescope.extensions.file_browser.file_browser()
        end,
        desc = "File Browser (at current file)",
      },
      {
        "<leader>.",
        function()
          local ok, telescope = pcall(require, "telescope")
          if not ok then
            vim.notify("telescope.nvim not available", vim.log.levels.WARN)
            return
          end
          pcall(telescope.load_extension, "file_browser")
          telescope.extensions.file_browser.file_browser({ path = vim.loop.cwd() })
        end,
        desc = "File Browser (at CWD)",
      },
    },
    lazy = true,
  },

  ------------------------------------------------------------------------------
  -- search.nvim (Tabbed UI wrapper around Telescope)
  ------------------------------------------------------------------------------
  {
    "FabianWirth/search.nvim",
    dependencies = { "nvim-telescope/telescope.nvim" },
    keys = {
      {
        "<leader>s",
        function()
          require("search").open()
        end,
        desc = "Search (tabbed UI)",
      },
    },
    config = function()
      local ok1, search = pcall(require, "search")
      local ok2, builtin = pcall(require, "telescope.builtin")
      if not (ok1 and ok2) then return end

      search.setup({
        mappings = { next = "<Tab>", prev = "<S-Tab>" },
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
          { name = "All Files", tele_func = builtin.find_files, tele_opts = { no_ignore = true, hidden = true } },
          { name = "Grep",      tele_func = builtin.live_grep },
          { name = "Buffers",   tele_func = builtin.buffers },
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
}
