---@module 'custom.picker_fd_depth.usercmds'
---@brief Custom user commands for the depth-based file picker.

local M = {}

--- Enable and register the UserCommand using the custom framework library.
---@return nil
function M.enable()
  -- Safely import the library module and extract its specific '.create' function method
  local ok, lib_usercmd = pcall(require, "lib.usercmd")
  local create_cmd = (ok and lib_usercmd and lib_usercmd.create) or vim.api.nvim_create_user_command

  create_cmd("FindFiles", function(opts)
    local args = opts.fargs
    local depth = args[1] or 0
    local engine = args[2] or "telescope"

    -- Performance: Lazy loading the core logic only on execution
    require("custom.picker_fd_depth.core").find_files(depth, engine)
  end, {
    nargs = "*",
    desc = "Search files across directories. Syntax: :FindFiles [depth] [telescope/fzf]",
    complete = function(ArgLead, CmdLine, _)
      local words = vim.split(CmdLine, "%s+")
      if #words == 3 then
        return vim.tbl_filter(function(item)
          return item:find("^" .. ArgLead)
        end, { "telescope", "fzf" })
      end
    end,
  })
end

return M
