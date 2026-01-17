---@module 'config.neotree.sources.switcher'
---@description Hover-based source switcher for Neo-tree using hover-select v2

local ICONS = require("config.neotree.sources.icons")
local hover_select = require("lib.ui.hover_select")
local window_state = require("config.neotree.state.windows")
local controller = require("config.neotree.open.window.controller")

local M = {}

---Get list of available sources from Neo-tree's setup
---@return string[] sources List of source names
local function get_available_sources()
  local ok, neo_tree = pcall(require, "neo-tree")
  if not ok then
    vim.notify("Neo-tree not loaded", vim.log.levels.ERROR)
    return {}
  end

  local config = neo_tree.config or {}
  local sources = config.sources or {}

  if #sources == 0 then
    local ok_manager, manager = pcall(require, "neo-tree.sources.manager")
    if ok_manager then
      local state = manager.get_state("filesystem")
      if state and state.config and state.config.sources then
        sources = state.config.sources
      end
    end
  end

  if #sources == 0 then
    local ok_lazy, lazy_config = pcall(require, "lazy.core.config")
    if ok_lazy then
      local plugins = lazy_config.plugins or {}
      local spec = plugins["neo-tree.nvim"]
      if spec and spec.opts then
        local opts = spec.opts
        if type(opts) == "function" then
          local ok_exec, result = pcall(opts)
          if ok_exec and type(result) == "table" then
            opts = result
          end
        end
        sources = opts.sources or {}
      end
    end
  end

  if #sources == 0 then
    vim.notify("Using fallback source list", vim.log.levels.WARN)
    sources = {
      "filesystem",
      "buffers",
      "git_status",
      "document_symbols",
    }

    if pcall(require, "neo-tree.sources.diagnostics") then
      sources[#sources + 1] = "diagnostics"
    end

    if pcall(require, "netman") then
      sources[#sources + 1] = "netman.ui.neo-tree"
    end

    if pcall(require, "neo-tree-tests-source") then
      sources[#sources + 1] = "tests"
    end
  end

  return sources
end

---Check if source is currently loadable
---@param source_name string
---@return boolean loadable
---@return string|nil error_msg
local function check_source_loadable(source_name)
  if source_name == "document_symbols" then
    local clients = vim.lsp.get_clients({ bufnr = 0 })
    if #clients == 0 then
      return false, "No LSP client attached to current buffer"
    end
  end

  if source_name == "diagnostics" then
    local ok = pcall(require, "neo-tree.sources.diagnostics")
    if not ok then
      return false, "Diagnostics source not installed"
    end
  end

  if source_name == "netman.ui.neo-tree" then
    local ok = pcall(require, "netman")
    if not ok then
      return false, "Netman plugin not installed"
    end
  end

  if source_name == "tests" then
    local ok = pcall(require, "neo-tree-tests-source")
    if not ok then
      return false, "Tests source not installed"
    end
  end

  return true, nil
end

---Show Neo-tree source picker in a hover-select floating window
function M.show_picker()
  local sources = get_available_sources()

  if #sources == 0 then
    vim.notify("No sources available", vim.log.levels.WARN)
    return
  end

  local current_source = window_state.get_source()
  local current_position = window_state.get_position() or require("config.neotree").get_default_position()

  ---@type string[]
  local items = {}

  for i, name in ipairs(sources) do
    local icon = ICONS.get_icon(name, "nerd", "v1")
    local is_current = (name == current_source) and " ←" or ""
    local loadable, _ = check_source_loadable(name)
    local status = loadable and "" or " [!]"

    items[i] = string.format("%s %s%s%s", icon, name, is_current, status)
  end

  hover_select.open({
    title = "Select Neo-tree Source",
    items = items,
    auto_width = true,
    use_tab_navigation = true,

    ---@param _ string Display string (unused)
    ---@param index integer 1-based index into sources
    on_select = function(_, index)
      local source_name = sources[index]
      if not source_name then
        return
      end

      if source_name == current_source then
        vim.notify("Already showing " .. source_name, vim.log.levels.INFO)
        return
      end

      local loadable, err_msg = check_source_loadable(source_name)
      if not loadable then
        vim.notify(
          string.format("Cannot load %s: %s", source_name, err_msg or "Unknown error"),
          vim.log.levels.WARN
        )
        return
      end

      -- CRITICAL: Use controller's make_opener with source parameter
      local opener = controller.make_opener(current_position, source_name)
      opener()
    end,
  })
end

---Debug: Print all available information about sources
function M.debug_sources()
  local info = {
    ["neo-tree.config.sources"] = nil,
    ["filesystem.state.config.sources"] = nil,
    ["lazy.plugins.opts.sources"] = nil,
    ["detected_plugins"] = {},
    ["window_state"] = window_state.get_state(),
  }

  local ok, neo_tree = pcall(require, "neo-tree")
  if ok and neo_tree.config then
    info["neo-tree.config.sources"] = neo_tree.config.sources
  end

  local ok_manager, manager = pcall(require, "neo-tree.sources.manager")
  if ok_manager then
    local state = manager.get_state("filesystem")
    if state and state.config then
      info["filesystem.state.config.sources"] = state.config.sources
    end
  end

  local ok_lazy, lazy_config = pcall(require, "lazy.core.config")
  if ok_lazy then
    local plugins = lazy_config.plugins or {}
    local spec = plugins["neo-tree.nvim"]
    if spec and spec.opts then
      info["lazy.plugins.opts.sources"] = spec.opts.sources or spec.opts
    end
  end

  info["detected_plugins"] = {
    diagnostics = pcall(require, "neo-tree.sources.diagnostics"),
    netman = pcall(require, "netman"),
    tests = pcall(require, "neo-tree-tests-source"),
  }

  vim.print(info)
end

---Get available sources (for debugging)
---@return string[]
function M.get_available_sources()
  return get_available_sources()
end

return M
