-- log state on window enter to help debug toggles
vim.api.nvim_create_autocmd("WinEnter", {
  callback = function()
    local ft = vim.bo.filetype or "<none>"
    local bufnr = vim.api.nvim_get_current_buf()
    local winbar = vim.wo.winbar ~= "" and vim.wo.winbar or "<empty>"
    local tabline = vim.o.tabline ~= "" and vim.o.tabline or "<empty>"
    vim.schedule(function()
      -- use schedule to avoid fast-event echo issues
      vim.notify(string.format("[win-debug] ft=%s bufnr=%d winbar=%s tabline=%s", ft, bufnr, winbar, tabline), vim.log.levels.DEBUG)
    end)
  end,
})
