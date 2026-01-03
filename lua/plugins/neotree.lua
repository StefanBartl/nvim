---@module 'plugins.neotree'
--- Neo-tree plugin spec that imports centralized keymaps.

local KEYMAPS = require("config.neotree.keymaps")
local BUFFERS = require("config.neotree.keymaps.buffers")
local DOCUMENT_SYMBOLS = require("config.neotree.keymaps.document_symbols")
local FILESYSTEM = require("config.neotree.keymaps.filesystem")
local GIT_STATUS = require("config.neotree.keymaps.git_status")
local TESTS = require("config.neotree.keymaps.tests")
local COMMANDS = require("config.neotree.commands")
local ICONS = require("config.neotree.sources.icons")

return {

  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "MunifTanjim/nui.nvim",

      -- Optional sources
      { "miversen33/netman.nvim", optional = true },
      { "TimCreasman/neo-tree-tests-source.nvim", optional = true },
      { "neo-tree.sources.diagnostics", optional = true },
    },

    lazy = false,

    opts = function()
      local has_netman = pcall(require, "netman")
      local has_neotest_source = pcall(require, "neo-tree-tests-source")
      local has_diagnostics = pcall(require, "neo-tree.sources.diagnostics")

      -- configuration knobs
      local icon_family = "nerd" -- common | nerd | codicons
      local icon_variant = "v1" -- v1 | v2
      local name_length = "long" -- long | short

      local enabled_sources = {
        "filesystem",
        "buffers",
        "git_status",
        "document_symbols",
        "diagnostics",
      }

      ---@type table[]
      local sources = {
        {
          source = "filesystem",
          display_name = ICONS.format(icon_family, icon_variant, "filesystem", name_length),
        },
        {
          source = "buffers",
          display_name = ICONS.format(icon_family, icon_variant, "buffers", name_length),
        },
        {
          source = "git_status",
          display_name = ICONS.format(icon_family, icon_variant, "git_status", name_length),
        },
        {
          source = "document_symbols",
          display_name = ICONS.format(icon_family, icon_variant, "document_symbols", name_length),
        },
      }

      if has_netman then
        sources[#sources + 1] = {
          source = "netman.ui.neo-tree",
          display_name = ICONS.format(icon_family, icon_variant, "netman", name_length),
        }
      end

      if has_neotest_source then
        sources[#sources + 1] = {
          source = "tests",
          display_name = ICONS.format(icon_family, icon_variant, "tests", name_length),
        }
      end

      if has_diagnostics then
        sources[#sources + 1] = {
          source = "diagnostics",
          display_name = ICONS.format(icon_family, icon_variant, "diagnostics", name_length),
        }
      end

      return {
        sources = enabled_sources,
        source_selector = {
          winbar = true,
          statusline = false,
          show_scrolled_off_parent_node = true,
          padding = { left = 1, right = 1 },
          sources = sources,
        },
        close_if_last_window = false,
        popup_border_style = "rounded",
        sort_case_insensitive = true,

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
            has_diagnostics and { "diagnostics" } or nil,
            { "clipboard" },
          },
          file = {
            { "indent" },
            { "icon" },
            { "name", use_git_status_colors = true },
            { "git_status", highlight = "NeoTreeDimText" },
            has_diagnostics and { "diagnostics" } or nil,
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
          client_filters = "first",

          -- Proper renderers for document_symbols
          renderers = {
            root = {
              { "indent" },
              { "icon", default = "C" },
              { "name", zindex = 10 },
            },
            symbol = {
              { "indent", with_expanders = true },
              { "kind_icon", default = "?" },
              {
                "container",
                content = {
                  { "name", zindex = 10 },
                  { "kind_name", zindex = 20, align = "right" },
                },
              },
            },
          },

          -- Document symbols has NO filesystem mappings!
          window = {
            mappings = DOCUMENT_SYMBOLS, -- Only document_symbols mappings
            position = "left",
          },
        },

        diagnostics = has_diagnostics and {
          window = { position = "left", mappings = {} },
          renderers = {
            directory = { { "indent" }, { "icon" }, { "name" } },
            file = { { "indent" }, { "icon" }, { "name" } },
          },
        } or nil,

        -- tests source configuration
        tests = has_neotest_source and vim.tbl_extend("force", TESTS, {
          window = { mappings = TESTS },
        }) or nil,

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
