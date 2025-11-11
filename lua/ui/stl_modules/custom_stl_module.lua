---@module 'ui.custom_stl_module
--- Module with helper function for custom nvchad/ui/statusline

local fn, api = vim.fn, vim.api

local M = {}

-------------------------------------
-- NERD FONTS HELPER
-------------------------------------

--- Convert a hex codepoint string (e.g. "F0056") to a UTF-8 character.
--- Uses Vim's nr2char to produce a valid UTF-8 sequence.
---@param hex string                 -- upper/lower hex without "0x", e.g. "F0056"
---@return string                    -- the UTF-8 character or empty string on failure
local function cp(hex)
  -- Defensive: tonumber(..., 16) may return nil on invalid input
  local n = tonumber(hex, 16)
  if not n then return "" end
  return fn.nr2char(n)
end

--- Choose the breadcrumb separator: prefer the given Nerd Font codepoint,
--- but fall back to a Unicode arrow if the glyph is not available or too wide.
---@param hex string                 -- preferred Nerd Font codepoint in hex, e.g. "F0056"
---@return string                    -- separator surrounded by spaces, e.g. "  "
local function nerd_sep_or_fallback(hex)
  local g = cp(hex)
  -- Only accept if it renders as a single display cell (prevents centering drift)
  if g ~= "" and fn.strdisplaywidth(g) == 1 then
    return " " .. g .. " "
  end
  -- Fallbacks with broad font coverage
  local wide = vim.o.columns >= 100
  return wide and " ⟶ " or " › "
end

-------------------------------------
-- BREADCRUMBS HELPER
-------------------------------------

--- Escape % so user text cannot break statusline sequences.
--- @param s string
--- @return string
function M.stl_escape(s)
	return (s:gsub("%%", "%%%%"))
end

--- Ellipsize in the middle to a maximum length (display width aware enough for ASCII).
--- @param s string
--- @param max integer
--- @return string
function M.ellipsize_middle(s, max)
	if #s <= max then return s end
	local head = math.floor((max - 1) / 2)
	local tail = max - head - 1
	return string.sub(s, 1, head) .. "…" .. string.sub(s, #s - tail + 1, #s)
end

--- Repo-/project-relative path (fallback: path relative to cwd; final fallback: tail).
--- @param path string
--- @return string
function M.repo_relative(path)
	if path == "" then return "[No Name]" end
	local dir = fn.fnamemodify(path, ":h")
	local gitdir = vim.fs.find(".git", { upward = true, path = dir })[1]
	if gitdir then
		local root = fn.fnamemodify(gitdir, ":h")
		local rel = fn.fnamemodify(path, (":~:%s"):format(root))
		if rel == path then return fn.fnamemodify(path, ":t") end
		rel = rel:gsub("^%./", ""):gsub("^/", "")
		return rel
	else
		return fn.fnamemodify(path, ":~:.")
	end
end

--- Try to extract a concise symbol path near the cursor (Treesitter → LSP → nil).
--- Only keeps named semantic nodes; avoids generic "block" noise.
--- @return string|nil
function M.symbol_context()
	local ok_ts = pcall(require, "vim.treesitter")
	local ok_utils, tsu = pcall(require, "nvim-treesitter.ts_utils")
	if not ok_ts or not ok_utils or not tsu then return nil end

	local node = tsu.get_node_at_cursor()
	if not node then return nil end

	local keep = {
		function_declaration = true,
		function_definition = true,
		method_declaration = true,
		method_definition = true,
		class_declaration = true,
		class_specifier = true,
		struct_specifier = true,
		interface_declaration = true,
		module_declaration = true,
		namespace_definition = true,
		impl_item = true, -- rust
	}

	function M.ts_identifier_of(n)
		-- 1) Named field "name"
		local named = n:field("name")
		if named and named[1] then
			local t = vim.treesitter.get_node_text(named[1], 0)
			if t and #t > 0 then return t end
		end
		-- 2) Shallow search for common identifier-like node types
		local want = {
			"identifier", "property_identifier", "field_identifier",
			"type_identifier", "name",
		}
		local function in_list(x) for _, w in ipairs(want) do if x == w then return true end end end
		local function first_ident(m, depth)
			depth = depth or 0
			if depth > 2 then return nil end
			if in_list(m:type()) then
				local t = vim.treesitter.get_node_text(m, 0)
				if t and #t > 0 then return t end
			end
			for i = 0, m:child_count() - 1 do
				local r = first_ident(m:child(i), depth + 1)
				if r then return r end
			end
			return nil
		end
		local t = first_ident(n, 0)
		if t and #t > 0 then return t end
		-- 3) Final fallback: first plausible token from the line
		local raw = vim.treesitter.get_node_text(n, 0) or ""
		raw = raw:gsub("^%s+", ""):gsub("\n.*", "")
		local guess = raw:match("^%w+%s+([%w_]+)%s*%(")
				or raw:match("^%w+%s+([%w_]+)%s*[={:]")
				or raw:match("^([%w_%.:]+)%s*%(")
				or raw:match("^([%w_%.:]+)")
		return guess
	end

	local names = {}
	local u = node
	while u do
		local t = u:type()
		if keep[t] then
			local ident = M.ts_identifier_of(u)
			if ident and #ident > 0 then
				if t:find("function") or t:find("method") then
					if not ident:find("%)$") then ident = ident .. "()" end
				end
				table.insert(names, 1, ident)
			end
		end
		local p = u:parent()
		if not p or p == u then break end
		u = p
	end

	if #names == 0 then return nil end
	return table.concat(names, " → ")
