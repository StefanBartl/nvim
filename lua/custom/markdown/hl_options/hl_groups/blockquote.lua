---@module 'custom.markdown.hl_options.hl_groups.blockquote'
--- VS Code–style blockquote highlighting with two distinct regions:
---
---   MarkdownBlockquoteMarker  – the `>` token: colored fg, no bg
---   MarkdownBlockquoteText    – the text after `>`: normal fg, colored bg
---
--- Why two matchadd() calls instead of one nvim_set_hl?
---
---   Tree-sitter fires @punctuation.special.markdown (priority 100) on `>`,
---   which beats any nvim_set_hl link at priority 90. The text after `>` has
---   no covering capture at all in most parsers. matchadd() at priority 110
---   wins in both cases.
---
--- \zs in the text pattern means "match starts here": the `>\s*` prefix is
--- used for position but is NOT highlighted, so the two regions don't overlap.

local M = {}

local GROUP_MARKER = "MarkdownBlockquoteMarker"
local GROUP_TEXT   = "MarkdownBlockquoteText"
local PRIORITY     = 110

-- \v^\s*\>\s*        → the `>` plus optional leading/trailing whitespace
-- \v^\s*\>\s*\zs.*$  → everything after `> ` to end of line
local PAT_MARKER = [[\v^\s*\>\s*]]
local PAT_TEXT   = [[\v^\s*\>\s*\zs.*$]]

local BUF_VAR_MARKER = "markdown_bq_match_marker"
local BUF_VAR_TEXT   = "markdown_bq_match_text"

--- Derive a background color from the marker fg by dimming it toward black.
--- Used as the default text background when the user hasn't set one.
--- Returns a hex string.
---@param fg string  hex color, e.g. "#6A9955"
---@return string
local function dim_bg(fg)
  local r = tonumber(fg:sub(2, 3), 16) or 0x6A
  local g = tonumber(fg:sub(4, 5), 16) or 0x99
  local b = tonumber(fg:sub(6, 7), 16) or 0x55
  -- Mix ~20% of the fg color into black.
  return string.format("#%02x%02x%02x",
    math.floor(r * 0.20),
    math.floor(g * 0.20),
    math.floor(b * 0.20))
end

---@param hl Custom.MD.BlockquoteHL
local function set_hl(hl)
  local marker_fg = hl.marker_fg or hl.fg or "#6A9955"
  local text_bg   = hl.text_bg or dim_bg(marker_fg)

  if hl.link then
    vim.api.nvim_set_hl(0, GROUP_MARKER, { link = hl.link })
    vim.api.nvim_set_hl(0, GROUP_TEXT,   { link = hl.link })
    return
  end

  vim.api.nvim_set_hl(0, GROUP_MARKER, {
    fg     = marker_fg,
    bold   = hl.marker_bold   or false,
    italic = hl.marker_italic or false,
  })

  vim.api.nvim_set_hl(0, GROUP_TEXT, {
    -- fg intentionally omitted → inherits Normal fg (= normal text color)
    fg     = hl.text_fg   or nil,
    bg     = text_bg,
    italic = hl.text_italic or false,
    bold   = hl.text_bold   or false,
  })
end

---@param bufnr integer
local function add_match(bufnr)
  -- Clean up stale IDs from re-source or BufEnter.
  local prev_marker = vim.b[bufnr][BUF_VAR_MARKER]
  local prev_text   = vim.b[bufnr][BUF_VAR_TEXT]
  if prev_marker then pcall(vim.fn.matchdelete, prev_marker) end
  if prev_text   then pcall(vim.fn.matchdelete, prev_text)   end

  vim.b[bufnr][BUF_VAR_MARKER] = vim.fn.matchadd(GROUP_MARKER, PAT_MARKER, PRIORITY)
  vim.b[bufnr][BUF_VAR_TEXT]   = vim.fn.matchadd(GROUP_TEXT,   PAT_TEXT,   PRIORITY)
end

---@param opts table|nil  Full Custom.MD.Config (reads opts.blockquote_hl)
function M.apply(opts)
  opts = opts or {}
  local hl = opts.blockquote_hl or {}

  set_hl(hl)

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      local ft = vim.bo[bufnr].filetype
      if ft == "markdown" or ft == "markdown.mdx" or ft == "mdx" then
        local wins = vim.fn.win_findbuf(bufnr)
        if #wins > 0 then
          vim.api.nvim_win_call(wins[1], function()
            add_match(bufnr)
          end)
        end
      end
    end
  end
end

---@param augroup integer
function M.setup_autocmds(augroup)
  vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
    group   = augroup,
    pattern = { "markdown", "markdown.mdx", "mdx" },
    callback = function(ev)
      local bufnr = ev.buf
      local ft = vim.bo[bufnr].filetype
      if ft ~= "markdown" and ft ~= "markdown.mdx" and ft ~= "mdx" then
        return
      end
      add_match(bufnr)
    end,
  })
end

return M
