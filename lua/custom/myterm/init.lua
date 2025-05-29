---@module 'myterm'
---@brief Public API for terminal management
---@description
--- Main public interface of the myterm module.
--- Provides commands to create, toggle, run, focus, and close terminal instances.
--- Acts as the controller layer, orchestrating internal state and terminal logic modules.

local M = {}

-- Submodules
local manager = require("custom.myterm.terminal_manager")
local state = require("custom.myterm.state")
local commands = require("custom.myterm.command_runner")
local label = require("custom.myterm.label")

--- Opens a new terminal with the specified layout mode
---@param mode "float"|"horizontal"|"vertical"
---@return nil
function M.new(mode)
  assert(mode ~= nil and type(mode) == "string", "mode must be a string")
  manager.new_terminal(mode)
end

--- Toggles visibility of the last active terminal
--- Reopens it if currently hidden
---@return nil
function M.toggle()
  local term = state.get_last_focused()
  if not term then
    vim.notify("[myterm] No terminal active – opening new horizontal", vim.log.levels.INFO)
    return M.new("horizontal")
  end

  if vim.api.nvim_win_is_valid(term.win) then
    vim.api.nvim_win_hide(term.win)
    print("Terminal " .. term.id .. " minimized")
  else
    vim.cmd("botright")
    if term.mode == "horizontal" then
      vim.cmd("split")
      vim.api.nvim_win_set_height(0, 10) -- NOTE: Here maybe change height
      term.win = vim.api.nvim_get_current_win()
    elseif term.mode == "vertical" then
      vim.cmd("vsplit")
      vim.api.nvim_win_set_width(0, 80)
      term.win = vim.api.nvim_get_current_win()
    elseif term.mode == "float" then
      local width = math.floor(vim.o.columns * 0.8)
      local height = math.floor(vim.o.lines * 0.8)
      local col = math.floor((vim.o.columns - width) / 2)
      local row = math.floor((vim.o.lines - height) / 2)
      term.win = vim.api.nvim_open_win(term.buf, true, {
        relative = "editor",
        width = width,
        height = height,
        col = col,
        row = row,
        style = "minimal",
        border = "rounded",
      })
    end

    vim.api.nvim_set_current_buf(term.buf)
    vim.cmd("startinsert")
    state.set_focus(term.id)
    label.apply(term)
    --print("Terminal " .. term.id .. " reopened [" .. term.mode .. "]")
  end
end

--- Runs the currently stored command in the given or active terminal
---@param id? integer
---@return nil
function M.run(id)
  commands.run_command(id)
end

--- Prompts for and stores a command to be executed later
---@return nil
function M.set_command()
  commands.set_command()
end

--- Clears the stored command
---@return nil
function M.clear_command()
  commands.clear_command()
end

--- Sets the focus to the given terminal ID and displays it
---@param id integer
---@return nil
function M.focus(id)
  local ok = state.set_focus(id)
  if ok then
    M.show_active()
  end
end

--- Prints the current active terminal ID and layout
---@return nil
function M.show_active()
  local ids = state.valid_ids()
  local active_id = state.get_focused_id()

  if #ids == 0 then
    print("No active terminals")
    return
  end

  local label_parts = {}
  for _, id in ipairs(ids) do
    if id == active_id then
      table.insert(label_parts, string.format("%d*", id))
    else
      table.insert(label_parts, tostring(id))
    end
  end

  local active_term = state.get(active_id or -1)
  local mode = active_term and active_term.mode or "?"

  print(string.format("Terminals: %s (active: %s)", table.concat(label_parts, ", "), mode))
end

--- Closes and removes the given terminal by ID
---@param id integer
---@return boolean ok Whether the terminal was closed
---@return string|nil err Optional error message
function M.close(id)
  local term = state.get(id)
  if not term then
    return false, "Terminal not found"
  end
  if not vim.api.nvim_buf_is_valid(term.buf) then
    return false, "Terminal buffer is already invalid"
  end

  local ok, err = pcall(vim.api.nvim_buf_delete, term.buf, { force = true })
  return ok, err
end

-- Setup user commands, autocommands and keymaps
require("custom.myterm.usercommands").register(M)
require("custom.myterm.autocmds").setup()
require("custom.myterm.keymaps").setup(M)

return M
