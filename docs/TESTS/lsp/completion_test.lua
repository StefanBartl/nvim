-- Quick diagnostic script for nvim-cmp setup
-- Run this in Neovim with: :luafile %

local function test_completion()
  print("=== nvim-cmp Diagnostic ===\n")

  -- Test 1: Is cmp loaded?
  local cmp_loaded = package.loaded["cmp"]
  if cmp_loaded then
    print("✅ nvim-cmp is LOADED")
  else
    print("❌ nvim-cmp is NOT loaded!")
    print("   → Plugin not installed or config block missing")
    return
  end

  -- Test 2: Is cmp_nvim_lsp loaded?
  local cmp_lsp_loaded = package.loaded["cmp_nvim_lsp"]
  if cmp_lsp_loaded then
    print("✅ cmp-nvim-lsp is LOADED")
  else
    print("❌ cmp-nvim-lsp is NOT loaded!")
    print("   → Missing dependency in plugin spec")
    return
  end

  -- Test 3: Check cmp config
  local cmp = require("cmp")
  local config = cmp.get_config()

  if config and config.sources then
    print("✅ cmp.setup() was called")
    print("\n📋 Configured sources:")
    for i, source_group in ipairs(config.sources) do
      for j, source in ipairs(source_group) do
        print(string.format("   %d.%d: %s (priority: %s)",
          i, j, source.name, tostring(source.priority or "default")))
      end
    end
  else
    print("❌ cmp.setup() was NEVER called!")
    print("   → config block missing or errored")
    return
  end

  -- Test 4: Check LSP capabilities
  local ok, caps_mod = pcall(require, "lsp.core.capabilities")
  if ok and type(caps_mod.get) == "function" then
    local caps = caps_mod.get()
    if caps.textDocument and caps.textDocument.completion then
      print("✅ LSP completion capabilities present")
    else
      print("❌ LSP completion capabilities MISSING!")
    end
  else
    print("⚠️  Could not load lsp.core.capabilities")
  end

  -- Test 5: Check active LSP clients
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients > 0 then
    print(string.format("\n✅ %d LSP client(s) attached:", #clients))
    for _, client in ipairs(clients) do
      local has_completion = client.server_capabilities
        and client.server_capabilities.completionProvider
      print(string.format("   • %s: %s",
        client.name,
        has_completion and "HAS completion" or "NO completion"))
    end
  else
    print("\n⚠️  No LSP clients attached to current buffer")
  end

  -- Test 6: Try to trigger completion
  print("\n🧪 Manual completion test:")
  print("   Type in insert mode: vim.api.nvim_")
  print("   Then press: <C-Space>")
  print("   Expected: Completion menu appears")

  print("\n=== End Diagnostic ===")
end

-- Run the test
test_completion()

