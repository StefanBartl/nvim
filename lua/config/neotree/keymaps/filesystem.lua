---@module 'config.neotree.keymaps.filesystem'
--- Filesystem-Source-specific extra mappings

local notify = require("lib.notify").create("[cfg.neotree.keymaps.fs] ")

local node_utils = require("config.neotree.utils.node")
local safe_hide_preview = require("config.neotree.utils").safe_hide_preview
local copy_entries = require("config.neotree.actions.copy.entries")
local copy_folders = require("config.neotree.actions.copy.folders")
local to_require = require("config.neotree.actions.path.to_require")
local node_info = require("config.neotree.actions.info.node")
local save_node_buffer = require("config.neotree.actions.save.node_buffer")
local save_adjacent_buffer = require("config.neotree.actions.save.adjacent_buffer")
local grep_picker = require("config.neotree.actions.grep_picker")
local traverse = require("config.neotree.actions.traverse")
local commands = require("config.neotree.commands")
local trash = require("config.neotree.trash")
local undo = require("config.neotree.undo")
local node_replace_buf = require("config.neotree.actions.node_replace_buf")

local fn = vim.fn

---@return table<string, any>
return {

  --====================== Filter ======================================

  ["/"] = "noop",
  ["f"] = "filter_on_submit",
  ["F"] = "fuzzy_finder",
  ["<C-c>"] = "clear_filter",

  --====================== Commands ====================================

  ["i"] = "run_command",
  ["tf"] = "telescope_find",
  ["tg"] = "telescope_grep",

  --====================== File Operations =============================

  ["<CR>"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      local node = node_utils.get_current(state)
      if not node then
        notify.info("no node under cursor")
        return
      end

      local current_win = vim.api.nvim_get_current_win()
      local buf = vim.api.nvim_win_get_buf(current_win)
      local is_neotree_win = vim.bo[buf].filetype == "neo-tree"
      if not is_neotree_win then
        notify.warn("Neo-tree: Not in a Neo-tree window")
        return
      end

      safe_hide_preview()

      if node.type == "directory" or (node.has_children and not node.is_expanded) then
        state.commands.toggle_node(state)
        return
      end

      if pcall(require, "window-picker") then
        local ok = pcall(state.commands.open_with_window_picker, state)
        if not ok then
          pcall(state.commands.open, state)
        end
      else
        pcall(state.commands.open, state)
      end
    end,
    desc = "Safe expand / collapse nodes and open files",
  },

  ["<2-LeftMouse>"] = "open",
  ["<leader>"] = "noop",
  ["<S-CR>"] = "open_badd",
  ["gb"] = "open_badd",

  --====================== Save Operations =============================

  ["<C-s>"] = {
    function(_)
      save_adjacent_buffer()
    end,
    desc = "force-save last normal buffer (w!)",
  },

  ["<M-s>"] = {
    function(_)
      save_node_buffer()
    end,
    desc = "force-save buffer matching node under cursor (w!)",
  },

  --====================== Preview =====================================

  ["<Tab>"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      local current_win = vim.api.nvim_get_current_win()
      local buf = vim.api.nvim_win_get_buf(current_win)

      if vim.bo[buf].filetype ~= "neo-tree" then
        notify.warn("Neo-tree: Preview only works in Neo-tree window")
        return
      end

      local ok, _ = pcall(function()
        state.commands.toggle_preview(state)
      end)

      if not ok then
        pcall(function()
          local preview = require("neo-tree.sources.common.preview")
          if preview and preview.hide then
            preview.hide()
          end
        end)
      end
    end,
    desc = "Preview Mode",
  },

  ["<C-b>"] = { "scroll_preview", config = { direction = 1 } },
  ["<C-f>"] = { "scroll_preview", config = { direction = -1 } },
  ["<PageUp>"] = { "scroll_preview", config = { direction = 10 } },
  ["<PageDown>"] = { "scroll_preview", config = { direction = -10 } },

  --====================== Replace / Focus =============================

  ["O"] = {
    function(state)
      node_replace_buf(state, { focus = true, auto_close = true })
    end,
    desc = "Open file and replace current buffer",
  },

  --====================== Splits / Tabs ===============================

  ["sg"] = "open_vsplit",
  ["st"] = "open_tabnew",
  ["sv"] = "open_split",

  --====================== Clipboard ===================================

  ["c"] = "copy_to_clipboard",
  ["p"] = "paste_from_clipboard",
  ["x"] = "cut_to_clipboard",

  --====================== Create / Modify =============================

  -- ["a"] = { "add", nowait = true, config = { show_path = "relative" } },
  ["a"] = { "custom_add", nowait = true, config = { insert_clipb = true } }, -- { insert_clipb = true } möglich (ohne confirmation)
  ["D"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      commands.diff_files(state)
    end,
    desc = "Diff files (mark two files, then trigger)",
  },
  ["r"] = "rename",

  --====================== Trash =======================================

  ["d"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      trash.neotree_send_node_to_trash(state)
    end,
    desc = "Delete marked files or file under cursor",
  },

  ["U"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      undo.neotree_undo_trash(state)
    end,
    desc = "Undo last trash",
  },

  ["<leader>th"] = {
    function(_)
      undo.show_history()
    end,
    desc = "Show trash history",
  },

  --====================== Mark ========================================

  ["m"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      commands.mark.toggle_mark(state, false) -- cursor stays at node after mmarking it
    end,
    desc = "Mark/Unmark single file",
  },

  ["]m"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      commands.mark.mark_all_in_directory(state)
    end,
    desc = "Mark all files in directory",
  },


  ["[m"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      commands.mark.unmark_all_in_directory(state)
    end,
    desc = "Unmark all files in directory",
  },

  ["<leader>ms"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      require("config.neotree.commands.mark.show").show_marked_nodes(state)
    end,
    desc = "Show all marks",
  },

  ["<leader>mc"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      commands.mark.clear_all_marks(state)
    end,
    desc = "Clear all marks",
  },

  --====================== Navigation ==================================

  ["+"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      traverse.down(state)
    end,
    desc = "Navigate into directory and set as root (CWD sync)",
  },

  ["-"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      traverse.up(state)
    end,
    desc = "Navigate up one level (in-place, CWD sync)",
  },

  --====================== Path / Copy ==================================

  ["[a"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      local node = node_utils.get_current(state)
      if not node then
        notify.info("no node under cursor")
        return
      end

      local path, _ = node_utils.get_path(node)
      if path == "" then
        notify.info("no path")
        return
      end

      fn.setreg("+", path, "c")
      notify.info(("copied: %s"):format(path))
    end,
    desc = "Copy absolute path (+)",
  },

  ["]a"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      local node = node_utils.get_current(state)
      if not node then
        notify.info("no node under cursor")
        return
      end

      local path, is_dir = node_utils.get_path(node)
      if path == "" then
        notify.info("no path")
        return
      end

      local base = is_dir and path or fn.fnamemodify(path, ":h")
      fn.setreg("+", base, "c")
      notify.info(("copied: %s"):format(base))
    end,
    desc = "Copy base (dir) absolute path (+)",
  },

  ["[f"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      local success = copy_entries(state, {
        relative_to_cwd = false,
        preview_limit = 20,
        quote_paths = false,
        format = "list",
      })
      if not success then
        notify.warn("Failed to copy file list")
      end
    end,
    desc = "Copy absolute file path (file node) or recursive file list (folder node) to clipboard (reg +)",
  },

  ["]f"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      local success = copy_entries(state, {
        relative_to_cwd = true,
        preview_limit = 20,
        quote_paths = false,
        format = "list",
      })
      if not success then
        notify.warn("Failed to copy file list")
      end
    end,
    desc = "Copy relative file path (file node) or recursive file list (folder node) to clipboard (reg +) (relative to cwd)",
  },

  ["[F"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      local success = copy_folders(state, { relative_to_cwd = false, preview_limit = 20 })
      if not success then
        notify.warn("Failed to copy folder list")
      end
    end,
    desc = "Copy absolute folder path (file node) or recursive folder list (folder node) to clipboard (reg +)",
  },

  ["]F"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      local success = copy_folders(state, { relative_to_cwd = true, preview_limit = 20 })
      if not success then
        notify.warn("Failed to copy folder list")
      end
    end,
    desc = "Copy relative folder path (file node) or recursive folder list (folder node) to clipboard (reg +) (relative to cwd)",
  },

  --====================== Info / Special ===============================

  ["I"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      node_info.show_from_neotree(state)
    end,
    desc = "Show file or directory information (hover)",
  },

  ["<leader>fm"] = {
    function(state)
      local ok, filemanager = pcall(require, "config.neotree.open.filemanager")
      if not ok then
        notify.error("File manager module not loaded")
        return
      end

      local success = filemanager.open_from_neotree(state)
      if not success then
        notify.warn("Failed to open in file manager")
      end
    end,
    desc = "Open in system file manager",
  },

  ["<leader>sm"] = {
    function(state)
      require("config.neotree.open.system_app").open_from_neotree(state)
    end,
    desc = "Open with System Application",
  },

  ["rq"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      local node = node_utils.get_current(state)
      if not node then
        notify.info("no node under cursor")
        return
      end

      to_require.copy_as_require(node, {
        relative = true,
        show_preview = true,
      })
    end,
    desc = "Copy Lua require() string(s)",
  },

  --====================== Search / Grep ================================

  ["gr"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      -- Default: auto-detect (prefers telescope, falls back to fzf)
      grep_picker.live_grep(state)
    end,
    desc = "Live grep in node directory (auto-detect picker)",
  },

  -- Alternative: Explicit telescope
  ["<leader>gt"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      grep_picker.live_grep(state, "telescope")
    end,
    desc = "Live grep in node directory (telescope)",
  },

  -- Alternative: Explicit fzf
  ["<leader>gf"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      grep_picker.live_grep(state, "fzf")
    end,
    desc = "Live grep in node directory (fzf-lua)",
  },
}
