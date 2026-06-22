---@module 'custom.markdown.tableview.views.browser_basic'

local notify = require("lib.nvim.notify").create("[custom.markdown.tableview.views.browser_basic]")

local api = vim.api
local parser = require("custom.markdown.tableview.parser")

-- small helper: escape HTML special chars
---@param s string
---@return string
local function html_escape(s)
  if s == nil then
    return ""
  end
  -- simple replacement for &, <, >, " and '
  s = s:gsub("&", "&amp;")
  s = s:gsub("<", "&lt;")
  s = s:gsub(">", "&gt;")
  s = s:gsub('"', "&quot;")
  s = s:gsub("'", "&#39;")
  return s
end

return function(bufnr)
  local line = api.nvim_win_get_cursor(0)[1]
  local tables = parser.get_tables(bufnr)
  local chosen = nil
  for _, t in ipairs(tables) do
    if t.start_line <= line and line <= (t.end_line or t.start_line) then
      chosen = t
      break
    end
  end
  if not chosen then
    notify.info("[Costum.Markdown.TableView] No table under cursor")
    return
  end
  -- Simple fallback: create a temporary markdown snippet and open in default browser
  local tmp = vim.fn.tempname() .. ".html"
  local fh = io.open(tmp, "w")
  if not fh then
    notify.error("[Costum.Markdown.TableView] Failed to create temp file for browser preview")
    return
  end
  -- minimal HTML table generator
  fh:write("<!doctype html><html><head><meta charset='utf-8'><title>TableView</title>")
  fh:write(
    "<style>table{border-collapse:collapse;font-family:system-ui,Segoe UI,Roboto,Arial;}th,td{border:1px solid #bbb;padding:6px;text-align:left}</style>"
  )
  fh:write("</head><body><table><thead><tr>")
  for _, c in ipairs(chosen.header.cells) do
    fh:write("<th>" .. html_escape(c.content or "") .. "</th>")
  end
  fh:write("</tr></thead><tbody>")
  for _, r in ipairs(chosen.rows) do
    fh:write("<tr>")
    for _, c in ipairs(r.cells) do
      fh:write("<td>" .. html_escape(c.content or "") .. "</td>")
    end
    fh:write("</tr>")
  end
  fh:write("</tbody></table></body></html>")
  fh:close() -- open with system viewer
  local esc = vim.fn.shellescape(tmp)
  local sys = vim.loop.os_uname().sysname or ""
  local cmd
  if sys:match("Windows") or sys:match("windows") then
    cmd = string.format('cmd /C start "" %s', esc)
  elseif sys == "Darwin" then
    cmd = string.format("open %s", esc)
  else
    cmd = string.format("xdg-open %s", esc)
  end
  pcall(vim.fn.jobstart, cmd, { detach = true })
end
