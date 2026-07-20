# Keymap collision & prefix-wait analysis

Cross-referenced every plugin's [Keymaps cheatsheet](Keymaps/All.md) against
every other plugin's, looking for two distinct problems:

1. **Prefix-wait**: a shorter mapping (e.g. `<leader>lr`) is bound directly
   *and* one or more longer mappings share that exact string as their prefix
   (e.g. `<leader>lrr`). Neovim can't know which one you want until either
   `timeoutlen` (default 1000ms) elapses or you type another character — so
   the short mapping fires late, every time.
2. **Shadowing/collision**: the same `lhs`+mode is bound by two different
   plugins, so whichever is buffer-local (or registered last) silently wins
   and the other becomes unreachable in that context.

Scope: only *default-active* keymaps were checked for live impact (most
plugins ship keymaps off by default — those are noted but not treated as
"currently colliding"). Buffer-local keymaps confined to a plugin's own
special buffer (dashboards, floats, pickers) are excluded from the collision
section entirely — only one such buffer can be focused at a time, so `q`/
`<Esc>`-to-close being reused by ~10 plugins there is fine, not a bug (see
Notes).

## 1. Prefix-wait: shorter mapping + longer siblings sharing its exact prefix

### `recommender.nvim` — confirmed, self-contained

| lhs | length | action |
| --- | --- | --- |
| `<leader>lr` | bare | `:Recommender` |
| `<leader>lrr` | +1 char | `:Recommender regex` |
| `<leader>lrt` | +1 char | `:Recommender treesitter` |
| `<leader>lrh` | +1 char | `:Recommender regex 5` |

Pressing `<leader>lr` always waits out `timeoutlen` before running plain
`:Recommender`, because `lrr`/`lrt`/`lrh` are still valid continuations.
**Fix**: either drop the bare `<leader>lr` mapping (make `:Recommender` only
reachable via `<leader>lrr` etc., or a dedicated command), or move
`lrr`/`lrt`/`lrh` off the `lr` prefix entirely (e.g. `<leader>lx`+letter).

### `fileops.nvim` — confirmed, self-contained, twice

| lhs | length | action |
| --- | --- | --- |
| `<leader>nf` | bare | Next file (replace) |
| `<leader>nfn` | +1 char | Next file (stay listed) |
| `<leader>pf` | bare | Previous file (replace) |
| `<leader>pfn` | +1 char | Previous file (stay listed) |

Same problem, twice over — `<leader>nf`/`<leader>pf` (your most likely
everyday keys, given they're the plain "replace" variants) both wait out
`timeoutlen` because of the `n` suffix variant. **Fix**: rename the "stay
listed" variant off the `nf`/`pf` prefix (e.g. `<leader>nl`/`<leader>pl` for
"listed", or swap which variant gets the short form since "replace" is
presumably the one you want fast).

### Checked and clean (no bare-prefix-plus-siblings pattern found)

- `dap.nvim` — `<leader>d` itself is never bound, only `<leader>d`+one letter throughout. No wait.
- `cascade.nvim` — `<leader>c`+one letter throughout (`cx`, `cX`, `ct`, `cT`, `cr`, `cf`, `cF`, `cs`, `cv`); no bare `<leader>c`. No wait (which-key also intercepts the prefix if installed, changing the UX further in your favor).
- `project-insight.nvim` — `ps`/`pS` diverge at the very next character (case-sensitive), not a prefix relationship. No wait.
- `gopath.nvim`, `github_stats.nvim`, `sessions.nvim` — single-level suffixes only, nothing nests.

## 2. Cross-plugin shadowing

### `<C-p>` (n) — buffer-ctx.nvim vs. markdown.nvim, on markdown buffers

- `buffer-ctx.nvim`: `<C-p>` (n), **global**, default on → "yank all marked lines to clipboard".
- `markdown.nvim`: `<C-p>` (n, v, x), **buffer-local to markdown/mdx/md filetype**, default on → "goto previous heading".

