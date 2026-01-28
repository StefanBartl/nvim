---@module 'config.todo_comments'

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
  opts.highlight.pattern = "\\v\\C<(" .. keyword_or .. ")>"
  opts.highlight.before = nil
  opts.highlight.keyword = nil
  opts.highlight.after = nil
  opts.highlight.comments_only = true
  opts.highlight.multiline = true
  opts.highlight.multiline_pattern = "^."
  opts.highlight.multiline_context = 3

  todo.setup(opts)
end

return M
