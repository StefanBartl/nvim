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
  -- `window/open/keymaps/reveal_current_file.lua` no longer exists in this
  -- config (see docs/NOTES/.../Keymaps/NeoTree.md) -- true would crash
  -- M.setup() on the first caller that doesn't override it.
  reveal_current_file = false,
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

  -- `window/open/keymaps/reveal_current_file.lua` no longer exists in this
  -- config (see docs/NOTES/.../Keymaps/NeoTree.md); `reveal_current_file`
  -- defaults to false for exactly that reason, so there is nothing to wire
  -- up here even when a caller sets it -- the option is a documented no-op
  -- until that module is rebuilt.
  if M.options.only_lhs then
    require("config.neotree.window.open.keymaps.only_lhs").attach()
  end

  -- Statusline blanking + HL isolation are filetree.nvim's window_style
  -- feature now (see personal/init.lua) - confirmed working in real
  -- interactive use; the config.neotree autocmds/disable_statusline +
  -- window/highlight duplicates were removed.
  require("config.neotree.usercmds").enable()
  require("config.neotree.keymaps.global").attach()
end

---@type Cfg.NeoTree.SetupModule
return M
