---@module 'autocmds.markdown'
--- Markdown-focused autocommands with modular gofile_cases.
--- Exposes `enable(cfg)` to wire features.

---@class MdAutoCmds
local M = {}

-- Public API -----------------------------------------------------------------

--- Enable Markdown-related autocommands per feature.
--- @param cfg table|nil
function M.enable(cfg)
  local defaults = require("autocmds.markdown.defaults")
  cfg = vim.tbl_deep_extend("force", vim.deepcopy(defaults), cfg or {})

end

return M
