---@module 'config.neotest.adapters.factory'
---@brief Adapter factory with strict singleton enforcement

--- CDX: M.get_all() is never called -- plugins/neotest.lua hardcodes
--- opts.adapters to plenary/vitest/go directly instead of using this
--- registry, so python/rust/typescript never actually get activated despite
--- being installed. Documented split-brain, see docs/ROADMAP/IDEAS/test.md §2.1.

local M = {}

----------------------------------------------------------------------
-- Global Singleton Cache
----------------------------------------------------------------------

---@type table<string, table>
_G._neotest_adapter_cache = _G._neotest_adapter_cache or {}

----------------------------------------------------------------------
-- Helper: Check if file exists
----------------------------------------------------------------------

---@param filepath string
---@return boolean
local function file_exists(filepath)
  return vim.fn.filereadable(filepath) == 1
end

----------------------------------------------------------------------
-- Adapter Registry
----------------------------------------------------------------------

---@type table<string, fun(): table|nil>
local ADAPTER_BUILDERS = {
  lua = function()
    local ok, plenary = pcall(require, "neotest-plenary")
    if not ok then
      return nil
    end

    local min_init_candidates = {
      "./scripts/tests/minimal_init.lua",
      vim.fn.getcwd() .. "/scripts/tests/minimal_init.lua",
    }

    local min_init = nil
    for _, candidate in ipairs(min_init_candidates) do
      if file_exists(candidate) then
        min_init = candidate
        break
      end
    end

    -- Return with or without minimal_init
    if min_init then
      return plenary({ min_init = min_init })
    else
      return plenary()
    end
  end,

  go = function()
    local ok, neotest_go = pcall(require, "neotest-go")
    if not ok then
      return nil
    end
    return neotest_go({
      experimental = {
        test_table = true,
      },
      args = { "-v", "-race", "-count=1", "-timeout=60s" },
    })
  end,

  python = function()
    local ok, neotest_python = pcall(require, "neotest-python")
    if not ok then
      return nil
    end
    return neotest_python({
      dap = { justMyCode = false },
      args = { "-v", "-s", "--log-level=DEBUG" },
    })
  end,

  rust = function()
    local ok, neotest_rust = pcall(require, "neotest-rust")
    if not ok then
      return nil
    end
    return neotest_rust({
      args = { "--no-capture" },
      dap_adapter = "lldb",
    })
  end,

  typescript = function()
    return require("config.neotest.adapters.typescript").create()
  end,
}

----------------------------------------------------------------------
-- Public API
----------------------------------------------------------------------

--- Get or create adapter (Singleton)
---@param lang string
---@return table|nil
function M.get(lang)
  -- Check global cache first
  if _G._neotest_adapter_cache[lang] then
    return _G._neotest_adapter_cache[lang]
  end

  -- Build adapter
  local builder = ADAPTER_BUILDERS[lang]
  if not builder then
    return nil
  end

  local adapter = builder()
  if adapter then
    _G._neotest_adapter_cache[lang] = adapter
  end

  return adapter
end

--- Get all available adapters (deduplicated)
---@return table[]
function M.get_all()
  local adapters = {}

  for lang, _ in pairs(ADAPTER_BUILDERS) do
    local adapter = M.get(lang)
    if adapter then
      adapters[#adapters + 1] = adapter
    end
  end

  return adapters
end

return M
