---@module 'debugging.usercmds'

local buflib = require("lib.buf_win_tab.windows_utils")
local tablib = require("lib.buf_win_tab.tabs_utils")

local M = {}

---@return nil
function M.attach()
  vim.api.nvim_create_user_command("BufReport", function()
    local r = buflib.collect_report()
    for _, l in ipairs(r.textual) do
      vim.notify(l, vim.log.levels.INFO)
    end
  end, { desc = "[debugging] Prints a Buffer-Report to :messages" })

  vim.api.nvim_create_user_command("TabReport", function()
    local r = tablib.collect_report()
    for _, l in ipairs(r.textual) do
      vim.notify(l, vim.log.levels.INFO)
    end
  end, { desc = "[debugging] Prints a Tab-Report to :messages" })
end

return M
