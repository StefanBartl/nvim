---@module 'config.neotest.adapters.typescript'
---@brief Neotest adapter configuration for TypeScript/JavaScript testing

local M = {}

local function create_adapter()
  local ok_vitest, vitest = pcall(require, "neotest-vitest")
  if ok_vitest then
    return vitest({
      vitestCommand = "npx vitest",
      env = { CI = "true" },
      cwd = function(_)
        return vim.fn.getcwd()
      end,
    })
  end

  local ok_jest, jest = pcall(require, "neotest-jest")
  if ok_jest then
    return jest({
      jestCommand = "npm test --",
      jestConfigFile = function(file)
        -- Synchrone Alternative zu glob
        local config_files = {
          "jest.config.js",
          "jest.config.ts",
          "jest.config.json",
        }

        local dir = vim.fn.fnamemodify(file, ":h")
        while dir ~= "/" and dir ~= "" do
          for _, config in ipairs(config_files) do
            local config_path = dir .. "/" .. config
            if vim.fn.filereadable(config_path) == 1 then
              return config_path
            end
          end
          dir = vim.fn.fnamemodify(dir, ":h")
        end

        return nil
      end,
      env = { CI = "true" },
      cwd = function(_)
        return vim.fn.getcwd()
      end,
    })
  end

  return nil
end

M.adapter = create_adapter()

M.test_patterns = {
  "%.test%.ts$",
  "%.test%.tsx$",
  "%.spec%.ts$",
  "%.spec%.tsx$",
  "%.test%.js$",
  "%.test%.jsx$",
  "%.spec%.js$",
  "%.spec%.jsx$",
}

function M.is_test_file(filepath)
  if not filepath or filepath == "" then
    return false
  end

  for i = 1, #M.test_patterns do
    if filepath:match(M.test_patterns[i]) then
      return true
    end
  end

  return false
end

return M
