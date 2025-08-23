---@module 'custom.get_project_tree'
---@brief Asynchronous project structure inspection (file tree, count, clipboard)
---@description
--- Provides safe async utilities to inspect a project structure from Neovim.
--- Features:
--- - Write full file tree (excluding `.git`)
--- - Count all project files
--- - Copy structure to clipboard (requires `xclip`)
--- All operations are non-blocking and integrate safely with the UI.

---@class ProjectTreeModule
local M = {}

local fn = vim.fn
local api = vim.api
local uv = vim.uv or vim.loop

---@diagnostic disable
---Runs a shell command asynchronously and returns output to callback
---@param cmd string
---@param on_exit fun(success: boolean, output: string): nil
---@return nil
local function run_command(cmd, on_exit)
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
    on_exit(code == 0, table.concat(output, "\n"))
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
---@diagnostic enable

---Returns full path to tree output file
---@return string|nil path
---@return string|nil error
local function get_tree_file()
  local cwd = fn.getcwd()
  if cwd == "" then return nil, "Invalid working directory" end
  local name = fn.fnamemodify(cwd, ":t")
  local outdir = fn.expand("~/temp")
  if fn.isdirectory(outdir) == 0 then
    local ok, err = pcall(fn.mkdir, outdir, "p")
    if not ok then return nil, "Failed to create output dir: " .. err end
  end
  return outdir .. "/" .. name .. "-tree.txt", nil
end

---Generates the project file tree into ~/temp/<project>-tree.txt
---@param callback fun(success: boolean, msg: string): nil
---@return nil
function M.write_tree(callback)
  local cwd = fn.getcwd()
  local path, err = get_tree_file()
  if not path then
    callback(false, err or "Error")
    return
  end

  local cmd = "find " .. fn.shellescape(cwd)
      .. " -not -path '*/.git/*' -printf '%P\\n' | sort > "
      .. fn.shellescape(path)

  run_command(cmd, function(success, output)
    local msg = success and "Tree written to: " .. path or "Failed to write tree: " .. output
    callback(success, msg)
  end)
end

---Copies the generated tree file to clipboard via xclip
---@param callback fun(success: boolean, msg: string): nil
---@return nil
function M.copy_tree_to_clipboard(callback)
  local path, err = get_tree_file()
  if not path or fn.filereadable(path) == 0 then
    callback(false, err or ("Tree file does not exist: " .. path))
    return
  end

  local cmd = "xclip -selection clipboard < " .. fn.shellescape(path)
  run_command(cmd, function(success, output)
    local msg = success and "Project tree copied to clipboard." or "Failed to copy to clipboard:\n" .. output
    callback(success, msg)
  end)
end

---Counts project files (excluding .git) and returns result
---@param callback fun(success: boolean, msg: string): nil
---@return nil
function M.count_files(callback)
  local cwd = fn.getcwd()
  if cwd == "" then
    callback(false, "Invalid working directory")
    return
  end

  local cmd = "find " .. fn.shellescape(cwd) .. " -type f -not -path '*/.git/*' | wc -l"
  run_command(cmd, function(success, output)
    if not success then
      callback(false, "Failed to count files:\n" .. output)
      return
    end
    local count = tonumber(output:match("%d+"))
    if not count then
      callback(false, "Could not parse file count from: " .. output)
    else
      callback(true, "Total project files: " .. count)
    end
  end)
end

-- User Commands
api.nvim_create_user_command("ProjectTreeGet", function()
  M.write_tree(function(ok, msg)
    api.notify(msg, ok and vim.log.levels.INFO or vim.log.levels.ERROR, {})
  end)
end, {})

api.nvim_create_user_command("ProjectTreeCopyClipboard", function()
  M.copy_tree_to_clipboard(function(ok, msg)
    api.notify(msg, ok and vim.log.levels.INFO or vim.log.levels.ERROR, {})
  end)
end, {})

api.nvim_create_user_command("ProjectFilesCount", function()
  M.count_files(function(ok, msg)
    api.notify(msg, ok and vim.log.levels.INFO or vim.log.levels.ERROR, {})
  end)
end, {})

return M
