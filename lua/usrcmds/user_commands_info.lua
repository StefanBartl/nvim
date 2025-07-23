---@module 'utils.user_commands_info'
---@class UserCommandInfo
---@field name string
---@field definition string
---@field desc? string

local M = {}

---Get all user-defined commands with description
---@return UserCommandInfo[]
function M.list_user_commands()
  local raw = vim.api.nvim_get_commands({ builtin = false })
  local result = {}

  for name, cmd in pairs(raw) do
    table.insert(result, {
      name = ":" .. name,
      definition = cmd.definition or "",
      desc = cmd.desc or "",
    })
  end

  table.sort(result, function(a, b)
    return a.name < b.name
  end)

  return result
end

---Print all user commands nicely formatted
function M.print_user_commands()
  local cmds = M.list_user_commands()
  local lines = { "**User-defined Commands:**", "" }

  for _, cmd in ipairs(cmds) do
    table.insert(lines, string.format("%-25s %s", cmd.name, cmd.desc or ""))
  end

  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "User Commands" })
end

return M
