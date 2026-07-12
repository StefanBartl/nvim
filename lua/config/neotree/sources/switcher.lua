---@module 'config.neotree.sources.switcher'
---@brief Hover-based source switcher for Neo-tree using direct Neo-tree commands

local notify = require("lib.nvim.notify").create("[config.neotree.sources.switcher]")

local ICONS = require("config.neotree.sources.icons")
local kit = require("lib.nvim.ui.kit")

local M = {}

---Get list of available sources from Neo-tree's setup
---@return string[] sources List of source names
local function get_available_sources()
  local ok, neo_tree = pcall(require, "neo-tree")
  if not ok then
    notify.error("Neo-tree not loaded")
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
    notify.warn("Using fallback source list")
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

---Get current Neo-tree window position if open
---@return string|nil position Current position or nil if not open
local function get_current_position()
  -- Check all windows in current tabpage
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(win) then
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "neo-tree" then
        -- Try to get position from window config
        local win_config = vim.api.nvim_win_get_config(win)

        -- Float detection
        if win_config.relative and win_config.relative ~= "" then
          return "float"
        end

        -- Try to detect position from window placement
        local win_width = vim.api.nvim_win_get_width(win)
        local win_height = vim.api.nvim_win_get_height(win)
        local screen_width = vim.o.columns
        local screen_height = vim.o.lines

        -- Current window detection (takes most of screen)
        if win_width >= screen_width * 0.8 and win_height >= screen_height * 0.8 then
          return "current"
        end

        -- Left/Right detection (narrow vertical split)
        if win_width < screen_width * 0.5 then
          local win_col = vim.api.nvim_win_get_position(win)[2]
          if win_col == 0 then
            return "left"
          else
            return "right"
          end
        end

        -- Fallback: assume left
        return require("config.neotree").get_default_position()
      end
    end
  end

  return nil
end

---Get current source from the active Neo-tree buffer
---@return string|nil source Current source name or nil
local function get_current_source()
  local buf = vim.api.nvim_get_current_buf()

  if vim.bo[buf].filetype ~= "neo-tree" then
    return nil
  end

  -- Neo-tree stores source name in buffer variables
  local source = vim.b[buf].neo_tree_source
  if type(source) == "string" then
    return source
  end

  return nil
end


---Switch to a different Neo-tree source
---@param source_name string Target source name
---@return nil
local function switch_to_source(source_name)
  local ok, NeoCmd = pcall(require, "neo-tree.command")
  if not ok then
    notify.error("Neo-tree command module not loaded")
    return
  end

  -- Close existing Neo-tree window first
  NeoCmd.execute({ action = "close" })

  local position = get_current_position()
    or require("config.neotree").get_default_position()

  NeoCmd.execute({
    source = source_name,
    action = "show",
    position = position,
    reveal = false,
  })
end

---Show Neo-tree source picker in a hover-select floating window
---@return nil
function M.show_picker()
  local sources = get_available_sources()

  if #sources == 0 then
    notify.warn("No sources available")
    return
  end

  local current_source = get_current_source()

  ---@type string[]
  local items = {}

  for i, name in ipairs(sources) do
    local icon = ICONS.get_icon(name, "nerd", "v1")
    local is_current = (name == current_source) and " ←" or ""
    local loadable, _ = check_source_loadable(name)
    local status = loadable and "" or " [!]"

    items[i] = string.format("%s %s%s%s", icon, name, is_current, status)
  end

  kit.select({
    title = "Select Neo-tree Source",
    items = items,

    ---@param _ string Display string (unused)
    ---@param index integer 1-based index into sources
    on_select = function(_, index)
      local source_name = sources[index]
      if not source_name then
        return
      end

      if source_name == current_source then
        notify.info("Already showing " .. source_name)
        return
      end

      local loadable, err_msg = check_source_loadable(source_name)
      if not loadable then
        notify.warn(string.format("Cannot load %s: %s", source_name, err_msg or "Unknown error"))
        return
      end

      -- Switch to source using direct Neo-tree command
      switch_to_source(source_name)
    end,
  })
end

---Debug: Print all available information about sources
---@return nil
function M.debug_sources()
  local info = {
    ["neo-tree.config.sources"] = nil,
    ["filesystem.state.config.sources"] = nil,
    ["lazy.plugins.opts.sources"] = nil,
    ["detected_plugins"] = {},
    ["current_position"] = get_current_position(),
    ["current_source"] = get_current_source(),
    ["default_position"] = require("config.neotree").get_default_position(),
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
