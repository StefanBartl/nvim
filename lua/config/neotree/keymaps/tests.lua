---@module 'config.neotree.keymaps.tests'
--- Neotest-Source-specific mappings for Neo-tree

---@return table<string, any>
return {

  --====================== Test Execution ==============================

  ["<CR>"]   = "run_test",
  ["<S-CR>"] = "debug_test",

  --====================== Output =====================================

  ["O"] = "short_output",
  ["o"] = "output",

  --====================== Control ====================================

  ["s"] = "stop_test",
  ["w"] = "watch_test",

  --====================== Disable ALL filesystem operations ==========

  -- single-character symbols
  ["+"] = "noop",
  ["-"] = "noop",
  ["/"] = "noop",

  -- single-character letters
  ["a"] = "noop",
  ["c"] = "noop",
  ["d"] = "noop",
  ["m"] = "noop",
  ["p"] = "noop",
  ["r"] = "noop",
  ["x"] = "noop",

  -- single-character uppercase letters
  ["A"] = "noop",
  ["D"] = "noop",
  ["I"] = "noop",
  ["M"] = "noop",
  ["U"] = "noop",
  ["Y"] = "noop",

  -- multi-character plain tokens
  ["dd"] = "noop",
  ["fm"] = "noop",
  ["gb"] = "noop",
  ["gr"] = "noop",
  ["rq"] = "noop",
  ["sm"] = "noop",
  ["st"] = "noop",
  ["sv"] = "noop",

  -- control / modifier keys (grouped by base key)
  ["<C-c>"] = "noop",
  ["<C-b>"] = "noop",
  ["<C-f>"] = "noop",
  ["<C-s>"] = "noop",

  ["<M-s>"] = "noop",

  ["<Tab>"] = "noop",

  -- leader keys
  ["<leader>mc"] = "noop",
  ["<leader>th"] = "noop",

  -- named special keys
  ["<PageDown>"] = "noop",
  ["<PageUp>"]   = "noop",
}
