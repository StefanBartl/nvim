---@module 'ui.base_config'
--- Returns the base configuration for the UI module.

---@return table
return {
  ui = {
    statusline = {
      theme = "vscode_colored",
      -- order = { "mode", "git", "%=", "breadcrumbs", "%=", "diagnostics", "lsp", "cursor", "cwd" },
      modules = {},
    },
  },
  base46 = { transparency = false, theme_toggle = { "tokyonight", "vim_default" }, theme = "tokyonight" },
}
