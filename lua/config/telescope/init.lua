---@module 'config.telescope'
--- Modularized Telescope setup with unified history and file browser keymaps
--- Prefers SQLite-backed history (smart_history) if available, otherwise falls back to file-based history.
--- Also merges keymaps for history and file browser, sets UI highlights, and loads extensions safely.

local M = {}

local actions = require("telescope.actions")
local files_path_shorten = require("lib.filesystem.path_shorten")
local ignore_list = require("lib.filesystem.ignore.list")
local history = require("config.telescope.history")
local history_keymaps = require("config.telescope.history.keymaps")
local fb_keymaps = require("config.telescope.file_browser.keymaps")
local hl_selection = require("config.telescope.ui.hl_selection")
local bg = require("config.telescope.open_background")

local notify = vim.notify
local levels = vim.log.levels

-- Helper: compute effective max length for path display
---@param picker_opts table|nil Telescope picker options
---@param default integer fallback maximum length
---@return integer
local function adapt_max_len(picker_opts, default)
  if type(picker_opts) == "table" and picker_opts.winwidth and type(picker_opts.winwidth) == "number" then
    return math.max(10, picker_opts.winwidth - 10)
  end
  return default or 60
end

-- Returns merged default options for telescope.setup
---@return table opts
function M.defaults()
  local hist_config = history.setup()

  -- Merge history and file browser keymaps
  local km =
    vim.tbl_deep_extend("force", history_keymaps.get(actions) or {}, fb_keymaps.get(actions), bg.get_mappings())

  return {
    path_display = function(picker_opts, path)
      local max_len = adapt_max_len(picker_opts, 60)
      return files_path_shorten(path, max_len)
    end,
    file_ignore_patterns = ignore_list.as_telescope_patterns(),
    history = hist_config,
    sorting_strategy = "ascending",
    layout_config = { prompt_position = "top" },
    mappings = km,
  }
end

-- Returns extension configuration table
---@return table extensions
function M.extensions()
  local ext = {
    file_browser = {
      path = "%:p:h",
      cwd_to_path = true,
      select_buffer = true,
      hidden = true,
      respect_gitignore = false,
      follow_symlinks = true,
      display_stat = { date = true, size = true, mode = false },
      use_fd = true,
      git_status = true,
      prompt_path = true,
    },
  }

  -- Merge backend-specific extensions (e.g., smart_history)
  local hist_ext = history.get_extension_config()
  if hist_ext then
    ext = vim.tbl_deep_extend("force", ext, hist_ext)
  end

  return ext
end

-- Returns list of extensions to load
---@return string[] extensions
function M.extensions_list()
  local list = { "fzf" }
  vim.list_extend(list, history.get_extensions())
  return list
end

-- Apply Telescope setup
---@param opts table|nil optional override options
---@return table opts effective options
function M.setup(opts)
  opts = opts or {}
  local telescope = require("telescope")

  -- Merge defaults and extensions
  opts.defaults = vim.tbl_deep_extend("force", opts.defaults or {}, M.defaults())
  opts.extensions = vim.tbl_deep_extend("force", opts.extensions or {}, M.extensions())
  opts.extensions_list = opts.extensions_list or M.extensions_list()

  telescope.setup(opts)

  -- Load extensions safely
  for _, ext in ipairs(opts.extensions_list or {}) do
    local ok, err = pcall(telescope.load_extension, ext)
    if not ok then
      notify(string.format("Failed to load telescope extension '%s': %s", ext, err), levels.WARN)
    end
  end

  -- Highlight selection
  hl_selection.setup()

  return opts
end

return M
