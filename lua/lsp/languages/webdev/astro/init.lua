---@module 'lsp.languages.webdev.astro'

local api = vim.api

local M = {}

---@return nil
function M.enable()
  local grp = api.nvim_create_augroup("LangAstro", { clear = true })

  require("lsp.languages.webdev.astro.usercmds").setup()
  require("lsp.languages.webdev.astro.autocmds").setup()

  -- Auto-tag setup (versuche zuerst nvim-ts-autotag)
  local autotag = require("lsp.languages.webdev.astro.autotag")
  local autotag_ok = autotag.setup()

  -- Auto-start LSP for astro files
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'astro',
    callback = function(args)
      require("lsp.languages.webdev.astro.keymaps").attach()

      -- Falls nvim-ts-autotag nicht verfügbar, nutze manuelle Implementation
      if not autotag_ok then
        autotag.setup_manual_autoclose(args.bufnr)
      end
      -- Buffer-lokale Settings
      vim.bo[args.bufnr].commentstring = "{/* %s */}"
      vim.bo[args.bufnr].shiftwidth = 2
      vim.bo[args.bufnr].tabstop = 2
      vim.bo[args.bufnr].expandtab = true

      -- The server should auto-attach due to filetypes in config
      -- But we can force it if needed
      vim.schedule(function()
        local clients = vim.lsp.get_clients({ bufnr = args.buf, name = 'astro' })
        if #clients == 0 then
          vim.lsp.start({
            name = 'astro',
            cmd = { 'astro-ls', '--stdio' },
            -- cmd = { 'astro-language-server', '--stdio' },
          })
        end
      end)
    end,
    desc = 'Start Astro LSP',
  })

end

return M
