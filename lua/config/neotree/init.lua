---@module 'config.neotree'
---@brief Neo-tree unified configuration and initialization

local M = {}

---Initialize trash system
---@param config Cfg.NeoTree.Trash.Config|boolean
---@return nil
local function setup_trash(config)
  local trash_mod = require("config.neotree.trash")

  -- Default config
  local default_config = {
    debug = false,
    auto_close_buffers = false,
    create_backups = true,
    use_safety_system = true,
    confirm_dangerous = true,
    use_dry_run = false,
  }

  -- Merge user config if table provided
  if type(config) == "table" then
    trash_mod.setup(vim.tbl_deep_extend("force", default_config, config))
  else
    trash_mod.setup(default_config)
  end

  -- Register user commands
  require("config.neotree.trash.commands").setup()
end

---Initialize window opener (with or without debug timing)
---@param debug boolean
---@return nil
local function setup_window_opener(debug)
  if debug then
    require("config.neotree.open.window").attach_opener_mappings({ debug = true })
  else
    require("config.neotree.open.window").attach_opener_mappings()
  end
end

---Initialize current file highlight
---@param config Cfg.NeoTree.CurrentHl.Config|boolean
---@return nil
local function setup_current_hl(config)
  local default_config = {
    colors = {
      file = "green",
      parent = { fg = "darkgreen", underline = false },
    },
  }

  if type(config) == "table" then
    require("config.neotree.current_hl").setup(vim.tbl_deep_extend("force", default_config, config))
  else
    require("config.neotree.current_hl").setup(default_config)
  end
end

---Initialize CWD sync
---@param config Cfg.NeoTree.CwdSync.Config|boolean
---@return nil
local function setup_cwd_sync(config)
  local default_config = {
    debounce_ms = 150,
    keep_focus = true,
    also_set_nvim_cwd = false,
    open_if_closed = false,
    use_project_root = true,
    project_root_fallback_to_bufdir = true,
    force_position_left = true,
  }

  if type(config) == "table" then
    require("config.neotree.cwd_sync").setup(vim.tbl_deep_extend("force", default_config, config))
  else
    require("config.neotree.cwd_sync").setup(default_config)
  end
end

---Main setup function
---@param opts Cfg.NeoTree.InitOpts|nil
---@return nil
function M.setup(opts)
  opts = opts or {}

  -- 1. Trash system
  if opts.trash then
    setup_trash(opts.trash)
  end

  -- 2. Window opener (debug or normal)
  setup_window_opener(opts.window_debug or opts.debug or false)

  -- 3. Current file highlight
  if opts.current_hl then
    setup_current_hl(opts.current_hl)
  end

  -- 4. CWD sync
  if opts.cwd_sync then
    setup_cwd_sync(opts.cwd_sync)
  end
end

return M
