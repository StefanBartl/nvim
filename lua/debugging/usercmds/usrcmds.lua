---@module 'debugging.usercmds'

local M = {}

---@return nil
function M.attach()
  local ok_buflib, buflib = pcall(require, "lib.buf_win_tab.buffer_utils")
  local ok_winlib, winlib = pcall(require, "lib.buf_win_tab.windows_utils")
  local ok_tablib, tablib = pcall(require, "lib.buf_win_tab.tabs_utils")

  if ok_buflib then
    vim.api.nvim_create_user_command("BufReport", function()
      local r = buflib.print_summary()
      for _, l in ipairs(r.textual) do
        vim.notify(l, vim.log.levels.INFO)
      end
    end, { desc = "[debugging] Buffer-Report to :messages" })
  end

  if ok_tablib then
    vim.api.nvim_create_user_command("TabReport", function()
      local r = tablib.collect_report()
      for _, l in ipairs(r.textual) do
        vim.notify(l, vim.log.levels.INFO)
      end
    end, { desc = "[debugging] Tab-Report to :messages" })
  end

  if ok_winlib then
    vim.api.nvim_create_user_command("WinReport", function(opts)
      local winid = nil
      if opts.args ~= "" then
        winid = tonumber(opts.args)
        if not winid or not vim.api.nvim_win_is_valid(winid) then
          vim.notify("Invalid window ID: " .. opts.args, vim.log.levels.ERROR)
          return
        end
      end

      local r = winlib.collect_win_report(winid)
      for _, l in ipairs(r.textual) do
        vim.notify(l, vim.log.levels.INFO)
      end
    end, {
      nargs = "?",
      desc = "[debugging] Window-Report to :messages (optional: window ID)",
    })
  end
end

return M
