---@module 'ui.ibl'
--- Modern ibl setup with resilient highlights for any colorscheme.

local ok_ibl, ibl = pcall(require, "ibl")
if not ok_ibl then
  return
end

local ok_hooks, hooks = pcall(require, "ibl.hooks")
if ok_hooks then
  hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
    -- Define defaults; `default=true` prevents overriding theme-defined groups
    vim.api.nvim_set_hl(0, "IblIndent",     { link = "LineNr",       default = true })
    vim.api.nvim_set_hl(0, "IblWhitespace", { link = "NonText",      default = true })
    vim.api.nvim_set_hl(0, "IblScope",      { link = "CursorLineNr", default = true })
    -- Optional back-compat alias in case some code still uses "IblChar"
    vim.api.nvim_set_hl(0, "IblChar",       { link = "IblIndent",    default = true })
  end)
end

ibl.setup({
  indent = {
    char = "│",                    -- choose any char you like
    highlight = { "IblIndent" },   -- use official group name
  },
  whitespace = {
    highlight = { "IblWhitespace" },
  },
  scope = {
    enabled = true,
    show_start = false,
    show_end   = false,
    highlight  = { "IblScope" },
  },
})

