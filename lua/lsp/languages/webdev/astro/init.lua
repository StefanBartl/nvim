---@module 'lsp.languages.webdev.astro'

local api = vim.api

local M = {}

---@return nil
function M.enable()
  local grp = api.nvim_create_augroup("LangAstro", { clear = true })

  api.nvim_create_autocmd("FileType", {
    group = grp,
    pattern = "astro",
    callback = function(ev)
      local bufnr = ev.buf

      -- Tabs/Spaces
      vim.bo[bufnr].shiftwidth = 2
      vim.bo[bufnr].tabstop = 2
      vim.bo[bufnr].expandtab = true

      -- Format on save
      api.nvim_create_autocmd("BufWritePre", {
        buffer = bufnr,
        callback = function()
          local ok, conform = pcall(require, "conform")
          if ok then
            conform.format({ bufnr = bufnr, timeout_ms = 2000 })
          else
            vim.lsp.buf.format({ bufnr = bufnr, timeout_ms = 2000 })
          end
        end,
      })
    end,
  })

  require("lsp.languages.webdev.astro.keymaps").attach()

  vim.notify("astro lsop attached")
end

return M


