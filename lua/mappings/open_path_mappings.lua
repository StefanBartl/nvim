require("utils.open_path").setup({
  require_existing = true,      -- invalid path => immediate return
  notify = false,               -- warnings
  split = "vertical",           -- default for window target
  set_default_keymaps = false,  -- keep existing mappings
})


vim.keymap.set("n", "Gpb", function() require("utils.open_path").open_in_buffer() end,
  { desc = "[OpenPath] Open under cursor (buffer)" })

vim.keymap.set("n", "Gpv", function() require("utils.open_path").open_in_window() end,
  { desc = "[OpenPath] Open under cursor (split vertical)" })

vim.keymap.set("n", "Gph", function() require("utils.open_path").open_in_window("horizontal") end,
  { desc = "[OpenPath] Open under cursor (split horizontal)" })

vim.keymap.set("n", "Gpt", function() require("utils.open_path").open_in_tab() end,
  { desc = "[OpenPath] Open under cursor (new tab)" })

vim.keymap.set("n", "Gpf", function() require("utils.open_path").open_in_filemanager() end,
  { desc = "[OpenPath] Reveal/open in system file manager" })

vim.keymap.set("n", "Gpd", function()
  require("utils.open_path").open_in_window_max()
end, { desc = "[OpenPath] Open under cursor (split + maximize) - non-destructive" })

vim.keymap.set("n", "GpD", function()
   require("utils.open_path").open_in_window_only()
end, { desc = "[OpenPath] Open under cursor (split + only) - destructive" })
