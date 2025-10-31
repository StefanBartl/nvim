---@module 'custom.markdown.handler.init'
--- Central handler for context-sensitive Markdown actions.
--- Dispatches to image, url, file, or TOC/anchor navigation based on the line under cursor.

local M = {}

local api = vim.api
local image  = require("custom.markdown.handler.image")
local url    = require("custom.markdown.handler.url")
local file   = require("custom.markdown.handler.file")
local anchor = require("custom.markdown.anchor.jump")
local is_inside_toc_block = require("custom.markdown.anchor.is_inside_toc_block")
local is_html_anchor_line = require("custom.markdown.anchor.is_html_anchor_line")
--AUDIT: EXTERN JUMPS

--- Handle action under cursor.
--- Priority: TOC/Anchor navigation > HTML anchors > Image > URL > File
---@return nil
function M.handle_cursor_action()
  local line = api.nvim_get_current_line()

  -- 1. Markdown TOC/Anchor links
  if line and line:match("%(#[^)]+%)") then
    if is_inside_toc_block() or line:match("^%s*%-+%s*%[") then
      anchor.jump()
      return
    end
  end

  -- 2. HTML Anchors
  if is_html_anchor_line(line) then
    anchor.jump()
    return
  end

  -- 3. Image
  if image.is_image_line(line) then
    image.open(line)
    return
  end

  -- 4. URL
  if url.is_url_line(line) then
    url.open(line)
    return
  end

  -- 5. File
  if file.is_file_line(line) then
    file.open(line)
    return
  end

  vim.notify("[Custom.Markdown] Handler: No recognized target under cursor", vim.log.levels.INFO)
end

return M
