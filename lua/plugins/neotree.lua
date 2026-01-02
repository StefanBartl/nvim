---@module 'plugins.neotree'
--- Neo-tree plugin spec that imports centralized keymaps.

local KEYMAPS = require("config.neotree.keymaps")
local BUFFERS = require("config.neotree.keymaps.buffers")
local DOCUMENT_SYMBOLS = require("config.neotree.keymaps.document_symbols")
local FILESYSTEM = require("config.neotree.keymaps.filesystem")
local GIT_STATUS = require("config.neotree.keymaps.git_status")
local TESTS = require("config.neotree.keymaps.tests")
local COMMANDS = require("config.neotree.commands")

return {

  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "MunifTanjim/nui.nvim",

      -- Optional sources
      { "miversen33/netman.nvim", optional = true },
      { "TimCreasman/neo-tree-tests-source.nvim", optional = true },
    },

    lazy = false,

    opts = function()
      -- Detect available sources
      local has_netman = pcall(require, "netman")
      local has_neotest_source = pcall(require, "neo-tree-tests-source")

      -- Build source selector list
      local sources = {
        { source = "filesystem", display_name = "  Files" },
        { source = "buffers", display_name = "  Buffers" },
        { source = "git_status", display_name = " 󰊢 Git" },
        { source = "document_symbols", display_name = "  Symbols" },
      }

      if has_netman then
        sources[#sources + 1] = { source = "netman.ui.neo-tree", display_name = "  Network" }
      end

      if has_neotest_source then
        sources[#sources + 1] = { source = "tests", display_name = "  Tests" }
      end

      return {
        close_if_last_window = false,
        popup_border_style = "rounded",
        sort_case_insensitive = true,

        source_selector = {
          winbar = false,
          statusline = false,
          show_scrolled_off_parent_node = true,
          padding = { left = 1, right = 0 },
          sources = sources,
        },

        event_handlers = {
          {
            event = "neo_tree_buffer_enter",
            handler = function()
              vim.cmd("highlight! Cursor blend=100")
            end,
          },
          {
            event = "neo_tree_buffer_leave",
            handler = function()
              vim.cmd("highlight! Cursor guibg=#5f87af blend=0")
            end,
          },
        },

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
            { "git_status", highlight = "NeoTreeDimText" },
            { "diagnostics" },
            { "clipboard" },
          },
          file = {
            { "indent" },
            { "icon" },
            { "name", use_git_status_colors = true },
            { "git_status", highlight = "NeoTreeDimText" },
            { "diagnostics" },
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
          window = { position = "left", mappings = FILESYSTEM },
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

        buffers = { window = { mappings = BUFFERS } },
        git_status = { window = { mappings = GIT_STATUS } },
        document_symbols = {
          follow_cursor = true,
          window = { mappings = DOCUMENT_SYMBOLS },
        },

        -- tests source configuration
        tests = has_neotest_source and TESTS or nil,

        -- Netman source configuration
        netman = has_netman and {
          window = {
            position = "left",
            mappings = {},
          },
        } or nil,
      }
    end,

    config = function(_, opts)
      require("config.neotree.custom_actions.find_or_grep_menu").attach(opts)
      require("config.neotree.current_hl").attach(opts)
      require("neo-tree").setup(opts)
      require("config.neotree.current_hl").setup({
        colors = {
          file = "green",
          parent = { fg = "darkgreen", underline = false },
        },
      })
      require("config.neotree.cwd_sync").setup({
        debounce_ms = 150,
        keep_focus = true,
        also_set_nvim_cwd = false,
        open_if_closed = false,
        use_project_root = true,
        project_root_fallback_to_bufdir = true,
        force_position_left = true,
      })
      require("config.neotree.open").attach_opener_mappings()
    end,
  },
}
