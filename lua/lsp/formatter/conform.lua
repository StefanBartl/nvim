---@module 'lsp.formatter.conform'
---@class ConformPolicy

local M = {}

---@return nil
function M.setup()
  local ok, conform = pcall(require, "conform")
  if not ok then return end

  conform.setup({
    formatters_by_ft = {
      lua = { "stylua" },
      go = { "goimports", "gofmt" },
      javascript = { "prettierd", "prettier" },
      typescript = { "prettierd", "prettier" },
      typescriptreact = { "prettierd", "prettier" },
      javascriptreact = { "prettierd", "prettier" },
      json = { "jq" },
      css = { "prettierd", "prettier" },
      html = { "prettierd", "prettier" },
      zig = { "zigfmt" },
      c = { "clang_format" },
      cpp = { "clang_format" },
      cs = { "csharpier" },
    },
    notify_on_error = true,
  })
end

return M
