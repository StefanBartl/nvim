---@module 'config.neotree.safety.validation'
---@brief Input validation for file operations

local M = {}

---Validate path is safe to operate on
---@param path string
---@return boolean valid, string|nil reason
function M.validate_path(path)
  if not path or path == "" then
    return false, "path is empty"
  end

  -- Normalize path
  path = vim.fn.expand(path)

  -- Check if path is too short (system directory protection)
  local depth = select(2, path:gsub("[/\\]", ""))
  if depth < 2 then
    return false, "path too shallow (system directory protection)"
  end

  -- Blacklist critical paths
  local blacklist = {
    "^/$",                      -- Root
    "^C:\\$",                   -- Windows root
    "^/bin",                    -- System binaries
    "^/sbin",                   -- System binaries
    "^/etc",                    -- System config
    "^/boot",                   -- Boot files
    "^C:\\Windows",             -- Windows directory
    "^C:\\Program Files",       -- Program Files
  }

  for _, pattern in ipairs(blacklist) do
    if path:match(pattern) then
      return false, "path is in blacklist (system directory)"
    end
  end

  return true, nil
end

---Find buffers that have a specific path open
---@param path string File path to check
---@return integer[] buffers Array of buffer numbers
local function find_buffers_with_path(path)
  local buffers = {}
  local normalized_path = vim.fn.resolve(path):gsub("\\", "/")

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
      local buf_name = vim.api.nvim_buf_get_name(buf)
      if buf_name ~= "" then
        local normalized_buf = vim.fn.resolve(buf_name):gsub("\\", "/")
        if normalized_buf == normalized_path then
          table.insert(buffers, buf)
        end
      end
    end
  end

  return buffers
end

---Validate operation is allowed
---@param operation string "delete"|"move"|"copy"|"create"
---@param paths string[] Paths involved
---@return boolean valid, string|nil reason, table|nil extra_info
function M.validate_operation(operation, paths)
  local allowed_operations = { "delete", "move", "copy", "create", "rename" }

  if not vim.tbl_contains(allowed_operations, operation) then
    return false, "unknown operation: " .. operation, nil
  end

  if not paths or #paths == 0 then
    return false, "no paths provided", nil
  end

  -- Validate each path
  for _, path in ipairs(paths) do
    local valid, reason = M.validate_path(path)
    if not valid then
      return false, string.format("invalid path '%s': %s", path, reason), nil
    end
  end

  -- Operation-specific validation
  if operation == "delete" then
    -- Check if any path is currently open in buffer
    local open_files = {}

    for _, path in ipairs(paths) do
      local buffers = find_buffers_with_path(path)
      if #buffers > 0 then
        table.insert(open_files, {
          path = path,
          buffers = buffers,
        })
      end
    end

    if #open_files > 0 then
      return false, "paths are open in buffers", { open_files = open_files }
    end
  end

  return true, nil, nil
end

---Confirm dangerous operation with user
---@param operation string
---@param paths string[]
---@return boolean confirmed
function M.confirm_operation(operation, paths)
  local dangerous = {
    delete = true,
    move = false,
    copy = false,
    create = false,
  }

  if not dangerous[operation] then
    return true
  end

  local prompt
  if #paths == 1 then
    prompt = string.format("%s: %s ? (y/N) ", operation, paths[1])
  else
    prompt = string.format("%s %d items? (y/N) ", operation, #paths)
  end

  local ans = vim.fn.input(prompt)
  vim.api.nvim_command("redraw")

  return ans == "y" or ans == "Y"
end

return M
