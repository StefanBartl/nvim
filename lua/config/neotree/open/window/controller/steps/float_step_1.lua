-- ============================================================================
-- STEP 1: Minimal - Nur NeoCmd.execute
-- ============================================================================

local fs = require("config.neotree.open.window.controller.float_debug_steps")

---Minimal float open - nur execute, keine extras
---@param callback fun(success: boolean)
return function (callback)
  print("[STEP 1] Minimal execute")

  local NeoCmd, err = fs.get_neo_cmd()
  if not NeoCmd then
    print("[STEP 1] ERROR: " .. err)
    callback(false)
    return
  end

  local ok = pcall(NeoCmd.execute, {
    source = "filesystem",
    action = "show",
    position = "float",
    toggle = false,
  })

  print(string.format("[STEP 1] Execute result: %s", tostring(ok)))
  callback(ok)
end

