---@module 'wkddap.@types'

---@class DapSetupOptions
---@field languages? string[] List of languages to enable (default: all available)
---@field ui? DapUiOptions UI configuration options
---@field keymaps? DapKeymapOptions Keymap configuration options
---@field commands? DapCommandOptions Command configuration options
---@field adapters? table<string, table> Custom adapter overrides
---@field configurations? table<string, table[]> Custom launch configurations
---@field auto_install? boolean Auto-install missing adapters via Mason (default: false)
---@field log_level? integer Logging level (vim.log.levels)

---@class DapUiOptions
---@field enable? boolean Enable DAP UI integration (default: true)
---@field virtual_text? boolean Enable virtual text (default: true)
---@field signs? boolean Enable gutter signs (default: true)
---@field highlights? boolean Configure custom highlights (default: true)

---@class DapKeymapOptions
---@field enable? boolean Enable default keymaps (default: true)
---@field prefix? string Leader prefix for DAP keymaps (default: "<leader>d")

---@class DapCommandOptions
---@field enable? boolean Enable user commands (default: true)
---@field autocmds? boolean Enable autocommands (default: true)



return {}
