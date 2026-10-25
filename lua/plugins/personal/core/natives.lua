---@module 'plugins.personal.core.natives'
---@brief The native apps (own repos with a build artifact) next to the plugin checkouts, for `:MyNative`.
---@description
--- Native apps are no lazy specs: they are built, not loaded. This is their list: where the repo is, which
--- artifact a build produces, which paths feed it, the command that builds it and the one that builds and
--- installs it for the current user from the terminal (no downloaded setup.exe, which SmartScreen stops on a
--- managed workstation). `hint` is what to do by hand when there is no command.
--- The same facts live in `scripts/sync-machine.ps1` (`$natives`) for the machine-switch check; keep both in step.

local M = {}

-- pwsh when there is one, else the Windows PowerShell every Windows has
local shell = vim.fn.executable("pwsh") == 1 and "pwsh" or "powershell"

---argv of a PowerShell script of the repo
---@param script string Relative to the repo
---@param ... string Arguments of the script
---@return string[]
local function ps(script, ...)
  return { shell, "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", script, ... }
end

---@class Plugins.Personal.Native
---@field repo string "owner/repo"
---@field name string Folder below $REPOS_DIR
---@field artifact? string Path of the build result, relative to the repo (nil: a library or no known artifact)
---@field sources? string[] Paths whose newest commit decides whether the artifact is stale
---@field build? string[] argv of a build (no install), run in the repo folder
---@field install? string[] argv of a build plus install for the current user, run in the repo folder
---@field hint string What to run by hand (shown when there is no command)

---@type Plugins.Personal.Native[]
M.list = {
  {
    repo = "StefanBartl/tasks-desktop",
    name = "tasks-desktop",
    artifact = "target/release/tasks-hub.exe",
    sources = { "crates", "ui", "Cargo.lock", "engine.lock" },
    build = ps("scripts/build-install.ps1", "-BuildOnly"),
    install = ps("scripts/build-install.ps1"),
    hint = "scripts/build-install.ps1 [-BuildOnly]",
  },
  {
    repo = "StefanBartl/rules-desktop",
    name = "rules-desktop",
    artifact = "target/release/rules-hub.exe",
    sources = { "crates", "ui", "Cargo.lock" },
    build = ps("scripts/build-install.ps1", "-BuildOnly"),
    install = ps("scripts/build-install.ps1"),
    hint = "scripts/build-install.ps1 [-BuildOnly]",
  },
  {
    repo = "StefanBartl/ai-desktop",
    name = "ai-desktop",
    artifact = "build/ai-desktop.exe",
    sources = { "src", "CMakeLists.txt" },
    -- setup.ps1 configures build/ when it is not (a bare `cmake --build build` cannot) and vendors third_party/
    build = ps("scripts/setup.ps1", "-SkipInstall"),
    install = ps("scripts/setup.ps1"),
    hint = "scripts/setup.ps1 [-SkipInstall]",
  },
  {
    repo = "StefanBartl/takt",
    name = "takt",
    hint = "nothing to build yet (the repo is still a skeleton)",
  },
  {
    repo = "StefanBartl/docmap-desktop",
    name = "docmap-desktop",
    artifact = "src-tauri/target/release/docmap-desktop.exe",
    sources = { "src", "src-tauri", "engine.lock" },
    build = ps("scripts/build-install.ps1", "-BuildOnly"),
    install = ps("scripts/build-install.ps1"),
    hint = "scripts/build-install.ps1 [-BuildOnly]",
  },
  {
    repo = "StefanBartl/appkit",
    name = "appkit",
    hint = "a library for the desktop apps, nothing to build on its own",
  },
}

---@param name string
---@return Plugins.Personal.Native|nil
function M.get(name)
  for _, native in ipairs(M.list) do
    if native.name == name then
      return native
    end
  end
  return nil
end

---@return string[]
function M.names()
  local out = {}
  for _, native in ipairs(M.list) do
    out[#out + 1] = native.name
  end
  return out
end

return M
