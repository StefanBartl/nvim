---@module 'mappings'
---@brief Entry point to register all keymaps grouped by topic.

local M = {}

---Convenience wrapper for vim.keymap.set with sane defaults.
---@param modes string|string[]
---@param lhs string
---@param rhs string|function
---@param opts table|nil
local function map(modes, lhs, rhs, opts)
  opts = opts or {}
  if opts.noremap == nil then opts.noremap = true end
  if opts.silent == nil then opts.silent = true end
  vim.keymap.set(modes, lhs, rhs, opts)
end

---Setup all mapping modules (safe to call multiple times).
---@return nil
function M.setup()
  -- provide map helper for submodules
  vim.g.__map_helper = map

  require("mappings.general_mappings").setup()
  require("mappings.fzf_mappings").setup()
  require("mappings.telescope_mappings").setup()
  require("mappings.lsp_mappings").setup()
  require("mappings.trouble_mappings").setup()
  require("mappings.utils_mappings").setup()
  require("mappings.buf_win_tab_mappings").setup()
  require("mappings.git_mappings").setup()
  require("mappings.harpoon_mappings").setup()
  require("mappings.editing_mappings").setup()
  require("mappings.terminal_mappings").setup()
  require("mappings.noice_mappings").setup()
  require("mappings.custom_mappings").setup()
  require("mappings.nvchad_mappings").setup()
  require("mappings.contextmenu_mappings").setup()
  require("mappings.extra_diagnostics").setup()
  require("mappings.test_mappings").setup()

  vim.g.__map_helper = nil
end

return M
