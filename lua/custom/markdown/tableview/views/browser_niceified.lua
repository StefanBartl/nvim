---@module 'custom.markdown.tableview.views.browser_niceified'
--- Render selected Markdown table as a nicer HTML page and open it in the system browser.
--- This module returns a function(bufnr) that finds the table at the current cursor
--- and opens a temporary HTML file in the system default browser.

local api = vim.api
local notify = vim.notify
local parser = require("custom.markdown.tableview.parser")

--- Escape HTML special characters for safe insertion into the generated HTML.
---@param s string?
---@return string
local function html_escape(s)
  if s == nil then return "" end
  s = tostring(s)
  s = s:gsub("&", "&amp;")
  s = s:gsub("<", "&lt;")
  s = s:gsub(">", "&gt;")
  s = s:gsub('"', "&quot;")
  s = s:gsub("'", "&#39;")
  return s
end

--- Build a small, pleasant HTML document for the table.
--- Adds thicker borders, header styling, zebra rows, subtle shadow and responsive layout.
---@param chosen MarkdownTable
---@param source string optional textual source / caption
---@return string html
local function build_html(chosen, source)
  local buf = {}
  local function w(s) table.insert(buf, s) end

  w("<!doctype html><html><head><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'>")
  w("<title>TableView — Preview</title>")
  -- CSS: nicer table appearance
  w([[
  <style>
    :root{
      --bg:#f7fafc;
      --card:#ffffff;
      --muted:#6b7280;
      --border:#c4c7cc;
      --accent:#0f172a;
      --header-bg:#0f172a;
      --header-fg:#ffffff;
      --zebra:#fbfdff;
    }
    html,body{height:100%;margin:0;background:var(--bg);font-family:Inter,Segoe UI,Roboto,Helvetica,Arial,sans-serif;color:var(--accent);}
    .wrap{max-width:1100px;margin:36px auto;padding:18px;}
    .card{background:var(--card);border-radius:10px;box-shadow:0 6px 24px rgba(15,23,42,0.08);overflow:hidden;border:2px solid var(--border);}
    header{padding:14px 18px;border-bottom:1px solid rgba(0,0,0,0.04);display:flex;align-items:center;gap:12px;}
    header h1{font-size:16px;margin:0;font-weight:600;color:var(--header-bg);}
    header .meta{margin-left:auto;font-size:12px;color:var(--muted);}
    .table-wrap{padding:18px;overflow:auto;}
    table{width:100%;border-collapse:separate;border-spacing:0;table-layout:auto;}
    thead th{background:linear-gradient(180deg,var(--header-bg),rgba(0,0,0,0.03));color:var(--header-fg);padding:10px 12px;text-align:left;font-weight:700;border-bottom:3px solid var(--border);font-size:13px;}
    tbody td{padding:10px 12px;border-bottom:1px solid rgba(0,0,0,0.04);vertical-align:top;font-size:13px}
    tbody tr:nth-child(odd){background:var(--zebra)}
    tbody tr:hover{background:rgba(15,23,42,0.03)}
    .caption{padding:12px 18px;border-top:1px solid rgba(0,0,0,0.04);font-size:12px;color:var(--muted);background:linear-gradient(180deg, rgba(255,255,255,0.02), transparent);}
    @media (max-width:700px){
      header h1{font-size:14px}
      thead th, tbody td{font-size:12px;padding:8px}
    }
  </style>
  ]])
  w("</head><body><div class='wrap'><div class='card'>")

  -- Header: show a title and optional source info
  w("<header>")
  w("<h1>Table Preview</h1>")
  if source and source ~= "" then
    w("<div class='meta'>" .. html_escape(source) .. "</div>")
  end
  w("</header>")

  w("<div class='table-wrap'><table><thead><tr>")
  -- header cells
  for _, c in ipairs(chosen.header.cells) do
    w("<th>" .. html_escape(c.content or "") .. "</th>")
  end
  w("</tr></thead><tbody>")
  for _, r in ipairs(chosen.rows) do
    w("<tr>")
    for _, c in ipairs(r.cells) do
      -- preserve simple markdown emphasis by escaping; heavy markdown rendering is out of scope here
      w("<td>" .. html_escape(c.content or "") .. "</td>")
    end
    w("</tr>")
  end
  w("</tbody></table></div>")

  -- Caption area with source info and small tips
  w("<div class='caption'>")
  w("<div>Rendered by TableView — exported HTML preview.</div>")
  if source and source ~= "" then
    w("<div style='margin-top:6px;color:var(--muted)'>Source: " .. html_escape(source) .. "</div>")
  end
  w("</div>") -- caption

  w("</div></div></body></html>")
  return table.concat(buf, "")
end

--- Public: generate HTML for table at cursor and open in system browser
---@param bufnr number
---@return nil
return function(bufnr)
  bufnr = bufnr or api.nvim_get_current_buf()
  if not (api.nvim_buf_is_valid(bufnr) and api.nvim_buf_is_loaded(bufnr)) then
    notify("[Custom.Markdown.TableView] Invalid buffer for browser preview", vim.log.levels.ERROR)
    return
  end

  local cur_line = api.nvim_win_get_cursor(0)[1]
  local tables = parser.get_tables(bufnr)
  local chosen = nil
  for _, t in ipairs(tables) do
    if t.start_line <= cur_line and cur_line <= (t.end_line or t.start_line) then
      chosen = t
      break
    end
  end

  if not chosen then
    notify("[Custom.Markdown.TableView] No table under cursor", vim.log.levels.INFO)
    return
  end

  -- Build a human-readable source caption: "col <start_line>; H1, H2, H3"
  local headers = {}
  for _, c in ipairs(chosen.header.cells or {}) do table.insert(headers, c.content or "") end
  local source = string.format("col %d; %s", chosen.start_line or 0, table.concat(headers, ", "))

  local html = build_html(chosen, source)

  local tmp = vim.fn.tempname() .. ".html"
  local fh, err = io.open(tmp, "w")
  if not fh then
    notify("[Custom.Markdown.TableView] Failed to write preview file: " .. tostring(err), vim.log.levels.ERROR)
    return
  end
  fh:write(html)
  fh:close()

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