Buffer-local always wins over global for the same buffer, so on any markdown
file, `<C-p>` silently does "goto previous heading" — buffer-ctx's mark-yank
becomes unreachable there specifically (works fine in every other filetype).
If you use `:Mark yank` while editing markdown notes, you've likely hit this
without realizing why. **Fix**: remap one side — buffer-ctx.nvim's
`mark.keymaps.yank` config key is the easiest lever (it's already
individually configurable per buffer-ctx's own cheatsheet).

### `<leader>ps` (n) — project-insight.nvim vs. pdfport.nvim, lower severity

- `project-insight.nvim`: `<leader>ps`, **global**, default on → "symbols (telescope)".
- `pdfport.nvim`: `<leader>ps`, **buffer-local to nvim-tree/oil/netrw filetypes**, only if that integration's `setup()` was explicitly called (not automatic) → "open with system application".

Only overlaps while sitting inside a file-tree buffer with pdfport's
integration active there — in which case pdfport's buffer-local wins.
Probably harmless in practice (you're unlikely to want symbol search while
browsing a file tree), but it's a coincidence worth knowing if either
plugin's scope changes later.

## 3. Shared top-level prefixes (not colliding today, just worth knowing before adding new bindings)

Several plugins independently chose the same one-letter `<leader>` prefix
for unrelated purposes. None of these currently collide (their second
characters differ), but each is a namespace two plugins are quietly sharing:

| Prefix | Plugins using it | Their second-level keys |
| --- | --- | --- |
| `<leader>c` | buffer-ctx.nvim, cascade.nvim | buffer-ctx: `cn`+letter; cascade: `c`+letter directly (`cx`,`cX`,`ct`,`cT`,`cr`,`cf`,`cF`,`cs`,`cv`) |
| `<leader>p` | fileops.nvim, gopath.nvim, project-insight.nvim, pdfport.nvim (buffer-local) | fileops: `pf`,`pfn`,`pF`,`PF`; gopath: `pp`; project-insight: `ps`,`pS`; pdfport: `po`,`pt`,`ps`,`pi` |
| `<leader>d` | dap.nvim, fileops.nvim | dap: `d`+letter (continue/step/etc.); fileops: `dcf` (delete current file) — no direct clash, but both treat `<leader>d` as "their" prefix |

If you (or a plugin update) ever add a new binding under `<leader>c`/
`<leader>p`/`<leader>d`, check this table first.

## Notes — what's *not* a problem

- **`q`/`<Esc>`-to-close** is reused by roughly a dozen plugins' popups/floats/scratch buffers (debugging views, node-info, trash-history, template picker, marks list, "open with" picker, stats popup, README viewer, TableView float, table_selector, translate window, diff float, replacer/Telescope). This is fine: each is buffer-local to that plugin's own special buffer, only one such buffer can ever be focused at a time, and it matches Vim's own convention (`q` closes quickfix/help/etc.) — consistent, low-risk design, not a collision.
- **`<C-a>`** is used by both `pickers.nvim` (`entry_actions.create_file`, opt-in/user-wired) and `replacer.nvim`/`migrate.nvim` (apply-all, picker-buffer-local) — no overlap since they're different pickers, never focused simultaneously.
- Most of the mappings that *look* risky (cascade's preset, most of buffer-ctx's individual keys, emojis.nvim, migrate.nvim, sessions.nvim, color_my_ascii.nvim) are **off by default** — they only become live once you explicitly configure them, at which point it's worth re-checking this file for your specific chosen keys.
- `debugging.nvim`'s prefix is the literal `<` key (`<lt>m`, `<lt>n`, …) — not a collision with anything else (no other plugin uses `<` as a prefix), but it's a genuinely unusual choice worth a second look: it's easy to mistype against the far more common `<leader>` convention every other plugin here uses, and there's no which-key group to reveal it if you forget it exists.
