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

map("n", "<leader>ss", function()
	require("custom.last_file.last_session").save()
	vim.cmd "qa!"
end, { desc = "[General] Save last file and Force quit all" })
