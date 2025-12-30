---@module 'lsp.usercmds'
--- LSP UserCommands mit Autocompletion

-- CRITICAL: Load vim.lsp types
require("@types.lsp")

local nvim_create_user_command = vim.api.nvim_create_user_command
local lsp = vim.lsp

local M = {}

local desc_tag = "[lsp] "

-- =============================================================================
-- HELPER FUNCTIONS
-- =============================================================================

--- Get all active/configured servers from registry
---@return string[]
local function _active_servers()
  local ok, reg = pcall(require, "lsp.core.registry")
  if ok and type(reg) == "table" and type(reg.ACTIVE) == "table" then
    return vim.deepcopy(reg.ACTIVE)
  end
  -- Fallback
  return { "lua_ls", "ts_ls", "gopls", "marksman", "html", "bashls" }
end

--- Get clients attached to buffer
---@param bufnr integer|nil
---@return vim.lsp.Client[]
local function _buf_clients(bufnr)
  return lsp.get_clients({ bufnr = bufnr or 0 })
end

--- Get list of installed LSPs via Mason
---@return string[]
local function get_installed_lsps()
  local ok, registry = pcall(require, "mason-registry")
  if not ok then
    return {}
  end
  local lsps = {}
  for _, pkg in ipairs(registry.get_installed_packages()) do
    if pkg:is_installed() and pkg:is_lsp() then
      table.insert(lsps, pkg.name)
    end
  end
  table.sort(lsps)
  return lsps
end

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
  local clients = _buf_clients(bufnr)
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
    vim.notify("No LSP name provided", vim.log.levels.WARN)
    return false
  end

  -- Check if already running
  if is_server_running(name, bufnr) then
    vim.notify(
      string.format("LSP '%s' already running", name),
      vim.log.levels.INFO
    )
    return true
  end

  -- Try native API first
  local ok = pcall(lsp.enable, name)
  if ok then
    vim.notify(string.format("Started LSP: %s", name), vim.log.levels.INFO)
    return true
  end

  -- Fallback: try lspconfig
  local ok_config, lspconfig = pcall(require, "lspconfig")
  if ok_config and lspconfig[name] then
    pcall(lspconfig[name].launch)
    vim.notify(string.format("Started LSP: %s (via lspconfig)", name), vim.log.levels.INFO)
    return true
  end

  vim.notify(
    string.format("Failed to start LSP: %s", name),
    vim.log.levels.ERROR
  )
  return false
end

-- =============================================================================
-- COMPLETION FUNCTIONS
-- =============================================================================

