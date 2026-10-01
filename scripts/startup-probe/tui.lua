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

-- fnameescape: `luafile` expands % and # in its argument like any file name.
local cmd = { vim.v.progpath, "--cmd", "luafile " .. vim.fn.fnameescape(here .. "/probe.lua") }
for i = 1, #arg do
  cmd[#cmd + 1] = arg[i]
end

-- The child inherits this process's stdout, and a Neovim TUI whose stdout is a
-- pipe draws into the pipe, not only into its pty: tens of KB of escape
-- sequences per run. Harmless for the numbers, noisy for a person.
---@diagnostic disable-next-line: undefined-field -- missing from the uv type stubs
if vim.uv.guess_handle(1) == "pipe" then
  io.stderr:write(
    "startup-probe: stdout is a pipe, so the probed nvim draws its UI into it (25-45 KB of"
      .. " escape sequences). Redirect stdout to a file or NUL; the report goes to PROBE_OUT.\n"
  )
end

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
