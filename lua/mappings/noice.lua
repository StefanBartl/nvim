---@module 'mappings.noice'

local M = {}


function M.setup()
	local map = vim.g.__map_helper
	local ok1, noice = pcall(require, "noice")
	local ok2, noice_lsp = pcall(require, "noice.lsp")

	map({ "n", "i", "s" }, "<A-k>", function()
		if not ok2 or not noice_lsp.scroll(4) then return "<c-f>" end
	end, { silent = true, expr = true, desc = "[Noice] LSP Scroll forward" })

	map({ "n", "i", "s" }, "<A-j>", function()
		if not ok2 or not noice_lsp.scroll(-4) then return "<c-b>" end
	end, { silent = true, expr = true, desc = "[Noice] LSP Scroll backward" })

	map({ "n", "i" }, "<A-x>", function()
		if ok1 then noice.cmd("dismiss") end
	end, { desc = "[Noice] Dismiss UI" })

	map("n", "<lt>n", "<cmd>Noice all<cr>", { silent = true, desc = "[Noice] All" })
	map("n", "<lt>e", "<cmd>Noice errors<cr>", { silent = true, desc = "[Noice] Errors" })
end

return M
