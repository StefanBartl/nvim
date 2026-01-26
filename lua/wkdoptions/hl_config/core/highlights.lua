---@module 'wkdoptions.hl_config.core.highlights'
--- Safe highlight group application with error guards and validation.

local M = {}

--- Apply a single highlight group with full error handling
---@param name string
---@param spec table
---@return boolean success
---@return string? error
function M.set_hl_safe(name, spec)
  if type(name) ~= "string" or name == "" then
    return false, "Invalid highlight group name"
  end
  if type(spec) ~= "table" then
    return false, "Highlight spec must be a table"
  end

  local ok, err = pcall(vim.api.nvim_set_hl, 0, name, spec)
  if not ok then
    return false, ("Failed to set HL group '%s': %s"):format(name, tostring(err))
  end

  return true
end

--- Apply all highlight groups from a colors table
---@param colors WKDOptions.HighlightColors
---@return table<string, string> errors -- map of group_name -> error_msg
function M.apply_all(colors)
  local errors = {}

  for name, spec in pairs(colors) do
    local ok, err = M.set_hl_safe(name, spec)
    if not ok then
      errors[name] = err
    end
  end

  return errors
end

--- Check if a highlight group exists (follows links)
---@nodiscard
---@param name string
---@return boolean
function M.exists(name)
  if type(name) ~= "string" or name == "" then
    return false
  end

  local ok, info = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
  return ok and type(info) == "table" and next(info) ~= nil
end

--- Get effective highlight (resolves links, returns empty table on error)
---@nodiscard
---@param name string
---@return table
function M.get_hl_safe(name)
  local ok, info = pcall(vim.api.nvim_get_hl, 0, { name = name, link = true })
  if not ok or type(info) ~= "table" then
    return {}
  end
  return info
end

--- Create a fallback highlight if group doesn't exist or is empty
---@param name string
---@param fallback table
---@return nil
function M.ensure_hl(name, fallback)
  if not M.exists(name) then
    M.set_hl_safe(name, fallback)
  end
end

return M
