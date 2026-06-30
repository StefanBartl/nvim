---@module 'config.neotree.file_operation_wrapper'
---@brief Wrapper for file operations with automatic quarantine management
-- (Für zukünftige File-Ops wie Copy, Move, Create)

local M = {}
local watcher_quarantine = require("config.neotree.watcher_quarantine")

---Wrap any file operation with automatic quarantine
---@param operation fun(): boolean, string Operation to execute
---@param paths string[] Paths involved in operation
---@param duration_ms integer|nil Quarantine duration (default: 1500)
---@return boolean success
---@return string message
function M.with_quarantine(operation, paths, duration_ms)
  duration_ms = duration_ms or 1500

  -- Enter quarantine before operation
  watcher_quarantine.enter_quarantine(duration_ms, paths)

  -- Small delay for filesystem to register watcher stop
  vim.wait(50)

  -- Execute operation
  local ok, msg = operation()

  -- Quarantine expires automatically, no need to exit manually
  return ok, msg
end

---Safe copy operation with quarantine
---@param src string Source path
---@param dest string Destination path
---@return boolean success
---@return string message
function M.safe_copy(src, dest)
  return M.with_quarantine(function()
    local ok, err = vim.loop.fs_copyfile(src, dest)
    if ok then
      return true, "copied"
    else
      return false, tostring(err)
    end
  end, { src, dest }, 1000)
end

---Safe move operation with quarantine
---@param src string Source path
---@param dest string Destination path
---@return boolean success
---@return string message
function M.safe_move(src, dest)
  return M.with_quarantine(function()
    local ok, err = os.rename(src, dest)
    if ok then
      return true, "moved"
    else
      return false, tostring(err)
    end
  end, { src, dest }, 1500)
end

---Safe create operation with quarantine
---@param path string Path to create
---@param is_dir boolean True for directory, false for file
---@return boolean success
---@return string message
function M.safe_create(path, is_dir)
  return M.with_quarantine(function()
    if is_dir then
      local ok = vim.fn.mkdir(path, "p") == 1
      return ok, ok and "created directory" or "mkdir failed"
    else
      local ok, err = pcall(function()
        local f = io.open(path, "w")
        if f then
          f:close()
          return true
        end
        return false
      end)
      return ok, ok and "created file" or tostring(err)
    end
  end, { path }, 1000)
end

return M
