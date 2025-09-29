---@module 'usrcmds.diagnostics.qf'
--- Push workspace/buffer diagnostics to quickfix or location list.
--- Compatible with Neovim 0.10 (two-arg setloclist) and 0.11+ (single-arg).

---@class DiagnosticsQfOpts
--- Optional: open quickfix/loclist window immediately.
---@field open? boolean
--- Optional: numeric severity (vim.diagnostic.severity.*) or string ("error","warn","info","hint","all")
---@field severity? integer|string
--- Optional: target buffer; nil = all buffers (workspace) for quickfix, or current buffer for loclist.
---@field bufnr? integer
--- Optional: namespace filter; nil = all namespaces.
---@field namespace? integer
--- Optional: window id for loclist; defaults to 0 (current window).
---@field win_id? integer

---@class DiagnosticsQf
local M = {}

-- Cache the setloclist arity detection once to avoid repeated pcall overhead.
---@type boolean|nil
local SETLOCLIST_TAKES_TWO_ARGS = nil

--- Convert a user-facing string severity into numeric vim.diagnostic.severity or nil.
--- Returns:
---   "error" -> vim.diagnostic.severity.ERROR
---   "warn"  -> vim.diagnostic.severity.WARN
---   "info"  -> vim.diagnostic.severity.INFO
---   "hint"  -> vim.diagnostic.severity.HINT
---   "all" or "" or nil -> nil (no filter)
--- Any unknown string also maps to nil to avoid runtime assertions.
--- @param s string|integer|nil
--- @return integer|nil
local function to_numeric_severity(s)
	-- Already numeric → accept as-is (defensive check)
	if type(s) == "number" then
		return s
	end
	if type(s) ~= "string" then
		return nil
	end
	local v = s:lower()
	if v == "" or v == "all" then return nil end
	if v == "error" or v == "err" then return vim.diagnostic.severity.ERROR end
	if v == "warn" or v == "warning" then return vim.diagnostic.severity.WARN end
	if v == "info" then return vim.diagnostic.severity.INFO end
	if v == "hint" then return vim.diagnostic.severity.HINT end
	-- Unknown strings → nil (do not pass through to API)
	return nil
end

--- Internal helper: call setloclist with correct arity across Neovim versions.
--- On 0.10: setloclist(winid, opts)
--- On 0.11+: setloclist(opts)
--- @param opts table
--- @return nil
local function call_setloclist(opts)
	-- First-run detection using pcall; cache the outcome.
	if SETLOCLIST_TAKES_TWO_ARGS == nil then
		local ok = pcall(vim.diagnostic.setloclist, 0, { open = false })
		SETLOCLIST_TAKES_TWO_ARGS = ok
	end
	if SETLOCLIST_TAKES_TWO_ARGS then
		-- Neovim 0.10 signature
		local win = opts.win_id or 0
		local copy = vim.tbl_extend("force", {}, opts)
		copy.win_id = nil -- not part of the 0.10 signature
		---@diagnostic disable-next-line param-type-mismatch
		vim.diagnostic.setloclist(win, copy)
	else
		-- Neovim 0.11+ signature
		vim.diagnostic.setloclist(opts)
	end
end

--- Push diagnostics into the quickfix list (workspace by default).
--- @param opts DiagnosticsQfOpts|nil
--- @return nil
function M.to_qf(opts)
	opts = opts or {}
	local sev = to_numeric_severity(opts.severity)

	-- Build options table carefully and only set fields with non-nil values.
	local qfopts = {
		open = (opts.open ~= false), -- default true
	}
	if opts.bufnr ~= nil then qfopts.bufnr = opts.bufnr end
	if opts.namespace ~= nil then qfopts.namespace = opts.namespace end
	if sev ~= nil then qfopts.severity = sev end

	-- Single-argument API for setqflist since 0.9+
	vim.diagnostic.setqflist(qfopts)
end

--- Push diagnostics into the current window's location list (buffer by default).
--- @param opts DiagnosticsQfOpts|nil
--- @return nil
function M.to_loc(opts)
	opts = opts or {}
	local sev = to_numeric_severity(opts.severity)

	local locopts = {
		open = (opts.open ~= false), -- default true
		win_id = opts.win_id or 0,
	}
	-- For loclist, a missing bufnr is interpreted as "current buffer" by the API.
	if opts.bufnr ~= nil then locopts.bufnr = opts.bufnr end
	if opts.namespace ~= nil then locopts.namespace = opts.namespace end
	if sev ~= nil then locopts.severity = sev end

	call_setloclist(locopts)
end

--- Define user commands (idempotent).
--- :DiagQF [severity]    → workspace → quickfix
--- :DiagLoc [severity]   → current buffer → loclist
--- @return nil
function M.setup_commands()
	if vim.g._diagnostics_qf_cmds == 1 then return end
	vim.g._diagnostics_qf_cmds = 1

	vim.api.nvim_create_user_command("DiagQF", function(ctx)
		-- ctx.args is "" when omitted → maps to nil severity
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

function M.setup_keymaps(map)
	map("n", "<leader>wq", function()
		M.to_qf({ open = true })
	end, { desc = "Diagnostics → Quickfix (workspace)" })

	map("n", "<leader>wl", function()
		M.to_loc({ open = true, win_id = 0 })
	end, { desc = "Diagnostics → Loclist (buffer)" })
end

return M
