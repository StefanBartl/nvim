---@module 'config.neotree.open.system_app'
---@brief Open files/folders with system default application
--- Cross-platform support for Windows, macOS, and Linux

local M = {}

local notify = require("lib.notify").create("[neotree.open.system_app]")
local node_utils = require("config.neotree.utils.node")

---Open path with system default application
---@param path string Absolute path to file or directory
---@return boolean success
local function open_with_system(path)
  -- Try lazy.util first (LazyVim integration)
  local ok_lazy, lazy_util = pcall(require, "lazy.util")
  if ok_lazy and lazy_util.open then
    local success = pcall(lazy_util.open, path, { system = true })
    if success then
      return true
    end
  end

  -- Try vim.ui.open (Neovim 0.10+)
  if vim.ui.open then
    local success = pcall(vim.ui.open, path)
    if success then
      return true
    end
  end

  -- Platform-specific fallback
  local success = false

  if vim.fn.has("mac") == 1 then
    local job_id = vim.fn.jobstart({ "open", path }, { detach = true })
    success = job_id > 0
  elseif vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
    -- Windows: Use explorer.exe for directories, start for files
    local stat = vim.loop.fs_stat(path)
    if stat and stat.type == "directory" then
      -- Open directory in Explorer
      local job_id = vim.fn.jobstart({ "explorer.exe", path }, { detach = true })
      success = job_id > 0
    else
      -- Open file with default application using PowerShell
      local ps_cmd = string.format(
        [[powershell -NoProfile -Command "Start-Process -FilePath '%s'"]],
        path:gsub("'", "''")
      )
      local job_id = vim.fn.jobstart(ps_cmd, { detach = true, shell = true })
      success = job_id > 0
    end
  else
    -- Linux/Unix: Use xdg-open
    local job_id = vim.fn.jobstart({ "xdg-open", path }, { detach = true })
    success = job_id > 0
  end

  return success
end

---Open selected Neo-tree node with system application
---@param state Cfg.NeoTree.State
---@return nil
function M.open_from_neotree(state)
  local node = node_utils.get_current(state)
  if not node then
    notify.warn("No node under cursor")
    return
  end

  local path, _ = node_utils.get_path(node)
  if path == "" then
    notify.warn("No path under cursor")
    return
  end

  local success = open_with_system(path)
  if not success then
    notify.error("Failed to open with system application")
  else
    notify.info("Opened: " .. vim.fn.fnamemodify(path, ":t"))
  end
end

return M
