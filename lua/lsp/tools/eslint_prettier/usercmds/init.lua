---@module 'lsp.tools.eslint_prettier.usercmds'
--- Create user commands like :EslintFix, :PrettierFormat, :LintAndFormat, :ToggleLintFormatOnSave
local api = vim.api
local core = require("lsp.tools.eslint_prettier.core.find_root")
local check = require("lsp.tools.eslint_prettier.core.check_config")
local eslint_fix = require("lsp.tools.eslint_prettier.eslint.fix")
local prettier_fmt = require("lsp.tools.eslint_prettier.prettier.format")

local M = {}

function M.attach(ctx)
  ctx = ctx or {}
  api.nvim_create_user_command("EslintFix", function()
    local bufnr = api.nvim_get_current_buf()
    local root = core(bufnr)
    if not check.has_eslint(root) then
      vim.notify("No eslint config found in project root; skipping", vim.log.levels.INFO)
      return
    end
    eslint_fix.eslint_fix(bufnr)
  end, { desc = "Run eslint_d --fix on current file (requires eslint config in project root)" })

  api.nvim_create_user_command("PrettierFormat", function()
    local bufnr = api.nvim_get_current_buf()
    local root = core(bufnr)
    if not check.has_prettier(root) then
      vim.notify("No prettier config found in project root; skipping", vim.log.levels.INFO)
      return
    end
    prettier_fmt.prettier_format(bufnr)
  end, { desc = "Run prettier --write on current file (requires prettier config in project root)" })

  api.nvim_create_user_command("LintAndFormat", function()
    local bufnr = api.nvim_get_current_buf()
    local root = core(bufnr)
    if check.has_eslint(root) then
      eslint_fix.eslint_fix(bufnr)
    end
    if check.has_prettier(root) then
      prettier_fmt.prettier_format(bufnr)
    end
  end, { desc = "Run eslint_d --fix then prettier --write on current file" })

  api.nvim_create_user_command("ToggleLintFormatOnSave", function()
    ctx._enabled = not not not not ctx._enabled -- placeholder if ctx is external
    -- better: toggle global in main module; user can call require('lsp.tools.eslint_prettier')._enabled = false
    vim.notify("Toggle autorun: use plugin.setup to change default programmatically", vim.log.levels.INFO)
  end, { desc = "Toggle automatic lint+format on save (toggle via API)" })
end

return M
