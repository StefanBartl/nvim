---@module 'mappings.buf_win_tab'

local M = {}

function M.setup()
	local map = vim.g.__map_helper

	-- ---------------------------------------------------------------------------
	--  Buffers
	-- ---------------------------------------------------------------------------

	map("n", "<leader>bn", "<cmd>enew<CR>", { desc = "[Buffers] New" })
	map("n", "<tab>", function() require("nvchad.tabufline").next() end, { desc = "[Buffers] Next" })
	map("n", "<S-tab>", function() require("nvchad.tabufline").prev() end, { desc = "[Buffers] Prev" })
	map("n", "<leader>bc", function() require("nvchad.tabufline").close_buffer() end, { desc = "[Buffers] Close" })
	map("n", "<leader>bx", function()
		local current = vim.api.nvim_get_current_buf()
		-- Check if it's a terminal buffer
		local buftype = vim.bo[current].buftype
		vim.cmd("bnext")
		-- Force delete if terminal, normal delete otherwise
		if buftype == 'terminal' then
			vim.api.nvim_buf_delete(current, { force = true })
		else
			pcall(function()
				vim.api.nvim_buf_delete(current, { force = false })
			end)
		end
	end, { desc = "[Buffers] Close current, go to next" })

	-- ---------------------------------------------------------------------------
	-- Windows
	-- ---------------------------------------------------------------------------

	map("n", "<leader><Esc>", function()
		vim.cmd "qa!"
	end, { desc = "[Wimdows] Force quit all" })

	-- Window closing
	map({ "n", "v" }, "<leader>q", "<Cmd>close!<CR>", { desc = "[Windows] Close window" })
	map("i", "<leader>q", "<C-o><Cmd>close<CR>", { desc = "[Windows] Close window (insert)" })
	map("t", "<leader>q", "<C-\\><C-n><Cmd>close<CR>", { desc = "[Windows] Close window (terminal)" })

	-- Window movement
	map("n", "<C-h>", "<C-w>h", { desc = "[Window] Jump left" })
	map("n", "<C-l>", "<C-w>l", { desc = "[Window] Jump right" })
	map("n", "<C-j>", "<C-w>j", { desc = "[Window] Jump down" })
	map("n", "<C-k>", "<C-w>k", { desc = "[Window] Jump up" })

	-- Resize window
	map({ "n", "t" }, "<A-Left>", "<cmd>vertical resize -5<CR>", { desc = "[Window] Resize narrower" })
	map({ "n", "t" }, "<A-Right>", "<cmd>vertical resize +5<CR>", { desc = "[Window] Resize wider" })
	map({ "n", "t" }, "<A-Up>", "<cmd>resize +5<CR>", { desc = "[Window] Resize taller" })
	map({ "n", "t" }, "<A-Down>", "<cmd>resize -5<CR>", { desc = "[Window] Resize shorter" })

  map("n", "<leader>zm", function() require("utils.window_zoom").zoom_toggle() end, { desc = "[Window] Zoom toggle."})

	-- ---------------------------------------------------------------------------
	-- Tabs
	-- ---------------------------------------------------------------------------

	map("n", "<leader>tn", "<cmd>tabnext<CR>", { desc = "[Tabs] Next tab" })
	map("n", "<leader>tp", "<cmd>tabprevious<CR>", { desc = "[Tabs] Previous tab" })
	map("n", "<leader>tc", "<cmd>tabnew<CR>", { desc = "[Tabs] New tab" })
	map("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "[Tabs] Close tab" })

end

return M
