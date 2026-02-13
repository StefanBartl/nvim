---@module 'lsp.languages.webdev.astro'

local M = {}

local bo = vim.bo

---@return nil
function M.enable()
  -- local grp = api.nvim_create_augroup("LangAstro", { clear = true })

  require("lsp.languages.webdev.astro.usercmds").setup()
  require("lsp.languages.webdev.astro.autocmds").setup()

  -- Auto-tag setup (versuche zuerst nvim-ts-autotag)
  local autotag = require("lsp.languages.webdev.astro.autotag")
  local autotag_ok = autotag.setup()

  -- FIXED: Don't call vim.lsp.start() - let vim.lsp.enable() handle it
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'astro',
    callback = function(args)
      require("lsp.languages.webdev.astro.keymaps").attach()

      -- Falls nvim-ts-autotag nicht verfügbar, nutze manuelle Implementation
      if not autotag_ok then
        autotag.setup_manual_autoclose(args.buf)
      end

      -- Buffer-lokale Settings
      bo[args.buf].commentstring = "{/* %s */}"
      bo[args.buf].shiftwidth = 2
      bo[args.buf].tabstop = 2
      bo[args.buf].expandtab = true

      -- REMOVED: vim.lsp.start() - causes conflict with vim.lsp.enable()
      -- The server auto-attaches because:
      -- 1. vim.lsp.config("astro", {...}) defines the config
      -- 2. vim.lsp.enable("astro") enables auto-attach on FileType
      -- 3. filetypes = { "astro" } triggers attachment
    end,
    desc = 'Configure Astro buffer settings',
  })
end

---@type Lsp.Languages.ConfiguredLangs.Webdev.Astro.Modu1e
return M
