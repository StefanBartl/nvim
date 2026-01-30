---@module 'custom.markdown.anchor.jump'
--- Jump to the header linked under cursor.
--- Handles duplicate anchors using GitHub convention (slug, slug-1, slug-2, ...).
--- Recognizes Markdown links, image links, HTML <img>, <a>, <div>, <section> elements with #anchor.

---@class anchor_jump_module
---@field jump fun(): nil

local notify = require("lib.notify").create("[custom.markdown.anchor.jump]")

local M = {}

local api = vim.api

--- GitHub/GFM-like slug generator (identical to toc.lua implementation).
---@param title string
---@return string
local function slugify_gfm(title)
  local s = title:lower()
  s = s:gsub("%s+", "-")
  s = s:gsub("[^%w%-%_]", "")
  s = s:gsub("%-+", "-")
  s = s:gsub("^[-_]+", ""):gsub("[-_]+$", "")
  return s
end

--- Extract anchor from current line.
--- Recognizes:
---  * Markdown links: [text](#anchor)
---  * Markdown image links: ![alt](#anchor)
---  * HTML tags with href or src: <a href="#anchor">, <img src="#anchor">
---  * HTML elements with id: <div id="#anchor">, <section id="#anchor">
---@param line string
---@return string|nil
local function extract_anchor(line)
  if not line or line == "" then
    return nil
  end

  -- 1. Markdown link / image link
  local md = line:match("%(#([^)]+)%)")
  if md then
    return md
  end

  -- 2. HTML <img src="#...">
  local img = line:match("<img[^>]-src%s*=%s*[\"']#(.-)[\"']")
  if img then
    return img
  end

  -- 3. HTML <a href="#...">
  local ahref = line:match("<a[^>]-href%s*=%s*[\"']#(.-)[\"']")
  if ahref then
    return ahref
  end

  -- 4. HTML element with id="#..."
  local idtag = line:match("<%w+[^>]-id%s*=%s*[\"']#(.-)[\"']")
  if idtag then
    return idtag
  end

  return nil
end

--- Jump to heading matching the given anchor.
--- Respects fenced code blocks and handles duplicate anchors (GitHub style).
---@param anchor string
---@return boolean success
local function jump_to_anchor(anchor)
  if not anchor or anchor == "" then
    return false
  end

  local bufnr = api.nvim_get_current_buf()
  local total = api.nvim_buf_line_count(bufnr)
  local seen_count = {}
  local in_fence = false
  local fence_pattern = "^%s*([`~]{3,})%S*%s*$"

  for i = 1, total do
    local line = api.nvim_buf_get_lines(bufnr, i - 1, i, false)[1] or ""

    -- Track fenced code blocks
    if line:match(fence_pattern) then
      in_fence = not in_fence
    elseif not in_fence then
      local hashes, title = line:match("^(%s*#+)%s+(.*%S)")
      if hashes and title then
        local base = slugify_gfm(title)
        if base == "" then
          base = "section-" .. i
        end

        local count = seen_count[base] or 0
        local current_anchor
        if count == 0 then
          current_anchor = base
        else
          current_anchor = base .. "-" .. tostring(count)
        end
        seen_count[base] = count + 1

        if current_anchor == anchor then
          api.nvim_win_set_cursor(0, { i, 0 })
          vim.cmd("normal! zz")
          return true
        end
      end
    end
  end

  return false
end

--- Jump to the header linked under cursor.
---@return nil
function M.jump()
  local ok, line = pcall(api.nvim_get_current_line)
  if not ok or not line then
    notify.error("[Custom.Markdown] Anchor: Could not read current line")
    return
  end

  local anchor = extract_anchor(line)
  if not anchor then
    notify.info("[Custom.Markdown] Anchor: No anchor found under cursor")
    return
  end

  local success = pcall(jump_to_anchor, anchor)
  if not success then
    notify.warn("[Custom.Markdown] Anchor: Could not jump to anchor: " .. anchor)
  end
end

return M
