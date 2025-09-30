---@module 'autocmds.git'
--- Git-focused autocommands with feature flags and safe fallbacks.
--- Features:
---   1) conflicts_qf    – On startup (and/or focus) detect unresolved merge conflicts and populate Quickfix
---   2) commit_ft       – Git commit message buffer tweaks (spell, textwidth, colorcolumn, formatting)
---   3) conflict_marks  – Highlight Git conflict markers <<<<<<<, =======, >>>>>> in any buffer
---   4) gitsigns_refresh – Periodically refresh gitsigns when (re)entering Neovim or focusing it
---   5) blame_on_hold   – Show inline blame on CursorHold via gitsigns (non-intrusive)
--- Enable with `require('autocmds.git').enable(cfg)`.


---@class GitAutoCmds
local M = {}

local api, fn = vim.api, vim.fn

-- Helpers ---------------------------------------------------------------------

--- Create/clear a namespaced augroup.
---@param name string
---@return integer
local function augroup(name)
	return api.nvim_create_augroup("git_autocmds_" .. name, { clear = true })
end

--- Normalize an event list.
---@param ev any
---@param fallback string[]
---@return string[]
local function norm_events(ev, fallback)
	if type(ev) == "table" and #ev > 0 then return ev end
	return fallback
end

--- Return true if CWD is inside a Git work-tree.
---@param git_cmd string
---@return boolean
local function in_git_repo(git_cmd)
	local out = fn.system(git_cmd .. " rev-parse --is-inside-work-tree 2>/dev/null")
	return type(out) == "string" and out:match("^true") ~= nil
end

--- Return true if current buffer should be processed given ignore rules.
---@param ignore_buftypes string[]|nil
---@return boolean
local function normal_buf_allowed(ignore_buftypes)
  local bt = vim.bo.buftype or ""
  if ignore_buftypes and vim.tbl_contains(ignore_buftypes, bt) then return false end
  return bt == "" or bt == "acwrite"
end

-- Defaults --------------------------------------------------------------------

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
    enable = true,
    delay = 0,
    hl_prev = "Comment",
    virt_priority = 1000,
    max_len = 160,
    git_cmd = "git",
    ignore_buftypes = { "nofile", "prompt", "terminal" },
  },
}

-- Private: ephemeral virtual text ns/cleanup for line_diff_on_hold ------------
local NS_LINE_DIFF = api.nvim_create_namespace("git_line_diff_preview")

local function clear_line_diff(buf)
  if api.nvim_buf_is_valid(buf) then
    api.nvim_buf_clear_namespace(buf, NS_LINE_DIFF, 0, -1)
  end
end

-- Public API ------------------------------------------------------------------

