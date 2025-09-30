---@module 'autocmds.git'
--- Orchestrates all Git-related autocommands by delegating to submodules.
--- Public entrypoint: require('autocmds.git').enable(cfg)
--- Each submodule implements exactly one feature and exposes `enable(cfg)`.

---@class GitAutoCmds
local M = {}

-- Local aliases (fast access in hotpaths)
local api, fn = vim.api, vim.fn

--------------------------------------------------------------------------------
-- Helpers (kept local to orchestrator)
--------------------------------------------------------------------------------

---Create/clear a namespaced augroup.
---@param name string
---@return integer
local function augroup(name)
	return api.nvim_create_augroup("git_autocmds_" .. name, { clear = true })
end

---Normalize event configuration to a non-empty list.
---@param ev any
---@param fallback string[]
---@return string[]
local function norm_events(ev, fallback)
	if type(ev) == "table" and #ev > 0 then return ev end
	return fallback
end

---Check if current directory is inside a Git work-tree.
---@param git_cmd string
---@return boolean
local function in_git_repo(git_cmd)
	local out = fn.system((git_cmd or "git") .. " rev-parse --is-inside-work-tree 2>/dev/null")
	return type(out) == "string" and out:match("^true") ~= nil
end

---Return true if the current buffer is a "normal" file buffer (not special/ignored).
---@param ignore_buftypes string[]|nil
---@return boolean
local function normal_buf_allowed(ignore_buftypes)
	local bt = vim.bo.buftype or ""
	if ignore_buftypes and vim.tbl_contains(ignore_buftypes, bt) then return false end
	return bt == "" or bt == "acwrite"
end

---Namespace for inline virtual text previews (line_diff_on_hold).
local NS_LINE_DIFF = api.nvim_create_namespace("git_line_diff_preview")

---Clear all virtual text for the given buffer in our namespace.
---@param buf integer
---@return nil
local function clear_line_diff(buf)
	if api.nvim_buf_is_valid(buf) then
		api.nvim_buf_clear_namespace(buf, NS_LINE_DIFF, 0, -1)
	end
end

--------------------------------------------------------------------------------
-- Defaults
--------------------------------------------------------------------------------

---@type GitAutoCmdsCfg
local Defaults = {
	conflicts_qf = {
		enable = true,
		events = { "VimEnter" },
		diff_filter = "U",
		open_qf = true,
		notify = true,
		git_cmd = "git",
	},
	commit_ft = {
		enable = true,
		spell = true,
		textwidth = 72,
		colorcolumn = "73",
		formatoptions = "tcqj",
		start_in_insert = false,
	},
	conflict_marks = {
		enable = true,
		hl_a = "DiffDelete",
		hl_b = "DiffChange",
		hl_c = "DiffAdd",
	},
	gitsigns_refresh = {
		enable = true,
		events = { "BufEnter", "FocusGained" },
	},
	blame_on_hold = {
		enable = false,
		delay = 0,
		virt = true,
		ignore_buftypes = { "nofile", "prompt" },
	},
  line_diff_on_hold = {
    enable = true,                    -- master switch for this feature
    modes = "n",                      -- run in Normal+Visual; omit Insert (use "i" to include)
    delay = 3000,                      -- extra debounce (ms) beyond 'updatetime' before running
    hl_prev = "Comment",               -- highlight group for fallback EOL preview text
    virt_priority = 1000,              -- extmark virt_text priority
    max_len = 160,                     -- truncate fallback preview to this many characters
    git_cmd = "git",                   -- git executable to use
    ignore_buftypes = { "nofile", "prompt", "terminal" }, -- skip on these buftypes

    -- Filters and presentation tweaks
    only_tracked = true,               -- only run on git-tracked files (skip new/untracked)
    require_clean_buffer = false,      -- when true, skip if buffer has unsaved changes
    prefix = "previous: ",             -- prefix before fallback EOL preview text
    right_align = false,               -- when true, place virt_text with 'right_align' instead of 'eol'

    -- Event control
    -- events_override = { "CursorHold", "CursorHoldI" }, -- uncomment to fully override auto-mapped events

    -- Inline preview behavior and stability
    prefer_inline = true,              -- prefer gitsigns.preview_hunk_inline() when available
    restore_view = true,               -- save/restore winsaveview()+cursor to avoid scroll jumps
    throttle_ms = 1200,                -- min time (ms) between triggers per window to reduce re-renders
  },
}

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

-- AUDIT: disble single featujres with ...=false

---Enable git-related autocommands per feature.
---@param cfg GitAutoCmdsCfg|boolean|nil
---@return nil
function M.enable(cfg)
	if not cfg or cfg == false then return end
	if cfg == true then
		---@diagnostic disable-next-line
		cfg = {}
	end
	---@type GitAutoCmdsCfg
	cfg = vim.tbl_deep_extend("force", vim.deepcopy(Defaults), cfg or {})

	-- Shared context passed to submodules (no globals)
	local shared = {
		augroup = augroup,
		norm_events = norm_events,
		in_git_repo = in_git_repo,
		normal_buf_allowed = normal_buf_allowed,
		NS_LINE_DIFF = NS_LINE_DIFF,
		clear_line_diff = clear_line_diff,
	}

	-- Delegate to submodules (each may register its own autocmds)
	require("autocmds.git.conflicts_qf").enable(cfg.conflicts_qf, shared)
	require("autocmds.git.commit_ft").enable(cfg.commit_ft, shared)
	require("autocmds.git.conflict_marks").enable(cfg.conflict_marks, shared)
	require("autocmds.git.gitsigns_refresh").enable(cfg.gitsigns_refresh, shared)
	require("autocmds.git.blame_on_hold").enable(cfg.blame_on_hold, shared)
	if cfg.line_diff_on_hold ~= false then
		require("autocmds.git.line_diff_on_hold").enable(cfg.line_diff_on_hold, shared)
	  vim.o.updatetime = 100
	end
end

return M
