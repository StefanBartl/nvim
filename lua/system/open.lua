---@module 'system.open'

local M = {}

---@param path string
---@return string[]|nil cmd
local function build_open_cmd(path)
  local env = require("system.env").get()
  if env.is_windows then
    return { "cmd.exe", "/C", "start", "", path }
  elseif env.is_wsl then
    if vim.fn.executable("wslview") == 1 then
      return { "wslview", path }
    end
    -- Fallback: xdg-open innside WSL
    return { "xdg-open", path }
  elseif env.is_macos then
    return { "open", path }
  else
    -- Linux/BSD
    return { "xdg-open", path }
  end
end

---@param path string
---@return boolean started
function M.open(path)
  if type(path) ~= "string" or path == "" then
    vim.notify("Invalid path", vim.log.levels.ERROR)
    return false
  end
  local cmd = build_open_cmd(path)
  if not cmd then
    vim.notify("No suitable open command found", vim.log.levels.ERROR)
    return false
  end

  if vim.system then
    vim.system(cmd, { detach = true }, function(_) end)
    return true
  else
    local ok = vim.fn.jobstart(cmd, { detach = true })
    if ok <= 0 then
      vim.notify("Failed to start: " .. table.concat(cmd, " "), vim.log.levels.ERROR)
      return false
    end
    return true
  end
end

return M
