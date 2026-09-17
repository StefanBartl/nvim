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

**16 von 36 Repos abgeschlossen**; Runde 17 (reposcope.nvim), 18 (gopath.nvim) und 19 (color_my_ascii.nvim) laufen parallel.

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
| 17 | reposcope.nvim | 17 | *läuft* | — |
| 18 | gopath.nvim | 18 | *läuft* | — |
| 19 | color_my_ascii.nvim | 19 | *läuft* | — |

Details je Runde: siehe Handover, Abschnitt "Fortschritt".

## Warteschlange

Nach den drei laufenden Runden in dieser Reihenfolge (🟠 vor 🟡, siehe Survey):

diff.nvim → cascade.nvim →
sandbox.nvim → data.nvim → spotlight.nvim → mdview.nvim → filetree.nvim → lsp.nvim

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
| reposcope.nvim | 113 | 12 | 🔄 Runde 17 läuft |
| gopath.nvim | 77 | 16 | 🔄 Runde 18 läuft |
| color_my_ascii.nvim | 95 | 17 | 🔄 Runde 19 läuft |
| diff.nvim | 23 | 17 | 🟡 mittel |
| cascade.nvim | 48 | 18 | 🟡 mittel |
| sandbox.nvim | 270 | 19 | 🟡 mittel (sehr großes Repo) |
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
| github_stats.nvim | `BufWipeout`-Handler löschte den Buffer, der gerade gewiped wird → `E937`, sobald der Buffer beim Wipe noch in seinem Fenster lag (`nvim_buf_delete()` von außen; `:q`/`:bwipeout`/`:bdelete`/`close()` waren immer sauber) | `dfdb1d8` |

### Offen (gepinnt)

**Runde 16 / fileops.nvim** — fünf Stück, drei davon nur unter Windows sichtbar:

