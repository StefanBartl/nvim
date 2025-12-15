---@module 'plugins.telescope'
---@brief Telescope plugin configuration with modular history backend support.

local files_path_shorten = require("lib.filesystem.path_shorten")

--- Computes effective maximum path length based on window dimensions
---@param picker_opts table Picker-specific options from Telescope
---@param default_len integer Default length if window width cannot be determined
---@return integer max_len Maximum display length for paths
---@private
local function adapt_max_len(picker_opts, default_len)
  if type(picker_opts) == "table" and type(picker_opts.winwidth) == "number" then
    return math.max(10, picker_opts.winwidth - 10)
  end
  return default_len or 60
end

return {
  ------------------------------------------------------------------------------
  -- Telescope core
  ------------------------------------------------------------------------------
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",

      -- Optional SQLite backend (only loaded if actually usable)
      {
        "kkharji/sqlite.lua",
        cond = function()
          local ok = pcall(require, "sqlite")
          return ok
        end,
      },
      {
        "nvim-telescope/telescope-smart-history.nvim",
        cond = function()
          local ok_sqlite = pcall(require, "sqlite")
          local ok_ext = pcall(require, "telescope-smart-history")
          return ok_sqlite and ok_ext
        end,
      },

      -- Optional GitHub extension
      { "nvim-telescope/telescope-github.nvim", lazy = true },
    },

    opts = function(_, opts)
      opts = opts or {}

      -- Initialize history backend (SQLite or file-based fallback)
      local history = require("config.telescope.history")
      local history_config = history.setup()

      local actions = require("telescope.actions")

      -- Configure defaults
      opts.defaults = vim.tbl_deep_extend("force", opts.defaults or {}, {
        -- Path display with intelligent shortening
        path_display = function(picker_opts, path)
          local max_len = adapt_max_len(picker_opts, 60)
          return files_path_shorten(path, max_len)
        end,

        file_ignore_patterns = {
          "node_modules",
          "package%.lock.json",
          "yarn.lock",
          "pnpm%-lock.yaml",
          "dist",
          "build",
          "out",
          "target",
          "bin",
          "obj",
          "%.git",
          "%.github",
          ".vscode",
          ".idea",
          "__pycache__",
          "%.class",
          "%.pyc",
          "%.log",
          "%.tmp",
          "%.cache",
        },

        -- History backend configuration (empty if unavailable)
        history = history_config,

        sorting_strategy = "ascending",
        layout_config = { prompt_position = "top" },

        -- History navigation mappings (only if backend available)
        mappings = history.is_available() and {
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
        } or {
          -- Fallback mappings without history
          i = {
            ["<PageUp>"] = actions.preview_scrolling_up,
            ["<PageDown>"] = actions.preview_scrolling_down,
          },
          n = {
            ["<PageUp>"] = actions.preview_scrolling_up,
            ["<PageDown>"] = actions.preview_scrolling_down,
          },
        },
      })

      -- Configure extensions
      opts.extensions = vim.tbl_deep_extend("force", opts.extensions or {}, {
        file_browser = {
          path = "%:p:h",
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
      })

      -- Merge backend-specific extension config
      local ext_config = history.get_extension_config()
      if ext_config then
        opts.extensions = vim.tbl_deep_extend("force", opts.extensions, ext_config)
      end

      -- Base extensions (always loaded)
      local extensions = { "fzf" }

      -- Add history extension if available
      vim.list_extend(extensions, history.get_extensions())

      opts.extensions_list = extensions

      return opts
    end,

    config = function(_, opts)
      local telescope = require("telescope")
      telescope.setup(opts)

      -- Load extensions safely
      for _, ext in ipairs(opts.extensions_list or {}) do
        local ok, err = pcall(telescope.load_extension, ext)
        if not ok then
          vim.notify(
            string.format("Failed to load telescope extension '%s': %s", ext, err),
            vim.log.levels.WARN
          )
        end
      end

      -- Set highlight for selection
      vim.api.nvim_set_hl(0, "TelescopeSelection", {
        fg = "#ffffff",
        bg = "#1abc9c",
        bold = true,
        ctermfg = 15,
        ctermbg = 24,
      })
    end,
  },

  ------------------------------------------------------------------------------
  -- fzf-native: compiled sorter
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
  -- search.nvim (Tabbed UI wrapper)
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
      if not (ok1 and ok2) then
        return
      end

      search.setup({
        mappings = { next = "<Tab>", prev = "<S-Tab>" },
        tabs = {
          {
            "Files",
            function(tab_opts)
              tab_opts = tab_opts or {}
              if vim.fn.isdirectory(".git") == 1 then
                builtin.git_files(tab_opts)
              else
                builtin.find_files(tab_opts)
              end
            end,
          },
          {
            name = "All Files",
            tele_func = builtin.find_files,
            tele_opts = { no_ignore = true, hidden = true },
          },
          { name = "Grep", tele_func = builtin.live_grep },
          { name = "Buffers", tele_func = builtin.buffers },
        },
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
      })
    end,
  },
}
