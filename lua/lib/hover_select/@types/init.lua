---@meta
---@module 'lib.hover_select.@types'

-- === init ===
---@class Lib.HoverSelect.Options
---@field items string[] List of items to display (one per line)
---@field on_select fun(selected: string|string[], index: integer|integer[]): nil Callback when item(s) selected
---@field multi_select? boolean Enable multi-selection with Tab/Shift-Tab (default: false)
---@field buf_options? table<string, any> Additional buffer options to merge
---@field win_options? table<string, any> Additional window options to merge
---@field title? string Optional window title
---@field relative? string Window positioning ('cursor', 'win', 'editor')
---@field width? integer Window width (default: auto-calculated)
---@field height? integer Window height (default: auto-calculated)

---@class Lib.HoverSelect.State
---@field bufnr integer|nil Buffer number
---@field winid integer|nil Window ID
---@field items string[] Original items list
---@field on_select function|nil Selection callback
---@field multi_select boolean Multi-selection enabled
---@field selections table<integer, boolean> Selected line indices (1-based)
---@field ns_id integer Namespace ID for highlights

return {}