--- Enable git-related autocommands per feature.
---@param cfg GitAutoCmdsCfg|boolean|nil  -- Backward compatible: true/false toggles everything; table for granular config.
---@return nil
function M.enable(cfg)
	if not cfg or cfg == false then return end
	if cfg == true then
		---@diagnostic disable-next-line
		cfg = {}
	end
	---@type GitAutoCmdsCfg
	cfg = vim.tbl_deep_extend("force", vim.deepcopy(Defaults), cfg or {})

	-- 1) Conflicts → Quickfix ---------------------------------------------------
	-- Description: Scan for unresolved conflicts (diff-filter=U by default) and populate quickfix.
	if cfg.conflicts_qf.enable then
		api.nvim_create_autocmd(norm_events(cfg.conflicts_qf.events, { "VimEnter" }), {
			group = augroup("conflicts_qf"),
			callback = function()
				local git = cfg.conflicts_qf.git_cmd or "git"
				if not in_git_repo(git) then
					return
				end
				local filter = cfg.conflicts_qf.diff_filter or "U"
				local cmd = string.format("%s diff --name-only --diff-filter=%s", git, filter)
				---@type string[]
				local conflicts = fn.systemlist(cmd)
				if type(conflicts) ~= "table" or #conflicts == 0 then
					return
				end
				---@type table[]
				local qf = {}
				for _, file in ipairs(conflicts) do
					qf[#qf + 1] = { filename = file, lnum = 1, col = 1, text = "Git conflict" }
				end
				fn.setqflist(qf, "r")
				if cfg.conflicts_qf.open_qf ~= false then
					vim.cmd("copen")
				end
				if cfg.conflicts_qf.notify ~= false then
					vim.notify("Git conflicts detected:\n" .. table.concat(conflicts, "\n"), vim.log.levels.WARN)
				end
			end,
			desc = "Git: populate quickfix with unresolved conflicts",
		})
	end

	-- 2) Git commit buffer tuning ----------------------------------------------
	-- Description: On FileType gitcommit, apply sane defaults for writing commit messages.
	if cfg.commit_ft.enable then
		api.nvim_create_autocmd("FileType", {
			group = augroup("commit_ft"),
			pattern = "gitcommit",
			callback = function()
				if cfg.commit_ft.spell ~= false then vim.opt_local.spell = true end
				if cfg.commit_ft.textwidth then vim.opt_local.textwidth = cfg.commit_ft.textwidth end
				if cfg.commit_ft.colorcolumn then vim.opt_local.colorcolumn = cfg.commit_ft.colorcolumn end
				if cfg.commit_ft.formatoptions then vim.opt_local.formatoptions = cfg.commit_ft.formatoptions end
				if cfg.commit_ft.start_in_insert then
					vim.schedule(function()
						if vim.bo.filetype == "gitcommit" then vim.cmd("startinsert") end
					end)
				end
			end,
			desc = "Git: commit message buffer settings",
		})
	end

	-- 3) Conflict marker highlights --------------------------------------------
	-- Description: Highlight <<<<<<< / ======= / >>>>>>> in any buffer. Cleared per-window on leave.
	if cfg.conflict_marks.enable then
		api.nvim_create_autocmd("BufWinEnter", {
			group = augroup("conflict_marks_on"),
			callback = function()
				-- Three matches with dedicated highlight groups; store ids in w: scope to clear later.
				local id_a = vim.fn.matchadd(cfg.conflict_marks.hl_a or "DiffDelete", [[^<<<<<<< .\+$]])
				local id_b = vim.fn.matchadd(cfg.conflict_marks.hl_b or "DiffChange", [[^=======\s*$]])
				local id_c = vim.fn.matchadd(cfg.conflict_marks.hl_c or "DiffAdd", [[^>>>>>>> .\+$]])
				vim.w._git_conflict_match_ids = { id_a, id_b, id_c }
			end,
			desc = "Git: highlight conflict markers",
		})
		api.nvim_create_autocmd("BufWinLeave", {
			group = augroup("conflict_marks_off"),
			callback = function()
				local ids = vim.w._git_conflict_match_ids
				if type(ids) == "table" then
					for _, id in ipairs(ids) do
						pcall(vim.fn.matchdelete, id)
					end
				end
				vim.w._git_conflict_match_ids = nil
			end,
			desc = "Git: clear conflict marker highlights",
		})
	end

	-- 4) Gitsigns refresh on focus/enter ---------------------------------------
	-- Description: Refresh gitsigns to keep hunks up-to-date when focusing/entering buffers.
	if cfg.gitsigns_refresh.enable then
		api.nvim_create_autocmd(norm_events(cfg.gitsigns_refresh.events, { "BufEnter", "FocusGained" }), {
			group = augroup("gitsigns_refresh"),
			callback = function()
				local ok, gs = pcall(require, "gitsigns")
				if ok and gs.refresh then
					pcall(gs.refresh)
				end
			end,
			desc = "Git: refresh gitsigns on focus/enter",
		})
	end

	-- 5) Inline blame on CursorHold (gitsigns) ---------------------------------
	-- Description: Show ephemeral inline blame when the cursor rests, for normal file buffers.
	if cfg.blame_on_hold.enable then
		api.nvim_create_autocmd("CursorHold", {
			group = augroup("blame_on_hold"),
			callback = function()
				local bt = vim.bo.buftype
				if cfg.blame_on_hold.ignore_buftypes and vim.tbl_contains(cfg.blame_on_hold.ignore_buftypes, bt) then
					return
				end
				local ok, gs = pcall(require, "gitsigns")
				if not ok or not gs.blame_line then return end
				local function run()
					pcall(gs.blame_line, {
						full = false,
						ignore_whitespace = true,
						virt_text = (cfg.blame_on_hold.virt ~= false),
					})
				end
				local delay = tonumber(cfg.blame_on_hold.delay or 0) or 0
				if delay > 0 then
					vim.defer_fn(run, delay)
				else
					run()
				end
			end,
			desc = "Git: inline blame on CursorHold (gitsigns)",
		})
	end

	  -- 6) Line diff on CursorHold -----------------------------------------------
  -- Behavior:
  --   • If the cursor line belongs to a gitsigns hunk → call `preview_hunk_inline()` (shows +/- inline).
  --   • Else → fetch the last-change commit for this line and show that line’s content as “previous:” virtual text.
  if cfg.line_diff_on_hold.enable then
    api.nvim_create_autocmd("CursorHold", {
      group = augroup("line_diff_on_hold"),
      callback = function()
        local buf = api.nvim_get_current_buf()
        if not normal_buf_allowed(cfg.line_diff_on_hold.ignore_buftypes) then return end
        if not vim.bo[buf].modifiable and not vim.bo[buf].readonly then return end

        local git = cfg.line_diff_on_hold.git_cmd or "git"
        if not in_git_repo(git) then return end

        local function run()
          clear_line_diff(buf)

          -- Try gitsigns hunk preview first (covers uncommitted changes nicely).
          local ok_gs, gs = pcall(require, "gitsigns")
          if ok_gs then
            -- `preview_hunk_inline` shows inline +/- for the current hunk if any.
            if gs.preview_hunk_inline then
              local ok_inline = pcall(gs.preview_hunk_inline)
              if ok_inline then
                -- Also clear when moving away so the inline preview doesn’t linger forever.
                api.nvim_create_autocmd({ "CursorMoved", "BufHidden", "BufLeave", "WinLeave" }, {
                  group = augroup("line_diff_on_hold_clear_inline"),
                  once = true,
                  callback = function() clear_line_diff(buf) end,
                })
                return
              end
            end
          end

          -- If there is no hunk at the line, show the “last-change commit” version of this line.
          local file = fn.expand("%:p")
          if file == "" then return end
          local row = api.nvim_win_get_cursor(0)[1]

          -- 1) Get the commit that last touched this exact line.
          --    Using porcelain blame to obtain the commit hash. We keep it simple: no -M/-C detection to stay fast.
          local blame = fn.systemlist(string.format(
            [[%s blame -L %d,%d --porcelain -- %s]],
            git, row, row, fn.fnameescape(file)
          ))
          if type(blame) ~= "table" or #blame == 0 then return end

          -- First line of porcelain blame starts with "<commit> <orig_lineno> <lineno> <num_lines>"
          local first = blame[1] or ""
          local commit = first:match("^([0-9a-fA-F]+)%s")
          if not commit or #commit < 7 then return end

          -- 2) Extract the line text from that commit’s version of the file.
          --    Note: We use the version at the last-change commit (not its parent). This is a pragmatic approximation.
          local show = fn.systemlist(string.format(
            [[%s show %s:%s]],
            git, commit, fn.fnameescape(fn.fnamemodify(file, ":."))  -- path relative to repo root works best
          ))
          if type(show) ~= "table" or #show == 0 then return end

          local prev_line = show[row] or ""
          if prev_line == "" then
            -- If the file layout changed, we fall back to showing the first non-empty match nearby.
            for i = math.max(1, row - 2), math.min(#show, row + 2) do
              if show[i] and show[i] ~= "" then prev_line = show[i]; break end
            end
          end

          -- 3) Render as right-side virtual text (truncated), labeled as “prev: …”.
          local maxlen = tonumber(cfg.line_diff_on_hold.max_len or 160) or 160
          local txt = prev_line:gsub("\t", "  ")
          if vim.fn.strdisplaywidth(txt) > maxlen then
            txt = txt:sub(1, maxlen - 1) .. "…"
          end

          local hl = cfg.line_diff_on_hold.hl_prev or "Comment"
          local virt_prio = tonumber(cfg.line_diff_on_hold.virt_priority or 1000) or 1000

          api.nvim_buf_set_extmark(buf, NS_LINE_DIFF, row - 1, -1, {
            virt_text = { { "  prev: ", hl }, { txt, hl } },
            virt_text_pos = "eol",
            hl_mode = "combine",
            priority = virt_prio,
          })

          -- 4) Auto-clear on movement or context switch.
          api.nvim_create_autocmd({ "CursorMoved", "BufHidden", "BufLeave", "WinLeave" }, {
            group = augroup("line_diff_on_hold_clear"),
            once = true,
            callback = function() clear_line_diff(buf) end,
          })
        end

        local delay = tonumber(cfg.line_diff_on_hold.delay or 0) or 0
        if delay > 0 then vim.defer_fn(run, delay) else run() end
      end,
      desc = "Git: inline line diff preview on CursorHold",
    })
  end
end

return M
