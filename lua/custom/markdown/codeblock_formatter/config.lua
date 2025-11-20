---@module 'custom.markdown.codeblock_formatter.config'
--- Configuration for custom.markdown.codeblock_formatter
--- Provides default settings and alias mappings.
--- This module only exposes a `default` table that other modules require.
local M = {}

M.default = {
  notify_level = vim.log.levels.INFO,
  prefer_treesitter = true,
  ts_block_node = "fenced_code_block",
  -- language aliases (fence -> canonical formatter key)
  lang_aliases = {
    ts = "typescript",
    typescript = "typescript",
    js = "javascript",
    javascript = "javascript",
    py = "python",
    python = "python",
    lua = "lua",
    go = "go",
    c = "c",
    cpp = "cpp",
    cxx = "cpp",
  },
  -- default formatter registry is provided by formatters module and merged at setup time
}

return M
