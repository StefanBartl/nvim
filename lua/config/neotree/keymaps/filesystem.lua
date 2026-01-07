---@module 'config.neotree.keymaps.filesystem'
-- Filesystem-Source-specific extra mappings (unchanged) ============

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
      -- 1) get  the current node
      local node = node_utils.get_current(state)
      if not node then
        notify.info("no node under cursor")
        return
      end

      -- 2) Check if we're in a valid Neo-tree window
      local current_win = vim.api.nvim_get_current_win()
      local buf = vim.api.nvim_win_get_buf(current_win)
      local is_neotree_win = vim.bo[buf].filetype == "neo-tree"
      if not is_neotree_win then
        notify.warn("Neo-tree: Not in a Neo-tree window")
        return
      end

      -- 3) Clean up any safe preview (if open)
      safe_hide_preview(state)

      -- 4) Expand/collapse directories safely
      -- If the node is a directory or has children and is collapsed, toggle it
      if node.type == "directory" or (node.has_children and not node.is_expanded) then
        state.commands.toggle_node(state)
        return
      end

      -- 5) Normal open: prefer window-picker if present
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
  -- ["<Tab>"] = "toggle_preview",
  ["<2-LeftMouse>"] = "open",

  --======= background buffer add (no focus change, Neo-tree stays)

  ["<S-CR>"] = "open_badd",
  -- Fallback, if <S-CR> is not recognized in terminals
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
      -- Validate window context
      local current_win = vim.api.nvim_get_current_win()
      local buf = vim.api.nvim_win_get_buf(current_win)

      if vim.bo[buf].filetype ~= "neo-tree" then
        notify.warn("Neo-tree: Preview only works in Neo-tree window")
        return
      end

      -- Safe toggle with error handling
      local ok, _ = pcall(function()
        state.commands.toggle_preview(state)
      end)

      if not ok then
        -- Fallback: try to hide preview
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

  --======= preview toggle + scrolling (Neo-tree preview)

  ["<PageDown>"] = { "scroll_preview", config = { direction = -10 } },
  ["<PageUp>"] = { "scroll_preview", config = { direction = 10 } },
  ["<C-f>"] = { "scroll_preview", config = { direction = -1 } },
  ["<C-b>"] = { "scroll_preview", config = { direction = 1 } },

  --====================== Replace Buffer And Focus ===================
  -- FIX: in `lua\config\neotree\open_replace\init.lua `
  ---@param state Cfg.NeoTree.State
  ["<S-o>"] = function(state)
    open_replace(state, { focus = true, auto_close = true })

    -- Open_replace_logger = {
    --   info = function(msg, ctx)
    --     notify("[neotree] " .. msg .. (ctx and (" " .. vim.inspect(ctx)) or ""), levels.INFO)
    --   end,
    --   warn = function(msg, ctx)
    --.info     notify("[neotree] " .. msg .. (ctx and (" " .. vim.inspect(ctx)) or ""))
    --   end,
    --   debug = function(msg, ctx)
    --     notify("[neotree] [DEBUG] " .. (msg or "") .. (ctx and (" " .. vim.inspect(ctx)) or ""), levels.DEBUG)
    --   end,
    -- }
    -- require("config.neotree.open_replace")(state, { focus = true, auto_close = true, logger = Open_replace_logger })
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
  ["D"] = "diff_files", --FIX: Funktioniert nicht

  --====================== Trash Operations ===========================

  --FIX: No nodes selectes wenn nicht markiert ist. Ob es mit mark funkltinert kann noch nicht geprüft, da mark nicht funktoinert.
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
    desc = "Show trash history (optional)",
  },

  --====================== Mark Operations ============================
  -- Note: <C-c> and <C-a> are problematic in Neovim terminals
  -- Using <leader>m prefix for mark operations instead

  --FIX: Gesamte mark operations funktionieret nicht

  ["m"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      commands.mark.toggle_mark(state)
    end,
    desc = "Mark/Unmark single file",
  },

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
      -- 1) Safely get the current node
      local node = node_utils.get_current(state)
      if not node then
        notify.info("no node under cursor")
        return
      end

      -- 2) Resolve the absolute path and check if it's valid
      local path, is_dir = node_utils.get_path(node)
      if path == "" then
        notify.warn("no path under cursor")
        return
      end

      -- 3) Determine the directory: if the node is a file, use its parent
      local dir = is_dir and path or fn.fnamemodify(path, ":h")

      -- 4) Attempt to change Neovim's cwd safely
      local ok, err = pcall(vim.api.nvim_set_current_dir, dir)
      if not ok then
        notify.error(("cd failed: %s"):format(tostring(err)))
        return
      end

      -- 5) If Neo-tree command module exists, execute focus/reveal on the new dir
      local ok_cmd, neo_cmd = pcall(require, "neo-tree.command")
      if ok_cmd and neo_cmd then
        neo_cmd.execute({ source = "filesystem", dir = dir, reveal = true })
      end

      -- 6) Notify the user of the cwd change
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

    --FIX: funktionert nicht
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
        return
      end

      fn.setreg("+", path, "c")
    end,
    desc = "Copy Path to Clipboard",
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

    --FIX: die beiden r funktien machen dasselbe
  ["]r"] = {
    --- Copy the node's relative path to the system clipboard (+)
    --- Base preference: project root → fallback to cwd
    ---@param state Cfg.NeoTree.State
    function(state)
      -- 1) Safely get current node
      local node = node_utils.get_current(state)
      if not node then
        notify.info("no node under cursor")
        return
      end

      -- 2) Get relative path via path_utils
      local path, msg = path_utils.from_node(node, "relative", { base_dir = false })
      if not path then
        notify.info(msg)
        return
      end

      -- 3) Copy to system clipboard
      fn.setreg("+", path, "c")
      notify.info(("Copied relative path: %s"):format(path))
    end,
    desc = "Copy relative path (+) (root→node or cwd→node)",
  },

  ["[r"] = {
    --- Copy the node's base directory (relative) to system clipboard (+)
    --- Base preference: project root → fallback to cwd
    ---@param state Cfg.NeoTree.State
    function(state)
      -- 1) Safely get current node
      local node = node_utils.get_current(state)
      if not node then
        notify.info("no node under cursor")
        return
      end

      -- 2) Get relative base directory via path_utils
      local path, msg = path_utils.from_node(node, "relative", { base_dir = true })
      if not path then
        notify.info(msg)
        return
      end

      -- 3) Copy to system clipboard
      vim.fn.setreg("+", path, "c")
      notify.info("Copied relative path: " .. path)
    end,
    desc = "Copy relative path",
  },

  ["[f"] = {
    --FIX: funktinoert nicht
    ---@param state Cfg.NeoTree.State
    function(state)
      copy_folders(state, { relative_to_cwd = false, preview_limit = 20 })
    end,
    desc = "Copy recursive folder list (absolute paths) to clipboard (+)",
  },

  ["[F"] = {
    --FIX: funktinoert nicht
    ---@param state Cfg.NeoTree.State
    function(state)
      copy_folders(state, { relative_to_cwd = true, preview_limit = 20 })
    end,
    desc = "Copy recursive folder list (relative to cwd) to clipboard (+)",
  },

  ["[t"] = {
    --FIX: funktinoert nicht
    ---@param state Cfg.NeoTree.State
    function(state)
      copy_entries(state, { -- AUDIT: In Modul typisieren oder hier kommentieren
        relative_to_cwd = false,
        preview_limit = 20,
        quote_paths = false,
        format = "list",
      })
    end,
    desc = "Copy recursive file list",
  },

  ["[T"] = {
    --FIX: funktinoert nicht
    ---@param state Cfg.NeoTree.State
    function(state)
      copy_entries(state, {
        relative_to_cwd = true,
        preview_limit = 20,
        quote_paths = false,
        format = "list",
      })
    end,
    desc = "Copy recursive file list (relative to cwd) to clipboard (+)",
  },

  --====================== Special Operations ==========================

  ["I"] = {
    --FIX: funktinoert nicht
    ---@param state Cfg.NeoTree.State
    function(state)
      node_info.show_from_neotree(state)
    end,
    desc = "Show file or directory information (hover)",
  },

  ["O"] = {
    --FIX: funktinoert nicht
    ---@param state Cfg.NeoTree.State
    function(state)
      -- 1) Safely get the current node
      local node = node_utils.get_current(state)
      if not node then
        notify.info("no node under cursor")
        return
      end

      -- 2) Resolve the absolute path of the node
      local path, _ = node_utils.get_path(node)
      if path == "" then
        notify.warn("No path under cursor")
        return
      end

      -- 3) Open the file using the system's default application
      require("lazy.util").open(path, { system = true })
    end,
    desc = "Open with System Application",
  },

  ["L"] = {
    -- FIX: No path under cursor
    ---@param state Cfg.NeoTree.State
    function(state)
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
      fm.open(state)
    end,
    desc = "Open in system file manager",
  },

  ["[l"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      -- 1) Safely get the current node
      local node = node_utils.get_current(state)
      if not node then
        notify.info("no node under cursor")
        return
      end

      -- 2) Call the utility to copy Lua require() strings
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
