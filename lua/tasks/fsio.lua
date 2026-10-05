---@module 'tasks.fsio'
---@brief Small byte-exact file primitives the task engine builds on.
---@description
--- Thin layer over `lib.nvim.fs.*` / `lib.nvim.cross.fs.mutate` for the few
--- things the engine needs that no single lib.nvim function does:
---
---  - `write_atomic`: temp sibling + rename, no newline appended (the lib's
---    `fs.write.to_file` appends one, which would change a file that was
---    deliberately written without it);
---  - `create_exclusive`: `O_CREAT|O_EXCL`, so two writers can never both
---    believe they created the same task file (ERR-31);
---  - line-ending helpers, because a vault checked out with CRLF must keep
---    reading and comparing as if it were LF.
---
--- Key responsibilities:
---  - forward-slash paths everywhere the engine hands one out
---  - never raise: every function answers `value|nil, err` or `ok, err`
---
--- Not its job: deciding what to write or where (that is `mutate`/`index`).

local read_file = require("lib.nvim.fs.read")
local mkdirp = require("lib.nvim.fs.mkdirp")
local mutate = require("lib.nvim.cross.fs.mutate")
local unify_slashes = require("lib.nvim.cross.fs.separators.unify_slashes")

local uv = vim.uv or vim.loop

local M = {}

---Forward slashes, no trailing slash (a bare drive root `C:/` or `/` is kept).
---@param path string
---@return string
function M.norm(path)
  local p = unify_slashes(path)
  if #p > 1 and p:sub(-1) == "/" and not p:match("^%a:/$") then
    p = p:sub(1, -2)
  end
  return p
end

---@param path string
---@return string
function M.dirname(path)
  return (M.norm(path):match("^(.*)/[^/]*$")) or "."
end

---@param path string
---@return boolean
function M.is_dir(path)
  local st = uv.fs_stat(path)
  return st ~= nil and st.type == "directory"
end

---@param path string
---@return boolean
function M.is_file(path)
  local st = uv.fs_stat(path)
  return st ~= nil and st.type == "file"
end

---@param path string
---@return string|nil content
---@return string|nil err
function M.read(path)
  return read_file(path)
end

---`\r\n` -> `\n`, so a CRLF checkout compares equal to the generated LF text.
---@param s string
---@return string
function M.lf(s)
  return (s:gsub("\r\n", "\n"))
end

---The line ending a text uses: CRLF when it contains one, else LF.
---@param s string
---@return string
function M.eol_of(s)
  return s:find("\r\n", 1, true) and "\r\n" or "\n"
end

---`s` without leading and trailing whitespace, in linear time. The usual
---`s:match("^%s*(.-)%s*$")` retries the rest of a whitespace run from every
---byte inside it, so one line with 40 000 spaces costs seconds (SEC-32); this
---one walks the trailing run once.
---@param s string
---@return string
function M.trim(s)
  local first = s:find("%S")
  if not first then
    return ""
  end
  local last = #s
  while last > first and s:find("^%s", last) do
    last = last - 1
  end
  return s:sub(first, last)
end

---@param path string
---@param err? string
---@return boolean ok
---@return string|nil err
local function ensure_parent(path, err)
  local ok, merr = mkdirp(M.dirname(path))
  if not ok then
    return false, err or merr
  end
  return true, nil
end

---Write `content` to `path` through a temp sibling and a rename, creating the
---parent directory. Bytes are written as given (no newline is appended).
---@param path string
---@param content string
---@return boolean ok
---@return string|nil err
function M.write_atomic(path, content)
  local ok, perr = ensure_parent(path)
  if not ok then
    return false, perr
  end
  -- Unique per process and call, so concurrent writers never share a temp file.
  local tmp = ("%s.tasks-tmp.%d.%d"):format(path, vim.uv.os_getpid(), vim.uv.hrtime())
  local f, open_err = io.open(tmp, "wb")
  if not f then
    return false, "open failed: " .. tostring(open_err or tmp)
  end
  local wrote, write_err = f:write(content)
  local closed, close_err = f:close()
  if not wrote or not closed then
    pcall(os.remove, tmp)
    return false, "write failed: " .. tostring(write_err or close_err or tmp)
  end
  local renamed, rename_err = mutate.rename_file(tmp, path)
  if not renamed then
    pcall(os.remove, tmp)
    return false, "rename failed: " .. tostring(rename_err)
  end
  return true, nil
end

---Create `path` with `content`, failing with `"exists"` when the file is
---already there. The existence test and the creation are one syscall.
---@param path string
---@param content string
---@return boolean ok
---@return string|nil err  `"exists"` when the file was already present
function M.create_exclusive(path, content)
  local ok, perr = ensure_parent(path)
  if not ok then
    return false, perr
  end
  local fd, open_err = uv.fs_open(path, "wx", 420) -- 0644
  if not fd then
    if tostring(open_err):match("^EEXIST") then
      return false, "exists"
    end
    return false, "open failed: " .. tostring(open_err)
  end
  local written, write_err = uv.fs_write(fd, content, 0)
  uv.fs_close(fd)
  if not written or written ~= #content then
    pcall(os.remove, path)
    return false, "write failed: " .. tostring(write_err or path)
  end
  return true, nil
end

---Rename a file or folder (one filesystem, so atomic). The target must not exist.
---@param from string
---@param to string
---@return boolean ok
---@return string|nil err
function M.rename(from, to)
  if uv.fs_stat(to) then
    return false, "target exists: " .. to
  end
  local ok, err = uv.fs_rename(from, to)
  if not ok then
    return false, tostring(err)
  end
  return true, nil
end

---Copy a file, failing when the target exists. Creates the parent folder.
---@param from string
---@param to string
---@return boolean ok
---@return string|nil err  `"exists"` when the target was already there
function M.copy(from, to)
  local ok, perr = ensure_parent(to)
  if not ok then
    return false, perr
  end
  local copied, err = uv.fs_copyfile(from, to, { excl = true })
  if not copied then
    if tostring(err):match("^EEXIST") then
      return false, "exists"
    end
    return false, tostring(err)
  end
  return true, nil
end

---Create a folder and its parents.
---@param path string
---@return boolean ok
---@return string|nil err
function M.mkdirp(path)
  local ok, err = mkdirp(path)
  if not ok then
    return false, tostring(err)
  end
  return true, nil
end

---@param path string
---@return boolean ok
---@return string|nil err
function M.remove(path)
  local ok, err = mutate.delete_file(path)
  if not ok then
    return false, tostring(err)
  end
  return true, nil
end

return M
