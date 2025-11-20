---@module 'custom.markdown.core.fold'

local M = {}

-- existing helpers ...

function M.foldexpr(lnum)
  local line = vim.fn.getline(lnum)

  -- frontmatter / fences handling remains as before (if you had it here)

  -- ATX heading?
  local atx = line:match("^%s*(#+)%s+")
  if atx then
    local a = #atx
    return ">" .. a -- simplified: no special-casing for H1
  end

  -- Setext H2 underline (---)
  local prev = vim.fn.getline(lnum - 1)
  if prev and prev:match("^%s*%S") and line:match("^%s*[-=]+%s*$") then
    return ">2"
  end

  return "="
end

function M.toggle_under_cursor()
  vim.cmd.normal({ args = { "za" }, bang = false })
  vim.cmd.normal({ args = { "zz" }, bang = false })
end

function M.unfold_all_center()
  vim.cmd.normal({ args = { "zR" }, bang = false })
  vim.cmd.normal({ args = { "zz" }, bang = false })
end

return M
