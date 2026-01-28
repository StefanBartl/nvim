---@module 'config.neotree'
---@brief Neo-tree unified configuration and initialization

local M = {}

--- Default configuration
---@type Cfg.NeoTree.InitOpts
local defaults = {
  debug = false,
  busy_guard = false,
  default_position = "right",
  restore_last_position = false,
  window_debug = false,
  window_open = false,
  reveal_current_file = true,
  only_lhs = false,
  trash = {
    debug = false,
    auto_close_buffers = true,
    create_backups = true,
    use_safety_system = true,
    confirm_dangerous = true,
    use_dry_run = false,
  },
  current_hl = {
    colors = {
      file = "green",
      parent = { fg = "darkgreen", underline = false },
    },
  },
}

--- Active configuration (merged with user options)
---@type Cfg.NeoTree.InitOpts
M.options = vim.deepcopy(defaults)

---@return Cfg.NeoTree.Position|"right"
function M.get_default_position()
  return M.options.default_position or "right"
end

---@return boolean
function M.busy_guard()
  return M.options.busy_guard
end

--- Initialize trash system
---@param config Cfg.NeoTree.Trash.Config|boolean|nil
---@return nil
local function setup_trash(config)
  local trash_mod = require("config.neotree.trash")

  if type(config) == "table" then
    trash_mod.setup(config)
  elseif config == true then
    trash_mod.setup(M.options.trash)
  end

  require("config.neotree.trash.commands").setup()
end

--- Initialize window opener (with or without debug timing)
---@param debug boolean
---@return nil
local function setup_window_opener(debug)
  require("config.neotree.open.window").attach_opener_mappings({ debug = debug })
end

--- Initialize current file highlight
---@param config Cfg.NeoTree.CurrentHl.Config|boolean|nil
---@return nil
local function setup_current_hl(config)
  if type(config) == "table" then
    require("config.neotree.current_hl").setup(config)
  elseif config == true then
    require("config.neotree.current_hl").setup(M.options.current_hl)
  end
end

--- Main setup function
---@param opts Cfg.NeoTree.InitOpts|nil User configuration options
---@return nil
function M.setup(opts)
  -- Merge user options with defaults
  if type(opts) == "table" then
    M.options = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts)
  end

  -- Setup subsystems
  if M.options.trash then
    setup_trash(M.options.trash)
  end

  if M.options.window_open then
    setup_window_opener(
      (M.options.window_debug ~= nil and M.options.window_debug) or M.options.debug or false
    )
  else
    if M.options.reveal_current_file then
      require("config.neotree.open.keymaps.reveal_current_file").attach()
    end
    if M.options.only_lhs then
      require("config.neotree.open.keymaps.only_lhs").attach()
    end
  end

  if M.options.current_hl then
    setup_current_hl(M.options.current_hl)
  end

  -- require("config.neotree.autocmds").attach({})

  -- Register checkhealth
  vim.api.nvim_create_user_command("NeoTreeCheckHealth", function()
    require("config.neotree.checkhealth").check()
  end, {
    desc = "Run Neo-tree config health checks",
  })
end

---@type Cfg.NeoTree.SetupModule
return M
