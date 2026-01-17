---@module 'custom.markdown.tableview'
--- Controller for Markdown table preview.
--- Collects tables, offers selection, and renders via renderer.

local M = {}

---@param opts Custom.TableView.Options|nil
---@return nil
function M.setup(opts)
  opts = opts or {}
  require("custom.markdown.tableview.autocmds").setup()
end

return M
