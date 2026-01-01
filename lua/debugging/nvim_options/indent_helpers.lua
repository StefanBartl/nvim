---@module 'debugging.nvim_options.indent_helpers'
--Helpers to inspect and toggle indentation providers in Neovim.
-- Usage:
-- :lua require("debugging.indent_helpers").print_indent_options()
-- :lua require("debugging.indent_helpers").prefer_treesitter_indent()

local M = {}

-- Print current indentation-related buffer options
function M.print_indent_options(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local opts = {
    autoindent = vim.api.nvim_get_option_value("autoindent", { buf = bufnr }),
    smartindent = vim.api.nvim_get_option_value("smartindent", { buf = bufnr }),
    cindent = vim.api.nvim_get_option_value("cindent", { buf = bufnr }),
    indentexpr = vim.api.nvim_get_option_value("indentexpr", { buf = bufnr }),
    indentkeys = vim.api.nvim_get_option_value("indentkeys", { buf = bufnr }),
    shiftwidth = vim.api.nvim_get_option_value("shiftwidth", { buf = bufnr }),
    tabstop = vim.api.nvim_get_option_value("tabstop", { buf = bufnr }),
  }
  print(vim.inspect(opts))
end

-- Simple toggle to prefer tree-sitter indent by disabling cindent/smartindent
function M.prefer_treesitter_indent(enable)
  enable = enable == nil and true or enable
  local ft = vim.bo.filetype
  if enable then
    vim.bo.cindent = false
    vim.bo.smartindent = false
  else
    -- restore defaults if desired; may want to be more selective
    vim.bo.cindent = false
    vim.bo.smartindent = false
  end
  print(("treesitter-prefer mode for %s set to %s"):format(ft, tostring(enable)))
end

return M
