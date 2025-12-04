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

    event_handlers = {
      -- uncomment this if neotree should close after opening a file
      -- {
      --   event = "file_opened",
      --   handler = function()
      --     require("neo-tree.command").execute { action = "close" }
      --   end,
      -- },
      {
        event = "neo_tree_window_before_open",
        handler = function(args)
          if args and args.position == "right" then
            args.position = "left"
          end
        end,
      },

      -- AFTER open: Falls trotzdem rechts → schließen und links öffnen
      {
        event = "neo_tree_window_after_open",
        handler = function(args)
          -- Defensive checks
          if not args or not args.winid then
            return
          end
          if not vim.api.nvim_win_is_valid(args.winid) then
            return
          end

          local ok_pos, win_pos = pcall(vim.api.nvim_win_get_position, args.winid)
          if not ok_pos then
            return
          end

          local ok_width, win_width = pcall(vim.api.nvim_win_get_width, args.winid)
          if not ok_width then
            return
          end

          local screen_width = vim.o.columns

          -- Check if window is on the right side
          if (win_pos[2] + win_width) >= (screen_width - 5) then
            vim.schedule(function()
              -- Extract source from tabnr (args contains this)
              local source = "filesystem"

              -- Try to get source from window's buffer
              if vim.api.nvim_win_is_valid(args.winid) then
                local bufnr = vim.api.nvim_win_get_buf(args.winid)
                local bufname = vim.api.nvim_buf_get_name(bufnr)
                local match = bufname:match("neo%-tree://([^/]+)")
                if match then
                  source = match
                end
              end

              -- Close window
              pcall(vim.api.nvim_win_close, args.winid, true)

              -- Reopen on left
              local ok_cmd, neo_cmd = pcall(require, "neo-tree.command")
              if ok_cmd then
                vim.defer_fn(function()
                  neo_cmd.execute({
                    source = source,
                    position = "left",
                    action = "show",
                  })
                end, 100)
              end
            end)
          end
        end,
      },
    },

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
      window = { position = "left", mappings = FILESYSTEM },
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
    require("config.neotree.prevent_open_right").setup()
  end,
}
