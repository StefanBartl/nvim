-- custom/compress_dir.lua
local M = {}

--- Compresses the current working directory and saves a file list
function M.init()
  -- Load necessary functions
  local fn = vim.fn

  -- Get current working directory
  local cwd = fn.getcwd()
  local cwd_name = fn.fnamemodify(cwd, ":t")
  local temp_dir = fn.expand("~/temp/" .. cwd_name .. "-comp")

  -- Create target directory
  if fn.isdirectory(temp_dir) == 0 then
    fn.mkdir(temp_dir, "p")
  end

  -- Create dir-and-file_list (excluding .git)
  local list_file = temp_dir .. "/dir-and-file_list"
  local list_command = "find " .. vim.fn.shellescape(cwd) .. " -not -path '*/.git/*' > " .. vim.fn.shellescape(list_file)
  os.execute(list_command)

  -- Archive filename
  local archive_file = temp_dir .. "/" .. cwd_name .. ".tar.gz"

  -- Build tar command with exclusion of .git
  local tar_command = "tar --exclude=" .. vim.fn.shellescape(cwd .. "/.git") ..
      " -czf " .. vim.fn.shellescape(archive_file) ..
      " -C " .. vim.fn.shellescape(fn.fnamemodify(cwd, ":h")) ..
      " " .. vim.fn.shellescape(cwd_name)

  -- Compress the directory
  local result = os.execute(tar_command)
  if result ~= 0 then
    vim.notify("Compression failed!", vim.log.levels.ERROR)
    return
  end

  vim.notify("Directory compressed and copied successfully to " .. temp_dir, vim.log.levels.INFO)
end

vim.api.nvim_create_user_command("CompressDir", function()
  require("custom.compress_dir").init()
end, {})

return M
