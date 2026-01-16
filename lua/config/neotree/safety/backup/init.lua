---@module 'config.neotree.safety.backup'
---@brief Automatic backup system for destructive file operations

local M = {}

local uv = vim.loop
local fn = vim.fn

---@type Cfg.NeoTree.Safety.BackupEntry[]
local backup_history = {}

local MAX_HISTORY = 50
local MAX_AGE_DAYS = 7

---Get backup directory
---@return string
local function get_backup_dir()
  local dir = fn.stdpath("cache") .. "/neotree_backups"
  fn.mkdir(dir, "p")
  return dir
end

---Create unique backup filename
---@param path string Original path
---@return string
local function create_backup_filename(path)
  local timestamp = os.date("%Y%m%d_%H%M%S")
  local basename = fn.fnamemodify(path, ":t")
  local random = string.format("%04x", math.random(0, 0xFFFF))
  return string.format("%s.%s.%s.bak", basename, timestamp, random)
end

---Create backup of file or directory
---@param path string Path to backup
---@param operation string Operation type
---@return string|nil backup_path, string|nil error
function M.create_backup(path, operation)
  operation = operation or "unknown"

  -- Check if path exists
  local stat = uv.fs_stat(path)
  if not stat then
    return nil, "path does not exist"
  end

  local backup_dir = get_backup_dir()
  local backup_filename = create_backup_filename(path)
  local backup_path = backup_dir .. "/" .. backup_filename

  local ok, err

  if stat.type == "file" then
    -- Backup single file
    ok, err = pcall(uv.fs_copyfile, path, backup_path)
  elseif stat.type == "directory" then
    -- Backup directory recursively
    ok, err = pcall(function()
      fn.mkdir(backup_path, "p")
      -- Use system command for recursive copy
      if vim.fn.has("win32") == 1 then
        fn.system({ "xcopy", path, backup_path, "/E", "/I", "/Q", "/H", "/Y" })
      else
        fn.system({ "cp", "-r", path, backup_path })
      end
      return vim.v.shell_error == 0
    end)
  else
    return nil, "unsupported file type: " .. stat.type
  end

  if not ok then
    return nil, tostring(err)
  end

  -- Add to history
  local entry = {
    original_path = path,
    backup_path = backup_path,
    timestamp = os.time(),
    operation = operation,
    metadata = {
      size = stat.size,
      type = stat.type,
      mtime = stat.mtime.sec,
    }
  }

  table.insert(backup_history, 1, entry)

  -- Limit history
  while #backup_history > MAX_HISTORY do
    table.remove(backup_history)
  end

  return backup_path, nil
end

---Restore from backup
---@param backup_path string Backup path
---@param restore_path string|nil Restore to this path (nil = original)
---@return boolean success, string|nil error
function M.restore_backup(backup_path, restore_path)
  -- Find entry in history
  local entry = nil
  for _, e in ipairs(backup_history) do
    if e.backup_path == backup_path then
      entry = e
      break
    end
  end

  if not entry then
    return false, "backup not found in history"
  end

  restore_path = restore_path or entry.original_path

  -- Check if backup still exists
  if fn.filereadable(backup_path) == 0 and fn.isdirectory(backup_path) == 0 then
    return false, "backup file/directory not found"
  end

  -- Check if restore path already exists
  if fn.filereadable(restore_path) == 1 or fn.isdirectory(restore_path) == 1 then
    local ans = fn.input("Restore path exists. Overwrite? (y/N) ")
    if ans ~= "y" and ans ~= "Y" then
      return false, "user cancelled"
    end
  end

  local ok, err

  if entry.metadata.type == "file" then
    ok, err = pcall(uv.fs_copyfile, backup_path, restore_path)
  else
    -- Directory restore
    ok, err = pcall(function()
      if vim.fn.has("win32") == 1 then
        fn.system({ "xcopy", backup_path, restore_path, "/E", "/I", "/Q", "/H", "/Y" })
      else
        fn.system({ "cp", "-r", backup_path, restore_path })
      end
      return vim.v.shell_error == 0
    end)
  end

  if not ok then
    return false, tostring(err)
  end

  vim.notify(string.format("Restored: %s", restore_path), vim.log.levels.INFO)
  return true, nil
end

---List all backups
---@return Cfg.NeoTree.Safety.BackupEntry[]
function M.list_backups()
  return vim.deepcopy(backup_history)
end

---Get backup for original path
---@param original_path string
---@return Cfg.NeoTree.Safety.BackupEntry|nil
function M.get_backup_for_path(original_path)
  for _, entry in ipairs(backup_history) do
    if entry.original_path == original_path then
      return entry
    end
  end
  return nil
end

---Clean old backups
---@param max_age_days integer|nil Default: 7
---@return integer cleaned_count
function M.clean_old_backups(max_age_days)
  max_age_days = max_age_days or MAX_AGE_DAYS
  local cutoff = os.time() - (max_age_days * 24 * 60 * 60)

  local cleaned = 0
  local new_history = {}

  for _, entry in ipairs(backup_history) do
    if entry.timestamp < cutoff then
      -- Delete old backup
      pcall(function()
        if fn.isdirectory(entry.backup_path) == 1 then
          fn.delete(entry.backup_path, "rf")
        else
          fn.delete(entry.backup_path)
        end
      end)
      cleaned = cleaned + 1
    else
      table.insert(new_history, entry)
    end
  end

  backup_history = new_history
  return cleaned
end

---Show backup UI (select and restore)
function M.show_backup_ui()
  if #backup_history == 0 then
    vim.notify("No backups available", vim.log.levels.INFO)
    return
  end

  local items = {}
  for i, entry in ipairs(backup_history) do
    local time_str = os.date("%Y-%m-%d %H:%M:%S", entry.timestamp)
    local size_str = string.format("%.2f KB", entry.metadata.size / 1024)
    table.insert(items, string.format("[%d] %s | %s | %s | %s",
      i, time_str, entry.operation, size_str, entry.original_path))
  end

  vim.ui.select(items, {
    prompt = "Select backup to restore:",
  }, function(_, idx)
    if not idx then return end

    local entry = backup_history[idx]
    local ok, err = M.restore_backup(entry.backup_path)

    if not ok then
      vim.notify("Restore failed: " .. tostring(err), vim.log.levels.ERROR)
    end
  end)
end

return M
