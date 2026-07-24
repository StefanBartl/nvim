---@module 'wkdoptions.hl_config.breadcrumbs.statusline'
---@brief Public API for statusline integration
---
--- Provides ready-to-use functions for NvChad/Lualine-style statuslines.
--- Separated from ctx logic for clean public interface.

local lazy = require("lib.lua.lazy")
local trim = lazy.require("lib.lua.strings.core").trim

-- Lazy-load context builder
local ctx = lazy.require("wkdoptions.hl_config.breadcrumbs.ctx")

local M = {}

-----------------------------------------------------------
-- Utility Functions
-----------------------------------------------------------

--- Escape `%` for statusline rendering
---@nodiscard
---@param s string
---@return string
local function stl_escape(s)
  return (tostring(s or ""):gsub("%%", "%%%%"))
end

--- Ellipsize in the middle (ASCII-oriented)
---@nodiscard
---@param s string
---@param max integer
---@return string
local function ellipsize_middle(s, max)
  if #s <= max then
    return s
  end

  local head = math.floor((max - 1) / 2)
  local tail = max - head - 1
  return string.sub(s, 1, head) .. "…" .. string.sub(s, #s - tail + 1, #s)
end

--- Ellipsize at the end
---@nodiscard
---@param s string
---@param max integer
---@return string
local function ellipsize_end(s, max)
  if #s <= max then
    return s
  end
  return string.sub(s, 1, max - 1) .. "…"
end

--- Default project-relative path resolver
---@nodiscard
---@param abs string
---@return string
local function default_repo_relative(abs)
  if abs == "" then
    return "[No Name]"
  end

  -- Use path_cache if available for performance
  local ok, path_cache = pcall(require, "wkdoptions.hl_config.path_cache")
  if ok and type(path_cache.repo_relative_cached) == "function" then
    return path_cache.repo_relative_cached(abs, 0)
  end

  -- Fallback: vim.fn
  return vim.fn.fnamemodify(abs, ":~:.")
end

-----------------------------------------------------------
-- Simple Segment Builder
-----------------------------------------------------------

--- Build a plain statusline segment (no HL escapes)
--- Format: [path][SEP][context]
---@nodiscard
---@param opts WKDOptions.HL_CFG.Breadcrumbs.StlOptions|nil
---@return string
function M.statusline_segment(opts)
  opts = opts or {}

  local include_path = opts.include_path
  if include_path == nil then
    include_path = true
  end

  local sep = (opts.sep ~= nil and opts.sep ~= "") and opts.sep or " › "
  local ellipsis = opts.ellipsis or "middle"

  -- 1) Resolve buffer path and context
  local bufnr = vim.api.nvim_get_current_buf()
  local abs = vim.api.nvim_buf_get_name(bufnr) or ""

  -- Build context
  local context = ""
  local ok, result = pcall(ctx._build_context)
  if ok and result and result ~= "" then
    context = result
  end

  -- 2) Optionally compute project-relative path
  local rel = ""
  if include_path then
    local rel_fn = type(opts.path_resolver) == "function"
      and opts.path_resolver
      or default_repo_relative
    rel = tostring(rel_fn(abs) or "")
  end

  -- 3) Compose: avoid dangling separators
  local parts = {}

  if include_path and rel ~= "" then
    parts[#parts + 1] = rel
    if context ~= "" then
      parts[#parts + 1] = sep
    end
  end

  if context ~= "" then
    parts[#parts + 1] = context
  end

  local line = table.concat(parts, "")

  -- 4) Ellipsize (window-aware default)
  local default_max = math.max(30, math.floor(vim.o.columns * 0.5))
  local maxw = tonumber(opts.max_width or default_max) or default_max

  if maxw > 0 and #line > maxw then
    line = (ellipsis == "end")
      and ellipsize_end(line, maxw)
      or ellipsize_middle(line, maxw)
  end

  -- 5) Escape `%` and trim
  line = stl_escape(trim(line))

  return line
end

-----------------------------------------------------------
-- Statusline Module Factory
-----------------------------------------------------------

--- Create a closure for NvChad/Lualine statusline modules
--- Optionally adds icon and mode-band HL wrapping
---@nodiscard
---@param opts WKDOptions.HL_CFG.Breadcrumbs.StlOptions|nil
---@return fun():string
function M.statusline_module(opts)
  opts = opts or {}

  local want_icon = (opts.include_icon ~= false)
  local want_band = (opts.band_highlight ~= false)

  return function()
    -- Build plain segment
    local seg = M.statusline_segment(opts)
    if seg == "" then
      return ""
    end

    -- Try to use UI helper for icon + band HL
    local ok, utl = pcall(require, "ui.custom_stl_module")
    if not ok then
      return seg
    end

    local out = seg

    -- Optional: prepend icon
    if want_icon and type(utl.file_icon_segment) == "function" then
      local icon = utl.file_icon_segment()
      if icon and icon ~= "" then
        out = icon .. " " .. out
      end
    end

    -- Optional: wrap with mode-band HL
    if want_band
      and type(utl.mode_band_group) == "function"
      and type(utl.hl_open) == "function" then
      out = utl.hl_open(utl.mode_band_group()) .. out
    end

    return out
  end
end

return M
