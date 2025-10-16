---@module 'translate.replace'
---Provides helper functions for text replacement using translate.nvim

local M = {}

---Replace a given range with translated text
---@param start_line number
---@param end_line number
---@param target_lang string
M.replace_range = function(start_line, end_line, target_lang)
    vim.cmd(string.format("%d,%dTranslate %s -output=replace", start_line, end_line, target_lang))
end

return M
