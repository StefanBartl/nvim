---@module 'config.neotree.helper.is_ignored_dir'
--- Helper to check if a folder name is in the ignore list.

local ignored_dirs = require("config.neotree.helper.is_ignored_dir.ignored_dirs")

---@param name string Folder name
---@return boolean
return function (name)
  for _, ignored in ipairs(ignored_dirs) do
    if name == ignored then
      return true
    end
  end
  return false
end

