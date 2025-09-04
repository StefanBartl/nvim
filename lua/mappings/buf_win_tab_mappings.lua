---@module 'mappings.buffers'

local M = {}

function M.setup()
	local map = vim.g.__map_helper

	map("n", "<leader>bn", "<cmd>enew<CR>", { desc = "[Buffers] New" })
	map("n", "<tab>", function() require("nvchad.tabufline").next() end, { desc = "[Buffers] Next" })
	map("n", "<S-tab>", function() require("nvchad.tabufline").prev() end, { desc = "[Buffers] Prev" })
	map("n", "<leader>bc", function() require("nvchad.tabufline").close_buffer() end, { desc = "[Buffers] Close" })
	map("n", "<leader>bx", function()
		local current = vim.api.nvim_get_current_buf()
		vim.cmd("bnext")
		vim.cmd("bd " .. current)
	end, { desc = "[Buffers] Close current, go to next" })

	map({ "n", "v" }, "<M-x>", "<Cmd>close<CR>", { desc = "[Windows] Close window" })
	map("i", "<M-x>", "<C-o><Cmd>close<CR>", { desc = "[Windows] Close window (insert)" })
	map("t", "<M-x>", "<C-\\><C-n><Cmd>close<CR>", { desc = "[Windows] Close window (terminal)" })

	-- ---------------------------------------------------------------------------
	-- Tab navigation
	-- ---------------------------------------------------------------------------

	-- map("n", "<leader>tn", "<cmd>tabnext<CR>", { desc = "[Tabs] Next tab" })
	-- map("n", "<leader>tp", "<cmd>tabprevious<CR>", { desc = "[Tabs] Previous tab" })
	-- map("n", "<leader>tc", "<cmd>tabnew<CR>", { desc = "[Tabs] New tab" })
	-- map("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "[Tabs] Close tab" })


	map("n", "<leader>del", ":lua confirm_delete()<CR>", { desc = "[General] Delete selected file (confirm)" })
	map("n", "<leader>d!!", ":call DeleteFile()<CR>", { desc = "[General] Delete file (no confirm) & close buffer" })
	map("n", "<leader>dd", function()
		if vim.fn.confirm("Delete all lines in buffer?", "&Yes\n&No", 2) == 1 then
			vim.api.nvim_buf_set_lines(0, 0, -1, false, {})
		end
	end, { desc = "[Buffers] Delete all lines (confirm)" })

 map("n", "<leader>zm", function () require("utils.window_zoom").zoom_toggle() end, { desc = "[Window] Toggle window zoom" })
end

return M
