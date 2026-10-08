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
--- `tree_toggle` now (features configured in plugins/personal/specs/navigate.lua);
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
    -- Not a startup plugin by its own trigger, but not on demand either:
    -- filetree.nvim loads on VeryLazy and lists neo-tree as a dependency, so
    -- in every session with a UI it comes in right after the first frame.
    -- (An earlier version of this comment claimed "29 instead of 44 plugins,
    -- ~1050 instead of ~1300 ms". That was measured headless, where VeryLazy
    -- never fires; see section 14 of docs/ROADMAP/reports/startup-und-config-
    -- optimierung-analyse-konzept-2026-09-26.md.)
    --
    -- What its `dependencies` drag in is therefore paid at every start, and
    -- neotest was most of it: ~150 of neo-tree's ~170 ms, with its adapters,
    -- vim-test, nio and FixCursorHold. neotest is no dependency any more. The
    -- `tests` source builds its items through a neotest *consumer* that only
    -- has a client once neotest is set up -- just dropping the dependency
    -- makes `:Neotree tests` die on a nil consumer -- so `config` below loads
    -- neotest right before that source first renders
    -- (config.neotest.neotree.load_with_tests_source). The source's own plugin
    -- stays a dependency: neo-tree's setup() requires every enabled source.
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
      "mrbjarksen/neo-tree-diagnostics.nvim",
    },
    config = function(_, opts)
      require("neo-tree").setup(opts)
      NEOTEST.load_with_tests_source()
    end,
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
          -- false (2026-10-08): neo-tree's own libuv watcher re-scans the WHOLE
          -- directory on every (debounced) fs event and does not guard against
          -- overlapping scans. On a busy directory with thousands of entries
          -- (%TEMP%) that starts ~1.7-3 full scans per second, none of which
          -- finishes, so the tree never re-renders while it burns CPU (measured:
          -- 5 events/s on 2000 entries -> 35 scans in 20 s, 20-29% of a core, 0
          -- re-renders; watcher off -> 0 scans, ~10%). The same flag also arms
          -- neo-tree's .git watcher. filetree.nvim's `file_watcher` feature
          -- (on by default, recursive, 500 ms trailing debounce) refreshes the
          -- tree on external changes instead: measured with this config, an
          -- external file / `git add` / edit shows up 1-2 s later than with
          -- the neo-tree watcher (git status colours included). With the flag
          -- off neo-tree additionally refreshes once per buffer write
          -- (`enable_refresh_on_write`, default true).
          use_libuv_file_watcher = false,
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
