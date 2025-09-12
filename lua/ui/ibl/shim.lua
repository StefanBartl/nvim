---@module 'ui.ibl.shim'
--- Create back-compat highlight groups before ibl runs on ColorScheme.

local aug = vim.api.nvim_create_augroup("ibl_compat_shims", { clear = true })

vim.api.nvim_create_autocmd("ColorScheme", {
  group = aug,
  pattern = "*",
  callback = function()
    -- Define base groups with safe defaults (won't override a theme due to `default=true`)
    pcall(vim.api.nvim_set_hl, 0, "IblIndent",     { link = "LineNr",       default = true })      -- base indent
    pcall(vim.api.nvim_set_hl, 0, "IblWhitespace", { link = "NonText",      default = true })      -- blanks
    pcall(vim.api.nvim_set_hl, 0, "IblScope",      { link = "CursorLineNr", default = true })      -- scope guide
    -- Back-compat for older configs: make IblChar an alias of IblIndent
    pcall(vim.api.nvim_set_hl, 0, "IblChar",       { link = "IblIndent",    default = true })
  end,
  desc = "Ensure IBL highlight groups exist before other ColorScheme handlers",
})

