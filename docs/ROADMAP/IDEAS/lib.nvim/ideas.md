# Candidate `lib.nvim` building blocks

> **Stand 2026-09-14 — Aufwand/Nutzen-Analyse nachgetragen.** Jede Idee wurde
> gegen den aktuellen `lib.nvim`-Baum geprüft (`E:/repos/lib.nvim/lua/lib/`).
> Ergebnis: von 39 Ideen sind **9 bereits vollständig erledigt** und **16
> teilweise durch ein bestehendes, ähnliches Modul abgedeckt** — nur **14**
> sind wirklich noch offen. Jede Zeile trägt jetzt einen Status:
> ✅ erledigt · 🟡 teilweise/verwandtes Modul vorhanden · ⬜ offen.
>
> (Kleine Korrektur zur letzten Anfrage: die Aufwand/Nutzen-Analyse war für
> *diese* Datei gemeint, nicht für `lib.nvim.deps.md` — die habe ich vorhin
> versehentlich zuerst bearbeitet. Der dortige Stand bleibt trotzdem korrekt
> und nützlich, nur eben nicht das, was angefragt war.)

Recurring pattern: a plugin builds something generically useful and the report
suggests hoisting it into `lib.nvim` so future plugins don't reinvent it.

---

## Quick-Wins (offen, günstig, hoher Nutzen)

Wer als Nächstes an `lib.nvim` weiterbaut, findet hier das beste
Aufwand/Nutzen-Verhältnis unter den tatsächlich noch offenen Punkten:

| Idee | Aufwand | Nutzen | Warum zuerst |
|---|---|---|---|
| Token-based supersession (`async.latest_wins`) | mittel | hoch | Muster taucht potenziell überall auf (Picker-Previews, LSP, Suche) |
| Literal-pattern-builder (`\V`+escaping) | klein | mittel-hoch | Sicherheitsrelevant — verhindert Regex-Injection bei Nutzertext |
| Range-parser (`"1-3,5,7"` → Liste) | klein | mittel | Trivialer, wiederverwendbarer Parser, mehrere plausible Konsumenten |
| `buffer.apply_edits` (bottom-up + stale-match check) | mittel | hoch | Verhindert falsch angewandte Edits bei verschobenen Positionen |
| Checkpoint/Snapshot + byte-exact restore | hoch | hoch | Betrifft 3 destruktive Tools (replacer/fileops/migrate) — Datensicherheit |
| Cache-only/live-fallback Namenskonvention | ~0 (reine Doku) | mittel | Kostet nur eine README-Ergänzung |

Alles andere unten im Detail — inklusive der vielen Ideen, die sich beim
Nachschauen als bereits erledigt oder durch ein Nachbar-Modul abgedeckt
herausgestellt haben.

---

- **Soft-dependency-bridge helper** (`pcall(require, modname)` → shape-check →
  adapter → fallback), e.g. `lib.nvim.softdep.resolve(modname, shape_check,
  adapter)` — from [diff.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/diff.nvim.md) (`pickers_bridge.lua`,
`image_compare.lua`).
  > **Aufwand: mittel · Nutzen: mittel · Status: ⬜ offen** (kein `softdep`-Modul im Baum). Empfehlung: zurückstellen bis ein zweiter Konsument auftaucht (Rule of Three) — aktuell nur diff.nvim.

- **Byte-level word-diff utility** (`vim.diff` on exploded strings) as
  `lib.nvim.diff.word_ranges(a, b, algorithm)` — from [diff.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/diff.nvim.md).
  > **Aufwand: klein-mittel · Nutzen: mittel · Status: 🟡 teilweise** — `lib.lua.diff` existiert bereits (zeilenweiser Myers-LCS + Splice-Diff), die wortweise Variante fehlt aber. Empfehlung: klein genug für einen baldigen Sprint, baut auf vorhandener Diff-Infrastruktur auf.

- **URL-as-content-source fetch helper** (curl via `vim.system` + libuv timer
  fallback) as `lib.nvim.net.fetch_text(url, opts, callback)` — from
  [diff.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/diff.nvim.md); overlaps with the "safe external
  download" idea below.
  > **Aufwand: — · Nutzen: mittel · Status: ✅ erledigt** — `lib.nvim.net.curl` deckt das mit `fetch_raw`/`fetch_raw_blocking`/`fetch_json`/`fetch_json_blocking`/`fetch_stream` bereits vollständig ab, inkl. Callback-Scheduling (jüngst gefixt: `fix(net.curl): schedule fetch_json/fetch_raw/download callbacks`). Keine Aktion nötig.

- **N-way native diffmode orchestrator** (`lib.nvim.diffmode.open_n_way({bufs},
  view)`) generalizing `diff.nvim`'s `three_way()`/`side_by_side()` layout code
  — from [diff.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/diff.nvim.md).
  > **Aufwand: hoch · Nutzen: klein · Status: ⬜ offen**. Layout-Code zu generalisieren ist nicht trivial, und aktuell gibt es nur einen Konsumenten. Niedrige Priorität.

