---@module 'config.neotest.init.dependencies'

local PLUGINS = {
  "nvim-neotest/nvim-nio",
  "nvim-lua/plenary.nvim",
  "antoinemadec/FixCursorHold.nvim",
  "nvim-treesitter/nvim-treesitter",
}

local CONSUMER = {
  "TimCreasman/neo-tree-tests-source.nvim",
}

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
