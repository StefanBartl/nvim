---@module 'debugging.usercmds.reports'

local notify = require("lib.nvim.notify").create("[debugging.usercmds.reports]")

local buflib = require("lib.nvim.buf_win_tab.buffer_utils")
local winlib = require("lib.nvim.buf_win_tab.windows_utils")
local tablib = require("lib.nvim.buf_win_tab.tabs_utils")

local M = {}

---@return nil
function M.enable()
  vim.api.nvim_create_user_command("BufReport", function()
    buflib.print_summary()
  end, { desc = "[debugging.usercmds.reports] Prints a Buffer-Report to :messages" })

  vim.api.nvim_create_user_command("TabReport", function()
    local r = tablib.collect_report()
    for _, l in ipairs(r.textual) do
      notify.info(l)
    end
  end, { desc = "[debugging.usercmds.reports] Prints a Tab-Report to :messages" })

  vim.api.nvim_create_user_command("WinReport", function(_opts)
    local winid = nil
    if _opts.args ~= "" then
      winid = tonumber(_opts.args)
      if not winid or not vim.api.nvim_win_is_valid(winid) then
        notify.error("Invalid window ID: " .. _opts.args)
        return
      end
    end

    local r = winlib.collect_win_report(winid)
    for _, l in ipairs(r.textual) do
      notify.info(l)
    end
  end, {
    nargs = "?",
    desc = "[debugging.usercmds.reports] Prints a Window-Report to :messages (optional: specify window ID)",
  })
end

return M
