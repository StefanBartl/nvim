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

--- Start LSP server by name with async attachment check
---@param name string
---@param bufnr integer|nil
---@return boolean success
local function start_lsp(name, bufnr)
  bufnr = bufnr or 0

  if not name or name == "" then
    notify.warn("No LSP name provided")
    return false
  end

  -- Check if already running
  if is_server_running(name, bufnr) then
    notify.info(string.format("LSP '%s' already running", name))
    return true
  end

  -- Try native API first
  local ok, err = pcall(lsp.enable, name)

  if not ok then
    notify.error(string.format("Failed to enable LSP '%s': %s", name, tostring(err)))

    -- Fallback: try lspconfig
    local ok_config, lspconfig = pcall(require, "lspconfig")
    if ok_config and lspconfig[name] then
      pcall(lspconfig[name].launch)
      notify.info(string.format("Started LSP: %s (via lspconfig fallback)", name))
      return true
    end

    return false
  end

  -- Success case: schedule async check
  notify.info(string.format("LSP '%s' setup called, waiting for attachment...", name))

  -- Check attachment after short delay (LSP startup is async)
  vim.defer_fn(function()
    if is_server_running(name, bufnr) then
      notify.info(string.format("✓ LSP '%s' attached successfully", name))
    else
      notify.warn(string.format(
        "⚠ LSP '%s' setup completed but not yet attached. Check buffer filetype or :LspLog for errors",
        name
      ))
    end
  end, 1500) -- 1.5s delay for server startup

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
