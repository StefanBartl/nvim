---@module 'ui.types.ibl'

---@class UiHooksIblHl
---@field indent string?                 -- highlight link target for IblIndent
---@field whitespace string?             -- highlight link target for IblWhitespace
---@field scope string?                  -- highlight link target for IblScope
---@field alias_char_to_indent boolean?  -- if true, link IblChar -> IblIndent

---@class UiHooksIbl
---@field hl UiHooksIblHl?
---@field enable_hooks boolean?          -- register ibl.hooks (HIGHLIGHT_SETUP)
---@field enable_shim boolean?           -- register ColorScheme shim as safety net

---@class UiHooksConfig
---@field ibl UiHooksIbl?

---@class _UiHooksState
---@field augroups table<string, integer>  -- name -> augroup id
---@field ibl_registered boolean
---@field colorscheme_shim boolean
