---@module 'debugging.autocmds.list_autocmds'
--- Module for debugging autocommands in Neovim

---List all autocommands matching a specific event and pattern
---@param event string The autocommand event to filter by (e.g., "BufAdd")
---@param pattern string|nil The pattern to match (e.g., "*"), defaults to "*"
---@return nil
local function list_autocmds(event, pattern)
  pattern = pattern or "*"

  -- Get all autocommands for the specified event
  local autocmds = vim.api.nvim_get_autocmds({
    event = event,
    pattern = pattern,
  })

  if #autocmds == 0 then
    print(string.format("No autocommands found for event '%s' with pattern '%s'", event, pattern))
    return
  end

  print(string.format("\n=== Autocommands for %s %s ===\n", event, pattern))

  for i, cmd in ipairs(autocmds) do
    print(string.format("[%d] Group: %s", i, cmd.group_name or "default"))
    print(string.format("    Event: %s", cmd.event))
    print(string.format("    Pattern: %s", cmd.pattern or "N/A"))
    print(string.format("    Buffer: %s", cmd.buffer or "N/A"))

    if cmd.command then
      print(string.format("    Command: %s", cmd.command))
    end

    if cmd.callback then
      print(string.format("    Callback: <function>"))
    end

    if cmd.desc then
      print(string.format("    Description: %s", cmd.desc))
    end

    print("")
  end
end

-- Usage example in command mode
vim.api.nvim_create_user_command("DebugListAutocmds", function(opts)
  local event = opts.fargs[1] or "BufAdd"
  local pattern = opts.fargs[2]
  list_autocmds(event, pattern)
end, {
  nargs = "*",
  desc = "[debugging.automcds] List all autocommands for a specific event and pattern",
})
