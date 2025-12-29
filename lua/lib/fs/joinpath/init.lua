---@module 'lib.fs.joinpath'

local unpack = table.unpack or unpack

---@param parts string[]
---@return string
return function(parts)
  return vim.fs.joinpath(unpack(parts))
end
