---@module 'markdown.fenced_fix'
-- Neutralize blanket color links on fenced code so injections can shine through.

---@class UIMarkdownFencedFix
local M = {}

local function safe_link(name, target)
  pcall(vim.api.nvim_set_hl, 0, name, { link = target })
end

local function safe_clear(name)
  -- Empty opts table clears explicit fg/bg/style while keeping default link resolution.
  pcall(vim.api.nvim_set_hl, 0, name, {})
end

function M.apply()
  -- Legacy regex groups (used by builtin 'syntax/markdown.vim' or some themes)
  safe_clear("markdownCode")                 -- remove enforced single-color
  safe_link("markdownCodeDelimiter", "Comment")

  -- Tree-sitter markup groups (Neovim ≥0.9)
  -- Some colorschemes color the entire fenced area via these captures.
  -- Relink them to Normal to allow injected language tokens to define their own colors.
  safe_link("@markup.raw", "Normal")
  safe_link("@markup.raw.markdown_inline", "Normal")
  safe_link("@markup.raw.block", "Normal")
  safe_link("@markup.fenced_code.block", "Normal")

  -- Optional: make inline code (`\``) distinct but not overpowering
  safe_link("@markup.raw.inline", "String")  -- tiny hint for `inline code`
end

return M

