-- Automatisches Entfernen von Trailing Leerzeichen
vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*",
    command = [[%s/\s\+$//e]],
})

-- Entfernen von Leerzeichen in leeren Zeilen
vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*",
    command = [[%s/^\s*$//e]],
})

-- Restore cursor position
-- Der Code sorgt dafür, dass beim Öffnen einer Datei der Cursor automatisch zur letzten gespeicherten Position in der Datei springt, außer in folgenden Fällen:
--- -) Die Datei ist eine git commit-Nachricht.
--- -) Die Datei ist ein Hexdump (xxd) oder eine Git-Rebase-Datei.

local autocmd = vim.api.nvim_create_autocmd
autocmd("BufReadPost", {
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
    pattern = {"*.jpg", "*.jpeg", "*.png"},
    callback = function()
        vim.fn.system("open " .. vim.fn.expand("%"))
    end
})

-- Enter fügt Zeile oberhalb ein
