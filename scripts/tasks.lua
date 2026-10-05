---@brief `scripts/tasks.lua` -- headless entry of the wkdbook task engine (list, index, new, set, done, check, ...).
---@description
--- A thin wrapper: it puts this config's `lua/` and lib.nvim on the
--- runtimepath (`-u NONE` loads neither), then hands `arg` to `tasks.cli`.
--- Every rule lives in `lua/tasks/`; there is no second implementation.
---
---     nvim --headless -u NONE -l scripts/tasks.lua list --status=doing
---     nvim --headless -u NONE -l scripts/tasks.lua new lib.nvim "Notify: unify channels" --kind=feature --prio=2
---     nvim --headless -u NONE -l scripts/tasks.lua set lib.nvim/notify-unify-channels status=doing
---     nvim --headless -u NONE -l scripts/tasks.lua done lib.nvim/notify-unify-channels --done-in=lib.nvim@abc1234
---     nvim --headless -u NONE -l scripts/tasks.lua check
---
--- The vault is `$TASKS_VAULT`, else `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins`
--- (override once with `--vault=<dir>`). lib.nvim is found through `$LIB_NVIM_DIR`,
--- `$LIB_NVIM_PATH`, `$REPOS_DIR/lib.nvim`, then lazy.nvim's data folder.
---
--- Placement (TOOL-PLACEMENT.md): workspace tooling that assumes this machine's
--- checkout layout, so it lives in the config's `scripts/`, not in a plugin.
--- Like every `nvim -l` script it reads its arguments from the global `arg`
--- (`...` is empty on current Neovim), and an empty command is a usage error.

-- Absolute: `nvim -l tasks.lua` from inside scripts/ gives a bare relative name, and a relative
-- config root would leave `tasks.*` to be found in whatever config dir Neovim has (another checkout).
local script = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p")
local config_root = vim.fs.dirname(vim.fs.dirname(vim.fs.normalize(script)))

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

vim.opt.rtp:prepend(config_root)
vim.opt.rtp:append(lib)

local argv = {}
for i = 1, #(arg or {}) do
  argv[#argv + 1] = arg[i]
end

local code = require("tasks.cli").run(argv)
io.stdout:flush()
io.stderr:flush()
os.exit(tonumber(code) or 1)
