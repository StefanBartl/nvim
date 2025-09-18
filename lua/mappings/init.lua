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

---Setup all mapping modules
---@return nil
function M.setup()
  vim.g.__map_helper = map

	require("mappings.buf_win_tab").setup()
	require("mappings.custom").setup()
	require("mappings.contextmenu").setup()
	require("mappings.dbg_messages").setup()
	require("mappings.editing").setup()
	require("mappings.experimental").setup()
	require("mappings.extra_diagnostics").setup()
	require("mappings.fzf").setup()
  require("mappings.general").setup()
	require("mappings.git").setup()
	require("mappings.harpoon").setup()
  require("mappings.lsp").setup()
	require("mappings.markdown").setup()
  require("mappings.noice").setup()
	require("mappings.nvchad").setup()
	require("mappings.neotree").setup()
	require("lua.mappings.smart_del_key").setup({ set_cr = true })
	require("mappings.sourrounding").setup()
	require("mappings.telescope").setup()
	require("mappings.terminal").setup()
	require("mappings.trouble").setup()

	vim.g.__map_helper = nil
end

return M
