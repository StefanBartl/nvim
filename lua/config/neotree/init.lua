---@module 'config.neotree'
---@brief Neo-tree unified configuration and initialization

local lazy = require("lib.lua.lazy")
local TRASH_DEFAULTS = lazy.require("config.neotree.trash.defaults")
local event_patch = require("config.neotree.utils.event_patch")
local notify = require("lib.nvim.notify").create("[config.neotree]")

local M = {}

--- Default configuration
---@type Cfg.NeoTree.InitOpts
local defaults = {
  debug = false,
  default_position = "left",
  restore_last_position = false,
  window_debug = false,
  window_open = false,
  reveal_current_file = true,
  only_lhs = false,
  trash = TRASH_DEFAULTS,
}

--- Active configuration (merged with user options)
---@type Cfg.NeoTree.InitOpts
M.options = vim.deepcopy(defaults)

---@return Cfg.NeoTree.Position|"left"
function M.get_default_position()
  return M.options.default_position or "left"
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
    notify.warn(
      "[Neo-tree] Warning: Could not patch fs_watch callbacks. EPERM errors may occur during file operations."
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

  require("config.neotree.autocmds").attach() -- disable statusline;
  require("config.neotree.usercmds").enable()
  require("config.neotree.window.highlight").setup({ all = true })
  require("config.neotree.keymaps.global").attach()
end

---@type Cfg.NeoTree.SetupModule
return M
