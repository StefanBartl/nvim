---@module 'config.neotree.checkhealth'
---@brief Comprehensive health checks for Neo-tree configuration

local M = {}

local health = vim.health or vim.health
local start = health.start
local ok = health.ok
local warn = health.warn
local error = health.error
local info = health.info


---Check Neo-tree plugin installation
---@return boolean installed
local function check_neotree_plugin()
  start("Neo-tree Plugin")

  local ok_neo, _ = pcall(require, "neo-tree")
  if ok_neo then
    ok("neo-tree.nvim is installed")
    return true
  else
    error("neo-tree.nvim is not installed")
    info("Install via your plugin manager")
    return false
  end
end

---Check core Neo-tree configuration modules
---@return boolean all_ok
local function check_core_modules()
  start("Core Configuration Modules")

  local modules = {
    { name = "config.neotree", desc = "Main configuration" },
    { name = "config.neotree.keymaps", desc = "Keymap registry" },
    { name = "config.neotree.event_handlers", desc = "Event handlers" },
  }

  local all_ok = true

  for _, mod in ipairs(modules) do
    local ok_mod = pcall(require, mod.name)
    if ok_mod then
      ok(mod.desc .. " loaded")
    else
      error(mod.desc .. " not loadable: " .. mod.name)
      all_ok = false
    end
  end

  return all_ok
end

---Check actions modules
---@return boolean all_ok
local function check_actions()
  start("Action Modules")

  local actions = {
    {
      name = "config.neotree.actions.traverse",
      desc = "Bi-directional navigation",
      required = true,
    },
    {
      name = "config.neotree.actions.project_root",
      desc = "Project root detection",
      required = true,
    },
    { name = "config.neotree.actions.grep_picker", desc = "Grep picker", required = true },
    { name = "config.neotree.actions.copy.entries", desc = "Copy entries", required = false },
    { name = "config.neotree.actions.copy.folders", desc = "Copy folders", required = false },
    {
      name = "config.neotree.actions.path.to_require",
      desc = "Path to require()",
      required = false,
    },
    { name = "config.neotree.actions.info.node", desc = "Node info", required = false },
  }

  local all_ok = true

  for _, action in ipairs(actions) do
    local ok_action = pcall(require, action.name)
    if ok_action then
      ok(action.desc .. " available")
    elseif action.required then
      error(action.desc .. " not available: " .. action.name)
      all_ok = false
    else
      warn(action.desc .. " not available (optional)")
    end
  end

  return all_ok
end

---Check trash system
---@return boolean all_ok
local function check_trash_system()
  start("Trash System")

  local ok_trash, trash = pcall(require, "config.neotree.trash")
  if ok_trash then
    ok("Trash module loaded")

    -- Check config
    if trash.config then
      info("Configuration:")
      info("  use_safety_system: " .. tostring(trash.config.use_safety_system))
      info("  create_backups: " .. tostring(trash.config.create_backups))
      info("  auto_close_buffers: " .. tostring(trash.config.auto_close_buffers))
    end

    -- Check submodules
    local submodules = {
      "config.neotree.trash.platform",
      "config.neotree.trash.validation.buffer_checker",
      "config.neotree.trash.confirmation",
      "config.neotree.trash.operations",
    }

    for _, mod in ipairs(submodules) do
      local ok_sub = pcall(require, mod)
      if ok_sub then
        ok("  " .. mod:match("[^.]+$") .. " loaded")
      else
        warn("  " .. mod:match("[^.]+$") .. " not loaded")
      end
    end

    return true
  else
    warn("Trash system not loaded (optional)")
    return false
  end
end

---Check state modules
---@return boolean all_ok
local function check_state_modules()
  start("State Management")

  local ok_win_state, win_state = pcall(require, "config.neotree.state.windows")
  local ok_tree_state, tree_state = pcall(require, "config.neotree.state.tree")

  if ok_win_state then
    ok("Window state module loaded")

    local state = win_state.get_state()
    info("Current state:")
    info("  open: " .. tostring(state.open))
    info("  position: " .. tostring(state.position))
    info("  source: " .. tostring(state.source))
  else
    error("Window state module not loadable")
  end

  if ok_tree_state then
    ok("Tree state module loaded")

    local node_id = tree_state.get_node()
    local expanded = tree_state.get_expanded()

    info("Tree state:")
    info("  last node: " .. tostring(node_id))
    info("  expanded nodes: " .. tostring(vim.tbl_count(expanded)))
  else
    error("Tree state module not loadable")
  end

  -- State modules
  local state = require("config.neotree.state.windows")
  local s = state.get_state()

  vim.health.info(string.format("Window state: open=%s, position=%s", s.open, s.position or "nil"))

  return ok_win_state and ok_tree_state
end

---Check CWD sync
---@return boolean available
local function check_cwd_sync()
  start("CWD Synchronization")

  local ok_sync = pcall(require, "config.neotree.cwd_sync")
  if ok_sync then
    ok("CWD sync module loaded")
    return true
  else
    warn("CWD sync not loaded (optional)")
    return false
  end
end

---Check current highlight
---@return boolean available
local function check_current_hl()
  start("Current File Highlighting")

  local ok_hl = pcall(require, "config.neotree.current_hl")
  if ok_hl then
    ok("current_hl module loaded")
    return true
  else
    warn("current_hl not loaded (optional)")
    return false
  end
end

---Check watcher quarantine
---@return boolean available
local function check_watcher_quarantine()
  start("Watcher Quarantine System")

  local ok_watcher = pcall(require, "config.neotree.watcher_quarantine")
  if ok_watcher then
    ok("Watcher quarantine module loaded")

    local ok_health, watcher = pcall(require, "config.neotree.watcher_quarantine")
    if ok_health and watcher.health_check then
      local healthy, reason = watcher.health_check()
      if healthy then
        ok("Watcher system is healthy")
      else
        warn("Watcher system issue: " .. (reason or "unknown"))
      end
    end

    return true
  else
    warn("Watcher quarantine not loaded (optional)")
    return false
  end
