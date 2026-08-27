# Testing sandbox.nvim

How to manually test every implemented feature of `sandbox.nvim`. One-time
setup, then one section per feature: prerequisites, steps, what to expect.
Checkbox syntax (`- [ ]`) throughout.

**Prerequisite for almost everything below**: a real, running Docker,
Podman, or nerdctl install. sandbox.nvim is a thin hexagonal layer over
those CLIs — `:checkhealth sandbox` (§Setup) tells you which are actually
usable on this machine before you try anything else. Sections that only
need the plugin itself, no engine (§1 engine detection reporting, most of
§13 WSL structure checks) are noted as such; everything else needs at least
one real engine with the daemon actually running (Docker Desktop / Podman
machine started).

Repo: `E:\repos\sandbox.nvim`. Spec: `lua/plugins/personal/init.lua` —
`event = "VeryLazy"`, `dependencies = { "StefanBartl/lib.nvim" }`, `opts =
{ progress_style = "statusline" }` (the only override — `image pull`/`push`
and the devcontainer build report into the shared `lib.nvim.progress`
registry, rendered by the statusline's `plugin_progress` module). Note this
config uses `event = "VeryLazy"`, not the README's own "recommended"
`event = "VimEnter"` — both are valid per the README's own comparison
table, just worth knowing which one is actually active here. `engine` is
**not** set, so this machine auto-detects: Podman preferred if installed,
else Docker, else nerdctl — confirm which one actually won in §1 before
assuming.

**Telemetry note**: 50 accumulated sessions, but only 40 total calls
recorded across all 517 instrumented functions, and every one of them is
`logger.flush` — background log-buffer flushing, not a feature entry
point. There is **no** usable priority signal here at all, not even a weak
one (contrast `reposcope.nvim`'s checklist, where a few non-entry-point
calls at least hinted at real usage). Ordering below follows the README's
own Features list and `docs/WORKFLOW.md`'s explicit framing: "the single
biggest habit change this plugin asks for" is the container list view, so
that leads.

## Setup

```vim
:checkhealth sandbox
```

**Expect**: which engine CLI(s) were actually found on `PATH`, which one is
**active** and why (session override / `.sandboxrc` / configured-or-detected
default — this config has none of the first two, so it should say
"detected"), and whether `lib.nvim` (required) / telescope.nvim (optional)
are present.

- [ ] Note the active engine now — every section below that shows example
      output should be cross-checked against *this* engine's real CLI output
      (`podman ps`/`docker ps`/`nerdctl ps` in a terminal), not assumed.
- [ ] If you have more than one engine installed, this is also the moment
      to confirm the detection preference actually held (Podman > Docker >
      nerdctl) — temporarily rename/hide the higher-priority one's binary
      from `PATH` (a new shell, not this Neovim session) and restart Neovim
      to see the fallback in action, if you want to verify it rather than
      trust the doc.

---

## 1. Container list view — the core habit

Per `docs/WORKFLOW.md`: "stop copying container ids out of `docker ps` and
into commands." This is the plugin's own stated flagship interaction.

**Steps**

```vim
:Sandbox container list
```

(with at least one real container present — `docker run -d --name
sbx-test alpine sleep 300`, or the engine's equivalent, if you don't have
one handy)

- [ ] Opens a read-only scratch buffer (`sandbox.nvim://container-list`)
      listing every container, running **and** stopped, each with a
      `[status]` prefix colored by state (green running, red stopped,
      yellow paused, comment-colored other) — confirm the colors actually
      track a real running vs. stopped container, not just present.
- [ ] On the running test container: `s`/`x`/`X`/`r` (start/stop/kill/
      restart), `p`/`P` (pause/unpause), `<CR>`/`i` (inspect), `l`/`L`
      (logs / logs-follow), `e` (exec shell), `t`/`T` (top/stats), `n`
      (rename, prompts), `D` (remove) — try at least start/stop, inspect,
      logs, and exec for real; confirm each acts on the entry **under the
      cursor**, not a stale id typed into a `:Sandbox` command.
- [ ] `R` refreshes the list — stop a container from a separate terminal,
      `R` in the buffer, confirm its status updates without reopening.
- [ ] `opts.refresh_interval` (unset by default here — try
      `:lua require("sandbox.config").set("refresh_interval", 2000)` for
      this test) — the list should now re-render itself; switch away to a
      different buffer/window and confirm the timer pauses (check via the
      engine that no runaway process shows up, or just trust the doc's
      claim and confirm no error occurs); `:bwipeout` the list buffer and
      confirm the timer actually stops (no lingering autocmd error later).
- [ ] Multi-select: `V`, select 2–3 stopped test containers, press `D` —
      one confirmation for the **whole batch**, not one per container;
      confirm the prompt **lists the item names** (capped at 10, "… and N
      more" beyond that), not just "Remove 3 containers?".
- [ ] `<RightMouse>` on a row — if `nvzone/menu` is installed, a context
      menu mirroring the row's own keymaps; if not, confirm it's silently
      inert (no error), since `menu.enable = true` here just gates the
      trigger, not its presence.

---

## 2. `--buffer`/`-b` streaming vs. collapsed notify

**Steps**

```vim
:Sandbox image pull alpine
:Sandbox image pull alpine --buffer
```

(or `-b`; pick a small image you don't mind pulling twice — cache makes
the second pull near-instant anyway, which is itself worth noticing)

- [ ] Without the flag: a single `vim.notify` on completion, no visible
      buffer.
- [ ] With `--buffer`/`-b`: a scrollable terminal buffer streaming the raw
      pull output live, not just a summary at the end.
- [ ] Try the same distinction on `container start`/`stop` — a one-line
      operation like `stop` rarely needs it, but confirm the flag is at
      least *accepted* without erroring even where it's not very useful.

---

## 3. Container run wizard, exec (+ `workdir=`), logs-follow

**Steps**

```vim
:Sandbox container run
```

Answer the prompts (image `alpine`, a name, skip ports/volumes/env if you
want a fast pass). Then:

```vim
:Sandbox container exec <name> bash workdir=/tmp
:Sandbox container exec-once <name> workdir=/tmp ls -la
:Sandbox container logs-follow <name>
```

- [ ] `run` prompts in sequence (image → name → ports → volumes → env) and
      actually starts a real, running container — confirm via `container
      list` or the engine CLI directly afterward.
- [ ] `exec` opens an interactive shell inside it — confirm `workdir=/tmp`
      really lands you in `/tmp` (`pwd` inside the shell), and that putting
      `workdir=` is required to come **before** anything positional —
      confirm the docs' warning is real by trying `exec <name> bash
      workdir=/tmp` (workdir before the command) vs. `exec <name> workdir=/tmp
      bash` if you want to see the failure mode described (workdir handed
      to the inner command instead of consumed).
- [ ] `exec-once` runs one command non-interactively and shows real output
      (the actual `ls -la` listing).
- [ ] `logs-follow` streams live — generate some log output from inside the
      container (`docker exec <name> sh -c 'while true; do echo hi; sleep
      1; done'` from a separate terminal) and confirm new lines appear
      without re-running the command. `q` in the buffer stops the follow —
      confirm the underlying job actually stops (check `:jobs`-equivalent
      or just that CPU/notify activity ends). Then start `logs-follow`
      again and `:bwipeout` the buffer directly instead of pressing `q` —
      confirm the background job is still cleaned up (the `BufWipeout`
      safety net).
- [ ] `container stats`/`container top` on the running container — real,
      current numbers (not zeros or placeholders).
- [ ] `container cp <name>:/etc/hostname ./hostname.txt` then the reverse
      direction — confirm the file round-trips with real content on both
      sides.

---

## 4. Images: pull/push/build/tag/save/load/history/inspect/remove/prune

**Steps**

```vim
:Sandbox image list
:Sandbox image build sbx-test-img:latest .
```

(from a directory with a trivial `Dockerfile`, e.g. `FROM alpine` +
`RUN echo hi`, if you don't have one handy — a two-line scratch file works)

- [ ] `image list` opens a read-only buffer; `<CR>`/`i` inspect, `h`
      history, `t` tag (prompts for target), `D` remove, `R` refresh — try
      `t` on the image you just built, confirm `image list` shows both tags
      afterward.
- [ ] `build` streams output into a terminal buffer (build logs are
      inherently verbose — confirm it isn't silently collapsed the way a
      one-line command might be) and the resulting image is real (`image
      list` shows it, or `docker images` directly).
- [ ] `image save sbx-test-img:latest ./sbx-test.tar`, then `image remove
      sbx-test-img:latest`, then `image load ./sbx-test.tar` — confirm the
      image is genuinely gone after `remove` and genuinely back after
      `load` (check `image list` at each step, not just trust the notify).
- [ ] `image history sbx-test-img:latest` — real layer history, not empty.
- [ ] `image prune` — confirm it only removes **dangling** images (build
      something, don't tag the old version when rebuilding, then prune and
      confirm only the untagged one disappears).
- [ ] With `opts.confirm_destructive = false` (scratch `setup()` override)
      — `image remove`/`prune` should skip the confirmation prompt
      entirely; confirm it actually removed something rather than just
      skipping silently.

---

## 5. Volumes and networks

**Steps**

```vim
:Sandbox volume create sbx-test-vol
:Sandbox volume list
:Sandbox network create sbx-test-net
:Sandbox network list
```

- [ ] Both list views open, show the real created resource, and support
      `<CR>`/`i` (inspect), `D` (remove), `R` (refresh) — try inspect on
      each, confirm real engine metadata in the folded `vim.inspect`-style
      view (`za`/`zo`/`zc` to toggle sections, `q` to close).
- [ ] `network connect sbx-test-net <container-name>` /
      `network disconnect sbx-test-net <container-name>` on a running
      container — confirm via `container inspect <name>` (or the engine
      CLI) that the network actually attached/detached.
- [ ] `volume prune` / `network prune` — confirm only genuinely **unused**
      resources are removed (a volume mounted into a running container
      should survive a prune attempt, or at minimum the engine's own
      refusal should surface cleanly, not crash the command).

---

## 6. Compose (`:Sandbox compose ...`) — auto-detected from cwd

**Prerequisites**: a real `docker-compose.yml`/`compose.yml` — a trivial
one works:
```yaml
services:
  web:
    image: alpine
    command: sleep 300
```

**Steps**

`cd` (or `:cd`) into that directory first — per `docs/WORKFLOW.md`,
compose takes **no** id/name argument, it walks up from cwd to find the
file.

```vim
:Sandbox compose up
:Sandbox compose ps
:Sandbox compose logs
:Sandbox compose restart
:Sandbox compose down
```

- [ ] `up` starts the project detached — confirm via `compose ps` or
      `container list` that the `web` service is really running.
- [ ] Run the same commands from a Neovim session `cd`'d **outside** the
      compose project's directory tree — confirm it either fails cleanly
      ("no compose file found") or, per the documented risk, finds a
      *different* project's compose file further up the tree if one
      happens to exist there. Worth confirming this trap is real, not just
      documented.
- [ ] `down` actually stops **and removes** the containers (not just
      stops) — confirm via `container list` afterward that they're gone,
      not just stopped.
- [ ] Progress for `up` shows in the statusline (this config's
      `progress_style = "statusline"`).

---

## 7. Devcontainer (`:Sandbox devcontainer ...`) — experimental

**Prerequisites**: a `.devcontainer/devcontainer.json` — a minimal one:
```json
{ "image": "alpine", "workspaceFolder": "/workspace" }
```

**Steps**

`cd` into that project's root.

```vim
:Sandbox devcontainer build
:Sandbox devcontainer attach
```

- [ ] `build` resolves the image (a plain `image` field pulls directly;
      `build.dockerfile` builds locally — try whichever your test file
      uses), starts it with the workspace bind-mounted at
      `workspaceFolder`, and names it predictably
      (`sandbox-devcontainer-<workspace-dir-basename>`) — confirm via
      `container list` that the name matches this pattern.
- [ ] `attach` finds that same container by name and opens a shell in it —
      confirm you land inside `/workspace` with the real project files
      bind-mounted (touch a file inside, check it appears on the host).
- [ ] If your test file uses `dockerComposeFile` instead, confirm `build`
      transparently delegates to `compose up` — you should **not** need to
      run `compose up` yourself first.
- [ ] JSONC support: add a `//` comment and a trailing comma to the test
      `devcontainer.json`, `build` again — confirm it still parses (comments
      and trailing commas are stripped before parsing).

---

## 8. Registry login/logout

**Prerequisites**: a real registry account (Docker Hub, GHCR, or any
private registry you can safely test against) — or just confirm the
prompt/stdin mechanics without a real successful login if you'd rather not
use real credentials in a test.

**Steps**

```vim
:Sandbox registry login
```

(on Podman: `:Sandbox registry login docker.io` — Podman has no implicit
Docker Hub default, unlike Docker)

- [ ] Prompts for username (`vim.ui.input`) then password
      (`vim.fn.inputsecret`, masked — confirm the typed password is not
      echoed to the command line).
- [ ] The password never appears in `:messages`, shell history, or (if you
      can check) the process list — it's piped via stdin
      (`--password-stdin`), not passed as an argv element.
- [ ] After a real successful login, `:Sandbox image push <your-tag>` on an
      image you're allowed to push should succeed; `registry logout`
      afterward, then the same push should fail with an auth error.
- [ ] On Podman specifically: `:Sandbox registry login` with **no**
      registry argument — confirm it's refused/prompts for one, rather than
      silently assuming Docker Hub the way Docker's own login does.

---

## 9. Engine switching

**Prerequisites**: at least two of Docker/Podman/nerdctl installed to see
a real switch; with only one, confirm the commands at least report
correctly rather than erroring.

**Steps**

```vim
:Sandbox engine get
:Sandbox engine set docker
:Sandbox engine get
:Sandbox engine reset
:Sandbox engine get
```

- [ ] First `get` should report the auto-detected engine and say **why**
      (this config has no `.sandboxrc`/explicit `engine=`, so it should
      name "detected default", not a session override).
- [ ] `set docker` (or whichever you don't currently have active) switches
      immediately, no restart — confirm `:Sandbox container list` now
      reflects the **other** engine's real containers (if you have any
      running under it) or at least a clean empty list, not a stale
      previous-engine listing.
- [ ] Second `get` should now report "session override".
- [ ] `reset` clears the override — third `get` should fall back to
      `.sandboxrc`/detected default again, matching the very first `get`.
- [ ] **`.sandboxrc` precedence**: drop a `.sandboxrc` with `engine=podman`
      (or whichever isn't your default) in a scratch project directory,
      `:cd` into it, `:Sandbox engine get` — should report the `.sandboxrc`
      source, not the global default. `:Sandbox engine set <other>` inside
      that same directory should still override it for the session
      (session override beats `.sandboxrc` per the documented precedence).
- [ ] **`E` from inside a list view**: `:Sandbox container list`, press `E`
      — cycles docker → podman → nerdctl (declared order, not `pairs()`
      iteration — confirm it lands the same place on a second full cycle)
      and **re-renders** the list in place, no need to leave the buffer.

---

## 10. WSL distro management — Windows-only, conditional

**Prerequisites**: Windows with WSL installed (`wsl.exe` on `PATH`) — this
machine qualifies per the environment info, so this should be fully
testable, not just structurally.

**Steps**

```vim
:Sandbox wsl list
```

- [ ] Lists real registered distros — cross-check against `wsl --list
      --verbose` in a real terminal.
- [ ] `:Sandbox wsl<Tab>` completes to a real subcommand list (`list`,
      `start`, `stop`, `exec`, `set-default`, `set-version`, `export`,
      `import`, `shutdown-all`) — since WSL is available here, this
      registration should be present; this is the one thing worth actively
      confirming given the docs explicitly warn it's conditional.
- [ ] `:Sandbox wsl start <name>` / `wsl stop <name>` on a real, non-default
      distro you don't mind starting/stopping — confirm state actually
      changes (`wsl --list --verbose` again).
- [ ] `:Sandbox wsl exec <name> echo hello` — real command execution
      inside the distro, real output.
- [ ] `:Sandbox wsl set-default <name>` — confirm `wsl --list --verbose`
      shows the new default (`*` marker), then set it back.
- [ ] `:Sandbox wsl export <name> <path>.tar` — confirm a real, non-empty
      tarball appears on disk.
- [ ] `:Sandbox wsl shutdown-all` — confirms first (same
      `confirm_destructive` gate); **only run this if you're prepared for
      every running distro to actually stop**, including any you're using
      for other work right now.

---

## 11. Telescope picker extension

**Prerequisites**: telescope.nvim installed (it is, in this config) —
opt-in, not loaded until explicitly requested.

**Steps**

```lua
require("telescope").load_extension("sandbox")
```

```vim
:Telescope sandbox containers
:Telescope sandbox images
:Telescope sandbox wsl
```

- [ ] `containers`: `<CR>` inspect, `<C-s>` start, `<C-x>` stop, `<C-r>`
      restart, `<C-l>` logs, `<C-d>` remove — confirm at least start/stop
      and inspect act on the real container under the cursor, matching what
      the list-view buffer's own keymaps would do for the same action.
- [ ] `images`: `<CR>` inspect, `<C-h>` history, `<C-d>` remove.
- [ ] `wsl`: `<CR>` exec, `<C-s>` start, `<C-x>` stop, `<C-d>` set default.
- [ ] Before `load_extension` is called, confirm `:Telescope sandbox ...`
      doesn't exist/errors cleanly — it's genuinely not loaded until opted
      into.

---

## 12. Statusline component

**Steps**

```lua
:lua print(require("sandbox.statusline").status())
```

- [ ] Real output shaped `"<engine> (running/total)"`, e.g. `"docker
      (2/5)"` — cross-check the counts against `:Sandbox container list`.
- [ ] Call it twice within 3 seconds (`status_cache_ttl_ms` default) — a
      cached read shouldn't shell out again; start/stop a container in
      between and confirm the number **doesn't** update until the cache
      window passes (or call it again after 3s and confirm it does).
- [ ] Stop the engine daemon entirely (or point at a nonexistent engine via
      a scratch `setup({ engine = "docker" })` when Docker isn't installed)
      — should degrade to `""`, not error.

---

## 13. `docs generate` and route-table integrity

**Steps**

```vim
:Sandbox docs generate
```

- [ ] Regenerates `docs/GENERATED_COMMANDS.md` in the plugin's own repo
      from the live route table — confirm the file's mtime actually updates
      and its content lists real subcommands you've been using above
      (`container list`, `compose up`, etc.).
- [ ] Spot-diff it against `docs/BINDINGS.md` for anything that looks
      stale in the hand-maintained doc — not expected to find anything (the
      workflow doc frames this as a pre-PR check), but worth one real
      diff pass since you have both open already.

---

## What this checklist does not cover

The exact JSON shape each adapter parses from its engine's `--format`
output is an implementation detail `TESTS/` already covers against a faked
`run_argv` — nothing here re-derives it. Devcontainer support explicitly
excludes "features", lifecycle commands (`postCreateCommand`, ...), and
`remoteUser` per the README's own scope note, so there's nothing to test
there beyond confirming they're absent, not broken. containerd has no
separate adapter by design (nerdctl covers it) — nothing to test in
isolation.
