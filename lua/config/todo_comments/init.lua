---@module 'config.todo_comments'
--- todo-comments.nvim setup, built from `keywords/init.lua`'s keyword table
--- -- degrades to a no-op `M.setup` if todo-comments itself is not
--- installed, rather than erroring.

local unique_table = require("lib.lua.tables.unique_table")

local M = {}

local todo_ok, todo = pcall(require, "todo-comments")
if not todo_ok then
  ---@param _ table|nil # Unused
  function M.setup(_) end
  return {}
end

local KEYWORDS = require("config.todo_comments.keywords")

--- Workaround for an upstream todo-comments bug:
---   highlight.lua:94 nvim_buf_set_extmark -> "Invalid 'end_col': out of range"
--- add_highlight() snapshots the buffer lines, then applies extmarks; if the
--- buffer shrinks in between (e.g. rapidly switching buffers) the cached `#line`
--- end_col is now past the real line length and the extmark call throws.
--- add_highlight is a local, so we wrap the module's public highlight() and
--- temporarily clamp any out-of-range columns while it runs. Highlights still
--- apply correctly; only the stray error is gone. Idempotent.
local function patch_highlight_endcol()
  local ok, hl = pcall(require, "todo-comments.highlight")
  if not ok or type(hl.highlight) ~= "function" or hl.__endcol_clamped then
    return
  end

  local api = vim.api
  local orig = hl.highlight

  hl.highlight = function(buf, first, last, event)
    if not api.nvim_buf_is_valid(buf) then
      return
    end

    local orig_set = api.nvim_buf_set_extmark
    api.nvim_buf_set_extmark = function(b, ns, line, col, opts)
      local snapshot = api.nvim_buf_get_lines(b, line, line + 1, false)
      local len = snapshot[1] and #snapshot[1] or nil
      if len == nil then
        -- Line vanished since the snapshot; drop this extmark instead of erroring.
        return 0
      end
      if col > len then
        col = len
      end
      if opts and type(opts.end_col) == "number" and opts.end_col > len then
        opts.end_col = len
      end
      return orig_set(b, ns, line, col, opts)
    end

    local ok_run = pcall(orig, buf, first, last, event)
    api.nvim_buf_set_extmark = orig_set
    return ok_run
  end

  hl.__endcol_clamped = true
end

---@param keywords table<string, { alt: string[]? }>
local function build_keyword_list(keywords)
  ---@type string[]
  local words = {}

  for k, v in pairs(keywords) do
    --AUDIT::  REMOVED vim.pesc - keywords should not be escaped for Vim regex
    words[#words + 1] = k  -- Changed from: vim.pesc(k)

    if type(v.alt) == "table" then
      for _, a in ipairs(v.alt) do
        words[#words + 1] = a  -- Changed from: vim.pesc(a)
      end
    end
  end

  local unique = unique_table.unique(words)
  return table.concat(unique, "|")
end

local keyword_or = build_keyword_list(KEYWORDS)

---@param opts table|nil
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
  patch_highlight_endcol()
end

return M
