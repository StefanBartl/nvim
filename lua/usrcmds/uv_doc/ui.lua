---@module 'uv_doc.ui'
---@brief UI rendering for documentation and symbol lists

local M = {}

local strings = require("lib.strings")
local notify = require("lib.notify")
local config = require("usrcmds.uv_doc.config")
local http = require("usrcmds.uv_doc.http")
local parser = require("usrcmds.uv_doc.parser")
local fetcher = require("usrcmds.uv_doc.fetcher")
local search = require("usrcmds.uv_doc.search")
local normalize = require("usrcmds.uv_doc.normalize")
local constants = require("usrcmds.uv_doc.constants")

--- Opens floating list with cursorline navigation
---@param names string[]
---@param title string
---@param on_enter fun(name: string)
local function open_list(names, title, on_enter)
  if type(names) ~= "table" or #names == 0 then
    notify.info("No symbols to display")
    return
  end

  local buf = vim.api.nvim_create_buf(false, true)
  if not vim.api.nvim_buf_is_valid(buf) then
    notify.error("Failed to create list buffer")
    return
  end

  vim.bo[buf].bufhidden = "wipe"
  vim.api.nvim_buf_set_name(buf, "libuv-index://" .. strings.slugify(title))
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, names)
  vim.bo[buf].filetype = "uvdoc-list"
  vim.bo[buf].modifiable = false

  local width = math.floor(vim.o.columns * 0.5)
  local height = math.min(math.max(#names, 4) + 2, math.floor(vim.o.lines * 0.7))
  local row = math.floor((vim.o.lines - height) / 2 - 1)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = title,
    title_pos = "center",
  })

  if not vim.api.nvim_win_is_valid(win) then
    notify.error("Failed to create list window")
    return
  end

  vim.wo[win].cursorline = true

  local function current_name()
    if not vim.api.nvim_win_is_valid(win) then
      return nil
    end

    local cursor_ok, cursor = pcall(vim.api.nvim_win_get_cursor, win)
    if not cursor_ok or not cursor or #cursor < 2 then
      return nil
    end

    local lnum = cursor[1]
    local line_ok, lines = pcall(vim.api.nvim_buf_get_lines, buf, lnum - 1, lnum, false)
    if not line_ok or not lines or #lines == 0 then
      return nil
    end

    return strings.trim(lines[1])
  end

  vim.keymap.set("n", "<CR>", function()
    local name = current_name()
    if name and not strings.is_empty_or_space(name) then
      pcall(vim.api.nvim_win_close, win, true)
      on_enter(name)
    end
  end, { buffer = buf, nowait = true, silent = true })

  vim.keymap.set("n", "q", function()
    pcall(vim.api.nvim_win_close, win, true)
  end, { buffer = buf, nowait = true, silent = true })

  vim.keymap.set("n", "<Esc>", function()
    pcall(vim.api.nvim_win_close, win, true)
  end, { buffer = buf, nowait = true, silent = true })

  vim.keymap.set("n", "y", function()
    local name = current_name()
    if name and not strings.is_empty_or_space(name) then
      vim.fn.setreg('"', name)
      notify.info("yanked: " .. name)
    end
  end, { buffer = buf, nowait = true, silent = true })
end

--- Renders documentation in float/split
---@param uvname string
---@param src_url string
---@param signature string
---@param body string[]
local function render_doc(uvname, src_url, signature, body)
  ---@type string[]
  local lines = {
    [10] = "",
    [9] = "Summary",
    [8] = "",
    [7] = "```",
    [6] = signature,
    [5] = "```c",
    [4] = "",
    [3] = "C signature",
    [2] = "",
    [1] = "# " .. uvname,
  }

  if #body == 0 then
    lines[11] = "(no summary available)"
  else
    for i = 1, #body do
      lines[#lines + 1] = body[i] or ""
    end
  end

  lines[#lines + 1] = ""
  lines[#lines + 1] = "Source"
  lines[#lines + 1] = ""
  lines[#lines + 1] = src_url

  local buf = vim.api.nvim_create_buf(false, true)
  if not vim.api.nvim_buf_is_valid(buf) then
    notify.error("Failed to create documentation buffer")
    return
  end

  vim.bo[buf].bufhidden = "wipe"
  vim.api.nvim_buf_set_name(buf, "libuv-doc://" .. uvname)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].filetype = "markdown"

  local cfg = config.get()
  if cfg.open == "split" then
    vim.cmd("botright new")
    vim.api.nvim_win_set_buf(0, buf)
  else
    local width = math.floor(vim.o.columns * 0.62)
    local height = math.floor(vim.o.lines * 0.70)
    local row = math.floor((vim.o.lines - height) / 2 - 1)
    local col = math.floor((vim.o.columns - width) / 2)

    vim.api.nvim_open_win(buf, true, {
      relative = "editor",
      width = width,
      height = height,
      row = row,
      col = col,
      style = "minimal",
      border = "rounded",
    })
  end
end

--- Fetches and displays documentation
---@param uvname string
local function fetch_and_show(uvname)
  local idx = fetcher.get_genindex()
  if not idx then
    notify.warn("genindex unavailable; try :h luvref.txt")
    return
  end

  local href = parser.find_href(idx, uvname)
  if not href then
    notify.warn("not found in index: " .. uvname)
    return
  end

  local html_url = constants.BASE_URL .. href
  local rst_url = constants.BASE_URL .. parser.href_to_rst(href)

  local rst, err = http.get(rst_url)
  if not rst then
    notify.error("failed to fetch RST: " .. (err or "unknown"))
    return
  end

  local sig, body = parser.extract_function(rst, uvname)
  if strings.is_empty_or_space(sig) then
    sig, body = parser.extract_type(rst, uvname)
  end

  if strings.is_empty_or_space(sig) then
    notify.warn("could not extract signature for: " .. uvname)
    return
  end

  render_doc(uvname, html_url, sig, body)
end

--- Shows documentation for name or query
---@param name string|nil
function M.show_doc(name)
  local raw = name or vim.fn.expand("<cword>")
  if strings.is_empty_or_space(raw) then
    notify.warn("no name given")
    return
  end

  local looks_exact = raw:match("^uv_%w+$")
    or raw:match("^vim%.uv%.%w+$")
    or raw:match("^vim%.loop%.%w+$")

  if looks_exact then
    fetch_and_show(normalize.to_uv(raw))
    return
  end

  fetcher.ensure_symbols()
  local cands = search.candidates_for(raw)

  if #cands == 0 then
    notify.info("no matches for query: " .. raw)
  elseif #cands == 1 then
    fetch_and_show(cands[1])
  else
    open_list(cands, "libuv: " .. raw, fetch_and_show)
  end
end

--- Shows interactive symbol list
---@param query string|nil
function M.show_list(query)
  fetcher.ensure_symbols()
  local cands = search.candidates_for(query)

  if #cands == 0 then
    notify.info("no matches")
    return
  end

  local title = "libuv index" .. (query and (" [" .. query .. "]") or "")
  open_list(cands, title, fetch_and_show)
end

return M
