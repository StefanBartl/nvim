---@module 'usrcmds.lspdoctor'

local M = {}

function M.check()
  print("🔎 LSP Doctor started...")

  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then
    print("🚫 NO LSP for actual buffer attached.")
  else
    print("🩺 Active LSP(s):")
    for _, c in pairs(clients) do
      print("   - " .. c.name)
    end
  end

  local diags = vim.diagnostic.get(0)
  if #diags == 0 then
    print("📭 NO Diagnostics in actual buffer.")
  else
    print("📬 Diagnostics found: " .. #diags)
  end

  local trouble_ok = pcall(require, "trouble")
  print("📦 trouble.nvim loaded: ", trouble_ok and "✔️" or "❌")
end

vim.api.nvim_create_user_command("LspDoctor", function()
  require("usrcmds.lspdoctor").check()
end, {})

return M
