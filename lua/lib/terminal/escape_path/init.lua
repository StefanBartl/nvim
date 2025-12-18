---@module 'lib.terminal.escape_path'
-- Cross-platform path escaping for terminal commands
-- Escape spaces and special characters for shell

return function(path)
  return path:gsub("([%s%$`\\])", "\\%1")
end
