---@module 'options'
--- Opinionated Neovim options grouped by topic.

--require("nvchad.options") --- Loads NvChad defaults first, then applies custom overrides.
local o = vim.o
local opt = vim.opt
local wo = vim.wo
local fn = vim.fn
local opt_local = vim.opt_local

-----------------------------------------------------------
-- Appearance & UI
-----------------------------------------------------------

-- Enable truecolor support in compatible terminals.
opt.termguicolors = true

-- Line numbers: absolute + relative for efficient motions.
-- opt.number = true
-- opt.relativenumber = true
require("wkdoptions.ui.line_numbers")

-- Always show the sign column to avoid layout shifts.
opt.signcolumn = "yes" -- "number" / "auto"

wo.wrap = true -- wrap long lines visually (no hard line breaks)
wo.linebreak = true -- wrap at word boundaries as per 'breakat'
wo.breakindent = true -- indent wrapped screen lines
wo.breakindentopt = "shift:2,sbr" -- add +2 spaces and use 'showbreak'
vim.o.showbreak = "⤷ " -- prefix shown on continuation screen lines

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

-- Indentation width and tab behavior
vim.o.expandtab = true -- use spaces
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
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

-- CHECK: PHASE1A
-- Markdown-specific folding via utils.markdown.foldexpr only for markdown buffers
do
  local autocmd = require("lib.nvim.autocmd")
  autocmd.create("FileType", function()
    opt_local.foldmethod = "expr"
    opt_local.foldexpr = "v:lua.require'markdown_nvim.core.fold'.foldexpr(v:lnum)"
    opt_local.foldenable = true
    opt_local.foldlevel = 99
    opt_local.foldlevelstart = 99
  end, {
    group = autocmd.group("MarkdownLocalFolds", true),
    pattern = { "markdown" },
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
-- opt.backupdir = fn.stdpath("data") .. "/backup//"

-- Disable swap files to reduce disk churn on large repos.
opt.swapfile = false
-- Example: dedicated swap directory:
-- opt.directory = fn.stdpath("data") .. "/swap//"

-- Enable persistent undo and store it under the cache path.
opt.undofile = true
opt.undodir = fn.stdpath("cache") .. "/undo"


-----------------------------------------------------------
-- Diff profile selector
-----------------------------------------------------------

local set_diff_profile = require("wkdoptions.set_diff_profile.selector")

-- options:
-- 'minimal': default minimal diff options
-- 'context': more context lines
-- 'review': best for code reviews
-- 'strict': strict diffing, no context lines

-- Default diff profile
set_diff_profile("review")

--[[
  Recommended accompanying window options (optional): 'OptionSet' autocmd
    Typical errors that this solution avoids:
      - Mixing old and new diffopt values
      - (set diffopt =... in Lua, error-prone)
      - inline strings without validation
      - profile switching without a reset
]]--

require("lib.nvim.autocmd").create("OptionSet", function()
  if vim.wo.diff then
    vim.wo.wrap = false
    vim.wo.cursorbind = false
  end
end, {
  pattern = "diff",
  desc = "Reset wrap/cursorbind when entering diff mode",
})

-----------------------------------------------------------
-- Terminals
-----------------------------------------------------------

if fn.has("win32") == 1 then
  if fn.executable("pwsh") == 1 then
    o.shell = "pwsh.exe"
    o.shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command"
    o.shellredir = "2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode"
    o.shellpipe = "2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode"
    o.shellquote = ""
    o.shellxquote = ""
  elseif fn.executable("powershell") == 1 then
    o.shell = "powershell.exe"
    o.shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command"
    o.shellredir = "2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode"
    o.shellpipe = "2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode"
    o.shellquote = ""
    o.shellxquote = ""
  end
else
  o.shell = fn.executable("zsh") == 1 and "zsh" or "bash"
  o.shellcmdflag = "-c"
end

-----------------------------------------------------------
-- WSL
-------------------------------------------------------
local has_wl_clipboard =
  vim.fn.executable("wl-copy") == 1
  and vim.fn.executable("wl-paste") == 1

if has_wl_clipboard then
  vim.g.clipboard = {
    name = "WaylandClipboard",

    copy = {
      ["+"] = "wl-copy",
      ["*"] = "wl-copy",
    },

    paste = {
      ["+"] = function()
        return vim.fn.systemlist(
          [[wl-paste --no-newline | tr -d '\r']]
        )
      end,

      ["*"] = function()
        return vim.fn.systemlist(
          [[wl-paste --no-newline | tr -d '\r']]
        )
      end,
    },

    cache_enabled = 1,
  }
end
