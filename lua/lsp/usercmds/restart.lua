---@module 'lsp.usercmds.restart'
--- LspRestartHere command implementation

local M = {}

local notify = require("lib.notify").create("[LSP.Restart] ")
local lsp = vim.lsp

--- Get clients attached to buffer
---@param bufnr integer|nil
---@return vim.lsp.Client[]
local function get_buffer_clients(bufnr)
  return lsp.get_clients({ bufnr = bufnr or 0 })
end

--- Start LSP server by name (with retry logic)
---@param name string
---@param bufnr integer|nil
---@return boolean success
local function start_lsp(name, bufnr)
  bufnr = bufnr or 0

  if not name or name == "" then
    return false
  end

  -- CRITICAL FIX: vim.lsp.enable expects an ARRAY!
  local ok = pcall(lsp.enable, {name})  -- ✅ {name} instead of name
  if ok then
    return true
  end

  -- Fallback: try lspconfig
  local ok_config, lspconfig = pcall(require, "lspconfig")
  if ok_config and lspconfig[name] then
    local ok_launch = pcall(function()
      lspconfig[name].launch()
    end)
    return ok_launch == true
  end

  return false
end

--- Execute LspRestartHere command
---@param args table vim.api.nvim_create_user_command args
---@return nil
function M.execute(args)
  local bufnr = 0
  local clients = get_buffer_clients(bufnr)

  if #clients == 0 then
    notify.info("No LSP clients to restart")
    return
  end

  if args.args and args.args ~= "" then
    -- Restart specific server
    local found = false
    for _, c in ipairs(clients) do
      if c.name == args.args then
        found = true
        lsp.stop_client(c.id, true)

        -- Delayed restart to allow cleanup
        vim.defer_fn(function()
          if start_lsp(args.args, bufnr) then
            notify.info(string.format("Restarted LSP: %s", args.args))
          else
            notify.error(string.format("Failed to restart LSP: %s", args.args))
          end
        end, 100)
        break
      end
    end

    if not found then
      notify.warn(string.format("LSP '%s' not running", args.args))
    end
  else
    -- Restart all servers
    local server_names = {}
    for _, c in ipairs(clients) do
      server_names[#server_names + 1] = c.name
    end

    local ids = {}
    for _, c in ipairs(clients) do
      ids[#ids + 1] = c.id
    end

    lsp.stop_client(ids, true)

    -- Delayed restart for all servers
    vim.defer_fn(function()
      local started = 0
      for _, name in ipairs(server_names) do
        if start_lsp(name, bufnr) then
          started = started + 1
        end
      end
      notify.info(string.format("Restarted %d/%d LSP server(s)", started, #server_names))
    end, 100)
  end
end

return M
