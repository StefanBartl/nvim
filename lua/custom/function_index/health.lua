---@module 'custom.function_index.health'
---@brief Health check for function_index module
---@description
--- Provides health check functionality for `:checkhealth function_index`.
--- Validates dependencies, configuration, and cache status.

local M = {}
local health = vim.health or require("health")

--- Check if ripgrep is installed and has PCRE2 support
local function check_ripgrep()
  health.start("ripgrep (rg)")

  if vim.fn.executable("rg") ~= 1 then
    health.error("ripgrep is not installed or not in PATH", {
      "Install ripgrep: https://github.com/BurntSushi/ripgrep",
      "macOS: brew install ripgrep",
      "Ubuntu/Debian: apt install ripgrep",
      "Arch: pacman -S ripgrep",
    })
    return
  end

  health.ok("ripgrep is installed")

  -- Check version
  local version_output = vim.fn.system("rg --version")
  local version = version_output:match("ripgrep ([%d%.]+)")

  if version then
    health.info("Version: " .. version)
  end

  -- Check PCRE2 support
  if version_output:match("PCRE2") then
    health.ok("PCRE2 support is enabled")
  else
    health.warn("PCRE2 support not detected", {
      "PCRE2 is required for complex regex patterns",
      "Reinstall ripgrep with PCRE2 support",
    })
  end
end

--- Check Telescope availability
local function check_telescope()
  health.start("Telescope")

  local ok, telescope = pcall(require, "telescope")
  if ok then
    health.ok("Telescope is installed")

    -- Check if telescope.nvim is properly configured
    local config_ok, _ = pcall(function()
      return telescope.load_extension
    end)

    if config_ok then
      health.ok("Telescope is properly configured")
    else
      health.warn("Telescope might not be fully configured")
    end
  else
    health.warn("Telescope is not installed", {
      "Install telescope.nvim for picker support",
      "See: https://github.com/nvim-telescope/telescope.nvim",
    })
  end
end

--- Check fzf-lua availability
local function check_fzf_lua()
  health.start("fzf-lua")

  local ok, _ = pcall(require, "fzf-lua")
  if ok then
    health.ok("fzf-lua is installed")
  else
    health.warn("fzf-lua is not installed", {
      "Install fzf-lua for alternative picker",
      "See: https://github.com/ibhagwan/fzf-lua",
    })
  end
end

--- Check cache directory
local function check_cache()
  health.start("Cache")

  local ok, main_module = pcall(require, "custom.function_index")
  if not ok then
    health.error("Could not load function_index module")
    return
  end

  local config = main_module.get_config()
  local cache_dir = config.cache.dir

  -- Check if cache directory exists
  local stat = vim.loop.fs_stat(cache_dir)
  if stat then
    if stat.type == "directory" then
      health.ok("Cache directory exists: " .. cache_dir)

      -- Check permissions (writable)
      local test_file = cache_dir .. "/.write_test"
      local fd = vim.loop.fs_open(test_file, "w", 420)
      if fd then
        vim.loop.fs_close(fd)
        vim.loop.fs_unlink(test_file)
        health.ok("Cache directory is writable")
      else
        health.error("Cache directory is not writable: " .. cache_dir)
      end
    else
      health.error("Cache path exists but is not a directory: " .. cache_dir)
    end
  else
    health.info("Cache directory does not exist yet (will be created on first use)")
  end

  -- Check cache stats
  local stats = main_module.get_cache_stats()
  if stats then
    health.info("Cached functions: " .. stats.entry_count)
    health.info("Cached files: " .. stats.file_count)
    health.info("Cache size: " .. string.format("%.2f KB", stats.cache_size_bytes / 1024))
    health.info("Last indexed: " .. os.date("%Y-%m-%d %H:%M:%S", stats.indexed_at))
  else
    health.info("No cache found (index has not been built yet)")
  end
end

--- Check configuration
local function check_configuration()
  health.start("Configuration")

  local ok, main_module = pcall(require, "custom.function_index")
  if not ok then
    health.error("Could not load function_index module")
    return
  end

  local config = main_module.get_config()

  -- Check enabled languages
  local enabled_langs = {}
  for lang, enabled in pairs(config.languages) do
    if enabled then
      enabled_langs[#enabled_langs + 1] = lang
    end
  end

  if #enabled_langs > 0 then
    health.ok("Enabled languages: " .. table.concat(enabled_langs, ", "))
  else
    health.error("No languages enabled", {
      "Enable at least one language in config.languages",
    })
  end

  -- Check picker availability
  local default_picker = config.ui.default_picker
  if default_picker == "telescope" then
    local telescope_ok = pcall(require, "telescope")
    if telescope_ok then
      health.ok("Default picker (telescope) is available")
    else
      health.error("Default picker (telescope) is not installed")
    end
  elseif default_picker == "fzf" then
    local fzf_ok = pcall(require, "fzf-lua")
    if fzf_ok then
      health.ok("Default picker (fzf-lua) is available")
    else
      health.error("Default picker (fzf-lua) is not installed")
    end
  end

  -- Check cache TTL
  if config.cache.ttl_seconds > 0 then
    health.info("Cache TTL: " .. config.cache.ttl_seconds .. " seconds")
  else
    health.info("Cache TTL: disabled (cache never expires)")
  end

  -- Check auto-rebuild
  if config.indexing.auto_rebuild_on_save then
    health.warn("Auto-rebuild on save is enabled (may impact performance)")
  else
    health.ok("Auto-rebuild on save is disabled")
  end
end

--- Check Neovim version
local function check_neovim_version()
  health.start("Neovim")

  local version = vim.version()
  local version_str = string.format("%d.%d.%d", version.major, version.minor, version.patch)

  if version.major == 0 and version.minor < 9 then
    health.error("Neovim version " .. version_str .. " is too old", {
      "function_index requires Neovim >= 0.9.0",
      "Upgrade Neovim: https://github.com/neovim/neovim/releases",
    })
  else
    health.ok("Neovim version " .. version_str .. " is supported")
  end
end

--- Main health check function
function M.check()
  check_neovim_version()
  check_ripgrep()
  check_telescope()
  check_fzf_lua()
  check_configuration()
  check_cache()
end

return M
