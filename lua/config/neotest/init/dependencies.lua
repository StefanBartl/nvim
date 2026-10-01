---@module 'config.neotest.init.dependencies'
--- The plugin/consumer/adapter repo lists neotest's lazy.nvim spec declares
--- as `dependencies` -- plain data, kept apart from the spec itself.

local PLUGINS = {
  "nvim-neotest/nvim-nio",
  "nvim-lua/plenary.nvim",
  "antoinemadec/FixCursorHold.nvim",
  "nvim-treesitter/nvim-treesitter",
  -- Its own `cmd` trigger: this is vim-test's only spec, and neotest loads on
  -- demand, so without it `:TestNearest` & co. would not exist until
  -- something else had loaded neotest.
  {
    "vim-test/vim-test",
    cmd = { "TestNearest", "TestFile", "TestSuite", "TestLast", "TestVisit", "TestClass" },
  },
}

local CONSUMER = {
  "TimCreasman/neo-tree-tests-source.nvim",
}

--- CDX: parked -- neotest-vim-test has no builder in factory.lua's
--- ADAPTER_BUILDERS, so it never becomes an active adapter. Part of the
--- neotest adapter split-brain: docs/ROADMAP/CDX/config-cdx-triage.md §3.
local ADAPTER = {
  { "nvim-neotest/neotest-plenary", ft = "lua" },
  { "nvim-neotest/neotest-vim-test", ft = { "vim", "lua", "sh", "bash", "zsh", "asm" } },
  { "nvim-neotest/neotest-go", ft = "go" },
  { "nvim-neotest/neotest-python", ft = "python" },
  { "rouge8/neotest-rust", ft = "rust" },
  {
    "nvim-neotest/neotest-jest",
    ft = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
  },
  {
    "marilari88/neotest-vitest",
    ft = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
  },
}

local deps = {}
for _, v in ipairs(PLUGINS) do
  table.insert(deps, v)
end
for _, v in ipairs(CONSUMER) do
  table.insert(deps, v)
end
for _, v in ipairs(ADAPTER) do
  table.insert(deps, v)
end

return deps
