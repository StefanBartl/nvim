---@module 'config.neotest.adapters.typescript'
---@brief Neotest adapter configuration for TypeScript/JavaScript testing

local M = {}

---Find package.json by walking up from file
---@param file_path string
---@return string|nil
local function find_package_json(file_path)
  -- Normalisiere Pfad für Windows
  local normalized = file_path:gsub("\\", "/")
  local dir = vim.fn.fnamemodify(normalized, ":h")

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

local function create_adapter()
  -- Try Vitest first
  local ok_vitest, vitest = pcall(require, "neotest-vitest")
  if ok_vitest then
    return vitest({
      vitestCommand = "npx vitest",

      -- KRITISCH: Environment-Variable für besseres Parsing
      env = {
        CI = "true",
        FORCE_COLOR = "0",  -- Keine ANSI-Farben im Output
      },

      -- KRITISCH: CWD korrekt setzen
      cwd = function(file_path)
        local pkg = find_package_json(file_path)
        if pkg then
          return vim.fn.fnamemodify(pkg, ":h")
        end
        return vim.fn.getcwd()
      end,

      filter_dir = function(name, rel_path, root)
        return name ~= "node_modules"
      end,

      is_test_file = function(file_path)
        if not file_path then
          return false
        end

        -- Normalisiere Pfad
        local normalized = file_path:gsub("\\", "/")

        -- Prüfe alle Test-Muster
        return normalized:match("%.test%.[jt]sx?$") ~= nil
            or normalized:match("%.spec%.[jt]sx?$") ~= nil
      end,
    })
  end

  -- Fallback: Jest
  local ok_jest, jest = pcall(require, "neotest-jest")
  if ok_jest then
    return jest({
      jestCommand = "npx jest",
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

  local normalized = filepath:gsub("\\", "/")

  for i = 1, #M.test_patterns do
    if normalized:match(M.test_patterns[i]) then
      return true
    end
  end

  return false
end

return M
