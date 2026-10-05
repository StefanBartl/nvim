-- TESTS/run.lua -- headless spec runner for the pieces of this config that are plain Lua.
--
-- Run from anywhere:
--   nvim -n -i NONE --headless -u NONE -l TESTS/run.lua
-- One spec only:
--   nvim -n -i NONE --headless -u NONE -l TESTS/run.lua tasks_model_spec.lua
--
-- The specs need lib.nvim; it is looked up like scripts/tasks.lua does
-- ($LIB_NVIM_DIR, $LIB_NVIM_PATH, $REPOS_DIR/lib.nvim, lazy's data folder).
-- Exits 1 when a spec fails, 2 when lib.nvim cannot be found.

local script = debug.getinfo(1, "S").source:sub(2)
local tests_dir = vim.fs.normalize(vim.fs.dirname(script))
local config_root = vim.fs.dirname(tests_dir)

---@param dir string|nil
---@return boolean
local function has_lib(dir)
  return dir ~= nil and dir ~= "" and vim.fn.isdirectory(dir .. "/lua/lib/nvim") == 1
end

---@return string|nil
local function find_lib()
  local repos = vim.env.REPOS_DIR
  local candidates = {
    vim.env.LIB_NVIM_DIR,
    vim.env.LIB_NVIM_PATH,
    (repos and repos ~= "") and (repos .. "/lib.nvim") or "",
    vim.fn.stdpath("data") .. "/lazy/lib.nvim",
  }
  for i = 1, 4 do
    if has_lib(candidates[i]) then
      return candidates[i]
    end
  end
  return nil
end

local lib = find_lib()
if not lib then
  io.stderr:write("error: lib.nvim not found (set LIB_NVIM_DIR or REPOS_DIR)\n")
  os.exit(2)
end

vim.opt.rtp:prepend(config_root)
vim.opt.rtp:append(lib)
-- Specs that start a child Neovim (the CLI end-to-end spec) find lib.nvim the same way.
vim.env.LIB_NVIM_DIR = lib
-- The dashboard records visits for its frecency sort; no spec (nor a child Neovim
-- it starts) may touch the real file in stdpath("state").
vim.env.TASKS_FRECENCY_FILE = vim.fn.tempname() .. "-tasks-frecency.json"

local H = dofile(tests_dir .. "/harness.lua")

local specs = {
  "tasks/tasks_vault_spec.lua",
  "tasks/tasks_fsio_spec.lua",
  "tasks/tasks_model_spec.lua",
  "tasks/tasks_scan_spec.lua",
  "tasks/tasks_index_spec.lua",
  "tasks/tasks_mutate_spec.lua",
  "tasks/tasks_mutate_safety_spec.lua",
  "tasks/tasks_check_spec.lua",
  "tasks/tasks_folder_spec.lua",
  "tasks/tasks_effort_severity_spec.lua",
  "tasks/tasks_form_spec.lua",
  "tasks/tasks_cli_spec.lua",
  "tasks/tasks_routes_spec.lua",
  "tasks/tasks_dash_spec.lua",
  "tasks/tasks_dash_picker_spec.lua",
  "tasks/tasks_frecency_spec.lua",
  "tasks/tasks_dash_watch_spec.lua",
  "tasks/tasks_dash_refresh_spec.lua",
  "tasks/tasks_staleness_spec.lua",
  "tasks/tasks_ci_spec.lua",
}

-- Optional filter: only the specs whose path contains one of the arguments.
local wanted = {}
for i = 1, #(arg or {}) do
  wanted[#wanted + 1] = arg[i]
end

---Straight to stdout: `print` in a headless Neovim goes through the message area
---and can run two results together on one line.
---@param s string
local function say(s)
  io.stdout:write(s, "\n")
end

local ran, failed = 0, 0
for _, name in ipairs(specs) do
  local selected = #wanted == 0
  for _, w in ipairs(wanted) do
    if name:find(w, 1, true) then
      selected = true
    end
  end
  if selected then
    ran = ran + 1
    local run = dofile(tests_dir .. "/" .. name)
    local ok, err = pcall(run, H)
    H.cleanup()
    if ok then
      say(("ok    %s"):format(name))
    else
      failed = failed + 1
      say(("FAIL  %s\n      %s"):format(name, tostring(err)))
    end
  end
end

if ran == 0 then
  say("no spec matched the given name(s)")
  os.exit(2)
end
if failed > 0 then
  say(("\n%d of %d spec(s) failed"):format(failed, ran))
  os.exit(1)
end
say(("\nCONFIG_TESTS_OK (%d spec(s))"):format(ran))
