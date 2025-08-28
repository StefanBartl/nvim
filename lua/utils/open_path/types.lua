---@module 'utils.open_path.types'
--- Shared type aliases and enums for open_path modules.

---@alias OpenSplitOrientation "vertical"|"horizontal"

---@enum OpenKind
local OpenKind = {
  edit = "edit",
  vsplit = "vsplit",
  split = "split",
  tabedit = "tabedit",
}

---@class OpenPathConfig
---@field require_existing boolean   -- If true, silently return when path doesn't exist on disk
---@field notify boolean             -- If true, show warnings (otherwise, silent returns)
---@field split OpenSplitOrientation -- Default split orientation for window target
---@field set_default_keymaps boolean -- If true, defines default gt/gtw/gtt mappings

---@class DetectedPath
---@field abs string                 -- Absolute normalized path
---@field is_dir boolean             -- True if directory
---@field line integer|nil           -- 1-based line number if suffix was provided
---@field col integer|nil            -- 1-based column number if suffix was provided

return {
  OpenKind = OpenKind,
}

