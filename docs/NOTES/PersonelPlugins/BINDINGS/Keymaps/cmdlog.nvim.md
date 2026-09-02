# cmdlog — Keymaps Cheatsheet

No global/normal-mode keymaps **by default**. Since 2026-07-25, `setup()`
accepts an optional `keymaps` table (`{ [subcommand] = lhs }`, `""` for bare
`:Cmdlog`) that registers real normal-mode `vim.keymap.set` bindings for
`:Cmdlog <subcommand>` — see `docs/OPTIONS.md`. Not configured in this
config as of this writing (no `keymaps` passed to `setup()`), so the point
below still holds in practice: all *active* keymaps remain
prompt-buffer-local, inside picker `attach_mappings` — different per
backend (`config.options.picker`: `"telescope"` or `"fzf"`).

Cross-reference: `docs/BINDINGS.md` in the repo is now the source of truth
(added after this file was last written) and matches the tables below;
`README.md`'s "Shortcuts (inside pickers)" section is accurate for the
Telescope backend. `docs/ADD_PICKER.md` documents the extension pattern
for plugin authors, not end-user keys.

## which-key

Only relevant once the optional `keymaps` table above is actually
configured (not the case in this config currently) — those global bindings
get picked up by which-key.nvim's `add()` when installed, see
`lua/cmdlog/integrations/which_key.lua`. No-op if which-key is absent. The
prompt-buffer-local picker keys (Telescope/fzf-lua sections below) are not
which-key's domain — they live inside `attach_mappings`, not the global
keymap namespace.

## Telescope backend — shared module `lua/cmdlog/ui/mappings.lua`

Used by every picker except `favorites_picker`.

| lhs | mode | action |
| --- | --- | --- |
| `<CR>` | i | Closes picker, feeds the selected entry back into the command-line for editing (does **not** execute it) |
| `<Tab>` | i | Toggles favorite for the selected entry, closes + refreshes the picker |
| `<C-r>` | i | Closes + manually refreshes the picker |
| `<C-x>` | i | Deletes the selected entry — or, when entries are marked, every marked one — from its underlying history (Neovim `:` history via `histdel()`, or the shell history file with a confirmation prompt). Only bound where the caller passes a `delete_fn` — not in `favorites_picker` (`<Tab>` already removes a favorite there) |
| `<C-Space>` | i | Marks/unmarks the entry for a batch delete and moves down (`actions.toggle_selection` + `move_selection_worse`). Telescope's own multi-select key is `<Tab>`, which is `toggle_favorite` here, hence a separate key |
| `<C-t>` | i | Prompts (`vim.ui.input`) for a tag and attaches it to the selected favorite via `core/tags.lua`, then refreshes the picker. Favorites picker only (`opts.tag = true`) — tags are stored per favorite, so a command that is not one has nothing to attach to |
| `<C-s>` | i | Rotates to the next picker (nvim → shell → favorites → project → …), keeping the current prompt text. Implemented in `lua/cmdlog/ui/cycle.lua`, bound in `nvim`/`shell`/`favorites`/`project` pickers only. Telescope only. **Added 2026-08-09.** |
| `<C-z>` | i | Undoes the most recent favorite toggle (single-level, session-local). Bound wherever `<Tab>` is (any picker with `toggle_favorite`). **Added 2026-08-09.** |
| `<C-Up>` | i | Moves the selected favorite up one slot in the persisted order. Favorites picker only (`opts.reorder = true`). **Added 2026-08-09.** |
| `<C-Down>` | i | Moves the selected favorite down one slot in the persisted order. Favorites picker only. **Added 2026-08-09.** |