end

-------------------------------------
-- RENDER BREADCRUMBS
-------------------------------------

--- Render the centered breadcrumbs module (no leading/trailing spaces to keep centering exact).
--- @return string
function M.render_breadcrumbs()
	local utils = require "nvchad.stl.utils"
	local bufnr = utils.stbufnr()
	local path = api.nvim_buf_get_name(bufnr)
	if path == "" then return "" end

	local rel = M.repo_relative(path)
	local ctx = M.symbol_context()

  -- Prefix the relative path with a filetype icon (colored to match the mode band)
  local icon_seg = M.file_icon_segment()

	-- separate filepath from breadcrumb with nerd font hex code
	local sep = nerd_sep_or_fallback("f0058")

  local line = ctx and (#ctx > 0) and (rel .. sep .. ctx) or rel
  -- Optional: scale with window width (use ~40% of columns)
  local maxw = math.max(30, math.floor(vim.o.columns * 0.5))
  line = M.ellipsize_middle(line, maxw)
  line = M.stl_escape(line)

  -- No leading/trailing spaces overall; add a single space between icon and text.
  line = icon_seg .. " " .. line

  return line .. "%*"
end

-------------------------------------
-- MODULES HIGHLIGHTING
-------------------------------------

-- Strip embedded statusline highlights like "%#Group#" / "%*" to allow re-wrapping with our own group.
function M.stl_strip_hl(s)
	return (s:gsub("%%#.-#", ""):gsub("%%%*", ""))
end

-- Open a highlight group without resetting at the end.
-- Use this when you want the band to keep filling the center area up to the next module.
function M.hl_open(group)
	return "%#" .. group .. "#"
end

-- Wrap payload with a statusline highlight group.
function M.hl_wrap(group, s)
	if not s or s == "" then return "" end
	return "%#" .. group .. "#" .. s .. "%*"
end

-- Compute current "mode band" highlight group, e.g. "St_Normalmode", "St_Insertmode", ...
-- Use this to wrap other modules so they visually match the mode/git band.
function M.mode_band_group()
	local utils = require("nvchad.stl.utils")
	local m = api.nvim_get_mode().mode
	local name = (utils.modes[m] and utils.modes[m][2]) or "Normal"
	return "St_" .. name .. "mode"
end

-------------------------------------
-- FILE ICONS
-------------------------------------

---@class FileIconHLCache
---@field name string                 -- highlight group name used for the icon segment
---@field fg string|nil               -- last foreground hex color (e.g. "#aabbcc")
---@field bg string|nil               -- last background hex color matching current mode band

--- Create or update a highlight group that matches the current mode band background,
--- but uses the devicon foreground color. This avoids flicker by caching the last colors.
---@param fg string|nil               -- hex foreground color from devicons (e.g. "#6f8faf")
---@param band_bg string|nil          -- hex background color of the mode band
---@return string                     -- highlight group name to use in the statusline
local function ensure_icon_hl(fg, band_bg)
  -- cache lives on the module table to avoid redefinition per render
  ---@type FileIconHLCache
  M.__icon_hl = M.__icon_hl or { name = "St_FileIcon", fg = nil, bg = nil }

  if M.__icon_hl.fg ~= fg or M.__icon_hl.bg ~= band_bg then
    -- Define or update the highlight; nil is allowed and means "inherit"
    api.nvim_set_hl(0, M.__icon_hl.name, { fg = fg, bg = band_bg })
    M.__icon_hl.fg = fg
    M.__icon_hl.bg = band_bg
  end
  return M.__icon_hl.name
end

--- Try to obtain a devicon (and its color) for a given path.
--- Falls back to a generic icon if devicons are unavailable.
---@param path string                 -- absolute or relative file path; empty means "No Name"
---@return string icon                -- glyph to display (never empty)
---@return string|nil color           -- hex foreground (e.g. "#aabbcc") or nil
local function devicon_for_path(path)
  local ok, devicons = pcall(require, "nvim-web-devicons")
  local filename = (path == "" or path == nil) and "[No Name]" or fn.fnamemodify(path, ":t")
  local ext = filename:match("^.+%.(.+)$") or ""

  if not ok then
    -- Generic fallback icon (Nerd Font)
    return "󰈙", nil
  end

  -- Prefer get_icon_color if supported by the installed devicons version
  local icon, color
  local ok_color = pcall(function()
    icon, color = devicons.get_icon_color(filename, ext, { default = true })
  end)
  if not ok_color or not icon then
    icon = devicons.get_icon(filename, ext, { default = true })
    -- Try best-effort color lookup when get_icon_color isn't available
    if devicons.get_color then
      local ok_c = pcall(function()
        color = devicons.get_color(filename, ext, { default = true })
      end)
      if not ok_c then color = nil end
    end
  end

  if not icon or icon == "" then icon = "󰈙" end
  return icon, color
end

--- Convert an Neovim API "hl" color field (integer) to a "#RRGGBB" string.
---@param n integer|nil
---@return string|nil
local function int_to_hex(n)
  if type(n) ~= "number" then return nil end
  return string.format("#%06x", n)
end

--- Resolve the current mode band's background color (hex) to blend the icon nicely.
---@return string|nil
local function mode_band_bg_hex()
  local group = M.mode_band_group()
  -- On recent Neovim versions, `link=false` returns resolved attrs
  local hl = api.nvim_get_hl(0, { name = group, link = false }) or {}
  -- Different versions may expose "bg" or "background"
	---@diagnostic disable-next-line
  return int_to_hex(hl.bg or hl.background)
end

--- Build the statusline-ready icon segment for the current buffer.
--- The icon is wrapped in a dedicated HL group that uses the mode band's background.
---@return string                      -- e.g. "%#St_FileIcon#󰢱%*"
function M.file_icon_segment()
  local utils = require "nvchad.stl.utils"
  local bufnr = utils.stbufnr()
  local path = api.nvim_buf_get_name(bufnr) or ""

  local icon, fg = devicon_for_path(path)
  local bg = mode_band_bg_hex()
  local group = ensure_icon_hl(fg, bg)

  -- Wrap with statusline HL escapes. No trailing/leading spaces here.
  return "%#" .. group .. "#" .. icon .. "%*"
end

return M
