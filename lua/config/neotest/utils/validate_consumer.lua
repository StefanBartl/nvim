---@module 'config.neotest.utils.validate_consumer'
---@brief Validiert die korrekte Initialisierung des Neo-tree Tests Consumers

local notify = require("lib.notify").create("[neotest.validate]")

local M = {}

--- Prüft ob Neo-tree Tests Source korrekt geladen ist
---@return boolean success
---@return string|nil error_msg
function M.check_consumer()
  -- 1. Prüfe ob neotest.consumers.neotree existiert
  local consumer_ok, consumer = pcall(require, "neotest.consumers.neotree")
  if not consumer_ok then
    return false, "Consumer module not found: neotest.consumers.neotree"
  end

  -- 2. Prüfe Typ
  if type(consumer) ~= "function" then
    return false, string.format(
      "Consumer has unexpected type: %s (expected: function)",
      type(consumer)
    )
  end

  -- 3. Prüfe ob Neotest setup ausgeführt wurde
  local neotest_ok, neotest = pcall(require, "neotest")
  if not neotest_ok then
    return false, "Neotest not loaded"
  end

  -- 4. Prüfe ob Consumer registriert ist
  if not neotest.config or not neotest.config.consumers then
    return false, "Neotest consumers not configured"
  end

  if not neotest.config.consumers.neotree then
    return false, "Neo-tree consumer not registered in neotest.config.consumers"
  end

  -- 5. Prüfe ob Neo-tree Source existiert
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

--- Führt vollständige Diagnose durch und gibt Bericht aus
function M.diagnose()
  local lines = { "=== Neo-tree Tests Consumer Diagnostics ===" }
  lines[#lines + 1] = ""

  -- Schritt 1: Consumer-Modul
  local consumer_ok, consumer = pcall(require, "neotest.consumers.neotree")
  lines[#lines + 1] = string.format(
    "1. Consumer Module: %s",
    consumer_ok and "✓ LOADED" or "✗ NOT FOUND"
  )
  if consumer_ok then
    lines[#lines + 1] = string.format("   Type: %s", type(consumer))
  end
  lines[#lines + 1] = ""

  -- Schritt 2: Neotest Config
  local neotest_ok, neotest = pcall(require, "neotest")
  lines[#lines + 1] = string.format(
    "2. Neotest: %s",
    neotest_ok and "✓ LOADED" or "✗ NOT FOUND"
  )

  if neotest_ok then
    local has_consumers = neotest.config and neotest.config.consumers
    lines[#lines + 1] = string.format(
      "   Config.consumers: %s",
      has_consumers and "✓ EXISTS" or "✗ MISSING"
    )

    if has_consumers then
      local has_neotree = neotest.config.consumers.neotree ~= nil
      lines[#lines + 1] = string.format(
        "   Neotree registered: %s",
        has_neotree and "✓ YES" or "✗ NO"
      )
    end
  end
  lines[#lines + 1] = ""

  -- Schritt 3: Neo-tree Sources
  local sources_ok, neotree_sources = pcall(require, "neo-tree.sources.manager")
  lines[#lines + 1] = string.format(
    "3. Neo-tree Sources: %s",
    sources_ok and "✓ LOADED" or "✗ NOT FOUND"
  )

  if sources_ok then
    local source_names = neotree_sources.get_source_names()
    local has_tests = false
    for _, name in ipairs(source_names) do
      if name == "tests" then
        has_tests = true
        break
      end
    end

    lines[#lines + 1] = string.format(
      "   Tests source: %s",
      has_tests and "✓ REGISTERED" or "✗ NOT REGISTERED"
    )

    lines[#lines + 1] = "   Available sources:"
    for _, name in ipairs(source_names) do
      lines[#lines + 1] = string.format("     - %s", name)
    end
  end
  lines[#lines + 1] = ""

  -- Gesamtergebnis
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

--- Registriert Diagnose-Command
function M.setup_command()
  vim.api.nvim_create_user_command("NeotestValidateConsumer", function()
    M.diagnose()
  end, { desc = "Validate Neo-tree tests consumer setup" })
end

return M
