---@module 'wkdoptions.italic_keywords'
--- Per-language keyword lists (return/for/if/... equivalents) that get
--- italicized -- lua/typescript/go/cpp/rust each with their own set.
local Autocmd = require("lib.nvim.bindings.autocmd")

local M = {}

-- Sprachen-spezifische Keyword-Definitionen
M.languages = {
  lua = { enabled = true, keywords = { "return", "in", "for", "while", "if", "then", "else" } },
  typescript = { enabled = true, keywords = { "return", "in", "const", "let", "async", "await" } },
  go = { enabled = true, keywords = { "return", "range", "defer", "go", "select" } },
  cpp = { enabled = true, keywords = { "return", "auto", "const", "constexpr", "nullptr" } },
  rust = { enabled = true, keywords = { "return", "let", "mut", "match", "impl" } },
  asm = { enabled = true, keywords = { "mov", "jmp", "ret", "call", "push", "pop" } },
}

function M.setup()
  for lang, config in pairs(M.languages) do
    if config.enabled then
      Autocmd.create("FileType", function()
        -- Doppelte Backslashes für Vim-Regex!
        local pattern = '\\<\\(' .. table.concat(config.keywords, '\\|') .. '\\)\\>'
        vim.fn.matchadd('ItalicKeywords_' .. lang, pattern)
      end, {
        pattern = lang,
      })

      -- Highlight-Gruppe pro Sprache
      vim.api.nvim_set_hl(0, 'ItalicKeywords_' .. lang, { italic = true })
    end
  end
end

return M
