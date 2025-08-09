---@module 'lsp.languages.typescript'
---@class LangTsQoL

local M = {}

---@return nil
function M.enable()
  local grp = vim.api.nvim_create_augroup("LangTs", { clear = true })
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = grp,
    pattern = { "*.ts", "*.tsx", "*.js", "*.jsx" },
    callback = function(ev)
      local has_ts = false
      for _, c in ipairs(vim.lsp.get_clients({ bufnr = ev.buf })) do
        if c.name == "ts_ls" then has_ts = true; break end
      end
      if not has_ts then return end
      pcall(vim.lsp.buf.code_action, {
        apply = true,
        context = { only = { "source.organizeImports.ts" }, diagnostics = {} },
      })
    end,
  })
end

return M
