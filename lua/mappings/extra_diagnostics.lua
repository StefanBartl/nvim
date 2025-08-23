---@module 'mappings.diagnostics'
--- Small helpers for navigating LSP diagnostics (next/prev) with keymaps and user commands.
--- Provides filtering by severity and optional workspace-wide navigation via quickfix.

---@class DiagNav
---@field severity_map table<string, integer>  -- Maps strings like "error" to vim.diagnostic.severity.ERROR
---@field default_opts table                   -- Default opts passed to vim.diagnostic.goto_next/prev
local M = {}

---@type table<string, integer>
M.severity_map = {
  -- Map common variants (lowercase, uppercase) to the numeric severity constants.
  error = vim.diagnostic.severity.ERROR,
  err   = vim.diagnostic.severity.ERROR,
  e     = vim.diagnostic.severity.ERROR,

  warn  = vim.diagnostic.severity.WARN,
  warning = vim.diagnostic.severity.WARN,
  w     = vim.diagnostic.severity.WARN,

  info  = vim.diagnostic.severity.INFO,
  i     = vim.diagnostic.severity.INFO,

  hint  = vim.diagnostic.severity.HINT,
  h     = vim.diagnostic.severity.HINT,
}

---@type table
M.default_opts = {
  -- Set 'wrap' to true to cycle at file ends; false to stop at boundaries.
  wrap = true,
  -- 'float' can be bool or table; here we open a minimal floating window when landing on a diagnostic.
  float = { border = "rounded", source = "if_many", focusable = false },
  -- 'severity' can be a single level or a table { min=..., max=... }.
  -- Left nil here; commands/mappings may override.
}

--- Parse a user-provided severity string into the numeric constant.
--- Falls back to nil if unknown.
---@param s string|nil
---@return integer|nil
local function parse_severity(s)
  if type(s) ~= "string" then return nil end
  return M.severity_map[string.lower(s)]
end

--- Jump to next diagnostic in current buffer, with optional severity filter.
---@param severity integer|nil
---@param opts table|nil
---@return nil
function M.goto_next(severity, opts)
  opts = opts or {}
  local o = vim.tbl_extend("force", M.default_opts, opts or {})
  if severity then o.severity = severity end
  -- Use builtin navigator; respects current window/buffer.
  vim.diagnostic.jump({count=1, float=true})
end

--- Jump to previous diagnostic in current buffer, with optional severity filter.
---@param severity integer|nil
---@param opts table|nil
---@return nil
function M.goto_prev(severity, opts)
  opts = opts or {}
  local o = vim.tbl_extend("force", M.default_opts, opts or {})
  if severity then o.severity = severity end
  vim.diagnostic.jump({count=-1, float=true})
end

