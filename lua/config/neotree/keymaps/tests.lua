---@module 'config.neotree.keymaps.tests'
--- Neotest-Source-specific mappings for Neo-tree

---@return table<string, any>
return {
  -- Test Execution
  ["<CR>"] = "run_test",
  ["<S-CR>"] = "debug_test",

  -- Output
  ["o"] = "output",
  ["O"] = "short_output",

  -- Control
  ["s"] = "stop_test",
  ["w"] = "watch_test",

  -- Disable ALL filesystem operations (gleiche Liste wie document_symbols):
  ["/"] = "noop",
  ["<C-c>"] = "noop",
  ["a"] = "noop",
  ["A"] = "noop",
  ["d"] = "noop",
  ["dd"] = "noop",
  ["r"] = "noop",
  ["c"] = "noop",
  ["x"] = "noop",
  ["p"] = "noop",
  ["m"] = "noop",
  ["<S-m>"] = "noop",
  ["<leader>mc"] = "noop",
  ["U"] = "noop",
  ["<leader>th"] = "noop",
  ["+"] = "noop",
  ["-"] = "noop",
  ["I"] = "noop",
  ["L"] = "noop",
  ["[l"] = "noop",
  ["grep"] = "noop",
  ["D"] = "noop",
  ["[p"] = "noop",
  ["]p"] = "noop",
  ["]r"] = "noop",
  ["[r"] = "noop",
  ["[f"] = "noop",
  ["[F"] = "noop",
  ["[t"] = "noop",
  ["[T"] = "noop",
  ["Y"] = "noop",
  ["<S-o>"] = "noop",
  ["gb"] = "noop",
  ["<C-s>"] = "noop",
  ["<M-s>"] = "noop",
  ["<Tab>"] = "noop",
  ["<PageDown>"] = "noop",
  ["<PageUp>"] = "noop",
  ["<C-f>"] = "noop",
  ["<C-b>"] = "noop",
  ["sv"] = "noop",
  ["sg"] = "noop",
  ["st"] = "noop",
}
