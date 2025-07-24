---@module 'autocmds.starttimelog'
---@description
---Logging startup tme to logfile path

local start_time = vim.loop.hrtime()
local logfile = vim.fn.stdpath("data") .. "/starttime.log"

--[[
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    local end_time = vim.loop.hrtime()
    local delta_ms = (end_time - start_time) / 1e6
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")

    local log_line = string.format("[nvim] %s - Startup Time: %.2f ms\n", timestamp, delta_ms)

    local ok, fd = pcall(io.open, logfile, "a")
    if ok and fd then
      fd:write(log_line)
      fd:close()
    else
      vim.schedule(function()
        vim.notify("Failed to write /starttime.log", vim.log.levels.WARN)
      end)
    end
  end,
})
--]]
