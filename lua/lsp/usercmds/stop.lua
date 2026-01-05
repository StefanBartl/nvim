---@module 'lsp.usercmds.stop'
--- LspStopHere command implementation

local M = {}

local notify = require("lib.notify").create("[LSP.Stop] ")
local lsp = vim.lsp

--- Get clients attached to buffer
---@param bufnr integer|nil
---@return vim.lsp.Client[]
local function get_buffer_clients(bufnr)
  return lsp.get_clients({ bufnr = bufnr or 0 })
end

--- Execute LspStopHere command
---@param args table vim.api.nvim_create_user_command args
---@return nil
function M.execute(args)
  local bufnr = 0

  if args.args and args.args ~= "" then
    -- Stop specific server
    local clients = get_buffer_clients(bufnr)
    local found = false

    for _, c in ipairs(clients) do
      if c.name == args.args then
        lsp.stop_client(c.id, true)
        found = true
        notify.info(string.format("Stopped LSP: %s", args.args))
        break
      end
    end

    if not found then
      notify.warn(string.format("LSP '%s' not running", args.args))
    end
  else
    -- Stop all servers
    local ids = {}
    for _, c in ipairs(get_buffer_clients(bufnr)) do
      ids[#ids + 1] = c.id
    end

    if #ids > 0 then
      lsp.stop_client(ids, true)
      notify.info(string.format("Stopped %d LSP client(s)", #ids))
    else
      notify.info("No LSP clients running")
    end
  end
end

return M
