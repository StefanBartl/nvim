---@module 'custom.markdown'
--- Public entry: wires config + UI; re-exports core API. Pure cores; side effects only here.

local M = {}

require("custom.markdown.anchor.jump")
-- AUDIT:
require("custom.markdown.fenced_fix").setup({
  -- Falls „noch oranger“ gewünscht ist, Reihenfolge hier anpassen oder direkt "Special" wählen.
  inline_base_hl = { "DiagnosticWarn", "Special", "Constant", "String" },
  inline_style = { italic = false, bold = false },
  delimiter_hl = "Comment",
}).apply()


-- AUDIT:
require("custom.markdown.tableview").setup({
  prefer_browser = false,
  auto_on_cursor = false,
  float_width = 0.6,
  float_height = 0.35,
})

local cfg = require("custom.markdown.config")
local fold = require("custom.markdown.core.fold")
local head = require("custom.markdown.core.headings")
local wrap = require("custom.markdown.core.wrap")
local autocmd = require("custom.markdown.setup.autocmd")

---@param opts MarkdownConfig|nil
---@return nil
function M.setup(opts)
  cfg.setup(opts or {})
  autocmd.setup()
end


M.foldexpr = fold.foldexpr
M.goto_prev_heading = head.goto_prev_heading
M.goto_next_heading = head.goto_next_heading
M.shift_increase = head.increase
M.shift_decrease = head.decrease
M.toggle_visual_bold = wrap.toggle_visual_bold

---@type MarkdownPublicAPI
return M

