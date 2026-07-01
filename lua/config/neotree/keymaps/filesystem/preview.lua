---@module 'config.neotree.keymaps.filesystem.preview'
---@brief Standard Neo-tree preview window control and scroll keymaps.
---@description
--- Provides the generic <Tab> toggle-preview handler and scroll bindings.
--- This module is overridden for image nodes by images.lua and for PDF nodes
--- by pdfport.lua via the parent init.lua merge order.

---@type table<string, any>
return {

  -- Toggle the floating preview window for the node under the cursor.
  -- Falls back to explicitly hiding the preview when the command errors,
  -- which can happen when no preview is currently visible.
  ["<Tab>"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      local win = vim.api.nvim_get_current_win()
      local buf = vim.api.nvim_win_get_buf(win)

      -- Guard: only act when focus is inside a Neo-tree buffer.
      if vim.bo[buf].filetype ~= "neo-tree" then return end

      if not pcall(state.commands.toggle_preview, state) then
        -- toggle_preview may error when there is nothing to close; hide manually.
        local ok, preview = pcall(require, "neo-tree.sources.common.preview")
        if ok and preview.hide then preview.hide() end
      end
    end,
    desc = "Preview: toggle floating preview window",
  },

  ["<C-b>"]      = { "scroll_preview", config = { direction =   1 } },
  ["<C-f>"]      = { "scroll_preview", config = { direction =  -1 } },
  ["<PageUp>"]   = { "scroll_preview", config = { direction =  10 } },
  ["<PageDown>"] = { "scroll_preview", config = { direction = -10 } },
}
