---@module 'wkddap.utils.validation'

local M = {}

--- Pick process ID for attach mode
---@return thread|nil pid
function M.pick_process()
  local co = coroutine.running()
  if co then
    return coroutine.create(function()
      vim.ui.select(vim.fn.systemlist("ps -eo pid,comm"), {
        prompt = "Select process:",
        format_item = function(item)
          return item
        end,
      }, function(choice)
        if choice then
          coroutine.resume(co, tonumber(choice:match("^%s*(%d+)")))
        else
          coroutine.resume(co, nil)
        end
      end)
    end)
  end
  return nil
end

--- Validate file exists
---@param path string File path
---@return boolean valid, string? error
function M.validate_file(path)
  if not path or path == "" then
    return false, "Empty path"
  end

  local stat = vim.loop.fs_stat(path)
  if not stat then
    return false, "File not found: " .. path
  end

  if stat.type ~= "file" then
    return false, "Not a file: " .. path
  end

  return true, nil
end

return M
