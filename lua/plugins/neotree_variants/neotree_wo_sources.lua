---@module 'plugins.neotree'

local KEYMAPS = require("config.neotree.keymaps")
local FILESYSTEM = require("config.neotree.keymaps.filesystem")
local COMMANDS = require("config.neotree.commands")

return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "MunifTanjim/nui.nvim",
      { "miversen33/netman.nvim", lazy = true },
      { "TimCreasman/neo-tree-tests-source.nvim", lazy = true },
      { "mrbjarksen/neo-tree-diagnostics.nvim", lazy = true },
    },

    lazy = false,

    opts = function()
      return {
        sources = { "filesystem" },
        source_selector = {
          winbar = false,
          statusline = false,
        },

        close_if_last_window = false,
        popup_border_style = "rounded",
        sort_case_insensitive = true,
        event_handlers = require("config.neotree.event_handlers"),

        default_component_config = {
          indent = { with_expanders = false },
          icon = {
            folder_empty = "",
            folder_empty_open = "",
            default = "",
            folder_closed = "",
            folder_open = "",
            highlight = "NeoTreeFileIcon",
          },
          modified = {
            symbol = "[+]",
            highlight = "NeoTreeModified",
          },
          name = {
            trailing_slash = true,
            use_git_status_colors = false,
            highlight_opened_files = true,
            highlight = "NeoTreeFileName",
          },
          git_status = {
            symbols = {
              added = "A",
              deleted = "D",
              modified = "M",
              renamed = "R",
              unstaged = "✗",
              staged = "✓",
              untracked = "★",
              ignored = "◌",
              conflict = "C",
            },
          },
        },

        renderers = {
          directory = {
            { "indent" },
            { "icon" },
            { "current_filter" },
            { "name" },
            { "clipboard" },
          },
          file = {
            { "indent" },
            { "icon" },
            { "name", use_git_status_colors = true },
            { "git_status", highlight = "NeoTreeDimText" },
            {
              function(_, node, state)
                local marks = state.explicitly_marked_node_ids or {}
                local node_id = node:get_id()
                if marks[node_id] then
                  return {
                    text = " ✓",
                    highlight = "NeoTreeGitStaged",
                  }
                end
                return {}
              end,
            },
            { "clipboard" },
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
          window = {
            position = require("config.neotree").get_default_position(),
            mappings = FILESYSTEM,
          },
          filtered_items = {
            visible = true,
            hide_dotfiles = false,
            hide_gitignored = false,
            hide_hidden = false,
            hide_by_pattern = {},
            hide_by_name = require("lib.fs.ignore.list").as_neotree_names(),
            never_show = {},
            never_show_by_pattern = {},
          },
        },
      }
    end,

    config = function(_, opts)
      require("config.neotree.actions.find_or_grep_menu").attach(opts)
      require("config.neotree.current_hl").attach(opts)
      require("neo-tree").setup(opts)
      require("config.neotree").setup({
        debug = true,
        busy_guard = false,
        default_position = "right",
        restore_last_position = false,
        window_debug = true,
        trash = {
          debug = false,
          auto_close_buffers = true,
          create_backups = true,
          use_safety_system = true,
          confirm_dangerous = true,
          use_dry_run = false,
        },
        current_hl = {
          colors = {
            file = "green",
            parent = { fg = "darkgreen", underline = false },
          },
        },
        cwd_sync = false, -- WATCH: für dev-phase deatkiviert {
        -- debounce_ms = 150,
        -- keep_focus = true,
        -- also_set_nvim_cwd = false,
        -- open_if_closed = false,
        -- use_project_root = true,
        -- project_root_fallback_to_bufdir = true,
        -- },
      })
    end,
  },
}
