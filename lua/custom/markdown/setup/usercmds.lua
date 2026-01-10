---@module 'custom.markdown.setup.usercmds'
--- Create buffer-local usercommands for Markdown buffers:
--- 1. OpenWithSystemApplication - Opens files/URLs under cursor
--- AUDIT: Hier wird buffer lokal implementiert, dass sollte aber bei allen mcustom.markdown Modulen sowieso bereits sein sein.

local M = {}
local api = vim.api
local handler = require("custom.markdown.handler")

--- Create all buffer-local usercommands for a Markdown buffer
---@param args table Autocmd args table (must contain buf field)
function M.apply(args)
  -- Validate input arguments
  if type(args) ~= "table" or type(args.buf) ~= "number" then
    return
  end

  local bufnr = args.buf

  -- Ensure buffer is valid and loaded
  if not (api.nvim_buf_is_valid(bufnr) and api.nvim_buf_is_loaded(bufnr)) then
    return
  end

  -- Get existing buffer commands to avoid duplicates
  local ok, cmds = pcall(api.nvim_buf_get_commands, bufnr, { builtin = false })
  if not ok then
    cmds = {}
  end

  -- Create OpenWithSystemApplication command if not exists
  if not cmds["OpenWithSystemApplication"] then
    pcall(function()
      api.nvim_buf_create_user_command(bufnr, "OpenWithSystemApplication", function()
        handler.handle_cursor_action()
      end, {
        desc = "[Custom.Markdown] Open image/url/file under cursor with system app",
        nargs = 0,
      })
    end)
  end
end

return M
