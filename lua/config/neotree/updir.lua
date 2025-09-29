---@module 'neo-tree-updir'
--- Up-one-level mapping for Neo-tree that works correctly in float/current/sidebars.
--- It updates the tree root in-place and adjusts the CWD (window-local for float/current).

---@class NeoTreeUpdir
local M = {}

---@param state table  -- neo-tree internal state for the current window
---@return nil
function M.up_one_level(state)
	-- Resolve current root (falls state.path noch nicht gesetzt ist, vom Cursor ableiten)
	local current_root = state.path
	if not current_root or current_root == "" then
		local node = state.tree:get_node()
		local path = node and (node.path or node:get_id()) or ""
		if path == "" then
			vim.notify("no path under cursor", vim.log.levels.WARN)
			return
		end
		-- If a file is focused, use its directory; if a directory, use it directly
		current_root = (vim.fn.isdirectory(path) == 1) and path or vim.fn.fnamemodify(path, ":h")
	end

	-- Compute parent
	local parent = vim.fn.fnamemodify(current_root, ":h")
	if parent == current_root or parent == "" then
		vim.notify("already at top-level directory", vim.log.levels.WARN)
		return
	end

	-- Determine where Neo-tree is shown to pick reasonable CWD semantics
	local position = (state.window and state.window.position) or "left"

	-- Use window-local CWD for float/current to avoid surprising global cd side effects
	local cd_cmd = (position == "current" or position == "float") and "lcd" or "cd"
	local esc = vim.fn.fnameescape(parent)

	-- Set CWD (pcall to avoid hard errors)
	local ok_cd, cd_err = pcall(function() vim.cmd(string.format("%s %s", cd_cmd, esc)) end)
	if not ok_cd then
		vim.notify(("cwd change failed: %s"):format(tostring(cd_err)), vim.log.levels.ERROR)
		return
	end

	-- In-place root change without spawning a new Neo-tree window
	-- Prefer the built-in navigate_up if available; otherwise set_root explicitly.
	if state.commands and state.commands.navigate_up then
		-- navigate_up() uses state.path to go one level up; since we also changed CWD,
		-- both stay aligned. This operates entirely in the current Neo-tree instance.
		state.commands.navigate_up(state)
	elseif state.commands and state.commands.set_root then
		-- Fallback: set the root to the computed parent directly
		state.commands.set_root(state, parent)
	else
		-- Last resort: refresh via manager with the target path
		local ok_mgr, manager = pcall(require, "neo-tree.sources.manager")
		if ok_mgr then
			manager.navigate(state, parent)
		else
			vim.notify("neo-tree: no suitable command to change root", vim.log.levels.ERROR)
			return
		end
	end

	-- Optional: refresh the view to ensure UI is up-to-date
	local ok_mgr, manager = pcall(require, "neo-tree.sources.manager")
	if ok_mgr and manager and manager.refresh then
		-- manager.refresh(state)
		-- Variate 1:
		-- instead of: manager.refresh(state)
		-- choose an explicit source name, or derive it from state
		-- local src = (type(state) == "table" and (state.name or state.source or state.source_name)) or "filesystem"
		-- manager.refresh(src)
		--
		-- VAriante 2:
		local ok_mod, refresher = pcall(require, "config.neotree.refresh_adapter")
		if ok_mod then
			-- pass the state you already have; helper extrahiert den Namen
			refresher.refresh(state)
		else
			-- minimal direct fix ohne Helper
			if ok_mgr and manager and type(manager.refresh) == "function" then
				local src = (type(state) == "table" and (state.name or state.source or state.source_name)) or "filesystem"
				manager.refresh(src)
			end
		end
	end

	vim.notify(("cwd → %s"):format(parent), vim.log.levels.INFO)
end

return M
