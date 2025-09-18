---@module 'options'
--- Opinionated Neovim options grouped by topic.

--require("nvchad.options") --- Loads NvChad defaults first, then applies custom overrides.
local opt = vim.opt
local wo = vim.wo

-- AUDIT:
vim.diagnostic.config({
  update_in_insert = false,          -- do not reflow diagnostics while typing
  severity_sort = true,              -- sort by severity (improves sign/virttext order)
  virtual_text = { spacing = 2, prefix = "●" }, -- keep inline hints compact
  float = { border = "rounded", source = "if_many" }, -- nicer hover for diagnostics
})

-----------------------------------------------------------
-- Appearance & UI
-----------------------------------------------------------

-- Enable truecolor support in compatible terminals.
opt.termguicolors = true

-- Line numbers: absolute + relative for efficient motions.
opt.number = true
opt.relativenumber = true

-- Always show the sign column to avoid layout shifts.
opt.signcolumn = "yes" -- "number" / "auto"

wo.wrap = true               -- wrap long lines visually (no hard line breaks)
wo.linebreak = true          -- wrap at word boundaries as per 'breakat'
wo.breakindent = true        -- indent wrapped screen lines
wo.breakindentopt = "shift:2,sbr" -- add +2 spaces and use 'showbreak'
vim.o.showbreak = "⤷ "	            -- prefix shown on continuation screen lines

opt.laststatus = 3 -- ensures 'one' continuous statusline

-----------------------------------------------------------
-- Clipboard
-----------------------------------------------------------

-- Integrate with the system clipboard by default.
opt.clipboard = "unnamedplus"


-----------------------------------------------------------
-- Editing & Indentation
-----------------------------------------------------------

-- Basic and smart indentation helpers.
opt.autoindent = true
opt.smartindent = true

-- Indentation width and tab behavior (project default).
opt.shiftwidth = 2
opt.tabstop = 2
opt.smarttab = true


-----------------------------------------------------------
-- Search
-----------------------------------------------------------

-- Case-insensitive search unless the pattern contains uppercase.
opt.ignorecase = true
opt.smartcase = true


-----------------------------------------------------------
-- Folding (Treesitter-based)
-----------------------------------------------------------

-- Use Treesitter's fold expression; keep folds open by default.
opt.foldmethod = "expr"
opt.foldexpr = "nvim_treesitter#foldexpr()"
opt.foldlevel = 99
opt.foldlevelstart = 99

-- Markdown-specific folding via utils.markdown.foldexpr only for markdown buffers
do
  local grp = vim.api.nvim_create_augroup("MarkdownLocalFolds", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = grp,
    pattern = { "markdown" },
    callback = function()
      vim.opt_local.foldmethod = "expr"
      vim.opt_local.foldexpr = "v:lua.require'utils.markdown'.foldexpr(v:lnum)"
      vim.opt_local.foldenable = true
      vim.opt_local.foldlevel = 99
      vim.opt_local.foldlevelstart = 99
    end,
    desc = "Enable lightweight markdown-specific folding only for markdown buffers",
  })
end

----------------------------------------------------------
-- Performance & Input Latency
-----------------------------------------------------------

-- Make CursorHold-driven UIs react faster (diagnostics, git signs, etc.).
opt.updatetime = 200

-- Make <Esc> feel instant; keep a small timeout for terminal keycodes.
opt.ttimeoutlen = 10


-----------------------------------------------------------
-- Completion & File Globs
-----------------------------------------------------------

-- Skip heavy/irrelevant directories during filename completion.
opt.wildignore:append({
	"*/node_modules/*",
	"*/.git/*",
	"*/dist/*",
	"*/build/*",
})


-----------------------------------------------------------
-- Files & Persistence
-----------------------------------------------------------

-- Do not create backup/writebackup files (use VCS instead).
opt.backup = false
opt.writebackup = false
-- Example: dedicated backup directory:
-- opt.backupdir = vim.fn.stdpath("data") .. "/backup//"

-- Disable swap files to reduce disk churn on large repos.
opt.swapfile = false
-- Example: dedicated swap directory:
-- opt.directory = vim.fn.stdpath("data") .. "/swap//"

-- Enable persistent undo and store it under the cache path.
opt.undofile = true
opt.undodir = vim.fn.stdpath("cache") .. "/undo"

