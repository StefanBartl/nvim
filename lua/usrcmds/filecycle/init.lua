---@module 'usrcmds.filecycle'
--- Navigate to the next/previous file in the current buffer's directory.
--- This module provides user commands and keymaps to "load into the current window".

local DEFAULTS = {
  open_target = "current",
  keep_focus = true,
  include_hidden = false,
  wrap = true,
  follow_symlinks = true,
  root = "buffer_dir",
  confirm_on_modified = true,
  case_insensitive = true,
}

---@class FileCycleState
---@field opts FileCycleConfig
local M = { opts = DEFAULTS }

-- Local aliases (clarity over micro perf)
local api, fn, uv = vim.api, vim.fn, (vim.uv or vim.loop)

---@alias FilePath string

--- Resolve a canonical path for comparison/opening.
--- Uses fs_realpath when allowed, otherwise returns absolute path.
---@param p FilePath
---@param follow boolean
---@return FilePath
local function canon(p, follow)
	if follow and uv and uv.fs_realpath then
		local rp = uv.fs_realpath(p)
		if type(rp) == "string" and rp ~= "" then return rp end
	end
	return fn.fnamemodify(p, ":p")
end

--- Return current directory to scan according to config.
---@param opts FileCycleConfig
---@return FilePath|nil, string|nil
local function get_root_dir(opts)
	local target = opts.root
	if target == "cwd" then
		local cwd = fn.getcwd()
		if type(cwd) == "string" and cwd ~= "" then return cwd end
		return nil, "failed to getcwd()"
	end
	-- buffer_dir (default)
	local name = api.nvim_buf_get_name(0)
	if not name or name == "" then return nil, "current buffer has no file name" end
	local dir = fn.fnamemodify(name, ":p:h")
	if not dir or dir == "" then return nil, "failed to resolve buffer directory" end
	return dir, nil
end

--- Predicate: keep this directory entry?
---@param name string  -- filename (not path)
---@param is_file boolean
---@param opts FileCycleConfig
---@return boolean
local function keep_entry(name, is_file, opts)
	if not is_file then return false end
	if not opts.include_hidden and name:sub(1, 1) == "." then return false end
	return true
end

