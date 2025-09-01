require("utils.open_path").setup({
  require_existing = true,      -- invalid path => immediate return
  notify = false,               -- warnings
  split = "vertical",           -- default for window target
  set_default_keymaps = false,  -- keep existing mappings
})

vim.keymap.set("n", "opb", function() require("utils.open_path").open_in_buffer() end,
  { desc = "Open under cursor (buffer)" })

vim.keymap.set("n", "opv", function() require("utils.open_path").open_in_window() end,
  { desc = "Open under cursor (split vertical)" })

vim.keymap.set("n", "oph", function() require("utils.open_path").open_in_window("horizontal") end,
  { desc = "Open under cursor (split horizontal)" })

vim.keymap.set("n", "opt", function() require("utils.open_path").open_in_tab() end,
  { desc = "Open under cursor (new tab)" })

vim.keymap.set("n", "opf", function() require("utils.open_path").open_in_filemanager() end,
  { desc = "Reveal/open in system file manager" })

vim.keymap.set("n", "opd", function()
  require("utils.open_path").open_in_window_max()
end, { desc = "Open under cursor (split + maximize) - non-destructive" })

vim.keymap.set("n", "opD", function()
   require("utils.open_path").open_in_window_only()
end, { desc = "Open under cursor (split + only) - destructive" })
