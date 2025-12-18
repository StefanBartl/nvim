---@module 'autocmds.patches.utils'
---@brief Shared utility functions for the patch system.
---@description
--- Provides file I/O, path manipulation, checksums, and other utilities.

local M = {}

local uv = vim.loop

--- Compute SHA256 checksum of a file
---@param filepath string
---@return string|nil checksum
---@return string|nil error
function M.compute_checksum(filepath)
  local fd = uv.fs_open(filepath, "r", 420)
  if not fd then
    return nil, "Failed to open file"
  end

  local stat = uv.fs_fstat(fd)
  if not stat then
    uv.fs_close(fd)
    return nil, "Failed to stat file"
  end

  local content = uv.fs_read(fd, stat.size, 0)
  uv.fs_close(fd)

  if not content then
    return nil, "Failed to read file"
  end

  -- Use vim's built-in SHA256 if available, fallback to simple hash
  local ok, hash = pcall(vim.fn.sha256, content)
  if ok and hash then
    return hash
  end

  -- Simple fallback hash (not cryptographically secure)
  local h = 5381
  for i = 1, #content do
    h = ((h * 33) + content:byte(i)) % 2147483647
  end
  return string.format("%x", h)
end

--- Check if a file exists and is readable
---@param filepath string
---@return boolean
function M.file_exists(filepath)
  local stat = uv.fs_stat(filepath)
  return stat ~= nil
end

--- Read file contents synchronously
---@param filepath string
---@return string|nil content
---@return string|nil error
function M.read_file(filepath)
  local fd = uv.fs_open(filepath, "r", 420)
  if not fd then
    return nil, "Failed to open file"
  end

  local stat = uv.fs_fstat(fd)
  if not stat then
    uv.fs_close(fd)
    return nil, "Failed to stat file"
  end

  local content = uv.fs_read(fd, stat.size, 0)
  uv.fs_close(fd)

  if not content then
    return nil, "Failed to read file"
  end

  return content
end

--- Write content to file synchronously
---@param filepath string
---@param content string
---@return boolean success
---@return string|nil error
function M.write_file(filepath, content)
  local fd = uv.fs_open(filepath, "w", 420)
  if not fd then
    return false, "Failed to open file for writing"
  end

  local bytes_written = uv.fs_write(fd, content, 0)
  uv.fs_close(fd)

  if not bytes_written then
    return false, "Failed to write to file"
  end

  return true
end

--- Detect repository name from target path
---@param target string
---@return string repo_name
function M.detect_repo(target)
  local lazy_root = vim.fn.expand("~/.local/share/nvim/lazy/")
  local pattern = lazy_root:gsub("([^%w])", "%%%1") .. "([^/\\]+)"
  local repo = target:match(pattern)
  return repo or "unknown"
end

--- Convert array to lookup set
---@param list string[]|nil
---@return table<string, boolean>|nil
function M.to_set(list)
  if not list or type(list) ~= "table" then
    return nil
  end

  local set = {}
  for _, v in ipairs(list) do
    if type(v) == "string" then
      set[v] = true
    end
  end

  return next(set) and set or nil
end

--- Get current ISO 8601 timestamp
---@return string
function M.get_timestamp()
  return tostring(os.date("!%Y-%m-%dT%H:%M:%SZ"))
end

--- Safe execute with timeout
---@param fn function
---@param timeout_ms number
---@return boolean success
---@return any result
function M.with_timeout(fn, timeout_ms)
  local success = false
  local result = nil
  local done = false

  -- Execute function
  vim.schedule(function()
    if done then
      return
    end
    local ok, res = pcall(fn)
    success = ok
    result = res
    done = true
  end)

  -- Wait with timeout
  local start = uv.now()
  while not done and (uv.now() - start) < timeout_ms do
    vim.wait(10)
  end

  if not done then
    return false, "Timeout"
  end

  return success, result
end

--- Normalize path separators for current platform
---@param path string
---@return string, number
function M.normalize_path(path)
  if vim.fn.has("win32") == 1 then
    return path:gsub("/", "\\")
  else
    return path:gsub("\\", "/")
  end
end

--- Create directory recursively
---@param dirpath string
---@return boolean success
---@return string|nil error
function M.ensure_dir(dirpath)
  local stat = uv.fs_stat(dirpath)
  if stat and stat.type == "directory" then
    return true
  end

  -- Create parent directories first
  local parent = vim.fn.fnamemodify(dirpath, ":h")
  if parent ~= dirpath and parent ~= "" then
    local ok, err = M.ensure_dir(parent)
    if not ok then
      return false, err
    end
  end

  -- Create this directory
  local ok, err = uv.fs_mkdir(dirpath, 493) -- 0755
  if not ok then
    return false, err
  end

  return true
end

return M
