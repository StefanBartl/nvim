---@module 'utils.replace_buffer_with_clipboard'

-- Function to clear the current buffer and paste from system clipboard
local function replace_with_clipboard()
  -- Get text from the + register (system clipboard)
  local clip = vim.fn.getreg("+")
  -- Split into lines (Neovim expects a list of lines for buffer API)
  local lines = vim.split(clip, "\n", { plain = true })

  -- Replace the whole buffer content
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end

vim.keymap.set("n", "<leader>rp", replace_with_clipboard, {
  desc = "[Edit] Replace buffer with clipboard content",
  noremap = true,
  silent = true,
})
vim.api.nvim_create_user_command("ReplaceWithClipboard", replace_with_clipboard, {
  desc = "Replace current buffer with system clipboard content",
})
