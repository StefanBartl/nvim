-- test.lua
local M = {}

function M.test_completion()
  -- HIER sollte Completion funktionieren:
  vim.api.nvim_   -- <-- Ctrl+Space hier
  vim.fn.           -- <-- Ctrl+Space hier
  vim.uv.       -- <-- Ctrl+Space hier

  local tbl = { foo = 1, bar = 2 }
  tbl.  -- <-- Ctrl+Space hier (sollte foo/bar zeigen)
end

return
