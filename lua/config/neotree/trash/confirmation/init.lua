---@module 'config.neotree.trash.confirmation'
---@brief Single confirmation point for trash operations

local M = {}

local api = vim.api
local fn = vim.fn

---Get unified confirmation for trash operation
---@param names string[]
---@param has_open_buffers boolean
---@return "all"|"individual"|"cancel"
---@nodiscard
function M.get_unified_confirmation(names, has_open_buffers)
  if #names == 1 then
    local buffer_info = has_open_buffers
      and "\n(Open buffers will be closed automatically)"
      or ""

    local prompt = ("Move to trash: %s?%s (y/N) "):format(names[1], buffer_info)
    local ans = fn.input(prompt)
    api.nvim_command("redraw")

    return (ans == "y" or ans == "Y") and "all" or "cancel"
  end

  -- Multiple items
  local lines = {
    "=== Trash Confirmation ===",
    "",
    ("#items: %d"):format(#names),
  }

  -- Show first 10 items
  for i = 1, math.min(10, #names) do
    lines[#lines + 1] = ("  %d. %s"):format(i, names[i])
  end

  if #names > 10 then
    lines[#lines + 1] = ("  ... and %d more"):format(#names - 10)
  end

  lines[#lines + 1] = ""

  if has_open_buffers then
    lines[#lines + 1] = "⚠ Some files have open buffers"
    lines[#lines + 1] = "  (will be closed automatically)"
    lines[#lines + 1] = ""
  end

  lines[#lines + 1] = "Options:"
  lines[#lines + 1] = "  [a] Delete all at once"
  lines[#lines + 1] = "  [i] Confirm each individually"
  lines[#lines + 1] = "  [c] Cancel"
  lines[#lines + 1] = ""

  local prompt = table.concat(lines, "\n") .. "Choice (a/i/c): "
  local ans = fn.input(prompt)
  api.nvim_command("redraw")

  if ans == "a" or ans == "A" then
    return "all"
  elseif ans == "i" or ans == "I" then
    return "individual"
  end

  return "cancel"
end

---Confirm individual item (only called in "individual" mode)
---@param name string
---@return boolean confirmed
---@nodiscard
function M.confirm_individual(name)
  local prompt = ("Delete %s? (y/N) "):format(name)
  local ans = fn.input(prompt)
  api.nvim_command("redraw")

  return ans == "y" or ans == "Y"
end

return M
