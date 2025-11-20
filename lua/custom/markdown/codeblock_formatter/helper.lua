---@module 'custom.markdown.codeblock_formatter.helper'

local fn = vim.fn

local M = {}

function M.write_temp_file(text, ext)
  local tmp = fn.tempname() .. (ext or "")
  local f, ferr = io.open(tmp, "wb")
  if not f then
    return nil, tostring(ferr)
  end
  f:write(text)
  f:close()
  return tmp
end

function M.read_file(path)
  local f, err = io.open(path, "rb")
  if not f then
    return nil, tostring(err)
  end
  local content = f:read("*a")
  f:close()
  return content
end

function M.remove_tmp(path)
  pcall(os.remove, path)
end

return M
