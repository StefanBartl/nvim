---@module 'usrcmds.compress_dir'
---@brief Compresses the current directory and stores a file list in a temp location.
---@description
--- This module provides an asynchronous, safe way to archive the current working
--- directory and create a file list (excluding `.git`), storing both in a temporary
--- directory. It includes structured error handling and follows standard coding rules.
---
--- - Excludes `.git` directory
--- - Outputs a file listing and compressed `.tar.gz` archive
--- - Uses vim.system() when available, otherwise falls back to luv
--- - Notifies only from the user command, not from the module

---@class CompressDirModule
local M = {}

local fn = vim.fn

--- Validate and return a safe target directory for compression output.
---@return string|nil temp_dir  -- Validated output directory
---@return string|nil error_msg -- Error string if invalid
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

--- Run a shell command asynchronously and call on_exit(success, output).
--- Uses vim.system() on Neovim ≥ 0.10; falls nicht verfügbar, fällt auf uv.spawn zurück.
---@param cmd string
---@param on_exit fun(success: boolean, output: string)
---@return nil
local function _run_shell_async(cmd, on_exit)
  -- Preferred path: Neovim 0.10+ high-level API
  if type(vim.system) == "function" then
    vim.system({ "sh", "-c", cmd }, { text = true }, function(obj)
      local success = (obj.code == 0)
      local out = (obj.stdout or "") .. (obj.stderr or "")
      on_exit(success, out)
    end)
    return
  end

  -- Fallback: luv (Neovim 0.9)
  local uv = vim.uv or vim.loop

	---@diagnostic disable
  ---@type uv.uv_pipe_t|nil
  local stdout = uv.new_pipe(false)
  ---@type uv.uv_pipe_t|nil
  local stderr = uv.new_pipe(false)
  if not stdout or not stderr then
    on_exit(false, "Failed to create pipes")
    return
  end

  ---@type string[]
  local output = {}

  -- Keep type narrow: process handle or nil. No casts needed.
  ---@type uv.uv_process_t|nil
  local handle

  -- Only required fields; suppress static false-positive for missing optional fields.
  ---@diagnostic disable
  handle = uv.spawn("sh", {
    args = { "-c", cmd },
    stdio = { nil, stdout, stderr },
  }, function(code)
    if stdout and not stdout:is_closing() then
      stdout:read_stop()
      stdout:close()
    end
    if stderr and not stderr:is_closing() then
      stderr:read_stop()
      stderr:close()
    end
    if handle and not handle:is_closing() then
      handle:close()
    end
    on_exit(code == 0, table.concat(output, ""))
  end)

  stdout:read_start(function(err, data)
    if err then
      output[#output + 1] = tostring(err)
      return
    end
    if data then output[#output + 1] = data end
  end)

  stderr:read_start(function(err, data)
    if err then
      output[#output + 1] = tostring(err)
      return
    end
    if data then output[#output + 1] = data end
  end)
end
  ---@diagnostic enable

--- Compress the current working directory into a temp folder with file listing.
---@param on_complete fun(success: boolean, message: string) -- Callback with status
---@return nil
function M.compress_current_directory(on_complete)
  local cwd = fn.getcwd()
  local cwd_name = fn.fnamemodify(cwd, ":t")

  local target, dir_err = _get_target_temp_dir()
  if not target then
    on_complete(false, dir_err or "Unknown error")
    return
  end

  local list_path = target .. "/dir-and-file_list"
  local archive_path = target .. "/" .. cwd_name .. ".tar.gz"
  local parent_dir = fn.fnamemodify(cwd, ":h")

  -- Note: if one wants only files, add: -type f
  local list_cmd = "find " .. fn.shellescape(cwd) .. " -not -path '*/.git/*' > " .. fn.shellescape(list_path)
  local tar_cmd = "tar --exclude=" .. fn.shellescape(cwd .. "/.git")
    .. " -czf " .. fn.shellescape(archive_path)
    .. " -C " .. fn.shellescape(parent_dir) .. " " .. fn.shellescape(cwd_name)

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
