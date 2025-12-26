---@module 'custom.function_index'
---@brief Multi-language function indexer for Neovim
---@description
--- A high-performance function indexer that uses ripgrep to build
--- a searchable index of function definitions across the entire CWD.
--- Supports multiple languages, persistent caching, and integrates
--- with Telescope and fzf-lua.
---
--- Key features:
--- - No LSP/Tree-sitter dependency
--- - Fast indexing with ripgrep + PCRE2
--- - Persistent cache with incremental updates
--- - Pre-filled search queries (clipboard, cursor word)
--- - Multi-language support (Lua, Python, JS, Go, Rust, C/C++, etc.)
---
--- @see custom.function_index.core.indexer
--- @see custom.function_index.ui.telescope_picker
--- @see custom.function_index.ui.fzf_picker

local M = {}

local cache_mod = require("custom.function_index.core.cache")
local indexer_mod = require("custom.function_index.core.indexer")
local telescope_picker = require("custom.function_index.ui.telescope_picker")
local fzf_picker = require("custom.function_index.ui.fzf_picker")

--- Default configuration
---@type table
local default_config = {
  cache = {
    enabled = true,
    dir = vim.fn.stdpath("cache") .. "/function_index",
    ttl_seconds = 3600, -- 1 hour
  },
  indexing = {
    auto_rebuild_on_save = false,
    exclude_patterns = {
      "node_modules/",
      ".git/",
      "build/",
      "dist/",
      "target/",
      "__pycache__/",
      "*.min.js",
      "*.min.css",
    },
    max_file_size_kb = 1024, -- 1 MB
    follow_symlinks = false,
  },
  languages = {
    lua = true,
    python = true,
    javascript = true,
    typescript = true,
    go = true,
    rust = true,
    c = true,
    cpp = true,
    java = false,
    ruby = false,
    php = false,
  },
  ui = {
    show_language_icons = true,
    show_function_types = true,
    group_by_file = false,
    default_picker = "telescope", -- "telescope" or "fzf"
  },
}

--- Active configuration (merged with user options)
---@type table
local config = vim.deepcopy(default_config)

--- Validate user configuration
---@param user_config table
---@return boolean # true if valid
---@return string|nil # Error message if invalid
local function validate_config(user_config)
  if type(user_config) ~= "table" then
    return false, "Configuration must be a table"
  end

  -- Validate cache.ttl_seconds
  if user_config.cache and user_config.cache.ttl_seconds then
    if type(user_config.cache.ttl_seconds) ~= "number" or user_config.cache.ttl_seconds < 0 then
      return false, "cache.ttl_seconds must be a non-negative number"
    end
  end

  -- Validate indexing.max_file_size_kb
  if user_config.indexing and user_config.indexing.max_file_size_kb then
    if type(user_config.indexing.max_file_size_kb) ~= "number" or user_config.indexing.max_file_size_kb < 0 then
      return false, "indexing.max_file_size_kb must be a non-negative number"
    end
  end

  -- Validate ui.default_picker
  if user_config.ui and user_config.ui.default_picker then
    if user_config.ui.default_picker ~= "telescope" and user_config.ui.default_picker ~= "fzf" then
      return false, "ui.default_picker must be 'telescope' or 'fzf'"
    end
  end

  return true, nil
end

