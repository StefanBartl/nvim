---@module 'config.neotree'
---@brief Neo-tree unified configuration and initialization

local lazy = require("lib.lazy")
local CURRENT_HL_DEFAULTS = lazy.require("config.neotree.current_hl.defaults")
local CWD_SYNC_DEFAULTS = lazy.require("config.neotree.cwd_sync.defaults")
local TRASH_DEFAULTS = lazy.require("config.neotree.trash.defaults")
local event_patch = require("config.neotree.utils.event_patch")

local M = {}

--- Default configuration
---@type Cfg.NeoTree.InitOpts
local defaults = {
  debug = false,
  busy_guard = false,
  default_position = "left",
  restore_last_position = false,
  window_debug = false,
  window_open = false,
  reveal_current_file = true,
  only_lhs = false,
  current_hl = CURRENT_HL_DEFAULTS,
  cwd_sync = CWD_SYNC_DEFAULTS,
  trash = TRASH_DEFAULTS,
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

--- Initialize CWD sync
---@param config Cfg.NeoTree.CwdSync.Config|boolean
---@return nil
local function setup_cwd_sync(config)
  local cfg = vim.tbl_extend("force", CWD_SYNC_DEFAULTS, config or {})
  require("config.neotree.cwd_sync").setup(cfg)
end

--- Main setup function
---@param opts Cfg.NeoTree.InitOpts|nil User configuration options
---@return nil
function M.setup(opts)
  opts = opts or {}

  -- Merge user options with defaults
  if type(opts) == "table" then
    M.options = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts)
  end

  -- CRITICAL: Patch fs_watch callbacks BEFORE any Neo-tree usage
  -- Try both patching methods for maximum coverage
  local patch_ok = event_patch.patch()
  local watcher_patch_ok = event_patch.patch_watcher_start()

  if not patch_ok and not watcher_patch_ok then
    vim.notify(
      "[Neo-tree] Warning: Could not patch fs_watch callbacks. EPERM errors may occur during file operations.",
      vim.log.levels.WARN
    )
  end

  -- ================
  -- Setup subsystems

  if M.options.trash then
    setup_trash(M.options.trash)
  end

  if M.options.reveal_current_file then
    require("config.neotree.window.open.keymaps.reveal_current_file").attach()
  end
  if M.options.only_lhs then
    require("config.neotree.window.open.keymaps.only_lhs").attach()
  end

  if M.options.current_hl then
    setup_current_hl(M.options.current_hl)
  end

  if M.options.cwd_sync.enabled then
    setup_cwd_sync(M.options.cwd_sync)
  end

  require("config.neotree.autocmds").attach()
  require("config.neotree.usercmds").enable()
  require("config.neotree.window.highlight").setup({ all = true })

  -- Source-Switcher Keymap
  vim.keymap.set("n", "<leader>ns", function()
    require("config.neotree.sources.switcher").show_picker()
  end, { desc = "[Neo-tree] Switch Source" })
end

---@type Cfg.NeoTree.SetupModule
return M
