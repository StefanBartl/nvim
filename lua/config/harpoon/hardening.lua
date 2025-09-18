---@module 'config.harpoon.hardening'
--- One-time Harpoon v2 setup with:
--- - Stable project key (Git root -> cwd)
--- - Autosave on UI close and common editor events
--- - Safe sanitize + dedup (no full table replacement)
--- - Cross-platform UI labels (drive/partition aware)
--- - Optional FZF menu bound on <C-h> (fallback to quick menu)
---
--- This module is Linux/macOS-first but also supports Windows (drive letters, UNC).

local M      = {}

local safe   = require("utils.safe_call")
local pkey   = require("config.harpoon.utils.fs_project_key")
local sani   = require("config.harpoon.utils.sanitize")
local label  = require("config.harpoon.utils.path_label")
local _ = require("config.harpoon.ui.menu_fzf")
local dbg    = require("config.harpoon.debug")
local uv = vim.uv or vim.loop

local function make_debounced_saver(harpoon, ms)
  local t = uv.new_timer()
  local pending = false
  ms = ms or 200
  return function()
    pending = true
    t:stop()
    t:start(ms, 0, function()
      if not pending then return end
      pending = false
      vim.schedule(function()
        local list = harpoon:list()
        if type(harpoon.save) == "function" then
          pcall(harpoon.save, harpoon)
        elseif list and type(list.save) == "function" then
          pcall(list.save, list)
        end
      end)
    end)
  end
end

---@param harpoon HarpoonApi
---@return nil
local function install_autosave(harpoon)
	-- Save when quick-menu toggles
	local ok_ui, ui = pcall(require, "harpoon.ui")
	if ok_ui and type(ui) == "table" and type(ui.toggle_quick_menu) == "function" then
		local orig = ui.toggle_quick_menu
		ui.toggle_quick_menu = function(...)
			local ret = { orig(...) }
			vim.schedule(function()
				local list = harpoon:list()
				if type(harpoon.save) == "function" then
					pcall(harpoon.save, harpoon)
				elseif list and type(list.save) == "function" then
					pcall(list.save, list)
				end
			end)
			local unpack = table.unpack or unpack
			return unpack(ret)
		end
	end

	-- Cheap persistence on editor events (debounced by scheduler tick)
	local grp = vim.api.nvim_create_augroup("HarpoonAutosave", { clear = true })
	vim.api.nvim_create_autocmd({ "BufLeave", "FocusLost" }, {
		group = grp,
		callback = function()
			vim.schedule(function()
				-- Reuse the upvalue 'harpoon' captured from the outer function.
				if not harpoon then return end
				local list = harpoon:list()
				if type(harpoon.save) == "function" then
					pcall(harpoon.save, harpoon)
				elseif list and type(list.save) == "function" then
					pcall(list.save, list)
				end
			end)
		end,
	})
end

---@param provider "fzf"|"telescope"
---@return nil
local function install_keymaps(provider)
	vim.keymap.set("n", "<C-h>", function()
		require("config.harpoon.ui").open({ provider = provider or "fzf" })
	end, { desc = "Harpoon menu (short labels)" })
end

---@param harpoon HarpoonApi
---@return nil
local function sanitize_and_dedup_once(harpoon)
	vim.schedule(function()
		local list = harpoon:list()
		sani.sanitize_items_in_place(list)
		sani.dedup_in_place_safe(list)
		if type(harpoon.save) == "function" then
			pcall(harpoon.save, harpoon)
		elseif list and type(list.save) == "function" then
			pcall(list.save, list)
		end
	end)
end

--- Robust formatter: accepts both table items and plain strings.
---@param item table|string
---@return string
local function display_label(item)
	-- Harpoon v2 items are usually tables: { value = string, context = {...} }
	local v = (type(item) == "table") and item.value or item
	if type(v) ~= "string" then
		v = tostring(v or "")
	end
	-- Reuse cross-platform shortening (keeps drive/UNC/home root visible)
	return label.to_label(v)
end

---@return nil
function M.setup()
	local ok, harpoon = pcall(require, "harpoon")
	if not ok then return end

	-- Single setup with stable project key + customized display for the quick menu
	safe.safe_call(function()
		harpoon:setup({
			settings = {
				save_on_toggle = true,
				sync_on_ui_close = true,
				key = pkey.project_key, -- Git root -> cwd
			},
			-- Ensure Harpoon's own quick menu shows shortened path labels consistently
			default = {
				display = display_label,
			},
			-- Optional menu tweaks can go here, e.g. width/height if supported by your snapshot:
			-- menu = { width = math.max(60, math.floor(vim.o.columns * 0.6)) },
		})
	end)

	install_autosave(harpoon)
	install_keymaps("fzf")         -- Standard
	-- install_keymaps("telescope")
	dbg.setup_cmd()

	sanitize_and_dedup_once(harpoon)
end

return M
