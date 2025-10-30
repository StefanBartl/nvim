---@module 'custom.markdown.handler.init'
--- Central handler for context-sensitive Markdown actions.
--- Dispatches to image, url, file, or TOC navigation based on the line under cursor.
---@class handler_module
---@field handle_cursor_action fun(): nil
local M = {}

local api = vim.api
local image  = require("custom.markdown.handler.image")
local url    = require("custom.markdown.handler.url")
local file   = require("custom.markdown.handler.file")
local anchor = require("custom.markdown.anchor.jump")

--- Check if current line contains an anchor link pattern.
--- Matches [text](#anchor) or ![alt](#anchor).
---@param line string
---@return boolean
local function is_anchor_line(line)
  return line and line:match("%(#[^)]+%)") ~= nil
end

--- Check if current line is inside a TOC block.
--- A TOC block starts with the header and ends with "---" or next heading.
---@return boolean
local function is_inside_toc_block()
  local bufnr = api.nvim_get_current_buf()
  local cursor_line = api.nvim_win_get_cursor(0)[1]
  local total = api.nvim_buf_line_count(bufnr)

  -- Search backwards for TOC header
  local toc_start = nil
  for i = cursor_line, 1, -1 do
    local line = api.nvim_buf_get_lines(bufnr, i - 1, i, false)[1]
    if line and line:match("^%s*##%s+[Tt]able%s+[Oo]f%s+[Cc]ontent") then
      toc_start = i
      break
    end
    -- Stop if we hit another heading
    if line and line:match("^%s*#%s+") then
      break
    end
  end

  if not toc_start then return false end

  -- Search forwards from TOC start for separator or next heading
  for i = toc_start + 1, total do
    local line = api.nvim_buf_get_lines(bufnr, i - 1, i, false)[1]
    if line and (line:match("^%s*%-%-%-%s*$") or line:match("^%s*#%s+")) then
      return cursor_line >= toc_start and cursor_line < i
    end
  end

  return cursor_line >= toc_start
end

--- Handle action under cursor.
--- Priority: TOC/Anchor navigation > Image > URL > File
---@return nil
function M.handle_cursor_action()
  local line = api.nvim_get_current_line()

  -- Check for anchor links (TOC or other internal links)
  if is_anchor_line(line) then
    -- Prefer TOC context, but handle all anchor links
    if is_inside_toc_block() or line:match("^%s*%-+%s*%[") then
      anchor.jump()
      return
    end
  end

  if image.is_image_line(line) then
    image.open(line)
    return
  end
  if url.is_url_line(line) then
    url.open(line)
    return
  end
  if file.is_file_line(line) then
    file.open(line)
    return
  end

  vim.notify("[Custom.Markdown] Handler: No recognized target under cursor", vim.log.levels.INFO)
end

return M