--- Completion for LspStartHere: configured servers + mason servers
---@param arglead string
---@param cmdline string
---@param cursorpos integer
---@return string[]
---@diagnostic disable-next-line: unused-local
local function complete_start_here(arglead, cmdline, cursorpos)
  local candidates = {}
  local seen = {}

  -- Add configured servers
  for _, name in ipairs(_active_servers()) do
    if not seen[name] then
      candidates[#candidates + 1] = name
      seen[name] = true
    end
  end

  -- Add mason servers
  for _, name in ipairs(get_installed_lsps()) do
    if not seen[name] then
      candidates[#candidates + 1] = name
      seen[name] = true
    end
  end

  -- Add servers for current filetype
  for _, name in ipairs(get_servers_for_buffer(0)) do
    if not seen[name] then
      candidates[#candidates + 1] = name
      seen[name] = true
    end
  end

  table.sort(candidates)

  -- Filter by arglead
  if arglead and arglead ~= "" then
    local filtered = {}
    for _, name in ipairs(candidates) do
      if name:match("^" .. vim.pesc(arglead)) then
        filtered[#filtered + 1] = name
      end
    end
    return filtered
  end

  return candidates
end

--- Completion for LspStopHere: running servers
---@param arglead string
---@param cmdline string
---@param cursorpos integer
---@return string[]
---@diagnostic disable-next-line: unused-local
local function complete_stop_here(arglead, cmdline, cursorpos)
  local clients = _buf_clients(0)
  local names = {}

  for _, c in ipairs(clients) do
    names[#names + 1] = c.name
  end

  table.sort(names)

  -- Filter by arglead
  if arglead and arglead ~= "" then
    local filtered = {}
    for _, name in ipairs(names) do
      if name:match("^" .. vim.pesc(arglead)) then
        filtered[#filtered + 1] = name
      end
    end
    return filtered
  end

  return names
end

-- =============================================================================
-- USER COMMANDS
-- =============================================================================

function M.attach()
  -- LspStartHere: Start servers (auto-detect or specify)
  pcall(nvim_create_user_command, "LspStartHere", function(args)
    if args.args and args.args ~= "" then
      -- Start specific server
      start_lsp(args.args, 0)
    else
      -- Auto-detect based on filetype
      local servers = get_servers_for_buffer(0)
      if #servers == 0 then
        local ft = vim.bo[0].filetype
        vim.notify(
          string.format("No LSP configured for filetype '%s'", ft or "none"),
          vim.log.levels.WARN
        )
        return
      end

      local started = 0
      for _, name in ipairs(servers) do
        if start_lsp(name, 0) then
          started = started + 1
        end
      end

      vim.notify(
        string.format("Started %d/%d LSP server(s)", started, #servers),
        vim.log.levels.INFO
      )
    end
  end, {
    nargs = "?",
    complete = complete_start_here,
    desc = desc_tag .. "Start LSP servers (auto-detect or specify name)"
  })

  -- LspStopHere: Stop servers
  pcall(nvim_create_user_command, "LspStopHere", function(args)
    if args.args and args.args ~= "" then
      -- Stop specific server
      local clients = _buf_clients(0)
      local found = false

      for _, c in ipairs(clients) do
        if c.name == args.args then
          lsp.stop_client(c.id, true)
          found = true
          vim.notify(
            string.format("Stopped LSP: %s", args.args),
            vim.log.levels.INFO
          )
          break
        end
      end

      if not found then
        vim.notify(
          string.format("LSP '%s' not running", args.args),
          vim.log.levels.WARN
        )
      end
    else
      -- Stop all servers
      local ids = {}
      for _, c in ipairs(_buf_clients(0)) do
        ids[#ids + 1] = c.id
      end

      if #ids > 0 then
        lsp.stop_client(ids, true)
        vim.notify(
          string.format("Stopped %d LSP client(s)", #ids),
          vim.log.levels.INFO
        )
      else
        vim.notify("No LSP clients running", vim.log.levels.INFO)
      end
    end
  end, {
    nargs = "?",
    complete = complete_stop_here,
    desc = desc_tag .. "Stop LSP clients (all or specify name)"
  })

  -- LspRestartHere: Restart servers
  pcall(nvim_create_user_command, "LspRestartHere", function(args)
    local bufnr = 0
    local clients = _buf_clients(bufnr)

    if #clients == 0 then
      vim.notify("No LSP clients to restart", vim.log.levels.INFO)
      return
    end

    if args.args and args.args ~= "" then
      -- Restart specific server
      local found = false
      for _, c in ipairs(clients) do
        if c.name == args.args then
          found = true
          lsp.stop_client(c.id, true)
          vim.defer_fn(function()
            start_lsp(args.args, bufnr)
          end, 100)
          vim.notify(
            string.format("Restarting LSP: %s", args.args),
            vim.log.levels.INFO
          )
          break
        end
      end

      if not found then
        vim.notify(
          string.format("LSP '%s' not running", args.args),
          vim.log.levels.WARN
        )
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

      vim.defer_fn(function()
        for _, name in ipairs(server_names) do
          start_lsp(name, bufnr)
        end
      end, 100)

      vim.notify(
        string.format("Restarting %d LSP server(s)...", #server_names),
        vim.log.levels.INFO
      )
    end
  end, {
    nargs = "?",
    complete = complete_stop_here,
    desc = desc_tag .. "Restart LSP clients (all or specify name)"
  })

  -- LspInfo: Show detailed info
  pcall(nvim_create_user_command, "LspInfo", function()
    local bufnr = 0
    local ft = vim.bo[bufnr].filetype
    local clients = _buf_clients(bufnr)
    local expected = get_servers_for_buffer(bufnr)

    local lines = {
      "LSP Information",
      "===============",
      "",
      string.format("Buffer:   %d", bufnr),
      string.format("Filetype: %s", ft or "none"),
      "",
      "Expected servers for this filetype:",
    }

    if #expected > 0 then
      for _, name in ipairs(expected) do
        local running = is_server_running(name, bufnr)
        table.insert(lines, string.format("  • %s [%s]", name, running and "✓ running" or "✗ not running"))
      end
    else
      table.insert(lines, "  (none configured)")
    end

    table.insert(lines, "")
    table.insert(lines, "Currently attached clients:")

    if #clients > 0 then
      for _, c in ipairs(clients) do
        local root = c.config and c.config.root_dir or "unknown"
        table.insert(lines, string.format("  • %s (id: %d)", c.name, c.id))
        table.insert(lines, string.format("    root: %s", root))
      end
    else
      table.insert(lines, "  (none)")
    end

    -- Show in floating window
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].filetype = "markdown"
    vim.bo[buf].modifiable = false

    local width = math.min(80, vim.o.columns - 4)
    local height = math.min(#lines + 2, vim.o.lines - 4)

    vim.api.nvim_open_win(buf, true, {
      relative = "editor",
      width = width,
      height = height,
      row = math.floor((vim.o.lines - height) / 2),
      col = math.floor((vim.o.columns - width) / 2),
      style = "minimal",
      border = "rounded",
      title = " LSP Info ",
      title_pos = "center",
    })

    vim.api.nvim_buf_set_keymap(buf, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
  end, {
    desc = desc_tag .. "Show LSP information for current buffer"
  })
end

return M
