---@brief `scripts/tasks.lua` -- headless entry of the task engine for THIS machine's layout (list, index, new, set, done, check, ...).
---@description
--- The personal wrapper around tasks.nvim's own `scripts/tasks.lua`: it finds the plugin and lib.nvim, fills
--- in this author's vault layout as defaults (`$TASKS_VAULT`, `$TASKS_EXTRA_AREAS`), then hands `arg` to
--- `tasks_nvim.cli`. Every rule lives in the plugin; there is no second implementation.
---
---     nvim --headless -u NONE -l scripts/tasks.lua list --status=doing
---     nvim --headless -u NONE -l scripts/tasks.lua new lib.nvim "Notify: unify channels" --kind=feature --prio=2
---     nvim --headless -u NONE -l scripts/tasks.lua set lib.nvim/notify-unify-channels status=doing
---     nvim --headless -u NONE -l scripts/tasks.lua done lib.nvim/notify-unify-channels --done-in=lib.nvim@abc1234
---     nvim --headless -u NONE -l scripts/tasks.lua check
---
--- The vault is `--vault=<dir>`, else `$TASKS_VAULT`, else `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins`.
--- lib.nvim is found through `$LIB_NVIM_DIR`, `$LIB_NVIM_PATH`, `$REPOS_DIR/lib.nvim`, then lazy.nvim's data
--- folder; tasks.nvim through `$TASKS_NVIM_DIR`, `$REPOS_DIR/tasks.nvim`, then lazy.nvim's data folder.
---
--- Placement (TOOL-PLACEMENT.md): workspace tooling that assumes this machine's checkout layout, so it lives
--- in the config's `scripts/`; the generic script ships with the plugin. Like every `nvim -l` script it reads
--- its arguments from the global `arg` (`...` is empty on current Neovim), and an empty command is a usage error.

-- Absolute: `nvim -l tasks.lua` from inside scripts/ gives a bare relative name, and a relative
-- config root would leave `tasks.*` to be found in whatever config dir Neovim has (another checkout).
local script = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p")
local config_root = vim.fs.dirname(vim.fs.dirname(vim.fs.normalize(script)))

---@return string|nil
local function find_tasks_nvim()
  local repos = vim.env.REPOS_DIR
  local candidates = {
    vim.env.TASKS_NVIM_DIR,
    (repos and repos ~= "") and (repos .. "/tasks.nvim") or "",
    vim.fn.stdpath("data") .. "/lazy/tasks.nvim",
  }
  for i = 1, 3 do
    local dir = candidates[i]
    if dir and dir ~= "" and vim.fn.isdirectory(dir .. "/lua/tasks_nvim") == 1 then
      return dir
    end
  end
  return nil
end

---@param dir string|nil
---@return boolean
local function has_lib(dir)
  return dir ~= nil and dir ~= "" and vim.fn.isdirectory(dir .. "/lua/lib/nvim") == 1
end

---@return string|nil
local function find_lib()
  local repos = vim.env.REPOS_DIR
  -- Not a list literal: `ipairs` would stop at the first unset variable.
  local candidates = {
    LIB_NVIM_DIR = vim.env.LIB_NVIM_DIR,
    LIB_NVIM_PATH = vim.env.LIB_NVIM_PATH,
    REPOS_DIR = (repos and repos ~= "") and (repos .. "/lib.nvim") or nil,
    lazy = vim.fn.stdpath("data") .. "/lazy/lib.nvim",
  }
  for _, key in ipairs({ "LIB_NVIM_DIR", "LIB_NVIM_PATH", "REPOS_DIR", "lazy" }) do
    if has_lib(candidates[key]) then
      return candidates[key]
    end
  end
  return nil
end

local lib = find_lib()
if not lib then
  io.stderr:write(
    "error: lib.nvim not found (set LIB_NVIM_DIR, or REPOS_DIR with a lib.nvim checkout)\n"
  )
  os.exit(2)
end

local tasks_nvim = find_tasks_nvim()
if not tasks_nvim then
  io.stderr:write(
    "error: tasks.nvim not found (set TASKS_NVIM_DIR, or REPOS_DIR with a tasks.nvim checkout)\n"
  )
  os.exit(2)
end

-- This author's vault layout, as defaults only: an exported variable wins.
local repos_dir = vim.env.REPOS_DIR
if (not vim.env.TASKS_VAULT or vim.env.TASKS_VAULT == "") and repos_dir and repos_dir ~= "" then
  vim.env.TASKS_VAULT = repos_dir .. "/WKDBooks/Development/wkdbook-myplugins"
end
if not vim.env.TASKS_EXTRA_AREAS or vim.env.TASKS_EXTRA_AREAS == "" then
  vim.env.TASKS_EXTRA_AREAS = "ALL,nvim-config,docmap-desktop,migrate.nvim"
end

vim.opt.rtp:prepend(config_root)
vim.opt.rtp:append(lib)
vim.opt.rtp:append(tasks_nvim)

local argv = {}
for i = 1, #(arg or {}) do
  argv[#argv + 1] = arg[i]
end

local code = require("tasks_nvim.cli").run(argv)
io.stdout:flush()
io.stderr:flush()
os.exit(tonumber(code) or 1)
