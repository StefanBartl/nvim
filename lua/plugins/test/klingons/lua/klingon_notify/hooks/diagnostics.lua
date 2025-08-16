---@module 'klingon_notify.hooks.diagnostics'
--- Auto-trigger Klingon shouts when diagnostics change.
--- Keeps a per-buffer "worst severity" and shouts only on state transitions.

---@class KlingonDiagHookCfg
---@field debounce_ms integer

local M = {}

---@type table<integer, integer>
local last_max = {}

---@type integer|nil
local aug

---@type boolean
local enabled = false

--- Compute max severity for a buffer (lower number = worse)
---@param bufnr integer
---@return integer|nil
local function max_severity(bufnr)
  local items = vim.diagnostic.get(bufnr)
  local worst ---@type integer|nil
  for _, d in ipairs(items) do
    if not worst or d.severity < worst then
      worst = d.severity
    end
  end
  return worst
end

---@param sev integer|nil
local function shout_for(sev)
  local ok, KN = pcall(require, "klingon_notify")
  if not ok then return end
  if sev == nil then
    KN.success("No diagnostics")
    return
  end
  if sev == vim.diagnostic.severity.ERROR then
    KN.error("Diagnostics updated")
  elseif sev == vim.diagnostic.severity.WARN then
    KN.warn("Diagnostics updated")
  else
    KN.info("Diagnostics updated")
  end
end

--- Debounced reaction for a buffer
---@param bufnr integer
---@param debounce integer
local function react(bufnr, debounce)
  vim.defer_fn(function()
    if not enabled then return end
    local worst = max_severity(bufnr)
    if last_max[bufnr] ~= worst then
      last_max[bufnr] = worst
      shout_for(worst)
    end
  end, debounce)
end

--- Enable diagnostics hook.
---@param cfg KlingonDiagHookCfg
---@return boolean
function M.enable(cfg)
  if enabled then return true end
  local d = cfg and cfg.debounce_ms or 100
  aug = vim.api.nvim_create_augroup("KlingonDiagHook", { clear = true })
  vim.api.nvim_create_autocmd({ "DiagnosticChanged", "BufEnter" }, {
    group = aug,
    callback = function(args)
      local bufnr = args.buf or vim.api.nvim_get_current_buf()
      react(bufnr, d)
    end,
  })
  enabled = true
  return true
end

--- Disable diagnostics hook and clear state.
function M.disable()
  if aug then pcall(vim.api.nvim_del_augroup_by_id, aug) end
  aug = nil
  last_max = {}
  enabled = false
end

return M
