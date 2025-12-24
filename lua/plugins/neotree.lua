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
      statusline = false,
      show_scrolled_off_parent_node = true,
      padding = { left = 1, right = 0 },
      sources = {
        { source = "filesystem", display_name = "  Files" },
        { source = "buffers", display_name = "  Buffers" },
        { source = "git_status", display_name = " 󰊢 Git" },
      },
    },

    event_handlers = {
      --- ====  neotree should close after opening a file ====
      -- {
      --   event = "file_opened",
      --   handler = function()
      --     require("neo-tree.command").execute({ action = "close" })
      --   end,
      -- },

      --- ==== hide cursor in neotree window, only see the full line highlight ====
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
        folder_empty = "",
        folder_empty_open = "",
        default = "",

        -- AUDIT: REQUIRED?? FOR TRASH MARKING
        folder_closed = "",
        folder_open = "",
        highlight = "NeoTreeFileIcon",
      },
      modified = {
        -- symbol = "•",
        -- REQUIRED FOR TRASH MARKING
        symbol = "[+]",
        highlight = "NeoTreeModified",
      },
      name = {
        trailing_slash = true,
        use_git_status_colors = false,
        -- Add custom highlighting for marked files (required for trash marking, but wsa there before)
        highlight_opened_files = true,
        -- REQUIRED FOR TRASH MARKING
        highlight = "NeoTreeFileName",
      },
      git_status = {
        symbols = {
          added = "A",
          deleted = "D",
          modified = "M",
          renamed = "R",
          -- untracked = "U",
          -- ignored = "I",
          unstaged = "✗",
          staged = "✓",
          untracked = "★", -- 'untracked' style is used for marked files in trash
          ignored = "◌",
          conflict = "C",
        },
      },
    },

    -- Add custom renderer for marked files (trash)
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
        -- Add custom component for marks
        {
          -- Custom mark indicator component
          function(_, node, state)
            local marks = state.explicitly_marked_node_ids or {}
            local node_id = node:get_id()
            if marks[node_id] then
              return {
                text = " ✓", -- or use " ★" or " ●"
                highlight = "NeoTreeGitStaged", -- green highlight
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

        -- Everything is visible by default
        visible = true,
        hide_dotfiles = false,
        hide_gitignored = false,

        -- Hide files marked "hidden" by the filesystem (mainly relevant on Windows),
        hide_hidden = false,
        hide_by_pattern = {},
        hide_by_name = require("lib.filesystem.ignore.list").as_neotree_names(),

        -- Items listed here are *never* shown, even if `visible = true`.
        never_show = {},
        never_show_by_pattern = {},
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
        file = "green",
        parent = { fg = "darkgreen", underline = false },
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

    require("config.neotree.open").attach_opener_mappings()
  end,
}