- **Statusline-component convention** (`plugin.status()` → short string, empty
  when inactive) generalized across all *.nvim plugins with "active state" —
  from [diff.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/diff.nvim.md).
  > **Aufwand: klein (reine Konvention+Doku) · Nutzen: hoch · Status: 🟡 teilweise** — `lib.nvim.ui.statusline` existiert als Modul; ob die `plugin.status()`-Konvention plugin-übergreifend durchgesetzt/dokumentiert ist, wurde nicht verifiziert. Günstig zu prüfen und ggf. nur noch zu dokumentieren.

- **Static-vs-runtime audit framework** generalizing `debugging.nvim`'s
  tree-sitter-scan-of-registration-call-sites + live-API-diff pattern (used
  there for autocmds) to other registration-style APIs (`nvim_create_user_command`,
  `vim.keymap.set`, `vim.diagnostic` handlers) — from
  [debugging.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/debugging.nvim.md).
  > **Aufwand: hoch · Nutzen: klein · Status: ⬜ offen**. Ein Konsument, hochspezialisiert. Niedrige Priorität.

- **Reusable "Tagged-Scratch-Window" module** generalizing `debugging.nvim`'s
  window-var-based (not registry-based) window tracking, focus-and-scroll with
  bounded retries, defensive handle validation — for any auto-refreshing log
  window (LSP log viewer, test-runner output) — from
  [debugging.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/debugging.nvim.md).
  > **Aufwand: mittel · Nutzen: mittel · Status: 🟡 teilweise** — `ui.kit.viewer`/`ui.kit.preview` decken Popup-Rendering ab, das spezifische window-var-Tracking + Fokus/Scroll-Retry-Muster aus debugging.nvim ist nicht als eigenes Modul erkennbar. Lohnt sich bei einem dritten Konsumenten (LSP-Log-Viewer, Test-Runner-Output).

- **Configurable command-registry composer** as a documented lib.nvim pattern
  — the split between a logic/dispatch module and a thin composer-route
  registration module — from [debugging.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/debugging.nvim.md).
  > **Aufwand: — · Nutzen: hoch · Status: ✅ faktisch erledigt** — `lib.nvim.usercmd.composer` (`registry.lua`, `tree.lua`, `docgen.lua`, `flags.lua`, `check.lua`, `argtypes.lua`, `kv.lua`) ist genau dieser Composer und bereits das etablierte, dokumentierte Muster. Keine Aktion nötig.

- **Generic `Registry` building block** ("who is responsible for X",
  self-registration, deterministic order, `reset()` for tests) extracted from
  `documentation.nvim`'s `lang_registry.lua` — from
  [documentation.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/documentation.nvim.md).
  > **Aufwand: klein-mittel · Nutzen: hoch · Status: 🟡 teilweise** — `usercmd.composer.registry` ist eine domänenspezifische Instanz dieses Musters; eine eigenständige, domänenunabhängige `lib.nvim.registry` wurde nicht gefunden. Günstiger, aus vorhandenem Code zu extrahieren als neu zu bauen.

- **Generic keymap-override-resolver** (`defaults + overrides + notify` →
  validated resolved list) generalizing `documentation.nvim`'s
  `bindings/keymaps.resolve()` — from [documentation.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/documentation.nvim.md).
  > **Aufwand: klein-mittel · Nutzen: mittel · Status: 🟡 teilweise** — `bindings.keymap` (`registry.lua`, `records.lua`, `portability.lua`, `which_key.lua`) deckt Keymap-Verwaltung breit ab; ob exakt "defaults+overrides+notify→resolved list" als Funktion existiert, nicht bestätigt. Kurz prüfen, sonst kleine Ergänzung.

- **Local loopback server with `VimLeavePre` lifecycle + shape-validated
  routes** as a reusable building block, generalizing `documentation.nvim`'s
  `editor/serve.lua` (127.0.0.1-only, port 0, strict validators) — from
  [documentation.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/documentation.nvim.md).
  > **Aufwand: hoch · Nutzen: klein · Status: ⬜ offen** (kein `net.server`-Äquivalent im Baum). Sicherheitskritischer Code (Port-Bindung, Validierung) bei nur einem Konsumenten — niedrige Priorität.

- **Undo/history stack with sentinel-clear pattern** as a `lib.nvim.ui.kit`
  utility, generalizing `documentation.nvim`'s `browse/init.lua` `go`/`CLEAR`/
  `history_step` navigation model — from [documentation.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/documentation.nvim.md).
  > **Aufwand: klein-mittel · Nutzen: mittel · Status: 🟡 teilweise** — `ui.kit` hat viele Navigationskomponenten (`chooser`, `picker`, `select`), ein explizites History-Stack-Utility ist darunter nicht eindeutig identifizierbar.

- **Common-prefix-collapse module** (longest common prefix over a list of
  strings → single alias suggestion), generalizing `recommender.nvim`'s
  Tree-sitter analyzer, usable e.g. for JS/TS import consolidation — from
  [recommender.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/recommender.nvim.md).
  > **Aufwand: klein · Nutzen: klein-mittel · Status: ⬜ offen**. Günstiger reiner String-Algorithmus, aber nur ein bekannter Konsument — auf den zweiten warten.

