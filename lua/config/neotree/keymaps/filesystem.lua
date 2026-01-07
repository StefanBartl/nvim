---@module 'config.neotree.keymaps.filesystem'
--- Filesystem-Source-specific extra mappings

-- AUDIT: FIX: Neotree keymaps werden relativ oft verwendet. imports hier belassen, in die funktionen refactoren oder mit `lib.lazy`?

local notify = require("lib.notify").create("[cfg.neotree.keymaps.fs] ")

local node_utils = require("config.neotree.utils.node")
local safe_hide_preview = require("config.neotree.utils").safe_hide_preview
local copy_entries = require("config.neotree.actions.copy.entries")
local copy_folders = require("config.neotree.actions.copy.folders")
local to_require = require("config.neotree.actions.path.to_require")
local node_info = require("config.neotree.actions.info.node")
local path_utils = require("config.neotree.utils.path")
local save_node_buffer = require("config.neotree.actions.save.node_buffer")
local save_adjacent_buffer = require("config.neotree.actions.save.adjacent_buffer")
local fzf_grep_picker = require("config.neotree.fzf_grep_picker")
local updir = require("config.neotree.updir")
local is_wsl = require("lib.is_wsl")
local open_replace = require("config.neotree.open_replace")
local commands = require("config.neotree.commands")
local trash = require("config.neotree.trash")
local undo = require("config.neotree.undo")
local fn = vim.fn

