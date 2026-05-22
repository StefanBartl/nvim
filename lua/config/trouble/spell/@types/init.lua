---@module 'config.trouble.spell.types'
---@brief Type definitions for trouble.nvim spell integration.

---@alias Cfg.Spell.ErrorType
---| "bad"
---| "rare"
---| "local"
---| "caps"

---@class Cfg.Spell.Entry
---@field [1] string
---@field [2] Cfg.Spell.ErrorType
---@field [3] integer

---@class Cfg.Spell.Opts
---@field severity? vim.diagnostic.Severity
---@field source? string
---@field keymap? string|false
---@field keymap_fix? string|false
---@field keymap_fix1? string|false

---@class Cfg.Spell.Config
---@field severity vim.diagnostic.Severity
---@field source string
---@field keymap string|false
---@field keymap_fix string|false
---@field keymap_fix1 string|false

---@class Cfg.Spell.Module
---@field setup fun(opts?: Cfg.Spell.Opts)
---@field run fun()
---@field clear fun()
---@field refresh fun()
---@field goto_next fun()
---@field fix_current fun()
---@field get_config fun(): Cfg.Spell.Config

return {}
