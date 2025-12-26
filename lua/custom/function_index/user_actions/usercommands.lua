---@module 'custom.function_index.user_actions.usercommands'
---@brief User command definitions for function_index

local M = {}

---Register user commands
function M.setup()
  local function_index = require("custom.function_index")

  -- Telescope commands with scope support
  vim.api.nvim_create_user_command("FunctionIndexTelescope", function(opts)
    local scope = opts.args == "%" and "buffer" or "cwd"
    function_index.telescope_functions_index(scope)
  end, {
    nargs = "?",
    complete = function()
      return { "%", "cwd" }
    end,
    desc = "[Function Index] Telescope picker. Args: % (buffer) or cwd (default)",
  })

  -- fzf-lua commands with scope support
  vim.api.nvim_create_user_command("FunctionIndexFzfLua", function(opts)
    local scope = opts.args == "%" and "buffer" or "cwd"
    function_index.fzf_functions_index(scope)
  end, {
    nargs = "?",
    complete = function()
      return { "%", "cwd" }
    end,
    desc = "[Function Index] fzf-lua picker. Args: % (buffer) or cwd (default)",
  })

  -- Generic command that auto-detects picker
  vim.api.nvim_create_user_command("FunctionIndex", function(opts)
    local scope = opts.args == "%" and "buffer" or "cwd"

    -- Default to Telescope if available, otherwise fzf-lua
    local has_telescope = pcall(require, "telescope")
    if has_telescope then
      function_index.telescope_functions_index(scope)
    else
      function_index.fzf_functions_index(scope)
    end
  end, {
    nargs = "?",
    complete = function()
      return { "%", "cwd" }
    end,
    desc = "[Function Index] Auto-detect picker. Args: % (buffer) or cwd (default)",
  })
end

return M
