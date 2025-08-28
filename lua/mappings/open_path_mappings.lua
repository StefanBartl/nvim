require("utils.open_path").setup({
  require_existing = true,      -- invalid path => immediate return
  notify = false,               -- warnings
  split = "vertical",           -- default for window target
  set_default_keymaps = false,  -- keep existing mappings
})

vim.keymap.set("n", "gtb", function() require("utils.open_path").open_in_buffer() end,
  { desc = "Open under cursor (buffer)" })

vim.keymap.set("n", "gtw", function() require("utils.open_path").open_in_window() end,
  { desc = "Open under cursor (split vertical)" })

vim.keymap.set("n", "gth", function() require("utils.open_path").open_in_window("horizontal") end,
  { desc = "Open under cursor (split horizontal)" })

vim.keymap.set("n", "gtt", function() require("utils.open_path").open_in_tab() end,
  { desc = "Open under cursor (new tab)" })

vim.keymap.set("n", "gtm", function() require("utils.open_path").open_in_filemanager() end,
  { desc = "Reveal/open in system file manager" })

vim.keymap.set("n", "gtW", function()
  require("utils.open_path").open_in_window_max()
end, { desc = "Open under cursor (split + maximize) - non-destructive" })

vim.keymap.set("n", "gtf", function()
   require("utils.open_path").open_in_window_only()
end, { desc = "Open under cursor (split + only) - destructive" })
