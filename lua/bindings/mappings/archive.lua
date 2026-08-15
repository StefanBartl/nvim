---@module 'bindings.mappings.archive'
local map = {} -- dummy table for lsp

--------------------------
--- General Mappings
--------------------------

-- Improved wrapped-line movement with auto-centering
-- After movement, center the cursor (zz) for better visibility
-- If no count is given: move by screen line (gj/gk)
-- If a count is given: move by physical line (j/k)
map(
  { "n", "x" },
  "j",
  "v:count == 0 ? 'gjzz' : 'jzz'",
  { desc = "Down (smart: wrapped-line aware, centers after move)", expr = true, silent = true }
)

map(
  { "n", "x" },
  "<Down>",
  "v:count == 0 ? 'gjzz' : 'jzz'",
  { desc = "Down (smart: wrapped-line aware, centers after move)", expr = true, silent = true }
)

map(
  { "n", "x" },
  "k",
  "v:count == 0 ? 'gkzz' : 'kzz'",
  { desc = "Up (smart: wrapped-line aware, centers after move)", expr = true, silent = true }
)

map(
  { "n", "x" },
  "<Up>",
  "v:count == 0 ? 'gkzz' : 'kzz'",
  { desc = "Up (smart: wrapped-line aware, centers after move)", expr = true, silent = true }
)

--------------------------

