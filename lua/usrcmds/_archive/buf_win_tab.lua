--- Tabs
vim.api.nvim_create_user_command(
  "MoveBufferToTab",
  function()
       require("custom.functions.buf_win_tabs.move_buffer_to_tab").move_current_buffer_to_new_tab()
  end,
  { desc = "Move the current buffer to a new tab" }
)
