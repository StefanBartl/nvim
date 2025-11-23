---@module 'plugins.neotree'
--- Neo-tree plugin spec that imports centralized keymaps.

local KEYMAPS = require("config.neotree.keymaps")
local BUFFERS = require("config.neotree.keymaps.buffers")
local DOCUMENT_SYMBOLS = require("config.neotree.keymaps.document_symbols")
local FILESYSTEM = require("config.neotree.keymaps.filesystem")
local GIT_STATUS = require("config.neotree.keymaps.git_status")
local COMMANDS = require("config.neotree.commands")

return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = { "MunifTanjim/nui.nvim" },
  lazy = false,
  opts = {
    close_if_last_window = false,
    popup_border_style = "rounded",
    sort_case_insensitive = true,

    source_selector = {
      winbar = false,
      show_scrolled_off_parent_node = true,
      padding = { left = 1, right = 0 },
      sources = {
        { source = "filesystem", display_name = "  Files" },
        { source = "buffers", display_name = "  Buffers" },
        { source = "git_status", display_name = " 󰊢 Git" },
      },
    },

    -- uncomment this if neotree should close after opening a file
    -- event_handlers = {
    --   {
    --     event = "file_opened",
    --     handler = function()
    --       require("neo-tree.command").execute { action = "close" }
    --     end,
    --   },
    -- },

    default_component_config = {
      indent = { with_expanders = false },
      icon = {
        folder_empty = "",
        folder_empty_open = "",
        default = "",
      },
      modified = { symbol = "•" },
      name = {
        trailing_slash = true,
        highlight_opened_files = true,
        use_git_status_colors = false,
      },
      git_status = {
        symbols = {
          added = "A",
          deleted = "D",
          modified = "M",
          renamed = "R",
          untracked = "U",
          ignored = "I",
          unstaged = "",
          staged = "S",
          conflict = "C",
        },
      },
    },

    window = {
      width = 25,
      mappings = KEYMAPS,
    },

    commands = COMMANDS,

    filesystem = {
      bind_to_cwd = true,
      follow_current_file = { enabled = true },
      find_by_full_path_words = true,
      group_empty_dirs = true,
      use_libuv_file_watcher = true,
      window = { mappings = FILESYSTEM },
      filtered_items = {

        -- Everything is visible by default
        visible = true,
        hide_dotfiles = false,
        hide_gitignored = false,

        -- Hide files marked "hidden" by the filesystem (mainly relevant on Windows),
        hide_hidden = false,
        hide_by_pattern = {},
        hide_by_name = {
          ".git",
          ".hg",
          ".svc",
          ".DS_Store",
          "thumbs.db",
          ".sass-cache",
          "node_modules",
          ".pytest_cache",
          ".mypy_cache",
          "__pycache__",
          ".stfolder",
          ".stversions",
        },

        -- Items listed here are *never* shown, even if `visible = true`.
        never_show = {},
        never_show_by_pattern = { "vite.config.js.timestamp-*" },
      },
    },

    buffers = { window = { mappings = BUFFERS } },
    git_status = { window = { mappings = GIT_STATUS } },
    document_symbols = { follow_cursor = true, window = { mappings = DOCUMENT_SYMBOLS } },
  },

  config = function(_, opts)
    require("config.neotree.custom_actions.find_or_grep_menu").attach(opts)
    require("config.neotree.current_hl").attach(opts) -- ① vor setup(): Komponenten-Wrapper injizieren
    require("neo-tree").setup(opts)
    ---@diagnostic disable-next-line
    require("config.neotree.current_hl").setup({ -- ② nach setup(): Autocmds + Highlights aktivieren
      -- enable = true,
      -- debounce = 50,
      -- use_git_status_colors = false,
      colors = {
        -- simple hex
        file = "green",
        -- link to an existing highlight group (keeps your theme semantics)
        -- parent = { link = "Directory" },
        -- or full hl table with styles
        parent = { fg = "darkgreen", underline = false },
        -- or pragmatic name (mapped to hex internally; ok for quick tests)
        -- file = "red",
      },
    })
    ---@diagnostic disable-next-line
    require("config.neotree.cwd_sync").setup({
      debounce_ms = 80,
      keep_focus = true,
      also_set_nvim_cwd = false, -- set to true if global :cd should follow too
      open_if_closed = false, -- set to true to auto-open Neo-tree on first sync
      use_project_root = true,
    })
  end,
}
