---@module 'config.translate.replace'
---Provides helper functions for text replacement using translate.nvim
---
---Responsibilities:
---- execute the translate.nvim command for either a whole range or multiple
---  safe subranges when skipping code is requested.
---- Keep the interface small: replace_range(start, end, target_lang, opts)
local M = {}

---@class TranslateReplaceOptions
---@field nocode boolean|nil whether to avoid translating fenced/inline code

local filter = require("config.translate.filter")

---Replace a given range with translated text.
---If opts.nocode is true, the function will determine sub-ranges that exclude
---fenced code blocks and lines with inline code markers and call the external
---Translate command for each sub-range separately.
---@param start_line number 1-based start line (inclusive)
---@param end_line number 1-based end line (inclusive)
---@param target_lang string target language code (e.g. "DE", "EN")
---@param opts TranslateReplaceOptions|nil
M.replace_range = function(start_line, end_line, target_lang, opts)
  opts = opts or {}
  local nocode = opts.nocode or false

  -- Simple guard
  if not start_line or not end_line or start_line > end_line then
    vim.notify("Invalid range for translation", vim.log.levels.WARN)
    return
  end

  if not nocode then
    -- single command for whole range
    vim.cmd(string.format("%d,%dTranslate %s -output=replace", start_line, end_line, target_lang))
    return
  end

  -- nocode == true: compute safe subranges and translate them individually
  local bufnr = vim.api.nvim_get_current_buf()
  local ranges = filter.get_translatable_line_ranges(bufnr, start_line, end_line)

  if not ranges or #ranges == 0 then
    vim.notify("No translatable text found (skipped fenced code and inline code).", vim.log.levels.INFO)
    return
  end

  -- iterate over safe ranges and translate each
  for _, r in ipairs(ranges) do
    local s = r.start
    local e = r["end"]
    -- defensive check
    if s and e and s <= e then
      vim.cmd(string.format("%d,%dTranslate %s -output=replace", s, e, target_lang))
    end
  end
end

return M
