---@module 'wkdnvchad.ui.statusline.modules.file_icons.devicons'
--------------------------------------------------------------------------------
-- Paths & devicons
--------------------------------------------------------------------------------

---@type WkdNvC.UI.Stl.Modules.Highlighting
local hl_module = require("lib.lazy").require("wkdnvchad.ui.statusline.modules.highlighting")

local M = {}

local api = vim.api
-- Caches
local icon_cache = require("lib.memo.lru").new(256)
local hl_cache = { name = "St_FileIcon", fg = nil, bg = nil }

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
  local group = hl_module.mode_band_group()
  local ok, hl = pcall(api.nvim_get_hl, 0, { name = group, link = false })
  if not ok or not hl then
    return nil
  end
  return int_to_hex(hl.bg)
end


---@nodiscard
---@param fg string|nil
---@param band_bg string|nil
---@return string
local function ensure_icon_hl(fg, band_bg)
  if hl_cache.fg ~= fg or hl_cache.bg ~= band_bg then
    local ok = pcall(api.nvim_set_hl, 0, hl_cache.name, { fg = fg, bg = band_bg })
    if ok then
      hl_cache.fg = fg
      hl_cache.bg = band_bg
    end
  end
  return hl_cache.name
end

---@nodiscard
---@param path string
---@return string icon, string|nil color
local function devicon_for_path(path)
  local cache_key = path
  local cached = icon_cache:get(cache_key)
  if cached then
    return cached.icon, cached.color
  end

  local filename = (path == "" or path == nil) and "[No Name]" or vim.fn.fnamemodify(path, ":t")
  local ext = filename:match("^.+%.(.+)$") or ""

  local ok_devicons, devicons = pcall(require, "nvim-web-devicons")
  if not ok_devicons then
    local result = { icon = "󰈙", color = nil }
    icon_cache:put(cache_key, result)
    return result.icon, result.color
  end

  local icon, color
  local ok_get = pcall(function()
    icon, color = devicons.get_icon_color(filename, ext, { default = true })
  end)

  if not ok_get or not icon then
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

  local result = { icon = icon, color = color }
  icon_cache:put(cache_key, result)
  return icon, color
end

---@nodiscard
---@return string
function M.file_icon_segment()
  local ok_utils, utils = pcall(require, "nvchad.stl.utils")
  if not ok_utils then
    return ""
  end

  local bufnr = utils.stbufnr()
  local ok_name, path = pcall(api.nvim_buf_get_name, bufnr)
  path = ok_name and path or ""

  local icon, fg = devicon_for_path(path)
  local bg = mode_band_bg_hex()
  local group = ensure_icon_hl(fg, bg)

  return "%#" .. group .. "#" .. icon .. "%*"
end

---@nodiscard
---@param band_group string
---@return string
function M.file_icon_segment_inherit(band_group)
  local ok_utils, utils = pcall(require, "nvchad.stl.utils")
  if not ok_utils then
    return ""
  end

  local bufnr = utils.stbufnr()
  local ok_name, path = pcall(api.nvim_buf_get_name, bufnr)
  path = ok_name and path or ""

  local icon, fg = devicon_for_path(path)
  local bg = mode_band_bg_hex()
  local group = ensure_icon_hl(fg, bg)

  return "%#" .. group .. "#" .. icon .. "%#" .. band_group .. "#"
end

---@nodiscard
---@return string
function M.file_icon_segment_lsp()
  -- Defensive require, da das Modul auch ohne NvChad-utils
  -- geladen werden können soll (z. B. in isolierten Tests).
  local ok_utils, utils = pcall(require, "nvchad.stl.utils")
  if not ok_utils then
    return ""
  end

  local bufnr = utils.stbufnr()

  -- Prüfen, ob mindestens ein LSP-Client an den Buffer gebunden ist.
  -- Ohne LSP-Kontext wird bewusst kein Icon gerendert.
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  if not clients or vim.tbl_isempty(clients) then
    return ""
  end

  -- Buffer-Namen sicher ermitteln.
  local ok_name, path = pcall(api.nvim_buf_get_name, bufnr)
  path = ok_name and path or ""
  if path == "" then
    return ""
  end

  -- Devicon und Vordergrundfarbe anhand des Pfads bestimmen.
  -- Diese Hilfsfunktionen werden aus dem bestehenden
  -- Devicon-Modul erwartet.
  local icon, fg = devicon_for_path(path)
  if not icon or icon == "" then
    return ""
  end

  -- Hintergrundfarbe an das aktuelle Mode-Band anpassen,
  -- damit das Icon visuell konsistent mit der LSP/Breadcrumb-
  -- Darstellung bleibt.
  local bg = mode_band_bg_hex()
  local group = ensure_icon_hl(fg, bg)

  -- Vollständig gewrapptes Statusline-Segment zurückgeben.
  return "%#" .. group .. "#" .. icon .. "%*"
end

return M
