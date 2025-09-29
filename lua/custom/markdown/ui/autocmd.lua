---@module 'custom.markdown.ui.autocmd'
--- Lightweight FileType hook (extensible).

local M = {}
local cfg = require("custom.markdown.config").get

---@return nil
function M.setup()
  if not cfg().enable_autocmds then return end
  local aug = vim.api.nvim_create_augroup("MarkdownSetup", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = aug,
    pattern = { "markdown" },
    callback = function(_) end,
    desc = "Attach markdown utilities",
  })
end

return M

