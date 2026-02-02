---@module 'config.neotree.keymaps.filesystem.files'
--- File open, expand, and split-related mappings.

local notify = require("lib.notify").create("[cfg.neotree.keymaps.fs] ")
local node_utils = require("config.neotree.utils.node")
local safe_hide_preview = require("config.neotree.utils").safe_hide_preview

---@type table<string, any>
return {

  -- FIX: DAS CRASHED
  -- Reveal alternate buffer file (wie :e #)
  ["B"] = {
    ---@param state Cfg.NeoTree.State
    function(_)
      safe_hide_preview()

      -- Get alternate buffer path (:e # semantics)
      local _, filepath = require("lib.buffer.get_alternate")()
      if not filepath or filepath == "" then
        notify.warn("No alternate buffer to reveal (try opening a file first)")
        return
      end

      -- Ensure the path is valid
      if vim.fn.filereadable(filepath) ~= 1 and vim.fn.isdirectory(filepath) ~= 1 then
        notify.warn("Alternate buffer is not a readable file")
        return
      end

      -- IMPORTANT:
      -- neo-tree.command is not guaranteed to be require-able depending on
      -- plugin lazy-loading and runtimepath state.
      -- The Neotree command interface is always available via :Neotree.
      --
      -- vim.cmd.Neotree(...) uses the same command parser internally
      -- (handle_reveal, do_show_or_focus, etc.).
      vim.cmd.Neotree({
        action = "focus",
        source = "filesystem",
        reveal_file = filepath,
        reveal_force_cwd = true,
      })

      local filename = vim.fn.fnamemodify(filepath, ":t")
      notify.info(("Revealed: %s"):format(filename))
    end,
    desc = "Reveal alternate buffer file (like :e #)",
  },

  -- FIX: DAS CRASHED
  -- Reveal current file (wenn man in einem File-Buffer ist und dann Neo-tree öffnet)
  ["<leader>b"] = {
    function(state)
      safe_hide_preview()

      -- Aktuellen Buffer holen (der vor Neo-tree war)
      local current_buf = vim.fn.bufnr("#")

      if current_buf == -1 or not vim.api.nvim_buf_is_valid(current_buf) then
        notify.warn("No previous buffer")
        return
      end

      local file = vim.api.nvim_buf_get_name(current_buf)
      if file == "" then
        notify.warn("Previous buffer has no file")
        return
      end

      state.commands.reveal_file(state, file)
      notify.info(("Revealed: %s"):format(vim.fn.fnamemodify(file, ":t")))
    end,
    desc = "Reveal current/previous buffer",
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
