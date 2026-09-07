---@module 'autocmds.explorer-singleton.smoke'
-- Ad hoc smoke test for autocmds/explorer-singleton.lua's state machine.
-- Not wired into any CI (this repo has no Lua test runner) — run manually
-- after touching that module:
--   nvim --headless -u NONE -l lua/autocmds/explorer-singleton.smoke.lua
-- (from the repo root, or adjust the rtp:prepend path below)
--
-- Uses real Neovim windows/buffers (with faked filetypes) and stubs
-- neo-tree.command / snacks so the actual close/reopen cascade can be
-- exercised without those plugins installed. Exits non-zero on failure.

local this = debug.getinfo(1, "S").source:sub(2)
local root = vim.fn.fnamemodify(this, ":p:h:h:h") -- lua/autocmds/… -> repo root
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

-- ── stub neo-tree.command ────────────────────────────────────────────────────
local neotree_win_handle -- winid currently "showing neo-tree", or nil
local function make_neotree_win()
  -- Filetype is set before the window becomes current, and this uses a plain
  -- `sbuffer` rather than fighting the `:split`-family buffer-clone timing.
  -- Background: wkdbook-Neovim/MyNotes/WinEnter-frisches-Fenster-Timing.md.
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].filetype = "neo-tree"
  vim.cmd("vertical sbuffer " .. buf)
  neotree_win_handle = vim.api.nvim_get_current_win()
  return neotree_win_handle
end

package.loaded["neo-tree.command"] = {
  execute = function(opts)
    if opts.action == "close" then
      if neotree_win_handle and vim.api.nvim_win_is_valid(neotree_win_handle) then
        pcall(vim.api.nvim_win_close, neotree_win_handle, true)
      end
      neotree_win_handle = nil
    elseif opts.action == "show" then
      make_neotree_win()
    end
  end,
}

-- ── stub snacks / snacks.picker ──────────────────────────────────────────────
local snacks_win_handle -- winid currently "showing the explorer picker", or nil
local explorer_active = false

local fake_picker = {
  close = function(_self)
    explorer_active = false
    if snacks_win_handle and vim.api.nvim_win_is_valid(snacks_win_handle) then
      pcall(vim.api.nvim_win_close, snacks_win_handle, true)
    end
    snacks_win_handle = nil
  end,
}

package.loaded["snacks"] = {
  picker = {
    get = function(opts)
      if opts.source == "explorer" and explorer_active then
        return { fake_picker }
      end
      return {}
    end,
  },
  explorer = function()
    -- Real snacks registers the picker in its active-set at construction,
    -- before the window exists -- so `explorer_active` is set first, then the
    -- window via nvim_open_win (matching snacks' real floating picker).
    explorer_active = true
    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].filetype = "snacks_picker_list"
    snacks_win_handle = vim.api.nvim_open_win(buf, true, {
      relative = "editor",
      width = 40,
      height = 10,
      row = 1,
      col = 1,
    })
  end,
}

-- ── exercise the coordinator ──────────────────────────────────────────────────
package.loaded["autocmds.explorer-singleton"] = nil
local coordinator = require("autocmds.explorer-singleton")
coordinator.setup()

-- 1. neo-tree open on the left.
make_neotree_win()
check("setup: neo-tree window exists", neotree_win_handle ~= nil)

-- 2. Open the snacks explorer -- should close neo-tree.
package.loaded["snacks"].explorer()
vim.wait(20)
check(
  "opening snacks explorer closed neo-tree",
  neotree_win_handle == nil or not vim.api.nvim_win_is_valid(neotree_win_handle)
)
check(
  "snacks explorer window exists",
  snacks_win_handle ~= nil and vim.api.nvim_win_is_valid(snacks_win_handle)
)

-- 3. Close the snacks explorer -- should reopen neo-tree exactly once.
fake_picker:close()
vim.wait(50)
check(
  "closing snacks explorer reopened neo-tree",
  neotree_win_handle ~= nil and vim.api.nvim_win_is_valid(neotree_win_handle)
)
check("snacks explorer window is gone", snacks_win_handle == nil)

-- 4. Close that reopened neo-tree -- nothing should come back.
pcall(vim.api.nvim_win_close, neotree_win_handle, true)
neotree_win_handle = nil
vim.wait(50)
check("closing the reopened neo-tree leaves nothing open (no cascade)", snacks_win_handle == nil)

print(("\nexplorer-singleton smoke test: %d passed, %d failed"):format(passed, failed))
if failed > 0 then
  os.exit(1)
end
