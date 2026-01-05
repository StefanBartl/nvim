---@module 'custom.markdown'
--- Public entry: wires config + UI; re-exports core API. Pure cores; side effects only here.

local M = {}

local cfg = require("custom.markdown.config")
local fold = require("custom.markdown.core.fold")
local head = require("custom.markdown.core.headings")
local wrap = require("custom.markdown.core.wrap")
local autocmds = require("custom.markdown.setup.autocmds")
local tableview = require("custom.markdown.tableview")
local tableview_live = require("custom.markdown.tableview.live")

---@param opts Custom.MD.Config|nil
---@return nil
function M.setup(opts)
  cfg.setup(opts or {})
  autocmds.setup()
  tableview.setup()
  tableview_live.setup_autocmds()
end

M.foldexpr = fold.foldexpr
M.goto_prev_heading = head.goto_prev_heading
M.goto_next_heading = head.goto_next_heading
M.toggle_visual_bold = wrap.toggle_visual_bold

---@diagnostic disable-next-line
require("custom.markdown.fenced_fix")
  .setup({
    -- Falls „noch oranger“ gewünscht ist, Reihenfolge hier anpassen oder direkt "Special" wählen.
    inline_base_hl = { "DiagnosticWarn", "Special", "Constant", "String" },
    inline_style = { italic = false, bold = false },
    delimiter_hl = "Comment",
  })
  .apply()

---@type Custom.MD.PublicAPI
return M
