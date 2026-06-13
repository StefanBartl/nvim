---@module 'custom.markdown.setup.usercmds'
--- Creates all markdown related user commands.

local M = {}

local api = vim.api

local handler = require("custom.markdown.handler")
local markdown_commands = require("custom.markdown.commands")

--- Create OpenWithSystemApplication command
---@param bufnr integer
local function create_open_command(bufnr)
  local ok, cmds = pcall(api.nvim_buf_get_commands, bufnr, {
    builtin = false,
  })

  if not ok then
    ---@diagnostic disable-next-line: missing-fields
    cmds = {}
  end

  if cmds["OpenWithSystemApplication"] then
    return
  end

  api.nvim_buf_create_user_command(bufnr, "OpenWithSystemApplication", function()
    handler.handle_cursor_action()
  end, {
    desc = "[Custom.Markdown] Open image/url/file under cursor",
    nargs = 0,
  })
end

--- Create global Markdown command dispatcher
local function create_markdown_command()
  local exists = vim.fn.exists(":Markdown") == 2

  if exists then
    return
  end

  vim.api.nvim_create_user_command("Markdown", function(opts)
    markdown_commands.execute(opts.fargs)
  end, {
    nargs = "*",
    complete = function(arglead, cmdline, cursorpos)
      return markdown_commands.complete(arglead, cmdline, cursorpos)
    end,

    desc = "[Custom.Markdown] Markdown utility commands",
  })
end

--- Create all commands for markdown buffers
---@param args table
function M.apply(args)
  if type(args) ~= "table" or type(args.buf) ~= "number" then
    return
  end

  local bufnr = args.buf

  if not (api.nvim_buf_is_valid(bufnr) and api.nvim_buf_is_loaded(bufnr)) then
    return
  end

  create_open_command(bufnr)
  create_markdown_command()
end

return M
