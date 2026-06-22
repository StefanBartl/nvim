---@module 'lsp.usercmds.stop'
--- LspStopHere command implementation

local M = {}

local notify = require("lib.nvim.notify").create("[LSP.Stop] ")
local lsp = vim.lsp

--- Get clients attached to buffer
---@param bufnr integer|nil
---@return vim.lsp.Client[]
local function get_buffer_clients(bufnr)
  return lsp.get_clients({ bufnr = bufnr or 0 })
end

--- Gracefully stop client with timeout
---@param client_id integer
---@param timeout_ms integer|nil
---@return boolean success
local function graceful_stop(client_id, timeout_ms)
  timeout_ms = timeout_ms or 3000

  -- Request graceful shutdown
  local ok = pcall(lsp.stop_client, client_id, false) -- false = graceful

  if not ok then
    -- Force stop if graceful fails
    pcall(lsp.stop_client, client_id, true)
    return false
  end

  -- Wait for graceful shutdown
  local deadline = vim.loop.now() + timeout_ms
  while vim.loop.now() < deadline do
    local client = lsp.get_client_by_id(client_id)
    if not client or client.is_stopped() then
      return true
    end
    vim.wait(100)
  end

  -- Force stop if timeout
  pcall(lsp.stop_client, client_id, true)
  return false
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
        graceful_stop(c.id)
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
      for _, id in ipairs(ids) do
        graceful_stop(id)
      end
      notify.info(string.format("Stopped %d LSP client(s)", #ids))
    else
      notify.info("No LSP clients running")
    end
  end
end

return M
