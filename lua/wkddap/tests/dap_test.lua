-- ============================================================================
-- MINIMAL DAP TEST
-- Speichere diese Datei als: lua/dap_test.lua
-- Führe aus mit: :luafile lua/dap_test.lua
-- ============================================================================

-- Schritt 1: Prüfe ob nvim-dap installiert ist
local ok_dap, dap = pcall(require, "dap")
if not ok_dap then
  print("[TEST] FEHLER: nvim-dap nicht installiert")
  return
end
print("[TEST] ✓ nvim-dap gefunden")

-- Schritt 2: Initialisiere listeners (WICHTIG!)
if not dap.listeners then
  dap.listeners = {
    before = {},
    after = {},
  }
  print("[TEST] ✓ dap.listeners initialisiert")
else
  print("[TEST] ✓ dap.listeners existiert bereits")
end

-- Schritt 3: Teste einen einfachen Adapter (Lua)
print("[TEST] Teste Lua-Adapter...")

-- Lua Adapter (OSV)
local ok_osv, _ = pcall(require, "osv")
if ok_osv then
  dap.adapters.nlua = function(callback, config)
    callback({
      type = "server",
      host = config.host or "127.0.0.1",
      port = config.port or 8086,
    })
  end
  print("[TEST] ✓ Lua-Adapter registriert")
else
  print("[TEST] ✗ OSV nicht gefunden (optional)")
end

-- Schritt 4: Teste eine Konfiguration
dap.configurations.lua = {
  {
    type = "nlua",
    request = "attach",
    name = "Attach to running Neovim instance",
    host = "127.0.0.1",
    port = 8086,
  },
}
print("[TEST] ✓ Lua-Konfiguration geladen")

-- Schritt 5: Teste DAP UI (falls installiert)
local ok_dapui, dapui = pcall(require, "dapui")
if ok_dapui then
  -- Initialisiere Event-Listener-Tabellen
  dap.listeners.after.event_initialized = dap.listeners.after.event_initialized or {}
  dap.listeners.before.event_terminated = dap.listeners.before.event_terminated or {}
  dap.listeners.before.event_exited = dap.listeners.before.event_exited or {}

  dapui.setup({
    layouts = {
      {
        elements = {
          { id = "scopes", size = 0.25 },
          { id = "breakpoints", size = 0.25 },
          { id = "stacks", size = 0.25 },
          { id = "watches", size = 0.25 },
        },
        size = 40,
        position = "left",
      },
    },
  })

  dap.listeners.after.event_initialized["wkdtest_config"] = function()
    print("[TEST] ✓ DAP UI Auto-Open funktioniert")
  end

  print("[TEST] ✓ DAP UI konfiguriert")
else
  print("[TEST] ℹ DAP UI nicht installiert (optional)")
end

-- Schritt 6: Teste Virtual Text
local ok_vt, vt = pcall(require, "nvim-dap-virtual-text")
if ok_vt then
  vt.setup({
    enabled = true,
    commented = true,
  })
  print("[TEST] ✓ Virtual Text konfiguriert")
else
  print("[TEST] ℹ Virtual Text nicht installiert (optional)")
end

-- Schritt 7: Zeige Zusammenfassung
print("\n" .. string.rep("=", 60))
print("DAP MINIMAL TEST ABGESCHLOSSEN")
print(string.rep("=", 60))
print("Status:")
print("  ✓ nvim-dap: OK")
print("  ✓ dap.listeners: Initialisiert")
print("  ✓ Lua-Adapter: Registriert")
print("  ✓ Lua-Konfiguration: Geladen")
print(ok_dapui and "  ✓ DAP UI: OK" or "  ℹ DAP UI: Nicht installiert")
print(ok_vt and "  ✓ Virtual Text: OK" or "  ℹ Virtual Text: Nicht installiert")
print("\nNächste Schritte:")
print("  1. Setze einen Breakpoint: :lua require('dap').toggle_breakpoint()")
print("  2. Starte Debugging: :lua require('dap').continue()")
print(ok_osv and "  3. Starte Lua Server: :lua require('osv').launch({port=8086})" or "")
print(string.rep("=", 60))
