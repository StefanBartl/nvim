---@module 'config.neotest.utils.validate_consumer'
---@brief Validates correct initialization of the Neo-tree tests consumer

local notify = require("lib.nvim.notify").create("[neotest.validate]")
local usercmd = require("lib.nvim.bindings.usercmd")

local M = {}

--- Checks whether the Neo-tree tests source is loaded correctly
---@return boolean success
---@return string|nil error_msg
function M.check_consumer()
  -- 1. Check that neotest.consumers.neotree exists
  local consumer_ok, consumer = pcall(require, "neotest.consumers.neotree")
  if not consumer_ok then
    return false, "Consumer module not found: neotest.consumers.neotree"
  end

  -- 2. Check its type
  if type(consumer) ~= "function" then
    return false,
      string.format("Consumer has unexpected type: %s (expected: function)", type(consumer))
  end

  -- 3. Check that Neotest setup has run
  local neotest_ok, neotest = pcall(require, "neotest")
  if not neotest_ok then
    return false, "Neotest not loaded"
  end

  -- 4. Check that the consumer is registered
  if not neotest.config or not neotest.config.consumers then
    return false, "Neotest consumers not configured"
  end

  if not neotest.config.consumers.neotree then
    return false, "Neo-tree consumer not registered in neotest.config.consumers"
  end

  -- 5. CRITICAL: check that the consumer was initialized (not still the factory)
  local consumer_instance = neotest.config.consumers.neotree
  if type(consumer_instance) == "function" then
    return false, "Consumer is still a factory function (not initialized)"
  end

  if type(consumer_instance) ~= "table" then
    return false,
      string.format(
        "Consumer has invalid type: %s (expected: table after initialization)",
        type(consumer_instance)
      )
  end

  -- 6. Check that the Neo-tree source exists
  local neotree_ok, neotree_sources = pcall(require, "neo-tree.sources.manager")
  if neotree_ok then
    local sources = neotree_sources.get_source_names()
    local has_tests = false
    for _, source in ipairs(sources) do
      if source == "tests" then
        has_tests = true
        break
      end
    end

    if not has_tests then
      return false, "Tests source not registered in Neo-tree"
    end
  end

  return true, nil
end

--- Runs the full diagnostic and prints a report
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
  local neotest_ok, neotest = pcall(require, "neotest")
  lines[#lines + 1] =
    string.format("2. Neotest: %s", neotest_ok and "✓ LOADED" or "✗ NOT FOUND")

  if neotest_ok then
    local has_consumers = neotest.config and neotest.config.consumers
    lines[#lines + 1] =
      string.format("   Config.consumers: %s", has_consumers and "✓ EXISTS" or "✗ MISSING")

    if has_consumers then
      local has_neotree = neotest.config.consumers.neotree ~= nil
      lines[#lines + 1] =
        string.format("   Neotree registered: %s", has_neotree and "✓ YES" or "✗ NO")

      if has_neotree then
        local consumer_type = type(neotest.config.consumers.neotree)
        lines[#lines + 1] = string.format("   Consumer type: %s", consumer_type)

        if consumer_type == "function" then
          lines[#lines + 1] = "   Status: ✗ NOT INITIALIZED (still factory)"
        elseif consumer_type == "table" then
          lines[#lines + 1] = "   Status: ✓ INITIALIZED"
        end
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
function M.setup_command()
  usercmd.create("NeotestValidateConsumer", function()
    M.diagnose()
  end, { desc = "Validate Neo-tree tests consumer setup" })
end

return M
