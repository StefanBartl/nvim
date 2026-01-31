---@module 'lsp.languages.java'

local M = {}

local api = vim.api

---@return nil
function M.enable()
  local grp = api.nvim_create_augroup("LangJava", { clear = true })

  api.nvim_create_autocmd("FileType", {
    group = grp,
    pattern = { "java" },
    callback = function(ev)
      local bufnr = ev.buf

      -- Set reasonable defaults
      vim.bo[bufnr].shiftwidth = 4
      vim.bo[bufnr].tabstop = 4
      vim.bo[bufnr].expandtab = true

      -- Organize imports on save
      api.nvim_create_autocmd("BufWritePre", {
        buffer = bufnr,
        callback = function()
          vim.lsp.buf.code_action({
            context = { only = { "source.organizeImports" } },
            apply = true,
          })
        end,
      })
    end,
  })
end

return M
