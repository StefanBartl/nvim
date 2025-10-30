---@module 'custom.markdown.tableview.views.live'

local api = vim.api
local uv = vim.loop
local notify = vim.notify
local parser = require("custom.markdown.tableview.parser")

local M = {}

local state = {
  running = false,
  port = nil,
  job_id = nil,
  html_file = nil,
  tmpdir = nil,
  ts_file = nil,
}

local DEFAULT_PORT = 4567

-- Helper: choose table under cursor
---@param bufnr number
---@return MarkdownTable?|nil
local function choose_table_under_cursor(bufnr)
  local line = api.nvim_win_get_cursor(0)[1]
  local tables = parser.get_tables(bufnr)
  for _, t in ipairs(tables) do
    if t.start_line <= line and line <= (t.end_line or t.start_line) then
      return t
    end
  end
  return nil
end

-- Ensure temporary directory for buffer
---@return string tmpdir
local function ensure_tmpdir_for_buf()
  state.tmpdir = state.tmpdir or vim.fn.tempname()
  vim.fn.mkdir(state.tmpdir, "p")
  state.ts_file = state.tmpdir .. "/timestamp.txt"
  return state.tmpdir
end

-- Write preview files
---@param table MarkdownTable
---@param tmpdir string
---@return boolean ok, string?|nil err
local function write_preview_files(table, tmpdir)
  local tmpfile = tmpdir .. "/table.html"
  local fh, err = io.open(tmpfile, "w")
  if not fh then return false, err end

  local function html_escape(s)
    if not s then return "" end
    s = s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
    s = s:gsub('"', "&quot;"):gsub("'", "&#39;")
    return s
  end

  fh:write("<!doctype html><html><head><meta charset='utf-8'><title>TableView</title>")
  fh:write([[
    <style>
      table { border-collapse: collapse; font-family: system-ui,Segoe UI,Roboto,Arial; }
      th { border: 2px solid #666; background: #f0f0f0; padding: 6px; text-align: left; }
      td { border: 1px solid #bbb; padding: 6px; text-align: left; }
    </style>
  ]])
  fh:write("</head><body><table><thead><tr>")
  for _, c in ipairs(table.header.cells) do
    fh:write("<th>" .. html_escape(c.content or "") .. "</th>")
  end
  fh:write("</tr></thead><tbody>")
  for _, r in ipairs(table.rows) do
    fh:write("<tr>")
    for _, c in ipairs(r.cells) do
      fh:write("<td>" .. html_escape(c.content or "") .. "</td>")
    end
    fh:write("</tr>")
  end
  fh:write("</tbody></table></body></html>")
  fh:close()

  state.html_file = tmpfile
  return true
end

-- Start HTTP server (simple)
---@return number?|nil port, uv_process_t?|nil job
local function start_http_server(_, port)
  -- Simple placeholder: in real implementation könnte uv_http_server oder python -m http.server verwendet werden
  -- hier nur ein Dummy: return port, nil
  return port
end

-- Open browser for file
---@param html_file string
---@param port number
local function open_browser_for_file(html_file, port)
  port = port or DEFAULT_PORT
  local filename = vim.fn.fnamemodify(html_file, ":t")
  local url = string.format("http://127.0.0.1:%d/%s", port, filename)
  local sys = uv.os_uname().sysname or ""
  if sys:match("Windows") or sys:match("windows") then
    vim.fn.jobstart({ "cmd", "/C", "start", "", url }, { detach = true })
  elseif sys == "Darwin" then
    vim.fn.jobstart({ "open", url }, { detach = true })
  else
    vim.fn.jobstart({ "xdg-open", url }, { detach = true })
  end
end

-- Public: start live preview
---@param bufnr number|nil
function M.start(bufnr)
  bufnr = bufnr or api.nvim_get_current_buf()
  local chosen = choose_table_under_cursor(bufnr)
  if not chosen then
    notify("[Custom.Markdown.TableView] No table under cursor for live preview", vim.log.levels.INFO)
    return
  end

  local tmpdir = ensure_tmpdir_for_buf()
  local ok, err = write_preview_files(chosen, tmpdir)
  if not ok then
    notify("[Custom.Markdown.TableView] Failed to write preview files: " .. tostring(err), vim.log.levels.ERROR)
    return
  end

  local port, job = start_http_server(tmpdir, DEFAULT_PORT)
  if not port then
    notify("[Custom.Markdown.TableView] Failed to start HTTP server", vim.log.levels.ERROR)
    return
  end

  state.port = port
  state.job_id = job
  state.running = true

  open_browser_for_file(state.html_file, state.port)
  notify("[Custom.Markdown.TableView] Live preview started (port " .. tostring(state.port) .. ")", vim.log.levels.INFO)
end

-- Public: regenerate preview
---@param bufnr number|nil
function M.regenerate(bufnr)
  bufnr = bufnr or api.nvim_get_current_buf()
  local chosen = choose_table_under_cursor(bufnr)
  local tmpdir = state.tmpdir or ensure_tmpdir_for_buf()
  if chosen then
    write_preview_files(chosen, tmpdir)
  elseif state.ts_file and vim.fn.filereadable(state.ts_file) == 1 then
    local tsfh = io.open(state.ts_file, "w")
    if tsfh then tsfh:write(tostring(os.time())); tsfh:close() end
  end
end

-- Public: stop live preview
function M.stop()
  if state.job_id then
    pcall(vim.fn.jobstop, state.job_id)
    state.job_id = nil
  end
  state.running = false
  notify("[Custom.Markdown.TableView] Live preview stopped", vim.log.levels.INFO)
end

-- Public: install autocmd
function M.setup_autocmd()
  local aug = api.nvim_create_augroup("CustomMarkdownTableViewLive", { clear = true })
  api.nvim_create_autocmd("BufWritePost", {
    group = aug,
    pattern = { "*.md", "*.markdown", "*.mdx" },
    callback = function(ev)
      if not state.running then return end
      M.regenerate(ev.buf)
    end,
    desc = "Regenerate TableView live preview on save",
  })
  notify("[Custom.Markdown.TableView] Live preview autocommand installed", vim.log.levels.DEBUG)
end

return M
