---@module 'config.neotest.init.icons'
---@brief Icon factory for neotest
---@description
--- Dieses Modul stellt eine aufrufbare Factory-Funktion bereit, die
--- unterschiedliche Icon-Sets für Neotest zurückliefert.
---
--- Verwendung:
---   icons = require("config.neotest.init.icons")("devicons")
---   icons = require("config.neotest.init.icons")("nerdfonts")
---   icons = require("config.neotest.init.icons")("default")
---   icons = require("config.neotest.init.icons")("alt")

---@alias NeotestIconVariant
---| "default"
---| "nerdfonts"
---| "devicons"
---| "alt"

----------------------------------------------------------------------
-- Icon-Sets
----------------------------------------------------------------------

---@type table<string, string>
local ICONS_DEFAULT = {
  passed = "✓",
  running = "●",
  failed = "✗",
  skipped = "○",
  unknown = "?",
  watching = "o",
}

---@type table<string, string>
local ICONS_NERDFONTS = {
  passed = "", -- nf-fa-check_circle
  running = "", -- nf-fa-spinner
  failed = "", -- nf-fa-times_circle
  skipped = "", -- nf-fa-circle_o
  unknown = "", -- nf-fa-question_circle
  watching = "󰛐", -- nf-md-eye_outline
}

---@type table<string, string>
local ICONS_ALT = {
  passed = "+",
  running = "~",
  failed = "x",
  skipped = "-",
  unknown = "?",
  watching = "*",
}

----------------------------------------------------------------------
-- Devicons-basierte Variante
----------------------------------------------------------------------

--- Baut ein Icon-Set unter Verwendung von nvim-web-devicons als Glyph-Quelle.
--- Devicons werden hier ausschließlich als Glyph-Registry genutzt.
---@return table<string, string>
local function build_devicons()
  local ok, devicons = pcall(require, "nvim-web-devicons")
  if not ok then
    return ICONS_NERDFONTS
  end

  return {
    passed = devicons.get_icon("ok") or ICONS_NERDFONTS.passed,
    running = devicons.get_icon("load") or ICONS_NERDFONTS.running,
    failed = devicons.get_icon("error") or ICONS_NERDFONTS.failed,
    skipped = devicons.get_icon("circle") or ICONS_NERDFONTS.skipped,
    unknown = devicons.get_icon("help") or ICONS_NERDFONTS.unknown,
    watching = ICONS_NERDFONTS.watching,
  }
end

----------------------------------------------------------------------
-- Factory
----------------------------------------------------------------------

--- Liefert ein Neotest-Icon-Set basierend auf der gewünschten Variante.
---@param variant NeotestIconVariant|nil
---@return table<string, string>
local function icons_factory(variant)
  if variant == "devicons" then
    return build_devicons()
  end

  if variant == "nerdfonts" then
    return ICONS_NERDFONTS
  end

  if variant == "alt" then
    return ICONS_ALT
  end

  return ICONS_DEFAULT
end

return icons_factory
