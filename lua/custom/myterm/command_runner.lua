---@module 'myterm.command_runner'
---@brief Command input and dispatch logic for terminal instances
---@description
--- This module handles user-supplied command storage and terminal dispatch.
--- It allows running a saved command in a focused terminal or sending one directly in the background.
--- It integrates with `myterm.state` to track target terminals.

local M = {}

-- State Tracking
local state = require("custom.myterm.state")

---@type string
local current_command = ""

--- Prompts the user for a command and stores it for later use
---@return nil
function M.set_command()
  current_command = vim.fn.input("Command: ")
end

--- Clears the stored command
---@return nil
function M.clear_command()
  current_command = ""
end

--- Sends the stored command to the given or currently focused terminal.
--- If the terminal window is hidden, it will be reopened.
---@param id? integer Optional terminal ID to target
---@return boolean success, string? err
function M.run_command(id)
  if current_command == "" then
    current_command = vim.fn.input("Command: ")
  end

  local term = id and state.get(id) or state.get_last_focused()
  if not term then
    return false, "No target terminal found"
  end

  if not vim.api.nvim_buf_is_valid(term.buf) then
    return false, "Terminal buffer is invalid"
  end

  -- Reopen window if necessary
  if not vim.api.nvim_win_is_valid(term.win) then
    local win
    if term.mode == "horizontal" then
      vim.cmd("split")
      vim.api.nvim_win_set_height(0, 10)
      win = vim.api.nvim_get_current_win()
    elseif term.mode == "vertical" then
      vim.cmd("vsplit")
      vim.api.nvim_win_set_width(0, 80)
      win = vim.api.nvim_get_current_win()
    elseif term.mode == "float" then
      local width = math.floor(vim.o.columns * 0.8)
      local height = math.floor(vim.o.lines * 0.8)
      local col = math.floor((vim.o.columns - width) / 2)
      local row = math.floor((vim.o.lines - height) / 2)
      win = vim.api.nvim_open_win(term.buf, true, {
        relative = "editor",
        width = width,
        height = height,
        col = col,
        row = row,
        style = "minimal",
        border = "rounded",
      })
    end

    term.win = win
  else
    vim.api.nvim_set_current_win(term.win)
  end

  vim.api.nvim_set_current_buf(term.buf)
  vim.cmd("startinsert")
  state.set_focus(term.id)

  local ok, err = pcall(vim.fn.chansend, term.job_id, { current_command .. "\r\n" })
  if not ok then
    return false, type(err) == "string" and err or tostring(err or "unknown error")
  end

  return true
end

--- Sends a one-off command to a terminal by ID without focusing or showing it
---@param id integer
---@param cmd string
---@return boolean success, string? err
function M.send_background(id, cmd)
  assert(type(id) == "number", "id must be a number")
  assert(type(cmd) == "string" and cmd ~= "", "cmd must be a non-empty string")

  local term = state.get(id)
  if not term then
    return false, "Terminal does not exist"
  end

  if not vim.api.nvim_buf_is_valid(term.buf) then
    return false, "Terminal buffer is invalid"
  end

  local ok, err = pcall(vim.fn.chansend, term.job_id, { cmd .. "\r\n" })
  if not ok then
    return false, type(err) == "string" and err or tostring(err or "unknown error")
  end

  return true
end

return M