---@return table<string, any>
return {

  --====================== Filter ======================================

  ["/"] = "noop",
  ["f"] = "filter_on_submit",
  ["F"] = "fuzzy_finder",
  ["<C-c>"] = "clear_filter",

  --====================== commands ===================================

  ["i"] = "run_command",
  ["tf"] = "telescope_find",
  ["tg"] = "telescope_grep",

  --====================== File Operations ============================

  --======= Expand / Collapse nodes

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

  --======= basics

  ["<leader>"] = "noop",
  ["<2-LeftMouse>"] = "open",

  --======= background buffer add (no focus change, Neo-tree stays)

  ["<S-CR>"] = "open_badd",
  ["gb"] = "open_badd",

  --====================== Save Operations ============================

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

  --====================== Preview Node ===============================

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

  --======= preview scrolling

  ["<PageDown>"] = { "scroll_preview", config = { direction = -10 } },
  ["<PageUp>"] = { "scroll_preview", config = { direction = 10 } },
  ["<C-f>"] = { "scroll_preview", config = { direction = -1 } },
  ["<C-b>"] = { "scroll_preview", config = { direction = 1 } },

  --====================== Replace Buffer And Focus ===================

  ["<S-o>"] = function(state)
    open_replace(state, { focus = true, auto_close = true })
  end,

  --====================== splits/tabs shorthand  =====================

  ["sv"] = "open_split",
  ["sg"] = "open_vsplit",
  ["st"] = "open_tabnew",

  --====================== File Clipboard Operations ==================

  ["c"] = "copy_to_clipboard",
  ["x"] = "cut_to_clipboard",
  ["p"] = "paste_from_clipboard",

  --====================== File Creation/Modification =================

  ["a"] = { "add", nowait = true, config = { show_path = "relative" } },
  ["A"] = { "add_directory", config = { show_path = "relative" } },
  ["r"] = "rename",

  -- FIXED: diff_files now uses proper command module
  ["D"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      commands.diff_files(state)
    end,
    desc = "Diff files (mark two files, then trigger)",
  },

  --====================== Trash Operations ===========================

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

  --====================== Mark Operations ============================

  ["m"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      commands.mark.toggle_mark(state)
    end,
    desc = "Mark/Unmark single file",
  },

--FIX: Not working
  ["<S-m>"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      commands.mark.mark_all_in_directory(state)
    end,
    desc = "Mark all files in directory",
  },

  ["<leader>mc"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      commands.mark.clear_all_marks(state)
    end,
    desc = "Clear all marks",
  },

  --==================== Navigation: Traverse Updir/Downdir  ========

  ["+"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      local node = node_utils.get_current(state)
      if not node then
        notify.info("no node under cursor")
        return
      end

      local path, is_dir = node_utils.get_path(node)
      if path == "" then
        notify.warn("no path under cursor")
        return
      end

      local dir = is_dir and path or fn.fnamemodify(path, ":h")

      local ok, err = pcall(vim.api.nvim_set_current_dir, dir)
      if not ok then
        notify.error(("cd failed: %s"):format(tostring(err)))
        return
      end

      local ok_cmd, neo_cmd = pcall(require, "neo-tree.command")
      if ok_cmd and neo_cmd then
        neo_cmd.execute({ source = "filesystem", dir = dir, reveal = true })
      end

      notify.info(("cwd → %s"):format(dir))
    end,
    desc = "Set Neovim cwd to node and focus Neo-tree there",
  },

  ["-"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      updir.up_one_level(state)
    end,
    desc = "Up one level (in-place) and adjust CWD",
  },

  --====================== Path & File Copying & Lists Operations =====

  ["Y"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      local node = node_utils.get_current(state)
      if not node then
        notify.warn("no node under cursor")
        return
      end

      local path, _ = node_utils.get_path(node)
      if path == "" then
        notify.warn("no path")
        return
      end

      fn.setreg("+", path, "c")
      notify.info(("Copied path: %s"):format(path))
    end,
    desc = "Copy absolute path to clipboard",
  },

  ["[p"] = {
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

  ["]p"] = {
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
    desc = "Copy base (dir) path (+)",
  },

  ["]r"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      local node = node_utils.get_current(state)
      if not node then
        notify.info("no node under cursor")
        return
      end

      local path, msg = path_utils.from_node(node, "relative", { base_dir = false })
      if not path then
        notify.info(msg or "Failed to get path")
        return
      end

      fn.setreg("+", path, "c")
      notify.info(("Copied relative path: %s"):format(path))
    end,
    desc = "Copy relative path (file)",
  },

  ["[r"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      local node = node_utils.get_current(state)
      if not node then
        notify.info("no node under cursor")
        return
      end

      local path, msg = path_utils.from_node(node, "relative", { base_dir = true })
      if not path then
        notify.info(msg or "Failed to get path")
        return
      end

      fn.setreg("+", path, "c")
      notify.info(("Copied relative directory: %s"):format(path))
    end,
    desc = "Copy relative directory path",
  },

    --FIX: On Folder node: Failes to copy files list: no file found
  ["[f"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      local success = copy_folders(state, { relative_to_cwd = false, preview_limit = 20 })
      if not success then
        notify.warn("Failed to copy folder list")
      end
    end,
    desc = "Copy recursive folder list (absolute paths) to clipboard (+)",
  },

    --FIX: On Folder node: Failes to copy files list: no file found
  ["[F"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      local success = copy_folders(state, { relative_to_cwd = true, preview_limit = 20 })
      if not success then
        notify.warn("Failed to copy folder list")
      end
    end,
    desc = "Copy recursive folder list (relative to cwd) to clipboard (+)",
  },

    --FIX: On Folder node: Failes to copy files list: no file found
  ["[t"] = {
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
    desc = "Copy recursive file list",
  },

    --FIX: On Folder node: Failes to copy files list: no file found
  ["[T"] = {
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
    desc = "Copy recursive file list (relative to cwd) to clipboard (+)",
  },

  --====================== Special Operations ==========================

  ["I"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      node_info.show_from_neotree(state)
    end,
    desc = "Show file or directory information (hover)",
  },

  -- FIX:Funkltioniert nicht;
  ["O"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      local node = node_utils.get_current(state)
      if not node then
        notify.info("no node under cursor")
        return
      end

      local path, _ = node_utils.get_path(node)
      if path == "" then
        notify.warn("No path under cursor")
        return
      end

      -- Try lazy.util first, fallback to vim.ui.open or xdg-open
      local ok_lazy, lazy_util = pcall(require, "lazy.util")
      if ok_lazy and lazy_util.open then
        lazy_util.open(path, { system = true })
      elseif vim.ui.open then
        vim.ui.open(path)
      else
        -- Manual fallback
        local cmd
        if vim.fn.has("mac") == 1 then
          cmd = { "open", path }
        elseif vim.fn.has("win32") == 1 then
          cmd = { "cmd.exe", "/c", "start", "", path }
        else
          cmd = { "xdg-open", path }
        end
        vim.fn.jobstart(cmd, { detach = true })
      end
    end,
    desc = "Open with System Application",
  },

    --FIX:
 --   Warn  23:17:17 notify.warn Open in Explorer: no path under cursor
 --   Warn  23:17:17 notify.warn [cfg.neotree.keymaps.fs] Failed to open in file manager
  ["L"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      local node = node_utils.get_current(state)
      if not node then
        notify.warn("No node under cursor")
        return
      end

      local path, _ = node_utils.get_path(node)
      if path == "" then
        notify.warn("No path available")
        return
      end

      local mod
      if fn.has("win32") == 1 or fn.has("win64") == 1 then
        mod = "config.neotree.open_fm.win"
      elseif is_wsl() then
        mod = "config.neotree.open_fm.wsl"
      else
        mod = "config.neotree.open_fm.unix_ubuntu"
      end

      local ok, fm = pcall(require, mod)
      if not ok then
        notify.error("open_fm module not found: " .. mod)
        return
      end

      local success = fm.open(state)
      if not success then
        notify.warn("Failed to open in file manager")
      end
    end,
    desc = "Open in system file manager",
  },

  ["[l"] = {
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

  ["grep"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      fzf_grep_picker.live_grep_node_dir(state)
    end,
    desc = "fzf-lua: live_grep in node directory (Windows/WSL/macOS/Linux)",
  },
}
