-- Purpose: Simple terminal manager for inline command execution
-- Thx to tjdevries: https://github.com/tjdevries/advent-of-nvim/blob/master/nvim/plugin/floaterminal.lua

local M = {}

local job_id = 0
local current_command = ""

--- Open a terminal in a horizontal split at the bottom
function M.open()
  vim.cmd.vnew()                    -- create a new vertical split
  vim.cmd.term()                    -- open a terminal
  vim.cmd.wincmd("J")               -- move terminal window to bottom
  vim.api.nvim_win_set_height(0, 5) -- set height to 5 lines
  job_id = vim.bo.channel           -- store the terminal channel ID
end

--- Ask user for a command and store it
function M.set_command()
  current_command = vim.fn.input("Command: ")
end

--- Re-run the last command or ask for one if none is set
function M.run_command()
  if current_command == "" then
    current_command = vim.fn.input("Command: ")
  end
  if job_id == 0 then
    vim.notify("No terminal job running!", vim.log.levels.WARN)
    return
  end
  vim.fn.chansend(job_id, { current_command .. "\r\n" })
end

--- Clear the current command
function M.clear_command()
  current_command = ""
  vim.notify("Command cleared", vim.log.levels.INFO)
end

return M
