---@module 'config.neotree.keymaps'
--- Centralized, buffer-local Neo-tree keymaps that override defaults consistently.

local copy_node_entries_handler = require("config.neotree.helper.copy_node_entries_handler")
local copy_node_folders_handler = require("config.neotree.helper.copy_node_folders_handler")
local rel_path_to_require = require("config.neotree.helper.rel_path_to_require")
local path_helper = require("config.neotree.helper.node_to_path")
local save_adjacent = require("config.neotree.helper.save_adjacent_buffer")
local save_node = require("config.neotree.helper.save_node_buffer")
local fzf_grep_picker = require("config.neotree.fzf_grep_picker")
local updir = require("config.neotree.updir")
local node_informations = require("config.neotree.helper.node_informations")
local is_wsl = require("lib.is_wsl")
local open_replace = require("config.neotree.open_replace")
local commands = require("config.neotree.commands")
local trash = require("config.neotree.trash")
local hide_preview_safe = require("config.neotree.helper.hide_preview_safe")
local undo = require("config.neotree.undo")

local fn, cmd = vim.fn, vim.cmd
local notify, levels = vim.notify, vim.log.levels
local desc_tag = "[neotree.keymaps.custom] "

-- ========= Window mappings (no nested tables; every key maps to a function/command) =========

