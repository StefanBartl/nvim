---@module 'md.tablewrap.commands'
--- User-facing commands, toggles, and autocmds for md.tablewrap.
--- This layer owns all notifications and user interactions.

local api     = vim.api

local config  = require("usrcmds.md_tablewrap.config")
local core    = require("usrcmds.md_tablewrap.core")

---@type MDTableWrapConfig
local CFG

local AUGROUP = "MDTableWrapAuto"

---@return nil
local function ensure_autocmds()
	-- Drop and recreate the group to reflect latest toggles.
	pcall(api.nvim_del_augroup_by_name, AUGROUP)
	if not CFG.on_save_enabled then return end

	local id = api.nvim_create_augroup(AUGROUP, { clear = true })
	api.nvim_create_autocmd("BufWritePre", {
		group = id,
		callback = function(args)
			local buf = args.buf
			if vim.bo[buf].filetype ~= "markdown" then return end
			if vim.wo.diff then return end -- avoid fighting diff mode

			local last = vim.b[buf].md_tablewrap_last_tick or 0
			local tick = api.nvim_buf_get_changedtick(buf)
			if tick == last then return end

			local ok, changed, err = core.reformat_all("detect", buf, CFG)
			if not ok then
				vim.notify("MDTableWrap (on-save): " .. (err or "unknown error"), vim.log.levels.ERROR)
				return
			end
			if changed and changed > 0 then
				vim.b[buf].md_tablewrap_last_tick = api.nvim_buf_get_changedtick(buf)
				vim.notify(string.format("MDTableWrap: formatted %d table(s) on save.", changed), vim.log.levels.INFO)
			end
		end,
		desc = "MDTableWrap: reflow all tables on save (Markdown only, detect mode).",
	})
end

