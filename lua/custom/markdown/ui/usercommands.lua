---@module 'custom.markdown.ui.usercommands'

local M = {}


-- --- Public setup ------------------------------------------------------------

---@return nil
function M.setup()

	vim.api.nvim_create_user_command("OpenWithSystemApplication", function()
		local line = vim.api.nvim_get_current_line()
		local path = line:match("%[.-%]%((.-)%)")

		if path then
			local current_file = vim.api.nvim_buf_get_name(0)
			local current_dir = vim.fn.fnamemodify(current_file, ":h")
			local full_path = vim.fn.resolve(current_dir .. "/" .. path)

			---AUDIT:USE GLOBAL VARIABLE
			if vim.fn.has("win32") == 1 then
				vim.fn.jobstart({ "cmd.exe", "/c", "start", '""', full_path }, { detach = true })
			elseif vim.fn.has("mac") == 1 then
				vim.fn.jobstart({ "open", full_path }, { detach = true })
			else
				vim.fn.jobstart({ "xdg-open", full_path }, { detach = true })
			end

			vim.notify("Opening: " .. full_path, vim.log.levels.INFO)
		else
			vim.notify("No link found under cursor", vim.log.levels.WARN)
		end
	end, { desc = "Open Markdown link/image with system application" })

end

return M
