---@module 'plugins.personal.core.natives'
---@brief The native apps (own repos with a build artifact) next to the plugin checkouts, for `:MyNative`.
---@description
--- Native apps are no lazy specs: they are built, not loaded. This is their list: where the repo is, which
--- artifact a build produces, which paths feed it, the command that builds it and the one that builds and
--- installs it for the current user from the terminal (no downloaded setup.exe, which SmartScreen stops on a
--- managed workstation), the one that uninstalls it, and the tools the build needs. `hint` is what to do by hand
--- when there is no command. What to keep in step when a repo changes: docs/NOTES/builds/maintenance.md.
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
---@field needs? string[] Tools of `bindings.usrcmds.native_repos.toolchain` the build needs
---@field build? string[] argv of a build (no install), run in the repo folder
---@field install? string[] argv of a build plus install for the current user, run in the repo folder
---@field uninstall? string[] argv that removes the installation of the current user, run in the repo folder
---@field hint string What to run by hand (shown when there is no command)

---A desktop app: every one has scripts/build-install.ps1 [-BuildOnly] and scripts/uninstall.ps1.
---@param entry Plugins.Personal.Native
---@return Plugins.Personal.Native
local function desktop(entry)
  entry.build = ps("scripts/build-install.ps1", "-BuildOnly")
  entry.install = ps("scripts/build-install.ps1")
  entry.uninstall = ps("scripts/uninstall.ps1")
  entry.hint = "scripts/build-install.ps1 [-BuildOnly], scripts/uninstall.ps1"
  return entry
end

---@type Plugins.Personal.Native[]
M.list = {
  desktop({
    repo = "WKDSteve/tasks-desktop",
    name = "tasks-desktop",
    artifact = "target/release/tasks-hub.exe",
    sources = { "crates", "ui", "Cargo.lock", "engine.lock" },
    needs = { "rust", "msvc", "node" },
  }),
  desktop({
    repo = "WKDSteve/rules-desktop",
    name = "rules-desktop",
    artifact = "target/release/rules-hub.exe",
    sources = { "crates", "ui", "Cargo.lock" },
    needs = { "rust", "msvc", "node" },
  }),
  -- build-install.ps1 hands over to scripts/setup.ps1, which configures build/ when it is not there
  desktop({
    repo = "WKDSteve/ai-desktop",
    name = "ai-desktop",
    artifact = "build/ai-desktop.exe",
    sources = { "src", "CMakeLists.txt" },
    needs = { "cmake", "mingw64" },
  }),
  {
    repo = "WKDSteve/takt",
    name = "takt",
    hint = "nothing to build yet (the repo is still a skeleton)",
  },
  -- spike stage: only the sink CLI is built; no installer yet, the extension is loaded unpacked from extension/
  {
    repo = "WKDSteve/streamtap",
    name = "streamtap",
    artifact = "desktop/target/release/streamtap-sink.exe",
    sources = { "desktop/crates", "desktop/Cargo.toml", "desktop/Cargo.lock" },
    needs = { "rust", "msvc" },
    build = { "cargo", "build", "--release", "--locked", "--manifest-path", "desktop/Cargo.toml" },
    hint = "cargo build --release --locked --manifest-path desktop/Cargo.toml (no install yet; extension: load unpacked)",
  },
  desktop({
    repo = "WKDSteve/docmap-desktop",
    name = "docmap-desktop",
    artifact = "src-tauri/target/release/docmap-desktop.exe",
    sources = { "src", "src-tauri", "engine.lock" },
    needs = { "rust", "msvc", "tauri-cli" },
  }),
  {
    repo = "WKDSteve/appkit",
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
