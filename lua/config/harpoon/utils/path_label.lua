---@module 'config.harpoon.utils.path_label'
--- Path shortening for UI labels (Linux/macOS/Windows incl. UNC).
--- Format: <root>/<..../><parent>/<file>
--- Examples:
---   "C:/..../mynotes/spickzettel.md"
---   "~/..../some/file.lua"
---   "/mnt/xy/..../some/huhu.c"
---   "//SERVER/Share/..../proj/file.txt"
---
--- Goals:
---   - Keep drive/partition/root visible (C:/, ~/, /, //SERVER/Share/)
---   - Always show parent + file
---   - Use "...." as elision marker for middle segments
---   - Work with mixed and backslash separators; display uses "/"

local M = {}

local uv = vim.uv or vim.loop

---@return string
local function homedir()
  return (uv.os_homedir and uv.os_homedir()) or vim.fn.expand("~")
end

---@param p string
---@return string
local function to_display_sep(p)
  return (p:gsub("\\", "/"))
end

---@param p string
---@return boolean
local function is_unc(p)
  -- UNC: starts with // or \\
 return p:match("^//") ~= nil
end

--@param p string
---@return string, string
local function split_unc_root(p)
  local s = p:match("^//([^/]+/[^/]+)")
  if not s then
    local rest = (p:gsub("^//+", ""))
    return "//", rest
  end

  local root = "//" .. s
  local rest = p:sub(#root + 2)
  return root, rest
end


---@param p string
---@return boolean
local function is_windows_drive(p)
  return p:match("^%a:[/\\]") ~= nil
end

---@param p string
---@return string, string
local function split_drive_root(p)
  -- C:/dir/file -> root="C:", rest="dir/file"
  local drive = p:sub(1,2):upper()
  local rest = p:sub(3)
  rest = rest:gsub("^[/\\]+", "")
  return drive, rest
end

---@param path string
---@return string
function M.to_label(path)
  if type(path) ~= "string" or path == "" then
    return ""
  end

  -- Realpath if possible for dedup friendliness; fallback to given path
  local rp = (uv.fs_realpath and uv.fs_realpath(path)) or path
  local p = to_display_sep(rp)

  local home = to_display_sep(homedir())
  local root, rest

  if is_unc(p) then
    root, rest = split_unc_root(p)
  elseif is_windows_drive(p) then
    root, rest = split_drive_root(p)
    root = root .. "/"  -- display as "C:/"
  elseif p:sub(1, #home + 1) == (home .. "/") then
    root, rest = "~", p:sub(#home + 2) -- "~/<rest>"
    root = root .. "/"
  elseif p == home then
    -- Exactly home: show "~"
    return "~"
  elseif p:sub(1,1) == "/" then
    -- Unix-like absolute
    root, rest = "/", p:sub(2)
  else
    -- Relative path: normalize against cwd to still produce an absolute-like label
    local cwd = to_display_sep((uv.cwd and uv.cwd()) or vim.fn.getcwd())
    if p:sub(1,1) ~= "/" and not is_windows_drive(p) and not is_unc(p) then
      p = cwd .. "/" .. p
    end
    return M.to_label(p) -- recurse once
  end

  -- Extract parent + filename
  local parent = rest:match("(.+)/[^/]+$") or ""
  local file = rest:match("[^/]+$") or rest

  if parent == "" then
    -- No parent directory left: "<root><file>"
    if root == "//" then return "//" .. file end
    return root .. file
  end

  local parent_name = parent:match("[^/]+$") or parent
  return string.format("%s..../%s/%s", root, parent_name, file)
end

return M

