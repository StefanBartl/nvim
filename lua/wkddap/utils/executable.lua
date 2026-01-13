---@module 'wkddap.utils.executable'

local M = {}

--- Check if executable exists in PATH
---@param name string Executable name
---@return boolean exists
function M.exists(name)
  return vim.fn.executable(name) == 1
end

--- Get executable path
---@param name string Executable name
---@return string|nil path
function M.path(name)
  local exe = vim.fn.exepath(name)
  if exe and exe ~= "" then
    return exe
  end
  return nil
end

--- Check Mason installation
---@param package_name string Mason package name
---@return string|nil path
function M.mason_path(package_name)
  local mason_bin = vim.fn.stdpath("data") .. "/mason/bin/" .. package_name

  if vim.loop.fs_stat(mason_bin) then
    return mason_bin
  end

  -- Windows: try .cmd extension
  if package.config:sub(1, 1) == "\\" then
    local cmd_path = mason_bin .. ".cmd"
    if vim.loop.fs_stat(cmd_path) then
      return cmd_path
    end
  end

  return nil
end

return M
