---@module 'myterm.state'
---@brief Terminal state tracking module
---@description
--- Stores and manages terminal instance state for all active terminals.
--- Handles tracking of buffers, windows, job IDs, modes and focus status.
--- Used by terminal_manager, command_runner and UI logic to resolve active terminals.

local M = {}

---@class TerminalInstance
---@field id integer
---@field buf integer
---@field win integer
---@field job_id integer
---@field mode "float"|"horizontal"|"vertical"
---@field last_focused boolean

---@type table<integer, TerminalInstance>
local terminals = {}

---@type integer
local current_id = 0

--- Registers a new terminal instance and marks it as focused
---@param buf integer
---@param win integer
---@param job_id integer
---@param mode "float"|"horizontal"|"vertical"
---@return integer id The newly assigned terminal ID
function M.add_terminal(buf, win, job_id, mode)
  assert(type(buf) == "number" and vim.api.nvim_buf_is_valid(buf), "Invalid buffer")
  assert(type(win) == "number" and vim.api.nvim_win_is_valid(win), "Invalid window")
  assert(type(job_id) == "number", "Invalid job_id")
  assert(mode == "float" or mode == "horizontal" or mode == "vertical", "Invalid mode")

  current_id = current_id + 1

  for _, term in pairs(terminals) do
    term.last_focused = false
  end

  terminals[current_id] = {
    id = current_id,
    buf = buf,
    win = win,
    job_id = job_id,
    mode = mode,
    last_focused = true,
  }

  print(string.format("Terminal %d/%d [%s] started", current_id, M.count(), mode))

  return current_id
end

--- Returns the terminal instance by ID
---@param id integer
---@return TerminalInstance|nil
function M.get(id)
  return terminals[id]
end

--- Returns the currently focused terminal instance
---@return TerminalInstance|nil
function M.get_last_focused()
  for _, term in pairs(terminals) do
    if term.last_focused then
      return term
    end
  end
  return nil
end

--- Sets the focus to a terminal by ID
---@param id integer
---@return boolean success
function M.set_focus(id)
  local term = terminals[id]
  if not term then
    return false
  end

  for _, t in pairs(terminals) do
    t.last_focused = false
  end

  term.last_focused = true
  print(string.format("Focus set to terminal %d/%d [%s]", id, M.count(), term.mode))
  return true
end

--- Returns the number of valid terminals
---@return integer
function M.count()
  local count = 0
  for _, term in pairs(terminals) do
    if vim.api.nvim_buf_is_valid(term.buf) then
      count = count + 1
    end
  end
  return count
end

--- Returns all valid terminal IDs
---@return integer[]
function M.valid_ids()
  local ids = {}
  for id, term in pairs(terminals) do
    if vim.api.nvim_buf_is_valid(term.buf) then
      ids[#ids + 1] = id
    end
  end
  table.sort(ids)
  return ids
end

--- Returns the ID of the currently focused terminal
---@return integer|nil
function M.get_focused_id()
  for id, term in pairs(terminals) do
    if term.last_focused then
      return id
    end
  end
  return nil
end

--- Removes a terminal entry by buffer number
---@param bufnr integer
---@return boolean removed
function M.remove_by_buf(bufnr)
  for id, term in pairs(terminals) do
    if term.buf == bufnr then
      terminals[id] = nil
      print("Terminal " .. id .. " was removed (buffer closed)")

      if term.last_focused then
        local fallback = next(terminals)
        if fallback then
          terminals[fallback].last_focused = true
          print("Focus moved to terminal " .. fallback)
        end
      end
      return true
    end
  end
  return false
end

return M
