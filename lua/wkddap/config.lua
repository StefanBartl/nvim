---@module 'wkddap.config'
---@brief Central configuration for DAP module

local M = {}

--- Default adapter binaries and their Mason package names
---@type table<string, {binary?: string, mason_pkg?: string, required?: boolean, type: 'binary'|'plugin'}>
M.adapter_binaries = {
  lua = {
    type = "plugin", -- Not a binary, it's a Neovim plugin
    binary = "osv",
    required = false,
  },
  javascript = {
    type = "binary",
    binary = "js-debug-adapter",
    mason_pkg = "js-debug-adapter",
    required = true,
  },
  c = {
    type = "binary",
    binary = "lldb-vscode",
    mason_pkg = "codelldb",
    required = true,
  },
  go = {
    type = "binary",
    binary = "dlv",
    mason_pkg = "delve",
    required = true,
  },
  python = {
    type = "binary",
    binary = "debugpy",
    mason_pkg = "debugpy",
    required = true,
  },
  rust = {
    type = "binary",
    binary = "lldb-vscode",
    mason_pkg = "codelldb",
    required = true,
  },
  zig = {
    type = "binary",
    binary = "lldb-vscode",
    mason_pkg = "codelldb",
    required = true,
  },
  assembly = {
    type = "binary",
    binary = "gdb",
    required = true,
  },
}

--- Language aliases for adapter reuse
---@type table<string, string>
M.language_aliases = {
  typescript = "javascript",
  typescriptreact = "javascript",
  javascriptreact = "javascript",
  cpp = "c",
  ["c++"] = "c",
  asm = "assembly",
  nasm = "assembly",
  gas = "assembly",
}

--- Default UI signs
---@type table<string, {text: string, texthl: string, linehl?: string, numhl?: string}>
M.signs = {
  DapBreakpoint = {
    text = "●",
    texthl = "DapBreakpoint",
    linehl = "",
    numhl = "",
  },
  DapBreakpointCondition = {
    text = "◆",
    texthl = "DapBreakpointCondition",
    linehl = "",
    numhl = "",
  },
  DapBreakpointRejected = {
    text = "○",
    texthl = "DapBreakpointRejected",
    linehl = "",
    numhl = "",
  },
  DapLogPoint = {
    text = "◉",
    texthl = "DapLogPoint",
    linehl = "",
    numhl = "",
  },
  DapStopped = {
    text = "→",
    texthl = "DapStopped",
    linehl = "DapStoppedLine",
    numhl = "",
  },
}

--- Default highlight groups
---@type table<string, table>
M.highlights = {
  DapBreakpoint = { fg = "#e51400" },
  DapBreakpointCondition = { fg = "#ffcc00" },
  DapBreakpointRejected = { fg = "#888888" },
  DapLogPoint = { fg = "#61afef" },
  DapStopped = { fg = "#98c379" },
  DapStoppedLine = { bg = "#3e4451" },
}

--- Virtual text configuration
---@type table
M.virtual_text = {
  enabled = true,
  commented = true,
  virt_text_pos = "eol",
  all_frames = false,
  highlight_changed_variables = true,
  highlight_new_as_changed = true,
  show_stop_reason = true,
  only_first_definition = true,
  all_references = false,
}

--- DAP UI layout configuration
---@type table
M.dapui_layout = {
  {
    elements = {
      { id = "scopes", size = 0.25 },
      { id = "breakpoints", size = 0.25 },
      { id = "stacks", size = 0.25 },
      { id = "watches", size = 0.25 },
    },
    size = 40,
    position = "left",
  },
  {
    elements = {
      { id = "repl", size = 0.5 },
      { id = "console", size = 0.5 },
    },
    size = 10,
    position = "bottom",
  },
}

--- Mason auto-install configuration
---@type table
M.mason_ensure_installed = {
  "js-debug-adapter",
  "codelldb",
  "delve",
  "debugpy",
}

--- Log file path
---@return string
function M.get_log_path()
  return vim.fn.stdpath("cache") .. "/dap.log"
end

--- Get adapter binary path with Mason fallback
---@param name string Adapter name
---@return string|nil path
function M.get_adapter_path(name)
  local config = M.adapter_binaries[name]
  if not config then
    return nil
  end

  -- Plugin-based adapters don't have binaries
  if config.type == "plugin" then
    return config.binary -- Return plugin name for checking
  end

  -- Check system PATH first
  local exe = vim.fn.exepath(config.binary)
  if exe and exe ~= "" then
    return exe
  end

  -- Try Mason installation
  if config.mason_pkg then
    local mason_path = vim.fn.stdpath("data") .. "/mason/bin/" .. config.binary
    local ok, stat = pcall(vim.loop.fs_stat, mason_path)
    if ok and stat then
      return mason_path
    end

    -- Windows: try .cmd extension
    if package.config:sub(1, 1) == "\\" then
      mason_path = mason_path .. ".cmd"
      ok, stat = pcall(vim.loop.fs_stat, mason_path)
      if ok and stat then
        return mason_path
      end
    end
  end

  return nil
end

--- Validate adapter availability
---@param name string Adapter name
---@return boolean available, string? error_message
function M.validate_adapter(name)
  local config = M.adapter_binaries[name]
  if not config then
    return false, string.format("Unknown adapter: %s", name)
  end

  -- For plugin-based adapters, check if the plugin is available
  if config.type == "plugin" then
    local plugin_name = config.binary
    local ok = pcall(require, plugin_name)
    if not ok then
      if config.required then
        return false, string.format("Required plugin '%s' not found", plugin_name)
      else
        return false, string.format("Optional plugin '%s' not found", plugin_name)
      end
    end
    return true, nil
  end

  -- For binary adapters, check if binary exists
  local path = M.get_adapter_path(name)
  if not path then
    if config.required then
      return false,
        string.format(
          "Required adapter '%s' not found. Install via Mason: %s",
          name,
          config.mason_pkg or config.binary
        )
    else
      return false, string.format("Optional adapter '%s' not found", name)
    end
  end

  return true, nil
end

return M
