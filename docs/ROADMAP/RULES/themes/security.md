# Security

Injection avoidance, sandboxing, regex-safety, credential handling, and other
defensive-against-untrusted-input patterns pulled from the per-plugin reports.

## Argv over shell strings

The single most repeated security pattern across the whole codebase: **every
external process call is built as an argv array, never a shell string.**

- [sandbox.nvim](../plugins/sandbox.nvim.md) (`util/run_argv.lua:17-21,91` —
  over 150 files, zero shell-string construction across the whole adapter
  tree; no `os.execute`/`io.popen`/`shell=true` anywhere).
- [diff.nvim](../plugins/diff.nvim.md) (`core/git.lua:72`, `core/url.lua:76-93`
  — `vim.system({...})` argv arrays for `git`/`curl`).
- [documentation.nvim](../plugins/documentation.nvim.md) (all subprocess
  execution via `vim.system` with argv, never a shell — `docs/SECURITY.md`).
- [fileops.nvim](../plugins/fileops.nvim.md) (`util/git.lua`,
  `features/on_hold.lua` — argv-only, `cwd` set explicitly per file rather than
  relying on Neovim's global cwd).
- [language.nvim](../plugins/language.nvim.md) (`translate/providers/google.lua:9-10`
  — translation payload text is "never shell-interpolated").
- [reposcope.nvim](../plugins/reposcope.nvim.md) (`utils/protection.lua:217-233`
  `safe_execute_shell` explicitly distinguishes string command (shell) vs
  argv-table (`lib.nvim.cross.run_argv`, no shell); clone commands built as
  argv tables — `providers/github/clone/clone_command.lua:1-34`).
- [gopath.nvim](../plugins/gopath.nvim.md) — n/a, no subprocess use found, but
  consistent with the pattern elsewhere.

## Secrets

- Never pass a secret (password/token) as a process argument if the target CLI
  offers a stdin variant — argv is visible via `ps`/shell history/process
  list, stdin is not — from [sandbox.nvim](../plugins/sandbox.nvim.md)
  (`docker login --password-stdin`, `adapters/docker/registry/login.lua:16-22`).
- Persistent history/logs should store the minimal scope needed (method/url/
  status/timestamp), never headers or bodies — secrets live almost exclusively
  there — from [runtime-analysis.nvim](../plugins/runtime-analysis.nvim.md)
  (`history.lua:83-105`).
- Placeholder/variable (`{{var}}`) resolution should happen exactly once,
  immediately before the external call; every log/history/UI path must keep
  the raw, unresolved copy, never the resolved one — from
  [runtime-analysis.nvim](../plugins/runtime-analysis.nvim.md) (`env.lua:169-193`).
- Argument/telemetry fingerprinting must capture shape, never content —
  strings truncated at a fixed length, tables reduced to a type tag, never
  serialized. "A profiler that stores real values is a security bug with a
  feature name." — from
  [runtime-analysis.nvim](../plugins/runtime-analysis.nvim.md)
  (`telemetry/fingerprint.lua:6-9`).
- Best-effort `.gitignore` warnings for files likely to contain secrets are
  acceptable as "cheap insurance" even when known-incomplete (documented, not
  hidden) — from [runtime-analysis.nvim](../plugins/runtime-analysis.nvim.md)
  (`env.lua:80-99`, `warn_if_not_gitignored`).
- A plugin must never manage API keys itself — no central key store, no
  persistence of the value anywhere the plugin controls. The key comes from
  the environment (e.g. `os.getenv("OPENAI_API_KEY")`); `:checkhealth`
  reports at most *present yes/no* and which provider is active, never the
  value itself — binding rule for every plugin with API access, not just the
  one it was first written against — from
  [typepilot.nvim](../../IDEAS/typepilot.nvim.md) (concept doc, not yet a
  built plugin with its own audit report here).

## Downloaded / remote content

- Binaries downloaded from GitHub Releases (or any remote source) MUST be
  checksum-verified before execution; delete the file on mismatch — from
  [mdview.nvim](../plugins/mdview.nvim.md) (`adapter/install.lua:82-96,119-166`,
  goreleaser-style sha256 checksums.txt).
- Remote content should render client-side with sanitizing, never become
  server-side DOM from unchecked input — from
  [mdview.nvim](../plugins/mdview.nvim.md) (comrak+ammonia in WASM, README:33-37).
- Any network fetch triggered implicitly by viewing/scanning content (not an
  explicit user action) should default to **disabled**, opt-in only, and never
  fire during plain listing/scanning (only on explicit single-item display) —
  from [images.nvim](../plugins/images.nvim.md) (`remote.lua:60-103`,
  `display.remote.enabled = false` by default, compared explicitly to email
  clients blocking external images).
- Downloads need both a timeout AND a byte-size limit (not just one), a
  URL-hashed cache to avoid re-fetching, and active deletion of partial/failed
  downloads rather than leaving a corrupt file in the cache — from
  [images.nvim](../plugins/images.nvim.md) (`remote.lua:60-103`, `curl
  --max-time`/`--max-filesize`); noted as a gap in
  [github_stats.nvim](../plugins/github_stats.nvim.md)'s `api.lua`, which
  lacks an explicit byte limit.

## Regex / pattern safety

- Any pattern built from user input and handed to a regex engine must be
  literal-escaped (`\V`/very-nomagic equivalent), never passed through as raw
  regex — prevents both false matches and pathological backtracking — from
  [spotlight.nvim](../plugins/spotlight.nvim.md) (`core/pattern.lua:19-43`,
  README "Security model").
- Case-sensitivity should be baked in explicitly (`\C`/`\c`) rather than
  depending on global `'ignorecase'`/`'smartcase'`, when meaning must stay
  stable across sessions/option changes — from
  [spotlight.nvim](../plugins/spotlight.nvim.md).
- Explicit bounded-input limits (max text length, max line length, max
  entries) should each carry a documented rationale for the specific unbounded
  input they defend against — from
  [spotlight.nvim](../plugins/spotlight.nvim.md) (README.md:508-553:
  `match.max_text_len=512`, `cursor.max_line_len=8192`,
  `quickfix.max_entries=10000`).
- Persisted snapshot/cache files are untrusted input: fully re-validate every
  field on load (type, length, count-cap); rebuild any regex/pattern from raw
  source text on load, never read a pre-built pattern from the file, so a
  manipulated snapshot can't inject a pattern — from
  [spotlight.nvim](../plugins/spotlight.nvim.md) (`persist.lua:180-192`).

## Untrusted-input validation / whitelisting

- Server-like surfaces (a local HTTP relay, a shell-out with a user-supplied
  ref) should validate with a strict **whitelist**, not a blacklist, and
  explicitly document what is *not* defended against — from
  [documentation.nvim](../plugins/documentation.nvim.md)
  (`editor/serve.lua`, `safe_sha` = `^%x%x%x%x%x%x%x+$` up to 40 chars, even
  `HEAD` rejected: "a whitelist that starts making exceptions stops being
  one"; `docs/SECURITY.md` "What this does not defend against" section).
- Config values sourced from a file outside the plugin's own config API
  (project-local `.rc` files, environment overrides) must be validated against
  a fixed enum/whitelist, never trusted raw — from
  [sandbox.nvim](../plugins/sandbox.nvim.md) (`.sandboxrc`, restrictive Lua
  pattern + enum check against `docker`/`podman`/`nerdctl`).
- User-controlled strings that become filename/path components (git branch
  names, project basenames) must be whitelist-sanitized AND have escape/control
  sequences (ANSI color codes) stripped first — blacklist alone is
  insufficient — from [sessions.nvim](../plugins/sessions.nvim.md)
  (`git.lua:62-82`, strips `\27%[[0-9;]*m` before whitelisting).
- Cache/file-path keys derived from user or project paths must be
  whitelist-filtered (`[^%w%-%._]`) before becoming part of a filesystem path —
  absolute paths (Windows drive letters, colons) could otherwise break out of
  the cache directory — from
  [runtime-analysis.nvim](../plugins/runtime-analysis.nvim.md)
  (`history.lua:37-58`, `sanitize`).
- External API responses should be defensively parsed with `type(...) ==
  "table"` checks at every nesting level before indexing, and sanitized with
  placeholders + a warning for missing required fields before caching/render,
  rather than trusted or allowed to crash the renderer — from
  [language.nvim](../plugins/language.nvim.md)
  (`translate/providers/google.lua:36-53`),
  [reposcope.nvim](../plugins/reposcope.nvim.md)
  (`cache/repository_cache.lua:99-123`, `_sanitize_repo`).
- Redaction/censoring approximations must always round toward
  over-protection, never under-protection ("over-redacting is the safe
  failure mode, under-redacting is not") — from
  [images.nvim](../plugins/images.nvim.md) (`redact.lua`).

## Isolation model honesty

- A plugin named after a security concept (e.g. "sandbox") should not imply it
  performs its own isolation if it doesn't — [sandbox.nvim](../plugins/sandbox.nvim.md)
  is a pure CLI remote-control layer over Docker/Podman/nerdctl; all real
  isolation is delegated to the external daemon, and the report explicitly
  verifies no `unshare`/`chroot`/namespace/cgroup/seccomp code exists in the
  plugin itself.
</content>
