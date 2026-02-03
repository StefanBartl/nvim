#!/usr/bin/env lua

-- Enhanced diagnostic script for nvim-cmp + LSP
-- Run: :luafile %

local function test_completion()
  print("=== Enhanced nvim-cmp + LSP Diagnostic ===\n")

  -- Test 1: Is cmp loaded?
  local cmp_loaded = package.loaded["cmp"]
  if cmp_loaded then
    print("✅ nvim-cmp is LOADED")
  else
    print("❌ nvim-cmp is NOT loaded!")
    return
  end

  -- Test 2: Is cmp_nvim_lsp loaded?
  local cmp_lsp_loaded = package.loaded["cmp_nvim_lsp"]
  if cmp_lsp_loaded then
    print("✅ cmp-nvim-lsp is LOADED")
  else
    print("❌ cmp-nvim-lsp is NOT loaded!")
    return
  end

  -- Test 3: Check cmp config AND sources
  local cmp = require("cmp")
  local config = cmp.get_config()

  if not (config and config.sources) then
    print("❌ cmp.setup() was NEVER called or failed!")
    return
  end

  print("✅ cmp.setup() was called")

  -- 🔴 KRITISCH: Sources anzeigen!
  local has_sources = false
  print("\n📋 Configured sources:")

  for group_idx, source_group in ipairs(config.sources) do
    if type(source_group) == "table" and #source_group > 0 then
      has_sources = true
      for src_idx, source in ipairs(source_group) do
        local prio = source.priority or "default"
        print(string.format("   %d.%d: %s (priority: %s)",
          group_idx, src_idx, source.name, prio))
      end
    end
  end

  if not has_sources then
    print("   ❌ NO SOURCES! This is the problem!")
    print("   → nvim-cmp loaded but sources not registered")
    print("   → This happens when cmp loads AFTER LSP")
    return
  end

  -- Test 4: Check LSP capabilities
  local ok_caps, caps_mod = pcall(require, "lsp.core.capabilities")
  if ok_caps and type(caps_mod.get) == "function" then
    local caps = caps_mod.get()
    if caps.textDocument and caps.textDocument.completion then
      print("\n✅ LSP completion capabilities present")

      -- Show completion item details
      local comp = caps.textDocument.completion.completionItem
      if comp then
        print("   • snippetSupport:", comp.snippetSupport or false)
        print("   • commitCharactersSupport:", comp.commitCharactersSupport or false)
        print("   • resolveSupport:", comp.resolveSupport and "yes" or "no")
      end
    else
      print("\n❌ LSP completion capabilities MISSING!")
    end
  end

  -- Test 5: Check active LSP clients
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients > 0 then
    print(string.format("\n✅ %d LSP client(s) attached:", #clients))
    for _, client in ipairs(clients) do
      local caps = client.server_capabilities
      local has_completion = caps and caps.completionProvider
      print(string.format("   • %s: %s",
        client.name,
        has_completion and "HAS completion" or "NO completion"))

      if has_completion and type(caps.completionProvider) == "table" then
        local triggers = caps.completionProvider.triggerCharacters
        if triggers and #triggers > 0 then
          print(string.format("     Triggers: %s", table.concat(triggers, ", ")))
        end
      end
    end
  else
    print("\n⚠️  No LSP clients attached to current buffer")
  end

  -- Test 6: Check completeopt
  print("\n⚙️  Completion settings:")
  print("   completeopt:", vim.o.completeopt)
  if not vim.o.completeopt:match("menu") then
    print("   ⚠️  'menu' missing in completeopt!")
  end

  -- Test 7: Manual trigger test
  print("\n🧪 Manual completion test:")
  print("   1. Open a Lua file (not this one)")
  print("   2. Enter insert mode")
  print("   3. Type: vim.api.nvim_")
  print("   4. Press: <C-Space>")
  print("   5. Expected: Menu with nvim_buf_get_lines etc.")

  print("\n=== End Diagnostic ===")
end

-- Run the test
local ok, err = pcall(test_completion)
if not ok then
  print("\n❌ TEST FAILED WITH ERROR:")
  print(err)
end
