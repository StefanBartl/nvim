---@module 'config.neotree.keymaps.filesystem.preview'
--- Preview window control and scrolling.

---@type table<string, any>
return {
  -- ["<Tab>"] = {
    -- "toggle_preview",
    -- config = {
      -- use_float = true,
      -- use_snacks_image = true,
      -- use_image_nvim = true,
    -- },
  -- },

  ["<Tab>"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      local win = vim.api.nvim_get_current_win()
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].filetype ~= "neo-tree" then
        return
      end

      if not pcall(state.commands.toggle_preview, state) then
        local ok, preview = pcall(require, "neo-tree.sources.common.preview")
        if ok and preview.hide then
          preview.hide()
        end
      end
    end,
    desc = "Preview Mode",
  },

  ["<C-b>"] = { "scroll_preview", config = { direction = 1 } },
  ["<C-f>"] = { "scroll_preview", config = { direction = -1 } },
  ["<PageUp>"] = { "scroll_preview", config = { direction = 10 } },
  ["<PageDown>"] = { "scroll_preview", config = { direction = -10 } },
}
