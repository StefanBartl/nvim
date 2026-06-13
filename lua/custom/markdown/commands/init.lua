---@module 'custom.markdown.commands'
--- Dispatcher for all :Markdown subcommands.

local M = {}

---@type table<string, fun(args:string[])>
local commands = {
  links = require("custom.markdown.commands.markdown_links").run,
}

--- Execute markdown subcommand
---@param argv string[]
function M.execute(argv)
  local command = argv[1]

  if not command then
    vim.notify(
      "Usage: :Markdown <subcommand>",
      vim.log.levels.INFO
    )
    return
  end

  local fn = commands[command]

  if not fn then
    vim.notify(
      string.format("Unknown Markdown command: %s", command),
      vim.log.levels.ERROR
    )
    return
  end

  table.remove(argv, 1)

  fn(argv)
end

--- Completion for :Markdown
---@param arglead string
---@param cmdline string
---@param cursorpos integer
---@return string[]
function M.complete(arglead, cmdline, cursorpos)
  -- Currently unused but kept for future subcommand-aware completion.
  local _ = cmdline
  local _ = cursorpos

  local result = {} ---@type string[]

  for name in pairs(commands) do
    if vim.startswith(name, arglead) then
      result[#result + 1] = name
    end
  end

  table.sort(result)

  return result
end

return M
