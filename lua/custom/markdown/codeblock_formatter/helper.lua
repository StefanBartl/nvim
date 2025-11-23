---@module 'custom.markdown.codeblock_formatter.helper'

local fn = vim.fn

local M = {}

-- remove leading/trailing fence lines (```...) if still present
-- Accepts array of lines (strings). If the first line or last line
-- looks like a fence, remove them. This is defensive — it does not change normal code.
function M.strip_fences(lines)
  if not lines or type(lines) ~= "table" or #lines == 0 then return lines end
  local first = lines[1]
  local last = lines[#lines]

  -- fence patterns accept language after opening backticks, e.g. ```lua
  local is_open_fence = first:match("^%s*```[%w_%-%+%#]*%s*$")
  local is_close_fence = last:match("^%s*```%s*$")

  if is_open_fence then
    table.remove(lines, 1)
  end
  -- recalc last after possible removal of first
  if #lines > 0 then
    last = lines[#lines]
    is_close_fence = last:match("^%s*```%s*$")
    if is_close_fence then
      table.remove(lines, #lines)
    end
  end
  return lines
end

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
