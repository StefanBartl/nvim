---@module 'mappings'
---@brief Entry point to register all keymaps grouped by topic.

local M = {}

---Setup all mapping modules
---@return nil
function M.setup()
  vim.g.__map_helper = require("lib.map")

  require("mappings.buf_win_tab").setup()
  require("mappings.buffer_jump").setup()
  require("mappings.custom").setup()
  require("mappings.ctrl_cycle").setup()
  require("mappings.editing").setup()
  require("mappings.experimental").setup()
  require("mappings.fzf").setup()
  require("mappings.general").setup()
  require("mappings.git").setup()
  require("mappings.harpoon").setup()
  require("mappings.lsp").setup()
  require("mappings.markdown").setup()
  require("mappings.noice").setup()
  require("mappings.nvchad").setup()
  require("mappings.smart_del_key").setup({ set_cr = true })
  require("mappings.sourrounding").setup()
  require("mappings.telescope").setup()
  require("mappings.terminal").setup()
  require("mappings.toggle_comment").setup()
  require("mappings.trouble").setup()
  require("mappings.window_orientation").setup()

  -- require("mappings.view_scroll").map_default_keys('<C-d>', '<C-u>')

  vim.g.__map_helper = nil
end

return M
