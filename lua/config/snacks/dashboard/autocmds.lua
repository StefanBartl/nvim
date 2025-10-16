---@module 'config.snacks.dashboard.autocmds'

local nvim_create_autocmd = vim.api.nvim_create_autocmd
local desc_tag = "[snacks.dashboard]: "

-- Small discoverability hint (non-intrusive, once).
nvim_create_autocmd("VimEnter", {
	once = true,
	callback = function()
		vim.defer_fn(function()
			vim.notify("Snacks ready · dashboard with Sessions loaded", vim.log.levels.DEBUG)
		end, 50)
	end,
	desc = desc_tag .. "Snacks init hint",
})

nvim_create_autocmd({"BufWinEnter"}, {
  callback = function()
    local ok_dash, dash = pcall(require, "snacks.dashboard")
    if ok_dash and type(dash.open) == "function" then
      -- Avoid opening if a buffer is already loaded to prevent flicker
      if vim.fn.winnr('$') == 1 and vim.fn.bufname() == "" then
        vim.defer_fn(function()
          pcall(dash.open)
        end, 10)
      end
    end
  end,
  desc = desc_tag .. "Always open custom Snacks dashboard on startup or empty buffer",
})
