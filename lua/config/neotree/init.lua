---@module 'config.neotree'
---@brief Neo-tree unified configuration and initialization

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
}

--- Active configuration (merged with user options)
---@type Cfg.NeoTree.InitOpts
M.options = vim.deepcopy(defaults)

---@return Cfg.NeoTree.Position|"left"
function M.get_default_position()
  return M.options.default_position or "left"
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

  -- ================
  -- Setup subsystems

  if M.options.reveal_current_file then
    require("config.neotree.window.open.keymaps.reveal_current_file").attach()
  end
  if M.options.only_lhs then
    require("config.neotree.window.open.keymaps.only_lhs").attach()
  end

  require("config.neotree.autocmds").attach() -- disable statusline;
  require("config.neotree.usercmds").enable()
  -- Kept alongside filetree.nvim's window_style feature (statusline default
  -- true, highlights_isolate opt-in, both enabled - see personal/init.lua):
  -- isolating a headless test from this fallback (temporarily removing it)
  -- showed window_style's FileType/BufWinEnter/WinEnter-triggered statusline
  -- blanking does NOT reliably apply on its own in headless mode, despite
  -- reaching the module with a verified-correct config - the earlier
  -- "verified" result was this fallback doing the work in parallel, not
  -- window_style. Same open question for highlights_isolate. Both stay here
  -- until that's understood or confirmed working in real interactive use.
  require("config.neotree.window.highlight").setup({ isolate_hl = true })
  require("config.neotree.keymaps.global").attach()
end

---@type Cfg.NeoTree.SetupModule
return M
