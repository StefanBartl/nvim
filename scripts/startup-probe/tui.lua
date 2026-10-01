---@module 'startup-probe.tui'
--- Runs the probe in a Neovim that has a UI.
---
--- lazy.nvim fires `User VeryLazy` after UIEnter, and a headless Neovim never
--- gets a UIEnter: every plugin on `event = "VeryLazy"` stays unloaded and
--- whatever those plugins do after loading never runs. This driver starts the
--- probed Neovim in a pseudo terminal it owns, so it comes up with its TUI
--- attached, like a real session.
---
---   nvim --headless -l scripts/startup-probe/tui.lua [args for the probed nvim]
---
--- PROBE, PROBE_MS and PROBE_OUT are read from the environment by probe.lua
--- (the child inherits them). Exits with the child's exit code, 2 on timeout.

-- "." when started from this directory: the source then has no path part.
local here = debug.getinfo(1, "S").source:sub(2):gsub("\\", "/"):match("^(.*)/[^/]*$") or "."

local cmd = { vim.v.progpath, "--cmd", "luafile " .. here .. "/probe.lua" }
for i = 1, #arg do
  cmd[#cmd + 1] = arg[i]
end

-- The terminal the child draws into: without a size it is 80x24.
vim.o.columns, vim.o.lines = 160, 45

local code = nil ---@type integer?
local job = vim.fn.jobstart(cmd, {
  term = true,
  on_exit = function(_, exit_code)
    code = exit_code
  end,
})
if job <= 0 then
  io.stderr:write("startup-probe: could not start " .. vim.v.progpath .. "\n")
  os.exit(1)
end

local budget = (tonumber(vim.env.PROBE_MS) or 6000) + 60000
if not vim.wait(budget, function()
  return code ~= nil
end, 50) then
  vim.fn.jobstop(job)
  io.stderr:write("startup-probe: the probed nvim did not exit within " .. budget .. " ms\n")
  os.exit(2)
end
os.exit(code)
