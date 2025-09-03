---@module 'plugins.fzf'
--- Fuzzy finding tools based on Telescope, fzf-lua, and optional tabbed UI (search.nvim)

--- Build fd options string.
---@return string  -- fd options ready for fzf-lua
---@private
function build_fd_opts()
	local custom_nvim_doc = vim.fn.stdpath("config") .. '/doc'

  -- Base options: files only, include dotfiles, ignore .git
  local parts = {
    "--type", "f",
    "--hidden",
    "--exclude", ".git",
    "--exclude", custom_nvim_doc,
  }
  return table.concat(parts, " ")
end

---@type LazyPluginSpec[]
return {

	-- fzf-lua: Alternative fuzzy finder based on fzf
	{
		"ibhagwan/fzf-lua",
		lazy = true,
		opts = {
			keymap = {
				fzf = {
					["ctrl-p"] = "next-history",
					["ctrl-n"] = "prev-history",
				},
			},
			fzf_opts = {
				["--history"] = vim.fn.stdpath "data" .. "/fzf-history",
			},
			-- Enable glob parsing for live_grep prompts ("query -- *.md !**/node_modules/**")
      grep = {
        rg_glob = true,                 -- interpret ' -- '*.md' part as ripgrep globs
        glob_flag = "--glob",           -- could be "--iglob" if case-insensitive globs are preferred
        glob_separator = "%s%-%-",      -- Lua pattern that matches ' --' in the prompt
        -- Baseline ripgrep options; keep them consistent with your setup
        rg_opts = [[--hidden --line-number --no-heading --color=never --smart-case]],
      },
			      -- Producer-side defaults for file pickers (fd). Prompt still filters client-side.
      files = {
        fd_opts = build_fd_opts(),
      },
		},
	},

}
