---@module 'custom.find_config.config.defaults'
---@description Default configuration values for find_config module

---@class Custom.FindConfig.Defaults
local M = {}

--- Default engine to use when none specified
---@type '"fzf"'|'"telescope"'
M.engine = "telescope"

--- Default keymap configuration
---@class Custom.FindConfig.KeymapDefaults
M.keymaps = {
  --- Enable keymap registration
  ---@type boolean
  enable = true,

  --- Keymap prefix (leader key)
  ---@type string
  prefix = "<leader>",

  --- Find files in config keymap suffix
  ---@type string
  find = "fc",

  --- Grep in config keymap suffix
  ---@type string
  grep = "gc",
}

--- Default user command configuration
---@class Custom.FindConfig.UsercmdDefaults
M.usercmds = {
  --- Enable user command registration
  ---@type boolean
  enable = true,

  --- User command name for file finding
  ---@type string
  find = "FindConfig",

  --- User command name for live grep
  ---@type string
  grep = "GrepConfig",
}

return M