--- List regular files in a directory (non-recursive), filtered & sorted.
---@param dir FilePath
---@param opts FileCycleConfig
---@return string[] files  -- absolute, canonicalized paths
local function list_files(dir, opts)
	---@type string[]
	local acc = {}
	for name, t in vim.fs.dir(dir) do
		local is_file = (t == "file")
		if not is_file and t == nil then
			-- Older libuv may not give type; check via fs_stat
			local st = uv and uv.fs_stat and uv.fs_stat(fn.fnamemodify(dir .. "/" .. name, ":p")) or nil
			is_file = (st and st.type == "file") or false
		end
		if keep_entry(name, is_file, opts) then
			acc[#acc + 1] = canon(dir .. "/" .. name, opts.follow_symlinks)
		end
	end
	local ci = opts.case_insensitive
	table.sort(acc, function(a, b)
		if ci then
			return a:lower() < b:lower()
		else
			return a < b
		end
	end)
	return acc
end

--- Find index of current file within the list.
---@param files string[]
---@param current FilePath
---@param ci? boolean
---@return integer|nil
local function index_of(files, current, ci)
	if ci or DEFAULTS.case_insensitive then current = current:lower() end
	for i = 1, #files do
		local v = ci and files[i]:lower() or files[i]
		if v == current then return i end
	end
	return nil
end

--- Open a path according to `opts.open_target`
---@param path string
---@param opts FileCycleConfig
---@return boolean ok
local function open_path(path, opts)
  if type(path) ~= "string" or path == "" then return false end
  local win = vim.api.nvim_get_current_win()
  if not (win and vim.api.nvim_win_is_valid(win)) then return false end
  local bufnr = vim.api.nvim_get_current_buf()
  if not (bufnr and vim.api.nvim_buf_is_valid(bufnr)) then return false end

  local target = opts.open_target or "current"
  local esc = vim.fn.fnameescape(path)

  if target == "current" then
    local cmd
    if opts.confirm_on_modified and vim.bo[bufnr].modified then
      cmd = "confirm edit " .. esc
    else
      cmd = "edit " .. esc
    end
    local ok, err = pcall(function() vim.cmd(cmd) end)
    if not ok then
      vim.notify(("[NextPrev] open failed: %s"):format(tostring(err)), vim.log.levels.ERROR)
      return false
    end
    return true
  elseif target == "split" or target == "vsplit" then
    local splitcmd = (target == "split") and "split " or "vsplit "
    local curwin = win
    local ok, err = pcall(function() vim.cmd(splitcmd .. esc) end)
    if not ok then
      vim.notify(("[NextPrev] %s failed: %s"):format(target, tostring(err)), vim.log.levels.ERROR)
      return false
    end
    if opts.keep_focus and vim.api.nvim_win_is_valid(curwin) then
      vim.schedule(function()
        pcall(vim.api.nvim_set_current_win, curwin)
      end)
    end
    return true
  elseif target == "tab" then
    local ok, err = pcall(function() vim.cmd("tabedit " .. esc) end)
    if not ok then
      vim.notify(("[NextPrev] tabedit failed: %s"):format(tostring(err)), vim.log.levels.ERROR)
      return false
    end
    -- keep_focus is intentionally ignored for tabs
    return true
  elseif target == "background" then
    -- Add buffer silently without changing windows
    local ok_add, b = pcall(vim.fn.bufadd, path)
    if not ok_add then return false end
    pcall(vim.fn.bufload, b)
    pcall(function() vim.bo[b].buflisted = true end)
    return true
  else
    vim.notify(("[NextPrev] unknown open_target: %s"):format(tostring(target)), vim.log.levels.WARN)
    return false
  end
end

--- Compute next/previous path and open it.
---@param dir FilePath
---@param mode "next"|"prev"
---@param opts FileCycleConfig
---@return boolean ok
local function navigate(dir, mode, opts)
	local files = list_files(dir, opts)
	if #files == 0 then
		vim.notify("[NextPrev] no files in directory", vim.log.levels.WARN)
		return false
	end

	local cur = api.nvim_buf_get_name(0)
	if not cur or cur == "" then
		vim.notify("[NextPrev] current buffer has no file name", vim.log.levels.WARN)
		return false
	end

	local key = canon(cur, opts.follow_symlinks)
	local ci = opts.case_insensitive or DEFAULTS.case_insensitive
	local idx = index_of(files, key, ci)
	if not idx then
		-- If current file is not in the filtered list, choose the closest by name and continue.
		table.insert(files, key)
		table.sort(files, function(a, b) return (ci and a:lower() or a) < (ci and b:lower() or b) end)
		for i = 1, #files do
			if (ci and files[i]:lower() == key:lower()) or files[i] == key then
				idx = i
				break
			end
		end
	end

	if not idx then
		vim.notify("[NextPrev] cannot place current file in ordering", vim.log.levels.WARN)
		return false
	end

	local target_idx
	if mode == "next" then
		if idx < #files then
			target_idx = idx + 1
		elseif opts.wrap then
			target_idx = 1
		end
	else
		if idx > 1 then
			target_idx = idx - 1
		elseif opts.wrap then
			target_idx = #files
		end
	end

	if not target_idx then
		vim.notify("[NextPrev] boundary reached (wrap disabled)", vim.log.levels.INFO)
		return false
	end

 return open_path(files[target_idx], opts)
end


--- AUDIT: usercmds und keymaps function

--- Setup module options and create user commands & keymaps.
---@param user_opts FileCycleConfig|nil
---@return nil
function M.setup(user_opts)
	user_opts             = user_opts or {}
	-- Merge options (shallow copy)
	local o               = {} ---@type FileCycleConfig
	o.open_target         = (user_opts.open_target ~= nil) and user_opts.open_target or DEFAULTS.open_target
	o.keep_focus          = (user_opts.keep_focus ~= nil) and user_opts.keep_focus or DEFAULTS.keep_focus
	o.include_hidden      = (user_opts.include_hidden ~= nil) and user_opts.include_hidden or DEFAULTS.include_hidden
	o.wrap                = (user_opts.wrap ~= nil) and user_opts.wrap or DEFAULTS.wrap
	o.follow_symlinks     = (user_opts.follow_symlinks ~= nil) and user_opts.follow_symlinks or DEFAULTS.follow_symlinks
	o.root                = (user_opts.root ~= nil) and user_opts.root or DEFAULTS.root
	o.confirm_on_modified = (user_opts.confirm_on_modified ~= nil) and user_opts.confirm_on_modified or
	DEFAULTS.confirm_on_modified
	o.case_insensitive    = (user_opts.case_insensitive ~= nil) and user_opts.case_insensitive or DEFAULTS
	.case_insensitive
	M.opts                = o

	-- User commands with -bang to allow forced edit
	api.nvim_create_user_command("NextFile", function(cmdopts)
		local dir, err = get_root_dir(M.opts)
		if not dir then
			vim.notify("[NextPrev] " .. (err or "no directory"), vim.log.levels.WARN)
			return
		end
		-- If bang, temporarily disable confirm and force edit!
		if cmdopts.bang then
			local prev = M.opts.confirm_on_modified
			M.opts.confirm_on_modified = false
			local ok1 = navigate(dir, "next", M.opts)
			if not ok1 and prev ~= nil then M.opts.confirm_on_modified = prev end
			-- force write of changed buffer is deliberately not done here
			return
		end
		navigate(dir, "next", M.opts)
	end, { desc = "Open next file in current directory", bang = true })

	api.nvim_create_user_command("PreviousFile", function(cmdopts)
		local dir, err = get_root_dir(M.opts)
		if not dir then
			vim.notify("[NextPrev] " .. (err or "no directory"), vim.log.levels.WARN)
			return
		end
		if cmdopts.bang then
			local prev = M.opts.confirm_on_modified
			M.opts.confirm_on_modified = false
			local ok1 = navigate(dir, "prev", M.opts)
			if not ok1 and prev ~= nil then M.opts.confirm_on_modified = prev end
			return
		end
		navigate(dir, "prev", M.opts)
	end, { desc = "Open previous file in current directory", bang = true })

	-- Keymaps (leader nf / pf), silent & noremap
	vim.keymap.set("n", "<leader>nf", function()
		local dir = select(1, get_root_dir(M.opts))
		if dir then navigate(dir, "next", M.opts) end
	end, { desc = "[NextPrev] Next file in directory", silent = true })

	vim.keymap.set("n", "<leader>pf", function()
		local dir = select(1, get_root_dir(M.opts))
		if dir then navigate(dir, "prev", M.opts) end
	end, { desc = "[NextPrev] Previous file in directory", silent = true })
end

--- Programmatic API: open next/prev with explicit options (optional).
---@param mode "next"|"prev"
---@param opts FileCycleConfig|nil
---@return boolean ok
function M.open(mode, opts)
	local o = opts and vim.tbl_deep_extend("force", M.opts, opts) or M.opts
	local dir, err = get_root_dir(o)
	if not dir then
		vim.notify("[NextPrev] " .. (err or "no directory"), vim.log.levels.WARN)
		return false
	end
	return navigate(dir, mode, o)
end

M.setup({
  open_target = "current",
  keep_focus = true,
  include_hidden = false,
  wrap = true,
  follow_symlinks = true,
  root = "buffer_dir",
  confirm_on_modified = true,
  case_insensitive = true,
})

return M
