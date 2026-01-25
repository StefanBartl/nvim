---@module 'uv_doc.insert'
---@brief Signature insertion at cursor position

local M = {}

local strings = require("lib.strings")
local http = require("usrcmds.uv_doc.http")
local parser = require("usrcmds.uv_doc.parser")
local fetcher = require("usrcmds.uv_doc.fetcher")
local search = require("usrcmds.uv_doc.search")
local normalize = require("usrcmds.uv_doc.normalize")
local constants = require("usrcmds.uv_doc.constants")

-- Create notify instance with proper API
local notify = require("lib.notify").create("uv_doc")

--- Fetches and inserts signature at cursor
---@param uvname string
local function fetch_and_insert_signature(uvname)
  local idx = fetcher.get_genindex()
  if not idx then
    notify("genindex unavailable; try :h luvref.txt", vim.log.levels.WARN)
    return
  end

  local href = parser.find_href(idx, uvname)
  if not href then
    notify("not found in index: " .. uvname, vim.log.levels.WARN)
    return
  end

  local rst_url = constants.BASE_URL .. parser.href_to_rst(href)
  local rst, err = http.get(rst_url)
  if not rst then
    notify("failed to fetch RST: " .. (err or "unknown"), vim.log.levels.ERROR)
    return
  end

  local sig, _ = parser.extract_function(rst, uvname)
  if not strings.is_empty_or_space(sig) then
    vim.api.nvim_put({ "```c", sig, "```" }, "l", true, true)
    return
  end

  sig, _ = parser.extract_type(rst, uvname)
  if not strings.is_empty_or_space(sig) then
    vim.api.nvim_put({ sig }, "l", true, true)
    return
  end

  notify("could not extract signature for: " .. uvname, vim.log.levels.WARN)
end

--- Opens list for signature insertion
---@param names string[]
---@param title string
local function open_insert_list(names, title)
  if type(names) ~= "table" or #names == 0 then
    notify("No symbols to display", vim.log.levels.INFO)
    return
  end

  local buf = vim.api.nvim_create_buf(false, true)
  if not vim.api.nvim_buf_is_valid(buf) then
    notify("Failed to create list buffer", vim.log.levels.ERROR)
    return
  end

  vim.bo[buf].bufhidden = "wipe"
  vim.api.nvim_buf_set_name(buf, "libuv-insert://" .. strings.slugify(title))
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
    notify("Failed to create list window", vim.log.levels.ERROR)
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
      fetch_and_insert_signature(name)
    end
  end, { buffer = buf, nowait = true, silent = true })

  vim.keymap.set("n", "q", function()
    pcall(vim.api.nvim_win_close, win, true)
  end, { buffer = buf, nowait = true, silent = true })

  vim.keymap.set("n", "<Esc>", function()
    pcall(vim.api.nvim_win_close, win, true)
  end, { buffer = buf, nowait = true, silent = true })
end

--- Inserts signature for name or query
---@param name string|nil
function M.insert_signature(name)
  local raw = name or vim.fn.expand("<cword>")
  if strings.is_empty_or_space(raw) then
    notify("no name given", vim.log.levels.WARN)
    return
  end

  local looks_exact = raw:match("^uv_%w+$")
    or raw:match("^vim%.uv%.%w+$")
    or raw:match("^vim%.loop%.%w+$")

  if looks_exact then
    fetch_and_insert_signature(normalize.to_uv(raw))
    return
  end

  fetcher.ensure_symbols()
  local cands = search.candidates_for(raw)

  if #cands == 0 then
    notify("no matches for query: " .. raw, vim.log.levels.INFO)
  elseif #cands == 1 then
    fetch_and_insert_signature(cands[1])
  else
    open_insert_list(cands, "insert signature [" .. raw .. "]")
  end
end

return M
