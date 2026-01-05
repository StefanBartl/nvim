---@module 'lsp.usercmds.start'
--- LspStartHere command implementation

local M = {}

local notify = require("lib.notify").create("[LSP.Start] ")
local lsp = vim.lsp

--- Get filetype-to-server mapping
---@return table<string, string[]>
local function get_filetype_server_map()
  return {
    lua = { "lua_ls" },
    javascript = { "ts_ls", "eslint" },
    typescript = { "ts_ls", "eslint" },
    javascriptreact = { "ts_ls", "eslint" },
    typescriptreact = { "ts_ls", "eslint" },
    go = { "gopls" },
    markdown = { "marksman" },
    ["markdown.mdx"] = { "marksman" },
    html = { "html", "emmet_ls" },
    css = { "cssls" },
    json = { "jsonls" },
    sh = { "bashls" },
    bash = { "bashls" },
    zsh = { "bashls" },
    c = { "clangd" },
    cpp = { "clangd" },
    cs = { "omnisharp" },
    zig = { "zls" },
  }
end

--- Get servers for current buffer's filetype
---@param bufnr integer|nil
---@return string[]
local function get_servers_for_buffer(bufnr)
  bufnr = bufnr or 0
  local ft = vim.bo[bufnr].filetype
  if not ft or ft == "" then
    return {}
  end

  local map = get_filetype_server_map()
  return map[ft] or {}
end

--- Check if server is running for buffer
---@param server_name string
---@param bufnr integer|nil
---@return boolean
local function is_server_running(server_name, bufnr)
  local clients = lsp.get_clients({ bufnr = bufnr or 0 })
  for _, c in ipairs(clients) do
    if c.name == server_name then
      return true
    end
  end
  return false
end

--- Start LSP server by name - triggers the server module which handles everything
---@param name string
---@param bufnr integer
---@return boolean success
local function start_lsp(name, bufnr)
  if not name or name == "" then
    notify.warn("No LSP name provided")
    return false
  end

  -- Check if already running
  if is_server_running(name, bufnr) then
    notify.info(string.format("LSP '%s' already running", name))
    return true
  end

  -- Strategy: Load the server module and let IT call vim.lsp.enable
  -- This is how it works in init.lua and it DOES work there!
  local ok_mod, server_mod = pcall(require, "lsp.servers." .. name)
  if not ok_mod or type(server_mod) ~= "table" or type(server_mod.setup) ~= "function" then
    notify.error(string.format("Server module 'lsp.servers.%s' not found or invalid", name))
    return false
  end

  -- Get shared config (same as init.lua does)
  local shared = {}

  local ok_caps, caps = pcall(require, "lsp.core.capabilities")
  if ok_caps and type(caps.get) == "function" then
    shared.capabilities = caps.get()
  else
    shared.capabilities = lsp.protocol.make_client_capabilities()
  end

  local ok_attach, attach = pcall(require, "lsp.core.attach")
  if ok_attach and type(attach.build) == "function" then
    local api = attach.build({ use_workspace_diagnostics = true, use_lazydev = true })
    shared.on_attach = api.on_attach
    shared.on_init = api.on_init
  else
    shared.on_attach = function() end
    shared.on_init = function() return true end
  end

  -- Call setup with enable=true (force enable)
  local ok_setup = pcall(server_mod.setup, shared, { enable = true })

  if not ok_setup then
    notify.error(string.format("Failed to setup server '%s'", name))
    return false
  end

  -- Give it a moment to attach
  vim.defer_fn(function()
    if is_server_running(name, bufnr) then
      notify.info(string.format("Started & attached LSP: %s", name))
    else
      notify.warn(string.format("Server '%s' setup called but not yet attached. Check :LspLog", name))
    end
  end, 200)

  return true
end

--- Execute LspStartHere command
---@param args table vim.api.nvim_create_user_command args
---@return nil
function M.execute(args)
  local bufnr = 0

  if args.args and args.args ~= "" then
    -- Start specific server
    start_lsp(args.args, bufnr)
  else
    -- Auto-detect based on filetype
    local servers = get_servers_for_buffer(bufnr)
    if #servers == 0 then
      local ft = vim.bo[bufnr].filetype
      notify.warn(string.format("No LSP configured for filetype '%s'", ft or "none"))
      return
    end

    local started = 0
    for _, name in ipairs(servers) do
      if start_lsp(name, bufnr) then
        started = started + 1
      end
    end

    notify.info(string.format("Started %d/%d LSP server(s)", started, #servers))
  end
end

return M