Alle zehn sind konfigurierbar/abschaltbar über `setup({ mappings = { ... } })`
**Batch delete (since 2026-08-24):** a batch asks once ("Delete N selected
entries...") and then suppresses the per-command shell confirmation — five
marked entries would otherwise raise five separate prompts. With nothing
marked, `<C-x>` behaves exactly as before, single confirmation included.

The mappings call `delete_fn(cmd, on_done, opts)`. Neither history source has
that shape natively, and passing them through raw was a real bug fixed at the
same time: `history.delete_entry` is synchronous and returns a boolean, so the
callback never fired and the picker stayed open on a stale list;
`shell.delete_entry` is `(cmd, opts, on_done)`, so the callback landed in the
`opts` slot and `<C-x>` in the shell picker raised
`attempt to call local 'on_done' (a nil value)`. Each picker now wraps its
source in an adapter.

(`select`/`toggle_favorite`/`refresh`/`delete`/`toggle_selection`/`tag`/
`cycle_source`/`undo_favorite`/`move_favorite_up`/`move_favorite_down`, each
`string|false`), see `docs/OPTIONS.md`. A legend of the active ones is
generated from `config.options.mappings` and shown in the Telescope
prompt title (`ui/picker_utils.lua`'s `build_legend()`).

`favorites_picker` hatte für `<C-t>` einmal ein eigenes, inline geschriebenes
`attach_mappings` (seit `7fcb21c`, 2026-07-25). **Das stimmt seit `ed60f8f`
nicht mehr:** der Picker ruft dasselbe geteilte Modul wie alle anderen und
schaltet die Sonderfälle über Flags frei — `{ tag = true, reorder = true }`.
`tag` steht damit in `DEFAULTS.mappings` wie jede andere Taste auch. Tags
liegen getrennt von `favorites.json` und werden neben dem Eintrag angezeigt.

Derselbe Merge hat also zwei Dinge auf einmal getan: die Telescope-Tasten ins
geteilte Modul gezogen (gewollt, und hier nachgetragen) und den
fzf-lua-`actions`-Block ersatzlos gelöscht (nicht gewollt, siehe unten).

## fzf-lua backend

| lhs | picker(s) | action |
| --- | --- | --- |
| `default` (`<CR>`) | all | Executes the command directly (`vim.cmd(selected[1])`) — **differs from Telescope's insert-only `<CR>`** |

**Das ist die ganze Tabelle.** Unter `picker = "fzf"` bindet cmdlog.nvim genau
eine Aktion. Die Keys aus `config.options.mappings` gehen über
`attach_mappings` an Telescope, und die fzf-lua-Hälfte von
`ui/picker_utils.lua:164-179` reicht `attach_mappings` nicht weiter — sie setzt
`prompt`, `previewer` und `actions`, und `opts.actions` übergibt kein einziger
Picker. Kein Favoriten-Toggle, kein Tag, kein Delete, in keinem Picker.

Known-error highlighting (`core/errors.lua`) ist aus verwandtem Grund
Telescope-only: fzf-lua-Einträge sind zugleich der Wert, der an `actions`
zurückgeht, dekorieren würde `vim.cmd(selected[1])` beschädigen.

### Wie das hier auffiel (2026-09-02)

Diese Tabelle führte bis heute `ctrl-f` (Favorit umschalten) und `ctrl-t`
(Tag). Beides gab es einmal: `favorites_picker.lua` hatte einen eigenen
`actions`-Block, `ctrl-f` seit `388ef16`, `ctrl-t` seit `7fcb21c`
(2026-07-25). Der Merge **`ed60f8f` „Merge feature-notes into main"
(2026-07-30)** hat den Block beim Auflösen mitgelöscht — die Commit-Message
sagt „keep both wherever complementary", der Diff entfernt
`actions = { ["ctrl-f"] = …, ["ctrl-t"] = … }` ersatzlos. Seither behaupteten
drei Dokumente ein Feature, das der Code nicht mehr hat: dieses Cheatsheet,
cmdlog.nvims `README.md` (Backend-Vergleichstabelle *und* die Shortcut-Liste)
und implizit `docs/OPTIONS.md`. Alle drei sind nachgezogen; der Code bleibt
wie er ist — die Entscheidung war „Doku auf die Realität ziehen", nicht
„Feature wiederherstellen".

Gefunden hat es `:Bindings check`: nach dem Quelltext-Fallback war `ctrl-f`
der einzige von 52 `keymap-not-live`-Befunden, der übrig blieb. `ctrl-t` fiel
dabei *nicht* auf — das Literal steht zufällig in
`lua/config/fzf/init.lua` dieser Config, wo es `file_tabedit` bindet, und der
Grep kann die beiden nicht unterscheiden. Der dokumentierte Preis der Achse,
hier einmal in freier Wildbahn.

## Notes

- Ein Kommentar auf `ui/mappings.lua:2` (`--- Handles <CR> to execute, <C-f> to toggle favorite, <C-r> to refresh`) ist **stale/inaccurate**: die tatsächlichen Bindings sind `<CR>` (einfügen, nicht ausführen) und `<Tab>` (nicht `<C-f>`) für Favoriten. `<C-f>` existiert nirgends mehr — auch nicht im fzf-lua-Backend, siehe oben.
- No conditional flags gate these beyond the `picker` config option — no "enable keymaps" toggle exists.
