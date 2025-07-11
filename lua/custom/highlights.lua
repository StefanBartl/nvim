---@module 'custom.highlights'

local M = {}

---@param hl fun(name: string, opts: table)
---@param c table
function M.override(hl, c)
  if vim.g.transparency then
    local transparent = { bg = "NONE", ctermbg = "NONE" }

    hl("Normal", transparent)
    hl("NormalNC", transparent)
    hl("EndOfBuffer", transparent)
    hl("SignColumn", transparent)
    hl("VertSplit", transparent)
    hl("LineNr", transparent)
    hl("CursorLineNr", transparent)
    hl("Folded", transparent)
    hl("NormalFloat", transparent)
    hl("FloatBorder", transparent)
    hl("Pmenu", transparent)
    hl("TelescopeNormal", transparent)
    hl("TelescopeBorder", transparent)
    hl("StatusLine", transparent)
    hl("StatusLineNC", transparent)
    hl("MsgArea", transparent)
  end
end

return M

