---@module 'custom.format.column_align.@types'

---@class Custom.Format.ColAlign.API
---@field align_to_column fun(target_col: number, fill_char: string|nil): nil Align selected character to target column
---@field align_interactive fun(): nil Prompt for column and fill char interactively
---@field align_repeat fun(): nil Repeat last alignment operation
---@field align_multiline fun(target_col: number, fill_char: string|nil): nil Align multiple lines (visual block)

---@class Custom.Format.ColAlign.State
---@field last_target_col number|nil Last used target column
---@field last_fill_char string|nil Last used fill character

return {}
