---@module 'usrcmds.md_tablewrap.config'
--- Configuration normalization and defaults for md.tablewrap.
--- This module performs strict type- and bounds-checking and returns
--- a normalized, immutable copy of the configuration for use by other modules.

local M = {}

---@type MDTableWrapConfig
local DEFAULTS = {
	inner_pad        = 1,
	outer_left       = 3,
	outer_right      = 3,
	auto_width       = true,     -- legacy switch (kept for compatibility)
	width_mode       = "minflex", -- "auto" | "equal" | "minflex"
	max_col_width    = nil,
	min_col_width    = 8,
	wrap_all_default = false,
	on_save_enabled  = false,
}

---@param name string
---@param v any
---@param min integer
---@param allow_nil boolean
---@return boolean ok, integer|nil val, string|nil err
local function as_int(name, v, min, allow_nil)
	if v == nil then
		if allow_nil then return true, nil, nil end
		return false, nil, name .. " is required"
	end
	if type(v) ~= "number" or v ~= math.floor(v) then
		return false, nil, name .. " must be an integer"
	end
	if v < min then
		return false, nil, string.format("%s must be ≥ %d", name, min)
	end
	return true, v, nil
end

---@param name string
---@param v any
---@return boolean ok, boolean|nil val, string|nil err
local function as_bool(name, v)
	if type(v) ~= "boolean" then
		return false, nil, name .. " must be a boolean"
	end
	return true, v, nil
end

---@param user table|nil
---@return boolean ok, MDTableWrapConfig|nil cfg, string|nil err
function M.normalize(user)
	if user == nil then
		-- Return a deep copy of defaults
		return true, vim.deepcopy(DEFAULTS), nil
	end
	if type(user) ~= "table" then
		return false, nil, "options must be a table"
	end
	local cfg = vim.deepcopy(DEFAULTS)

	if user.inner_pad ~= nil then
		local ok, val, err = as_int("inner_pad", user.inner_pad, 0, false); if not ok then return false, nil, err end
		cfg.inner_pad = val
	end
	if user.outer_left ~= nil then
		local ok, val, err = as_int("outer_left", user.outer_left, 0, false); if not ok then return false, nil, err end
		cfg.outer_left = val
	end
	if user.outer_right ~= nil then
		local ok, val, err = as_int("outer_right", user.outer_right, 0, false); if not ok then return false, nil, err end
		cfg.outer_right = val
	end
	if user.auto_width ~= nil then
		local ok, val, err = as_bool("auto_width", user.auto_width); if not ok then return false, nil, err end
		cfg.auto_width = val
	end
	if user.width_mode ~= nil then
		if type(user.width_mode) ~= "string" then
			return false, nil, "width_mode must be a string"
		end
		local m = user.width_mode
		if m ~= "auto" and m ~= "equal" and m ~= "minflex" then
			return false, nil, "width_mode must be one of: auto|equal|minflex"
		end
		cfg.width_mode = m
		cfg.auto_width = (m == "auto")
	end

	-- legacy auto_width still supported if width_mode not set explicitly
	if user.width_mode == nil and user.auto_width ~= nil then
		local okb, val, err = as_bool("auto_width", user.auto_width); if not okb then return false, nil, err end
		cfg.auto_width = val
		cfg.width_mode = val and "auto" or "equal"
	end
	if user.max_col_width ~= nil then
		if user.max_col_width == false then
			cfg.max_col_width = nil
		else
			local ok, val, err = as_int("max_col_width", user.max_col_width, 1, true); if not ok then return false, nil, err end
			cfg.max_col_width = val
		end
	end
	if user.min_col_width ~= nil then
		local ok, val, err = as_int("min_col_width", user.min_col_width, 1, false); if not ok then return false, nil, err end
		cfg.min_col_width = val
	end
	if user.wrap_all_default ~= nil then
		local ok, val, err = as_bool("wrap_all_default", user.wrap_all_default); if not ok then return false, nil, err end
		cfg.wrap_all_default = val
	end
	if user.on_save_enabled ~= nil then
		local ok, val, err = as_bool("on_save_enabled", user.on_save_enabled); if not ok then return false, nil, err end
		cfg.on_save_enabled = val
	end

	-- Sanity: max ≥ min if both set (not strict requirement, just warn via return err)
	if cfg.max_col_width and cfg.min_col_width and cfg.max_col_width < cfg.min_col_width then
		-- Swap to keep invariants reasonable
		cfg.max_col_width = cfg.min_col_width
	end

	return true, cfg, nil
end

---@return MDTableWrapConfig defaults_copy
function M.defaults()
	return vim.deepcopy(DEFAULTS)
end

return M
