---@module 'autocmds.general'

vim.api.nvim_create_augroup("general_autocmds", { clear = true })

-- Auto create dir when saving a file, in case some intermediate directory does not exist
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  group = "general_autocmds",
  callback = function(event)
    if event.match:match("^%w%w+:[\\/][\\/]") then
      return
    end
    local file = vim.uv.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})

-- WATCH:

local autocmd = vim.api.nvim_create_autocmd
autocmd("VimEnter", {
  command = ":silent !kitty @ set-spacing padding=0 margin=0",
})
autocmd("VimLeavePre", {
  command = ":silent !kitty @ set-spacing padding=20 margin=10",
})
-- Show Nvdash when all buffers are closed
vim.api.nvim_create_autocmd("BufDelete", {
  callback = function()
    local bufs = vim.t.bufs
    if #bufs == 1 and vim.api.nvim_buf_get_name(bufs[1]) == "" then
      vim.cmd "Nvdash"
    end
  end,
})


-- Show cursor line only in active window
-- vim.api.nvim_create_autocmd({ 'InsertLeave', 'WinEnter' }, {
-- 	group = augroup('auto_cursorline_show'),
-- 	callback = function(event)
-- 		if vim.bo[event.buf].buftype == '' then
-- 			vim.opt_local.cursorline = true
-- 		end
-- 	end,
-- })
-- vim.api.nvim_create_autocmd({ 'InsertEnter', 'WinLeave' }, {
-- 	group = augroup('auto_cursorline_hide'),
-- 	callback = function()
-- 		vim.opt_local.cursorline = false
-- 	end,
-- })


-- Go to last loc when opening a buffer, see ':h last-position-jump'
-- vim.api.nvim_create_autocmd('BufReadPost', {
-- 	group = augroup('last_loc'),
-- 	callback = function(event)
-- 		local exclude = { 'gitcommit', 'commit', 'gitrebase' }
-- 		local buf = event.buf
-- 		if
-- 			vim.tbl_contains(exclude, vim.bo[buf].filetype)
-- 			or vim.b[buf].lazyvim_last_loc
-- 		then
-- 			return
-- 		end
-- 		vim.b[buf].lazyvim_last_loc = true
-- 		local mark = vim.api.nvim_buf_get_mark(buf, '"')
-- 		local lcount = vim.api.nvim_buf_line_count(buf)
-- 		if mark[1] > 0 and mark[1] <= lcount then
-- 			pcall(vim.api.nvim_win_set_cursor, 0, mark)
-- 		end
-- 	end,
-- })
