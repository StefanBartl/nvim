---@module 'config.neotree.keymaps.tests'
--- Keymaps für Neo-tree Tests Source
-- AUDIT: Wird nicht verwendet derzeit!


---@type table<string, string|table>
local M = {
  -- Standard Neo-tree Navigation (überschreiben)
  ["<cr>"] = "open",
  ["<esc>"] = "cancel",
  ["<2-LeftMouse>"] = "open",

  -- Neotest-spezifisch
  ["t"] = "run_test",           -- Test unter Cursor ausführen
  ["T"] = "run_file",           -- Alle Tests in Datei
  ["d"] = "debug_test",         -- Debug einzelner Test
  ["w"] = "watch_test",         -- Watch-Mode
  ["s"] = "stop_test",          -- Tests stoppen
  ["o"] = "show_output",        -- Output anzeigen
  ["r"] = "refresh",            -- Tests neu laden

  -- Navigation
  ["q"] = "close_window",
  ["?"] = "show_help",
}

return M
