# `:MyNative`

Sister of `:MyPlugins` for the native apps next to the plugin checkouts. The list is
[`plugins.personal.core.natives`](../../../plugins/personal/core/natives.lua): `tasks-desktop`, `rules-desktop`,
`ai-desktop`, `takt`, `docmap-desktop`, `appkit`. They are no lazy specs (built, not loaded), so `:MyPlugins` never sees them.

```vim
:MyNative list              " per app: git state, build current / stale / missing
:MyNative clone [name]      " clone what is missing (additive)
:MyNative pull [name]       " git pull --ff-only, only clean repos; dirty or ahead ones are left alone
:MyNative build [name]      " build the stale or missing ones, output in the quickfix list
:MyNative install [name]    " build and install every cloned app for the current user, no downloaded setup.exe
```

- A build is **stale** when the newest commit touching its sources is newer than the artifact (same rule as
  `scripts/sync-machine.ps1`, which keeps its own copy of the table: keep both in step).
- `build` runs the build script of each repo: `scripts/build-install.ps1 -BuildOnly` (`tasks-desktop`,
  `rules-desktop`, `docmap-desktop`) and `scripts/setup.ps1 -SkipInstall` (`ai-desktop`; it configures `build/`
  when it is not there, which a bare `cmake --build build` cannot). It never installs or starts anything. `takt`
  (a skeleton) and `appkit` (a library) have no command and only print their hint.
- `install` runs the same scripts without `-BuildOnly` / `-SkipInstall`: build, then install for the current user.
  No setup.exe is downloaded, which is what SmartScreen stops on a managed workstation. The hubs install themselves
  (`<hub>.exe install`), `ai-desktop` copies into `%LOCALAPPDATA%\ai-desktop`, `docmap-desktop` runs the NSIS setup it
  just built with `/S` (a file built on the machine has no Mark-of-the-Web). Without a name every cloned app, since
  the build state says nothing about what is installed. The scripts refuse to install inside a Claude session.
- One build or install at a time.
- Without nvim: `pwsh -File scripts\build-install.ps1` in the repo (or the `irm .../releases/download/latest/install.ps1 | iex`
  line of its README, which installs the rolling build of the CI instead of a local one).
- Add an app: one entry in `natives.lua` (`repo`, `name`, optional `artifact` + `sources` + `build` + `install`, `hint`).

Code: `init.lua`; spec: `TESTS/native_repos/native_repos_spec.lua`.
