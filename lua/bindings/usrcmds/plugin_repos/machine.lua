---@module 'bindings.usrcmds.plugin_repos.machine'
---@brief `:MyPlugins machine [--pull]` - the machine-switch check of `scripts/sync-machine.ps1`.
---@description
--- Runs the PowerShell script in the background and shows its report in a scratch buffer:
--- per repo under `$REPOS_DIR` (plugins, vaults, the native apps) whether it is behind,
--- ahead, dirty, and whether a native build is older than its sources. Unlike
--- `:MyPlugins sync` it does not stop at the plugin list. With `--pull` clean repos on
--- `main` are fast-forwarded (`git pull --ff-only`); nothing else is ever changed.
--- Doc: `tasks-vault/TOOLS/machine-sync.md`.

local notify = require("lib.nvim.notify").create("[usrcmds.plugin_repos.machine]")
local open_named_scratch = require("lib.nvim.window.open_named_scratch")

local M = {}

local SCRATCH_NAME = "MyPlugins-machine"

---Path of the script inside the config this module was loaded from (so a worktree or a
---junctioned config finds its own copy, not the one under stdpath("config")).
---@return string
function M.script_path()
  local src = debug.getinfo(1, "S").source:sub(2)
  local root = vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(src)))))
  return vim.fs.joinpath(root, "scripts", "sync-machine.ps1")
end

---Argv that runs the script (pwsh when installed, else Windows PowerShell).
---@param opts? { pull?: boolean, only?: string, shell?: string, script?: string }
---@return string[]
function M.build_cmd(opts)
  opts = opts or {}
  local shell = opts.shell or (vim.fn.executable("pwsh") == 1 and "pwsh" or "powershell")
  local cmd = { shell, "-NoProfile", "-File", opts.script or M.script_path() }
  if opts.pull then
    cmd[#cmd + 1] = "-Pull"
  end
  if opts.only and opts.only ~= "" then
    cmd[#cmd + 1] = "-Only"
    cmd[#cmd + 1] = opts.only
  end
  return cmd
end

---Run the check; the report opens in a scratch buffer when the script ends.
---@param opts? { pull?: boolean, only?: string }
function M.run(opts)
  opts = opts or {}
  local script = M.script_path()
  if not (vim.uv or vim.loop).fs_stat(script) then
    notify.error("Script not found: " .. script .. " (pull the nvim config)")
    return
  end
  notify.info(
    "Checking all repos" .. (opts.pull and " (fast-forwarding clean ones)" or "") .. " ..."
  )
  vim.system(M.build_cmd(opts), { text = true }, function(res)
    vim.schedule(function()
      local text = (res.stdout or "") .. (res.stderr or "")
      local lines = vim.split(text, "\r?\n")
      lines[#lines + 1] = ""
      lines[#lines + 1] = ("exit %d - %s"):format(
        res.code,
        res.code == 0 and "everything current" or "needs attention"
      )
      open_named_scratch(SCRATCH_NAME, lines, { split = "below", modifiable = false })
      if res.code == 0 then
        notify.info("All repos current.")
      else
        notify.warn("Some repos need attention - see the report.")
      end
    end)
  end)
end

---@return table[]
function M.routes()
  return {
    {
      path = { "machine" },
      flags = {
        {
          name = "pull",
          bool = true,
          desc = "Fast-forward clean repos on main (git pull --ff-only)",
        },
        { name = "only", type = "STRING", desc = "Comma list of repo names to check" },
      },
      desc = "Machine-switch check over ALL repos in $REPOS_DIR (plugins, vaults, native apps): behind / ahead / dirty and stale native builds, report in a scratch buffer. --pull fast-forwards clean repos on main, --only=a,b limits the run. Runs scripts/sync-machine.ps1",
      run = function(ctx)
        M.run({ pull = ctx.flags.pull == true, only = ctx.flags.only })
      end,
    },
  }
end

return M
