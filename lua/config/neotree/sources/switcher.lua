---@module 'config.neotree.sources.switcher'
---@description Hover-based source switcher for Neo-tree using hover-select v2

local ICONS = require("config.neotree.sources.icons")
local hover_select = require("lib.hover_select")

local M = {}

---Debug: Print all available information about sources
function M.debug_sources()
  local info = {
    ["neo-tree.config.sources"] = nil,
    ["filesystem.state.config.sources"] = nil,
    ["lazy.plugins.opts.sources"] = nil,
    ["detected_plugins"] = {},
  }

  -- Neo-tree global config
  local ok, neo_tree = pcall(require, "neo-tree")
  if ok and neo_tree.config then
    info["neo-tree.config.sources"] = neo_tree.config.sources
  end

  -- Filesystem state config
  local ok_manager, manager = pcall(require, "neo-tree.sources.manager")
  if ok_manager then
    local state = manager.get_state("filesystem")
    if state and state.config then
      info["filesystem.state.config.sources"] = state.config.sources
    end
  end

  -- Lazy config
  local ok_lazy, lazy_config = pcall(require, "lazy.core.config")
  if ok_lazy then
    local plugins = lazy_config.plugins or {}
    local spec = plugins["neo-tree.nvim"]
    if spec and spec.opts then
      info["lazy.plugins.opts.sources"] = spec.opts.sources or spec.opts
    end
  end

  -- Detected plugins
  info["detected_plugins"] = {
    diagnostics = pcall(require, "neo-tree.sources.diagnostics"),
    netman = pcall(require, "netman"),
    tests = pcall(require, "neo-tree-tests-source"),
  }

  vim.print(info)
end

-- Alternative: Sources aus Lazy.nvim Config holen
-- Falls Neo-tree's Config nicht zugänglich ist, kann man die Sources auch direkt aus der Plugin-Spec holen:
--
---Get sources from lazy.nvim plugin spec
---@return string[]
local function get_sources_from_lazy()
  local ok, lazy_config = pcall(require, "lazy.core.config")
  if not ok then
    return {}
  end

  local plugins = lazy_config.plugins or {}
  local neotree_spec = plugins["neo-tree.nvim"]

  if not neotree_spec or not neotree_spec.opts then
    return {}
  end

  -- Wenn opts eine Funktion ist, ausführen
  local opts = neotree_spec.opts
  if type(opts) == "function" then
    local ok_exec, result = pcall(opts)
    if ok_exec and type(result) == "table" then
      opts = result
    end
  end

  return opts.sources or {}
end

---Get list of available sources from Neo-tree's setup
---@return string[]|nil sources List of source names
local function get_available_sources()
  -- CRITICAL: Sources direkt aus dem global setup holen
  local ok, neo_tree = pcall(require, "neo-tree")
  if not ok then
    vim.notify("Neo-tree not loaded", vim.log.levels.ERROR)
    return {}
  end

  -- Neo-tree's global config enthält die sources-Liste
  local config = neo_tree.config or {}
  local sources = config.sources or {}

  if #sources > 0 then -- INFO: Dieser Wefg funktioert. AUDIT: Fallback 3 (lazy) probieren, ob performance besser ist!
    vim.notify("Sources direkt aus dem global setup geholt", vim.log.levels.info)
    return sources
  end

  -- Fallback: Wenn config.sources nicht existiert, aus setup opts holen
  if #sources == 0 then
    -- Versuche aus dem filesystem state
    local ok_manager, manager = pcall(require, "neo-tree.sources.manager")
    if ok_manager then
      local state = manager.get_state("filesystem")
      if state and state.config and state.config.sources then
        sources = state.config.sources
      end
    end
    if #sources > 0 then
      vim.notify(
        "[neotree.sources.switcher]: fb 1 -> soures aus setup opts geholt",
        vim.log.levels.info
      )
      return sources
    end
  end

  -- Zweiter Fallback: Hardcoded bekannte Sources
  if #sources == 0 then
    vim.notify("Using fallback source list", vim.log.levels.WARN)
    sources = {
      "filesystem",
      "buffers",
      "git_status",
      "document_symbols",
    }

    -- Optional sources prüfen
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

  -- Dritter Fallback: Aus Lazy Config
  if #sources == 0 then
    sources = get_sources_from_lazy()
    if #sources > 0 then
      vim.notify("[neotree.sources.switcher]: fb 3 -> soures aus lazy", vim.log.levels.INFO)
      return sources
    end
  end

  vim.notify("[neotree.sources.switcher]: sources is nil", vim.log.levels.WARN)
  return nil
end

---Check if source is currently loadable
---@param source_name string
---@return boolean loadable
---@return string|nil error_msg
local function check_source_loadable(source_name)
  -- Special cases: Sources mit externen Dependencies
  if source_name == "document_symbols" then
    -- LSP muss aktiv sein
    local clients = vim.lsp.get_clients({ bufnr = 0 })
    if #clients == 0 then
      return false, "No LSP client attached to current buffer"
    end
  end

  if source_name == "diagnostics" then
    -- Diagnostics Plugin muss geladen sein
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

  if not sources or #sources == 0 then
    vim.notify("No sources available", vim.log.levels.WARN)
    return
  end

  -- Determine current source
  local manager = require("neo-tree.sources.manager")
  local state = manager.get_state_for_window()
  local current = state and state.name or nil

  ---@type string[]
  local items = {}

  -- Build display items with status indicators
  for i, name in ipairs(sources) do
    local icon = ICONS.get_icon(name, "nerd", "v1")
    local is_current = (name == current) and " ←" or ""

    -- Check if source is loadable
    local loadable, _ = check_source_loadable(name)
    local status = loadable and "" or " [!]"

    items[i] = string.format("%s %s%s%s", icon, name, is_current, status)
  end

  -- Open hover-select UI
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

      -- Check if source is loadable before switching
      local loadable, err_msg = check_source_loadable(source_name)
      if not loadable then
        vim.notify(
          string.format("Cannot load %s: %s", source_name, err_msg or "Unknown error"),
          vim.log.levels.WARN
        )
        return
      end

      -- CRITICAL: Neo-tree Command verwenden
      local ok, err = pcall(function()
        require("neo-tree.command").execute({
          source = source_name,
          action = "show",
          position = require("config.neotree").get_default_position(),
        })
      end)

      if not ok then
        vim.notify(
          string.format("Failed to switch to %s: %s", source_name, tostring(err)),
          vim.log.levels.ERROR
        )
      end
    end,
  })
end

---Get available sources (for debugging)
---@return string[]|nil
function M.get_available_sources()
  return get_available_sources()
end

return M
