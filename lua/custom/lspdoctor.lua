local M = {}

function M.check()
  print("🔎 LSP Doctor startet...")

  -- 1. Mason?
  local mason_ok = pcall(require, "mason")
  print("🔧 Mason installiert: ", mason_ok and "✔️" or "❌")

  -- 2. LSP-Client im Buffer?
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then
    print("🚫 Kein LSP für aktuellen Buffer attached.")
  else
    print("🩺 Aktive LSP(s):")
    for _, c in pairs(clients) do
      print("   - " .. c.name)
    end
  end

  -- 3. Diagnostics vorhanden?
  local diags = vim.diagnostic.get(0)
  if #diags == 0 then
    print("📭 Keine Diagnostics im aktuellen Buffer.")
  else
    print("📬 Diagnostics gefunden: " .. #diags)
  end

  -- 4. Trouble geladen?
  local trouble_ok = pcall(require, "trouble")
  print("📦 trouble.nvim geladen: ", trouble_ok and "✔️" or "❌")
end

return M