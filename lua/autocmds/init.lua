---@module 'autocmds'
--- Initialize module for 'autocmds'

---AUDIT: Wie im git abschnitt modularisieren

------------------------------------------------------
--- General
------------------------------------------------------

require("autocmds.general").enable({
	kitty = {
		enable        = true, -- Sets Kitty padding/margin to compact values on VimEnter and restores them on VimLeavePre.
		enter_padding = 0,
		enter_margin  = 0,
		leave_padding = 20,
		leave_margin  = 10,
	},
	auto_mkdir = {
		enable = true, -- Creates missing parent directories on BufWritePre, optionally skipping URL/remote-like paths.
		skip_remote = true,
	},
	nvdash = {
		enable = true, -- When the last listed buffer in the current tab closes, executes the given dashboard command.
		cmd = "Nvdash",
		is_listed_only = true,
	},
	cursorline = {
		enable = false, -- Toggles the local 'cursorline' option on focus/normal events and hides it on insert/leave events.
		show_events = { "InsertLeave", "WinEnter" },
		hide_events = { "InsertEnter", "WinLeave" },
	},
	last_loc = {
		enable = false, -- On BufReadPost, jumps back to the last cursor position unless the filetype is excluded.
		exclude = { "gitcommit", "commit", "gitrebase" },
	},
})


------------------------------------------------------
--- Git
------------------------------------------------------

local ok_g, git = pcall(require, "autocmds.git")
if ok_g then git.enable( true ) end

------------------------------------------------------
--- Markdown
------------------------------------------------------

require("autocmds.markdown").enable({
	wrap_key = {
		enable = true, -- Registers a buffer-local mapping in Markdown buffers that atomically wraps <cword> as [word]().
		key = "<leader>[",
		description = "Wrap current word in Markdown link syntax",
		pattern = "markdown",
		only_modifiable = true,
	},
	goto_file = {
		enable = true,                 -- Overrides "gf" in Markdown: follows inline/reference links, opens URLs, resolves relative paths; otherwise falls back.
		debug = false,                 -- If true: emits step-by-step resolution messages via vim.notify.
		pattern = "markdown",
		enable_windows_opener = false, -- Default: Linux/macOS only; optionally enable a Windows opener.
		-- open_cmd_mac  = { "open", "<url>" },
		-- open_cmd_unix = { "xdg-open", "<url>" },
	},
})


------------------------------------------------------
--- Terminals
------------------------------------------------------

require("autocmds.terminals").enable({
	numbers = {
		enable = true, -- On terminal open, turns off local 'number' and 'relativenumber' to declutter terminal panes.
		events = { "TermOpen" },
	},
	kitty = {
		enable        = true, -- In Kitty, applies compact padding/margin on VimEnter and restores defaults on VimLeavePre.
		enter_padding = 0,
		enter_margin  = 0,
		leave_padding = 20,
		leave_margin  = 10,
	},
	auto_insert = {
		enable = false, -- Automatically enters Insert mode in terminal buffers; add "TermEnter" to events if desired.
		events = { "TermOpen" },
	},
})


------------------------------------------------------
--- Text
------------------------------------------------------

require("autocmds.text").enable({
	trim_trailing = {
		enable = true, -- On BufWritePre, removes trailing whitespace at end-of-line in normal, modifiable buffers.
		pattern = "*",
		ignore_filetypes = { "diff" },
		ignore_buftypes = { "nofile", "prompt" },
		only_modifiable = true,
		only_normal_bufs = true,
	},
	trim_blank = {
		enable = true, -- On BufWritePre, cleans whitespace-only (blank) lines; restores the exact cursor position afterwards.
		pattern = "*",
		preserve_cursor = true,
		ignore_filetypes = { "diff" },
		ignore_buftypes = { "nofile", "prompt" },
		only_modifiable = true,
		only_normal_bufs = true,
	},
	last_loc = {
		enable = true, -- On BufReadPost, jumps back to the last saved cursor position unless filetype is excluded.
		pattern = "*",
		exclude = { "commit", "gitrebase", "xxd" },
		min_line = 1,
	},
})
