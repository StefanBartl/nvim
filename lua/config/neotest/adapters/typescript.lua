---@module 'config.neotest.adapters.typescript'
---@brief Neotest adapter for TypeScript/JavaScript with Vitest/Jest

local notify = require("lib.nvim.notify").create("[config.neotest.adapters.typescript]")

local M = {}

----------------------------------------------------------------------
-- CWD lock (prevents multi-root discovery)
----------------------------------------------------------------------

local _locked_cwd = vim.fn.getcwd()

----------------------------------------------------------------------
-- Root finding with CWD lock
----------------------------------------------------------------------

--- Find project root, but only if within locked CWD
---@param path string
---@return string|nil
local function find_root(path)
  -- CRITICAL: Reject paths outside locked CWD
  local abs_path = vim.fn.fnamemodify(path, ":p")
  if not abs_path:match("^" .. vim.pesc(_locked_cwd)) then
    return nil
  end

  local markers = {
    "vitest.config.ts",
    "vitest.config.js",
    "vitest.config.mjs",
    "vitest.config.json",
    "jest.config.ts",
    "jest.config.js",
    "jest.config.json",
    "package.json",
    "tsconfig.json",
  }

  if vim.fs and vim.fs.root then
    local root = vim.fs.root(path, markers)
    -- Verify root is within locked CWD
    if root and root:match("^" .. vim.pesc(_locked_cwd)) then
      return root
    end
  end

  -- Fallback: manual search
  local dir = vim.fn.fnamemodify(path, ":p:h")
  for _ = 1, 20 do
    -- Stop if we've left the locked CWD
    if not dir:match("^" .. vim.pesc(_locked_cwd)) then
      break
    end

    for _, marker in ipairs(markers) do
      if vim.fn.filereadable(dir .. "/" .. marker) == 1 then
        return dir
      end
    end

    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir then
      break
    end
    dir = parent
  end

  return _locked_cwd
end

----------------------------------------------------------------------
-- Framework detection with safe file reading
----------------------------------------------------------------------

--- Safely read file content
---@param path string
---@return string|nil
local function safe_read_file(path)
  if vim.fn.filereadable(path) ~= 1 then
    return nil
  end

  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok or not lines then
    return nil
  end

  return table.concat(lines, "\n")
end

--- Detect framework from root directory
---@param root string
---@return "vitest"|"jest"|nil
local function detect_framework(root)
  -- Check config files first
  if
    vim.fn.filereadable(root .. "/vitest.config.ts") == 1
    or vim.fn.filereadable(root .. "/vitest.config.js") == 1
    or vim.fn.filereadable(root .. "/vitest.config.mjs") == 1
    or vim.fn.filereadable(root .. "/vitest.config.json") == 1
  then
    return "vitest"
  end

  if
    vim.fn.filereadable(root .. "/jest.config.ts") == 1
    or vim.fn.filereadable(root .. "/jest.config.js") == 1
    or vim.fn.filereadable(root .. "/jest.config.json") == 1
  then
    return "jest"
  end

  -- Check package.json (safe)
  local pkg_content = safe_read_file(root .. "/package.json")
  if not pkg_content then
    return nil
  end

  -- Simple text search (faster than JSON parsing)
  if pkg_content:match('"vitest"') or pkg_content:match('"@vitest') then
    return "vitest"
  end

  if pkg_content:match('"jest"') or pkg_content:match('"@jest') then
    return "jest"
  end

  return nil
end

----------------------------------------------------------------------
-- Test File Detection
----------------------------------------------------------------------

--- Check if file is a test file
---@param file_path string
---@return boolean
local function is_test_file(file_path)
  if not file_path or file_path == "" then
    return false
  end

  -- CRITICAL: Reject files outside locked CWD
  local abs_path = vim.fn.fnamemodify(file_path, ":p")
  if not abs_path:match("^" .. vim.pesc(_locked_cwd)) then
    return false
  end

  -- Extension check
  if not file_path:match("%.[jt]sx?$") and not file_path:match("%.m[jt]s$") then
    return false
  end

  -- Pattern check
  return file_path:match("%.test%.[jt]sx?$") ~= nil
    or file_path:match("%.spec%.[jt]sx?$") ~= nil
    or file_path:match("%.test%.m[jt]s$") ~= nil
end

----------------------------------------------------------------------
-- Adapter Creation
----------------------------------------------------------------------

--- Create Vitest adapter
---@return table|nil
local function create_vitest()
  local ok, vitest = pcall(require, "neotest-vitest")
  if not ok then
    return nil
  end

  return vitest({
    vitestCommand = "npx vitest",
    env = { CI = "true" },
    cwd = find_root,
    filter_dir = function(name, rel_path, root)
      -- Exclude node_modules
      if name == "node_modules" then
        return false
      end

      -- CRITICAL: Only scan within locked CWD
      local full_path = root .. "/" .. rel_path
      return full_path:match("^" .. vim.pesc(_locked_cwd)) ~= nil
    end,
    is_test_file = is_test_file,
  })
end

--- Create Jest adapter
---@return table|nil
local function create_jest()
  local ok, jest = pcall(require, "neotest-jest")
  if not ok then
    return nil
  end

  return jest({
    jestCommand = "npx jest",
    env = { CI = "true" },
    cwd = find_root,
    filter_dir = function(name, rel_path, root)
      if name == "node_modules" then
        return false
      end

      local full_path = root .. "/" .. rel_path
      return full_path:match("^" .. vim.pesc(_locked_cwd)) ~= nil
    end,
    is_test_file = is_test_file,
  })
end

--- Create adapter based on project
---@return table|nil
function M.create()
  local root = find_root(_locked_cwd)
  notify.info("locked cwd for neotest: " .. _locked_cwd)

  if not root then
    notify.info("no root found for neotest")
    return create_vitest() or create_jest()
  end

  local framework = detect_framework(root)

  if framework == "vitest" then
    notify.info("vitest found")
    return create_vitest()
  elseif framework == "jest" then
    notify.info("jest found")
    return create_jest()
  end

  return create_vitest() or create_jest()
end

return M
