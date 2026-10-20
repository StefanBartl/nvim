---@module 'plugins.personal.core.natives'
---@brief The native apps (own repos with a build artifact) next to the plugin checkouts, for `:MyNative`.
---@description
--- Native apps are no lazy specs: they are built, not loaded. This is their list: where the repo is, which
--- artifact a build produces, which paths feed it, and (when a plain build exists) the command that builds it.
--- `hint` is what to do by hand when there is no build command (the desktop apps are built by their setup.exe).
--- The same facts live in `scripts/sync-machine.ps1` (`$natives`) for the machine-switch check; keep both in step.

local M = {}

---@class Plugins.Personal.Native
---@field repo string "owner/repo"
---@field name string Folder below $REPOS_DIR
---@field artifact? string Path of the build result, relative to the repo (nil: a library or no known artifact)
---@field sources? string[] Paths whose newest commit decides whether the artifact is stale
---@field build? string[] argv of a plain build, run in the repo folder
---@field hint string What to run by hand (shown when `build` is nil)

---@type Plugins.Personal.Native[]
M.list = {
  {
    repo = "StefanBartl/tasks-desktop",
    name = "tasks-desktop",
    artifact = "target/release/tasks-hub.exe",
    sources = { "crates", "ui", "Cargo.lock", "engine.lock" },
    hint = "built by its setup.exe (no build command here)",
  },
  {
    repo = "StefanBartl/rules-desktop",
    name = "rules-desktop",
    artifact = "target/release/rules-hub.exe",
    sources = { "crates", "ui", "Cargo.lock" },
    hint = "built by its setup.exe (no build command here)",
  },
  {
    repo = "StefanBartl/loomAI",
    name = "loomAI",
    artifact = "build/loomai.exe",
    sources = { "src", "CMakeLists.txt" },
    build = { "cmake", "--build", "build", "--config", "Release" },
    hint = "cmake --build build --config Release",
  },
  {
    repo = "StefanBartl/takt",
    name = "takt",
    artifact = "target/release/takt-player.exe",
    sources = { "apps", "crates", "Cargo.lock" },
    build = { "cargo", "build", "--release" },
    hint = "cargo build --release",
  },
  {
    repo = "StefanBartl/docmap-desktop",
    name = "docmap-desktop",
    hint = "built by its setup.exe (no build command here)",
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
