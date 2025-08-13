---@module 'lsp.formatter.init'
---@brief Formatter API with on-save toggle, Conform fallback, and pure-LSP fallback
---@version 1.1
---@nodiscard

---@alias Bufnr integer

---@class FormatterOptions
---@field format_on_save boolean        -- default off in our setup; can be enabled at build time
---@field timeout_ms integer            -- formatting timeout in ms

---@class FormatterApi
---@field format fun(bufnr?:Bufnr):boolean          -- run a one-shot format for the given buffer (or current)
---@field enable fun():boolean                      -- enable format-on-save (creates autocmd)
---@field disable fun():boolean                     -- disable format-on-save (clears autocmd)
---@field toggle fun():boolean                      -- toggle format-on-save and return new state (true = enabled)
---@field is_enabled fun():boolean                  -- current on-save state

local M = {}

---@param opts FormatterOptions
---@return FormatterApi
function M.build(opts)
  -- Defensive defaults; we will pass format_on_save = false from lsp.init
  opts = opts or { format_on_save = false, timeout_ms = 1500 }

  local ok_conform, conform = pcall(require, "conform")
  local util_ok, util = pcall(require, "lsp.core.util")

  -- Internal state and augroup handle
  local STATE = {
    enabled = opts.format_on_save == true,
    augroup = vim.api.nvim_create_augroup("LspFormatOnSave", { clear = true }),
  }

  --- Check if any attached LSP client can format the given buffer.
  ---@param bufnr Bufnr?
  ---@return boolean
  local function can_lsp_format(bufnr)
    if not util_ok or type(util.any_client_can_format) ~= "function" then
      return false
    end
    return util.any_client_can_format(bufnr or 0)
  end

  --- One-shot format with Conform first, then LSP fallback.
  --- Always silent, returns true on success (no notify).
  ---@param bufnr Bufnr?
  ---@return boolean
  local function format(bufnr)
    bufnr = bufnr or 0

    -- Skip special buffers
    if vim.bo[bufnr].buftype ~= "" then
      return false
    end

    -- Try Conform if available
    if ok_conform and type(conform.format) == "function" then
      local ok_run = pcall(conform.format, {
        bufnr = bufnr,
        timeout_ms = opts.timeout_ms,
        lsp_fallback = can_lsp_format(bufnr),
      })
      if ok_run then
        return true
      end
      -- Fall through to LSP if Conform failed
    end

    if can_lsp_format(bufnr) then
      local ok_lsp = pcall(vim.lsp.buf.format, {
        bufnr = bufnr,
        timeout_ms = opts.timeout_ms,
      })
      return ok_lsp == true
    end

    return false
  end

  --- Create the BufWritePre autocmd if enabled; otherwise do nothing.
  local function create_autocmd_if_enabled()
    -- Clear any previous autocmds in our group first (idempotent)
    pcall(vim.api.nvim_clear_autocmds, { group = STATE.augroup })
    if not STATE.enabled then
      return
    end
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = STATE.augroup,
      callback = function(ev)
        -- Purely silent; no notify/popups
        -- Guard again for special buffers and detached cases
        if vim.bo[ev.buf].buftype ~= "" then
          return
        end
        format(ev.buf)
      end,
      desc = "LSP/Conform: format current buffer on save (toggleable)",
    })
  end

  --- Enable on-save formatting
  ---@return boolean
  local function enable()
    if STATE.enabled then
      return true
    end
    STATE.enabled = true
    create_autocmd_if_enabled()
    return true
  end

  --- Disable on-save formatting
  ---@return boolean
  local function disable()
    if not STATE.enabled then
      return true
    end
    STATE.enabled = false
    pcall(vim.api.nvim_clear_autocmds, { group = STATE.augroup })
    return true
  end

  --- Toggle on-save formatting; return new state (true = enabled)
  ---@return boolean
  local function toggle()
    STATE.enabled = not STATE.enabled
    if STATE.enabled then
      create_autocmd_if_enabled()
    else
      pcall(vim.api.nvim_clear_autocmds, { group = STATE.augroup })
    end
    return STATE.enabled
  end

  ---@return boolean
  local function is_enabled()
    return STATE.enabled
  end

  -- Initialize once according to opts
  create_autocmd_if_enabled()

  return {
    format = format,
    enable = enable,
    disable = disable,
    toggle = toggle,
    is_enabled = is_enabled,
  }
end

return M

