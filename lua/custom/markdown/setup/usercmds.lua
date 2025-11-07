---@module 'custom.markdown.setup.usercmds'
---@description Provide routines to create buffer-local usercommands for Markdown buffers.

local M = {}

local api = vim.api
local handler = require("custom.markdown.handler")

--- Create or ensure a buffer-local usercommand named `OpenWithSystemApplication`.
--- This function is intended to be called from a FileType autocmd and receives the
--- autocmd event table (args) as provided by nvim_create_autocmd.
---@param args table
---@return nil
function M.apply(args)
  if type(args) ~= "table" or type(args.buf) ~= "number" then
    return
  end

  local bufnr = args.buf
  if not (api.nvim_buf_is_valid(bufnr) and api.nvim_buf_is_loaded(bufnr)) then
    return
  end

  -- Avoid creating the same buffer-local command twice.
  -- nvim_buf_get_commands returns a map of command definitions available to the buffer.
  local ok, cmds = pcall(api.nvim_buf_get_commands, bufnr, { builtin = false })
  if ok and cmds and cmds["OpenWithSystemApplication"] then
    return
  end

  pcall(function()
    api.nvim_buf_create_user_command(bufnr, "OpenWithSystemApplication",
      function()
        handler.handle_cursor_action()
      end,
      {
        desc = "[Custom.Markdown] Open image/url/file under cursor with system app",
        nargs = 0,
        complete = nil,
      }
    )
  end)
end

return M
