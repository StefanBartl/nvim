---@module 'config.menu.icons'
--- The glyphs the right-click menu draws in its icon column.
---
--- One table, resolved once, shared by every section (`custom_menu`, `git`,
--- and the contributor fallbacks in `mappings`) — because the column is
--- measured across the whole menu, so a glyph that renders two cells wide in
--- one section shifts the labels in all of them. Keeping the set in one place
--- is what makes that a single decision rather than a scattered one.
---
--- Every glyph goes through `lib.nvim.ui.nerd_font.glyph(hex, fallback)`,
--- which is a *declaration*, not a detection: Neovim cannot see the terminal
--- font, so the module returns the fallback unless `vim.g.have_nerd_font` is
--- set (init.lua does). It also refuses any glyph that measures wider than
--- one cell — the exact failure that made the old `🗑️ Delete File` emoji sit
--- a column off from its neighbours.
---
--- The fallbacks are deliberately ASCII and deliberately dull. They exist so
--- the menu stays *aligned* without a patched font, not so it stays pretty:
--- one cell each, and never a character that reads as part of the label.

local nerd = require("lib.nvim.ui.nerd_font")

--- Resolve one glyph, or its fallback.
---@param hex string       # Nerd Font codepoint, e.g. "F0AD"
---@param fallback string  # one-cell ASCII stand-in
---@return string
local function g(hex, fallback)
  return nerd.glyph(hex, fallback)
end

---@class Config.Menu.Icons
local M = {
  -- General section ---------------------------------------------------------
  format = g("F0AD", "~"), -- wrench
  code_action = g("F0EB", "*"), -- lightbulb
  inspect = g("F0349", "?"), -- magnify
  copy_all = g("F0C5", "c"), -- files
  copy_marked = g("F018F", "c"), -- content-copy
  paste = g("F0192", "v"), -- content-paste
  delete_marked = g("F0190", "x"), -- content-cut
  delete_all = g("F12D", "x"), -- eraser
  delete_file = g("F1F8", "x"), -- trash
  terminal = g("F120", ">"), -- terminal
  color_picker = g("F03D8", "#"), -- palette
  unicode_table = g("F031", "U"), -- font
  git = g("F02A2", "G"), -- source-branch

  -- Git subsection ----------------------------------------------------------
  git_stage = g("F067", "+"), -- plus
  git_reset = g("F0E2", "-"), -- undo
  git_stage_buffer = g("F0FE", "+"), -- plus-square
  git_reset_buffer = g("F021", "-"), -- refresh
  git_preview = g("F06E", "o"), -- eye
  git_blame = g("F007", "b"), -- user
  git_toggle = g("F205", "t"), -- toggle-on
  git_diff = g("F0EC", "d"), -- exchange
  git_history = g("F1DA", "h"), -- history

  -- Contributor fallbacks (see `config.menu.mappings`) -----------------------
  --
  -- A fallback, not an assignment: a Pattern-B plugin that names its own
  -- `icon` keeps it. These exist so a contributor that has not adopted the
  -- icon column yet still lands in it rather than leaving a hole in the
  -- column its neighbours fill.
  plugin = g("F1B2", "p"), -- cube: any contributor without an icon of its own
  markdown = g("F02D", "M"), -- book
  open = g("F0C1", "L"), -- chain
  dap = g("F188", "D"), -- bug
  cascade = g("F0E8", "C"), -- sitemap
  fileops = g("F15B", "F"), -- file
  images = g("F03E", "I"), -- picture
  spotlight = g("F002", "S"), -- search
  color_my_ascii = g("F1FC", "A"), -- paint-brush
  lsp = g("F0E7", "L"), -- bolt
}

return M