- **"Insert into best target window" helper** (source_win → alternate →
  first normal window), generalizing `recommender.nvim`'s
  `find_target_window()` — likely useful for pickers.nvim/reposcope.nvim too
  — from [recommender.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/recommender.nvim.md).
  > **Aufwand: klein · Nutzen: mittel · Status: 🟡 teilweise** — `lib.nvim.window.find_usable.is_usable_window` deckt die Fensterauswahl-Logik (normal, nicht floating, nicht Sidebar) bereits ab; die volle Kette source_win→alternate→erstes normales Fenster fehlt evtl. noch als Fertigfunktion. Günstige Ergänzung auf vorhandener Basis.

- **Frecency-as-a-service module** (log-damped count + bucketed recency, JSON
  persistence under `stdpath("data")/<plugin>/frecency.json`) — three
  independent implementations already exist
  ([emojis.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/emojis.nvim.md) exponential-decay variant,
  [pickers.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/pickers.nvim.md) log-damped variant) and both
  reports explicitly suggest consolidating into `lib.nvim`.
  > **Aufwand: — · Nutzen: hoch · Status: ✅ erledigt** — `lib.nvim.frecency` existiert als eigenständiges Modul. Offen ist nur noch, ob `emojis.nvim`/`pickers.nvim` tatsächlich darauf umgestellt sind — das wäre Migrations-Nacharbeit, kein neues Feature.

- **Route-Tree command composer** as a documented, promoted lib.nvim pattern
  (one data structure driving dispatch + completion + docs) — flagged
  independently by [pickers.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/pickers.nvim.md),
  [filetree.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/filetree.nvim.md), and
  [mdview.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/mdview.nvim.md) as something that should be
  consistently used/promoted across all plugins, not just documented once.
  > **Aufwand: — · Nutzen: hoch · Status: ✅ erledigt**, identisch mit dem Composer-Punkt oben: `usercmd.composer.tree` ist exakt diese Datenstruktur (dispatch + completion + `docgen.lua`). Prüfen, ob pickers.nvim/filetree.nvim/mdview.nvim schon umgestellt sind — sonst Migrationsaufgabe.

- **Buffer-local-autocmd-with-full-options fix**: a real, repeatedly-hit
  `lib.nvim.bindings.autocmd.create` gap (it doesn't pass through a `buffer` field) —
  independently documented as a workaround in at least four plugins:
  [pickers.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/pickers.nvim.md) (`selected_index/init.lua:184-193`),
  [github_stats.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/github_stats.nvim.md),
  [color_my_ascii.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/color_my_ascii.nvim.md),
  [markdown.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/markdown.nvim.md) — strong candidate for a
  one-time upstream fix rather than four workarounds.
  > **Aufwand: — (war ein kleiner Bugfix) · Nutzen: hoch (4 unabhängige Workarounds) · Status: ✅ erledigt** — `bindings.autocmd` reicht `opts.buffer` inzwischen korrekt durch (siehe `native_opts.buffer = opts.buffer`). Aufräum-Aufgabe: prüfen, ob die 4 genannten Plugins ihre Workarounds inzwischen zurückgebaut haben.

- **Windows file-lock diagnosis command** (`:LibWhoLocks <path>`) directly
  exposing `lib.nvim.cross.fs.lock.report` — from [lib.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/lib.nvim.md).
  > **Aufwand: klein · Nutzen: mittel · Status: ✅ erledigt (Kernfunktion)** — `cross.fs.lock.who`/`report` existiert bereits (die Idee zitiert exakt diesen Pfad). Nur noch prüfen, ob ein `:LibWhoLocks`-Usercommand registriert ist — falls nicht, eine ~10-Minuten-Ergänzung.

- **UI-Kit example/playground plugin** demoing every `lib.nvim.ui.kit`
  primitive interactively — from [lib.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/lib.nvim.md).
  > **Aufwand: mittel · Nutzen: mittel (Doku-/Onboarding-Wert, kein Produktionscode) · Status: ⬜ offen**. "Nice to have", niedrige Priorität — `ui.kit` hat bereits 16 Submodule mit eigenem README.

- **Generic count-chained-async-action helper** (`lib.nvim.chained_action`)
  capturing `dap.nvim`'s `counted_step()` event-chaining pattern (protocol-safe
  count repetition with cap + cleanup listeners) — from
  [dap.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/dap.nvim.md); suggested reuse:
  [github_stats.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/github_stats.nvim.md)'s N-fetch background
  fetching.
  > **Aufwand: mittel · Nutzen: klein-mittel · Status: 🟡 teilweise** — `lib.nvim.count` existiert als Modul; ob es das protokoll-sichere Event-Chaining-Pattern von dap.nvim abdeckt, wurde nicht verifiziert. Kurz prüfen, sonst niedrige Priorität.

- **Generic backend-provider-dispatch module** formalizing preference →
  install-check → fallback-with-warning → dispatch-by-name, from
  `dap.nvim`'s `ui/provider.lua` — from [dap.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/dap.nvim.md).
  > **Aufwand: mittel · Nutzen: klein · Status: ⬜ offen**. Ein Konsument — niedrige Priorität bis ein zweiter auftaucht.

