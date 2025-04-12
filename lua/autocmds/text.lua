
vim.api.nvim_create_autocmd("BufWritePost", {
  callback = function()
    print("Cursor nach :w: ", vim.fn.line("."), vim.fn.col("."))
  end,
})



-- Automatisches Entfernen von Trailing Leerzeichen
vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*",
    command = [[%s/\s\+$//e]],
})

-- Entfernen von Leerzeichen in leeren Zeilen
vim.api.nvim_create_autocmd("BufWritePre", {
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

-- Function to open welcome layout
local function open_workspace_layout()
  vim.cmd("vsplit")
  vim.cmd("terminal")
  vim.cmd("wincmd j")
  vim.cmd("split")
  vim.cmd("edit /media/steve/Depot/MyGithub/Notes/Notes.md")
  vim.cmd("wincmd k") -- back to terminal
  vim.cmd("wincmd h") -- focus left buffer
  vim.cmd("enew")
  vim.cmd("vertical resize " .. math.floor(vim.o.columns * 2 / 3))
end

-- Autostart: open Notes.md maximized if no file is passed
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    if vim.fn.argc() == 0 then
      vim.cmd("edit /media/steve/Depot/MyGithub/Notes/Notes.md")
      vim.cmd("only") -- maximize
      vim.notify("Willkommen! Drücke <leader>w für dein Setup.", vim.log.levels.INFO)
    end
  end,
})

-- Keymap to open custom layout (use Lazy-friendly format)
vim.keymap.set("n", "<leader>wo", open_workspace_layout, { desc = "Workspace Layout öffnen" })
