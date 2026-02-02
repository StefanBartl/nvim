---@module 'config.treesitter.parser'

--- Return a list of Tree-sitter parsers to ensure installed
---@return string[]
return {
  "bash",
  "c",
  "cpp",
  "dockerfile",
  "go",
  "gomod",
  "gosum",
  "json",
  "lua",
  "markdown",
  "markdown_inline",
  "python",
  "query",
  "regex",
  "rust",
  "sql",
  "toml",
  "tsx",
  "vim",
  "vimdoc",
  "yaml",

  -- Web Development
  "css",
  "html",
  "javascript",
  "typescript",
  "astro",

  -- Git
  "git_config",
  "git_rebase",
  "gitattributes",
  "gitcommit",
  "gitignore",
}