- **`with_cache` editor-state memoization helper**, generalizing
  `open.nvim`'s per-invocation cursor/selection/cfile cache — from
  [open.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/open.nvim.md).
  > **Aufwand: klein · Nutzen: mittel · Status: 🟡 teilweise** — `lib.nvim.cache` (`disk.lua`/`memory.lua`) existiert generisch; das spezifische "per-Invocation Cursor/Selection/cfile"-Rezept obendrauf ist nicht bestätigt. Günstig, auf vorhandenem Cache-Modul aufzubauen statt neu zu beginnen.

- **Disambiguating-positional-argument helper** for
  `lib.nvim.bindings.usercmd.composer` (match a free-text arg against known enum
  values, warn on uncertainty instead of guessing) — from
  [open.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/open.nvim.md), noting
  [replacer.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/replacer.nvim.md) has a similar ad hoc pattern.
  > **Aufwand: klein · Nutzen: mittel · Status: ✅ weitgehend erledigt** — `usercmd.composer.argtypes` validiert und vervollständigt bereits gegen `enum`-Spezifikationen. Prüfen, ob open.nvim/replacer.nvim darauf umgestellt sind — Migrationsaufgabe statt Neubau.

- **Adaptive Background Poller module** encapsulating poll-vs-due-interval
  decoupling, startup defer, interval cap, idempotent start/stop — from
  [github_stats.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/github_stats.nvim.md).
  > **Aufwand: mittel · Nutzen: mittel · Status: ⬜ offen**. Lohnt sich, sobald ein zweites Poll-Feature ansteht.

- **Paginated-external-API-with-best-effort-partial-results helper** — from
  [github_stats.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/github_stats.nvim.md).
  > **Aufwand: mittel · Nutzen: klein-mittel · Status: ⬜ offen**. Ein Konsument — niedrige Priorität.

- **TUI Dashboard Kit** (cursor-blocking, virtual selection state, auto-scroll,
  count-capable `gg`/`G`/`<C-d>`/`<C-u>`/`<C-f>`/`<C-b>` replication) — from
  [github_stats.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/github_stats.nvim.md), suggested as
  potentially useful for gopath.nvim's own dashboard-like UI.
  > **Aufwand: hoch · Nutzen: mittel · Status: 🟡 teilweise** — `ui.kit` deckt schon viel Fläche ab (`picker`, `chooser`, `select`), das spezifische vim-artige Count-Navigationsverhalten ist darunter nicht eindeutig. Hoher Aufwand — nur bei konkretem zweitem Bedarf (gopath.nvim) sinnvoll.

- **Fail-open tree-sitter-region-filter module** generalizing
  `language.nvim`'s `regions.lua` (capture-name → byte-ranges → fail-open on
  missing query) for `@spell`, `@nospell`, `@comment`, `@string`, etc. — from
  [language.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/language.nvim.md).
  > **Aufwand: klein-mittel · Nutzen: mittel · Status: ⬜ offen** — `lib.nvim.treesitter.guard` ist ein anderes Konzept (Dateityp-Allowlist für Treesitter-Aktivierung, keine Capture→Byte-Range-Extraktion). Echte Lücke, klar abgegrenzt vom vorhandenen Modul — guter Kandidat für markdown.nvim/andere Sprachfeatures.

- **Thesaurus-picker with count-driven direct selection** (`3<leader>th` = 3rd
  synonym, no menu), generalizable to any "replace word under cursor with
  alternative N" feature (spellcheck, thesaurus, translation) — from
  [language.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/language.nvim.md).
  > **Aufwand: mittel · Nutzen: klein · Status: ⬜ offen**. Sehr spezifisches UI-Feature, kein generischer Baustein außer dem Zahlen-Präfix-Muster. Eher plugin-spezifisch lassen.

- **`lib.nvim.lua.scoring` module** (additive score + named bonus/malus list +
  clamp, with a `details` breakdown) generalizing `learn-cli.nvim`'s
  `scoring.lua` for any gamification feature — from
  [learn-cli.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/learn-cli.nvim.md).
  > **Aufwand: klein · Nutzen: klein · Status: ⬜ offen** (kein Treffer im Baum). Ein Konsument, Gamification ist Nische — niedrige Priorität.

- **Spaced-repetition-queue module**, decoupled from CLI-exercise specifics,
  reusable e.g. for `language.nvim`'s translation-history vocabulary review —
  from [learn-cli.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/learn-cli.nvim.md).
  > **Aufwand: mittel · Nutzen: klein-mittel · Status: ⬜ offen**. Erst sinnvoll, wenn language.nvim das Vokabel-Review-Feature wirklich baut.

- **Window-local match-ledger module** (`window -> {id -> match id}`
  bookkeeping) generalizing `spotlight.nvim`'s `matchadd()`/`matchdelete()`
  session-persistence trick — from [spotlight.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/spotlight.nvim.md).
  > **Aufwand: klein · Nutzen: klein · Status: ⬜ offen** — `window.context` ist ein anderes Konzept (Fenster-Infos-Cache, kein `matchadd`/`matchdelete`-Tracking). Ein Konsument, niedrige Priorität.

