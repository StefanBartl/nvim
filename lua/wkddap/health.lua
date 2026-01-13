---@module "wkddap.health"
---@brief Health check for DAP installation

local M = {}

local health = vim.health or require("health")
local start = health.start or health.report_start
local ok = health.ok or health.report_ok
local warn = health.warn or health.report_warn
local error = health.error or health.report_error
local info = health.info or health.report_info

--- Check plugin availability
---@param plugin string Plugin name
---@return boolean
local function check_plugin(plugin)
  return pcall(require, plugin)
end

--- Health check entry point
function M.check()
  start("DAP Installation")

  -- Core plugin
  if check_plugin("dap") then
    ok("nvim-dap installed")
  else
    error("nvim-dap not found", { "Install via: lazy.nvim or packer" })
  end

  -- UI plugins
  if check_plugin("dapui") then
    ok("nvim-dap-ui installed")
  else
    warn("nvim-dap-ui not found", { "Recommended for rich debugging UI" })
  end

  if check_plugin("nvim-dap-virtual-text") then
    ok("nvim-dap-virtual-text installed")
  else
    info("nvim-dap-virtual-text not found (optional)")
  end

  start("Language Adapters")

  local config = require("wkddap.config")
  local registry = require("wkddap.registry")

  local available = registry.available_languages()
  for _, lang in ipairs(available) do
    local valid, err = config.validate_adapter(lang)
    if valid then
      ok(string.format("%s: adapter available", lang))
    else
      warn(string.format("%s: %s", lang, err))
    end
  end

  start("Configuration")

  local dap_module = require("wkddap")
  if dap_module._initialized then
    ok("DAP initialized")
  else
    info("DAP not yet initialized")
  end

  local enabled = registry.enabled_languages()
  if #enabled > 0 then
    ok(string.format("Enabled languages: %s", table.concat(enabled, ", ")))
  else
    info("No languages enabled")
  end
end

return M
