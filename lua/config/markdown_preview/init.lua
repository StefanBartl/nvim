---@module 'config.markdown_preview'
--- Behavior-only setup for iamcco/markdown-preview.nvim to keep exactly one
--- preview window alive that:
---   1) auto-starts on focusing any Markdown buffer (if none is open),
---   2) always reuses/updates that single preview when switching Markdown buffers,
---   3) does nothing when switching to non-Markdown buffers (no close, no update).
---
--- Put this file at: lua/config/markdown_preview.lua
--- Load from Lazy spec with:
---   config = function() require("config.markdown_preview").setup() end

local M = {}

--- Apply minimal, behavior-focused globals.
--- No OS/browser detection here; rely on system default browser.
function M.setup()

	--- specify browser to open preview page
	local browser = {
		win = vim.fs.joinpath('C:', 'Program Files', 'Google', 'Chrome', 'Application', 'chrome.exe'),
		wsl = vim.fs.joinpath('mnt', 'c', 'Program Files', 'Google', 'Chrome', 'Application', 'chrome.exe'),
		linux = vim.fs.joinpath(''), -- BUG: WATCH: AUDIT: If youre on Linux OS put path there
	}

	if vim.g.is_windows then
		vim.g.mkdp_browser = browser.win
	elseif vim.g.is_wsl then
		vim.g.mkdp_browser = browser.wsl
	elseif vim.g.is_linux then
		vim.g.mkdp_browser = browser.linux
	else
		vim.notify("[Options] Global env for OS not set (system/env.lua). Browser for Markdows Preview defaulted.", 2)
	end

	-- 1) Open preview when entering a Markdown buffer (first time only).
	--    The plugin’s autocommand handles this.
	vim.g.mkdp_auto_start = 1

	-- 2) Never auto-close when leaving a Markdown buffer.
	--    This keeps the preview alive while visiting other buffers.
	vim.g.mkdp_auto_close = 0

	-- 3) Always reuse a single preview window across Markdown buffers.
	vim.g.mkdp_combine_preview = 1

	-- 4) When the single preview is open, auto-refresh its contents whenever
	--    the current Markdown buffer changes (on buffer switches).
	vim.g.mkdp_combine_preview_auto_refresh = 1

	-- Optional (keep defaults for everything else). Example theme:
	-- vim.g.mkdp_theme = "dark"

	-- Optional fallback (only if someone observes that mkdp_auto_start
	-- does not trigger on their setup). In most setups this is NOT needed.
	--[[
  local aug = vim.api.nvim_create_augroup("MkdpAutoStartFallback", { clear = true })
  vim.api.nvim_create_autocmd("BufEnter", {
    group = aug,
    pattern = "*.md",
    callback = function()
      -- Safe to call repeatedly; with combine_preview=1 it reuses/updates.
      vim.cmd("silent! MarkdownPreview")
    end,
  })
  --]]
end

return M
