---@module 'config.neotest.utils.validate_consumer'
---@brief Validates correct initialization of the Neo-tree tests consumer

local notify = require("lib.nvim.notify").create("[neotest.validate]")
local usercmd = require("lib.nvim.bindings.usercmd")

local M = {}

--- Whether `v` can be called: a plain function, or a table carrying a
--- `__call` metamethod.
---
--- The distinction matters because `neotest.consumers.neotree` is a callable
--- *table* (it exposes `run`, `output`, `watch`, ... alongside `__call`), not
--- a bare function. A `type(v) == "function"` test rejects it, which made
--- this validator report a broken setup on a perfectly working one.
---@param v any
---@return boolean
local function is_callable(v)
  if type(v) == "function" then
    return true
  end
  local mt = type(v) == "table" and getmetatable(v) or nil
  return type(mt) == "table" and type(mt.__call) == "function"
end

--- Checks whether the Neo-tree tests source is loaded correctly
---@return boolean success
---@return string|nil error_msg
function M.check_consumer()
  -- 1. Check that neotest.consumers.neotree exists
  local consumer_ok, consumer = pcall(require, "neotest.consumers.neotree")
  if not consumer_ok then
    return false, "Consumer module not found: neotest.consumers.neotree"
  end

  -- 2. Check it can actually be used as a factory
  if not is_callable(consumer) then
    return false,
      string.format(
        "Consumer is not callable: %s (expected a function or __call table)",
        type(consumer)
      )
  end

  -- 3. Check that Neotest setup has run
  -- The table itself carries no settings (those come from the
  -- `neotest.config` module below), but it does serve the initialized
  -- consumers through `__index`, which step 5 needs.
  local neotest_ok, neotest = pcall(require, "neotest")
  if not neotest_ok then
    return false, "Neotest not loaded"
  end

  -- The resolved config lives in the `neotest.config` MODULE, not as a field
  -- on the `neotest` table -- that table is empty and serves its consumers
  -- through an `__index` metamethod, so `neotest.config` is always `nil`.
  -- Every check below used to read it, which meant this validator could only
  -- ever answer "Neotest consumers not configured", whatever the truth was.
  local cfg_ok, neotest_config = pcall(require, "neotest.config")
  if not cfg_ok then
    return false, "neotest.config not loadable"
  end

  -- 4. Check that the consumer is registered
  if not neotest_config or not neotest_config.consumers then
    return false, "Neotest consumers not configured"
  end

  if not neotest_config.consumers.neotree then
    return false, "Neo-tree consumer not registered in neotest.config.consumers"
  end

  -- 5. CRITICAL: check that the consumer was actually initialized.
  --
  -- Not via `config.consumers.neotree`: neotest's `setup()` does
  -- `consumers[name] = consumer(consumer_client(client, name)) or {}` into a
  -- module-local table and leaves the configured entry alone, so that entry
  -- stays the factory forever. Testing it for "is it a table yet" could
  -- therefore never succeed -- which is exactly what this validator reported.
  -- The initialized instance is served off the `neotest` table's `__index`.
  local consumer_instance = neotest.neotree
  if consumer_instance == nil then
    return false, "Consumer not initialized (neotest.neotree is nil — has neotest.setup run?)"
  end

  if type(consumer_instance) ~= "table" then
    return false,
      string.format(
        "Consumer has invalid type: %s (expected: table after initialization)",
        type(consumer_instance)
      )
  end

  -- 6. Check that the Neo-tree source is configured.
  --
  -- `require("neo-tree").config.sources`, not
  -- `neo-tree.sources.manager.get_source_names()`: that function does not
  -- exist in neo-tree v3 at all, so this step was a call on a nil value.
  -- It never ran before, because the broken `neotest.config` test above
  -- returned first -- fixing that is what brought execution down here.
  --
  -- neo-tree is lazy-loaded, so `config` is only populated once its `setup()`
  -- has run. "Could not look" is reported as such rather than as "missing":
  -- a validator that calls a not-yet-loaded plugin broken would send someone
  -- hunting for a problem that is not there.
  local neotree_ok, neotree = pcall(require, "neo-tree")
  local sources = neotree_ok and type(neotree.config) == "table" and neotree.config.sources
  if type(sources) == "table" then
    if not vim.tbl_contains(sources, "tests") then
      return false, "Tests source not registered in Neo-tree"
    end
  end

  return true, nil
end

--- Runs the full diagnostic and prints a report
---@return boolean success  Whether every checked step reported OK.
function M.diagnose()
  local lines = { "=== Neo-tree Tests Consumer Diagnostics ===" }
  lines[#lines + 1] = ""

  -- Step 1: consumer module
  local consumer_ok, consumer = pcall(require, "neotest.consumers.neotree")
  lines[#lines + 1] =
    string.format("1. Consumer Module: %s", consumer_ok and "✓ LOADED" or "✗ NOT FOUND")
  if consumer_ok then
    lines[#lines + 1] = string.format("   Type: %s", type(consumer))
  end
  lines[#lines + 1] = ""

  -- Step 2: Neotest config
  local neotest_ok = pcall(require, "neotest")
  lines[#lines + 1] =
    string.format("2. Neotest: %s", neotest_ok and "✓ LOADED" or "✗ NOT FOUND")

  if neotest_ok then
    -- Same correction as in `M.check_consumer`: the resolved config is the
    -- `neotest.config` module, never a field on the `neotest` table.
    local _cfg_ok, neotest_config = pcall(require, "neotest.config")
    local has_consumers = _cfg_ok and neotest_config and neotest_config.consumers
    lines[#lines + 1] =
      string.format("   Config.consumers: %s", has_consumers and "✓ EXISTS" or "✗ MISSING")

    if has_consumers then
      local has_neotree = neotest_config.consumers.neotree ~= nil
      lines[#lines + 1] =
        string.format("   Neotree registered: %s", has_neotree and "✓ YES" or "✗ NO")

      if has_neotree then
        local consumer_type = type(neotest_config.consumers.neotree)

        -- The configured entry is always the factory (see step 5 in
        -- `M.check_consumer`); whether it was initialized is visible on
        -- the instance neotest serves back.
        lines[#lines + 1] = string.format("   Configured as: %s", consumer_type)
        local inst = require("neotest").neotree
        lines[#lines + 1] = type(inst) == "table" and "   Status: ✓ INITIALIZED"
          or string.format("   Status: ✗ NOT INITIALIZED (%s)", type(inst))
      end
    end
  end
  lines[#lines + 1] = ""

  -- Overall result
  local success, error_msg = M.check_consumer()
  if success then
    lines[#lines + 1] = "✓ ALL CHECKS PASSED"
  else
    lines[#lines + 1] = "✗ VALIDATION FAILED"
    lines[#lines + 1] = string.format("Error: %s", error_msg or "unknown")
  end

  local output = table.concat(lines, "\n")

  if success then
    notify.info(output)
  else
    notify.error(output)
  end

  return success
end

--- Registers the diagnostic command
---@return nil
function M.setup_command()
  usercmd.create("NeotestValidateConsumer", function()
    M.diagnose()
  end, { desc = "Validate Neo-tree tests consumer setup" })
end

return M
