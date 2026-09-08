---@module 'config.neotree.window.open.keymaps.only_lhs.smoke'
-- Ad hoc smoke test for only_lhs.lua's E95 buffer-name-collision recovery.
-- Not wired into any CI (this repo has no Lua test runner) — run manually
-- after touching that module:
--   nvim --headless -u NONE -l lua/config/neotree/window/open/keymaps/only_lhs.smoke.lua
-- (from the repo root, or adjust the rtp:prepend path below)
--
-- Stubs lib.nvim.bindings.keymap (so M.attach() runs without the real
-- lib.nvim plugin) and neo-tree.command (so the first execute() call can be
-- made to fail exactly like the real E95 race, and the retry exercised
-- without neo-tree.nvim installed). Exits non-zero on failure.

local this = debug.getinfo(1, "S").source:sub(2)
local root = vim.fn.fnamemodify(this, ":p:h:h:h:h:h:h:h") -- lua/config/neotree/window/open/keymaps/… -> repo root
vim.opt.rtp:prepend(root)

local passed, failed = 0, 0
---@param name string
---@param ok boolean
---@param detail string|nil
local function check(name, ok, detail)
  if ok then
    passed = passed + 1
    print("  ok   " .. name)
  else
    failed = failed + 1
    print("  FAIL " .. name .. (detail and ("  — " .. detail) or ""))
  end
end

-- ── stub lib.nvim.bindings.keymap ────────────────────────────────────────────
local bound = {}
package.loaded["lib.nvim.bindings.keymap"] = function(_mode, lhs, rhs, _opts)
  bound[lhs] = rhs
end

-- ── stub neo-tree.command: 1st execute() fails (the E95 race), 2nd (the ────
-- retry) succeeds — mirrors the reported symptom exactly.
local calls = 0
local blank_win
package.loaded["neo-tree.command"] = {
  execute = function(_opts)
    calls = calls + 1
    if calls == 1 then
      -- First call "creates" a window whose buffer never got named — the
      -- actual failure mode: nvim_buf_set_name raised before naming.
      local buf = vim.api.nvim_create_buf(false, true)
      vim.bo[buf].filetype = "neo-tree"
      vim.cmd("vertical sbuffer " .. buf)
      blank_win = vim.api.nvim_get_current_win()
      error("Vim:E95: Buffer with this name already exists")
    end
    -- Second call succeeds: a properly-opened, named neo-tree window.
    local buf2 = vim.api.nvim_create_buf(false, true)
    vim.bo[buf2].filetype = "neo-tree"
    pcall(vim.api.nvim_buf_set_name, buf2, "neo-tree filesystem [1]")
    vim.cmd("vertical sbuffer " .. buf2)
  end,
}

-- ── exercise the mapping ──────────────────────────────────────────────────────
package.loaded["config.neotree.window.open.keymaps.only_lhs"] = nil
local mod = require("config.neotree.window.open.keymaps.only_lhs")
mod.attach()

check("<M-l> got bound", bound["<M-l>"] ~= nil)

local ok_call = pcall(bound["<M-l>"])
check("<M-l> callback does not throw despite the first execute() erroring", ok_call)
check("neo-tree.command.execute was called twice (fail, then retry)", calls == 2, tostring(calls))
check(
  "the blank/broken window was closed by the recovery",
  blank_win == nil or not vim.api.nvim_win_is_valid(blank_win)
)

local found_named = false
for _, w in ipairs(vim.api.nvim_list_wins()) do
  local b = vim.api.nvim_win_get_buf(w)
  if vim.bo[b].filetype == "neo-tree" and vim.api.nvim_buf_get_name(b) ~= "" then
    found_named = true
  end
end
check("a properly-named neo-tree window is left open after recovery", found_named)

print(("\nonly_lhs smoke test: %d passed, %d failed"):format(passed, failed))
if failed > 0 then
  os.exit(1)
end
