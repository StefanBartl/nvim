---@module 'config.neotree.keymaps.tests'
--- Neotest-Source-specific mappings for Neo-tree

---@return table<string, any>
return {
  -- Test execution
  ["<CR>"] = "run_test",
  ["<S-CR>"] = "debug_test",

  -- Output display
  ["o"] = "output",
  ["O"] = "short_output",

  -- Test control
  ["s"] = "stop_test",
  ["w"] = "watch_test",

  -- Navigation
  ["R"] = "refresh",
  ["?"] = "show_help",
  ["q"] = "close_window",

  -- Disable operations that don't make sense for tests
  ["x"] = "noop",
  ["c"] = "noop",
  ["p"] = "noop",
  ["d"] = "noop",
  ["dd"] = "noop",
  ["a"] = "noop",
  ["A"] = "noop",
  ["r"] = "noop",
}
