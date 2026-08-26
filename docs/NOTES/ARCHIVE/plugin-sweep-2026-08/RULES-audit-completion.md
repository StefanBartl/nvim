# Autocompletion audit (cross-plugin synthesis)

> **Backlog, keine Regel.** Completion-Audit (Ex-Command-/Picker-Input-Completion) aus
> dem Code-Audit vom 2026-08-08. Die daraus abgeleitete **allgemeine Regel** steht in
> `Checklists/regeln/LUA_NVIM.md` § Picker- und Kommando-UX (`UI-K*`).
> Hier steht nur die Lückenliste — abarbeiten und streichen.
>
> **Status 2026-08-25: geschlossen.** Die Lueckenliste ist leer: nvim-config
> und replacer.nvim sind erledigt, learn-cli.nvim ist ausgenommen. Der
> „Exists — and done well"-Teil bleibt als Nachschlagewerk stehen.


Synthesis of the per-plugin autocompletion audits (Ex-command / picker-input
completion). See each linked report's "Keybindings-Audit" section for full
file:line detail.

## The shared mechanism

Nearly every plugin in this ecosystem uses `lib.nvim.usercmd.composer` for its
`:Verb <subcommand>` command tree. Composer derives Tab-completion directly
from a declared route tree (subcommand literals, then positional-arg
completers) — a plugin author doesn't need to hand-write a `complete`
function — from [lib.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/lib.nvim.md)
(`usercmd/composer/complete.lua:1-132`). This is explicitly called out as the
generic infrastructure behind the "autocompletion vorhanden" verdict in almost
every other report.

## Exists — and done well (dynamic / live-state completion)

The strongest examples pull completion values from *live* state rather than a
frozen list baked in at `setup()`:

- **`documentation.nvim`**: `:DocMap`/`:DocBrowse` — 3-level completion
  (action → module names live from the scanned IR → sub-action), with module
  completion intentionally skipped until the root has actually been scanned
  once, to avoid a Tab-trigger forcing a full scan — from
  [documentation.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/documentation.nvim.md)
  (`bindings/usrcmds/init.lua:250-318`).
- **`sandbox.nvim`**: `:Sandbox` completion resolves container/image/volume/
  network/distro names live against the active engine, short-cached — from
  [sandbox.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/sandbox.nvim.md).
- **`emojis.nvim`**: `:Emojis` second argument completes checkbox-set names
  from the *currently configured* sets (`config.checkbox_set_names()`), so a
  user-defined set completes exactly like a built-in one — from
  [emojis.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/emojis.nvim.md) (`commands.lua:172-181`).
- **`cascade.nvim`**: `:Cascade <subcommand>` has full `<Tab>`-completion,
  range-aware, `!`-bang for reverse direction — from
  [cascade.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/cascade.nvim.md).
- **`pickers.nvim`**: the "Route Tree" drives dispatch, completion, AND
  documentation from one structure — Scope/Action/Nav completion, plus
  compat-commands like `:RepoFiles [repo]` completing from `$REPOS_DIR` — from
  [pickers.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/pickers.nvim.md) (`command/composer.lua`).
- **`insights.nvim`**: order-independent tokens (scope/type/UI in any order)
  still get full completion at every position via `repeated_args` — identical
  optional slots of the same type — from [insights.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/insights.nvim.md)
  (`bindings/usrcmds.lua:171-215,550-562`).
- **`mdview.nvim`**: every route's enum-valued args (`theme.known`,
  `cursor.modes`, `sync.actions`, `zoom.actions`, `reveal.actions`,
  `blanklines.actions`, `overlay.names()`) are fully completed, each value
  list sourced from its owning feature module rather than duplicated — from
  [mdview.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/mdview.nvim.md) (`bindings/usrcmds/init.lua`).
- **`open.nvim`**: `OPEN_TARGET`/`OPEN_SCOPE` completion types pull handler
  keys live from the handler registry, plus `path=` file completion and named
  scope keywords — from [open.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/open.nvim.md)
  (`bindings/usrcmds.lua:58-113`).
- **`buffer-ctx.nvim`**: `:Insert`/`:Copy` subcommands and their first
  argument are fully completable, including dynamic completion for
  boilerplate/snippet/env names via `composer.register_type` — from
  [buffer-ctx.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/buffer-ctx.nvim.md) (`commands.lua:311-347`).
