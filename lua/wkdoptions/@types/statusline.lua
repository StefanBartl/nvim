---@meta
---@module 'wkdoptions.@types.statusline'
---
--- Type definitions for statusline integration API

---@alias BreadcrumbsEllipsisMode
---| '"middle"' # Ellipsize in the middle (default)
---| '"end"'    # Ellipsize at the end

---@class BreadcrumbsStlOptions
---@field include_path boolean|nil # Include file path (default: true)
---@field sep string|nil # Separator between path and context (default: " › ")
---@field ellipsis BreadcrumbsEllipsisMode|nil # Ellipsization mode (default: "middle")
---@field max_width integer|nil # Maximum width before ellipsization (default: window-aware)
---@field path_resolver fun(abs: string): string|nil # Custom path resolver (default: repo_relative)
---@field include_icon boolean|nil # Include file icon (default: true, requires ui.custom_stl_module)
---@field band_highlight boolean|nil # Wrap with mode-band highlight (default: true, requires ui.custom_stl_module)

return {}