---@param user_opts table|nil
---@return nil
local function setup(user_opts)
	local ok, cfg_or_err, err = config.normalize(user_opts)
	if not ok then
		vim.notify("MDTableWrap: invalid configuration: " .. (err or "unknown"), vim.log.levels.ERROR)
		CFG = config.defaults()
	else
		---@diagnostic disable-next-line
		CFG = cfg_or_err
	end

	-- helper to set mode safely
	local function set_mode(mode)
		if mode ~= "auto" and mode ~= "equal" and mode ~= "minflex" then
			vim.notify("MDTableWrap: invalid mode " .. tostring(mode), vim.log.levels.ERROR); return
		end
		---@diagnostic disable-next-line
		CFG.width_mode = mode
		CFG.auto_width = (mode == "auto") -- keep legacy flag coherent
		vim.notify("MDTableWrap: width_mode = " .. mode, vim.log.levels.INFO)
	end

	ensure_autocmds()

	-- Core reflow command: scope depends on wrap_all_default
	api.nvim_create_user_command("MDTableWrap", function(opts)
    if not CFG then return end
		local mode = opts.bang and "force" or "detect"
		---@diagnostic disable-next-line
		if CFG.wrap_all_default then
			local ok2, changed, e = core.reformat_all(mode, api.nvim_get_current_buf(), CFG)
			if not ok2 then
				vim.notify("MDTableWrap: " .. (e or "failed"), vim.log.levels.ERROR); return
			end
			if changed and changed > 0 then
				vim.notify(string.format("MDTableWrap: formatted %d table(s).", changed), vim.log.levels.INFO)
			else
				vim.notify("MDTableWrap: nothing to format.", vim.log.levels.INFO)
			end
		else
			local ok2, e = core.reformat_current(mode, CFG)
			if not ok2 then
				if e == "not on a table line" and mode ~= "force" then
					vim.notify("MDTableWrap: place cursor inside a Markdown table.", vim.log.levels.WARN)
				else
					vim.notify("MDTableWrap: " .. (e or "failed"), vim.log.levels.ERROR)
				end
				return
			end
			vim.notify("MDTableWrap: table formatted.", vim.log.levels.INFO)
		end
	end, {
		desc = "Reflow Markdown tables (scope depends on wrap_all_default). Use ! to force.",
		bang = true,
	})

	api.nvim_create_user_command("MDTableWrapAll", function(opts)
		local mode = opts.bang and "force" or "detect"
		---@diagnostic disable-next-line
		local ok2, changed, e = core.reformat_all(mode, api.nvim_get_current_buf(), CFG)
		if not ok2 then
			vim.notify("MDTableWrap: " .. (e or "failed"), vim.log.levels.ERROR); return
		end
		if changed and changed > 0 then
			vim.notify(string.format("MDTableWrap: formatted %d table(s).", changed), vim.log.levels.INFO)
		else
			vim.notify("MDTableWrap: nothing to format.", vim.log.levels.INFO)
		end
	end, { desc = "Reflow all Markdown tables in the current buffer. Use ! to force.", bang = true })

	api.nvim_create_user_command("MDTableWrapAllToggle", function()
		---@diagnostic disable-next-line
		CFG.wrap_all_default = not CFG.wrap_all_default
		vim.notify("MDTableWrap: wrap_all_default = " .. tostring(CFG.wrap_all_default), vim.log.levels.INFO)
	end, { desc = "Toggle default scope for :MDTableWrap between current table and all tables." })

	api.nvim_create_user_command("MDTableOnSaveToggle", function()
		---@diagnostic disable-next-line
		CFG.on_save_enabled = not CFG.on_save_enabled
		ensure_autocmds()
		vim.notify("MDTableWrap: on_save_enabled = " .. tostring(CFG.on_save_enabled), vim.log.levels.INFO)
	end, { desc = "Toggle reflow of all tables on save (Markdown buffers only)." })

	-- Width strategy toggles
	api.nvim_create_user_command("MDTableWidthToggle", function()
		set_mode(CFG.width_mode == "auto" and "equal" or "auto")
	end, { desc = "Toggle between auto-width and equal-width modes." })

	api.nvim_create_user_command("MDTableAutoWidth", function()
		set_mode("auto")
	end, { desc = "Set auto-width mode." })

	api.nvim_create_user_command("MDTableEqualWidth", function()
		set_mode("equal")
	end, { desc = "Set equal-width mode." })

	api.nvim_create_user_command("MDTableFlexWidth", function()
		set_mode("minflex")
	end, { desc = "Set minflex mode (keep minima, give remainder to wrapping columns)." })

	api.nvim_create_user_command("MDTableWidthMode", function(opts)
		local m = vim.trim(opts.args or "")
		set_mode(m)
	end,
		{ desc = "Set width_mode: auto|equal|minflex.", nargs = 1, complete = function() return { "auto", "equal", "minflex" } end })

	api.nvim_create_user_command("MDTableWidthCycle", function()
		local order = { auto = "equal", equal = "minflex", minflex = "auto" }
		set_mode(order[CFG.width_mode] and order[CFG.width_mode] or "auto")
	end, { desc = "Cycle width_mode: auto → equal → minflex → auto." })

	-- Setters for min/max width
	api.nvim_create_user_command("MDTableWidthInfo", function()
		local m = string.format(
			"width_mode=%s (auto_width=%s), max_col_width=%s, min_col_width=%s, inner_pad=%d, outer_left=%d, outer_right=%d, wrap_all_default=%s, on_save_enabled=%s",
			tostring(CFG.width_mode),
			tostring(CFG.auto_width),
			CFG.max_col_width and tostring(CFG.max_col_width) or "nil",
			CFG.min_col_width and tostring(CFG.min_col_width) or "nil",
			CFG.inner_pad and CFG.inner_pad or 0, CFG.outer_left and CFG.outer_left or 0, CFG.outer_right and CFG.outer_right or 0,
			tostring(CFG.wrap_all_default), tostring(CFG.on_save_enabled)
		)
		vim.notify("MDTableWrap: " .. m, vim.log.levels.INFO, { title = "MDTableWrap" })
	end, { desc = "Show current width and behavior settings." })

	api.nvim_create_user_command("MDTableSetMinWidth", function(opts)
		local a = vim.trim(opts.args or "")
		if a == "" or a == "nil" or a == "false" or a == "0" then
			CFG.min_col_width = 1
			vim.notify("MDTableWrap: min_col_width set to 1.", vim.log.levels.INFO)
			return
		end
		local n = tonumber(a)
		if not n or n < 1 or n ~= math.floor(n) then
			vim.notify("MDTableWrap: invalid min_col_width (need integer ≥ 1).", vim.log.levels.ERROR)
			return
		end
		CFG.min_col_width = math.floor(n)
		vim.notify("MDTableWrap: min_col_width = " .. tostring(CFG.min_col_width), vim.log.levels.INFO)
	end, { desc = "Set min column width in cells (≥1).", nargs = "?" })

	-- Info
	api.nvim_create_user_command("MDTableWidthInfo", function()
		local m = string.format(
			"auto_width=%s, max_col_width=%s, min_col_width=%s, inner_pad=%d, outer_left=%d, outer_right=%d, wrap_all_default=%s, on_save_enabled=%s",
			tostring(CFG.auto_width),
			CFG.max_col_width and tostring(CFG.max_col_width) or "nil",
			CFG.min_col_width and tostring(CFG.min_col_width) or "nil",
			CFG.inner_pad, CFG.outer_left, CFG.outer_right,
			tostring(CFG.wrap_all_default), tostring(CFG.on_save_enabled)
		)
		vim.notify("MDTableWrap: " .. m, vim.log.levels.INFO, { title = "MDTableWrap" })
	end, { desc = "Show current width and behavior settings." })
end

local M = {}
M.setup = setup

--- Optional: allow tests to override text area provider (DI).
---@param fn_provider fun(win:integer):integer
function M.set_text_area_provider(fn_provider)
	core.set_text_area_provider(fn_provider)
end

return M
