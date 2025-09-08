---@module 'types.harpoon'
-- Add these or adapt your existing type file accordingly.

---@alias HarpoonValue string

---@class HarpoonContext
---@field row integer  -- 1-based
---@field col integer  -- 0-based

---@class HarpoonItem
---@field value HarpoonValue
---@field context HarpoonContext|nil

--- Legacy or non-standard item shapes sometimes found in older setups:
---@class HarpoonItemLegacy
---@field path string|nil         -- legacy field; may be present
---@field value string|nil        -- might be missing; we will normalize
---@field context HarpoonContext|nil

---@class HarpoonList
---@field items (HarpoonItem|HarpoonItemLegacy|string)[]  -- allow union
---@field remove fun(self: HarpoonList, index: integer)
---@field save fun(self: HarpoonList)

---@class HarpoonApi
---@field list fun(self: HarpoonApi): HarpoonList
---@field save fun(self: HarpoonApi)
---@field setup fun(self: HarpoonApi, opts: table)


---@class HarpoonPersistPathsOpts
---@field target_specs string[][]|nil  -- list of path segments per target; first segment can be a variable like "$REPOS_DIR" or "$HOME"

