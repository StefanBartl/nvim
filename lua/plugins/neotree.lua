---@module 'plugins.neotree'
--- neo-tree.nvim's lazy.nvim spec: sources (filesystem/git_status/
--- diagnostics/tests via neo-tree-tests-source.nvim), and keymaps
--- assembled from config.neotree.keymaps.* per source.
---
--- What is NOT here any more (2026-09-19, external-plugins report "neo-tree
--- config -> filetree.nvim"): the source switcher (picker, `"`/`!` cycling,
--- the source_selector display names), the `<M-c/f/l/r>` toggle keys with
--- their E95 self-heal, the node utilities, the config-level health check
--- and its two commands. All of it is filetree.nvim's `source_switcher` and
--- `tree_toggle` now (features configured in plugins/personal/init.lua);
--- `config/neotree/` keeps only what is genuinely neo-tree configuration --
--- the per-source `window.mappings` tables and one event handler.

local KEYMAPS = require("config.neotree.keymaps")
local NEOTEST = require("config.neotest.neotree")
local BUFFERS = require("config.neotree.keymaps.buffers")
local DOCUMENT_SYMBOLS = require("config.neotree.keymaps.document_symbols")
local FILESYSTEM = require("config.neotree.keymaps.filesystem")
local GIT_STATUS = require("config.neotree.keymaps.git_status")
local DIAGNOSTICS = require("config.neotree.keymaps.diagnostics")

-- Where every source opens by default; filetree.nvim's tree_toggle keys
-- pick a position per key on top of this.
local DEFAULT_POSITION = "left"

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

      -- The source_selector names come from filetree.nvim's source switcher,
      -- whose `display_names` is a pure function -- no setup() needed, and
      -- it is what `:Filetree source` shows in its own picker, so the two
      -- cannot disagree. Icon family/variant/length are its config knobs.
      local switcher = require("filetree.features.nav.source_switcher")
      local sources = switcher.display_names(enabled_sources, {
        family = "nerd", -- common | nerd | codicons
        variant = "v1", -- v1 | v2
        length = "long", -- long | short
      })

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
          -- `git_status.symbols` (M/A/D/R/...), the `git_status`/`diagnostics`/
          -- `clipboard` renderer entries below, and their config are gone
          -- (2026-09-22): filetree.nvim's own `git_status`/`lsp_diagnostics`/
          -- `copy_move` features draw the same three things as their own
          -- extmarks -- always have, adapter-agnostically -- so neo-tree's
          -- native versions were a second, independent copy of the same
          -- information. Invisible under filetree's un-styled default
          -- signs; visibly redundant once `decoration_style = "rounded"`
          -- turned filetree's half into a colored pill next to neo-tree's
          -- own plain glyph. `name.use_git_status_colors` stays -- coloring
          -- the filename itself is a technique filetree.nvim doesn't have,
          -- not a duplicate sign.
        },

        renderers = {
          directory = {
            { "indent" },
            { "icon" },
            { "current_filter" },
            { "name" },
          },
          file = {
            { "indent" },
            { "icon" },
            { "name", use_git_status_colors = true },
          },
        },

        commands = ALL_COMMANDS,
        window = {
          width = 25,
          mappings = KEYMAPS,
          position = DEFAULT_POSITION,
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
            position = DEFAULT_POSITION,
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
            position = DEFAULT_POSITION,
          },
        },

        git_status = {
          window = {
            mappings = GIT_STATUS,
            position = DEFAULT_POSITION,
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
            position = DEFAULT_POSITION,
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
            position = DEFAULT_POSITION,
          },
        },

        tests = {
          follow_cursor = true,
          window = {
            mappings = NEOTEST.keymaps(),
            position = DEFAULT_POSITION,
          },
        },
      }
    end,
  },
}
