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
vim.keymap.set("n", "<leader>wo", open_workspace_layout, { desc = "Workspace Layout öffnen" })