- **Literal-pattern-builder utility** (`\V` + escaping + `\C`/`\c` + optional
  word-boundaries by token kind) for any plugin matching user text safely
  against Vim regex (search/replace tools, bookmark highlighters) — from
  [spotlight.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/spotlight.nvim.md).
  > **Aufwand: klein · Nutzen: mittel-hoch · Status: ⬜ offen**. Trotz aktuell nur einem bekannten Konsumenten ein guter Kandidat — sicherheitsrelevant, da es Regex-Injection bei Nutzertext verhindert. Siehe Quick-Wins oben.

- **Origin-based exception model** (persistence override keyed by "where
  created" rather than "where occurs") as a general pattern for other
  file-scoped state/opt-out plugins (bookmarks.nvim, todo-highlighter) — from
  [spotlight.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/spotlight.nvim.md).
  > **Aufwand: mittel · Nutzen: klein · Status: ⬜ offen**. Abstraktes Muster, ein Konsument — niedrige Priorität.

- **Checkpoint/Snapshot + manifest + byte-exact restore utility**
  generalizing `replacer.nvim`'s `checkpoint.lua`, for any destructive
  multi-file tool ([fileops.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/fileops.nvim.md),
  [migrate.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/migrate.nvim.md) cwd-scope operations) — from
  [replacer.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/replacer.nvim.md).
  > **Aufwand: hoch · Nutzen: hoch · Status: ⬜ offen** (kein `checkpoint`/`snapshot`-Modul im Baum). Betrifft mehrere destruktive Multi-File-Tools (replacer/fileops/migrate) — Datensicherheit rechtfertigt den Aufwand. Siehe Quick-Wins oben.

- **Case-detection/-preservation module** extracted from `replacer.nvim`'s
  `casing.lua`, useful for [migrate.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/migrate.nvim.md) and
  [fileops.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/fileops.nvim.md)'s rename-assist — from
  [replacer.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/replacer.nvim.md).
  > **Aufwand: klein · Nutzen: mittel · Status: 🟡 unklar** — `lib.lua.strings.transform` existiert, ob es Case-Erkennung/-Erhaltung (camelCase/snake_case/…) bereits abdeckt, wurde nicht im Detail geprüft. Vor Neubau kurz verifizieren.

- **Generic hooks pattern** (`before_apply`/`after_apply`/`before_write`/
  `after_write` with veto + error isolation) as a `lib.nvim` building block
  for any plugin with an apply pipeline ([migrate.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/migrate.nvim.md),
  [pdfport.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/pdfport.nvim.md) extraction) — from
  [replacer.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/replacer.nvim.md).
  > **Aufwand: mittel · Nutzen: mittel · Status: ⬜ offen** (kein Treffer im Baum). Zwei konkrete Konsumenten (migrate.nvim, pdfport.nvim) — solide Priorität.

- **"Bottom-up edit + stale-match verification" as `lib.nvim.buffer.apply_edits`**
  — generic support for any plugin applying multiple positional text edits
  safely — from [replacer.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/replacer.nvim.md).
  > **Aufwand: mittel · Nutzen: hoch · Status: ⬜ offen** (kein `apply_edits` im Baum). Sicherheitsrelevant — verhindert falsch angewandte Edits, wenn sich Positionen zwischen Analyse und Anwendung verschoben haben. Siehe Quick-Wins oben.

- **Bounded-Concurrency Filesystem Scanner module** encapsulating
  `gopath.nvim`'s work-queue scan pattern — reusable for any plugin
  async-indexing large trees, explicitly noting
  [images.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/images.nvim.md)'s scan/orphans code as a possible
  consumer — from [gopath.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/gopath.nvim.md).
  > **Aufwand: mittel · Nutzen: mittel · Status: 🟡 teilweise** — `fs.scan_cached`/`fs.scan_roots` existieren bereits als Scan-Bausteine; ob darin eine bounded-concurrency Work-Queue steckt, nicht bestätigt. Erst prüfen, ob die vorhandenen Module reichen, bevor neu gebaut wird.

- **Cache-only vs. live-fallback resolve interface convention**
  (`resolve_cached`/`resolve_async`/`resolve_sync` trio + confidence-score
  convention) as a naming/shape convention for all resolver-like lib.nvim
  modules — from [gopath.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/gopath.nvim.md).
  > **Aufwand: ~0 (reine Doku-Konvention, kein Code) · Nutzen: mittel · Status: ⬜ offen als dokumentierte Konvention**. Sehr günstig — lohnt sich als reine README-Ergänzung. Siehe Quick-Wins oben.

- **"Create-on-missing" dialog module** (create file + parent dirs + "open in
  filetree" alternative) for any file-opening plugin, including
  [images.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/images.nvim.md) when inserting paths — from
  [gopath.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/gopath.nvim.md).
  > **Aufwand: klein · Nutzen: mittel · Status: 🟡 teilweise** — `fs.create_entry` deckt den reinen Dateisystem-Teil ab (Datei/Ordner inkl. Parent-Dirs anlegen, bewusst ohne UI/Notify); der Dialog-Teil ("open in filetree"-Alternative) fehlt noch. Kleine Ergänzung auf solider Basis.

- **Tag-based keymap registry** (`_registry` + tag-guard) as
  `lib.nvim.keymap.scope`, for any plugin with repeatedly recreated UI buffers
  (custom pickers, floating UIs) — from [reposcope.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/reposcope.nvim.md).
  > **Aufwand: klein-mittel · Nutzen: mittel · Status: 🟡 teilweise** — `bindings.keymap.registry` existiert bereits generisch; ob das Tag/Scope-Konzept speziell für wiederholt neu erzeugte UI-Buffer schon abgedeckt ist, nicht bestätigt.

- **API-response-sanitizer pattern** (required fields → placeholder + warning
  instead of crash) as a lib.nvim building block for any plugin consuming
  external JSON APIs, noting [pdfport.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/pdfport.nvim.md)'s
  backends as a possible consumer — from [reposcope.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/reposcope.nvim.md).
  > **Aufwand: klein-mittel · Nutzen: mittel · Status: ⬜ offen** (kein Treffer im Baum). Würde z. B. pdfport.nvim's Backends robuster machen — solide Priorität.

- **Custom single-line prompt-buffer widget** (cursor-lock via autocommands)
  as a reusable `lib.nvim.ui` component instead of every plugin reinventing
  cursor-locking — from [reposcope.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/reposcope.nvim.md).
  > **Aufwand: — · Nutzen: mittel · Status: ✅ weitgehend erledigt** — `ui.kit.prompt`/`ui.kit.input`/`ui.kit.live_input` decken genau dieses Muster ab. Prüfen, ob reposcope.nvim darauf migriert ist — sonst Migrationsaufgabe statt Neubau.

- **Terminal-capability-detection module** (env-var heuristic + session cache
  + once-per-session warning) for any plugin sending terminal-dependent escape
  sequences — from [images.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/images.nvim.md).
  > **Aufwand: klein · Nutzen: klein-mittel · Status: 🟡 teilweise** — `lib.nvim.terminal` existiert (`is_kitty`, `is_terminal_buf`), die volle Env-Var-Heuristik + Session-Cache + Once-Warning für allgemeine Capability-Erkennung ist nicht sicher vollständig. Kleine Ergänzung.

- **Cell-selection-on-scratch-buffer → pixel-conversion helper** for any
  plugin overlaying a visual selection on non-interactive terminal output
  (other OSC-1337-based overlays) — from [images.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/images.nvim.md).
  > **Aufwand: mittel · Nutzen: klein · Status: 🟡 teilweise** — `lib.nvim.image_preview` existiert bereits; ob die Zell→Pixel-Konvertierung darin steckt, nicht verifiziert. OSC-1337-Overlays sind ohnehin Nische — niedrige Priorität.

- **Safe-external-download module** (timeout + byte-limit + URL-hash cache)
  generalizing `images.nvim`'s `remote.lua:M.fetch`, explicitly noting
  [github_stats.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/github_stats.nvim.md)'s `api.lua` currently
  lacks a byte limit and could benefit — from [images.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/images.nvim.md).
  > **Aufwand: klein (Basis existiert) · Nutzen: mittel · Status: 🟡 teilweise** — `net.curl.download`/`download_blocking` existieren bereits; Timeout/Byte-Limit/URL-Hash-Cache im Detail nicht verifiziert. Kurz prüfen und ggf. github_stats.nvim's `api.lua` (laut Idee ohne Byte-Limit) darauf migrieren statt neu bauen.

- **Range-parser utility** (`"1-3,5,7"` → sorted deduped list) generalizing
  `pdfport.nvim`'s `page_range.lua`, reusable for page/line/commit ranges
  elsewhere — from [pdfport.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/pdfport.nvim.md).
  > **Aufwand: klein · Nutzen: mittel · Status: ⬜ offen** (kein Treffer im Baum). Trivialer, gut wiederverwendbarer Parser — guter Kandidat. Siehe Quick-Wins oben.

- **Progress-wrapping-callback helper** for `lib.nvim.progress`, generalizing
  `pdfport.nvim`'s one-finalization-point closure pattern — from
  [pdfport.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/pdfport.nvim.md).
  > **Aufwand: — · Nutzen: mittel · Status: ✅ weitgehend erledigt** — `lib.nvim.progress` (`M.create`) existiert bereits. Prüfen, ob pdfport.nvim's Closure-Pattern darauf umgestellt ist.

- **`lib.nvim.cache.disk` mtime-based cross-session cache recipe**,
  generalizing `pdfport.nvim`'s `util/cache.lua`, for other expensive
  extraction plugins (video transcription, OCR) — from
  [pdfport.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/pdfport.nvim.md).
  > **Aufwand: — · Nutzen: mittel · Status: ✅ erledigt** — `lib.nvim.cache.disk` existiert bereits und wird produktiv von `deps.first_run` genutzt. Nur noch als Rezept/Beispiel für pdfport.nvim's Anwendungsfall in der Doku ergänzen, falls gewünscht.

- **Portable-Path module** (placeholder substitution on write, resolve on
  read via a temp copy, never mutate the original) generalizing
  `sessions.nvim`'s `portable.lua`, reusable for any plugin syncing artifacts
  cross-machine (notes, bookmarks, project configs) — from
  [sessions.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/sessions.nvim.md).
  > **Aufwand: mittel · Nutzen: mittel · Status: ⬜ offen** (kein Treffer im Baum). Solide Priorität für Cross-Machine-Sync-Szenarien.

- **Git-skip-worktree-toggle helper** generalizing `sessions.nvim`'s
  `toggle_track`, for other "config repo syncs personal/transient files"
  scenarios — from [sessions.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/sessions.nvim.md).
  > **Aufwand: klein · Nutzen: klein · Status: ⬜ offen** — `lib.nvim.git` existiert mit vielen Funktionen (`repo_root`, `is_dirty`, `status_porcelain`, …), aber kein `skip-worktree`-Toggle darunter. Nischen-Feature, ein Konsument — niedrige Priorität, aber günstig zu ergänzen falls gebraucht.

- **Fallback-chain validator** (preferred lib → `vim.system` →
  `vim.fn.system`, plus "looks like error text" validation) as a generic
  utility instead of each plugin reimplementing it — from
  [sessions.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/sessions.nvim.md).
  > **Aufwand: klein · Nutzen: mittel · Status: ⬜ offen** — `cross.run`/`cross.run_argv` existieren als Ausführungs-Layer, die explizite Fallback-Validierungs-Kette wurde nicht bestätigt. Kurz prüfen, sonst günstiger Kandidat.

- **Secret-redaction module** matching header names against a known-sensitive
  list and masking values in any history/log automatically — generalizes
  `runtime-analysis.nvim`'s current "don't store at all" approach — from
  [runtime-analysis.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/runtime-analysis.nvim.md).
  > **Aufwand: — · Nutzen: hoch · Status: ✅ erledigt** — `net.curl.is_secret_header` + `secret_headers`-Handling existiert bereits (siehe jüngster Commit `fix(net.curl): escape newlines in config_quote, dedupe secret_headers vs opts.headers`). Keine Aktion nötig.

- **Fast-event-context linter** detecting `nvim_*` API calls from a
  non-scheduled callback and failing early with a clear message instead of
  `E5560` — from [runtime-analysis.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/runtime-analysis.nvim.md).
  > **Aufwand: hoch (statische Analyse) · Nutzen: mittel · Status: 🟡 anders gelöst** — `lib.nvim.safe_api` löst das Problem laufzeitseitig (pcall-Wrapper statt statischer Lint), nicht das vorgeschlagene Compile-Time-Linting. `safe_api` ist der pragmatischere, bereits gebaute Ersatz; ein echter Linter bliebe separat aufwändig — niedrige Priorität.

- **Token-based supersession library** (`lib.nvim.async.latest_wins(token)`)
  generalizing the pending-token "newest request wins" pattern — likely
  recurs in picker previews, LSP requests, search — from
  [runtime-analysis.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/runtime-analysis.nvim.md).
  > **Aufwand: klein-mittel · Nutzen: hoch · Status: ⬜ offen** — `lib.nvim.token` hat bisher nur `gen_token`, `lib.nvim.async` hat `await`/`run`/`wrap`, aber kein erkennbares `latest_wins`. Sehr verbreitetes Muster (Picker-Previews, LSP, Suche) — bester Kandidat der ganzen Liste. Siehe Quick-Wins oben.

- **Download + checksum-verify + extract bootstrap module** (Mason-like) for
  future LSP/formatter wrapper plugins — from [mdview.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/mdview.nvim.md).
  > **Aufwand: hoch · Nutzen: klein · Status: ⬜ offen** (kein Checksum/SHA-Code im Baum). Aktuell 0 Konsumenten, nur "für künftige Plugins" — spekulativ, YAGNI bis ein konkretes Plugin es braucht.

- **Detached-spawn watcher** diagnostic tool to list/kill orphaned detached
  processes left by previous Neovim instances — from
  [mdview.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/mdview.nvim.md).
  > **Aufwand: mittel · Nutzen: klein · Status: ⬜ offen**. Diagnose-Tool, Nische — niedrige Priorität.

- **`lib.nvim.cross.fs.mutate` with pluggable `on_retry` hooks** as a
  standalone mini-library — every plugin with Windows fileops hits the same
  watcher-lock bug class — from [filetree.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/filetree.nvim.md),
  echoed independently in [fileops.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/fileops.nvim.md).
  > **Aufwand: — · Nutzen: hoch · Status: ✅ erledigt** — `cross.fs.mutate` mit `M.retry`/`on_retry`/`delete_file`/`copy_file`/`rename_file`/`mkdir_p`/`symlink`/`hardlink` existiert bereits vollständig. Prüfen, ob filetree.nvim/fileops.nvim tatsächlich darauf migriert sind.

- **`FiletreeAdapter` interface** generalized into a standalone filetree
  backend-abstraction library, usable for git-status overlays or
  LSP-diagnostics-in-tree plugins — from [filetree.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/filetree.nvim.md).
  > **Aufwand: hoch · Nutzen: mittel · Status: ⬜ offen** — `lib.nvim.neotree` ist eine konkrete neo-tree.nvim-Integration (`node/`, `watch/`), keine generische Adapter-Abstraktion. Hoher Aufwand — zurückstellen bis ein zweites Baum-Plugin es braucht.

- **`cwd_mode`** (root-policy state machine + `dir_guard` + diff-based
  statusline update) as a standalone "project-root-policy" plugin,
  independent of any filetree — from [filetree.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/filetree.nvim.md).
  > **Aufwand: mittel · Nutzen: mittel · Status: 🟡 teilweise** — `fs.dir_guard.hold(path)` deckt das Kernstück (cwd halten, bei fremder Änderung zurücksetzen) bereits ab; die volle State-Machine + Diff-basiertes Statusline-Update fehlt vermutlich noch. Auf `dir_guard` aufbauen statt neu beginnen.

- **Locale-independent Windows Recycle-Bin restore** as its own small
  cross-platform trash library — from [filetree.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/filetree.nvim.md).
  > **Aufwand: mittel (Windows-API-spezifisch) · Nutzen: mittel · Status: 🟡 teilweise** — `fs.trash.trash`/`trash_blocking` existiert bereits ("send to trash", nicht permanent löschen); das *Restore*-Gegenstück (aus dem Papierkorb zurückholen) ist im Funktionsumfang nicht erkennbar. Prüfen, ob Restore wirklich fehlt, dann kleine Ergänzung statt eigener Bibliothek.

- **Markdown-reference-aware move/delete flow** (scan → prefetch at staging →
  chooser → retarget) generalized to other link formats (reST, AsciiDoc) —
  from [filetree.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/filetree.nvim.md) and echoed by
  [markdown.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/markdown.nvim.md)'s **link-integrity.nvim** idea
  (same pattern, framed as a standalone plugin for arbitrary file types).
  > **Aufwand: hoch · Nutzen: mittel · Status: ⬜ offen**. Zwei Plugins schlagen das unabhängig vor — aber wie die Idee selbst schon andeutet, passt es eher als eigenständiges Plugin ("link-integrity.nvim") als als lib.nvim-Baustein.

- **Adaptive-debounce module** (file/input size → delay tier) if the pattern
  recurs across plugins (color_my_ascii, possibly github_stats background
  fetching) — from [color_my_ascii.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/color_my_ascii.nvim.md).
  > **Aufwand: klein · Nutzen: klein · Status: 🟡 teilweise** — `lib.nvim.debounce` existiert bereits generisch (inkl. `buffer/`-Variante und `new_with_counter`), die adaptive Größen-Tier-Logik obendrauf fehlt. Explizit als "falls das Muster wiederkehrt" formuliert — YAGNI bis konkreter zweiter Bedarf.

- **Cache-statistics widget** (`:CacheStats`-like command) showing hit-rate/
  size/evictions uniformly across plugins — from
  [color_my_ascii.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/color_my_ascii.nvim.md).
  > **Aufwand: klein · Nutzen: klein-mittel · Status: ⬜ offen** (kein `stats`-Treffer im `cache`-Modul). Günstig, aber Nice-to-have.

- **Regex/pattern-migration framework** (registry + generic picker +
  long-string tracker) reusable by other *.nvim projects for their own API
  migrations — from [migrate.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/migrate.nvim.md).
  > **Aufwand: hoch · Nutzen: klein · Status: ⬜ offen**. Bleibt sinnvollerweise in migrate.nvim, kein lib.nvim-Kandidat solange kein zweites Migrations-Tool existiert.

- **Deprecation watcher** warning on `:checkhealth`/save if unmigrated
  deprecated calls remain — deliberately not built into migrate.nvim itself —
  from [migrate.nvim](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/plugins/migrate.nvim.md).
  > **Aufwand: mittel · Nutzen: klein-mittel · Status: ⬜ offen**. Bewusst nicht in migrate.nvim eingebaut laut Quelle — passt eher als eigenständiges Mini-Tool. Niedrige Priorität.

- **Robust buffer-jump fallback chain** (`vim.t.bufs` → `tabpagebuflist` →
  windows → `getbufinfo`) generalized into a shared "which buffers are
  visible in this session" helper, currently duplicated at one call site —
  from [nvim-config](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/nvim-config.md).
  > **Aufwand: klein · Nutzen: mittel · Status: 🟡 teilweise** — `lib.nvim.buf_win_tab` (u. a. `capture/`, `selection/`) existiert als Sammlung verwandter Hilfsfunktionen, die exakte 4-stufige Fallback-Kette ist nicht sicher bestätigt. Günstig, kleine Lücke schließen.

- **Startup-phase-runner** (`lua/startup/`) as a standalone, minimal,
  config-independent plugin for measuring/reporting any Neovim config's
  startup phases — from [nvim-config](E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists/belege/nvim-config.md).
  > **Aufwand: mittel · Nutzen: mittel (nur für die eigene Config gedacht, nicht für lib.nvim-Konsumenten) · Status: ⬜ offen**. Explizit config-seitiges Tool, kein lib.nvim-Baustein — gehört eher in die nvim-config selbst oder ein eigenständiges Utility-Plugin.