---@return table<string, any>
return {
  -- basics
  ["q"] = "close_window",
  ["?"] = "show_help",
  ["g?"] = "noop",
  ["<leader>"] = "noop",
  -- ["<Tab>"] = "toggle_preview",
  ["<2-LeftMouse>"] = "open",

  -- background buffer add (no focus change, Neo-tree stays)
  ["<S-CR>"] = "open_badd",
  -- Fallback, falls <S-CR> im Terminal nicht erkannt wird:
  ["gb"] = "open_badd",

  ["C"] = "close_node",
  ["z"] = "close_all_nodes",
  ["R"] = "refresh",

  -- splits/tabs shorthand
  ["s"] = "noop",
  ["sv"] = "open_split",
  ["sg"] = "open_vsplit",
  ["st"] = "open_tabnew",
  ["t"] = "noop", -- set to noop ; default t = tabnew; needed for telescope mappings tf and tg

  -- source switching
  ["<S-Tab>"] = "prev_source",

  -- file ops via neo-tree clipboard
  ["c"] = "copy_to_clipboard",
  ["x"] = "cut_to_clipboard",
  ["p"] = "paste_from_clipboard",
  ["r"] = "rename",

  ["a"] = { "add", nowait = true, config = { show_path = "relative" } },
  ["A"] = { "add_directory", config = { show_path = "relative" } },

  -- preview toggle + scrolling (Neo-tree preview)
  ["<PageDown>"] = { "scroll_preview", config = { direction = -10 } },
  ["<PageUp>"] = { "scroll_preview", config = { direction = 10 } },
  ["<C-f>"] = { "scroll_preview", config = { direction = -1 } },
  ["<C-b>"] = { "scroll_preview", config = { direction = 1 } },

  -- ===================================================================
  -- ================== Custom Neotree Mappings ========================
  -- ===================================================================

  -- ==================  Expand / Collapse nodes   =====================

  ["<CR>"] = function(state)
    local node = state.tree:get_node()
    if not node then
      return
    end

    -- ADDED: Check if we're in a valid Neo-tree window
    local current_win = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_win_get_buf(current_win)
    local is_neotree_win = vim.bo[buf].filetype == "neo-tree"

    if not is_neotree_win then
      vim.notify("Neo-tree: Not in a Neo-tree window", vim.log.levels.WARN)
      return
    end

    -- ADDED: Safe preview cleanup
    pcall(function()
      local preview = require("neo-tree.sources.common.preview")
      if preview and preview.hide then
        preview.hide()
      end
    end)

    -- 1) expand/collapse directories
    if node and (node.type == "directory" or (node:has_children() and not node:is_expanded())) then
      state.commands.toggle_node(state)
      return
    end

    -- 2) normal open (prefer window-picker if present)
    if pcall(require, "window-picker") then
      -- ADDED: Protect window-picker call
      local ok = pcall(state.commands.open_with_window_picker, state)
      if not ok then
        pcall(state.commands.open, state)
      end
    else
      pcall(state.commands.open, state)
    end
  end,

  -- ====================== Preview Node   ==========================

  ["<Tab>"] = function(state)
    -- Validate window context
    local current_win = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_win_get_buf(current_win)

    if vim.bo[buf].filetype ~= "neo-tree" then
      vim.notify("Neo-tree: Preview only works in Neo-tree window", vim.log.levels.WARN)
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

  -- ========= clear filter, preview and search highlight ==============

  ["<Esc>"] = function(state)
    require("neo-tree.sources.filesystem").reset_search(state, true)
    require("neo-tree.sources.filesystem.lib.filter_external").cancel()
    hide_preview_safe(state)
    cmd("nohlsearch")
  end,

  -- =================== Save Buffer And Nodes =========================

  ["<C-s>"] = {
    function(_)
      save_adjacent()
    end,
    desc = desc_tag .. "force-save last normal buffer (w!)",
  },

  ["<M-s>"] = {
    function(_)
      save_node()
    end,
    desc = desc_tag .. "force-save buffer matching node under cursor (w!)",
  },

  -- ================ Replace Buffer And Focus ==========================

  ["<S-o>"] = function(state)
    open_replace(state, { focus = true, auto_close = true })

    -- Open_replace_logger = {
    --   info = function(msg, ctx)
    --     notify("[neotree] " .. msg .. (ctx and (" " .. vim.inspect(ctx)) or ""), levels.INFO)
    --   end,
    --   warn = function(msg, ctx)
    --     notify("[neotree] " .. msg .. (ctx and (" " .. vim.inspect(ctx)) or ""), levels.WARN)
    --   end,
    --   debug = function(msg, ctx)
    --     notify("[neotree] [DEBUG] " .. (msg or "") .. (ctx and (" " .. vim.inspect(ctx)) or ""), levels.DEBUG)
    --   end,
    -- }
    -- require("config.neotree.open_replace")(state, { focus = true, auto_close = true, logger = Open_replace_logger })
  end,

  -- ======================   MISC   =================================

  ["D"] = "diff_files",

  ["I"] = {
    function(state)
      node_informations.show_from_neotree(state)
    end,
    desc = desc_tag .. "Show file or directory information (hover)",
  },

  -- resize helper
  -- FIX: add description tag
  ["w"] = function(state)
    local normal = state.window.width
    local large = normal * 1.9
    local small = math.floor(normal / 1.6)
    local cur_width = state.win_width
    local new_width = normal
    if cur_width > normal then
      new_width = small
    elseif cur_width == normal then
      new_width = large
    end
    cmd(new_width .. " wincmd |")
  end,

  ["Y"] = {
    function(state)
      local node = state.tree:get_node()
      local path = node:get_id()
      fn.setreg("+", path, "c")
    end,
    desc = desc_tag .. "Copy Path to Clipboard",
  },

  ["O"] = {
    function(state)
      require("lazy.util").open(state.tree:get_node().path, { system = true })
    end,
    desc = desc_tag .. "Open with System Application",
  },

  ["L"] = {
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
        notify("open_fm module not found: " .. mod, levels.ERROR)
        return
      end
      fm.open(state)
    end,
    desc = desc_tag .. "Open in system file manager",
  },

  ["[l"] = {
    function(state)
      local node = state.tree:get_node()
      if node then
        rel_path_to_require.copy_as_require(node, { relative = true })
      else
        vim.notify("No node under cursor", vim.log.levels.WARN)
      end
    end,
    desc = desc_tag .. "Copy Lua require() string(s) for current node (file or folder) to clipboard",
  },

  ["grep"] = {
    function(state)
      fzf_grep_picker.live_grep_node_dir(state)
    end,
    desc = desc_tag .. "fzf-lua: live_grep in node directory (Windows/WSL/macOS/Linux)",
  },

  -- ================= Traverse Updir/Downdir  ==========================

  ["+"] = {
    function(state)
      local node = state.tree:get_node()
      local path = node and (node.path or node:get_id()) or ""
      if path == "" then
        notify("no path under cursor", levels.WARN)
        return
      end
      local dir = (fn.isdirectory(path) == 1) and path or fn.fnamemodify(path, ":h")
      local ok, err = pcall(vim.api.nvim_set_current_dir, dir)
      if not ok then
        notify(("cd failed: %s"):format(tostring(err)), levels.ERROR)
        return
      end
      local ok_cmd, _ = pcall(require, "neo-tree.command")
      if ok_cmd then
        require("neo-tree.command").execute({ source = "filesystem", dir = dir, reveal = true })
      end
      notify(("cwd → %s"):format(dir), levels.INFO)
    end,
    desc = desc_tag .. "Set Neovim cwd to node and focus Neo-tree there",
  },

  ["-"] = {
    function(state)
      updir.up_one_level(state)
    end,
    desc = desc_tag .. "Up one level (in-place) and adjust CWD",
  },

  -- ================= Mark Operations (Fixed) =========================
  -- Note: <C-c> and <C-a> are problematic in Neovim terminals
  -- Using <leader>m prefix for mark operations instead

  -- Mark/Unmark single file
  ["m"] = function(state)
    commands.mark.toggle_mark(state)
  end,

  -- Mark all files in directory - using <leader>ma (m = mark, a = all)
  ["<S-m>"] = function(state)
    commands.mark.mark_all_in_directory(state)
  end,

  -- Clear all marks - using <leader>mc (m = mark, c = clear)
  ["<leader>mc"] = function(state)
    commands.mark.clear_all_marks(state)
  end,

  -- ================= Trash Operations =========================

  -- Delete marked files or file under cursor
  ["dd"] = function(state)
    trash.neotree_send_node_to_trash(state)
  end,

  -- Undo last trash (Shift+U)
  ["U"] = function(state)
    undo.neotree_undo_trash(state)
  end,

  -- Show trash history (optional)
  ["<leader>th"] = function(_)
    undo.show_history()
  end,

  -- ================ Path & File Lists Operations ===================

  -- copy paths to system clipboard
  ["[p"] = {
    function(state)
      local node = state.tree:get_node()
      local path = node and (node.path or node:get_id()) or ""
      if path == "" then
        notify("no path", levels.WARN)
        return
      end
      fn.setreg("+", path, "c")
      notify(("copied: %s"):format(path), levels.INFO)
    end,
    desc = desc_tag .. "Copy absolute path (+)",
  },

  ["]p"] = {
    function(state)
      local node = state.tree:get_node()
      local path = node and (node.path or node:get_id()) or ""
      if path == "" then
        notify("no path", levels.WARN)
        return
      end
      local base = fn.isdirectory(path) == 1 and path or fn.fnamemodify(path, ":h")
      fn.setreg("+", base, "c")
      notify(("copied: %s"):format(base), levels.INFO)
    end,
    desc = desc_tag .. "Copy base (dir) path (+)",
  },

  --- FIX: This is not relative, but absolute
  ["]r"] = {
    --- Copy the node's relative path to the system clipboard (+).
    --- Base preference: project root (utils.lv_project_root) → fallback to current working directory.
    ---@param state table
    function(state)
      local node = state.tree:get_node()
      local path, msg = path_helper(node, "relative", { base_dir = false })
      if not path then
        notify(msg, levels.WARN)
        return
      end
      fn.setreg("+", path, "c")
      notify(("Copied relative path: %s"):format(path), levels.INFO)
    end,
    desc = desc_tag .. "Copy relative path (+) (root→node or cwd→node)",
  },

  ["[r"] = {
    --- Copy the node's base directory (relative) to the system clipboard (+).
    --- Base preference: project root (utils.lv_project_root) → fallback to current working directory.
    ---@param state table
    function(state)
      local node = state.tree:get_node()
      local path, msg = path_helper(node, "relative", { base_dir = true })
      if not path then
        notify(msg, levels.WARN)
        return
      end
      fn.setreg("+", path, "c")
      notify(("Copied relative base dir: %s"):format(path), levels.INFO)
    end,
    desc = desc_tag .. "Copy relative base dir (+) (root→dir or cwd→dir)",
  },

  ["[f"] = {
    function(state)
      copy_node_folders_handler(state, { relative_to_cwd = false, preview_limit = 20 })
    end,
    desc = desc_tag .. "Copy recursive folder list (absolute paths) to clipboard (+)",
  },

  ["[F"] = {
    function(state)
      copy_node_folders_handler(state, { relative_to_cwd = true, preview_limit = 20 })
    end,
    desc = desc_tag .. "Copy recursive folder list (relative to cwd) to clipboard (+)",
  },

  ["[t"] = {
    function(state)
      copy_node_entries_handler(state, { relative_to_cwd = false, preview_limit = 20 })
    end,
    desc = desc_tag .. "Copy recursive file list (absolute paths) to clipboard (+)",
  },

  ["[T"] = {
    function(state)
      copy_node_entries_handler(state, { relative_to_cwd = true, preview_limit = 20 })
    end,
    desc = desc_tag .. "Copy recursive file list (relative to cwd) to clipboard (+)",
  },
}
