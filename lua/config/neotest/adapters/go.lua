---@module 'config.neotest.adapters.go'
---@brief Neotest adapter configuration for Go testing with go test

local M = {}

local function create_adapter()
  local ok, neotest_go = pcall(require, "neotest-go")
  if not ok then
    return nil
  end

  return neotest_go({
    experimental = {
      test_table = true,
    },
    args = { "-v", "-race", "-count=1", "-timeout=60s" },
    runner = "go",
    -- Root finder
    root_dir = function(fname)
      local util = require("lspconfig.util")
      -- Suche go.mod im PARENT-Verzeichnis
      local root = util.root_pattern("go.mod")(fname)
      if root then
        return root
      end
      -- Fallback: Git-Root
      return util.root_pattern(".git")(fname)
    end,
  })
end

M.adapter = create_adapter()

M.test_patterns = { "_test%.go$" }

function M.is_test_file(filepath)
  if not filepath or filepath == "" then
    return false
  end
  return filepath:match("_test%.go$") ~= nil
end

function M.get_test_patterns()
  return { "^Test", "^Benchmark", "^Example" }
end

return M
