---@module 'swd.zig'

-- Zig integration in Neovim using zig.vim and manual LSP setup (without mason)

-- Disable the error window for parse errors from zig.vim
vim.g.zig_fmt_parse_errors = 0

-- Disable automatic formatting on save from zig.vim
-- We will instead use formatting via the LSP (zls)
vim.g.zig_fmt_autosave = 0

-- Format the buffer using LSP before saving .zig and .zon files
vim.api.nvim_create_autocmd('BufWritePre', {
  pattern = { "*.zig", "*.zon" },
  callback = function()
    -- Calls the LSP's format function (zls supports zig fmt-style formatting)
    vim.lsp.buf.format()
  end,
})

-- Optional: apply code actions like import sorting or fixable issues on save
vim.api.nvim_create_autocmd('BufWritePre', {
  pattern = { "*.zig", "*.zon" },
  callback = function()
    vim.lsp.buf.code_action({
      -- Only apply specific types of code actions:
      -- - organizeImports: reorder or remove unused imports
      -- - fixAll: apply all fixable diagnostics (if supported)
      context = {
        diagnostics = {},
        only = { "source.organizeImports", "source.fixAll" }
      },
      apply = true, -- Apply the action(s) automatically without user prompt
    })
  end,
})

local lspconfig = require("lspconfig")

lspconfig.zls.setup({
  -- Manually specify the path to the ZLS binary
  -- Do not rely on mason here, especially if using Zig nightly
  cmd = { vim.fn.expand("~/tools/zls/zig-out/bin/zls") },

  settings = {
    zls = {
      -- Enable semantic tokens for better syntax highlighting in the UI
      semantic_tokens = "partial",

      -- Optional: specify path to Zig executable, if it's not in your $PATH
      zig_exe_path = vim.fn.expand("~/tools/zig-x86_64-linux-0.15.0-dev.1380+e98aeeb73/zig")
    }
  }
})
