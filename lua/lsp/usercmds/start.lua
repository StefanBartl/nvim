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

--- Start LSP server by name
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

  -- CRITICAL FIX: vim.lsp.enable expects an ARRAY, not a string!
  local ok = pcall(lsp.enable, {name})  -- ✅ {name} instead of name
  if ok then
    notify.info(string.format("Started LSP: %s", name))
    return true
  end

  -- Fallback: try lspconfig (for older Neovim or if native API fails)
  local ok_config, lspconfig = pcall(require, "lspconfig")
  if ok_config and lspconfig[name] then
    local ok_launch = pcall(function()
      lspconfig[name].launch()
    end)
    if ok_launch then
      notify.info(string.format("Started LSP: %s (via lspconfig)", name))
      return true
    end
  end

  notify.error(string.format("Failed to start LSP: %s", name))
  return false
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
