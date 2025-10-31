---@module 'usrcmds.templates'
--- Initializer file for the usercommands template modules

local M  = {}

local DEFAULTS = {
	html_accordion = true,
	html_aside = true,
	html_code = true,
	html_figure = true,
	html_formula_table = true,
	html_pagination = true,
	html_quote = true,
}

---@return nil
function M.setup(cfg)
  cfg = cfg or {}

	if cfg.html_accordion or DEFAULTS.html_accordion then
		require("usrcmds.templates.html.accordion")
	end

	if cfg.html_aside or DEFAULTS.html_aside then
		require("usrcmds.templates.html.aside")
	end

	if cfg.html_code or DEFAULTS.html_code then
		require("usrcmds.templates.html.code")
	end

	if cfg.html_figure or DEFAULTS.html_figure then
		require("usrcmds.templates.html.figure")
	end

	if cfg.html_formula_table or DEFAULTS.html_formula_table then
		require("usrcmds.templates.html.formula_table")
	end

	if cfg.html_pagination or DEFAULTS.html_pagination then
		require("usrcmds.templates.html.pagination")
	end

	if cfg.html_quote or DEFAULTS.html_quote then
		require("usrcmds.templates.html.quote")
	end
end

return M
