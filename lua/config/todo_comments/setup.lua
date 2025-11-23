---@module 'config.todo_comments.setup'
-- Export a setup function so lazy.nvim can pass opts reliably.

local M = {}

local todo_ok, todo = pcall(require, "todo-comments")
if not todo_ok then
  function M.setup(_) end
  return M
end

local KEYWORDS = require("config.todo_comments.keywords")

local function build_keyword_list(keywords)
  local words = {}
  for k, v in pairs(keywords) do
    table.insert(words, vim.pesc(k))
    if type(v.alt) == "table" then
      for _, a in ipairs(v.alt) do
        table.insert(words, vim.pesc(a))
      end
    end
  end
  local seen = {}
  local unique = {}
  for _, w in ipairs(words) do
    if not seen[w] then
      seen[w] = true
      table.insert(unique, w)
    end
  end
  return table.concat(unique, "|")
end

local keyword_or = build_keyword_list(KEYWORDS)

function M.setup(opts)
  opts = opts or {}
  if not opts.keywords then
    opts.keywords = KEYWORDS
  end

  opts.highlight = opts.highlight or {}

  if not opts.highlight.pattern then
    opts.highlight.pattern = "\\v\\C<(" .. keyword_or .. ")>"   -- exact word match, case-sensitive
    opts.highlight.before = nil        -- do not include chars before the match
    opts.highlight.keyword = nil      -- remove 'wide' expansion; let plugin default apply
    opts.highlight.after = nil         -- do not include chars after the match
    opts.highlight.comments_only = false
    opts.highlight.multiline = true
    opts.highlight.multiline_pattern = "^."
    opts.highlight.multiline_context = 3
  end

  todo.setup(opts)
end

return M
