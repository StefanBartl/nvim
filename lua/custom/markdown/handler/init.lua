---@module 'custom.markdown.handler.init'
--- Central handler for context-sensitive Markdown actions.
--- Dispatches to image, url, file, or TOC/anchor navigation based on the line under cursor.

local M = {}

local api = vim.api
local image = require("custom.markdown.handler.image")
local url = require("custom.markdown.handler.url")
local file = require("custom.markdown.handler.file")
local anchor = require("custom.markdown.anchor.jump")
local is_inside_toc_block = require("custom.markdown.anchor.is_inside_toc_block")
local is_html_anchor_line = require("custom.markdown.anchor.is_html_anchor_line")
local is_html_extern_anchor_line = require("custom.markdown.anchor.is_html_extern_anchor_line")

local uv = vim.loop

-- Slugify a heading text similar to many Markdown generators (lower, remove punctuation, spaces -> -)
local function slugify(s)
  if not s then
    return ""
  end
  local t = s:lower()
  -- remove curly id suffix if present (we'll handle separately)
  t = t:gsub("%s*{#.-}$", "")
  -- remove HTML tags inside heading
  t = t:gsub("<.->", "")
  -- replace non-alnum with dash
  t = t:gsub("[^%w%s-]", "")
  t = t:gsub("%s+", "-")
  t = t:gsub("-+", "-")
  t = t:gsub("^%-", ""):gsub("%-$", "")
  return t
end

-- Helpers for fragment search
local function escape_lua_pattern(s)
  return (s:gsub("([^%w])", "%%%1"))
end

local function strip_leading_hash(s)
  if not s then
    return s
  end
  return s:gsub("^%s*#%s*", "")
end

-- Search for fragment in current buffer and jump to it.
-- Tolerant to presence/absence of leading '#' in file id attributes.
-- Checks:
--  1) lines with id="fragment" or id='fragment' or id=fragment (unquoted), allowing optional leading '#'
--  2) lines with {#fragment}
--  3) headings whose slugified text equals fragment (GFM-like)
--  4) multi-line chunks (handles id inside style or on next line)
--  5) permissive fallback where fragment appears near HTML tokens
local function search_and_jump_to_fragment(fragment)
  if not fragment or fragment == "" then
    return false
  end

  -- normalize fragment: remove any leading '#'
  local frag = strip_leading_hash(fragment)
  local frag_esc = escape_lua_pattern(frag)

  local bufnr = api.nvim_get_current_buf()
  local total = api.nvim_buf_line_count(bufnr)
  local in_fence = false
  local fence_pattern = "^%s*([`~]{3,})%S*%s*$"

  -- 1) Strong line-by-line checks (id attr, {#frag}, slugified headings)
  for i = 1, total do
    local line = api.nvim_buf_get_lines(bufnr, i - 1, i, false)[1] or ""

    -- Track fenced code blocks
    if line:match(fence_pattern) then
      in_fence = not in_fence
    end
    if in_fence then
      goto continue_line
    end

    -- id attribute: allow id="frag" OR id="#frag" OR id=frag (unquoted)
    local id_pattern = "id%s*=%s*['\"]?#?" .. frag_esc .. "['\"]?"
    if line:match(id_pattern) then
      api.nvim_win_set_cursor(0, { i, 0 })
      return true
    end

    -- {#fragment} pattern (allow multiple leading # on the curly syntax)
    if line:match("{#*" .. frag_esc .. "}") then
      api.nvim_win_set_cursor(0, { i, 0 })
      return true
    end

    -- headings slug match (GFM-like)
    local hashes, title = line:match("^(%s*#+)%s+(.*%S)")
    if hashes and title then
      local base = slugify(title)
      if base == "" then
        base = "section-" .. i
      end
      if base == frag then
        api.nvim_win_set_cursor(0, { i, 0 })
        vim.cmd("normal! zz")
        return true
      end
      -- also consider GitHub duplicate suffixes: base-1, base-2, ...
      if frag:match("^" .. escape_lua_pattern(base) .. "%-?%d*$") then
        api.nvim_win_set_cursor(0, { i, 0 })
        vim.cmd("normal! zz")
        return true
      end
    end

    ::continue_line::
  end

  -- 2) Multi-line tag chunks (handles cases where id sits inside style or on next line)
  local radius = 5
  for i = 1, total do
    local start_line = i
    local end_line = math.min(total, i + radius)
    local ok, chunk_lines = pcall(api.nvim_buf_get_lines, bufnr, start_line - 1, end_line, false)
    if ok and chunk_lines then
      local chunk = table.concat(chunk_lines, " ")
      -- check id inside chunk (allow optional leading # in attribute)
      if chunk:match("id%s*=%s*['\"]?#?" .. frag_esc .. "['\"]?") or chunk:match("{#*" .. frag_esc .. "}") then
        api.nvim_win_set_cursor(0, { i, 0 })
        return true
      end
      -- if chunk contains relevant tags and the fragment token appears nearby, jump
      if
        (chunk:lower():match("<figure") or chunk:lower():match("<img") or chunk:lower():match("<figcaption"))
        and chunk:match(frag_esc)
      then
        api.nvim_win_set_cursor(0, { i, 0 })
        return true
      end
    end
  end

  -- 3) Permissive fallback: fragment appears on a line that also contains html-related tokens
  for i = 1, total do
    local line = api.nvim_buf_get_lines(bufnr, i - 1, i, false)[1] or ""
    if line:match(frag_esc) then
      if
        line:match("id")
        or line:match("style")
        or line:match("figure")
        or line:match("img")
        or line:match("figcaption")
        or line:match("src")
        or line:match("alt")
      then
        api.nvim_win_set_cursor(0, { i, 0 })
        return true
      end
    end
  end

  return false
end

-- Resolve target path relative to current buffer (like image/file handlers)
local function resolve_target_path(target)
  if not target then
    return nil
  end
  -- If it's a URL (http(s)), return as-is
  if target:match("^https?://") then
    return target
  end
  local expanded = vim.fn.expand(target)
  if not expanded:match("^/") and not expanded:match("^%a:[/\\]") then
    local bufdir = vim.fn.expand("%:p:h")
    if bufdir and bufdir ~= "" then
      expanded = vim.fn.fnamemodify(bufdir .. "/" .. expanded, ":p")
    else
      expanded = vim.fn.fnamemodify(expanded, ":p")
    end
  else
    expanded = vim.fn.fnamemodify(expanded, ":p")
  end
  return expanded
end

-- Try to open a file in the current window (edit). Returns true if file opened.
local function open_file_in_current_window(path)
  if not path or path == "" then
    return false
  end
  -- If it's a URL, defer to url handler
  if path:match("^https?://") then
    return url.open(path)
  end
  local stat = uv.fs_stat(path)
  if not stat then
    vim.notify("[Custom.Markdown] External anchor: target file not found: " .. tostring(path), vim.log.levels.WARN)
    return false
  end
  -- open with :edit
  vim.cmd("edit " .. vim.fn.fnameescape(path))
  return true
end

--- Handle action under cursor.
--- Priority: TOC/Anchor navigation > HTML anchors > Image > URL > File
---@return nil
function M.handle_cursor_action()
  local line = api.nvim_get_current_line()

  -- 1. Markdown TOC/Anchor links (intra-file)
  if line and line:match("%(#[^)]+%)") then
    if is_inside_toc_block() or line:match("^%s*%-+%s*%[") then
      anchor.jump()
      return
    end
  end

  -- 2. HTML Anchors (intra-file)
  if is_html_anchor_line(line) then
    anchor.jump()
    return
  end

  -- NEW: 2b. External file link with fragment -> open file and jump to fragment
  local ext = is_html_extern_anchor_line(line)
  if ext and ext.target then
    local target = ext.target
    local fragment = ext.fragment
    local resolved = resolve_target_path(target)
    if not resolved then
      vim.notify(
        "[Custom.Markdown] External anchor: could not resolve target: " .. tostring(target),
        vim.log.levels.WARN
      )
    else
      local ok = open_file_in_current_window(resolved)
      if ok then
        if fragment and fragment ~= "" then
          local jumped = search_and_jump_to_fragment(fragment)
          if not jumped then
            vim.notify(
              "[Custom.Markdown] External anchor: opened file but anchor '" .. fragment .. "' not found",
              vim.log.levels.INFO
            )
          end
        end
        return
      end
    end
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

  -- 5. File (plain file links without fragment)
  if file.is_file_line(line) then
    file.open(line)
    return
  end

  vim.notify("[Custom.Markdown] Handler: No recognized target under cursor", vim.log.levels.INFO)
end

return M
