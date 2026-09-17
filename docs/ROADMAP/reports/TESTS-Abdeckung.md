# Testabdeckung aller `.nvim`-Plugins — Statusreport

> Stand: 2026-09-17. Dieser Report ist die **Übersicht**; die ausführliche Runden-Doku
> (was je Repo abgedeckt/ausgelassen wurde, gefundene Bugs, Commit-SHAs) steht im Handover
> [`../handovers/test-coverage/test-coverage-campaign.md`](../handovers/test-coverage/test-coverage-campaign.md).

## Table of content

  - [Ziel und Vorgehen](#ziel-und-vorgehen)
  - [Fortschritt](#fortschritt)
  - [Warteschlange](#warteschlange)
  - [Survey aller Repos](#survey-aller-repos)
  - [Gefundene Bugs](#gefundene-bugs)
  - [Historie: der ursprüngliche 3-Repo-Report](#historie-der-ursprngliche-3-repo-report)

---

## Ziel und Vorgehen

Jedes `.nvim`-Plugin soll idealerweise 100% Abdeckung im eigenen `TESTS/`-Ordner haben.
Ein Repo gilt als "fertig", wenn jedes Modul mit echter Logik eine Assertion-Suite hat und
jede bewusste Auslassung im jeweiligen `TESTS/README.md` **mit Begründung** dokumentiert ist.

Regeln, die sich über die Runden eingespielt haben:

- Bestehende Test-Konvention des Repos beibehalten (eigener `H.eq`/`check()`-Harness vs.
  plenary/busted vs. eigenständige `TESTS/*.lua`-Skripte) — kein Framework-Wechsel nebenbei.
- Bewusst ausgelassen: reine `@types`/`---@meta`-Dateien, deklarative Tabellen ohne
  Verzweigung, Rendering-Wrapper, die ein echtes Backend (telescope/fzf-lua/snacks) brauchen,
  und alles, was einen echten externen Prozess oder Netzwerkzugriff erfordert.
- Gefundene Bugs werden **nicht stillschweigend wegrefactored**: entweder trivialer Blocker →
  Fix mit Begründung, oder `BUG:`-Assertion als Pin plus separater Fix-Task.
- Pro Repo: `luacheck`/`stylua` mit exakt den CI-Befehlen grün, Suite real headless gelaufen,
  Commit direkt auf `main` des jeweiligen Repos.
- Seit 2026-09-17 bis zu **drei** Agents gleichzeitig (vorher einer), je ein Repo pro Agent. Den
  gemeinsamen Handover schreibt nur die Hauptsession — parallele Agents würden sich dort
  gegenseitig überschreiben.

## Fortschritt

**20 von 36 Repos abgeschlossen**; Runde 21 (cascade.nvim) und 22 (sandbox.nvim) laufen parallel.

| # | Repo | Runde | Commit | Kurzfassung |
|---:|---|---:|---|---|
| 1 | pickers.nvim | 1 | `fbaed4c` | 19 ungetestete Logikdateien ergänzt; 400 → 575 Checks |
| 2 | cmdlog.nvim | 2 | `a43edc9` | `core/*`, `config/`, `bindings/*`, Picker-Merge; 35 → 257 Checks |
| 3 | dap.nvim | 3 | `5f2da6e` | 11 Sprach-Tabellen über 2 generische Contract-Specs; 4 → 30 Specs |
| 4 | casedesk.nvim | 4 | `3cc4cd9` | 32 neue Specs; 40 → 386 Assertions |
| 5 | buffer-ctx.nvim | 5 | `6290f8b` | 6 neue Specs; 24 → 40 von 46 Dateien abgedeckt |
| 6 | debugging.nvim | 6 | `7b05563` | 10 neue Specs; ~6 → ~23 von 34 Dateien |
| 7 | recommender.nvim | 7 | `6e7fb65` | 6 neue Specs; 5 → 11 von 23 Dateien |
| 8 | language.nvim | 8 | `51dd7d1` | 21 neue Specs; ~6 → 43 von 51 Dateien |
| 9 | open.nvim | 9 | `a8dbe1d` | 9 neue Specs; ~12 → 24 von 26 Dateien |
| 10 | replacer.nvim | 10 | `053e1d6` | 5 neue Suiten + CI-Verdrahtung; 8 → 13 Dateien |
| 11 | github_stats.nvim | 11 | `1b9b638` | 13 neue Specs, 4 erweitert; 109 → 482 Assertions |
| 12 | insights.nvim | 12 | `1be0f7a` | 24 neue Specs, 2 erweitert; 112 → 1590 Assertions |
| 13 | sessions.nvim | 13 | `0034df3` | 10 neue Specs; 77 → 487 Assertion-Stellen |
| 14 | pdfport.nvim | 14 | `3c9273a` | 11 neue Specs; 192 → 1059 Assertion-Stellen |
| 15 | emojis.nvim | 15 | `5ea0333` | 13 neue Specs; 261 → 773 Assertions |
| 16 | fileops.nvim | 16 | `7060232` | 10 neue Specs; 199 → 805 Assertions |
| 17 | reposcope.nvim | 17 | `98a9a36` | 25 neue Specs; 236 → 1910 Assertions |
| 18 | gopath.nvim | 18 | `394b4b3` | neue Unit-Suite unter `scripts/ci/`: 17 Specs, 435 Checks |
| 19 | color_my_ascii.nvim | 19 | `adcb5ef` | 13 neue Specs; 324 → 5566 Assertions |
| 20 | diff.nvim | 20 | `d7aa3a5` | 10 neue Specs; 295 → 694 Assertion-Stellen |
| 21 | cascade.nvim | 21 | *läuft* | — |
| 22 | sandbox.nvim | 22 | *läuft* | — |

Details je Runde: siehe Handover, Abschnitt "Fortschritt".

## Warteschlange

Nach den laufenden Runden in dieser Reihenfolge (siehe Survey):

data.nvim → spotlight.nvim → mdview.nvim → filetree.nvim → lsp.nvim

Die 🟢-Repos (`images.nvim`, `ai.nvim`, `hover.nvim`, `runtime-analysis.nvim`, `lib.nvim`,
`markdown.nvim`, `documentation.nvim`, `media.nvim`, `ui.nvim`) bekommen keine volle Runde,
außer eine konkrete Prüfung findet doch eine Lücke.

## Survey aller Repos

Lua-Quelldateien in `lua/` vs. Testdateien (grober Proxy, keine echte %-Abdeckung);
Erhebung 2026-09-15, die ✅-Zeilen sind seither abgearbeitet.

| Plugin | lua_src | lua_test | Status |
|---|---:|---:|---|
| pickers.nvim | 73 | 2 | ✅ fertig |
| cmdlog.nvim | 40 | 1 | ✅ fertig |
| dap.nvim | 41 | 5 | ✅ fertig |
| casedesk.nvim | 46 | 6 | ✅ fertig |
| buffer-ctx.nvim | 45 | 7 | ✅ fertig |
| debugging.nvim | 34 | 7 | ✅ fertig |
| recommender.nvim | 23 | 7 | ✅ fertig |
| language.nvim | 51 | 8 | ✅ fertig |
| open.nvim | 26 | 8 | ✅ fertig |
| replacer.nvim | 40 | 8 | ✅ fertig |
| github_stats.nvim | 44 | 9 | ✅ fertig |
| insights.nvim | 49 | 9 | ✅ fertig |
| sessions.nvim | 17 | 9 | ✅ fertig |
| pdfport.nvim | 50 | 10 | ✅ fertig |
| emojis.nvim | 23 | 11 | ✅ fertig |
| fileops.nvim | 18 | 11 | ✅ fertig |
| reposcope.nvim | 113 | 12 | ✅ fertig |
| gopath.nvim | 77 | 16 | ✅ fertig |
| color_my_ascii.nvim | 95 | 17 | ✅ fertig |
| diff.nvim | 23 | 17 | ✅ fertig |
| cascade.nvim | 48 | 18 | 🔄 Runde 21 läuft |
| sandbox.nvim | 270 | 19 | 🔄 Runde 22 läuft (sehr großes Repo) |
| data.nvim | 16 | 20 | 🟡 mittel |
| spotlight.nvim | 27 | 19 | 🟡 mittel |
| mdview.nvim | 78 | 24 | 🟡 mittel |
| filetree.nvim | 129 | 26 | 🟡 mittel |
| lsp.nvim | 176 | 29 | 🟡 mittel (großes Repo) |
| images.nvim | 37 | 29 | 🟢 gut |
| ai.nvim | 25 | 35 | 🟢 gut |
| hover.nvim | 40 | 38 | 🟢 gut |
| runtime-analysis.nvim | 43 | 54 | 🟢 gut |
| lib.nvim | 497 | 159 | 🟢 gut (Basis-Lib) |
| markdown.nvim | 81 | 102 | 🟢 gut |
| documentation.nvim | 139 | 104 | 🟢 gut |
| media.nvim | 31 | 98 | ✅ fertig (eigene Session) |
| ui.nvim | 93 | 232 | ✅ sehr gut |

## Gefundene Bugs

### Gefixt

| Repo | Bug | Fix |
|---|---|---|
| cmdlog.nvim | `:history`'s `>`-Marker der letzten Zeile wurde vom Parser verschluckt | `240ca1d` |
| buffer-ctx.nvim | `alpha_marker()` Off-by-one (`za.`/`zb.` statt `a.`/`b.`) | `79893f9` |
| buffer-ctx.nvim | `format/text_width.lua` dupliziert Bullet-Marker beim Reflow (+ Folgefehler in `wrap_words()`) | `3c99c3c` |
| recommender.nvim | Tree-sitter-Query nutzte veraltete Knotennamen (+ `iter_matches`-Listen-Semantik) | `cc338f6` |
| debugging.nvim | `inline_debug.lua` baute den Log-Pfad ohne Trenner zusammen | `8ac567e` |
| replacer.nvim | `config.get()` gab verschachtelte Tabellen per Referenz statt Deep-Copy zurück (+ toter Debug-Code) | `7031f73` |
| casedesk.nvim | `doctor.lua`'s `x and nil or y`-Idiom ließ den Ambiguitäts-Guard nie greifen | in `3cc4cd9` |
| github_stats.nvim | `dashboard/detail.lua` maß die Periode mit `vim.fn.strptime()`, das unter Windows immer `0` liefert → jede Spanne las sich als "(1 days)" | in `1b9b638` |
| github_stats.nvim | `usrcmds/utils.lua`s `split_lines()` hängte an jedes Ergebnis eine Leerzeile an; `show_float()` ruft es pro Array-Element auf → jeder mehrzeilige Report kam doppelt zeilenumbrochen heraus | `6a85943` |
| github_stats.nvim | `export.lua`s `write_lines()` pcallte das `writefile`, nicht das vorangehende `mkdir` → ein nicht anlegbares Elternverzeichnis entkam als rohes `E739` | `6a85943` |
| lib.nvim | `net/curl`s `is_secret_header` kannte GitLabs `PRIVATE-TOKEN` nicht → jeder authentifizierte GitLab-Request schrieb sein Token in die curl-Kommandozeile, lesbar für jeden anderen Prozess | `5c6b1ac` |
| fileops.nvim | die Delete-Taste rief `delete_fn({})` ohne Optionen → löschte trotz `delete.mode = "trash"` permanent und ohne Undo, und rief `on_before_delete` nie | `e7185fc` |
| fileops.nvim | `ops/cycle.lua` + `ops/bulk.lua`: `/`-Join vs. `\`-Buffername verglichen nie gleich → Navigation als No-op, Phantom-Buffer nach Rename. Nur der **Vergleich** normalisiert jetzt, nicht die gespeicherten Pfade | `81e15ee` |
| fileops.nvim | `delete_path` nahm Verzeichnisse an, die `uv.fs_unlink` nie löschen kann → `EPERM`-Retry-Budget verbrannt, danach Virenscanner beschuldigt | `81e15ee` |
| fileops.nvim | `conflict_marks` leakte pro `:e` drei unlöschbare Matches | `ffc1c9a` |
| insights.nvim | `symbols/parser.lua` verwarf unter Windows jeden rg-Treffer (Laufwerksbuchstabe im `:`-Split) → `:Insights symbols` fand lautlos nichts; `ui/scratch.lua`s Follow-Key hatte denselben blinden Fleck | `6031069` |
| emojis.nvim | der Visual-Zweig las die Marken der *vorherigen* Selektion → erste Selektion brach ab, jede weitere schaltete fremde Zeilen um | `7583459` |
| emojis.nvim | `frecency.save()`s ungeschütztes `mkdir` riss jede Emoji-Einfügung mit | `7583459` |
| color_my_ascii.nvim | `ensure-blank-lines` fügte Leerzeilen **in** den Block ein und zerstörte die ASCII-Art; zudem nicht idempotent | `0437fe0` |
| color_my_ascii.nvim | `unique_words`-Lookup war hash-order-abhängig (8 Wörter in zwei Sprachen) → Sprach-Erkennung nicht entschieden | `0437fe0` |
| github_stats.nvim | `BufWipeout`-Handler löschte den Buffer, der gerade gewiped wird → `E937`, sobald der Buffer beim Wipe noch in seinem Fenster lag (`nvim_buf_delete()` von außen; `:q`/`:bwipeout`/`:bdelete`/`close()` waren immer sauber) | `dfdb1d8` |

### Offen (gepinnt)

Stand nach dem Fix-Durchgang: **17 offen** (war 25). Erledigt sind alle fünf aus fileops.nvim,
zwei von vier aus emojis.nvim, einer aus insights.nvim (plus der mitgefixte Follow-Key), der
Token-Leak aus reposcope.nvim (in lib.nvim), und zwei der sechs aus color_my_ascii.nvim.

| Repo | Datei | Bug |
|---|---|---|
| insights.nvim | `symbols/ts_lua.lua` | der `assignment_statement`-Zweig nutzt `field("left")`/`field("right")`, die es in tree-sitter-lua nicht gibt → toter Code |
| insights.nvim | `symbols/ts_lua_tables.lua` | derselbe Defekt: verschachtelte Table-Felder bekommen nie ihr Präfix |
| insights.nvim | `tree/init.lua` | Exclude-Globs Lua-Stil escapt, landen aber als Regex → `*/.git/*` matcht nie |
| sessions.nvim | `core.lua` | `save()`s `ensure_dir()` steht außerhalb des pcall → rohes `E739`, auch aus dem `VimLeavePre`-Autosave |
| sessions.nvim | `layout.lua` | `restore()` lässt `{}`/`[]` durch → `build()` stirbt an einer nil-Kinderliste |
| emojis.nvim | `search.lua` | gieriger `file:line:`-Split verliert gegen das eigene `:100:`-Shortcode |
| emojis.nvim | `search.lua` | `RG_PATTERN` deckt Misc Technical (⌚ ⏳ ⏰) nicht ab |
| pdfport.nvim | `backends/tesseract.lua` | `finish_error()` zählt die gescheiterte Seite mit |
| pdfport.nvim | `bindings/autocmds.lua` | nicht idempotent trotz gegenteiliger Doku → zweites `setup()` hinterlässt zwei `BufReadCmd`-Autocmds |
| pdfport.nvim | `integrations/{fzf,telescope}.lua` | cachen Fehlschläge → eine gescheiterte Extraktion wird die ganze Session wiedergespielt |
| reposcope.nvim | `clone_manager.lua` | `not isdirectory(path)` ist immer `false` (0 ist truthy) → Pfad-Guard und `safe_mkdir` beide toter Code |
| reposcope.nvim | `bindings/keymaps.lua` | `unset_prompt_keymaps()` räumt per falschem Tag auf → `_registry` wächst pro Open/Close-Zyklus |
| reposcope.nvim | `repository_fetcher.lua` | `vim.json.decode("null")` liefert truthy `vim.NIL` → wirft statt über `on_failure` zu melden (GitLab-Fetcher macht es richtig) |
| reposcope.nvim | `utils/protection.lua` | `is_valid_path()` wirft ohne das laut Doc optionale zweite Argument |
| reposcope.nvim | `ui/actions/readme_viewer.lua` | zweites Öffnen bei offenem Viewer → `Invalid buffer id` |
| color_my_ascii.nvim | `comment_ascii`-Pfad | Highlights liegen `#prefix + 1` Bytes zu weit links (gestrippter Text als Koordinatensystem für Extmarks in der ungestrippten Zeile) |
| color_my_ascii.nvim | `parser.get_byte_offset` | fährt `vim.str_utf_pos` als Iterator, das eine Tabelle liefert → wirft für jede Spalte > 0 |
| color_my_ascii.nvim | `enable_bracket_highlighting` | kann Bracket-Highlighting nicht abschalten, weil `groups/operators.lua` alle sechs Klammern beansprucht |
| color_my_ascii.nvim | 12 Keywords | stehen doppelt in ihrer eigenen Sprachdatei → doppelt gemalt, doppelt im Tiebreaker |
| gopath.nvim | `external/helpers/opener.lua` | unparenthesiertes `gsub` im Table-Konstruktor → Ersetzungsanzahl landet als drittes argv-Element |
| gopath.nvim | `extractor/helpers.lua` | `expand_right` nimmt das Terminator-Zeichen mit in den Pfad |
| gopath.nvim | `tailsearch.sanitize` | Drive-Strip läuft vor der Backslash-Normalisierung und schließt Kleinbuchstaben aus |
| gopath.nvim | `resolvers/lua/require_path.lua` | die Vorzeilen-Suche für mehrzeilige `require(...)` ist toter Code |
| gopath.nvim | `providers/token.lua` | zerstört das `path(line)`-Format, das sein Docstring verspricht |
| gopath.nvim | `commands.check_under_cursor` | der `help`-Zweig ist unerreichbar |
| gopath.nvim | `util/path.invalidate_caches()` | leert `_pdir_*` nicht |
| gopath.nvim | `create.lua` | der "lib.nvim fehlt"-Fallback requirt ungeschützt genau diese Dependency |
| diff.nvim | `core/directory.lua` | ungeschütztes `readfile` → rohes `E484` an `on_done` vorbei, Aufrufer wartet ewig |
| diff.nvim | `core/scratch.lua` | `track()` dedupliziert nicht → `status()` kann `diff:3` melden |
| diff.nvim | `health.lua` | der "lib.nvim fehlt"-Zweig ruft danach unbedingt in lib.nvim hinein |

**Wiederkehrende Familien** (die Kampagne findet dieselben vier Fehler immer wieder):
Windows-Pfadbehandlung; ungeschützte Dateisystem-Aufrufe, deren `E739`/`E482` am eigenen
Fehlerpfad vorbeifliegt; Caches, die Fehlschläge memoisieren; und — inzwischen in **drei**
Repos (emojis, diff, gopath) — ein Health-Check, dessen "Dependency fehlt"-Zweig danach
unbedingt in genau diese Dependency hineinruft.

## Historie: der ursprüngliche 3-Repo-Report

Die erste Fassung dieses Reports (2026-09-15) deckte nur `pickers.nvim`, `dap.nvim` und
`cmdlog.nvim` ab und schätzte deren Aufwand auf 24–39 Stunden. Alle drei sind inzwischen
abgeschlossen (Runden 1–3); der Aufwandsschätzer hat sich als grob passend erwiesen, die
Reihenfolge-Empfehlung (pickers → dap → cmdlog) wurde zu pickers → cmdlog → dap umsortiert,
weil cmdlogs Harness bereits existierte und nur ausgebaut werden musste.
