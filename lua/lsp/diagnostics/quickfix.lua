---@module 'lsp.diagnostics.quickfix'
--- Push workspace/buffer diagnostics to quickfix or location list.
--- Compatible with Neovim 0.10 (two-arg setloclist) and 0.11+ (single-arg).

---@class Lsp.Diagnostics.Qf
local M = {}

---@type boolean|nil
local SETLOCLIST_TAKES_TWO_ARGS = nil

---@param s string|integer|nil
---@return integer|nil
local function to_numeric_severity(s)
  if type(s) == "number" then
    return s
  end
  if type(s) ~= "string" then
    return nil
  end
  local v = s:lower()
  if v == "" or v == "all" then
    return nil
  end
  if v == "error" or v == "err" then
    return vim.diagnostic.severity.ERROR
  end
  if v == "warn" or v == "warning" then
    return vim.diagnostic.severity.WARN
  end
  if v == "info" then
    return vim.diagnostic.severity.INFO
  end
  if v == "hint" then
    return vim.diagnostic.severity.HINT
  end
  return nil
end

---@param opts table
---@return nil
local function call_setloclist(opts)
  if SETLOCLIST_TAKES_TWO_ARGS == nil then
    local ok = pcall(vim.diagnostic.setloclist, 0, { open = false })
    SETLOCLIST_TAKES_TWO_ARGS = ok
  end
  if SETLOCLIST_TAKES_TWO_ARGS then
    local win = opts.win_id or 0
    local copy = vim.tbl_extend("force", {}, opts)
    copy.win_id = nil
    ---@diagnostic disable-next-line param-type-mismatch
    vim.diagnostic.setloclist(win, copy)
  else
    vim.diagnostic.setloclist(opts)
  end
end

---@param opts Lsp.Diagnostics.QfOpts|nil
---@return nil
function M.to_qf(opts)
  opts = opts or {}
  local sev = to_numeric_severity(opts.severity)

  local qfopts = {
    open = (opts.open ~= false),
  }
  if opts.bufnr ~= nil then
    qfopts.bufnr = opts.bufnr
  end
  if opts.namespace ~= nil then
    qfopts.namespace = opts.namespace
  end
  if sev ~= nil then
    qfopts.severity = sev
  end

  vim.diagnostic.setqflist(qfopts)
end

---@param opts Lsp.Diagnostics.QfOpts|nil
---@return nil
function M.to_loc(opts)
  opts = opts or {}
  local sev = to_numeric_severity(opts.severity)

  local locopts = {
    open = (opts.open ~= false),
    win_id = opts.win_id or 0,
  }
  if opts.bufnr ~= nil then
    locopts.bufnr = opts.bufnr
  end
  if opts.namespace ~= nil then
    locopts.namespace = opts.namespace
  end
  if sev ~= nil then
    locopts.severity = sev
  end

  call_setloclist(locopts)
end

---@return nil
function M.enable_commands()
  if vim.g._diagnostics_qf_cmds == 1 then
    return
  end
  vim.g._diagnostics_qf_cmds = 1

  vim.api.nvim_create_user_command("DiagWQF", function(ctx)
    M.to_qf({ severity = ctx.args })
  end, {
    nargs = "?",
    complete = function()
      return { "error", "warn", "info", "hint", "all" }
    end,
  })

  vim.api.nvim_create_user_command("DiagLoc", function(ctx)
    M.to_loc({ severity = ctx.args })
  end, {
    nargs = "?",
    complete = function()
      return { "error", "warn", "info", "hint", "all" }
    end,
  })
end

--- Navigation helpers for quickfix list.
--- Uses :cnext / :cprev to jump between entries.
--- pcall is used to avoid errors when the list is empty.
---@return nil
function M.qf_next()
  pcall(vim.cmd, "cnext")
end

---@return nil
function M.qf_prev()
  pcall(vim.cmd, "cprev")
end

---@param map function|nil
---@return nil
function M.enable_keymaps(map)
  if not map then
    map = vim.keymap.set
  end

  map("n", "<leader>wq", function()
    M.to_qf({ open = true })
  end, { desc = "Diagnostics → Quickfix (workspace)" })

  map("n", "<leader>lq", function()
    M.to_loc({ open = true, win_id = 0 })
  end, { desc = "Diagnostics → Loclist (buffer)" })

  map("n", "]q", function()
    M.qf_next()
  end, { desc = "Quickfix → next entry" })

  map("n", "[q", function()
    M.qf_prev()
  end, { desc = "Quickfix → previous entry" })
end

---@return nil
function M.enable_usercmds_and_keymaps()
  M.enable_commands()
  M.enable_keymaps()
end

return M
