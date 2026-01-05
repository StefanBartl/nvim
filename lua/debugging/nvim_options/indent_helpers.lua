---@module 'debugging.nvim_options.indent_helpers'
-- Helpers to inspect and toggle indentation providers in Neovim.
-- Usage:
-- :lua require("debugging.indent_helpers").print_indent_options()
-- :lua require("debugging.indent_helpers").prefer_treesitter_indent()
-- or
-- use usercommands

local M = {}

local api = vim.api

-- Print current indentation-related buffer options
---@param bufnr integer? Buffer number, defaults to current buffer
function M.print_indent_options(bufnr)
  bufnr = bufnr or api.nvim_get_current_buf()
  local opts = {
    autoindent = api.nvim_get_option_value("autoindent", { buf = bufnr }),
    smartindent = api.nvim_get_option_value("smartindent", { buf = bufnr }),
    cindent = api.nvim_get_option_value("cindent", { buf = bufnr }),
    indentexpr = api.nvim_get_option_value("indentexpr", { buf = bufnr }),
    indentkeys = api.nvim_get_option_value("indentkeys", { buf = bufnr }),
    shiftwidth = api.nvim_get_option_value("shiftwidth", { buf = bufnr }),
    tabstop = api.nvim_get_option_value("tabstop", { buf = bufnr }),
  }
  print(vim.inspect(opts))
end

-- Simple toggle to prefer tree-sitter indent by disabling cindent/smartindent
---@param enable boolean? Enable or disable tree-sitter preference, default true
function M.prefer_treesitter_indent(enable)
  enable = enable == nil and true or enable
  local ft = vim.bo.filetype
  if enable then
    vim.bo.cindent = false
    vim.bo.smartindent = false
  else
    -- Restore default behavior; currently disables tree-sitter preference
    vim.bo.cindent = true
    vim.bo.smartindent = true
  end
  print(("treesitter-prefer mode for %s set to %s"):format(ft, tostring(enable)))
end

-- Create user commands for the module
---@return nil
function M.enable()
  -- Command to print current indentation options
  api.nvim_create_user_command("DebugPrintIndentOptions", function()
    M.print_indent_options()
  end, {
    desc = "[debugging.nvim-options] Print indent options",
    nargs = 0,
  })

  -- Command to toggle tree-sitter indent preference
  api.nvim_create_user_command("DebugPreferTreesitterIndent", function(opts)
    local enable = true
    if opts.args == "false" or opts.args == "0" then
      enable = false
    end
    M.prefer_treesitter_indent(enable)
  end, {
    desc = "[debugging.nvim-options] Prefer tree-sitter indent (disable cindent/smartindent)",
    nargs = "?",
    complete = function()
      return { "true", "false", "1", "0" }
    end,
  })
end

return M
