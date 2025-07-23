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
    -- Prüft, ob der Buffer ein Dateibuffer ist
    if vim.bo.buftype == "" then
      local file_path = vim.fn.expand("%:p")
      if file_path ~= "" then
        vim.cmd('echo "' .. file_path .. '"')
      end
    end
  end,
  desc = "Shows absolute path of the file only once for file buffers",
})
