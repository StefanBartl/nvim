-- TESTS/native_repos/workstation_spec.lua -- on the workstation nothing builds, installs or starts a
-- native program: :MyNative build|install|deps, B of :MyPlugins machine and :MyPlugins runner
-- start|autostart on refuse, uninstall, runner stop/status and autostart off go on, and the lazy.nvim
-- build hooks that compile native code (fzf-native, all of mdview's npm build) are left out. Also how
-- machine.lua reads NVIM_MACHINE_ROLE (blanks, case, unknown values).
-- The workstation is simulated by replacing `require("machine").is`; the tool steps are probes that
-- throw, the terminal and vim.system are fakes, so even a run that gets through starts no real program.

local spec_dir = vim.fs.dirname(debug.getinfo(1, "S").source:sub(2))
local config_root = vim.fs.dirname(vim.fs.dirname(spec_dir))

---The spec table named `name` in a lazy.nvim spec file, read with the current machine role.
---@param file string  # relative to the config root
---@param name string
---@return table|nil
local function lazy_spec(file, name)
  local specs = dofile(config_root .. "/" .. file)
  for _, s in ipairs(specs) do
    if type(s) == "table" and s[1] == name then
      return s
    end
  end
  return nil
end

return function(H)
  local eq, ok = H.eq, H.ok
  local machine = require("machine")
  local guard = require("machine_guard")
  local toolchain = require("bindings.usrcmds.native_repos.toolchain")
  local plugin_machine = require("bindings.usrcmds.plugin_repos.machine")
  local runner = require("bindings.usrcmds.plugin_repos.runner")
  local dialog = require("lib.nvim.ui.dialog")

  local saved = {
    is = machine.is,
    machine = package.loaded.machine,
    role = vim.env.NVIM_MACHINE_ROLE,
    repos = vim.env.REPOS_DIR,
    userprofile = vim.env.USERPROFILE,
    ensure = toolchain.ensure,
    check = toolchain.check,
    notify = vim.notify,
    system = vim.system,
    yesno = dialog.yesno,
    terminal = runner._terminal,
    telescope_actions = package.loaded["telescope.actions"],
    telescope_cfg = package.loaded["config.telescope"],
  }
  -- Runs on success and on failure: TESTS/run.lua runs every spec in this process, so a failed
  -- assertion must not leave the simulated workstation or the silenced vim.notify behind.
  local function restore()
    machine.is, vim.env.REPOS_DIR = saved.is, saved.repos
    package.loaded.machine, vim.env.NVIM_MACHINE_ROLE = saved.machine, saved.role
    vim.env.USERPROFILE, runner._terminal = saved.userprofile, saved.terminal
    toolchain.ensure, toolchain.check = saved.ensure, saved.check
    vim.notify, vim.system, dialog.yesno = saved.notify, saved.system, saved.yesno
    package.loaded["telescope.actions"] = saved.telescope_actions
    package.loaded["config.telescope"] = saved.telescope_cfg
  end

  local passed, err = pcall(function()
    -- the module as native_repos_spec left it (TESTS/run.lua runs both in one process, no fresh
    -- copy): that spec drives its runs to their end, so `running` must be free here
    local native = require("bindings.usrcmds.native_repos")

    local repos = H.tmpdir()
    vim.fn.mkdir(repos .. "/ai-desktop", "p")
    vim.env.REPOS_DIR = repos

    local reached = {}
    toolchain.ensure = function()
      reached[#reached + 1] = "ensure"
      error("probe broke")
    end
    toolchain.check = function()
      reached[#reached + 1] = "check"
      error("probe broke")
    end
    local messages = {}
    vim.notify = function(msg, level)
      messages[#messages + 1] = { msg = tostring(msg), level = level }
    end
    local function blocked_message(what)
      for _, m in ipairs(messages) do
        if m.msg:find(what, 1, true) and m.msg:find("blocked on the workstation", 1, true) then
          return m.level
        end
      end
      return nil
    end

    -- config.telescope needs telescope only for its actions table
    package.loaded["telescope.actions"] = {}
    local function telescope_extensions()
      package.loaded["config.telescope"] = nil
      return require("config.telescope").extensions_list()
    end

    -- the workstation
    machine.is = function(role)
      return role == "workstation"
    end
    eq(guard.active(), true, "the role comes from machine.is, asked at call time")

    native.install("ai-desktop")
    native.install()
    native.deps("ai-desktop")
    native.build("ai-desktop")
    eq(reached, {}, "install, deps and build reach no tool step on the workstation")
    eq(blocked_message(":MyNative install"), vim.log.levels.ERROR, "install says why")
    eq(blocked_message(":MyNative deps"), vim.log.levels.ERROR, "deps says why")
    eq(blocked_message(":MyNative build"), vim.log.levels.ERROR, "build says why")

    local runs = 0
    local fake_terminal = {
      run = function()
        runs = runs + 1
        return true, nil, { bufnr = 1 }
      end,
    }
    local item = {
      Repo = "mdview.nvim",
      Path = repos .. "/ai-desktop",
      Hint = "",
      Command = "node scripts/build-go.mjs",
    }
    eq(
      plugin_machine.build_in_terminal(item, { terminal = fake_terminal, shell = "pwsh" }),
      false,
      "B of :MyPlugins machine starts no build on the workstation"
    )
    eq(runs, 0, "...the terminal is never asked")
    ok(blocked_message(":MyPlugins machine B"), "...and B says why")
    ok(
      (plugin_machine.build_command(item) or ""):find("node scripts/build-go.mjs", 1, true),
      "b (copy the command) is not blocked"
    )

    -- :MyPlugins runner: a runner takes the CI jobs that build the native apps, and `autostart on`
    -- registers a hidden PowerShell at logon; stop, status and autostart off|status stay allowed
    local home = H.tmpdir()
    H.write(home .. "/actions-runners/casedesk.nvim/run.cmd", "@echo off\n")
    vim.env.USERPROFILE = home
    local runner_runs = 0
    runner._terminal = {
      names = function()
        return {}
      end,
      run = function()
        runner_runs = runner_runs + 1
        return true, nil, {}
      end,
    }
    -- a fake vim.system: the schtasks call must never reach the real task scheduler here
    local system_calls = {}
    vim.system = function(argv)
      system_calls[#system_calls + 1] = argv[2]
      return {
        wait = function()
          return { code = 0, stdout = "", stderr = "" }
        end,
      }
    end
    runner.start("casedesk.nvim")
    runner.start()
    eq(runner_runs, 0, "no runner starts on the workstation")
    ok(blocked_message(":MyPlugins runner start"), "...and start says why")
    runner.autostart("on")
    eq(system_calls, {}, "autostart on registers no logon task on the workstation")
    ok(blocked_message(":MyPlugins runner autostart on"), "...and says why")
    runner.autostart("off")
    runner.autostart("status")
    eq(system_calls, { "/Delete", "/Query" }, "autostart off and status still go on")
    vim.system = saved.system

    -- the lazy.nvim build hooks: lazy runs them on every install/update of the plugin. `false`, not
    -- nil: lazy reads a nil `build` as "run the plugin's build.lua / build/init.lua if there is one"
    eq(guard.lazy_build("cmd"), false, "no replacement: no build at all, not even a build.lua")
    eq(guard.lazy_build("cmd", "safe"), "safe", "a replacement runs instead")
    local fzf = lazy_spec("lua/plugins/telescope.lua", "nvim-telescope/telescope-fzf-native.nvim")
    ok(fzf, "the fzf-native spec is found")
    eq(fzf.build, false, "fzf-native is not compiled on the workstation")
    eq(telescope_extensions(), {}, "...and telescope does not try to load it there")
    local mdview = lazy_spec("lua/plugins/personal/specs/view.lua", "WKDSteve/mdview.nvim")
    ok(mdview, "the mdview spec is found")
    -- not even `npm ci && npm run build`: that is wasm-pack, whose cargo compiles and runs build
    -- scripts and proc-macro DLLs, and which fetches and runs wasm-bindgen.exe and wasm-opt.exe
    eq(mdview.build, false, "mdview builds nothing on the workstation")

    -- uninstall stays allowed: it asks its question as everywhere
    local answer_cb
    dialog.yesno = function(_, _, cb)
      answer_cb = cb
    end
    native.uninstall("ai-desktop")
    eq(type(answer_cb), "function", "uninstall goes on on the workstation")
    answer_cb(false)

    -- the same calls off the workstation do reach the tool steps (the probes throw, nothing runs)
    machine.is = function()
      return false
    end
    eq(guard.active(), false, "off the workstation")
    eq(guard.refused("x"), false, "nothing is refused there")
    eq(guard.lazy_build("cmd", "safe"), "cmd", "...and a lazy build hook keeps its command")
    messages = {}
    native.install("ai-desktop")
    native.deps("ai-desktop")
    native.build("ai-desktop")
    eq(reached, { "ensure", "ensure", "check" }, "install, deps and build go on elsewhere")
    eq(blocked_message(":MyNative"), nil, "...without the block message")

    fzf = lazy_spec("lua/plugins/telescope.lua", "nvim-telescope/telescope-fzf-native.nvim")
    ok(type(fzf.build) == "string" and fzf.build ~= "", "fzf-native is compiled elsewhere")
    eq(telescope_extensions(), { "fzf" }, "...and loaded")
    mdview = lazy_spec("lua/plugins/personal/specs/view.lua", "WKDSteve/mdview.nvim")
    eq(
      mdview.build,
      "npm ci && npm run build:go && npm run build",
      "mdview builds its Go server elsewhere"
    )
    runner_runs = 0
    runner.start("casedesk.nvim")
    eq(runner_runs, 1, "a runner starts elsewhere")

    -- machine.lua reads NVIM_MACHINE_ROLE once, when it is loaded: a fresh copy per value. Blanks
    -- around the value do not count (cmd's `set X=workstation ` keeps one): read as an unknown
    -- role it would fall back to "default" and switch the whole block off.
    local function role_for(value)
      vim.env.NVIM_MACHINE_ROLE = value
      package.loaded.machine = nil
      messages = {}
      return { require("machine").role(), #messages }
    end
    eq(
      role_for(" Workstation \t"),
      { "workstation", 0 },
      "blanks and case around the role do not count"
    )
    eq(role_for("   "), { "default", 0 }, "a blank value is no role, like an unset one")
    eq(role_for(nil), { "default", 0 }, "no value is the private machine")
    eq(
      role_for("workstaion"),
      { "default", 1 },
      "an unknown value falls back to default, with a warning"
    )
  end)
  restore()
  H.cleanup()
  if not passed then
    error(err, 0)
  end
end
