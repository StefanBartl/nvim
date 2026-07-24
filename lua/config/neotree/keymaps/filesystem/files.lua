---@module 'config.neotree.keymaps.filesystem.files'
--- File open, expand, and split-related mappings.

local notify = require("lib.nvim.notify").create("[cfg.neotree.keymaps.fs] ")
local node_utils = require("config.neotree.utils.node")
local safe_hide_preview = require("config.neotree.utils").safe_hide_preview

-- B, <S-CR>, gb, sg, sv, st removed: filetree.nvim's reveal_alt/open_variants
-- features own these now (default-on) and blindly overwrite via buffer-local
-- vim.keymap.set on FileType, so keeping a second native implementation here
-- was pure dead weight racing the same key -- same class of issue as the
-- old native `d`/trash duplicate (see keymaps/filesystem/init.lua).
-- <CR> and <2-LeftMouse> stay: filetree.nvim's `preview` feature explicitly
-- captures and wraps THIS <CR> handler as its non-image/PDF fallback
-- (see filetree/features/ui/preview/init.lua, `original_cr_cb`), so it is not
-- a duplicate -- removing it would silently downgrade <CR> to neo-tree's raw
-- default action and drop the window-picker integration below.
---@type table<string, any>
return {

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
}
