---@module 'myterm.autocmds'
---@brief [[
--- Autocommands to clean up terminal state when buffers are deleted.
---@brief ]]

local state = require("custom.myterm.state")

local function setup()
  vim.api.nvim_create_autocmd({ "BufWipeout", "BufDelete" }, {
    callback = function(args)
      local bufnr = args.buf
      state.remove_by_buf(bufnr)
    end,
    desc = "[myterm] Clean up state when terminal buffer is closed",
  })

  vim.api.nvim_create_autocmd("TermEnter", {
    pattern = "*",
    callback = function()
      vim.keymap.set("t", "<Esc>", function()
        local state = require("custom.myterm.state")
        local term = state.get_last_focused()
        if term and vim.api.nvim_win_is_valid(term.win) then
          vim.api.nvim_win_hide(term.win)
          --print("Terminal " .. term.id .. " minimized via <Esc>")
        else
          vim.notify("No valid terminal to minimize", vim.log.levels.WARN)
        end
      end, { buffer = true, silent = true })

      local focused = state.get_last_focused()
      if focused then
        require("custom.myterm.label").apply(focused)
      end
    end,
    desc = "[myterm] Refresh label and <Esc> binding on TermEnter",
  })
end

return {
  setup = setup,
}
