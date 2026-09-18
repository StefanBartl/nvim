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

**27 von 36 Repos abgeschlossen — die urspruengliche Warteschlange ist komplett, UND ihr
kompletter Re-Audit gegen die 100%-Vorgabe (Runden 1-26) ist ebenfalls fertig.** Runde 27
(lsp.nvim) selbst ist erst frisch fertig geworden und braucht deshalb noch keinen separaten
Re-Audit-Durchgang. Die neun 🟢-Repos (siehe Survey) bekamen laut ursprünglicher Vorgabe
bewusst keine volle Runde, außer eine konkrete Prüfung findet doch eine Lücke — das steht
als möglicher nächster Schritt noch offen.

| # | Repo | Runde | Commit | Kurzfassung |
|---:|---|---:|---|---|
| 1 | pickers.nvim | 1 | `fbaed4c` | 19 ungetestete Logikdateien ergänzt; 400 → 575 Checks |
| 2 | cmdlog.nvim | 2 | `a43edc9` | `core/*`, `config/`, `bindings/*`, Picker-Merge; 35 → 257 Checks |
| 3 | dap.nvim | 3 | `5f2da6e` | 11 Sprach-Tabellen über 2 generische Contract-Specs; 4 → 30 Specs |
| 4 | casedesk.nvim | 4 | `3cc4cd9` | 32 neue Specs; 40 → 386 Assertions |
| 5 | buffer-ctx.nvim | 5 | `6290f8b` | 6 neue Specs; 24 → 40 von 46 Dateien abgedeckt |
| 6 | debugging.nvim | 6 | `5bdd781` (Re-Audit) | 10 neue Specs; ~6 → ~23 von 34 Dateien; Re-Audit: 15 → 16 Specs |
| 7 | recommender.nvim | 7 | `bef1939` (Re-Audit) | 6 neue Specs; 5 → 11 von 23 Dateien; Re-Audit: 12 → 15 Specs (ui.kit-Seam entsperrt) |
| 8 | language.nvim | 8 | `780aea6` (Re-Audit) | 21 neue Specs; ~6 → 43 von 51 Dateien; Re-Audit: 27 → 29 Specs |
| 9 | open.nvim | 9 | `553a445` (Re-Audit) | 9 neue Specs; ~12 → 24 von 26 Dateien; Re-Audit: 15 → 16 Specs |
| 10 | replacer.nvim | 10 | `6153561` (Re-Audit) | 5 neue Suiten + CI-Verdrahtung; 8 → 13 Dateien; Re-Audit: 9 → 10 CI-Dateien, 374 → 411 Checks |
| 11 | github_stats.nvim | 11 | `479fd9c` (Re-Audit) | 13 neue Specs, 4 erweitert; 109 → 482 Assertions; Re-Audit: 492 → 499 Checks |
| 12 | insights.nvim | 12 | `6bbab32` (Re-Audit) | 24 neue Specs, 2 erweitert; 112 → 1590 Assertions; Re-Audit: 1342 → 1362 Stellen |
| 13 | sessions.nvim | 13 | `12a4fb6` (Re-Audit) | 10 neue Specs; 77 → 487 Assertion-Stellen; Re-Audit: 498 → 504 Stellen |
| 14 | pdfport.nvim | 14 | `4bb13eb` (Re-Audit) | 11 neue Specs; 192 → 1059 Assertion-Stellen; Re-Audit: 1048 → 1057 Stellen |
| 15 | emojis.nvim | 15 | `9de7b6d` (Re-Audit) | 13 neue Specs; 261 → 773 Assertions; Re-Audit: 773 → 775 Checks |
| 16 | fileops.nvim | 16 | `037d3bb` (Re-Audit) | 10 neue Specs; 199 → 805 Assertions; Re-Audit: 804 → 831 Checks |
| 17 | reposcope.nvim | 17 | `ab97158` (Re-Audit) | 25 neue Specs; 236 → 1910 Assertions; Re-Audit: 1908 → 1934 Checks |
| 18 | gopath.nvim | 18 | `945a3fa` (Re-Audit) | neue Unit-Suite unter `scripts/ci/`: 17 Specs, 435 Checks; Re-Audit: 439 Checks/1610 Assertionen |
| 19 | color_my_ascii.nvim | 19 | `22b9115` (Re-Audit) | 13 neue Specs; 324 → 5566 Assertions; Re-Audit: 859 → 866 Stellen |
| 20 | diff.nvim | 20 | `d7aa3a5` (Re-Audit: solide, nichts zu tun) | 10 neue Specs; 295 → 694 Assertion-Stellen |
| 21 | cascade.nvim | 21 | `0bc75e6` (Re-Audit) | 10 neue Specs; 462 → 981 Assertion-Stellen; Re-Audit: 981 → 995 Stellen |
| 22 | sandbox.nvim | 22 | `d2ea226` (Re-Audit) | 17 → 37 Specs; 136 → 883 Checks; Re-Audit: 883 → 906 Checks |
| 23 | data.nvim | 23 | `a64c208` (Re-Audit: solide, nichts zu tun) | 17 → 29 Specs; 309 → 847 Assertion-Stellen |
| 24 | spotlight.nvim | 24 | `1928336` (Re-Audit) | 17 → 29 Specs; 472 → 1159 Assertionen; Re-Audit: 1159 → 1166 |
| 25 | mdview.nvim | 25 | `59c4a6e` (Re-Audit) | 19 → 30 Specs; 120 → 239 (nvim) + 8 → 13 (busted) Checks; Re-Audit: 33 Specs, 247 (nvim) + 19 (busted) |
| 26 | filetree.nvim | 26 | `8976113` (Re-Audit/Follow-up) | 696 → 858 Checks (Gap-Closing, sehr großes Repo); Follow-up: 858 → 945 Checks, alle 14 vertagten Dateien geschlossen |
| 27 | lsp.nvim | 27 | `30e3e6a` | 6 neue Specs; 697 → 729 Checks (2 zusätzlich durch eine parallel arbeitende Peer-Session) |

