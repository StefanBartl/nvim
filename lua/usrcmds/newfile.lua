---@module 'utils.newfile'
--- Create/edit/save files with optional recursive parent directory creation.
--- Linux/macOS friendly; no external dependencies.


local M = {}

--- Ensure parent directory exists.
---@param path Path
---@param recursive boolean
---@return boolean ok
function M.ensure_parent(path, recursive)
  local dir = vim.fn.fnamemodify(path, ":p:h")
  if dir == "" then return false end
  local flag = recursive and "p" or ""
  -- mkdir() returns 1 on success, 0 on failure (already exists → success=1)
  local ok = (vim.fn.mkdir(dir, flag) == 1) or (vim.fn.isdirectory(dir) == 1)
  return ok
end

--- Open a new buffer at {path}. Optionally create parents and write to disk.
---@param path Path
---@param opts? NewFileOpts
function M.edit_new(path, opts)
  opts = opts or { recursive = true, write_now = false, overwrite = false }
  if opts.recursive and not M.ensure_parent(path, true) then
    vim.notify("mkdir failed for: " .. path, vim.log.levels.ERROR)
    return
  end
  -- Set the buffer name to the target path
  vim.cmd(("file %s"):format(vim.fn.fnameescape(path)))
  -- Optionally write immediately (touch)
  if opts.write_now then
    local bang = opts.overwrite and "!" or ""
    vim.cmd(("write%s"):format(bang))
  end
end

--- Rename current buffer to {path} (save-as semantics).
--- Keeps editing the new path afterwards.
---@param path Path
---@param opts? NewFileOpts
function M.save_as(path, opts)
  opts = opts or { recursive = true, overwrite = false, write_now = true }
  if opts.recursive and not M.ensure_parent(path, true) then
    vim.notify("mkdir failed for: " .. path, vim.log.levels.ERROR)
    return
  end
  local bang = opts.overwrite and "!" or ""
  vim.cmd(("saveas%s %s"):format(bang, vim.fn.fnameescape(path)))
  -- if not opts.write_now then
  --   -- :saveas already wrote; nothing further needed
  -- end
end

--- Write current buffer contents to {path} as a copy (keeps buffer name).
---@param path Path
---@param opts? NewFileOpts
function M.write_to(path, opts)
  opts = opts or { recursive = true, overwrite = false, write_now = true }
  if opts.recursive and not M.ensure_parent(path, true) then
    vim.notify("mkdir failed for: " .. path, vim.log.levels.ERROR)
    return
  end
  local bang = opts.overwrite and "!" or ""
  vim.cmd(("write%s %s"):format(bang, vim.fn.fnameescape(path)))
end

-- User commands:
-- :NewFile {path}           -> set buffer name, create parents, do NOT write by default
-- :NewFileWrite {path}      -> like NewFile, but also :write immediately
-- :SaveAsR[!] {path}        -> save-as, create parents; with ! force overwrite
-- :WriteToR[!] {path}       -> write copy, create parents; with ! force overwrite
-- :MkParent                 -> ensure parent dir for the current buffer name

vim.api.nvim_create_user_command("NewFile", function(opts_)
 local path = vim.fn.expand(opts_.args)
  M.edit_new(path, { recursive = true, write_now = false, overwrite = false })
end, { nargs = 1, complete = "file" })

vim.api.nvim_create_user_command("NewFileWrite", function(opts_)
  local path = vim.fn.expand(opts_.args)
  M.edit_new(path, { recursive = true, write_now = true, overwrite = false })
end, { nargs = 1, complete = "file" })

vim.api.nvim_create_user_command("SaveAsR", function(opts_)
  local path = vim.fn.expand(opts_.args)
  M.save_as(path, { recursive = true, overwrite = opts_.bang, write_now = true })
end, { nargs = 1, bang = true, complete = "file" })

vim.api.nvim_create_user_command("WriteToR", function(opts_)
  local path = vim.fn.expand(opts_.args)
  M.write_to(path, { recursive = true, overwrite = opts_.bang, write_now = true })
end, { nargs = 1, bang = true, complete = "file" })

vim.api.nvim_create_user_command("MkParent", function()
  local name = vim.api.nvim_buf_get_name(0)
  if name == "" then
    vim.notify("buffer has no name; use :file {path} first", vim.log.levels.WARN)
    return
  end
  if M.ensure_parent(name, true) then
    vim.notify("ensured parent: " .. vim.fn.fnamemodify(name, ":p:h"), vim.log.levels.INFO)
  else
    vim.notify("mkdir failed for: " .. name, vim.log.levels.ERROR)
  end
end, {})


---@cast M NewFileAPI
return M
