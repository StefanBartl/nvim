---@module 'config.neotree.keymaps'
--- Centralized, buffer-local Neo-tree keymaps that override defaults consistently.

local copy_node_entries_handler = require("config.neotree.helper.copy_node_entries_handler")
local copy_node_folders_handler = require("config.neotree.helper.copy_node_folders_handler")

-- Safe hide of Neo-tree's floating preview, ignoring errors.
---@param _ any
local function hide_preview_safe(_)
  pcall(function()
    require("neo-tree.sources.common.preview").hide()
  end)
end

-- ========= Window mappings (no nested tables; every key maps to a function/command) =========

---@return table<string, any>
return {
  -- basics
  ["q"] = "close_window",
  ["?"] = "show_help",
  ["g?"] = "noop",
  ["<leader>"] = "noop",
  -- clear filter, preview and search highlight
  ["<Esc>"] = function(state)
    require("neo-tree.sources.filesystem").reset_search(state, true)
    require("neo-tree.sources.filesystem.lib.filter_external").cancel()
    hide_preview_safe(state)
    vim.cmd("nohlsearch")
  end,
  ["<Tab>"] = "toggle_preview",
  ["<2-LeftMouse>"] = "open",

  ["<CR>"] = function(state)
    local node = state.tree:get_node()

    -- 1) expand/collapse directories
    if node and (node.type == "directory" or (node:has_children() and not node:is_expanded())) then
      state.commands.toggle_node(state)
      return
    end

    -- 2) normal open (prefer window-picker if present)
    hide_preview_safe(state)
    if pcall(require, "window-picker") then
      state.commands.open_with_window_picker(state)
    else
      state.commands.open(state)
    end
  end,

  -- background buffer add (no focus change, Neo-tree stays)
  ["<S-CR>"] = "open_badd",
  -- Fallback, falls <S-CR> im Terminal nicht erkannt wird:
  ["gb"] = "open_badd",

  ["C"] = "close_node",
  ["z"] = "close_all_nodes",
  ["<C-r>"] = "refresh",

  -- splits/tabs shorthand
  ["s"] = "noop",
  ["sv"] = "open_split",
  ["sg"] = "open_vsplit",
  ["st"] = "open_tabnew",

  -- source switching
  ["<S-Tab>"] = "prev_source",

  -- file ops via neo-tree clipboard
  ["c"] = "copy_to_clipboard",
  ["x"] = "cut_to_clipboard",
  ["p"] = "paste_from_clipboard",
  ["r"] = "rename",

  -- create/delete
  ["dd"] = function(state)
    require("config.neotree.trash").neotree_send_node_to_trash(state)
  end, -- default: ["dd"] = "delete",
  ["a"] = { "add", nowait = true, config = { show_path = "relative" } },
  ["A"] = { "add_directory", config = { show_path = "relative" } },

  -- preview toggle + scrolling (Neo-tree preview)
  ["<PageDown>"] = { "scroll_preview", config = { direction = -10 } },
  ["<PageUp>"] = { "scroll_preview", config = { direction = 10 } },
  ["<C-f>"] = { "scroll_preview", config = { direction = -1 } },
  ["<C-b>"] = { "scroll_preview", config = { direction = 1 } },

  -- copy paths to system clipboard
  ["[p"] = {
    function(state)
      local node = state.tree:get_node()
      local path = node and (node.path or node:get_id()) or ""
      if path == "" then
        vim.notify("no path", vim.log.levels.WARN)
        return
      end
      vim.fn.setreg("+", path, "c")
      vim.notify(("copied: %s"):format(path), vim.log.levels.INFO)
    end,
    desc = "Copy absolute path (+)",
  },

  ["]p"] = {
    function(state)
      local node = state.tree:get_node()
      local path = node and (node.path or node:get_id()) or ""
      if path == "" then
        vim.notify("no path", vim.log.levels.WARN)
        return
      end
      local base = vim.fn.isdirectory(path) == 1 and path or vim.fn.fnamemodify(path, ":h")
      vim.fn.setreg("+", base, "c")
      vim.notify(("copied: %s"):format(base), vim.log.levels.INFO)
    end,
    desc = "Copy base (dir) path (+)",
  },

  ["]r"] = {
    --- Copy the node's relative path to the system clipboard (+).
    --- Base preference: project root (utils.lv_project_root) → fallback to current working directory.
    ---@param state table
    function(state)
      local node = state.tree:get_node()
      local path = node and (node.path or node:get_id()) or ""
      if path == "" then
        vim.notify("no path", vim.log.levels.WARN)
        return
      end
      local base = (vim.uv or vim.loop).cwd() or vim.fn.getcwd()
      local ok_root, Root = pcall(require, "utils.lv_project_root")
      if ok_root and type(Root.get) == "function" then
        base = Root.get(0) or base
      end
      local rel = vim.fn.relpath(path, base)
      vim.fn.setreg("+", rel, "c")
      vim.notify(("copied: %s"):format(rel), vim.log.levels.INFO)
    end,
    desc = "Copy relative path (+) (root→node or cwd→node)",
  },

  ["[r"] = {
    --- Copy the node's base directory (relative) to the system clipboard (+).
    --- Base preference: project root (utils.lv_project_root) → fallback to current working directory.
    ---@param state table
    function(state)
      local node = state.tree:get_node()
      local path = node and (node.path or node:get_id()) or ""
      if path == "" then
        vim.notify("no path", vim.log.levels.WARN)
        return
      end
      local dir = (vim.fn.isdirectory(path) == 1) and path or vim.fn.fnamemodify(path, ":h")
      local base = (vim.uv or vim.loop).cwd() or vim.fn.getcwd()
      local ok_root, Root = pcall(require, "utils.lv_project_root")
      if ok_root and type(Root.get) == "function" then
        base = Root.get(0) or base
      end
      local rel = vim.fn.relpath(dir, base)
      vim.fn.setreg("+", rel, "c")
      vim.notify(("copied: %s"):format(rel), vim.log.levels.INFO)
    end,
    desc = "Copy relative base dir (+) (root→dir or cwd→dir)",
  },

  ["[f"] = {
    function(state)
      copy_node_folders_handler(state, { relative_to_cwd = false, preview_limit = 20 })
    end,
    desc = "Copy recursive folder list (absolute paths) to clipboard (+)",
  },

  ["[F"] = {
    function(state)
      copy_node_folders_handler(state, { relative_to_cwd = true, preview_limit = 20 })
    end,
    desc = "Copy recursive folder list (relative to cwd) to clipboard (+)",
  },

  ["[t"] = {
    function(state)
      copy_node_entries_handler(state, { relative_to_cwd = false, preview_limit = 20 })
    end,
    desc = "Copy recursive file list (absolute paths) to clipboard (+)",
  },

  ["[T"] = {
    function(state)
      copy_node_entries_handler(state, { relative_to_cwd = true, preview_limit = 20 })
    end,
    desc = "Copy recursive file list (relative to cwd) to clipboard (+)",
  },

  -- resize helper
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
    vim.cmd(new_width .. " wincmd |")
  end,

  ["Y"] = {
    function(state)
      local node = state.tree:get_node()
      local path = node:get_id()
      vim.fn.setreg("+", path, "c")
    end,
    desc = "Copy Path to Clipboard",
  },

  ["O"] = {
    function(state)
      require("lazy.util").open(state.tree:get_node().path, { system = true })
    end,
    desc = "Open with System Application",
  },

  ["M"] = {
    function(state)
      local is_wsl = require("lib.is_wsl")
      local mod
      if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
        mod = "config.neotree.open_fm.win"
      elseif is_wsl() then
        mod = "config.neotree.open_fm.wsl"
      else
        mod = "config.neotree.open_fm.unix_ubuntu"
      end
      local ok, fm = pcall(require, mod)
      if not ok then
        vim.notify("open_fm module not found: " .. mod, vim.log.levels.ERROR)
        return
      end
      fm.open(state)
    end,
    desc = "Open in system file manager",
  },

  ["+"] = {
    function(state)
      local node = state.tree:get_node()
      local path = node and (node.path or node:get_id()) or ""
      if path == "" then
        vim.notify("no path under cursor", vim.log.levels.WARN)
        return
      end
      local dir = (vim.fn.isdirectory(path) == 1) and path or vim.fn.fnamemodify(path, ":h")
      local ok, err = pcall(vim.api.nvim_set_current_dir, dir)
      if not ok then
        vim.notify(("cd failed: %s"):format(tostring(err)), vim.log.levels.ERROR)
        return
      end
      local ok_cmd, _ = pcall(require, "neo-tree.command")
      if ok_cmd then
        require("neo-tree.command").execute({ source = "filesystem", dir = dir, reveal = true })
      end
      vim.notify(("cwd → %s"):format(dir), vim.log.levels.INFO)
    end,
    desc = "Set Neovim cwd to node and focus Neo-tree there",
  },

  ["-"] = {
    function(state)
      require("config.neotree.updir").up_one_level(state)
    end,
    desc = "Up one level (in-place) and adjust CWD",
  },

  ["grep"] = {
    function(state)
      require("config.neotree.fzf_grep_picker").live_grep_node_dir(state)
    end,
    desc = "fzf-lua: live_grep in node directory (Windows/WSL/macOS/Linux)",
  },
}
