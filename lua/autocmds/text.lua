---@module 'autocmds.text'

-- Create (or clear) an augroup for text-related autocmds
vim.api.nvim_create_augroup("text_autocmds", { clear = true })

--- Remove trailing whitespace on save
vim.api.nvim_create_autocmd("BufWritePre", {
  group = "text_autocmds",
  pattern = "*",
  command = [[%s/\s\+$//e]],
})

--- Remove whitespace from empty lines while preserving cursor position
vim.api.nvim_create_autocmd("BufWritePre", {
  group = "text_autocmds",
  pattern = "*",
  callback = function()
    ---@type integer, integer
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    vim.cmd([[silent! %s/^\s*$//e]])
    vim.api.nvim_win_set_cursor(0, { row, col })
  end,
})

--- Restore last cursor position when reopening a file
--- Skips commit messages, hexdumps, and git rebase files
vim.api.nvim_create_autocmd("BufReadPost", {
  group = "text_autocmds",
  pattern = "*",
  callback = function()
    ---@type integer
    local line = vim.fn.line([['"]])
    if
        line > 1
        and line <= vim.fn.line("$")
        and vim.bo.filetype ~= "commit"
        and vim.fn.index({ "xxd", "gitrebase" }, vim.bo.filetype) == -1
    then
      vim.cmd([[normal! g`"]])
    end
  end,
})

--- Automatically open images with the default image viewer on read
vim.api.nvim_create_autocmd("BufReadPost", {
  group = "text_autocmds",
  pattern = { "*.jpg", "*.jpeg", "*.png" },
  callback = function()
    vim.fn.system("open " .. vim.fn.expand("%"))
  end,
})
