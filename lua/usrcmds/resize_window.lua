-- Create a ":Size" user command to resize windows
vim.api.nvim_create_user_command("Size", function(opts)
  -- opts.fargs is a table with the arguments passed to the command
  local direction = opts.fargs[1]
  local step = tonumber(opts.fargs[2]) or 1 -- default step = 1 if omitted

  if not direction then
    print("Usage: :Size <left|right|up|down> <amount>")
    return
  end

  -- Map directions to resize commands
  if direction == "left" then
    vim.cmd("vertical resize -" .. step)
  elseif direction == "right" then
    vim.cmd("vertical resize +" .. step)
  elseif direction == "up" then
    vim.cmd("resize +" .. step)
  elseif direction == "down" then
    vim.cmd("resize -" .. step)
  else
    print("Invalid direction: " .. direction .. ". Use left|right|up|down.")
  end
end, {
  nargs = "+", -- require at least 1 argument
  complete = function(_, _, _)
    -- autocompletion for first arg
    return { "left", "right", "up", "down" }
  end,
  desc = "Resize window in a given direction by a given amount",
})
