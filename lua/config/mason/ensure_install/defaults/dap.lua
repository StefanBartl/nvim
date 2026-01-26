---@module 'config.mason.ensure_install.defaults.dap'
-- =====================================================================================
-- Tool set (defaults): true = ensure install, false = ignore
-- =====================================================================================

---@type Cfg.Mason.EnsureMap
return {
  ["node-debug2-adapter"] = false,
  ["java-language-server"] = false,
  ["php-debug-adapter"] = true,
  ["netcoredbg"] = true,
  ["js-debug-adapter"] = true,
  ["java-test"] = true,
  ["java-debug-adapter"] = true,
  ["firefox-debug-adapter"] = true,
  ["go-debug-adapter"] = true,
  ["bash-debug-adapter"] = true,
}
