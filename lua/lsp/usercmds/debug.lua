---@module 'lsp.usercmds.debug'
--- Debug utilities for LSP usercommands

local M = {}

local api = vim.api
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

--- Get configured servers
---@return string[]
local function get_configured_servers()
  local ok, reg = pcall(require, "lsp.core.registry")
  if ok and type(reg) == "table" and type(reg.ACTIVE) == "table" then
    return vim.deepcopy(reg.ACTIVE)
  end
  return {}
end

--- Get servers registered in vim.lsp.config
---@return string[]
local function get_registered_configs()
  if type(lsp.config) ~= "table" or not lsp.config.get then
    return {}
  end

  local configs = lsp.config.get() or {}
  local names = {}
  for _, cfg in pairs(configs) do
    if cfg.name then
      names[#names + 1] = cfg.name
    end
  end
  table.sort(names)
  return names
end

--- Execute debug info command
---@return nil
function M.execute()
  local bufnr = 0
  local ft = vim.bo[bufnr].filetype
  local map = get_filetype_server_map()
  local expected = map[ft] or {}
  local configured = get_configured_servers()
  local registered = get_registered_configs()
  local running = {}

  for _, c in ipairs(lsp.get_clients({ bufnr = bufnr })) do
    running[#running + 1] = c.name
  end

  local lines = {
    "LSP UserCommands Debug Info",
    "============================",
    "",
    string.format("Buffer:   %d", bufnr),
    string.format("Filetype: %s", ft or "none"),
    "",
    "1. Expected servers for this filetype:",
  }

  if #expected > 0 then
    for _, name in ipairs(expected) do
      table.insert(lines, string.format("   • %s", name))
    end
  else
    table.insert(lines, "   (none mapped)")
  end

  table.insert(lines, "")
  table.insert(lines, "2. Configured servers (registry.ACTIVE):")
  if #configured > 0 then
    for _, name in ipairs(configured) do
      table.insert(lines, string.format("   • %s", name))
    end
  else
    table.insert(lines, "   (none)")
  end

  table.insert(lines, "")
  table.insert(lines, "3. Registered configs (vim.lsp.config):")
  if #registered > 0 then
    for _, name in ipairs(registered) do
      table.insert(lines, string.format("   • %s", name))
    end
  else
    table.insert(lines, "   (none - THIS IS THE PROBLEM!)")
  end

  table.insert(lines, "")
  table.insert(lines, "4. Currently running:")
  if #running > 0 then
    for _, name in ipairs(running) do
      table.insert(lines, string.format("   • %s", name))
    end
  else
    table.insert(lines, "   (none)")
  end

  table.insert(lines, "")
  table.insert(lines, "Completion would show:")
  local completion_candidates = {}
  local seen = {}

  -- Same logic as completion.lua
  for _, name in ipairs(expected) do
    local is_running = false
    for _, r in ipairs(running) do
      if r == name then
        is_running = true
        break
      end
    end
    if not is_running and not seen[name] then
      completion_candidates[#completion_candidates + 1] = name
      seen[name] = true
    end
  end

  for _, name in ipairs(configured) do
    local is_running = false
    for _, r in ipairs(running) do
      if r == name then
        is_running = true
        break
      end
    end
    if not is_running and not seen[name] then
      completion_candidates[#completion_candidates + 1] = name
      seen[name] = true
    end
  end

  if #completion_candidates > 0 then
    for _, name in ipairs(completion_candidates) do
      table.insert(lines, string.format("   • %s", name))
    end
  else
    table.insert(lines, "   (none - all running or nothing configured)")
  end

  -- Show in floating window
  local buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].filetype = "markdown"
  vim.bo[buf].modifiable = false

  local width = math.min(80, vim.o.columns - 4)
  local height = math.min(#lines + 2, vim.o.lines - 4)

  api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " LSP Debug ",
    title_pos = "center",
  })

  api.nvim_buf_set_keymap(buf, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
end

return M
