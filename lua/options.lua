---@module 'options'

require "nvchad.options"

if vim.fn.has("termguicolors") == 1 then
  vim.opt.termguicolors = true
end

vim.opt.clipboard = "unnamedplus" -- Use system clipboard by default

-- Display the filename in the window title bar
vim.opt.title = true
-- Automatically indent new lines to match the previous line's indentation
vim.opt.autoindent = true
-- Smarter indentation based on syntax and filetype
vim.opt.smartindent = true
-- Highlight all search matches
vim.opt.hlsearch = true
-- Show (partial) command in the last line of the screen
vim.opt.showcmd = true
-- Show effects of search/replace in a split preview
vim.opt.inccommand = "split"
-- Case-insensitive search unless pattern contains uppercase letters
vim.opt.ignorecase = true
vim.opt.smartcase = true -- Case-insensitive unless pattern has uppercase
-- Make <Tab> smarter — respects 'shiftwidth', 'tabstop', etc.
vim.opt.smarttab = true
-- Number of spaces for each level of indentation
vim.opt.shiftwidth = 2
-- Display width of a tab character
vim.opt.tabstop = 2
-- Disable line wrapping
vim.opt.wrap = false
-- Ignore node_modules when completing filenames
vim.opt.wildignore:append({ "*/node_modules/*", "*/.git/*", "*/dist/*", "*/build/*" })

--vim.opt.cursorline = true                 -- Highlight current line for readability
vim.opt.list = true -- Visualize whitespace (useful in diffs/reviews)

-- When splitting a window horizontally, put the new window below
vim.opt.splitbelow = true
-- When splitting a window vertically, put the new window to the right
vim.opt.splitright = true

-- Enable undercurl text styling in supported terminals
vim.cmd([[let &t_Cs = "\e[4:3m"]]) -- Start undercurl
vim.cmd([[let &t_Ce = "\e[4:0m"]]) -- End undercurl

-- If Neovim is v0.8 or higher, hide the command line when not in use
if vim.fn.has("nvim-0.8") == 1 then
  vim.opt.cmdheight = 0
end

vim.g.copilot_enabled = true
vim.opt.omnifunc      = "v:lua.vim.lsp.omnifunc" -- completion omnifunc
vim.opt.fileformats   = "unix,dos,mac"

-- Limit completion popup height to reduce visual clutter.
-- Default: 0 (no limit; menu can grow very tall).
vim.opt.pumheight     = 12

-- Subtle transparency for popups and floating windows (requires truecolor-capable terminal/GUI).
-- Default: 0 (no blending).
vim.opt.pumblend      = 10
vim.opt.winblend      = 10

-- Clear, typographic glyphs for visible whitespace (applies when 'list' is enabled).
-- Default: more conservative ASCII placeholders; less expressive.
vim.opt.listchars     = {
  tab      = "» ", -- render a Tab as a chevron + space per tab stop
  trail    = "·", -- mark trailing spaces
  extends  = ">", -- right overflow indicator
  precedes = "<", -- left overflow indicator
  nbsp     = "␣", -- non-breaking space
}

-- Cleaner UI filler characters.
-- eob: remove ~ lines below EOF (quieter look).
-- fold*: Nerd Font icons instead of ASCII (requires a Nerd Font; replace if undesired).
-- diff: suppress filler glyphs in diff for less noise.
-- Default: shows '~' at EOB; ASCII fold markers; diff filler glyphs present.
vim.opt.fillchars:append({
  eob       = " ",
  fold      = " ",
  foldopen  = "",
  foldsep   = " ",
  foldclose = "",
  diff      = " ",
})

-- Faster idle timer so CursorHold-driven UIs (diagnostics, gitsigns) react quickly.
-- Default: 4000 ms (noticeably slower).
vim.opt.updatetime  = 200

-- Very fast terminal keycode timeout to make <Esc> feel instant.
-- Default: 50 ms (slower escape).
vim.opt.ttimeoutlen = 10

-- Higher-quality diffs and nicer behavior.
-- internal: use Neovim's built-in engine (often already enabled by default).
-- filler: keep line numbers aligned with filler lines (often default).
-- closeoff: exit diff when only one window remains (often default).
-- hiddenoff: avoid leaving modified hidden buffers when exiting diff (often default).
-- algorithm:patience: produce more stable hunks on reordered code (upgrade vs default Myers).
-- indent-heuristic: group by indentation for readability (upgrade vs default off).
-- linematch:60: fine-grained line matching (up to ~60ms extra compute) for better hunks (upgrade; not default).
vim.opt.diffopt:append({
  "internal",
  "filler",
  "closeoff",
  "hiddenoff",
  "algorithm:patience",
  "indent-heuristic",
  "linematch:60",
})

-- Quieter command-line.
-- c: suppress ins-completion messages (often already set by default).
-- I: no intro message at startup (often already set by default).
-- W: briefer/suppressed write messages (often already set by default).
-- S: no "search hit BOTTOM/TOP" prompts (this one typically differs from default).
vim.opt.shortmess:append({ c = true, I = true, W = true, S = true })

vim.opt.number = true
vim.o.relativenumber = true
vim.opt.cursorline = true

vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
vim.opt.foldlevel = 99      -- Sets the fold level globally. Folds with level higher than this will be closed.
vim.opt.foldlevelstart = 99 -- Sets the initial fold level when a buffer is opened. If this is lower than `foldlevel`, deeper folds will be closed at startup.

vim.opt.signcolumn = "yes"
vim.opt.cmdheight = 1

vim.opt.backup = false
vim.opt.writebackup = false
-- vim.opt.backupdir = vim.fn.stdpath("data") .. "/backup//"

vim.opt.swapfile = false
--vim.opt.directory = vim.fn.stdpath("data") .. "/swap//"

vim.opt.undofile = true
vim.opt.undodir = vim.fn.stdpath("cache") .. "/undo"
