---@module 'plugins.neotree'
--- neo-tree.nvim's lazy.nvim spec: sources (filesystem/git_status/
--- diagnostics/tests via neo-tree-tests-source.nvim), and keymaps
--- assembled from config.neotree.keymaps.* per source.

local KEYMAPS = require("config.neotree.keymaps")
local NEOTEST = require("config.neotest.neotree")
local BUFFERS = require("config.neotree.keymaps.buffers")
local DOCUMENT_SYMBOLS = require("config.neotree.keymaps.document_symbols")
local FILESYSTEM = require("config.neotree.keymaps.filesystem")
local GIT_STATUS = require("config.neotree.keymaps.git_status")
local DIAGNOSTICS = require("config.neotree.keymaps.diagnostics")
local ICONS = require("config.neotree.sources.icons")

return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    -- Loaded on demand, not at startup, and that is worth more than it looks:
    -- neo-tree's own load cost is ~27ms, but `dependencies` drags neotest and
    -- its eight adapters, nvim-treesitter, nvim-web-devicons, nui, plenary,
    -- vim-test and FixCursorHold in with it. Eager, that chain was the single
    -- largest item in startup -- 44 plugins loaded and ~1300ms; lazy it is 29
    -- and ~1050ms, measured over seven runs each.
    --
    -- The dependency on neotest stays. Dropping it instead was tried first and
    -- is a regression: the tests source builds its items through a neotest
    -- *consumer* that has to be registered before the source runs, so without
    -- it `:Neotree tests` dies on a nil consumer. Deferring the whole group
    -- keeps the ordering intact -- lazy loads dependencies with the parent.
    cmd = "Neotree",
    -- `lazy = false` is the usual way to keep `nvim <dir>` opening the tree
    -- instead of netrw. This does the same thing without paying for it on
    -- every other startup: the only case that needs neo-tree before a command
    -- or a keymap is a directory argument, so check for exactly that.
    init = function()
      if vim.fn.argc(-1) == 1 then
        -- Bound and checked: `argv(0)` answers the one argument as a string,
        -- while the `string[]` half of its declared type belongs to the
        -- index-less form (`argv()` = the whole list).
        local arg = vim.fn.argv(0)
        local stat = type(arg) == "string" and (vim.uv or vim.loop).fs_stat(arg)
        if stat and stat.type == "directory" then
          require("neo-tree")
        end
      end
    end,
    dependencies = {
      "MunifTanjim/nui.nvim",
      "TimCreasman/neo-tree-tests-source.nvim",
      "nvim-neotest/neotest",
      "mrbjarksen/neo-tree-diagnostics.nvim",
    },
    opts = function()
      local enabled_sources = {
        "filesystem",
        "buffers",
        "git_status",
        "document_symbols",
        "diagnostics",
        "tests",
      }

      -- Configuration knobs
      local icon_family = "nerd" -- common | nerd | codicons
      local icon_variant = "v1" -- v1 | v2
      local name_length = "long" -- long | short

      -- Build sources for source_selector
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
        {
          source = "diagnostics",
          display_name = ICONS.format(icon_family, icon_variant, "diagnostics", name_length),
        },
        {
          source = "tests",
          display_name = ICONS.format(icon_family, icon_variant, "tests", name_length),
        },
      }

      -- config.neotree.commands (custom_add/telescope_*/markdown_links/diff/mark)
      -- were removed: filetree.nvim owns those and none were key-bound here.
      -- Only neotest's commands remain in the registry.
      local ALL_COMMANDS = NEOTEST.commands()

      return {
        sources = enabled_sources,
        source_selector = {
          winbar = true,
          statusline = false,
          sources = sources,
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
            {
              "diagnostics",
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
            },
            { "clipboard" },
          },
          file = {
            { "indent" },
            { "icon" },
            { "name", use_git_status_colors = true },
            { "git_status", highlight = "NeoTreeDimText" },
            { "diagnostics" },
            { "clipboard" },
          },
        },

        commands = ALL_COMMANDS,
        window = {
          width = 25,
          mappings = KEYMAPS,
          position = require("config.neotree").get_default_position(),
        },

        filesystem = {
          bind_to_cwd = true,
          find_by_full_path_words = true,
          follow_current_file = {
            enabled = true,
            leave_dirs_open = false,
          },
          group_empty_dirs = true,
          use_libuv_file_watcher = true,
          window = {
            mappings = FILESYSTEM,
            position = require("config.neotree").get_default_position(),
          },
          filtered_items = {
            visible = true,
            hide_dotfiles = false,
            hide_gitignored = false,
            hide_hidden = false,
            hide_by_pattern = {},
            hide_by_name = require("lib.nvim.fs.ignore.list").as_neotree_names(),
            never_show = {},
            never_show_by_pattern = {},
          },
        },

        buffers = {
          window = {
            mappings = BUFFERS,
            position = require("config.neotree").get_default_position(),
          },
        },

        git_status = {
          window = {
            mappings = GIT_STATUS,
            position = require("config.neotree").get_default_position(),
          },
        },

        document_symbols = {
          follow_cursor = true,
          client_filters = "first",
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
          window = {
            mappings = DOCUMENT_SYMBOLS,
            position = require("config.neotree").get_default_position(),
          },
        },

        diagnostics = {
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
          show_unloaded = true,
          refresh = {
            delay = 100,
            event = "vim_diagnostic_changed",
            max_items = 10000,
          },
          window = {
            mappings = DIAGNOSTICS,
            position = require("config.neotree").get_default_position(),
          },
        } or nil,

        tests = {
          follow_cursor = true,
          window = {
            -- mappings = vim.tbl_extend(
            -- "force",
            -- require("config.neotree.keymaps.tests"),
            -- NEOTEST.keymaps()
            -- ),
            mappings = NEOTEST.keymaps(),
            position = require("config.neotree").get_default_position(),
          },
        },
      }
    end,

    config = function(_, opts)
      require("neo-tree").setup(opts)
      require("config.neotree").setup({
        debug = true,
        busy_guard = false,
        default_position = "left",
        restore_last_position = false,
        window_debug = false,
        window_open = false,
        reveal_current_file = false,
        only_lhs = true,
      })
    end,
  },
}
