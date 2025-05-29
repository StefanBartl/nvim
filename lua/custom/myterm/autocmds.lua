---@module 'myterm.autocmds'
---@brief Autocommands for terminal cleanup and key handling
---@description
--- This module defines autocommands for terminal behavior and state management:
--- - Automatically removes terminal state on buffer deletion
--- - Sets up <Esc> keybinding to minimize active terminal windows

-- State Tracking
local state = require("custom.myterm.state")

local function setup()
  -- Remove terminal state when buffer is deleted
  vim.api.nvim_create_autocmd({ "BufWipeout", "BufDelete" }, {
    callback = function(args)
      local bufnr = args.buf
      assert(type(bufnr) == "number", "bufnr must be a number")
      state.remove_by_buf(bufnr)
    end,
    desc = "[myterm] Clean up state when terminal buffer is closed",
  })

  -- Map <Esc> in terminal-normal mode to hide the window
  vim.api.nvim_create_autocmd("TermEnter", {
    pattern = "*",
    callback = function()
      vim.keymap.set("t", "<Esc>", function()
        local term = state.get_last_focused()
        if term and vim.api.nvim_win_is_valid(term.win) then
          vim.api.nvim_win_hide(term.win)
          print("Terminal " .. term.id .. " minimized via <Esc>")
        end
        -- do nothing if window invalid; don't notify here
      end, { buffer = true, silent = true, desc = "Minimize terminal via <Esc>" })
    end,
    desc = "[myterm] Map <Esc> to minimize terminal window",
  })
end

return {
  setup = setup,
}
