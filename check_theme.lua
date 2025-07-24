---@module 'check_theme'
---@diagnostic disable: param-type-mismatch

local theme = require("themes.hackthebox")

for k, v in pairs(theme.base_30 or {}) do
  if type(v) ~= "string" then
    vim.notify("Fehlende Farbe in base_30: " .. k, vim.log.levels.WARN)
  end
end

for k, v in pairs(theme.base_16 or {}) do
  if type(v) ~= "string" then
    vim.notify("Fehlende Farbe in base_16: " .. k, vim.log.levels.WARN)
  end
end
