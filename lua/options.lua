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
    opt_local.foldexpr = "v:lua.require'markdown.core.fold'.foldexpr(v:lnum)"
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
]]
--

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
  -- WORKSTATION-FREEZE-FIX: Der Firmen-OneDrive spiegelt "Dokumente" (Known
  -- Folder Move), wodurch `Documents\WindowsPowerShell\Modules` in
  -- $PSModulePath landet UND als Files-On-Demand-Platzhalter (online-only)
  -- markiert ist. nvim nutzt PowerShell als Shell (unten), also triggert jeder
  -- system()/Git-/:!-Aufruf eine PowerShell-Command-Discovery, die diesen
  -- OneDrive-Ordner enumerieren muss → Cloud-Rehydrierung → 60-90s UI-Freeze
  -- (gemessen: ein einzelner `Get-Module -ListAvailable`-Scan = 95s).
  -- nvim spawnt PowerShell ohnehin mit -NoProfile und braucht keine
  -- OneDrive-Module, daher entfernen wir alle OneDrive-Pfade aus dem
  -- PSModulePath, den die Kindprozesse erben. Behebt den Freeze an der Wurzel,
  -- unabhängig von OneDrive-Einstellungen/Firmen-Policy.

  -- local psmp = vim.env.PSModulePath
  -- if psmp and psmp:find("OneDrive", 1, true) then
  -- local kept = {}
  -- for entry in psmp:gmatch("[^;]+") do
  -- if not entry:find("OneDrive", 1, true) then
  -- kept[#kept + 1] = entry
  -- end
  -- end
  -- vim.env.PSModulePath = table.concat(kept, ";")
  -- end

  -- The two PowerShell generations want byte-identical options apart from the
  -- binary, so this is one function called with a different name rather than
  -- two branches that have to be kept in sync.
  local function use_powershell(binary)
    o.shell = binary
    o.shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command"
    o.shellredir = "2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode"
    o.shellpipe = "2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode"
    o.shellquote = ""
    o.shellxquote = ""
  end

  -- Windows PowerShell 5.1 is a system component, so this lookup *succeeds*,
  -- and a succeeding `executable()` stops at the first hit: ~0.2-3ms.
  if fn.executable("powershell") == 1 then
    use_powershell("powershell.exe")
  end

  -- pwsh (PowerShell 7) is preferred when present, but the probe for it is
  -- deferred, because a *failing* `executable()` is the expensive one: it
  -- walks every PATH entry against every PATHEXT extension and finds nothing.
  -- Measured here, 67 PATH entries x 11 extensions: ~44ms, and vim.fn does not
  -- cache the result, so it was paid on every single start by everyone who
  -- does not have pwsh installed. That was two thirds of this module's 63ms.
  --
  -- Deferring is safe precisely because the two differ only in `o.shell`: the
  -- shell is already fully configured and working when this runs, and the
  -- upgrade is a one-option swap. Anything that shells out before the first
  -- event-loop tick gets 5.1, which is not a downgrade in behaviour, only in
  -- version.
  vim.schedule(function()
    if fn.executable("pwsh") == 1 then
      use_powershell("pwsh.exe")
    end
  end)
else
  o.shell = fn.executable("zsh") == 1 and "zsh" or "bash"
  o.shellcmdflag = "-c"
end

-----------------------------------------------------------
-- WSL
-------------------------------------------------------
local is_windows = fn.has("win32") == 1

-- Only probe for Wayland tools off Windows. `vim.fn.executable()` on a name
-- that is NOT on $PATH walks every entry and stats candidates before giving
-- up -- measured at ~42ms here, versus ~3ms when the tool is found and the
-- walk stops early. On Windows wl-copy can never be found, so that was 42ms
-- of guaranteed-useless work on every start.
local has_wl_clipboard = not is_windows
  and fn.executable("wl-copy") == 1
  and fn.executable("wl-paste") == 1

if has_wl_clipboard then
  vim.g.clipboard = {
    name = "WaylandClipboard",

    copy = {
      ["+"] = "wl-copy",
      ["*"] = "wl-copy",
    },

    paste = {
      ["+"] = function()
        return vim.fn.systemlist([[wl-paste --no-newline | tr -d '\r']])
      end,

      ["*"] = function()
        return vim.fn.systemlist([[wl-paste --no-newline | tr -d '\r']])
      end,
    },

    cache_enabled = 1,
  }
elseif is_windows and fn.executable("win32yank") == 1 then
  -- Setting this explicitly skips Neovim's clipboard-provider probe, which
  -- spawns a process per candidate tool at startup (~28ms in the startup log,
  -- see docs/ROADMAP/PERF-Startup-Analyse.md). win32yank ships with the
  -- Neovim Windows install, so the executable() guard is a formality -- but it
  -- keeps a machine without it on the probe path rather than with a broken
  -- clipboard.
  vim.g.clipboard = {
    name = "win32yank",

    copy = {
      ["+"] = "win32yank.exe -i --crlf",
      ["*"] = "win32yank.exe -i --crlf",
    },

    paste = {
      ["+"] = "win32yank.exe -o --lf",
      ["*"] = "win32yank.exe -o --lf",
    },

    cache_enabled = 0,
  }
end
