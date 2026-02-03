---@module 'lsp.languages.webdev.astro'

local api = vim.api

local M = {}

---@return nil
function M.enable()
  local grp = api.nvim_create_augroup("LangAstro", { clear = true })

  require("lsp.languages.webdev.astro.commands").setup()
  require("lsp.languages.webdev.astro.autocmds").setup()

  api.nvim_create_autocmd("FileType", {
    group = grp,
    pattern = "astro",
    callback = function(_)
      require("lsp.languages.webdev.astro.keymaps").attach()
    end,
  })
end

return M
