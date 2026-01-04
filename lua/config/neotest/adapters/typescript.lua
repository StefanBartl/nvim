---@module 'config.neotest.adapters.typescript'
---@brief Neotest adapter configuration for TypeScript/JavaScript testing

local M = {}

---Find package.json by walking up from file
---@param file_path string
---@return string|nil
local function find_package_json(file_path)
  local dir = vim.fn.fnamemodify(file_path, ":h")

  -- Max 10 levels up
  for _ = 1, 10 do
    local pkg = dir .. "/package.json"
    if vim.fn.filereadable(pkg) == 1 then
      return pkg
    end

    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir or parent == "" then
      break
    end
    dir = parent
  end

  return nil
end

---Check if project uses Vitest
---@param pkg_path string
---@return boolean
---@diagnostic disable-next-line: unused-function, unused-local
local function uses_vitest(pkg_path)
  local ok, content = pcall(vim.fn.readfile, pkg_path)
  if not ok or not content then
    return false
  end

  local text = table.concat(content, "\n")
  return text:match('"vitest"') ~= nil
end

local function create_adapter()
  -- Try Vitest first
  local ok_vitest, vitest = pcall(require, "neotest-vitest")
  if ok_vitest then
    return vitest({
      vitestCommand = "npx vitest",
      env = { CI = "true" },
      cwd = function(file_path)
        local pkg = find_package_json(file_path)
        if pkg then
          return vim.fn.fnamemodify(pkg, ":h")
        end
        return vim.fn.getcwd()
      end,
      filter_dir = function(name, _, _)
        return name ~= "node_modules"
      end,
    })
  end

  -- Fallback: Jest
  local ok_jest, jest = pcall(require, "neotest-jest")
  if ok_jest then
    return jest({
      jestCommand = "npx jest",
      jestConfigFile = function(file_path)
        local pkg_dir = vim.fn.fnamemodify(find_package_json(file_path) or "", ":h")
        if pkg_dir == "" then
          return nil
        end

        local configs = {
          pkg_dir .. "/jest.config.js",
          pkg_dir .. "/jest.config.ts",
          pkg_dir .. "/jest.config.json",
        }

        for _, cfg in ipairs(configs) do
          if vim.fn.filereadable(cfg) == 1 then
            return cfg
          end
        end

        return nil
      end,
      env = { CI = "true" },
      cwd = function(file_path)
        local pkg = find_package_json(file_path)
        if pkg then
          return vim.fn.fnamemodify(pkg, ":h")
        end
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
