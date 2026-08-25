# Missing flag/option ideas (grouped by plugin)

> **Backlog, keine Regel.** Gesammelte Flag-/Options-Ideen aus dem Code-Audit vom
> 2026-08-08, nach Plugin gruppiert. Abarbeiten und streichen.
> Belege: `Checklists/belege/` (siehe `Checklists/README.md`).
> Regeln zu Konfigurierbarkeit: `Checklists/regeln/LUA_NVIM.md` § Konfigurierbarkeit.
>
> **Status 2026-08-25: geschlossen.** Alle Eintraege sind erledigt, als n/a
> begruendet oder (learn-cli.nvim) per Entscheidung ausgenommen. Was hier
> stehen bleibt, ist der Nachweis *warum* — kein offener Task mehr.


Collected "Fehlende Flags/Optionen" ideas from each per-plugin report's
Keybindings-Audit section. These are things the report's author noticed while
reading the code, not confirmed feature requests.

## nvim-config — erledigt 2026-08-24

- [x] `:MyPlugins clone/reclone --dry-run` — the groundwork really was
  already there: the safe/unsafe/missing split `finish_check`/`finish_reclone`
  compute is exactly the preview, it just always went on to confirm and act.
  `dry_run` now short-circuits both after reporting that split. `clone`'s
  dry-run doesn't even need the check phase — it reuses `ops.clone_one`'s own
  "exists" predicate (`loop.fs_stat`, no git call) directly.
- [x] `:MyReposUpdate --only=<name>` — done, but the mechanism differs from
  `:MyPlugins`'s: this command scans an arbitrary directory for *any* git repo
  rather than iterating a named list, so `--only` filters that scan's result
  by directory basename instead of validating against
  `plugins.personal.list`. Completion still works — it scans the resolved
  base dir the same way the real run would (cheap: no git subprocess) and
  offers basenames. Needed migrating `nargs` from `"?"` to `"*"` and a manual
  `--only=` token parse, since the command wasn't composer-based.
- [x] `:WhoLocks --json` — done. `lib.nvim.cross.fs.lock.report` only ever
  produces human text lines, so the json path calls `probe`/`who` directly and
  assembles a `vim.json.encode`-able table itself instead of routing through
  `report`.
- [x] `:Trouble` mappings (`[w`/`]w`) — **turned out to be no gap.**
  `lsp.nvim`'s `trouble_diag_next`/`prev` (where these keys now live, see the
  count audit) already loop `trouble.next()`/`trouble.prev()` `v:count1`
  times client-side — `5]w` already works. The premise ("once Trouble's API
  supports it") no longer applies: the workaround doesn't need a native count
  parameter from Trouble at all, so an explicit `<leader>x`-prefixed count
  variant would just duplicate what `v:count1` on the existing key already
  does.
— from [nvim-config](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/nvim-config.md)

## documentation.nvim — erledigt 2026-08-25

- [x] `:DocMap churn [range]` / `:DocMap diff [ref]` completen jetzt Refs.
  Der Vorzustand war schlechter als „keine Completion": beide fielen auf die
  *Aktions*-Liste durch, `:DocMap diff <Tab>` bot also
  `bindings`/`plugins`/… an — jeder Kandidat falsch. `churn` setzt zusaetzlich
  ein `A..`/`A...` fort und liefert das ganze `A..B`-Token zurueck.
  Die Ref-Auflistung ging als `lib.nvim.git.refs(dir, opts)` in die Lib, nicht
  in den Completion-Callback: „welche Revision?" ist keine
  documentation.nvim-Frage. Zwei Details dort tragen: `for-each-ref` sortiert
  per Default nach *refname* und begraebt damit den Branch, auf dem man
  gerade war (`-committerdate`), und Remote-Branches muessen ihr Praefix
  behalten — so nimmt git sie als Revision an, und ohne kollidieren sie mit
  dem gleichnamigen lokalen Branch.
- [x] `<Plug>`-Mappings fuer `DocBrowse`-Aktionen — **n/a.** `<Plug>`-Mappings
  sind in diesem Ecosystem kein Ziel: `opts.keys` (Rebinding pro Action-Id)
  plus `lib.nvim.map` deckt das vollstaendig ab, which-key-Labels bleiben die
  einzige Pflicht.
— from [documentation.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/documentation.nvim.md)

## lib.nvim

- No idea gaps flagged directly against lib.nvim's own (nonexistent) keymaps —
  see instead lib.nvim's "Ideen für andere Plugins" for generalized modules it
  could expose.
— from [lib.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/lib.nvim.md)

## learn-cli.nvim — ausgenommen

- Per Entscheidung vom 2026-08-24 aus diesem Sweep ausgenommen; steht hier
  nur, damit der Eintrag nicht als uebersehen gelesen wird.
  (`next_exercise`/`prev_exercise` ohne Count-Support.)

## replacer.nvim — erledigt 2026-08-25

- [x] Die Completion-Frage ist in `RULES-audit-completion.md` beantwortet und
  abgehakt. Darueber hinaus keine Flag-/Options-Luecken: `:Replace` hat 41
  Flags, und die einzige echte Fehlfunktion war nicht ein fehlendes Flag,
  sondern ein kaputtes — bare `--changed` (dokumentiert als „alle Kinds")
  wurde seit der composer-Migration vor `apply_tokens` abgewiesen. Gefixt
  ueber neues `FlagSpec.optional_value` in lib.nvim.