--- Setup function (entry point)
---@param user_config table|nil # User configuration
function M.setup(user_config)
  user_config = user_config or {}

  -- Validate configuration
  local valid, err = validate_config(user_config)
  if not valid then
    vim.notify("Invalid function_index configuration: " .. err, vim.log.levels.ERROR)
    return
  end

  -- Merge with defaults
  config = vim.tbl_deep_extend("force", default_config, user_config)

  -- Create user commands
  vim.api.nvim_create_user_command("FunctionIndexTelescope", function()
    telescope_picker.pick(config)
  end, {
    desc = "Open function index with Telescope",
  })

  vim.api.nvim_create_user_command("FunctionIndexFzfLua", function()
    fzf_picker.pick(config)
  end, {
    desc = "Open function index with fzf-lua",
  })

  vim.api.nvim_create_user_command("FunctionIndexRebuild", function()
    local _, msg = indexer_mod.rebuild_index(config)
    if msg then
      vim.notify(msg, vim.log.levels.INFO)
    end
  end, {
    desc = "Force rebuild function index cache",
  })

  vim.api.nvim_create_user_command("FunctionIndexClearCache", function()
    local ok, _ = cache_mod.clear(config)
    if ok then
      vim.notify("Cache cleared successfully", vim.log.levels.INFO)
    else
      vim.notify("Failed to clear cache: " .. tostring(err), vim.log.levels.ERROR)
    end
  end, {
    desc = "Clear function index cache",
  })

  vim.api.nvim_create_user_command("FunctionIndexStats", function()
    local stats = cache_mod.get_stats(config)
    if stats then
      local lines = {
        "Function Index Cache Statistics:",
        "",
        "Version: " .. stats.version,
        "Indexed at: " .. os.date("%Y-%m-%d %H:%M:%S", stats.indexed_at),
        "Working directory: " .. stats.cwd,
        "File count: " .. stats.file_count,
        "Function count: " .. stats.entry_count,
        "Cache size: " .. string.format("%.2f KB", stats.cache_size_bytes / 1024),
        "Cache path: " .. stats.cache_path,
      }
      vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
    else
      vim.notify("No cache found", vim.log.levels.WARN)
    end
  end, {
    desc = "Show function index cache statistics",
  })

  -- Debug command to test ripgrep
  vim.api.nvim_create_user_command("FunctionIndexDebug", function()
    local patterns_mod = require("custom.function_index.core.patterns")
    local patterns = patterns_mod.get_patterns(config.languages)

    vim.notify("Enabled languages: " .. vim.inspect(vim.tbl_keys(vim.tbl_filter(function(v)
      return v
    end, config.languages))), vim.log.levels.INFO)

    vim.notify("Found " .. #patterns .. " patterns", vim.log.levels.INFO)

    -- Test a simple Lua pattern
    local test_cmd = {
      "rg",
      "--vimgrep",
      "--pcre2",
      "--glob", "*.lua",
      [[^\s*function\s+]],
      "."
    }

    vim.notify("Test command: " .. table.concat(test_cmd, " "), vim.log.levels.INFO)

    local lines = vim.fn.systemlist(test_cmd)
    vim.notify("Test found " .. #lines .. " matches", vim.log.levels.INFO)

    if #lines > 0 then
      vim.notify("Sample match: " .. lines[1], vim.log.levels.INFO)
    end
  end, {
    desc = "Debug function index setup",
  })

  -- Optional: Auto-rebuild on save
  if config.indexing.auto_rebuild_on_save then
    vim.api.nvim_create_autocmd("BufWritePost", {
      pattern = "*",
      callback = function()
        -- Debounce: only rebuild after 2 seconds of inactivity
        vim.defer_fn(function()
          indexer_mod.rebuild_index(config)
        end, 2000)
      end,
    })
  end
end

--- Get current configuration
---@return table
function M.get_config()
  return config
end

--- Open picker (uses default from config)
function M.pick()
  if config.ui.default_picker == "fzf" then
    fzf_picker.pick(config)
  else
    telescope_picker.pick(config)
  end
end

--- Open Telescope picker
function M.pick_telescope()
  telescope_picker.pick(config)
end

--- Open fzf-lua picker
function M.pick_fzf()
  fzf_picker.pick(config)
end

--- Open picker with word under cursor
function M.pick_cword()
  if config.ui.default_picker == "fzf" then
    fzf_picker.pick_with_cword(config)
  else
    telescope_picker.pick_with_cword(config)
  end
end

--- Open picker with clipboard content
function M.pick_clipboard()
  if config.ui.default_picker == "fzf" then
    fzf_picker.pick_with_clipboard(config)
  else
    telescope_picker.pick_with_clipboard(config)
  end
end

--- Open picker with custom query
---@param query string # Search query
function M.pick_with_query(query)
  if config.ui.default_picker == "fzf" then
    fzf_picker.pick_with_query(config, query)
  else
    telescope_picker.pick_with_query(config, query)
  end
end

--- Rebuild index (force)
---@return table[]
---@return string|nil # Status message
function M.rebuild_index()
  return indexer_mod.rebuild_index(config)
end

--- Clear cache
---@return boolean # Success
---@return string|nil # Error message
function M.clear_cache()
  return cache_mod.clear(config)
end

--- Get cache statistics
---@return table|nil # Stats or nil
function M.get_cache_stats()
  return cache_mod.get_stats(config)
end

return M
