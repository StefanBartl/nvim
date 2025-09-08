---@module 'options'
--- Opinionated Neovim options grouped by topic.

--require("nvchad.options") --- Loads NvChad defaults first, then applies custom overrides.

-----------------------------------------------------------
-- Appearance & UI
-----------------------------------------------------------

-- Enable truecolor support in compatible terminals.
vim.opt.termguicolors = true

-- Line numbers: absolute + relative for efficient motions.
vim.opt.number = true
vim.opt.relativenumber = true

-- Always show the sign column to avoid layout shifts.
-- vim.opt.signcolumn = "yes"
vim.opt.signcolumn = "number"

-- vim.opt.wrap = false-- soft-wrap long lines
vim.wo.wrap = true               -- wrap long lines visually (no hard line breaks)
vim.wo.linebreak = true          -- wrap at word boundaries as per 'breakat'
-- vim.wo.breakindent = true        -- indent wrapped screen lines
-- vim.wo.breakindentopt = "shift:2,sbr" -- add +2 spaces and use 'showbreak'
-- vim.o.showbreak = "↳ "           -- prefix shown on continuation screen lines

vim.opt.laststatus = 3 -- ensures 'one' continuous statusline

-----------------------------------------------------------
-- Clipboard
-----------------------------------------------------------

-- Integrate with the system clipboard by default.
vim.opt.clipboard = "unnamedplus"


-----------------------------------------------------------
-- Editing & Indentation
-----------------------------------------------------------

-- Basic and smart indentation helpers.
vim.opt.autoindent = true
vim.opt.smartindent = true

-- Indentation width and tab behavior (project default).
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smarttab = true


-----------------------------------------------------------
-- Search
-----------------------------------------------------------

-- Case-insensitive search unless the pattern contains uppercase.
vim.opt.ignorecase = true
vim.opt.smartcase = true


-----------------------------------------------------------
-- Folding (Treesitter-based)
-----------------------------------------------------------

-- Use Treesitter's fold expression; keep folds open by default.
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99


-----------------------------------------------------------
-- Performance & Input Latency
-----------------------------------------------------------

-- Make CursorHold-driven UIs react faster (diagnostics, git signs, etc.).
vim.opt.updatetime = 200

-- Make <Esc> feel instant; keep a small timeout for terminal keycodes.
vim.opt.ttimeoutlen = 10


-----------------------------------------------------------
-- Completion & File Globs
-----------------------------------------------------------

-- Skip heavy/irrelevant directories during filename completion.
vim.opt.wildignore:append({
	"*/node_modules/*",
	"*/.git/*",
	"*/dist/*",
	"*/build/*",
})


-----------------------------------------------------------
-- Files & Persistence
-----------------------------------------------------------

-- Do not create backup/writebackup files (use VCS instead).
vim.opt.backup = false
vim.opt.writebackup = false
-- Example: dedicated backup directory:
-- vim.opt.backupdir = vim.fn.stdpath("data") .. "/backup//"

-- Disable swap files to reduce disk churn on large repos.
vim.opt.swapfile = false
-- Example: dedicated swap directory:
-- vim.opt.directory = vim.fn.stdpath("data") .. "/swap//"

-- Enable persistent undo and store it under the cache path.
vim.opt.undofile = true
vim.opt.undodir = vim.fn.stdpath("cache") .. "/undo"

