---@module 'wkdnvchad.ui.statusline.modules.file_icons.devicons'
--------------------------------------------------------------------------------
-- Paths & devicons
--------------------------------------------------------------------------------

local hl_module = require("wkdnvchad.ui.statusline.modules.highlighting")

local M = {}

---@nodiscard
---@param n integer|nil
---@return string|nil
local function int_to_hex(n)
  if type(n) ~= "number" then
    return nil
  end
  return string.format("#%06x", n)
end

---@nodiscard
---@return string|nil
local function mode_band_bg_hex()
  local group =hl_module.mode_band_group()
  local hl = vim.api.nvim_get_hl(0, { name = group, link = false }) or {}
  ---@diagnostic disable-next-line undefined-field
  return int_to_hex(hl.bg)
end

---@nodiscard
---@param fg string|nil
---@param band_bg string|nil
---@return string
local function ensure_icon_hl(fg, band_bg)
  ---@type WkdNvC.UI.Stl.Modules.Custom.FileIcon.HLCache
  M.__icon_hl = M.__icon_hl or { name = "St_FileIcon", fg = nil, bg = nil }
  if M.__icon_hl.fg ~= fg or M.__icon_hl.bg ~= band_bg then
    vim.api.nvim_set_hl(0, M.__icon_hl.name, { fg = fg, bg = band_bg })
    M.__icon_hl.fg = fg
    M.__icon_hl.bg = band_bg
  end
  return M.__icon_hl.name
end

---@nodiscard
---@param path string
---@return string icon, string|nil color
local function devicon_for_path(path)
  local ok, devicons = pcall(require, "nvim-web-devicons")
  local filename = (path == "" or path == nil) and "[No Name]" or vim.fn.fnamemodify(path, ":t")
  local ext = filename:match("^.+%.(.+)$") or ""
  if not ok then
    return "󰈙", nil
  end
  local icon, color
  local ok_color = pcall(function()
    icon, color = devicons.get_icon_color(filename, ext, { default = true })
  end)
  if not ok_color or not icon then
    icon = devicons.get_icon(filename, ext, { default = true })
    if devicons.get_color then
      pcall(function()
        color = devicons.get_color(filename, ext, { default = true })
      end)
    end
  end
  if not icon or icon == "" then
    icon = "󰈙"
  end
  return icon, color
end

---@nodiscard
---@return string
function M.file_icon_segment()
  local utils = require("nvchad.stl.utils")
  local bufnr = utils.stbufnr()
  local path = vim.api.nvim_buf_get_name(bufnr) or ""
  local icon, fg = devicon_for_path(path)
  local bg = mode_band_bg_hex()
  local group = ensure_icon_hl(fg, bg)
  return "%#" .. group .. "#" .. icon .. "%*"
end

---@nodiscard
---@param band_group string
---@return string
function M.file_icon_segment_inherit(band_group)
  local utils = require("nvchad.stl.utils")
  local bufnr = utils.stbufnr()
  local path = vim.api.nvim_buf_get_name(bufnr) or ""
  local icon, fg = devicon_for_path(path)
  local bg = mode_band_bg_hex()
  local group = ensure_icon_hl(fg, bg)
  return "%#" .. group .. "#" .. icon .. "%#" .. band_group .. "#"
end

return M
