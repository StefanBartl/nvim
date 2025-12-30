---@meta
---@module 'lib.hover_select.@types'

-- === init ===
---@class HoverSelectOptions
---@field items string[] List of items to display (one per line)
---@field on_select fun(selected: string, index: integer): nil Callback when item is selected
---@field buf_options? table<string, any> Additional buffer options to merge
---@field win_options? table<string, any> Additional window options to merge
---@field title? string Optional window title
---@field relative? string Window positioning ('cursor', 'win', 'editor')
---@field width? integer Window width (default: auto-calculated)
---@field height? integer Window height (default: auto-calculated)

---@class HoverSelectState
---@field bufnr integer|nil Buffer number
---@field winid integer|nil Window ID
---@field items string[] Original items list
---@field on_select function|nil Selection callback

return {}
