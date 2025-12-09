---@module 'autocmds.markdown.gofile_cases.helper.normalize_path'
--- Helper: normalize a path string for downstream processing.
--- Tasks:
---  - convert backslashes to forward slashes
---  - expand module-like dotted names to file paths (eg. `mod.sub` -> `mod/sub.lua`) when appropriate
---  - do not attempt to absolute-resolve relative filesystem paths (caller will combine with cwd)
--- Returns normalized path string.
--- @param path string
--- @return string
local function normalize_path(path)
  if not path or path == "" then
    return path
  end

  -- Convert backslashes to forward slashes for portability.
  local p = path:gsub("\\", "/")

  -- If string looks like a Lua module (letters/underscore start, contains dot),
  -- convert dots to slashes and append .lua
  if p:match("^[%a_][%w_]*%.") then
    p = p:gsub("%.", "/") .. ".lua"
  end

  return p
end

return normalize_path
