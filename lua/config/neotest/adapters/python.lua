---@module 'config.neotest.adapters.python'
---@brief Neotest adapter configuration for Python testing with pytest, unittest, or nose

local M = {}

local function detect_framework()
  if vim.fn.executable("pytest") == 1 then
    return "pytest"
  end

  if vim.fn.executable("nose2") == 1 then
    return "nose"
  end

  return "unittest"
end

---Find Python project root
---@param start_path string
---@return string
local function find_python_root(start_path)
  local markers = {
    "pyproject.toml",
    "setup.py",
    "setup.cfg",
    "pytest.ini",
    "tox.ini",
    ".git",
  }

  local dir = vim.fn.fnamemodify(start_path, ":h")

  for _ = 1, 10 do
    for _, marker in ipairs(markers) do
      if vim.fn.filereadable(dir .. "/" .. marker) == 1 then
        return dir
      end
    end

    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir or parent == "" then
      break
    end
    dir = parent
  end

  return vim.fn.fnamemodify(start_path, ":h")
end

local function create_adapter()
  local ok, neotest_python = pcall(require, "neotest-python")
  if not ok then
    return nil
  end

  local framework = detect_framework()

  return neotest_python({
    dap = { justMyCode = false },
    runner = framework,
    python = function()
      -- Try to find venv python first
      local cwd = vim.fn.getcwd()
      local venv_paths = {
        cwd .. "/venv/bin/python",
        cwd .. "/venv/Scripts/python.exe",
        cwd .. "/.venv/bin/python",
        cwd .. "/.venv/Scripts/python.exe",
      }

      for _, path in ipairs(venv_paths) do
        if vim.fn.executable(path) == 1 then
          return path
        end
      end

      return "python3"
    end,
    args = framework == "pytest" and {
      "-v",
      "-s",
      "--log-level=DEBUG",
      "--no-header",
      "--no-summary",
      "-q"
    } or {},
    pytest_discover_instances = true,
    -- ✅ CRITICAL: Root finder
    root = function(fname)
      return find_python_root(fname)
    end,
    -- ✅ CRITICAL: Explicit test file check
    is_test_file = function(file_path)
      local basename = vim.fn.fnamemodify(file_path, ":t")
      return basename:match("^test_.*%.py$") ~= nil or basename:match(".*_test%.py$") ~= nil
    end,
  })
end

M.adapter = create_adapter()

M.test_patterns = {
  "test_.*%.py$",
  ".*_test%.py$",
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

function M.get_test_patterns()
  return {
    "^def test_",
    "^class Test",
    "^async def test_",
  }
end

return M
