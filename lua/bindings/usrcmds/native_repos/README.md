# `:MyNative`

Sister of `:MyPlugins` for the native apps next to the plugin checkouts. The list is
[`plugins.personal.core.natives`](../../../plugins/personal/core/natives.lua): `tasks-desktop`, `rules-desktop`,
`ai-desktop`, `takt`, `streamtap`, `docmap-desktop`, `appkit`. They are no lazy specs (built, not loaded), so `:MyPlugins` never sees them.

```vim
:MyNative list               " per app: git state, build current / stale / missing
:MyNative clone [name]       " clone what is missing (additive)
:MyNative pull [name]        " git pull --ff-only, only clean repos; dirty or ahead ones are left alone
:MyNative deps [name]        " check the tools, install the missing ones that need no administrator
:MyNative build [name]       " build the stale or missing ones, output in the quickfix list
:MyNative install [name]     " tools, then build and install every cloned app for the current user
:MyNative uninstall [name]   " remove the installation of every cloned app (asks first; scripts/uninstall.ps1)
```

- **Blocked on the workstation.** With `NVIM_MACHINE_ROLE=workstation` (read by `lua/machine.lua`,
  `require("machine").is("workstation")`) `build`, `install` and `deps` stop at once with an error message: an own
  unsigned program is exactly what CrowdStrike Falcon reports there. `list`, `clone`, `pull` and `uninstall` stay
  allowed. The same block covers `B` of `:MyPlugins machine` (`b`, copying the command, still works),
  `:MyPlugins runner start` and `runner autostart on` (a runner builds the native apps in its CI jobs; `stop`,
  `status` and `autostart off|status` still work) and the lazy.nvim `build` hooks that compile native code:
  telescope-fzf-native gets no build there (telescope then skips the `fzf` extension and keeps its Lua sorter) and
  mdview.nvim gets no build at all (`build:go` is the Go server, and `npm run build` is wasm-pack, whose cargo
  compiles and runs build scripts and which fetches and runs `wasm-bindgen.exe`/`wasm-opt.exe`); mdview then uses
  its release assets. Code: [`lua/machine_guard.lua`](../../../machine_guard.lua) (`refused()`, `lazy_build()`),
  config-wide next to `lua/machine.lua`, since plugin specs and `config.telescope` ask it too.
- A build is **stale** when the newest commit touching its sources is newer than the artifact (same rule as
  `scripts/sync-machine.ps1`, which keeps its own copy of the table: keep both in step).
- Every desktop app has the same three scripts: `scripts/build-install.ps1 -BuildOnly` is the build,
  `scripts/build-install.ps1` builds and installs, `scripts/uninstall.ps1` removes. ai-desktop's `build-install.ps1`
  hands over to `scripts/setup.ps1`, which configures `build/` when it is not there (a bare `cmake --build build`
  cannot). `takt` (a skeleton) and `appkit` (a library) have no command and only print their hint. `streamtap`
  (spike stage) builds its sink CLI with `scripts/build.ps1` (refuses while the sink runs, touches the exe so a
  no-op build counts as current) and has no install or uninstall command yet.
- `deps`: the tools are in [`toolchain.lua`](toolchain.lua), each app names its own (`needs`). Installed for the
  current user: rustup (winget), the Tauri CLI (cargo), the MinGW-w64 packages of MSYS2 (pacman). Only named, since
  they need an administrator: Node.js, CMake, the MSVC build tools, MSYS2 itself.
- `install` runs `deps` first and skips an app whose tools are still missing (named in the message). No setup.exe
  is downloaded, which is what SmartScreen stops on a managed workstation. The hubs install themselves
  (`<hub>.exe install`), `ai-desktop` copies into `%LOCALAPPDATA%\ai-desktop` and puts its launcher on the user PATH,
  `docmap-desktop` runs the NSIS setup it just built with `/S` (a file built on the machine has no Mark-of-the-Web).
  Without a name every cloned app, since the build state says nothing about what is installed. `build` skips an app
  with missing tools as well, but installs none.
- The scripts refuse to install or uninstall inside a Claude session (it redirects AppData and HKCU).
- One build, install or deps run at a time.
- Without nvim: `pwsh -File scripts\build-install.ps1` in the repo (or the `irm .../releases/download/latest/install.ps1 | iex`
  line of its README, which installs the rolling build of the CI instead of a local one).
- Tools, paths and install folders: `docs/NOTES/builds/toolchain.md`; what to keep in step when a repo changes or an
  app is added: `docs/NOTES/builds/maintenance.md`.

Code: `init.lua`, `toolchain.lua`, `lua/machine_guard.lua` (the workstation block); specs: `TESTS/native_repos/native_repos_spec.lua`,
`TESTS/native_repos/workstation_spec.lua` (the workstation block, simulated).
