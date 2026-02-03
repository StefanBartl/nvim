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

-- ---Check if project uses Vitest
-- ---@param pkg_path string
-- ---@return boolean
-- local function uses_vitest(pkg_path)
  -- local ok, content = pcall(vim.fn.readfile, pkg_path)
  -- if not ok or not content then
    -- return false
  -- end

  -- local text = table.concat(content, "\n")
  -- return text:match('"vitest"') ~= nil
-- end

local function create_adapter()
  -- Try Vitest first
  local ok_vitest, vitest = pcall(require, "neotest-vitest")
  if ok_vitest then
    return vitest({
      -- KRITISCH: Explizites vitestCommand
      vitestCommand = function()
        -- Prüfe ob npx verfügbar ist
        if vim.fn.executable("npx") == 1 then
          return "npx vitest"
        end
        -- Fallback zu globalem vitest
        return "vitest"
      end,

      env = { CI = "true" },

      -- KRITISCH: CWD muss auf package.json-Verzeichnis zeigen
      cwd = function(file_path)
        local pkg = find_package_json(file_path)
        if pkg then
          local dir = vim.fn.fnamemodify(pkg, ":h")
          -- Normalisiere für Windows
          return dir:gsub("\\", "/")
        end
        return vim.fn.getcwd():gsub("\\", "/")
      end,

      filter_dir = function(name, rel_path, root)
        return name ~= "node_modules"
      end,

      -- KRITISCH: is_test_file muss ALLE JS/TS Varianten erkennen
      is_test_file = function(file_path)
        if not file_path then
          return false
        end

        -- Normalisiere Pfad
        local normalized = file_path:gsub("\\", "/")

        -- Prüfe alle Test-Muster
        local patterns = {
          "%.test%.js$",
          "%.test%.ts$",
          "%.test%.jsx$",
          "%.test%.tsx$",
          "%.spec%.js$",
          "%.spec%.ts$",
          "%.spec%.jsx$",
          "%.spec%.tsx$",
        }

        for _, pattern in ipairs(patterns) do
          if normalized:match(pattern) then
            return true
          end
        end

        return false
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
          return vim.fn.fnamemodify(pkg, ":h"):gsub("\\", "/")
        end
        return vim.fn.getcwd():gsub("\\", "/")
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

  -- Normalisiere Pfad
  local normalized = filepath:gsub("\\", "/")

  for i = 1, #M.test_patterns do
    if normalized:match(M.test_patterns[i]) then
      return true
    end
  end

  return false
end

return M
