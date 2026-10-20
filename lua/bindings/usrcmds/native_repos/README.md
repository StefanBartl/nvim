# `:MyNative`

Sister of `:MyPlugins` for the native apps next to the plugin checkouts. The list is
[`plugins.personal.core.natives`](../../../plugins/personal/core/natives.lua): `tasks-desktop`, `rules-desktop`,
`loomAI`, `takt`, `docmap-desktop`, `appkit`. They are no lazy specs (built, not loaded), so `:MyPlugins` never sees them.

```vim
:MyNative list              " per app: git state, build current / stale / missing
:MyNative clone [name]      " clone what is missing (additive)
:MyNative pull [name]       " git pull --ff-only, only clean repos; dirty or ahead ones are left alone
:MyNative build [name]      " cargo / cmake build of the stale or missing ones, output in the quickfix list
```

- A build is **stale** when the newest commit touching its sources is newer than the artifact (same rule as
  `scripts/sync-machine.ps1`, which keeps its own copy of the table: keep both in step).
- `build` only runs plain build commands (`cargo build --release` for `takt`, `cmake --build build --config Release`
  for `loomAI`). The desktop apps (`tasks-desktop`, `rules-desktop`, `docmap-desktop`) are built by their `setup.exe`,
  so they only print that hint, as do the library repos. It never installs or starts anything. One build at a time.
- Add an app: one entry in `natives.lua` (`repo`, `name`, optional `artifact` + `sources` + `build`, `hint`).

Code: `init.lua`; spec: `TESTS/native_repos/native_repos_spec.lua`.
