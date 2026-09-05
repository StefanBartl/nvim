# Usercmds — overview & collision check across all plugins

What the 31 per-plugin sheets in this folder cannot answer between them: does
any command name exist twice, and does any name get in another one's way.

Written 2026-08-25 from the 31 repos' `docs/BINDINGS.md` plus their sources,
and verified against a live headless Neovim where the answer depended on load
order.

## Table of content

  - [The numbers](#the-numbers)
  - [Duplicate names](#duplicate-names)
  - [Prefix ambiguity](#prefix-ambiguity)
  - [The one real interaction: `:Lsp` silences nvim-lspconfig](#the-one-real-interaction-lsp-silences-nvim-lspconfig)
  - [Names generic enough to be worth watching](#names-generic-enough-to-be-worth-watching)
  - [Shape: verb vs. flat](#shape-verb-vs-flat)
  - [Config-internal commands](#config-internal-commands)

---

## The numbers

**148 command names across 31 plugins, all 148 distinct.**

| Count | Plugin |
| ---: | --- |
| 26 | markdown.nvim *(1 global `:Markdown` + 25 buffer-local)* |
| 24 | lsp.nvim *(`:Lsp` + `:LspDoctor` + legacy aliases + server-specific)* |
| 19 | pickers.nvim *(`:Pickers` + 15 flat aliases + 3 `:Pickers*`)* |
| 10 | gopath.nvim, runtime-analysis.nvim |
| 9 | buffer-ctx.nvim |
| 5 | diff.nvim |
| 4 | documentation.nvim, migrate.nvim, replacer.nvim |
| 3 | language.nvim, lib.nvim, open.nvim, sessions.nvim |
| 2 | cascade.nvim, color_my_ascii.nvim, filetree.nvim, sandbox.nvim |
| 1 | cmdlog, dap, debugging, emojis, fileops, github_stats, images, insights, mdview, pdfport, recommender, reposcope, spotlight |

The long tail is the point: nineteen plugins expose exactly one or two
top-level names and put everything else behind a sub-command tree.

## Duplicate names

**None.** No command name is registered by two plugins.

Two near-misses that are *not* duplicates, recorded so the next audit does not
flag them:

- **`:Replace`** appears in recommender.nvim's and runtime-analysis.nvim's
  sheets. Both are cross-references to replacer.nvim, which owns it.
- **`:Replace`** also appears in `lib.nvim/lua/lib/nvim/bindings/usercmd/composer/`, and
  **`:Foo`** in documentation.nvim — both are docstring examples of how to call
  the composer, not registrations. A naive `grep nvim_create_user_command`
  reports them; reading the line does not.

## Prefix ambiguity

Vim resolves an exact command name before any longer one, so every name below
still works when typed in full. The cost is confined to abbreviations and
`<Tab>` completion. Four cross-plugin cases:

| Short | Longer | Effect |
| --- | --- | --- |
| `:File` (fileops.nvim) | `:Filetree` (filetree.nvim) | `:Fil<Tab>` offers both; `:File` still resolves to fileops |
| `:Mark` (buffer-ctx.nvim) | `:Markdown` (markdown.nvim) | `:Mark` resolves to buffer-ctx; markdown needs `:Markd` at minimum |
| `:Lib` (lib.nvim) | `:LibInspect` (runtime-analysis.nvim) | `:Lib` resolves to lib.nvim |
| `:Open` (open.nvim) | `:OpenWithSystemApplication` (markdown.nvim) | markdown's is buffer-local to markdown buffers; `:Open` is unaffected |

Everything else is a plugin prefixing its own commands — `:Gopath*`, `:Lsp*`,
`:RA*`, `:Diff*`, `:MDTable*`, `:TableView*`, `:Pickers*`, `:Session*`,
`:DocMap*`, `:Copy*`, `:Cascade*`, `:AllDrives*`, `:Translate*`. That is the
intended shape, not a collision.

## The one real interaction: `:Lsp` silences nvim-lspconfig

The check turned up exactly one place where two plugins reach for the same
names, and it resolves in a way nobody wrote down.

`lsp.nvim` registers `:LspInfo`, `:LspLog` and `:LspStatus` itself
(`lua/lsp/usercmds/init.lua`). **nvim-lspconfig registers `:LspInfo`, `:LspLog`,
`:LspStart`, `:LspStop` and `:LspRestart`** in its `plugin/lspconfig.lua`, and
it is still in the plugin spec — NvChad brings it in on `event = "User FilePost"`.
`nvim_create_user_command` overwrites silently, so whichever loads last should
win, and lspconfig loads later.

It does not win. Line 6 of `plugin/lspconfig.lua`:

```lua
if vim.fn.exists(':lsp') == 2 then
  return
end
```

Command lookup is case-insensitive, so `:lsp` matches lsp.nvim's `:Lsp` verb —
and lspconfig's entire plugin file returns before it registers anything.
Verified headless: after forcing `User FilePost` and confirming
`lspconfig loaded: true`, `:LspInfo` and `:LspLog` still carry lsp.nvim's
descriptions, and `:LspStart`/`:LspStop`/`:LspRestart` do not exist at all.

**What this means in practice:**

- Today there is no conflict, and the five lspconfig commands are simply absent.
- The reason is an upstream courtesy check keyed on the name `Lsp`. Rename
  lsp.nvim's verb — `setup({ usrcmds = { command = "…" } })` or similar — and
  lspconfig's plugin file stops bailing out: five commands appear, and two of
  them (`:LspInfo`, `:LspLog`) silently overwrite lsp.nvim's, because
  lspconfig loads later.
- So the verb name `Lsp` is load-bearing for more than ergonomics. Worth a line
  in lsp.nvim's own docs.

Side finding from the same probe: every lsp.nvim command description was
prefixed `[lps.usercmds]` — a transposition of `lsp`, from a single
`local desc_tag` in `lua/lsp/usercmds/init.lua:11`, visible in `:command` and
in which-key. The same typo sat in `deprecated_help/doc/InstallationNotes.md`,
where it was not cosmetic: the snippet told the reader to
`require("lps.tools.deprecated_help")`, which fails on paste. Both fixed
2026-08-25 (`lsp.nvim@329245c`).

## Names generic enough to be worth watching

No sibling claims these, but they are short, unnamespaced, and the kind of name
a third-party plugin or a future config command reaches for. Listed so a
collision is recognised rather than debugged:

| Command | Owner | Why it is exposed |
| --- | --- | --- |
| `:Format` | buffer-ctx.nvim | The obvious name for a formatter command; conform.nvim users often define it. Configurable — `cfg.command or "Format"` |
| `:Insert`, `:Copy`, `:Mark` | buffer-ctx.nvim | Three generic verbs from one plugin |
| `:File` | fileops.nvim | |
| `:Open` | open.nvim | |
| `:Diff` | diff.nvim | |
| `:Image` | images.nvim | image.nvim (third-party) uses `:Image*` names |
| `:Debug` | debugging.nvim | |
| `:LiveGrep` | pickers.nvim | The conventional name in telescope setups |
| `:Fence` | color_my_ascii.nvim | |

## Shape: verb vs. flat

Two patterns, both deliberate:

- **A composer verb** — `:Lsp`, `:Filetree`, `:Gopath`, `:Pickers`, `:Cascade`,
  `:Sandbox`, `:Markdown`, `:MDView`, `:RA`, `:Insights`, `:Session`, `:Lib`,
  `:File`, `:Reposcope`, `:Dap`, `:Debug`, `:Spotlight`, `:Emojis`,
  `:GithubStats`, `:Cmdlog`, `:PdfPort`, `:Recommender`, `:Image`,
  `:ColorMyAscii`. Sub-command dispatch with `<Tab>` completion at every level,
  built on `lib.nvim.bindings.usercmd.composer`.
- **Flat aliases kept next to it** — `:LspFormat`, `:DiagQF`, `:Gopath*`,
  `:DirPicker`, `:LiveGrep`, `:MarkLineToggle`, `:CwdHere`, … Muscle memory
  beats tidiness, and an alias costs one line. Both surfaces dispatch into the
  same functions, so they cannot drift.

Three plugins register a short alias for the verb itself: `:Ft`
(filetree.nvim), `:Sbx` (sandbox.nvim), `:RA` (runtime-analysis.nvim, where the
short form *is* the primary name).

## Config-internal commands

Five more verbs live in the config itself rather than in a plugin, and are
counted separately from the 148 above. They are indexed at the top of
[`All.md`](All.md): `:MyPlugins`, `:MyReposUpdate`, `:WhoLocks`, `:Case`
(casedesk) and `:Bindings` — the last one being the explorer over these very
sheets. None of the five collides with a plugin name.