Details je Runde: siehe Handover, Abschnitt "Fortschritt".

## Warteschlange

**Ursprüngliche Warteschlange ist mit Runde 27 (lsp.nvim) abgeschlossen.** Ab da läuft ein
Re-Audit aller 27 Runden gegen die 100%-Vorgabe (Nutzer-Entscheidung 2026-09-18): audit-first,
ältestes Repo zuerst, gezielt auf die wiederkehrenden Bug-Familien plus Byte-Offsets, keine
Auffüllung wo schon solide. Reihenfolge: 1-5 durch, 6-11 laufen, danach 12 (insights.nvim) usw.

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
| cascade.nvim | 48 | 18 | ✅ fertig |
| sandbox.nvim | 270 | 19 | ✅ fertig |
| data.nvim | 16 | 20 | ✅ fertig |
| spotlight.nvim | 27 | 19 | ✅ fertig |
| mdview.nvim | 78 | 24 | ✅ fertig |
| filetree.nvim | 129 | 26 | ✅ fertig |
| lsp.nvim | 176 | 29 | ✅ fertig |
| images.nvim | 37 | 33 | ✅ fertig (gezielter Check) |
| ai.nvim | 25 | 18 | ✅ fertig (gezielter Check) |
| hover.nvim | 40 | 26 | ✅ fertig (gezielter Check) |
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
| insights.nvim | `symbols/ts_lua.lua` + `symbols/ts_lua_tables.lua`: `field("left")`/`field("right")`/`field("variable_list")` existieren in tree-sitter-lua nicht → toter Code (Assignment-Branch nie erreicht, verschachtelte Table-Felder ohne Präfix) | `dcbe57a` |
| insights.nvim | `tree/init.lua` escapte Windows-Exclude-Globs Lua-Stil, landeten aber als .NET-Regex → `*/.git/*` matchte nie | `dcbe57a` |
| sessions.nvim | `core.lua`s `save()`/`save_tab()` riefen `mkdir` ungeschützt → rohes `E739`, auch aus dem `VimLeavePre`-Autosave | `9005c46` |
| sessions.nvim | `layout.lua`s `restore()` ließ `{}`/`[]` durch → `build()` starb an einer nil-Kinderliste statt "corrupt layout file" zu melden | `9005c46` |
| emojis.nvim | der Visual-Zweig las die Marken der *vorherigen* Selektion → erste Selektion brach ab, jede weitere schaltete fremde Zeilen um | `7583459` |
| emojis.nvim | `frecency.save()`s ungeschütztes `mkdir` riss jede Emoji-Einfügung mit | `7583459` |
| emojis.nvim | `health.check()` rief nach dem "lib.nvim fehlt"-Error unbedingt in lib.nvim hinein | `dd6a0fb` |
| color_my_ascii.nvim | `ensure-blank-lines` fügte Leerzeilen **in** den Block ein und zerstörte die ASCII-Art; zudem nicht idempotent | `0437fe0` |
| color_my_ascii.nvim | `unique_words`-Lookup war hash-order-abhängig (8 Wörter in zwei Sprachen) → Sprach-Erkennung nicht entschieden | `0437fe0` |
| lib.nvim | `net/curl`s `is_secret_header` kannte GitLabs `PRIVATE-TOKEN` nicht → jeder authentifizierte GitLab-Request schrieb sein Token in die curl-Kommandozeile, lesbar für jeden anderen Prozess | `5c6b1ac` |
| diff.nvim | `health.lua`s "lib.nvim fehlt"-Zweig rief danach unbedingt in lib.nvim hinein | `7f5f2dd` |
| gopath.nvim | `health.lua`s "lib.nvim fehlt"-Zweig rief danach unbedingt in lib.nvim hinein | `1cc43e1` |
| fileops.nvim | die Delete-Taste rief `delete_fn({})` ohne Optionen → löschte trotz `delete.mode = "trash"` permanent und ohne Undo, und rief `on_before_delete` nie | `e7185fc` |
| fileops.nvim | `ops/cycle.lua` + `ops/bulk.lua`: `/`-Join vs. `\`-Buffername verglichen nie gleich → Navigation als No-op, Phantom-Buffer nach Rename. Nur der **Vergleich** normalisiert jetzt, nicht die gespeicherten Pfade | `81e15ee` |
| fileops.nvim | `delete_path` nahm Verzeichnisse an, die `uv.fs_unlink` nie löschen kann → `EPERM`-Retry-Budget verbrannt, danach Virenscanner beschuldigt | `81e15ee` |
| fileops.nvim | `conflict_marks` leakte pro `:e` drei unlöschbare Matches | `ffc1c9a` |
| cascade.nvim | `lists/move.lua`: `renumber.tree` verankerte den Basiswert an der Zeile, die *nach* dem Move zufällig erste ist → `1. 2. 3. 4.` driftete bei jedem Move um +1 | `c23ea33` |
| cascade.nvim | `lists.cycle`-Default konnte nicht rundlaufen: `lists.types` kannte nur zwei der vier vom Cycle erzeugten Markerarten → `a)`-Zeile verlor jede Listen-Erkennung | `c23ea33` |
| filetree.nvim | `health.lua`s "lib.nvim fehlt"-Zweig rief danach unbedingt in lib.nvim hinein | `811bfed` |
| cmdlog.nvim | `health.lua`s letzte Zeile rief unbedingt in `lib.nvim.bindings.usercmd.composer` hinein, bei fehlendem lib.nvim crashte `:checkhealth cmdlog` direkt nach der eigenen Fehlanzeige | `df6f716` |
| debugging.nvim | `health.lua`s letzter Abschnitt rief den Composer ungeschützt auf, obwohl derselbe Check ihn Zeilen darüber schon als potenziell fehlend meldet | `5bdd781` |
| open.nvim | `health.lua`s letzte Zeile rief den Composer ungeschützt auf, obwohl derselbe Check ihn Zeilen darüber schon als fehlend meldet | `553a445` |
| sessions.nvim | `health.lua`s abschließender `composer.checkhealth()`-Aufruf lief unbedingt, obwohl der Preflight drei Zeilen darüber schon weiß, ob der `require` scheitert → crashte mit "loop or previous error loading module" statt zu degradieren | `12a4fb6` |
| reposcope.nvim | `repository_fetcher.lua`s `vim.json.decode("null")`-Crash in zwei von drei Fetchern (truthy `vim.NIL` statt Tabellen-Check) | `3c82ff3` |
| insights.nvim | `symbols/parser.lua`s Doppelpunkt-Scan fraß den Laufwerksbuchstaben, `ts_lua.lua`/`ts_lua_tables.lua`s `field("left")`/`field("right")` existierten nie, `tree/init.lua`s Glob→Regex-Escaping nutzte `%` statt `\` | `6031069`, `dcbe57a` |
| insights.nvim | `health.lua`s abschließender Composer-Aufruf lief ungeschützt trotz vorheriger "fehlt"-Meldung; `ui/fzf.lua`s Default-Action und `ts_lua*.lua`s `scan_cwd()`-Ignore-Liste teilten denselben Windows-Laufwerksbuchstaben- bzw. Backslash-Blindpunkt wie die drei oben genannten Bugs, an drei weiteren Stellen | `6bbab32` |
| data.nvim | `register.write()` behandelte `setreg`s Ausbleiben eines Wurfs als Beweis für einen erfolgreichen Schreibvorgang, aber `setreg("+"/"*", ...)` wirft nie bei fehlendem Clipboard-Provider — tut einfach nichts | `9937f5c` |
| color_my_ascii.nvim | `health.lua`s `checkhealth` meldete "lib.nvim not found" und requirte dann am Ende ungeschützt erneut genau dasselbe fehlende Modul für die Report-Übergabe → riss direkt nach der Warnung ab | `22b9115` |
| mdview.nvim | `health.lua`s `M.check()` degradiert korrekt, ruft am Ende aber ungeschützt erneut in `lib.nvim.bindings.usercmd.composer.checkhealth` hinein → crasht bei altem/unvollständigem lib.nvim, verschluckt jeden vorherigen ok/warn/error | `59c4a6e` |
| fileops.nvim | `bindings/keymaps.lua`s `delete_fn({})` löschte permanent ohne Undo trotz `"trash"`-Default; drei Windows-Trenner-Mismatches (`ops/cycle.lua`s No-op-Navigation, `ops/bulk.lua`s Phantom-Buffer, `ops/file.lua`s Verzeichnis-Unlink-Retry); `conflict_marks.lua`s Match-Leak bei erneutem `:edit` | `e7185fc`, `81e15ee`, `ffc1c9a` |
| fileops.nvim | `health.lua`s abschließender Composer-Aufruf lief ungeschützt trotz vorheriger "fehlt"-Meldung; `on_hold.lua`s Git-Show-Preview löste den Pfad nie korrekt auf (hat noch nie gerendert) und `truncate()` schnitt Byte- statt zeichengenau | `037d3bb` |
| github_stats.nvim | `export.lua`s `create_pdf()` verschluckte den Fehler von `ensure_parent_dir()` — derselbe Bug, den ein früherer Fix nur bei `write_lines()` behoben hatte, am analogen zweiten Call-Site übersehen | `680adb8` |
| debugging.nvim | `health.lua` requirte `lib.nvim.health` auf Modulebene ungeschützt — ein fehlendes lib.nvim hätte das Modul selbst crashen lassen, noch vor dem bereits gefixten Guard am Funktionsende | `50afa0b` |
| insights.nvim | `M.foo = function()` wurde unter dem bloßen Feldnamen statt der vollen dotted-Name gemeldet; Mehrfachzuweisungen prüften nur den ersten Wert; Windows-Regex-Escape-Menge für `tree/init.lua` deckte `{`/`}`/`\|`/`\` nicht ab; dabei zusätzlich ein Test-Isolations-Leak in `compress_tree_spec.lua` gefunden (`pairs(saved)` überspringt in Lua als `nil` gespeicherte Einträge) | `9c6be5e`, `27744f7` |
| cascade.nvim | `roman` vor `ascii` (nötig für den Cycle-Ring) ließ `marker.parse` sieben Buchstaben (c/d/i/l/m/v/x) fälschlich als römisch lesen → normale `a) b) c) d)`-Listen korrumpierten ab dem dritten Punkt bei jedem Renumber. Gefixt (auf Nutzerwunsch, vorher gepinnt): `renumber.tree` merkt sich jetzt die pro Einzugsbreite bereits etablierte Marker-Art und reicht sie als Tie-Breaker an `marker.parse` zurück, ohne den globalen Cycle-Ring-Fall zu berühren | `0865850` |
| images.nvim | `compare.lua`s `M.open` rief `require("ui.kit").compare(...)` ungeschützt auf, anders als jeder andere ui.kit-Pfad im Plugin, die alle sauber degradieren → `:Image compare` crashte roh statt wie dokumentiert auf `vim.ui.select` zurückzufallen | `bdc1b11` |

### Offen (gepinnt)

Stand: **34 offen**. Der komplette Re-Audit (Runden 1-26, gegen die 100%-Vorgabe vom
2026-09-18) sowie ein separater Bug/Security/Performance-Review der Kampagne selbst sind
beide fertig -- siehe Handover für Details. Der einzige zwischenzeitlich gepinnte
"schwerwiegende" Fund (cascade.nvim, `roman`-vor-`ascii`-Kollision) wurde auf Nutzerwunsch
noch gefixt statt gepinnt zu bleiben; die Zahl oben zählt ihn deshalb nicht mehr mit.

| Repo | Datei | Bug |
|---|---|---|
| buffer-ctx.nvim | `format/column_align.lua` | zielt mit einem Byte-Offset auf eine Display-Spalte → Mehrbyte-Zeichen vor der Selektion verschiebt die Ausrichtung |
| buffer-ctx.nvim | `mark/init.lua` | Cleanup-Autocmd über String-Augroup ohne `clear = true` → zweites `setup()` verdoppelt ihn (harmlos, da idempotent) |
| pickers.nvim | `health.lua` | letzte Zeile ruft den Composer bedingungslos außerhalb jedes `pcall` → crasht `:checkhealth pickers` komplett bei fehlendem lib.nvim |
| pickers.nvim | `smart/frecency.lua` | `M.patch()` löst die Augroup ohne `clear=true` auf → zweites `setup()` mit Frecency verdoppelt den Autocmd |
| casedesk.nvim | `health.lua` | `check_tools()`s "lib.nvim fehlt"-Zweig ruft danach ungeschützt in `casedesk.export.find_browser()` hinein, das wiederum ungeschützt genau die als fehlend gemeldete Dependency requirt → `:checkhealth casedesk` crasht komplett |
| open.nvim | `context.lua` | `gather()`s Visual-Signal-Guard (`mode()`-Check + `'<`/`'>`-Marks) kann nie zusammen zutreffen, da die Marks erst beim Verlassen von Visual committet werden → `signals.visual` ist auf dem `:Open`-Pfad immer `nil`, sonst ein Überbleibsel einer fremden Selektion |
| language.nvim | `health.lua` | `M.check()` ruft nach `check_lib()`s korrekter "Composer fehlt"-Warnung noch dreimal ungeschützt in genau dieses Modul hinein → `:checkhealth language` crasht komplett, jede Sektion danach fällt weg |
| replacer.nvim | `health.lua` | `M.check()` requirt den Composer für den Preflight erneut ungeschützt, obwohl `check_lib_nvim()` ihn Zeilen darüber schon korrekt als fehlend meldet und degradiert |
| github_stats.nvim | `dashboard/render.lua` | `fit_width()` polstert/kürzt nach Byte-Länge statt Display-Breite; unsichtbar bei ASCII-Zeiträumen, bricht lautlos bei einem Mehrbyte-`time_range`-Config-Wert |

| Repo | Datei | Bug |
|---|---|---|
| pdfport.nvim | `backends/tesseract.lua` | `finish_error()` zählt die gescheiterte Seite mit |
| pdfport.nvim | `bindings/autocmds.lua` | nicht idempotent trotz gegenteiliger Doku → zweites `setup()` hinterlässt zwei `BufReadCmd`-Autocmds |
| pdfport.nvim | `integrations/{fzf,telescope}.lua` | cachen Fehlschläge → eine gescheiterte Extraktion wird die ganze Session wiedergespielt |
| reposcope.nvim | `clone_manager.lua` | `not isdirectory(path)` ist immer `false` (0 ist truthy) → Pfad-Guard und `safe_mkdir` beide toter Code |
| reposcope.nvim | `bindings/keymaps.lua` | `unset_prompt_keymaps()` räumt per falschem Tag auf → `_registry` wächst pro Open/Close-Zyklus |
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
| gopath.nvim | `create.lua` | der "lib.nvim fehlt"-Fallback requirt ungeschützt genau diese Dependency (letzter offener Punkt dieser Familie außerhalb von `health.lua`-Dateien) |
| gopath.nvim | `resolvers/go/import_path.lua` | `parse_import` ist als einziger von acht Sprach-Resolvern nicht am eigenen Import-Keyword verankert → feuert auf jeden `"..."`-String-Literal mit `/`, der wie ein Package aussieht |
| diff.nvim | `core/directory.lua` | ungeschütztes `readfile` → rohes `E484` an `on_done` vorbei, Aufrufer wartet ewig |
| diff.nvim | `core/scratch.lua` | `track()` dedupliziert nicht → `status()` kann `diff:3` melden |
| cascade.nvim | `bindings/autocmds.lua` | zwei der drei Augroups werden nur geleert, wenn ihr Feature-Gate durchkommt → deaktiviertes Feature hinterlässt lebende Handler bis zum Neustart |
| cascade.nvim | `facade`-Kommandos | `cycle_group_add`/`remove` mutieren `config.DEFAULTS` direkt (Deep-Merge kopiert nur die oberste Ebene) |
| cascade.nvim | `usrcmds.lua` | `:Cascade indent N`/`dedent N` ignorieren `N` (falscher Wert an `run_indent_command` gereicht); `cycle remove` schneidet mehrwortige Werte am ersten Leerzeichen ab |
| cascade.nvim | `lists/renumber.lua` | `renumber.tree` über eine explizite Range mit mehr als einem Listen-Block (`:Cascade renumber`) setzt den zweiten Block vom `base_start` des ersten fort statt vom eigenen |

**Wiederkehrende Familien:**
- Windows-Pfadbehandlung; ungeschützte Dateisystem-Aufrufe, deren `E739`/`E482` am eigenen
  Fehlerpfad vorbeifliegt; Caches, die Fehlschläge memoisieren; Byte-vs-Zeichen-Offsets.
- **"Dependency fehlt, ruft sie danach trotzdem auf"** — ein Health-Check (oder ein
  ähnlicher Preflight) meldet eine fehlende Dependency korrekt und ruft am Ende der
  Funktion trotzdem ungeschützt in sie hinein. Gefunden in 17 Repos, **12 gefixt**
  (emojis, diff, gopath (in `health.lua`), filetree, cmdlog, debugging, open, sessions,
  insights, fileops, color_my_ascii, mdview), **5 offen**: `gopath.nvim`s
  `create.lua`-Fallback (kein `health.lua`, gleiches Muster), `pickers.nvim`s `health.lua`,
  `casedesk.nvim`s `health.lua`, `language.nvim`s `health.lua` (drei statt einem
  ungeschützten Aufruf) und `replacer.nvim`s `health.lua` (alle vier in Re-Audit-Runden
  gefunden).
- **Augroup ohne `clear=true` akkumuliert bei zweitem `setup()`** — eine gemeinsame
  Augroup wird per Namen aufgelöst statt eine id zu übergeben, sodass ein erneutes
  `setup()` einen zweiten Autocmd-Handler registriert statt den ersten zu ersetzen.
  Gefunden in 4 Repos, **1 gefixt** (pdfport.nvim), **3 offen**: `buffer-ctx.nvim`
  (`mark/init.lua`, harmlos da idempotent), `pickers.nvim` (`smart/frecency.lua`, nicht
  harmlos — verdoppelt Buffer-Read-Zählung), `cascade.nvim` (`bindings/autocmds.lua`,
  Variante: Gate *vor* der Augroup-Auflösung statt fehlendes `clear`).

## Historie: der ursprüngliche 3-Repo-Report

Die erste Fassung dieses Reports (2026-09-15) deckte nur `pickers.nvim`, `dap.nvim` und
`cmdlog.nvim` ab und schätzte deren Aufwand auf 24–39 Stunden. Alle drei sind inzwischen
abgeschlossen (Runden 1–3); der Aufwandsschätzer hat sich als grob passend erwiesen, die
Reihenfolge-Empfehlung (pickers → dap → cmdlog) wurde zu pickers → cmdlog → dap umsortiert,
weil cmdlogs Harness bereits existierte und nur ausgebaut werden musste.
