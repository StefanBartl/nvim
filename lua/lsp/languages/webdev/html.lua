---@module 'lsp.languages.webdev.html'
--- HTML language enablement helpers for autocommands and small QoL.

---@return nil
local M = {}

---@return nil
function M.enable()
  local grp = vim.api.nvim_create_augroup("LangHtml", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = grp,
    pattern = { "html", "htmldjango", "djangohtml" },
    callback = function(event)
      -- Example small QoL: ensure omnifunc is set for legacy completion fallback
      local bufnr = event.buf
      pcall(function()
        vim.api.nvim_set_option_value("omnifunc", "v:lua.vim.lsp.omnifunc", { buf = bufnr })
      end)
    end,
  })
end

return M
