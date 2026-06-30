local uv = vim.loop

local function benchmark_startup()
  -- Scenario 1: Alle Sources laden (aktuell)
  local start = uv.hrtime()
  require("neo-tree.sources.filesystem")
  require("neo-tree.sources.buffers")
  require("neo-tree.sources.git_status")
  require("neo-tree.sources.document_symbols")
  local duration_all = (uv.hrtime() - start) / 1e6

  -- Scenario 2: Nur filesystem (lazy)
  package.loaded["neo-tree.sources.filesystem"] = nil
  local start_lazy = uv.hrtime()
  require("neo-tree.sources.filesystem")
  local duration_lazy = (uv.hrtime() - start_lazy) / 1e6

  print(string.format("All sources: %.2f ms", duration_all))
  print(string.format("Filesystem only: %.2f ms", duration_lazy))
  print(string.format("Improvement: %.1f%%", (1 - duration_lazy / duration_all) * 100))
end

benchmark_startup()
