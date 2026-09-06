---@module 'config.neotest.init.dependencies'
--- The plugin/consumer/adapter repo lists neotest's lazy.nvim spec declares
--- as `dependencies` -- plain data, kept apart from the spec itself.

local PLUGINS = {
  "nvim-neotest/nvim-nio",
  "nvim-lua/plenary.nvim",
  "antoinemadec/FixCursorHold.nvim",
  "nvim-treesitter/nvim-treesitter",
  "vim-test/vim-test",
}

local CONSUMER = {
  "TimCreasman/neo-tree-tests-source.nvim",
}

--- CDX: neotest-vim-test is installed here but adapters/factory.lua's
--- ADAPTER_BUILDERS has no builder for it (only lua/go/python/rust/
--- typescript) -- it never becomes an active adapter, same class of orphan
--- as the python/rust/jest entries already documented in
--- docs/ROADMAP/IDEAS/test.md §2.1 (that doc's plugin list didn't call this
--- one out by name).
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
