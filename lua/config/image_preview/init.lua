---@module 'config.image_preview'

require("config.image_preview.pdf.buffer").setup({
  open_mode = "vsplit",
  focus = false,          -- keep focus in Neo-tree/editor
  density = 144,          -- 72..600
  notify = true,
  clear_on_leave = true,
  bg_hex = "#ffffff",
  cleanup_png = false,    -- set to true to delete PNG on close
})

