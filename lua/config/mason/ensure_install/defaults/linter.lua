---@module 'config.mason.ensure_install.defaults.linter'
-- =====================================================================================
-- Tool set (defaults): true = ensure install, false = ignore
-- =====================================================================================

---@type Cfg.Mason.EnsureMap
return {
  ["yamllint"] = true,
  ["systemdlint"] = true,
  ["swiftlint"] = true,
  ["sqlfluff"] = true,
  ["pymarkdownlnt"] = true,
  ["phpcs"] = true,
  ["phpmd"] = true,
  ["markuplint"] = true,
  ["markdownlint-cli2"] = true,
  ["luacheck"] = true,
  ["jsonlint"] = true,
  ["htmlhint"] = true,
  ["golangci-lint"] = true,
  ["eslint_d"] = true,
  ["cmakelint"] = true,
  ["cmakelang"] = true,
  ["ast-grep"] = true,
  ["markdownlint"] = true,
}
