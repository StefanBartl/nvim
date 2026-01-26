---@module 'markdown.fenced_fix'
--- Neutralize blanket fenced-code coloring so injections can shine through,
--- while giving inline code spans (backticks) a distinct, theme-friendly style.
--- Works with both legacy regex groups and modern Tree-sitter captures.
--- Re-applies safely on ColorScheme changes.

---@class UIMarkdownFencedFix
---@field opts Custom.MD.FencedFix.Opts

local notify = require("lib.notify").create("[custom.markdown.fenced_fix]")

local M = {}

-- Defaults aim for "orange-ish" via DiagnosticWarn, with robust fallbacks.
M.opts = {
  inline_base_hl = { "DiagnosticWarn", "Special", "Constant", "String" },
  inline_style = { bold = false, italic = false },
  delimiter_hl = "Comment",
  enable_legacy = true,
  enable_ts = true,
}

-- Small helpers --------------------------------------------------------------

---@param name string
---@param target string|table
local function safe_set(name, target)
  -- `target` may be a link name (string) or an attr table.
  local ok, err = pcall(function()
    if type(target) == "string" then
      vim.api.nvim_set_hl(0, name, { link = target })
    else
      vim.api.nvim_set_hl(0, name, target or {})
    end
  end)
  if not ok then
    vim.schedule(function()
      notify.debug(("markdown.fenced_fix: failed to set %s: %s"):format(name, err))
    end)
  end
end

---@param name string
local function safe_clear(name)
  -- Empty opts table clears explicit fg/bg/style while keeping default resolution.
  pcall(vim.api.nvim_set_hl, 0, name, {})
end

---@param names string[]
---@param target string|table
local function set_many(names, target)
  for _, n in ipairs(names) do
    safe_set(n, target)
  end
end

---@param name string
---@return table? hl
local function get_hl(name)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = true })
  if ok and type(hl) == "table" then
    return hl
  end
  return nil
end

---@param candidates string[]
---@return string? first
local function first_existing_hl(candidates)
  for _, n in ipairs(candidates) do
    if get_hl(n) then
      return n
    end
  end
  return nil
end

-- Public API -----------------------------------------------------------------

--- Apply highlight fixes with current options.
---@return nil
function M.apply()
  local o = M.opts

  if o.enable_legacy then
    -- Builtin 'syntax/markdown.vim' groups (regex-based)
    safe_clear("markdownCode") -- avoid blanket single-color blocks
    safe_set("markdownCodeDelimiter", o.delimiter_hl) -- subtle backticks in legacy mode
  end

  if o.enable_ts then
    -- Do NOT force raw to Normal; clear it so more specific inline/block links can win.
    safe_clear("@markup.raw")

    -- Fenced blocks: keep neutral to let injected languages colorize themselves.
    set_many({
      "@markup.raw.block",
      "@markup.fenced_code.block",
    }, "Normal")

    local base = first_existing_hl(o.inline_base_hl) or "Special"

    -- Try to fetch the concrete fg/bg of the base. If available, create an explicit
    -- hl table so we can add style flags (bold/italic). If not available, fall back
    -- to a simple link so the theme controls color.
    local style = o.inline_style or {}
    local base_hl = get_hl(base) or {}

    if (base_hl.fg or base_hl.bg) and next(style) ~= nil then
      -- base has concrete color info: create an explicit hl preserving colors + styles
      safe_set("MarkdownInlineCode", {
        fg = base_hl.fg,
        bg = base_hl.bg,
        bold = style.bold,
        italic = style.italic,
        underline = style.underline,
        undercurl = style.undercurl,
      })
    else
      -- either no concrete colors from base, or no style requested:
      -- keep a link so theme colors continue to apply (safer).
      safe_set("MarkdownInlineCode", base)
    end

    -- Modern captures for inline code content across markdown + markdown_inline
    set_many({
      "@markup.raw.inline",
      "@markup.raw.inline.markdown_inline",
      -- Compatibility with older Treesitter query names (Neovim 0.8/0.9 era)
      "@text.literal",
      "@text.literal.markdown_inline",
    }, "MarkdownInlineCode")

    -- Delimiters (the backticks) should be subtle
    set_many({
      "@markup.raw.delimiter",
      "@markup.raw.delimiter.markdown_inline",
      "@punctuation.delimiter.markdown",
      "@punctuation.delimiter.markdown_inline",
      -- Some themes reuse 'markdownCodeDelimiter' even with TS
      "markdownCodeDelimiter",
    }, o.delimiter_hl)
  end
end

--- Configure options (call once before .apply()).
---@param opts Custom.MD.FencedFix.Opts
---@return UIMarkdownFencedFix
function M.setup(opts)
  if type(opts) == "table" then
    for k, v in pairs(opts) do
      M.opts[k] = v
    end
  end
  pcall(M.apply) -- apply immediately
  return M
end

-- Auto re-apply on ColorScheme so themes cannot override our intent.
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("MarkdownFencedFix", { clear = true }),
  callback = function()
    pcall(M.apply)
  end,
  desc = "Re-apply fenced fix and inline code styling after colorscheme changes",
})

return M

-- AUDIT:

-- ---@module 'markdown.fenced_fix'
-- -- Neutralize blanket color links on fenced code so injections can shine through.
--
-- ---@class UIMarkdownFencedFix
-- local M = {}
--
-- local function safe_link(name, target)
--   pcall(vim.api.nvim_set_hl, 0, name, { link = target })
-- end
--
-- local function safe_clear(name)
--   -- Empty opts table clears explicit fg/bg/style while keeping default link resolution.
--   pcall(vim.api.nvim_set_hl, 0, name, {})
-- end
--
-- function M.apply()
--   -- Legacy regex groups (used by builtin 'syntax/markdown.vim' or some themes)
--   safe_clear("markdownCode")                 -- remove enforced single-color
--   safe_link("markdownCodeDelimiter", "Comment")
--
--   -- Tree-sitter markup groups (Neovim ≥0.9)
--   -- Some colorschemes color the entire fenced area via these captures.
--   -- Relink them to Normal to allow injected language tokens to define their own colors.
--   safe_link("@markup.raw", "Normal")
--   safe_link("@markup.raw.markdown_inline", "Normal")
--   safe_link("@markup.raw.block", "Normal")
--   safe_link("@markup.fenced_code.block", "Normal")
--
--   -- Optional: make inline code (`\``) distinct but not overpowering
--   safe_link("@markup.raw.inline", "String")  -- tiny hint for `inline code`
-- end
--
-- return M
