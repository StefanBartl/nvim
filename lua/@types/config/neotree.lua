---@meta
---@module 'config.types.neotree'

---@class NeoTreeWslFM
---@field setup fun(cfg: WslOpenConfig|nil)
---@field open fun(state: table): boolean

---@class WslOpenConfig
---@field backend '"auto"'|'"explorer"'|'"wslview"'
---@field silent boolean
