---@module 'wkdoptions.hl_config.breadcrumbs'
--- Breadcrumbs orchestrator: coordinates context building and winbar rendering.
--- Lazy-loads the context module only when breadcrumbs are enabled.

local lazy = require("lib.lua.lazy")
local State = lazy.require("wkdoptions.hl_config.core.state")
local Winbar = lazy.require("wkdoptions.hl_config.breadcrumbs.winbar")
local Debounce = lazy.require("lib.nvim.debounce")

local M = {}

--- Debounce handle shared across all windows (created lazily in M.enable)
---@type { call: fun(...:any), cancel: fun() }|nil
local refresh_debounced = nil

-- Context module (lazy-loaded)
local ctx_mod = nil

--- Get context module (lazy init)
---@nodiscard
---@return table|nil
local function get_ctx()
  if not ctx_mod then
    local ok, mod = pcall(require, "wkdoptions.hl_config.breadcrumbs.ctx")
    if ok then
      ctx_mod = mod
    end
  end
  return ctx_mod
end

--- Build context (delegates to ctx module or uses fallbacks)
---@nodiscard
---@return string|nil
local function build_context()
  local ctx = get_ctx()

  if not ctx then
    -- Fallback: try LSP current function
    local s = vim.b.lsp_current_function
    if type(s) == "string" and #s > 0 then
      return s
    end
    return nil
  end

  -- Prefer modular context builder
  if type(ctx._build_context) == "function" then
    local ok, result = pcall(ctx._build_context)
    if ok and type(result) == "string" and result ~= "" then
      return result
    end
  end

  return nil
end

--- Refresh winbar for current window
---@param cfg WKDOptions.HL_CFG
---@return nil
function M.refresh_with_config(cfg)
  if not State.is_enabled("breadcrumbs") then
    vim.wo.winbar = ""
    return
  end

  Winbar.apply(cfg, build_context)
end

--- Refresh using global config (used by after_set)
---@return nil
function M.refresh()
  local C = require("wkdoptions.config")
  M.refresh_with_config(C.cfg.highlight)
end

--- Install autocmds
---@param cfg WKDOptions.HL_CFG
---@return nil
function M.enable(cfg)
  local aug = State.get_augroup("Breadcrumbs", true)

  if not State.is_enabled("breadcrumbs") then
    -- Clear all winbars
    vim.api.nvim_create_autocmd("BufEnter", {
      group = aug,
      callback = function()
        vim.wo.winbar = ""
      end,
      desc = "Clear winbar (breadcrumbs disabled)",
    })
    return
  end

  if not refresh_debounced then
    refresh_debounced = Debounce.new(function(winid, bufnr)
      -- Window/buffer may have changed between the triggering event and this
      -- deferred call firing; skip stale work instead of building context
      -- for the wrong window.
      if not vim.api.nvim_win_is_valid(winid) or not vim.api.nvim_buf_is_valid(bufnr) then
        return
      end
      if vim.api.nvim_get_current_win() ~= winid then
        return
      end
      M.refresh_with_config(cfg)
    end, 30)
  end

  -- Update on viewport/cursor changes
  vim.api.nvim_create_autocmd({ "BufEnter", "CursorMoved", "WinScrolled" }, {
    group = aug,
    callback = function()
      refresh_debounced.call(vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf())
    end,
    desc = "Update breadcrumbs on movement/scroll (debounced)",
  })

  -- Initial refresh
  M.refresh_with_config(cfg)
end

return M
