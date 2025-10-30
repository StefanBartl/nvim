---@module 'custom.markdown.anchor.jump'
--- Jump to the header linked under cursor.
--- Handles duplicate anchors using GitHub convention (slug, slug-1, slug-2, ...).

---@class anchor_jump_module
---@field jump fun(): nil
local M = {}

--- GitHub/GFM-like slug generator (identical to toc.lua implementation).
--- Matches the exact logic from custom.markdown.core.toc module.
---@param title string
---@return string
local function slugify_gfm(title)
  -- Step 1: Convert to lowercase
  local s = title:lower()
  -- Step 2: Replace whitespace sequences with single hyphen
  s = s:gsub("%s+", "-")
  -- Step 3: Remove all chars except alphanumeric, hyphen, and underscore
  s = s:gsub("[^%w%-%_]", "")
  -- Step 4: Collapse multiple consecutive hyphens
  s = s:gsub("%-+", "-")
  -- Step 5: Trim leading/trailing hyphens and underscores
  s = s:gsub("^[-_]+", ""):gsub("[-_]+$", "")
  return s
end

--- Extract anchor from current line.
--- Matches patterns like [text](#anchor) or ![alt](#anchor).
---@param line string
---@return string|nil
local function extract_anchor(line)
  if not line then return nil end
  return line:match("%(#([^)]+)%)")
end

--- Jump to heading matching the given anchor.
--- Respects fenced code blocks and handles duplicate anchors.
---@param anchor string
---@return boolean success
local function jump_to_anchor(anchor)
  if not anchor or anchor == "" then return false end

  local bufnr = vim.api.nvim_get_current_buf()
  local total = vim.api.nvim_buf_line_count(bufnr)
  local seen_count = {}
  local in_fence = false
  local fence_pattern = "^%s*([`~]{3,})%S*%s*$"

  for i = 1, total do
    local line = vim.api.nvim_buf_get_lines(bufnr, i - 1, i, false)[1] or ""

    -- Track fence blocks to skip headings inside code
    if line:match(fence_pattern) then
      in_fence = not in_fence
    elseif not in_fence then
      local hashes, title = line:match("^(%s*#+)%s+(.*%S)")
      if hashes and title then
        local base = slugify_gfm(title)
        if base == "" then
          base = "section-" .. tostring(i)
        end

        -- Calculate current anchor with duplicate handling
        local count = seen_count[base] or 0
        local current_anchor
        if count == 0 then
          current_anchor = base
        else
          current_anchor = base .. "-" .. tostring(count)
        end
        seen_count[base] = count + 1

        -- Check if this matches the target anchor
        if current_anchor == anchor then
          vim.api.nvim_win_set_cursor(0, {i, 0})
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
  local line = vim.api.nvim_get_current_line()
  local anchor = extract_anchor(line)

  if not anchor then
    vim.notify("[Custom.Markdown] Anchor: No anchor found under cursor", vim.log.levels.INFO)
    return
  end

  if not jump_to_anchor(anchor) then
    vim.notify("[Custom.Markdown] Anchor: Could not find heading for anchor: " .. anchor, vim.log.levels.WARN)
  end
end

return M
