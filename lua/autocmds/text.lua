vim.api.nvim_create_augroup("mytext", { clear = true })

-- Automatisches Entfernen von Trailing Leerzeichen
vim.api.nvim_create_autocmd("BufWritePre", {
  group = "mytext",
  pattern = "*",
  command = [[%s/\s\+$//e]],
})

-- Entfernen von Leerzeichen in leeren Zeilen
vim.api.nvim_create_autocmd("BufWritePre", {
  group = "mytext",
  pattern = "*",
  callback = function()
    local curpos = vim.api.nvim_win_get_cursor(0)
    vim.cmd([[silent! %s/^\s*$//e]])
    vim.api.nvim_win_set_cursor(0, curpos)
  end,
})

-- Restore cursor position
-- Der Code sorgt dafür, dass beim Öffnen einer Datei der Cursor automatisch zur letzten gespeicherten Position in der Datei springt, außer in folgenden Fällen:
--- -) Die Datei ist eine git commit-Nachricht.
--- -) Die Datei ist ein Hexdump (xxd) oder eine Git-Rebase-Datei.

vim.api.nvim_create_autocmd("BufReadPost", {
  group = "mytext",
  pattern = "*",
  callback = function()
    local line = vim.fn.line "'\""
    if
        line > 1
        and line <= vim.fn.line "$"
        and vim.bo.filetype ~= "commit"
        and vim.fn.index({ "xxd", "gitrebase" }, vim.bo.filetype) == -1
    then
      vim.cmd 'normal! g`"'
    end
  end,
})

-- Image viewer
vim.api.nvim_create_autocmd("BufReadPost", {
  group = "mytext",
  pattern = { "*.jpg", "*.jpeg", "*.png" },
  callback = function()
    vim.fn.system("open " .. vim.fn.expand("%"))
  end
})
