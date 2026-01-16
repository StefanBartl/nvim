---@module 'plugins.neotree'
--- Neo-tree plugin spec that imports centralized keymaps.

local KEYMAPS = require("config.neotree.keymaps")
local BUFFERS = require("config.neotree.keymaps.buffers")
local DOCUMENT_SYMBOLS = require("config.neotree.keymaps.document_symbols")
local FILESYSTEM = require("config.neotree.keymaps.filesystem")
local GIT_STATUS = require("config.neotree.keymaps.git_status")
local TESTS = require("config.neotree.keymaps.tests")
local DIAGNOSTICS = require("config.neotree.keymaps.diagnostics")
local COMMANDS = require("config.neotree.commands")
-- local ICONS = require("config.neotree.sources.icons")
-- local neotest_neotree = require("config.neotest.neotree")

return {

  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "MunifTanjim/nui.nvim",

      -- Optional sources
      { "miversen33/netman.nvim" },
      { "TimCreasman/neo-tree-tests-source.nvim" },
      { "mrbjarksen/neo-tree-diagnostics.nvim" },
    },

    -- CRITICAL: lazy = true ermöglicht lazy source loading
    lazy = true,
    -- Nur filesystem beim Start laden
    event = "VeryLazy",
    opts = function()
      local has_netman = pcall(require, "netman")
      local has_neotest_source = pcall(require, "neo-tree-tests-source")
      local has_diagnostics = pcall(require, "neo-tree.sources.diagnostics")

      local registry = require("config.neotree.sources.registry")

      -- Register sources (NICHT laden!)
      registry.register("filesystem", function()
        return require("neo-tree.sources.filesystem")
      end)

      registry.register("buffers", function()
        return require("neo-tree.sources.buffers")
      end)

      registry.register("git_status", function()
        return require("neo-tree.sources.git_status")
      end)

      registry.register("document_symbols", function()
        return require("neo-tree.sources.document_symbols")
      end)

      -- -- Build sources for source_selector
      -- ---@type table[]
      -- local sources = {
      -- {
      -- source = "filesystem",
      -- display_name = ICONS.format(icon_family, icon_variant, "filesystem", name_length),
      -- },
      -- {
      -- source = "buffers",
      -- display_name = ICONS.format(icon_family, icon_variant, "buffers", name_length),
      -- },
      -- {
      -- source = "git_status",
      -- display_name = ICONS.format(icon_family, icon_variant, "git_status", name_length),
      -- },
      -- {
      -- source = "document_symbols",
      -- display_name = ICONS.format(icon_family, icon_variant, "document_symbols", name_length),
      -- },
      -- }

      -- if has_netman then
      -- sources[#sources + 1] = {
      -- source = "netman.ui.neo-tree",
      -- display_name = ICONS.format(icon_family, icon_variant, "netman", name_length),
      -- }
      -- end

      -- if has_neotest_source then
      -- sources[#sources + 1] = {
      -- source = "tests",
      -- display_name = ICONS.format(icon_family, icon_variant, "tests", name_length),
      -- }
      -- end

      -- if has_diagnostics then
      -- sources[#sources + 1] = {
      -- source = "diagnostics",
      -- display_name = ICONS.format(icon_family, icon_variant, "diagnostics", name_length),
      -- }
      -- end

      return {
        -- NUR filesystem initial laden
        sources = { "filesystem" },

        source_selector = {
          winbar = false, -- DISABLED: Icons würden alle sources laden
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
            { "git_status", highlight = "NeoTreeDimText" },
            diagnostics = has_diagnostics and {
              symbols = {
                hint = "",
                info = "",
                warn = "",
                error = "",
              },
              highlights = {
                hint = "DiagnosticSignHint",
                info = "DiagnosticSignInfo",
                warn = "DiagnosticSignWarn",
                error = "DiagnosticSignError",
              },
            } or nil,
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
          window = { position = "right", mappings = FILESYSTEM }, -- FIX: positions: require("config.neotree").get_default_position() klann ich hier noch nicht aufrufen? Ist dies notwendig? Oder überschreibe ich in der setup() nicht effektiv sowieso diese einstellung?
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
            position = "right",
          },
        },

        diagnostics = has_diagnostics
            and {
              auto_preview = {
                enabled = false,
                preview_config = {},
                event = "neo_tree_buffer_enter",
              },
              bind_to_cwd = true,
              diag_sort_function = "severity",
              follow_current_file = {
                enabled = true,
                always_focus_file = false,
              },
              group_dirs_and_files = true,
              group_empty_dirs = true,
              show_unloaded = true, -- Zeigt auch Diagnostics von nicht geladenen Buffern
              refresh = {
                delay = 100,
                event = "vim_diagnostic_changed", -- Aktualisiert bei Änderungen
                max_items = 10000,
              },
              window = {
                position = "right",
                mappings = DIAGNOSTICS,
              },
            }
          or nil,

        -- tests source configuration
        tests = has_neotest_source and vim.tbl_extend("force", TESTS, {
          window = { mappings = TESTS },
        }) or nil,

        -- Netman source configuration
        netman = has_netman and {
          window = {
            position = "right",
            mappings = {},
          },
        } or nil,
      }
    end,

    config = function(_, opts)
      require("config.neotree.actions.find_or_grep_menu").attach(opts)
      require("config.neotree.current_hl").attach(opts)
      require("neo-tree").setup(opts)
      require("config.neotree").setup({
        trash = {
          debug = true,
          auto_close_buffers = true,
          confirm_dangerous = true,
        },
        window_debug = true,
        current_hl = {
          colors = {
            file = "cyan",
            parent = { fg = "blue" },
          },
        },
      })

      -- Filesystem sofort laden
      local registry = require("config.neotree.sources.registry")
      registry.load("filesystem")

      require("neo-tree").setup(opts)

      -- Keymap für Source-Switcher
      vim.keymap.set("n", "<leader>ns", function()
        require("config.neotree.sources.switcher").show_picker()
      end, { desc = "[Neo-tree] Switch Source" })
    end,
  },
}
