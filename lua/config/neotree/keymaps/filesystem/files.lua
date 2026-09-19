---@module 'config.neotree.keymaps.filesystem.files'
--- File open, expand, and split-related mappings.

local notify = require("lib.nvim.notify").create("[cfg.neotree.keymaps.fs] ")

-- B, <S-CR>, gb, sg, sv, st removed: filetree.nvim's reveal_alt/open_variants
-- features own these now (default-on) and blindly overwrite via buffer-local
-- vim.keymap.set on FileType, so keeping a second native implementation here
-- was pure dead weight racing the same key -- same class of issue as the
-- old native `d`/trash duplicate (see keymaps/filesystem/init.lua).
-- <CR> and <2-LeftMouse> stay: filetree.nvim's `preview` feature explicitly
-- captures and wraps THIS <CR> handler as its non-image/PDF fallback
-- (see filetree/features/ui/preview/init.lua, `original_cr_cb`), so it is not
-- a duplicate -- removing it would silently downgrade <CR> to neo-tree's raw
-- default action and drop the window-picker integration below. The
-- `pcall(require, "window-picker")` guard below no longer describes an
-- optional external plugin (`s1n7ax/nvim-window-picker` left 2026-09-19,
-- external-plugins report) -- ui.nvim now ships a `require("window-picker")`
-- compatibility shim over `ui.windowpicker`, always present once ui.nvim is
-- loaded. Left as a real pcall anyway: this file has no business knowing
-- whether that shim continues to exist, only what to do if it doesn't.
---@type table<string, any>
return {

  ["<CR>"] = {
    ---@param state table  neo-tree's own state; `state.tree:get_node()` is the cursor node
    function(state)
      local tree = state and state.tree
      local node = tree and tree:get_node() or nil
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

      -- A native preview left open would otherwise stay on screen next to
      -- the file that just opened.
      pcall(function()
        require("neo-tree.sources.common.preview").hide()
      end)

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
