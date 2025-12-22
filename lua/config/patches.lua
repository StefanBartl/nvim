local monkeypatch = require("monkeypatch")

-- Method 1: Classic Diff Patch
monkeypatch.register({
  key = "gitsigns-system-compat",
  repo = "gitsigns.nvim",
  strategy = "diff",
  enabled = true,
  priority = 100,
  strip = 0,
  patch = vim.fn.stdpath("config") .. "/patches/gitsigns/system_compat.patch",
  target = vim.fn.stdpath("data") .. "/lazy/gitsigns.nvim/lua/gitsigns/system/compat.lua",
})

-- Method 2: Semantic Function Replacement
-- monkeypatch.register({
--   key = "noice-signature-fix",
--   repo = "noice.nvim",
--   strategy = "semantic",
--   enabled = true,
--   priority = 90,
--   target = vim.fn.stdpath("data") .. "/lazy/noice.nvim/lua/noice/lsp/signature.lua",
--   function_name = "on_signature",
--   expected_hash = "9c1f4e3d8a7b2c5f",  -- SHA256 of normalized function body
--   replacement = function()
--     return [[
-- local function on_signature(err, result, ctx, config)
--   -- Your fixed implementation
--   if not result or not result.signatures then
--     return
--   end
--   -- ... rest of function
-- end
-- ]]
--   end,
-- })

-- Method 3: Tree-sitter (Optional)
-- monkeypatch.register({
--   key = "telescope-picker-fix",
--   repo = "telescope.nvim",
--   strategy = "treesitter",
--   enabled = true,
--   priority = 80,
--   target = vim.fn.stdpath("data") .. "/lazy/telescope.nvim/lua/telescope/pickers.lua",
--   query = [[
--     (function_definition
--       name: (identifier) @name
--       (#eq? @name "new"))
--   ]],
--   replacement = function(node)
--     return "function M.new(...)\n  -- Fixed implementation\nend"
--   end,
-- })
