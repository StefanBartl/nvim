---@module 'debugging.usercmds.reports'

local buflib = require("lib.buf_win_tab.buffer_utils")
local winlib = require("lib.buf_win_tab.windows_utils")
local tablib = require("lib.buf_win_tab.tabs_utils")

local M = {}

---@return nil
function M.enable()
  vim.api.nvim_create_user_command("BufReport", function()
    buflib.print_summary()
  end, { desc = "[debugging] Prints a Buffer-Report to :messages" })

  vim.api.nvim_create_user_command("TabReport", function()
    local r = tablib.collect_report()
    for _, l in ipairs(r.textual) do
      vim.notify(l, vim.log.levels.INFO)
    end
  end, { desc = "[debugging] Prints a Tab-Report to :messages" })

  vim.api.nvim_create_user_command("WinReport", function(_opts)
    local winid = nil
    if _opts.args ~= "" then
      winid = tonumber(_opts.args)
      if not winid or not vim.api.nvim_win_is_valid(winid) then
        vim.notify("Invalid window ID: " .. _opts.args, vim.log.levels.ERROR)
        return
      end
    end

    local r = winlib.collect_win_report(winid)
    for _, l in ipairs(r.textual) do
      vim.notify(l, vim.log.levels.INFO)
    end
  end, {
    nargs = "?",
    desc = "[debugging] Prints a Window-Report to :messages (optional: specify window ID)",
  })
end

return M