- **`nvim-config`**: `plugin_repos/init.lua` registers custom arg types
  `MYPLUGINS_DIR` (includes a `$REPOS_DIR` suggestion) and `MYPLUGINS_NAME`
  (validated + completed live against the actual plugin list) — from
  [nvim-config](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/nvim-config.md); `case/init.lua`'s `CASE` type normalizes a
  pasted full ID down to its short number and completes against the registry.
- **`runtime-analysis.nvim`**: `:RA env [name]` and `:RA inspect <module>`
  complete live against `env.list_names()`/`package.loaded` — from
  [runtime-analysis.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/runtime-analysis.nvim.md)
  (`bindings/usrcmds.lua:60-90`).
- **`sessions.nvim`**: `save/load/delete/rename/toggle-track [name]` complete
  dynamically against the live session list (not a frozen snapshot); separate
  live lists for tab-sessions and layouts — from
  [sessions.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/sessions.nvim.md) (`bindings/usercmds/init.lua:59-62`).

## Missing or partial — flagged gaps

- **`nvim-config`** — **erledigt 2026-08-24.** `:MyReposUpdate [path]` hat
  jetzt Completion: `$REPOS_DIR` (wenn aufloesbar) plus echte
  Verzeichnis-Completion, gleiche Logik wie `MYPLUGINS_DIR`. Keine
  Eins-Zeiler-Wiederverwendung des Typs selbst, weil `resolve_base_dir` hier
  — anders als `MYPLUGINS_DIR`s `validate` — kein `$VAR`-Expansion machte;
  `fnamemodify` allein laesst `"$REPOS_DIR"` woertlich stehen. Ohne
  `lib.nvim.cross.fs.expand_path` davor waere `$REPOS_DIR` als Completion-
  Kandidat ein Koeder gewesen, der beim Ausfuehren gebrochen waere — jetzt
  eingebaut und geprueft. Nebenbei bekam der Befehl auch `--only=<name>`
  (siehe `RULES-flags-options.md`), was `nargs` von `"?"` auf `"*"` und die
  Completion auf eine Funktion umgestellt hat —
  [bindings/usrcmds/update_repos/init.lua](../../../../lua/bindings/usrcmds/update_repos/init.lua).
- **`learn-cli.nvim`** — **ausgenommen** (Entscheidung 2026-08-24), steht hier
  nur, damit der Eintrag nicht als uebersehen gelesen wird:
  `:LearnCLICreateCycle <name> [path]` has a `complete`
  function that ignores `arg_lead`/context entirely and always returns 3
  static placeholder strings; the second positional (`path`, a directory) has
  no completion at all — a real gap, not a deliberate omission — from
  [learn-cli.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/learn-cli.nvim.md) (`commands.lua:112-161`).
- **`replacer.nvim`** — **erledigt 2026-08-25.** Nachgemessen statt geraten.
  Flag-*Namen* completeten laengst — ausser bei bare `--`, und das war ein
  Guard-Bug in lib.nvim (`sub(1,2) == "--" and arg_lead ~= "--"`), der
  composers eigenem README widersprach; gefixt, damit listet `--<Tab>` alle
  41 Flags (43 bei `:Surround`). Das war der groesste Teil der Luecke.
  Von den *Werten* completete nur `--engine=`. Neu in
  `lua/replacer/argtypes.lua`: `--type=` (rg-Typnamen live aus
  `rg --type-list`, pro Session gecacht), `--changed=` (komma-verkettbar,
  bereits genannte Kinds fallen raus) und `--export=` (`PATH`, bewusst nicht
  `FILE` — dessen Validator verlangt eine *lesbare* Datei, `--export` nennt
  aber eine noch nicht existierende Ausgabedatei).
  `--glob=`/`--exclude=` bleiben absichtlich ohne Completion: sie nehmen
  *Muster*; ein existierender Pfad als Kandidat waere angenommen worden,
  haette genau eine Datei getroffen und die Ersetzung still verengt.
  Nebenbei gefunden und gefixt, vom Audit nicht erwaehnt: bare
  `:Replace a b --changed` war seit der composer-Migration kaputt
  (`flag '--changed' requires a value`, bevor `apply_tokens` ueberhaupt
  lief). Dafuer gibt es jetzt `FlagSpec.optional_value` in lib.nvim.
