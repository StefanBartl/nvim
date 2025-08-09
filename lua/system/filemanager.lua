---@module 'system.filemanager'

local M = {}

local function detect_cmd(path)
  local env = require("system.env").get()
  if env.is_windows then
    return { "explorer", path }
  elseif env.is_wsl then
    if vim.fn.executable("wslview") == 1 then
      return { "wslview", path }
    else
      return { "explorer.exe", path }
    end
  elseif env.is_macos then
    return { "open", path }
  else
    -- Linux Desktop
    if vim.fn.executable("xdg-open") == 1 then
      return { "xdg-open", path }
    elseif vim.fn.executable("nautilus") == 1 then
      return { "nautilus", path }
    else
      return nil
    end
  end
end

---@param path string
---@return boolean started
function M.open_dir(path)
  if type(path) ~= "string" or path == "" then
    vim.notify("Invalid path", vim.log.levels.ERROR)
    return false
  end
  local cmd = detect_cmd(path)
  if not cmd then
    vim.notify("No suitable file manager found", vim.log.levels.ERROR)
    return false
  end

  if vim.system then
    vim.system(cmd, { detach = true }, function(_) end)
    return true
  else
    local ok = vim.fn.jobstart(cmd, { detach = true })
    if ok <= 0 then
      vim.notify("Failed to start file manager", vim.log.levels.ERROR)
      return false
    end
    return true
  end
end

return M
