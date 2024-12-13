local M = {}

-- Führt eslint --fix auf die aktuelle Datei aus
local function run_eslint_fix()
  local file_path = vim.api.nvim_buf_get_name(0) -- Aktueller Dateipfad
  if file_path == "" then
    vim.notify("Keine Datei geöffnet!", vim.log.levels.ERROR)
    return
  end

  local cmd = "eslint --fix --config .eslintrc.js " .. vim.fn.shellescape(file_path)

  local result = vim.fn.system(cmd)

  if vim.v.shell_error ~= 0 then
    vim.notify("ESLint Fehler:\n" .. result, vim.log.levels.ERROR)
    return
  end

  vim.notify("ESLint Fix erfolgreich angewendet!", vim.log.levels.INFO)

  -- Schließe und öffne den Buffer neu
  vim.cmd("e!")
end

-- Definiere den Befehl :EslintFix
function M.setup()
  vim.api.nvim_create_user_command("EslintFix", run_eslint_fix, {})
end

return M
