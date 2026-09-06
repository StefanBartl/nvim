---@module 'config.todo_comments.colors.strong'
--- Higher-contrast color overrides for todo-comments' own highlight groups,
--- keyed by the same category names `keywords/init.lua` assigns each
--- keyword to (error/warning/info/hint/default/test/audit).

local STRONG_COLORS = {

  error = { "DiagnosticError", "ErrorMsg", "#f7768e" }, -- Strong red
  warning = { "DiagnosticWarn", "WarningMsg", "#ff9e64" }, -- Strong orange
  info = { "DiagnosticInfo", "#7aa2f7" }, -- Strong blue
  hint = { "DiagnosticHint", "#1abc9c" }, -- Strong teal
  default = { "Identifier", "#bb9af7" }, -- Strong purple
  test = { "Identifier", "#9ece6a" }, -- Strong green
  audit = { "DiagnosticHint", "Type", "#00BFA5" }, -- As defined in keywords
}

return STRONG_COLORS
