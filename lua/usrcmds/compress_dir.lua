---@module 'usercmds.compress_dir'
---@brief Compresses the current directory and stores a file list in a temp location.
---@description
--- This module provides an asynchronous, safe way to archive the current working
--- directory and create a file list (excluding `.git`), storing both in a temporary
--- directory. It includes structured error handling and follows standard coding rules.
---
--- - Excludes `.git` directory
--- - Outputs a file listing and compressed `.tar.gz` archive
--- - Uses `vim.fn.jobstart()` instead of `os.execute`
--- - Notifies only from the user command, not from the module

---@class CompressDirModule
local M = {}

local fn = vim.fn
local uv = vim.uv or vim.loop

---Validates and returns a safe target directory for compression output
---@return string|nil tempDir Validated output directory
---@return string|nil errorMsg Error string if invalid
local function _get_target_temp_dir()
  local cwd = fn.getcwd()
  local cwd_name = fn.fnamemodify(cwd, ":t")
  if cwd == "" or cwd_name == "" then
    return nil, "Invalid working directory"
  end

  local temp_root = fn.expand("~/temp")
  local target = temp_root .. "/" .. cwd_name .. "-comp"

  if fn.isdirectory(temp_root) == 0 then
    local ok, err = pcall(fn.mkdir, temp_root, "p")
    if not ok then
      return nil, "Failed to create temp root directory: " .. err
    end
  end

  if fn.isdirectory(target) == 0 then
    local ok, err = pcall(fn.mkdir, target, "p")
    if not ok then
      return nil, "Failed to create target directory: " .. err
    end
  end

  return target, nil
end

---@private
---Runs a shell command asynchronously and invokes a callback on exit
---@param cmd string
---@param on_exit fun(success: boolean, output: string)
---@return nil
local function _run_shell_async(cmd, on_exit)
  local stdout = uv.new_pipe(false)
  local stderr = uv.new_pipe(false)
  local output = {}

  local handle
  handle = uv.spawn("sh", {
    args = { "-c", cmd },
    stdio = { nil, stdout, stderr },
  }, function(code)
    stdout:close()
    stderr:close()
    if handle then handle:close() end
    local success = code == 0
    on_exit(success, table.concat(output, "\n"))
  end)

  stdout:read_start(function(err, data)
    if err then return end
    if data then table.insert(output, data) end
  end)

  stderr:read_start(function(err, data)
    if err then return end
    if data then table.insert(output, data) end
  end)
end

---Compresses the current working directory into a temp folder with file listing
---@param on_complete fun(success: boolean, message: string) Callback with status
---@return nil
function M.compress_current_directory(on_complete)
  local cwd = fn.getcwd()
  local cwd_name = fn.fnamemodify(cwd, ":t")

  local target, dir_err = _get_target_temp_dir()
  if not target and dir_err then
    on_complete(false, dir_err)
    return
  end

  local list_path = target .. "/dir-and-file_list"
  local archive_path = target .. "/" .. cwd_name .. ".tar.gz"
  local parent_dir = fn.fnamemodify(cwd, ":h")

  local list_cmd = "find " .. fn.shellescape(cwd) .. " -not -path '*/.git/*' > " .. fn.shellescape(list_path)
  local tar_cmd = "tar --exclude=" .. fn.shellescape(cwd .. "/.git") ..
      " -czf " .. fn.shellescape(archive_path) ..
      " -C " .. fn.shellescape(parent_dir) .. " " .. fn.shellescape(cwd_name)

  _run_shell_async(list_cmd, function(success_list, out1)
    if not success_list then
      on_complete(false, "Failed to generate file list:\n" .. out1)
      return
    end

    _run_shell_async(tar_cmd, function(success_tar, out2)
      if not success_tar then
        on_complete(false, "Compression failed:\n" .. out2)
      else
        on_complete(true, "Directory compressed successfully:\n" .. archive_path)
      end
    end)
  end)
end

-- Custom user command with UI integration (notification layer)
vim.api.nvim_create_user_command("CompressDir", function()
  M.compress_current_directory(function(success, msg)
    local level = success and vim.log.levels.INFO or vim.log.levels.ERROR
    vim.schedule(function()
      vim.notify(msg, level)
    end)
  end)
end, {})

return M
