---@module 'plugins.neotree'
--- Neo-tree plugin spec that imports centralized keymaps.

local KM = require "config.neotree.keymaps"

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
      width = 30,
      mappings = KM.window(),
				position = "left",
			},

		commands = KM.commands(),

    filesystem = {
      bind_to_cwd = false,
      follow_current_file = { enabled = true },
      find_by_full_path_words = true,
      group_empty_dirs = true,
      use_libuv_file_watcher = true,
      window = { mappings = KM.filesystem() },
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

    buffers = { window = { mappings = KM.buffers() } },
    git_status = { window = { mappings = KM.git_status() } },
    document_symbols = { follow_cursor = true, window = { mappings = KM.document_symbols() } },
  },

  config = function(_, opts)
    require("config.neotree.usr_picker").attach(opts)
    require("neo-tree").setup(opts)
    require("config.neotree.keymaps").setup_autocmds()
  end,
}
