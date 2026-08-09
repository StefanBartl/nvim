---@module 'bindings.usrcmds.case.marks'
--- Session-local mark set for bulk `:Cases close` — "wie in filetree.nvim":
--- toggle a case on `:Cases list` with `m` (or a Visual-line range), and
--- `:Cases close` picks up whatever's marked instead of opening its own
--- multi-select picker. Deliberately flat (a set of short numbers, not tied
--- to any buffer/window) — marks set while browsing `:Cases list` still
--- apply after that view is closed and `:Cases close` is run later.

local M = {}

---@type table<string, true>
local marked = {}

---@param short string
function M.toggle(short)
  marked[short] = not marked[short] or nil
end

---@param short string
---@return boolean
function M.is_marked(short)
  return marked[short] == true
end

function M.clear()
  marked = {}
end

---@return string[] sorted short numbers
function M.list()
  local out = {}
  for short in pairs(marked) do
    out[#out + 1] = short
  end
  table.sort(out)
  return out
end

---@return integer
function M.count()
  local n = 0
  for _ in pairs(marked) do
    n = n + 1
  end
  return n
end

return M
