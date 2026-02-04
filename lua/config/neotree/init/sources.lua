---@module 'config.neotree.sources.init'
---@brief Centralized source configuration with validation and error handling
--[[
opts = function()
  local sources_config = require("config.neotree.init.sources").generate_config({
    icon_family = "nerd",
    icon_variant = "v1",
    name_length = "long",
    enable_diagnostics = true,
    enable_tests = true,
  })

  return vim.tbl_deep_extend("force", sources_config, {
    -- ... rest of Neo-tree configuration ...
  })
end
--]]

local notify = require("lib.notify").create("[config.neotree.sources]")
local BUFFERS = require("config.neotree.keymaps.buffers")
local DIAGNOSTICS = require("config.neotree.keymaps.diagnostics")
local DOCUMENT_SYMBOLS = require("config.neotree.keymaps.document_symbols")
local GIT_STATUS = require("config.neotree.keymaps.git_status")
local ICONS = require("config.neotree.sources.icons")
local NEOTEST = require("config.neotest.neotree")

local M = {}

---@class Cfg.NeoTree.Sources.Config
---@field icon_family Cfg.NeoTree.Sources.IconFamily
---@field icon_variant Cfg.NeoTree.Sources.IconVariantKey
---@field name_length Cfg.NeoTree.Sources.IconLength
---@field enable_diagnostics? boolean
---@field enable_tests? boolean

---Default configuration
---@type Cfg.NeoTree.Sources.Config
local DEFAULT_CONFIG = {
  icon_family = "nerd",
  icon_variant = "v1",
  name_length = "long",
  enable_diagnostics = true,
  enable_tests = true,
}

local DOCUMENT_SYMBOLS_CONFIG = {
  follow_cursor = true,
  client_filters = "first",
  renderers = {
    root = {
      { "indent" },
      { "icon", default = "C" },
      { "name", zindex = 10 },
    },
    symbol = {
      { "indent", with_expanders = true },
      { "kind_icon", default = "?" },
      {
        "container",
        content = {
          { "name", zindex = 10 },
          { "kind_name", zindex = 20, align = "right" },
        },
      },
    },
  },
  window = {
    mappings = DOCUMENT_SYMBOLS,
    position = require("config.neotree").get_default_position(),
  },
}

---Check if a source module is available
---@param module_name string
---@return boolean available, string|nil error_msg
local function check_source_available(module_name)
  local ok, _ = pcall(require, module_name)
  if not ok then
    return false, string.format("Module '%s' not found", module_name)
  end
  return true, nil
end

