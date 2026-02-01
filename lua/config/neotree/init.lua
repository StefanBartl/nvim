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
  default_position = "right",
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

  if M.options.cwd_sync.enabled then
    setup_cwd_sync(M.options.cwd_sync)
  end

  -- Register checkhealth
  vim.api.nvim_create_user_command("NeoTreeCheckHealth", function()
    require("config.neotree.checkhealth").check()
  end, {
    desc = "Run Neo-tree config health checks",
  })
end

---Health check
function M.health_check()
  local results = {}

  -- Check event patch
  table.insert(results, {
    name = "FS Watch Callback Patch",
    status = event_patch.is_patched() and "✓" or "✗",
  })

  -- Check watcher quarantine
  local wq = require("config.neotree.watcher_quarantine")
  local healthy, reason = wq.health_check()
  table.insert(results, {
    name = "Watcher Quarantine",
    status = healthy and "✓" or "✗",
    reason = reason,
  })

  -- Print results
  local lines = { "=== Neo-tree Health Check ===" }
  for _, r in ipairs(results) do
    local line = string.format("%s %s", r.status, r.name)
    if r.reason then
      line = line .. " (" .. r.reason .. ")"
    end
    table.insert(lines, line)
  end

  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end

---@type Cfg.NeoTree.SetupModule
return M
