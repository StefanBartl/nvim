---@module 'custom.pathfinder.util'
--- Utility helpers: path normalization, pattern extraction, running shell commands.
--- Cross-platform considerations are handled here.

local uv = vim.loop
local M = {}
local notifier = require("custom.pathfinder.notifier")

--- Normalize path separators to the platform default.
---@param path string
---@return string
function M.normalize_sep(path)
  if not path then return "" end
  if uv.os_uname().version:match("Windows") then
    -- convert forward slashes to backslashes
    return path:gsub("/", "\\") or ""
  else
    -- convert backslashes to forward slashes
    return path:gsub("\\", "/") or ""
  end
end

--- Return basename from a path.
---@param path string
---@return string
function M.basename(path)
  path = path or ""
  -- remove trailing separator
  path = path:gsub("[/\\]+$", "")
  local name = path:match("([^/\\]+)$") or path
  return name
end

--- Run a shell command and return lines as table.
--- Uses vim.fn.systemlist for portability.
---@param cmd string
---@return string[] stdout_lines
---@return string stderr combined or empty
function M.system_lines(cmd)
  notifier.notify(("run shell: %s"):format(cmd), "debug")
  local ok = vim.fn.systemlist(cmd)
  if type(ok) ~= "table" then
    return {}, tostring(ok or "")
  end
  return ok, ""
end

--- Check if a path exists (file or directory)
---@param path string
---@return boolean
function M.exists(path)
  if not path or path == "" then return false end
  local stat = uv.fs_stat(path)
  return stat ~= nil
end

--- Open a file in the current window (or new split/whatever caller wants).
---@param path string
function M.open_file(path)
  notifier.notify(("open_file: %s"):format(path), "info")
  -- if path contains spaces or special chars, use fnameescape
  local safe = vim.fn.fnameescape(path)
  vim.cmd(("edit %s"):format(safe))
end

return M
