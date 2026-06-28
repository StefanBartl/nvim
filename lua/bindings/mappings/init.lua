---@module 'bindings.mappings'
---@brief Entry point to register all keymaps grouped by topic.

local M = {}

---Setup all mapping modules
---@return nil
function M.setup()
  vim.g.__map_helper = require("lib.nvim.map")

  require("bindings.mappings.buf_win_tab").setup()
  require("bindings.mappings.buffer_jump").setup()
  require("bindings.mappings.custom").setup()
  require("bindings.mappings.ctrl_cycle").setup()
  require("bindings.mappings.editing").setup()
  require("bindings.mappings.fzf").setup()
  require("bindings.mappings.general").setup()
  require("bindings.mappings.git").setup()
  require("bindings.mappings.harpoon").setup()
  require("bindings.mappings.lsp").setup()
  require("bindings.mappings.noice").setup()
  require("bindings.mappings.nvchad").setup()
  require("bindings.mappings.smart_del_key").setup({ set_cr = true })
  require("bindings.mappings.sourrounding").setup()
  require("bindings.mappings.telescope").setup()
  require("bindings.mappings.terminal").setup()
  require("bindings.mappings.toggle_comment").setup()
  require("bindings.mappings.trouble").setup()
  require("bindings.mappings.window_orientation").setup()

  -- require("bindings.mappings.view_scroll").map_default_keys('<C-d>', '<C-u>')

  vim.g.__map_helper = nil
end

return M