| Datei | Bug |
|---|---|
| `bindings/keymaps.lua` | die Delete-Taste ruft `delete_fn({})` ohne Optionen → `<leader>dcf` löscht seit dem Default-Wechsel auf `"trash"` weiterhin **permanent und ohne Undo** und ruft `on_before_delete` nie auf, obwohl der Modul-Header behauptet, `:File delete` zu spiegeln |
| `ops/cycle.lua` | mit `follow_symlinks = false` joint `list_files` mit `/`, der Buffername nutzt `\`, `canon` normalisiert unter Windows nicht → `index_of` findet die aktuelle Datei nie, `:File next`/`prev` sind ein lautloser No-op |
| `ops/bulk.lua` | `plan` joint mit `/`, wenn die Wurzel keinen Trenner am Ende hat (genau was `cycle.get_root_dir` liefert) → `nvim_buf_set_name` läuft nie, der Buffer zeigt nach `bulk rename` auf eine tote Datei, das nächste `:w` schreibt den alten Namen zurück |
| `ops/file.lua` | `delete_path` nimmt Verzeichnisse an, die `uv.fs_unlink` nie löschen kann → Windows-`EPERM` wird als transiente Sharing-Violation missdeutet, ~1,9 s Retry-Budget verbrannt, danach macht die Fehlermeldung einen Virenscanner verantwortlich |
| `features/conflict_marks.lua` | ein erneutes `:edit` derselben Datei ist ein `BufWinEnter` ohne vorheriges `BufWinLeave` → drei neue Matches je Aufruf, die alten IDs werden überschrieben und damit unlöschbar |

**Runde 15 / emojis.nvim**

| Datei | Bug |
|---|---|
| `init.lua` | der Visual-Zweig liest `'<`/`'>`, die Neovim erst beim *Verlassen* des Bereichs setzt; das Preset bindet `toggle` aber in `mode = { "n", "x" }` → erste Selektion bricht mit "no previous visual selection" ab, danach wird still die **vorherige** Selektion umgeschaltet. Das dokumentierte Feature funktioniert nie korrekt (`:'<,'>Emojis toggle` ist nicht betroffen) |
| `overlay/frecency.lua` | `save()`s `mkdir` steht außerhalb jedes pcall → ein rohes `E739` fliegt aus **jeder** Emoji-Einfügung, obwohl der Moduldoc genau das ausschließt ("losing a usage histogram must never break emoji insertion") |
| `search.lua` | greedy `^(.+):%d+:` — das eigene Shortcode-Vokabular liefert das Gegenbeispiel: `notes.md:3:scored 💯 out of :100:` wird zu Datei `notes.md:3:scored 💯 out of ` / Zeile 100; für `clear`/`replace` endet das in `E484` auf einem erfundenen Pfad |
| `search.lua` | `RG_PATTERN` deckt nur drei der vier `core.patterns.RANGES` ab; Misc Technical (⌚ ⏳ ⏰) fehlt, `cwd`-Aktionen überspringen diese Glyphen still |
| `health.lua` | meldet einen fehlenden lib.nvim-Composer als Error und ruft danach `composer.checkhealth()` unbedingt auf — auf genau der Maschine, die die Meldung braucht, bricht der Report ab |

**Runde 14 / pdfport.nvim**

| Datei | Bug |
|---|---|
| `backends/tesseract.lua` | `finish_error()` meldet `page_idx - 1`, aber `process_next()` hat den Index schon weitergezählt → ein Fehlschlag auf Seite 1 meldet "1 Seite verarbeitet". Der formgleiche `fail()` in `backends/ollama.lua` rechnet mit `page_idx - 2` richtig — dieselbe Vorlage, nur eine Kopie korrigiert |
| `bindings/autocmds.lua` | verspricht in Modul-Doc und Kommentar, die eigene Augroup zu leeren und neu zu bauen, tut es aber nicht: `lib.nvim`s `autocmd.create` löst einen String-`group` ohne `clear` auf. Ein zweites `setup()` mit `auto_open_on_read` hinterlässt zwei `BufReadCmd *.pdf`-Autocmds, der Mode-Picker geht doppelt auf |
| `integrations/{fzf,telescope}.lua` | memoisieren per Pfad, **bevor** `result.status` geprüft wird → eine einmal gescheiterte Extraktion (ollama nicht gestartet, poppler fehlt) wird für die ganze Session als Fehlertext wiedergespielt. `util/cache.lua` verweigert genau das ausdrücklich |

**Runde 13 / sessions.nvim** — beide wären ein Wechsel von "wirft" zu "meldet", daher gepinnt:

| Datei | Bug |
|---|---|
| `core.lua` | `save()`/`save_tab()` versprechen `(ok, err)` und kapseln `:mksession` in `pcall`, nicht aber das `ensure_dir()` darüber → ein nicht anlegbarer `cfg.root` entkommt als rohes `E739`, auch aus dem `VimLeavePre`-Autosave heraus (dieselbe Fehlerklasse wie der export.lua-Fund aus Runde 11) |
| `layout.lua` | `restore()` prüft nur `type(tree) ~= "table"`, lässt also `{}`/`[]` durch; `build()` stirbt dann an `attempt to get length of local 'children' (a nil value)` statt das versprochene "corrupt or missing layout file" zu melden |

Zusätzlich als Verhalten gepinnt (kein Defekt): `core.rename` zieht `.state.json` nicht mit — zwischen
Umbenennen und nächstem Save greifen `:Session load` und der Autoload auf `default_name` zurück.

**Runde 12 / insights.nvim**

| Datei | Bug |
|---|---|
| `symbols/parser.lua` | `parse_vimgrep_line()` splittet an den ersten drei Doppelpunkten; der Windows-Laufwerksbuchstabe frisst das Dateinamen-Feld, jede rg-Zeile wird still verworfen → **`:Insights symbols` findet unter Windows gar nichts** (verifiziert: rg gibt hier `E:/repos/…` aus) |
| `symbols/ts_lua.lua` | der `assignment_statement`-Zweig nutzt `field("left")`/`field("right")`, die es in tree-sitter-lua nicht gibt → toter Code; `M.foo = function()` liefert mit `use_treesitter_for_lua` keine Symbole |
| `symbols/ts_lua_tables.lua` | derselbe Defekt an eigener Stelle: verschachtelte Table-Felder bekommen nie ihr Präfix (`imports/ts_requires.lua` trägt bereits einen `child_of_type`-Helfer, der genau das löst) |
| `tree/init.lua` | Exclude-Globs werden Lua-Pattern-Stil mit `%` escapt, landen aber als Regex beim externen Tool → `*/.git/*` matcht nie, `:Insights tree`/`count` enthalten unter Windows das ganze `.git/` |

## Historie: der ursprüngliche 3-Repo-Report

Die erste Fassung dieses Reports (2026-09-15) deckte nur `pickers.nvim`, `dap.nvim` und
`cmdlog.nvim` ab und schätzte deren Aufwand auf 24–39 Stunden. Alle drei sind inzwischen
abgeschlossen (Runden 1–3); der Aufwandsschätzer hat sich als grob passend erwiesen, die
Reihenfolge-Empfehlung (pickers → dap → cmdlog) wurde zu pickers → cmdlog → dap umsortiert,
weil cmdlogs Harness bereits existierte und nur ausgebaut werden musste.
