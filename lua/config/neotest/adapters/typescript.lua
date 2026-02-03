---@module 'config.neotest.adapters.typescript'
---@brief Neotest adapter configuration for TypeScript/JavaScript testing

local M = {}

---Find project root by looking for package.json
---@param file_path string
---@return string|nil
local function find_project_root(file_path)
  -- Nutze Neovim's eingebaute Root-Finding
  local root = vim.fs.root(file_path, { "package.json", "tsconfig.json" })
  if root then
    return root
  end

  -- Fallback: Manuelles Suchen
  local dir = vim.fn.fnamemodify(file_path, ":h")

  for _ = 1, 10 do
    local pkg = dir .. "/package.json"
    if vim.fn.filereadable(pkg) == 1 then
      return dir
    end

    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir or parent == "" then
      break
    end
    dir = parent
  end

  return nil
end

local function create_adapter()
  -- Try Vitest first
  local ok_vitest, vitest = pcall(require, "neotest-vitest")
  if ok_vitest then
    return vitest({
      vitestCommand = "npx vitest",

      env = {
        CI = "true",
        FORCE_COLOR = "0",
      },

      -- KRITISCH: root statt cwd für Neotest >= 5.0
      root = function(file_path)
        return find_project_root(file_path) or vim.fn.getcwd()
      end,

      filter_dir = function(name, rel_path, root)
        return name ~= "node_modules"
      end,

      is_test_file = function(file_path)
        if not file_path then
          return false
        end

        return file_path:match("%.test%.[jt]sx?$") ~= nil
            or file_path:match("%.spec%.[jt]sx?$") ~= nil
      end,
    })
  end

  -- Fallback: Jest
  local ok_jest, jest = pcall(require, "neotest-jest")
  if ok_jest then
    return jest({
      jestCommand = "npx jest",
      env = { CI = "true" },
      root = function(file_path)
        return find_project_root(file_path) or vim.fn.getcwd()
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