---Build enabled sources list with validation
---@param config Cfg.NeoTree.Sources.Config
---@return string[] enabled_sources
---@return table<string, string> errors
local function build_enabled_sources(config)
  local enabled = { "filesystem", "buffers", "git_status", "document_symbols" }
  local errors = {}

  -- Diagnostics source
  if config.enable_diagnostics then
    local available, err = check_source_available("neo-tree.sources.diagnostics")
    if available then
      enabled[#enabled + 1] = "diagnostics"
    else
      errors.diagnostics = err
    end
  end

  -- Tests source (neotest integration)
  if config.enable_tests then
    local available, err = check_source_available("neo-tree-tests-source")
    if available then
      enabled[#enabled + 1] = "tests"
    else
      errors.tests = err
    end
  end

  return enabled, errors
end

---Build source_selector configuration
---@param enabled_sources string[]
---@param config Cfg.NeoTree.Sources.Config
---@return table[] sources
local function build_source_selector(enabled_sources, config)
  local sources = {}

  for _, source_name in ipairs(enabled_sources) do
    sources[#sources + 1] = {
      source = source_name,
      display_name = ICONS.format(
        config.icon_family,
        config.icon_variant,
        source_name,
        config.name_length
      ),
    }
  end

  return sources
end

---Generate Neo-tree sources configuration
---@param user_config? Cfg.NeoTree.Sources.Config
---@return table neotree_opts
function M.generate_config(user_config)
  -- Merge with defaults
  local config = vim.tbl_deep_extend("force", DEFAULT_CONFIG, user_config or {})

  -- Build enabled sources
  local enabled_sources, errors = build_enabled_sources(config)

  -- Log errors (non-blocking)
  if next(errors) then
    for source, error_msg in pairs(errors) do
      notify.debug(string.format("Source '%s' disabled: %s", source, error_msg))
    end
  end

  -- Build source_selector
  local source_selector_sources = build_source_selector(enabled_sources, config)

  -- Report loaded sources
  notify.info(
    string.format("Loaded %d sources: %s", #enabled_sources, table.concat(enabled_sources, ", "))
  )

  return {
    sources = enabled_sources,
    source_selector = {
      winbar = true,
      statusline = false,
      sources = source_selector_sources,
    },
    buffers = {
      window = { mappings = BUFFERS, position = require("config.neotree").get_default_position() },
    },
    git_status = {
      window = {
        mappings = GIT_STATUS,
        position = require("config.neotree").get_default_position(),
      },
    },
    document_symbols = DOCUMENT_SYMBOLS_CONFIG,

    diagnostics = {
      auto_preview = {
        enabled = false,
        preview_config = {},
        event = "neo_tree_buffer_enter",
      },
      bind_to_cwd = true,
      diag_sort_function = "severity",
      follow_current_file = {
        enabled = true,
        always_focus_file = false,
      },
      group_dirs_and_files = true,
      group_empty_dirs = true,
      show_unloaded = true,
      refresh = {
        delay = 100,
        event = "vim_diagnostic_changed",
        max_items = 10000,
      },
      window = {
        mappings = DIAGNOSTICS,
        position = require("config.neotree").get_default_position(),
      },
    } or nil,

    tests = {
      follow_cursor = true,
      window = {
        -- mappings = vim.tbl_extend(
        -- "force",
        -- require("config.neotree.keymaps.tests"),
        -- NEOTEST.keymaps()
        -- ),
        mappings = NEOTEST.keymaps(),
        position = require("config.neotree").get_default_position(),
      },
    },

    renderers = {
      directory = {
        { "indent" },
        { "icon" },
        { "current_filter" },
        { "name" },
        { "git_status", highlight = "NeoTreeDimText" },
        diagnostics = {
          symbols = {
            hint = "",
            info = "",
            warn = "",
            error = "",
          },
          highlights = {
            hint = "DiagnosticSignHint",
            info = "DiagnosticSignInfo",
            warn = "DiagnosticSignWarn",
            error = "DiagnosticSignError",
          },
        } or nil,
        { "clipboard" },
      },
      file = {
        { "indent" },
        { "icon" },
        { "name", use_git_status_colors = true },
        { "git_status", highlight = "NeoTreeDimText" },
        { "diagnostics" },
        {
          function(_, node, state)
            local marks = state.explicitly_marked_node_ids or {}
            local node_id = node:get_id()
            if marks[node_id] then
              return {
                text = " ✓",
                highlight = "NeoTreeGitStaged",
              }
            end
            return {}
          end,
        },
        { "clipboard" },
      },
    },
  }
end

---Get list of available sources
---@return string[] sources
function M.get_available_sources()
  local config = DEFAULT_CONFIG
  local enabled, _ = build_enabled_sources(config)
  return enabled
end

---Validate sources configuration
---@param user_config Cfg.NeoTree.Sources.Config
---@return boolean valid, string|nil error_msg
function M.validate_config(user_config)
  if type(user_config) ~= "table" then
    return false, "Config must be a table"
  end

  local valid_families = { common = true, nerd = true, codicons = true }
  if user_config.icon_family and not valid_families[user_config.icon_family] then
    return false, string.format("Invalid icon_family: %s", user_config.icon_family)
  end

  local valid_variants = { v1 = true, v2 = true }
  if user_config.icon_variant and not valid_variants[user_config.icon_variant] then
    return false, string.format("Invalid icon_variant: %s", user_config.icon_variant)
  end

  local valid_lengths = { long = true, short = true }
  if user_config.name_length and not valid_lengths[user_config.name_length] then
    return false, string.format("Invalid name_length: %s", user_config.name_length)
  end

  return true, nil
end

return M
