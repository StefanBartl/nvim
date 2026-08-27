---@module 'config.todo_comments.colors.strong'
--- Higher-contrast color overrides for todo-comments' own highlight groups,
--- keyed by the same category names `keywords/init.lua` assigns each
--- keyword to (error/warning/info/hint/default/test/audit).

local STRONG_COLORS = {

  error = { "DiagnosticError", "ErrorMsg", "#f7768e" }, -- Kräftiges Rot
  warning = { "DiagnosticWarn", "WarningMsg", "#ff9e64" }, -- Kräftiges Orange
  info = { "DiagnosticInfo", "#7aa2f7" }, -- Kräftiges Blau
  hint = { "DiagnosticHint", "#1abc9c" }, -- Kräftiges Teal
  default = { "Identifier", "#bb9af7" }, -- Kräftiges Lila
  test = { "Identifier", "#9ece6a" }, -- Kräftiges Grün
  audit = { "DiagnosticHint", "Type", "#00BFA5" }, -- Wie in keywords definiert
}

return STRONG_COLORS
