---@module 'config.neotree.keymaps.filesystem.files'
--- File open, expand, and split-related mappings.

local notify = require("lib.nvim.notify").create("[cfg.neotree.keymaps.fs] ")
local node_utils = require("config.neotree.utils.node")
local safe_hide_preview = require("config.neotree.utils").safe_hide_preview

---@type table<string, any>
return {

  -- Reveal alternate buffer file
  ["B"] = {
    ---@param state Cfg.NeoTree.State
    ---@diagnostic disable-next-line: unused-local
    function(state)
      safe_hide_preview()

      -- Get alternate buffer path (:e # semantics)
      local _, filepath = require("lib.nvim.buffer.get_alternate")()
      if not filepath or filepath == "" then
        notify.warn("No buffer to reveal (try opening a file first)")
        return
      end

      -- Ensure the path is valid
      if vim.fn.filereadable(filepath) ~= 1 and vim.fn.isdirectory(filepath) ~= 1 then
        notify.warn("buffer is not a readable file")
        return
      end

      -- Normalize to absolute path (mandatory for Neo-tree matching)
      filepath = vim.fn.fnamemodify(filepath, ":p")

      -- Execute Neo-tree reveal via internal command API
      require("neo-tree.command").execute({
        action = "focus", -- open and focus Neo-tree
        source = "filesystem", -- explicitly target filesystem source
        reveal_file = filepath, -- file or directory to reveal
        reveal_force_cwd = true, -- adjust root if file is outside cwd
      })
    end,

    desc = "Reveal buffer file (like :e #)",
  },

  ["<CR>"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      local node = node_utils.get_current(state)
      if not node then
        notify.info("no node under cursor")
        return
      end

      local win = vim.api.nvim_get_current_win()
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].filetype ~= "neo-tree" then
        notify.warn("Neo-tree: Not in a Neo-tree window")
        return
      end

      safe_hide_preview()

      if node.type == "directory" or (node.has_children and not node.is_expanded) then
        state.commands.toggle_node(state)
        return
      end

      if pcall(require, "window-picker") then
        if not pcall(state.commands.open_with_window_picker, state) then
          pcall(state.commands.open, state)
        end
      else
        pcall(state.commands.open, state)
      end
    end,
    desc = "Safe expand / collapse nodes and open files",
  },

  ["<2-LeftMouse>"] = "open",
  ["<S-CR>"] = "open_badd",
  ["gb"] = "open_badd",

  ["sg"] = "open_vsplit",
  ["sv"] = "open_split",
  ["st"] = "open_tabnew",
}
