---@module 'myterm.keymaps'
---@brief Keybindings for myterm terminal management


local function setup(myterm)
  local state = require("custom.myterm.state")
  local runner = require("custom.myterm.command_runner")
  -- New terminals
  vim.keymap.set("n", "<leader>tf", function() myterm.new("float") end, { desc = "[Myterm] New Floating Terminal" })
  vim.keymap.set("n", "<leader>th", function() myterm.new("horizontal") end,
    { desc = "[Myterm] New Horizontal Terminal" })
  vim.keymap.set("n", "<leader>tv", function() myterm.new("vertical") end, { desc = "[Myterm] New Vertical Terminal" })

  -- Toggle last focused
  vim.keymap.set("n", "<leader>to", myterm.toggle, { desc = "[Myterm] Toggle Active Terminal" })

  -- Command handling
  vim.keymap.set("n", "<leader>tt", myterm.set_command, { desc = "[Myterm] Terminal: Set Command" })
  vim.keymap.set("n", "<leader>tr", function() myterm.run() end, { desc = "[Myterm] Terminal: Run Command" })
  vim.keymap.set("n", "<leader>tc", myterm.clear_command, { desc = "[Myterm] Terminal: Clear Command" })

  -- Info & state
  vim.keymap.set("n", "<leader>ti", myterm.show_active, { desc = "[Myterm] Terminal: Show Active Info" })
  vim.keymap.set("n", "<leader>tx", function()
    local id = state.get_focused_id()
    if id then myterm.close(id) end
  end, { desc = "[Myterm] Terminal: Close Active" })

  -- Send command in background
  vim.keymap.set("n", "<leader>ts", function()
    local id = tonumber(vim.fn.input("Send to Terminal ID: "))
    local cmd = vim.fn.input("Command: ")
    if id and cmd ~= "" then
      local ok, err = runner.send_background(id, cmd)
      if not ok then
        vim.notify("Send failed: " .. (err or "unknown error"), vim.log.levels.ERROR)
      end
    end
  end, { desc = "[Myterm] Terminal: Send Background Command" })

  -- Focus terminal by ID
  vim.keymap.set("n", "<leader>tfoc", function()
    local id = tonumber(vim.fn.input("Focus Terminal ID: "))
    if id then myterm.focus(id) end
  end, { desc = "[Myterm] Terminal: Focus ID" })
end

return {
  setup = setup,
}
