---@module 'custom.dir_picker.config.aliases'
---@brief Named alias resolvers for directory paths.

-- 1. STATISCHE PFADE DEFINIEREN
local static_paths = {
  onboarding = [[C:\Users\StefanBartl\OneDrive - TRICENTIS\Dokumente\Onboarding]],
}

-- 2. DYNAMISCHE STANDARD-ALIASES (die immer existieren)
local M = {
  cwd = function()
    return vim.uv.cwd() or vim.fn.getcwd()
  end,

  home = function()
    return vim.uv.os_homedir() or vim.fn.expand("~")
  end,

  root = function()
    local path = vim.uv.cwd() or vim.fn.getcwd()
    while true do
      local parent = vim.fs.dirname(path)
      if parent == path then return path end
      path = parent
    end
  end,

  git = function()
    local found = vim.fs.find(".git", {
      upward = true,
      type = "directory",
      path = vim.uv.cwd() or vim.fn.getcwd(),
    })
    if found and found[1] then
      return vim.fs.dirname(found[1])
    end
    return vim.uv.cwd() or vim.fn.getcwd()
  end,
}

-- 3. NUR EXISTIERENDE PFADE HINZUFÜGEN
for alias_name, raw_path in pairs(static_paths) do
  local expanded_path = vim.fn.expand(raw_path)

  -- Wir prüfen DIREKT beim Laden, ob der Pfad existiert
  if vim.uv.fs_stat(expanded_path) then
    -- Nur wenn er existiert, fügen wir die Funktion zu M hinzu
    M[alias_name] = function()
      return expanded_path
    end
  end
end

return M
