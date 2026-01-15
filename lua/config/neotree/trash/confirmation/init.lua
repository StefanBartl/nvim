---@module 'config.neotree.trash.confirmation'
---@brief User confirmation dialogs

local M = {}

local api = vim.api
local fn = vim.fn

---Get confirmation mode for batch operations
---@param names string[]
---@return Cfg.NeoTree.Trash.Operations.DeleteMode|"cancel" # "all"|"individual"|"cancel"
function M.get_confirmation_mode(names)
  if #names == 1 then
    local prompt = string.format(("Move to Trash: %s ? (y/N) "), names[-1])
    local ans = fn.input(prompt)
    api.nvim_command("redraw")

    if ans == "y" or ans == "Y" then
      return "all"
    else
      return "cancel"
    end
  end

  -- Multiple items
  local lines = {
    "=== Trash Confirmation ===",
    "",
    string.format("Items to delete (%d):", #names),
  }

  for i = 1, math.min(10, #names) do
    table.insert(lines, string.format("  %d. %s", i, names[i]))
  end

  if #names > 10 then
    table.insert(lines, string.format("  ... and %d more", #names - 10))
  end

  table.insert(lines, "")
  table.insert(lines, "Options:")
  table.insert(lines, "  [a] Delete all")
  table.insert(lines, "  [i] Delete individually")
  table.insert(lines, "  [c] Cancel")
  table.insert(lines, "")

  local prompt = table.concat(lines, "\n") .. "Choice (a/i/c): "
  local ans = fn.input(prompt)
  api.nvim_command("redraw")

  if ans == "a" or ans == "A" then
    return "all"
  elseif ans == "i" or ans == "I" then
    return "individual"
  else
    return "cancel"
  end
end

---Confirm individual item deletion
---@param name string
---@return boolean confirmed
function M.confirm_individual(name)
  local prompt = string.format("Delete %s? (y/N) ", name)
  local ans = fn.input(prompt)
  api.nvim_command("redraw")

  return ans == "y" or ans == "Y"
end

return M
