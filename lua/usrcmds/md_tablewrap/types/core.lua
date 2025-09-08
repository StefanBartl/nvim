---@module 'usrcmds.md_tablewrap.types.core'

---@alias MDMode '"detect"'|'"force"'

---@class MDWrapBounds
---@field start_lnum integer   -- inclusive (1-based)
---@field end_lnum integer     -- inclusive (1-based)
---@field indent_col integer   -- visual columns before first '|'
---@field indent_str string    -- exact prefix before first '|'

---@class MDColumnAlign
---@field left boolean
---@field right boolean

---@class MDTableParse
---@field header string[]|nil
---@field body string[][]
---@field has_separator boolean
---@field aligns MDColumnAlign[]
---@field ncols integer

---@class MDWrapPlan
---@field col_widths integer[] -- content widths only (padding excluded)
---@field padding integer      -- per-side padding inside each cell'
