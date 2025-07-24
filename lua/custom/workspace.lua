-- Function to open welcome layout
local function open_workspace_layout()
  vim.cmd("vsplit")
  vim.cmd("terminal")
  vim.cmd("wincmd j")
  vim.cmd("split")
  vim.cmd("edit /media/steve/Depot/MyCodeberg/Notes/Notes.md")
  vim.cmd("wincmd k") -- back to terminal
  vim.cmd("wincmd h") -- focus left buffer
  vim.cmd("enew")
  vim.cmd("vertical resize " .. math.floor(vim.o.columns * 2 / 3))
end

-- Keymap to open custom layout (use Lazy-friendly format)
vim.keymap.set("n", "<leader>ow", open_workspace_layout, { desc = "[Custom] Workspace Layout öffnen" })

-- Zeigt den Pfad beim Öffnen oder Wechseln eines Buffers, aber nur für Dateibuffer
vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    if vim.bo.buftype == "" then
      local curr_buf = vim.api.nvim_get_current_buf()
      local curr_win = vim.api.nvim_get_current_win()
      local win_buf = vim.api.nvim_win_get_buf(curr_win)

      if curr_buf == win_buf then
        local path = vim.fn.expand("%:p"):gsub("\\", "/")
        if path ~= "" then
          vim.notify(path)
        end
      end
    end
  end,
  desc = "Shows path for opening file buffer if visible.",
})