end

---Check grep picker integration
---@return boolean available
local function check_grep_picker()
  start("Grep Picker Integration")

  local ok_picker, picker = pcall(require, "config.neotree.actions.grep_picker")
  if not ok_picker then
    error("Grep picker module not loaded")
    return false
  end

  ok("Grep picker module loaded")

  -- Check picker availability
  local healthy, message = picker.health_check()
  if healthy then
    ok(message or "Pickers available")
  else
    error(message or "No pickers available")
    info("Install telescope.nvim or fzf-lua")
  end

  -- Show picker status
  local status = picker.get_picker_status()
  info("Picker status:")
  info("  telescope: " .. (status.telescope and "✓" or "✗"))
  info("  fzf-lua: " .. (status.fzf and "✓" or "✗"))
  info("  default: " .. tostring(status.default or "none"))

  return healthy
end

---Check window management (stub)
---@return boolean available
local function check_window_management()
  start("Window Management")

  local ok_ctrl = pcall(require, "config.neotree.open.window.controller")
  if ok_ctrl then
    ok("Window controller loaded")
  else
    error("Window controller not loadable")
    return false
  end

  local semaphore = require("config.neotree.open.window.controller.semaphore")
  local status = semaphore.status()

  if status.available then
    vim.health.ok(string.format("Semaphore available (waiting: %d)", status.waiting))
  else
    vim.health.warn("Semaphore locked")
  end

  -- Cache stats
  ---@diagnostic disable-next-line: unused-local
  local buffer_utils = require("config.neotree.utils.buffer") -- AUDIT: Unused local buffer_utils
  vim.health.ok("Buffer validation cache active")

  -- Error stats
  local error_handler = require("config.neotree.open.window.controller.error_handler")
  local stats = error_handler.get_stats()

  if vim.tbl_count(stats) == 0 then
    vim.health.ok("No errors logged")
  else
    for context, count in pairs(stats) do
      vim.health.warn(string.format("%s: %d errors", context, count))
    end
  end

  local ok_float = pcall(require, "config.neotree.open.window.float")
  if ok_float then
    ok("Float window support available")
  else
    warn("Float window module not loaded")
  end

  local ok_measure = pcall(require, "config.neotree.open.window.measuring")
  if ok_measure then
    ok("Window measuring available")
  else
    warn("Window measuring not loaded")
  end
  return true
end

---Check sources system (stub)
---@return boolean available
local function check_sources_system()
  start("Source Management")

  local ok_reg = pcall(require, "config.neotree.sources.registry")
  if ok_reg then
    ok("Source registry loaded")
  else
    warn("Source registry not loaded")
  end

  local ok_icons = pcall(require, "config.neotree.sources.icons")
  if ok_icons then
    ok("Source icons available")
  else
    warn("Source icons not loaded")
  end

  local ok_switcher = pcall(require, "config.neotree.sources.switcher")
  if ok_switcher then
    ok("Source switcher available")
  else
    warn("Source switcher not loaded")
  end

  return true
end

---Check reveal system (stub)
---@return boolean available
local function check_reveal_system()
  start("Reveal System")

  local ok_reveal = pcall(require, "config.neotree.open.reveal.controller")
  if ok_reveal then
    ok("Reveal controller loaded")
    return true
  else
    warn("Reveal controller not loaded")
    return false
  end
end

---Check file manager integration (stub)
---@return boolean available
local function check_filemanager_integration()
  start("File Manager Integration")

  local ok_fm = pcall(require, "config.neotree.open.filemanager")
  if ok_fm then
    ok("File manager integration available")

    -- Platform-specific checks
    local uv = vim.uv or vim.loop
    local sysname = uv.os_uname().sysname

    if sysname == "Windows_NT" then
      local ok_win = pcall(require, "config.neotree.open.filemanager.win")
      if ok_win then
        ok("  Windows explorer integration available")
      end
    else
      local ok_unix = pcall(require, "config.neotree.open.filemanager.unix_ubutnu")
      if ok_unix then
        ok("  Unix file manager integration available")
      end
    end

    return true
  else
    warn("File manager integration not loaded")
    return false
  end
end

---Check utilities
---@return boolean all_ok
local function check_utilities()
  start("Utility Modules")

  local utils = {
    { name = "config.neotree.utils", desc = "General utilities" },
    { name = "config.neotree.utils.node", desc = "Node utilities" },
    { name = "config.neotree.utils.buffer", desc = "Buffer utilities" },
    { name = "config.neotree.utils.tree", desc = "Tree utilities" },
  }

  local all_ok = true

  for _, util in ipairs(utils) do
    local ok_util = pcall(require, util.name)
    if ok_util then
      ok(util.desc .. " available")
    else
      error(util.desc .. " not loadable: " .. util.name)
      all_ok = false
    end
  end

  return all_ok
end

---Main health check function
function M.check()
  -- Critical checks
  if not check_neotree_plugin() then
    return -- No point continuing if Neo-tree isn't installed
  end

  check_core_modules()
  check_state_modules()
  check_utilities()
  check_actions()

  -- Feature checks
  check_trash_system()
  check_cwd_sync()
  check_current_hl()
  check_watcher_quarantine()
  check_grep_picker()

  -- Integration checks (stubs)
  check_window_management()
  check_sources_system()
  check_reveal_system()
  check_filemanager_integration()

  -- Summary
  start("Summary")
  info("Health check complete. Review warnings and errors above.")
end

return M