--- Build quickfix from all workspace diagnostics and jump to next entry.
--- Useful if one wants to navigate across multiple open buffers.
---@param severity integer|nil
---@return nil
function M.workspace_next(severity)
  -- Collect all diagnostics visible to the client(s).
  local all = vim.diagnostic.get(nil, { severity = severity }) -- nil buffer = all buffers
  -- Convert to quickfix items
  ---@type table[]
  local qf = { [#all] = {} } -- pre-size for LuaLS and GC-friendliness
  for i, d in ipairs(all) do
    qf[i] = {
      bufnr = d.bufnr,
      lnum  = d.lnum + 1,
      col   = d.col + 1,
      text  = (d.source and ("[" .. d.source .. "] ") or "") .. (d.message or ""),
      type  = (d.severity == vim.diagnostic.severity.ERROR and "E")
           or (d.severity == vim.diagnostic.severity.WARN  and "W")
           or (d.severity == vim.diagnostic.severity.INFO  and "I")
           or "H",
    }
  end
  vim.fn.setqflist({}, "r", { title = "Workspace Diagnostics", items = qf })
  if #qf > 0 then
    vim.cmd("cnext")
  else
    vim.notify("No diagnostics found (workspace)", vim.log.levels.INFO)
  end
end

--- Build quickfix from all workspace diagnostics and jump to previous entry.
---@param severity integer|nil
---@return nil
function M.workspace_prev(severity)
  local all = vim.diagnostic.get(nil, { severity = severity })
  if #all == 0 then
    vim.notify("No diagnostics found (workspace)", vim.log.levels.INFO)
    return
  end
  -- Ensure quickfix is populated (reuse from workspace_next for simplicity)
  M.workspace_next(severity)
  vim.cmd("cprevious")
end

--- Create user commands with argument completion for severities.
---@return nil
function M.create_user_commands()
  -- :DiagNext[!] [severity]
  -- Without bang: current buffer; With bang: workspace-wide via quickfix.
  vim.api.nvim_create_user_command("DiagNext", function(ctx)
    local sev = parse_severity(ctx.args)
    if ctx.bang then
      M.workspace_next(sev)
    else
      M.goto_next(sev)
    end
  end, {
    nargs = "?",
    bang = true,
    complete = function(_, line)
      -- Offer severity completions after the command word.
      local items = { "error", "warn", "info", "hint" }
      local _, _, prefix = string.find(line, "%s+(%w*)$")
      if not prefix or prefix == "" then return items end
      local out = {}
      for _, it in ipairs(items) do
        if vim.startswith(it, prefix) then table.insert(out, it) end
      end
      return out
    end,
    desc = "Jump to next diagnostic (optional: error|warn|info|hint). Use ! for workspace-wide.",
  })

  -- :DiagPrev analog
  vim.api.nvim_create_user_command("DiagPrev", function(ctx)
    local sev = parse_severity(ctx.args)
    if ctx.bang then
      M.workspace_prev(sev)
    else
      M.goto_prev(sev)
    end
  end, {
    nargs = "?",
    bang = true,
    complete = function(_, line)
      local items = { "error", "warn", "info", "hint" }
      local _, _, prefix = string.find(line, "%s+(%w*)$")
      if not prefix or prefix == "" then return items end
      local out = {}
      for _, it in ipairs(items) do
        if vim.startswith(it, prefix) then table.insert(out, it) end
      end
      return out
    end,
    desc = "Jump to previous diagnostic (optional: error|warn|info|hint). Use ! for workspace-wide.",
  })
end

--- Install keymaps for normal/visual/operator-pending modes.
--- Uses standard ]d / [d variants and additional leader-based maps.
---@return nil
function M.create_keymaps()
  local map = vim.keymap.set

  -- Current buffer navigation (builtin)
  map({ "n", "x", "o" }, "]d", function() M.goto_next(nil) end, { desc = "[LSP] Next diagnostic" })
  map({ "n", "x", "o" }, "[d", function() M.goto_prev(nil) end, { desc = "[LSP] Prev diagnostic" })

  -- Severity-filtered quick access
  map({ "n", "x", "o" }, "]e", function() M.goto_next(vim.diagnostic.severity.ERROR) end, { desc = "[LSP] Next error" })
  map({ "n", "x", "o" }, "[e", function() M.goto_prev(vim.diagnostic.severity.ERROR) end, { desc = "[LSP] Prev error" })
  map({ "n", "x", "o" }, "]w", function() M.goto_next(vim.diagnostic.severity.WARN) end,  { desc = "[LSP] Next warning" })
  map({ "n", "x", "o" }, "[w", function() M.goto_prev(vim.diagnostic.severity.WARN) end,  { desc = "[LSP] Prev warning" })

  -- Leader-based mappings calling the user commands (show severity completion)
  map("n", "<leader>dn", ":DiagNext ", { desc = "[LSP] :DiagNext (type severity, Tab-complete)", silent = false })
  map("n", "<leader>dp", ":DiagPrev ", { desc = "[LSP] :DiagPrev (type severity, Tab-complete)", silent = false })

  -- Workspace-wide (across buffers) via quickfix with !
  map("n", "<leader>dN", ":DiagNext! ", { desc = "[LSP] Workspace next diagnostic (!)", silent = false })
  map("n", "<leader>dP", ":DiagPrev! ", { desc = "[LSP] Workspace prev diagnostic (!)", silent = false })
end

--- Public setup to be called from plugin init.
---@return nil
function M.setup()
  M.create_user_commands()
  M.create_keymaps()
end

return M

