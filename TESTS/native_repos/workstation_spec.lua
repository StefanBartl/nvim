-- TESTS/native_repos/workstation_spec.lua -- on the workstation nothing builds, installs or starts a
-- native program: :MyNative build|install|deps and B of :MyPlugins machine refuse, uninstall goes on,
-- and the lazy.nvim build hooks that compile native code (fzf-native, mdview's Go server) are left out.
-- The workstation is simulated by replacing `require("machine").is`; the tool steps are probes that
-- throw, so even a run that gets through starts no real program.

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
  local guard = require("bindings.usrcmds.native_repos.workstation")
  local toolchain = require("bindings.usrcmds.native_repos.toolchain")
  local plugin_machine = require("bindings.usrcmds.plugin_repos.machine")
  local dialog = require("lib.nvim.ui.dialog")

  local saved = {
    is = machine.is,
    repos = vim.env.REPOS_DIR,
    ensure = toolchain.ensure,
    check = toolchain.check,
    notify = vim.notify,
    yesno = dialog.yesno,
    native = package.loaded["bindings.usrcmds.native_repos"],
    telescope_actions = package.loaded["telescope.actions"],
    telescope_cfg = package.loaded["config.telescope"],
  }
  -- Runs on success and on failure: TESTS/run.lua runs every spec in this process, so a failed
  -- assertion must not leave the simulated workstation or the silenced vim.notify behind.
  local function restore()
    machine.is, vim.env.REPOS_DIR = saved.is, saved.repos
    toolchain.ensure, toolchain.check = saved.ensure, saved.check
    vim.notify, dialog.yesno = saved.notify, saved.yesno
    package.loaded["bindings.usrcmds.native_repos"] = saved.native
    package.loaded["telescope.actions"] = saved.telescope_actions
    package.loaded["config.telescope"] = saved.telescope_cfg
  end

  local passed, err = pcall(function()
    -- a fresh copy: native_repos_spec ends with an install whose probe never calls back, which
    -- leaves the module's `running` set in this process
    package.loaded["bindings.usrcmds.native_repos"] = nil
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

    -- the lazy.nvim build hooks: lazy runs them on every install/update of the plugin
    local fzf = lazy_spec("lua/plugins/telescope.lua", "nvim-telescope/telescope-fzf-native.nvim")
    ok(fzf, "the fzf-native spec is found")
    eq(fzf.build, nil, "fzf-native is not compiled on the workstation")
    eq(telescope_extensions(), {}, "...and telescope does not try to load it there")
    local mdview = lazy_spec("lua/plugins/personal/specs/view.lua", "WKDSteve/mdview.nvim")
    ok(mdview, "the mdview spec is found")
    eq(
      mdview.build,
      "npm ci && npm run build",
      "mdview's Go server is not built on the workstation"
    )

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
  end)
  restore()
  H.cleanup()
  if not passed then
    error(err, 0)
  end
end
