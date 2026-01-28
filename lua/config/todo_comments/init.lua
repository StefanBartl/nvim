---@module 'config.todo_comments'
-- Export a setup function so lazy.nvim can pass opts reliably.

local unique_table = require("lib.tables.unique_table")

local M = {}

local todo_ok, todo = pcall(require, "todo-comments")
if not todo_ok then
  function M.setup(_) end
  return {}
end

local KEYWORDS = require("config.todo_comments.keywords")

local function build_keyword_list(keywords)
  ---@type string[]
  local words = {}

  for k, v in pairs(keywords) do
    words[#words + 1] = vim.pesc(k)

    if type(v.alt) == "table" then
      for _, a in ipairs(v.alt) do
        words[#words + 1] = vim.pesc(a)
      end
    end
  end

  local unique = unique_table.unique(words)
  return table.concat(unique, "|")
end

local keyword_or = build_keyword_list(KEYWORDS)

function M.setup(opts)
  opts = opts or {}
  if not opts.keywords then
    opts.keywords = KEYWORDS
  end

  opts.highlight = opts.highlight or {}

  opts.highlight.pattern = "\\v\\C<(" .. keyword_or .. ")>" -- exact word match, case-sensitive
  opts.highlight.before = nil -- do not include chars before the match
  opts.highlight.keyword = nil -- remove 'wide' expansion; let plugin default apply
  opts.highlight.after = nil -- do not include chars after the match
  opts.highlight.comments_only = true -- uses treesitter to match keywords in comments only
  opts.highlight.multiline = true -- enable multine todo comments
  opts.highlight.multiline_pattern = "^." -- lua pattern to match the next multiline from the start of the matched keyword
  opts.highlight.multiline_context = 3 -- extra lines that will be re-evaluated when changing a line

  todo.setup(opts)
end

return M
