---@module 'custom.markdown.fenced_fix.@types'

---@class Custom.MD.FencedFix.Opts
---@field inline_base_hl? string[]  -- preference order for "orange-ish" look
---@field inline_style? { bold?: boolean, italic?: boolean, underline?: boolean, undercurl?: boolean }
---@field delimiter_hl? string      -- subtle look for backtick delimiters
---@field enable_legacy? boolean    -- also touch legacy regex groups
---@field enable_ts? boolean        -- touch Tree-sitter highlight groups

return  {}
