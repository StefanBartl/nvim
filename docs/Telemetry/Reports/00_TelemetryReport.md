# Telemetry-Auswertung — eine Woche, 2026-08-05 bis 2026-08-12

Quelle: `runtime-analysis.telemetry`, `profile_args=true`, `deep=true` (Standardpolicy aus `config/telemetry.lua`).

Pro Funktion: Aufrufe gesamt, davon die häufigsten Argument-Muster (Anzahl, Anteil, das Muster selbst — Werte sind bereits vom Plugin selbst als kompakte Signaturen aufgezeichnet, keine vollen Objekte).

## Table of content

  - [Zusammenfassung](#zusammenfassung)
    - [Die größten Ausreißer](#die-grten-ausreier)
    - [Klare Memoisierungs-Kandidaten (>90 % identisches Argument)](#klare-memoisierungs-kandidaten-90-identisches-argument)
    - [Ohne Daten](#ohne-daten)
    - [Zwei Vorbehalte, die du kennen solltest](#zwei-vorbehalte-die-du-kennen-solltest)
  - [lib.nvim](#libnvim)
  - [sessions.nvim](#sessionsnvim)
  - [pickers.nvim](#pickersnvim)
  - [buffer-ctx.nvim](#buffer-ctxnvim)
  - [open.nvim](#opennvim)
  - [sandbox.nvim](#sandboxnvim)
  - [spotlight.nvim](#spotlightnvim)
  - [documentation.nvim](#documentationnvim)
  - [fileops.nvim](#fileopsnvim)
  - [gopath.nvim](#gopathnvim)
  - [insights.nvim](#insightsnvim)
  - [filetree.nvim](#filetreenvim)
  - [reposcope.nvim](#reposcopenvim)
  - [debugging.nvim](#debuggingnvim)
  - [language.nvim](#languagenvim)
  - [cmdlog.nvim](#cmdlognvim)
  - [github_stats.nvim](#github_statsnvim)
  - [cascade.nvim](#cascadenvim)
  - [markdown.nvim](#markdownnvim)
  - [color_my_ascii.nvim](#color_my_asciinvim)
  - [images.nvim](#imagesnvim)
  - [Ohne Daten](#ohne-daten-1)

---

## Zusammenfassung

---

### Die größten Ausreißer

| Plugin | Funktion | Aufrufe/Woche | Anteil |
|---|---|---|---|
| **color_my_ascii.nvim** | `config.get_char_highlight` | **10.360.251** | 50 % |
| **markdown.nvim** | `hl_options.hl_groups.blockquote.highlight_line` | 3.301.952 | 86 % |
| documentation.nvim | `core.json.encode` | 1.600.564 | 79 % |

`color_my_ascii.nvim` ist mit Abstand der heißeste Pfad im ganzen Datensatz — über 10 Millionen Aufrufe einer einzigen Funktion in einer Woche, das ist fast sicher pro Zeile/Zeichen im Rendering. Bei `markdown.nvim` macht eine Highlight-Funktion 86 % aller Aufrufe des ganzen Plugins aus.

---

### Klare Memoisierungs-Kandidaten (>90 % identisches Argument)

- `filetree.nvim` — `feature("cwd_mode")`: 179.462× davon 100 % derselbe Aufruf
- `fileops.nvim` — `ops.file.ensure_parent`: 6.008× davon 98 % derselbe Pfad
- `gopath.nvim` — `util.path.invalidate_caches`: 6.008× immer mit denselben (leeren) Argumenten
- `github_stats.nvim` — `config.get_storage_root`: 6.545× immer identisch

Bei diesen lohnt sich ein Cache am ehesten — die Funktion tut praktisch immer dasselbe.

---

### Ohne Daten

**Keine Telemetrie-Datei** (nie geladen oder diese Woche nie aktiv): `replacer.nvim`, `diff.nvim`, `migrate.nvim`, `emojis.nvim`

**Datei da, aber 0 Funktionsaufrufe** (lief, aber nichts Instrumentiertes wurde benutzt): `runtime-analysis.nvim`, `dap.nvim`, `pdfport.nvim`, `recommender.nvim`, `mdview.nvim`

---

### Zwei Vorbehalte, die du kennen solltest

1. **`documentation.nvim`s und `runtime-analysis.nvim`s eigene Zahlen sind durch diese Sitzung verzerrt** — ich habe heute sehr viele `nvim --headless`-Läufe für Tests und Kartengenerierung gegen genau diese beiden Repos gefahren, und das zählt in dieselbe Telemetrie mit rein. Für die anderen ~25 Plugins ist das kein Problem.
2. **Echter Bug gefunden, nicht von mir verursacht**: in `documentation.nvim`s Telemetriedatei steckt ein ungültiges UTF-8-Fragment mitten in einem aufgezeichneten Argument-String — die Kürzungslogik für lange Argumente schneidet offenbar auf Byte-Ebene statt auf Zeichengrenzen und kann so ein Mehrbyte-Zeichen mittendurch trennen. Betrifft nur die Lesbarkeit einzelner Argument-Snippets, nicht die Zählungen. Wenn gewünscht, kann das in `runtime-analysis.telemetry`s Fingerprint-Kürzung behoben werden — sag Bescheid.

---

## lib.nvim

Sessions: 233 · Tage mit Daten: 8 (2026-08-05..2026-08-12) · Funktionen instrumentiert: 33 · Aufrufe gesamt: 151582

**Module, nach Gesamtaufrufen ihrer Funktionen:**

- `lazy` — 44452 (29%)
- `autocmd` — 32122 (21%)
- `notify` — 27476 (18%)
- `usercmd` — 26044 (17%)
- `composer` — 15828 (10%)
- `hl` — 2228 (1%)

**Top-Funktionen:**

- **`notify.create`** — 27476 Aufrufe
  - (keine Argument-Daten aufgezeichnet)
- **`usercmd.create`** — 26044 Aufrufe
  - (keine Argument-Daten aufgezeichnet)
- **`autocmd.create`** — 25442 Aufrufe
  - (keine Argument-Daten aufgezeichnet)
- **`lazy.require`** — 22226 Aufrufe
  - (keine Argument-Daten aufgezeichnet)
- **`lazy.module`** — 22226 Aufrufe
  - (keine Argument-Daten aufgezeichnet)
- **`composer.verb`** — 11940 Aufrufe
  - (keine Argument-Daten aufgezeichnet)
- **`autocmd.group`** — 3920 Aufrufe
  - (keine Argument-Daten aufgezeichnet)
- **`composer.register_type`** — 3887 Aufrufe
  - (keine Argument-Daten aufgezeichnet)

---

## sessions.nvim

Sessions: 171 · Tage mit Daten: 7 (2026-08-05..2026-08-12) · Funktionen instrumentiert: 77 · Aufrufe gesamt: 1818674

**Module, nach Gesamtaufrufen ihrer Funktionen:**

- `documentation.core.json` — 1432913 (79%)
- `documentation.core.docs` — 224184 (12%)
- `documentation.core.check` — 29626 (2%)
- `documentation.core.doccoverage` — 26530 (1%)
- `documentation.core.scan` — 23769 (1%)
- `documentation.core.lang.lua` — 15153 (1%)

**Top-Funktionen:**

- **`core.json.encode`** — 1432913 Aufrufe
  - (keine Argument-Daten aufgezeichnet)
- **`core.docs.resolve`** — 102242 Aufrufe
  - (keine Argument-Daten aufgezeichnet)
- **`core.docs.missing_member`** — 100387 Aufrufe
  - (keine Argument-Daten aufgezeichnet)
- **`core.check.declared_param_names`** — 26462 Aufrufe
  - (keine Argument-Daten aufgezeichnet)
- **`core.docs.bare_name`** — 19844 Aufrufe
  - (keine Argument-Daten aufgezeichnet)
- **`core.scan.split_summary`** — 18793 Aufrufe
  - (keine Argument-Daten aufgezeichnet)
- **`core.doccoverage.is_documented`** — 15538 Aufrufe
  - (keine Argument-Daten aufgezeichnet)
- **`core.mark_dirty`** — 12260 Aufrufe
  - 12260x (100%) ()

---

## pickers.nvim

Sessions: 252 · Tage mit Daten: 8 (2026-08-05..2026-08-12) · Funktionen instrumentiert: 13 · Aufrufe gesamt: 1532

**Module, nach Gesamtaufrufen ihrer Funktionen:**

- `pickers.config` — 869 (57%)
- `pickers.history` — 400 (26%)
- `pickers.keys` — 256 (17%)
- `pickers.entry_actions.adapters.snacks` — 3 (0%)
- `pickers.builtins` — 2 (0%)
- `pickers.keys.adapters.snacks` — 2 (0%)

**Top-Funktionen:**

- **`config.get`** — 867 Aufrufe
  - 867x (100%) ()
- **`keys.resolve`** — 253 Aufrufe
  - 250x (99%) ()
  - 2x (1%) (nil)
  - 1x (0%) (<table:map>)
- **`history.dir`** — 200 Aufrufe
  - 200x (100%) (<table:map>)
- **`history.fzf_opts`** — 100 Aufrufe
  - 100x (100%) (<table:map>)
- **`history.telescope_opts`** — 100 Aufrufe
  - 100x (100%) (<table:map>)
- **`keys.snacks_win`** — 2 Aufrufe
  - 2x (100%) ()
- **`builtins.run`** — 2 Aufrufe
  - 2x (100%) ("undo", nil, "snacks")
- **`keys.adapters.snacks.win`** — 2 Aufrufe
  - 2x (100%) (<table:map>)

---

## buffer-ctx.nvim

Sessions: 14 · Tage mit Daten: 7 (2026-08-05..2026-08-12) · Funktionen instrumentiert: 9 · Aufrufe gesamt: 150

**Module, nach Gesamtaufrufen ihrer Funktionen:**

- `buffer_ctx.ops.filepath` — 72 (48%)
- `buffer_ctx.util.notify` — 26 (17%)
- `buffer_ctx.commands` — 24 (16%)
- `buffer_ctx.util.clip` — 24 (16%)
- `buffer_ctx.mark` — 4 (3%)

**Top-Funktionen:**

- **`commands._dispatch`** — 24 Aufrufe
  - 18x (75%) ("filepath", <table:#1>, "clip")
  - 6x (25%) ("filepath", <table:#1>, "clip", nil)
- **`ops.filepath._format_segments`** — 24 Aufrufe
  - 14x (58%) (<table:#10>, "unix")
  - 4x (17%) (<table:#11>, "unix")
  - 3x (12%) (<table:#5>, "unix")
- **`ops.filepath.get_path`** — 24 Aufrufe
  - 24x (100%) (<table:map>)
- **`util.clip.copy`** — 24 Aufrufe
  - 16x (67%) ("C:/Users/bartl/AppData/Local/nvim/docs/R"…)
  - 2x (8%) ("E:/repos/documentation.nvim/docs/FEATURE"…)
  - 2x (8%) ("C:/Users/bartl/AppData/Local/nvim/lua/pl"…)
- **`ops.filepath.parse_args`** — 24 Aufrufe
  - 24x (100%) (<table:#1>)
- **`util.notify.info`** — 24 Aufrufe
  - 19x (79%) ("copied: C:/Users/bartl/AppData/Local/nvi"…)
  - 2x (8%) ("copied: E:/repos/documentation.nvim/docs"…)
  - 1x (4%) ("copied: E:/repos/runtime-analysis.nvim/d"…)
- **`mark.toggle`** — 2 Aufrufe
  - 2x (100%) (32)
- **`mark.yank`** — 2 Aufrufe
  - 2x (100%) ()

---

## open.nvim

Sessions: 3 · Tage mit Daten: 1 (2026-08-07..2026-08-07) · Funktionen instrumentiert: 4 · Aufrufe gesamt: 14

**Module, nach Gesamtaufrufen ihrer Funktionen:**

- `open.config` — 10 (71%)
- `open.registry` — 4 (29%)

**Top-Funktionen:**

- **`config.is_debug`** — 6 Aufrufe
  - 6x (100%) ()
- **`config.get`** — 4 Aufrufe
  - 4x (100%) ()
- **`registry.dispatch`** — 2 Aufrufe
  - 2x (100%) ("filemanager", <table:map>)
- **`registry.get`** — 2 Aufrufe
  - 2x (100%) ("filemanager")

---

## sandbox.nvim

Sessions: 72 · Tage mit Daten: 8 (2026-08-05..2026-08-12) · Funktionen instrumentiert: 1 · Aufrufe gesamt: 56

**Module, nach Gesamtaufrufen ihrer Funktionen:**

- `sandbox.logger` — 56 (100%)

**Top-Funktionen:**

- **`logger.flush`** — 56 Aufrufe
  - 56x (100%) ()

---

## spotlight.nvim

Sessions: 72 · Tage mit Daten: 8 (2026-08-05..2026-08-12) · Funktionen instrumentiert: 14 · Aufrufe gesamt: 81914

**Module, nach Gesamtaufrufen ihrer Funktionen:**

- `spotlight.core.registry` — 59182 (72%)
- `spotlight.core.match` — 22208 (27%)
- `spotlight.config` — 232 (0%)
- `spotlight.util.lib` — 144 (0%)
- `spotlight.persist` — 112 (0%)
- `spotlight.core.palette` — 36 (0%)

**Top-Funktionen:**

- **`core.registry.apply_to_window`** — 52187 Aufrufe
  - 4516x (9%) (1000)
  - 546x (1%) (1002)
  - 319x (1%) (1004)
  - +42965 (82%) weitere, seltenere Muster (nicht einzeln mitgezählt — Obergrenze pro Funktion, damit ein Aufruf mit x-beliebigen Argumenten nicht unbegrenzt Speicher kostet)
- **`core.match.forget_window`** — 16266 Aufrufe
  - 57x (0%) (1002)
  - 57x (0%) (1003)
  - 56x (0%) (1005)
  - +15048 (93%) weitere, seltenere Muster (nicht einzeln mitgezählt — Obergrenze pro Funktion, damit ein Aufruf mit x-beliebigen Argumenten nicht unbegrenzt Speicher kostet)
- **`core.registry.all`** — 5942 Aufrufe
  - 5942x (100%) ()
- **`core.match.reconcile_window`** — 5942 Aufrufe
  - 528x (9%) (1000, <table:empty>)
  - 224x (4%) (1047, <table:empty>)
  - 20x (0%) (1050, <table:empty>)
  - +4894 (82%) weitere, seltenere Muster (nicht einzeln mitgezählt — Obergrenze pro Funktion, damit ein Aufruf mit x-beliebigen Argumenten nicht unbegrenzt Speicher kostet)
- **`core.registry.remove_for_buffer`** — 997 Aufrufe
  - 4x (0%) (1)
  - 3x (0%) (2)
  - 3x (0%) (15)
  - +936 (94%) weitere, seltenere Muster (nicht einzeln mitgezählt — Obergrenze pro Funktion, damit ein Aufruf mit x-beliebigen Argumenten nicht unbegrenzt Speicher kostet)
- **`config.get`** — 232 Aufrufe
  - 112x (48%) ("persist.enable")
  - 56x (24%) ("persist.default")
  - 56x (24%) ("debug")
- **`util.lib.debug`** — 56 Aufrufe
  - 56x (100%) ("persist: snapshot filtered", <table:map>)
- **`persist.save_now`** — 56 Aufrufe
  - 56x (100%) ()

---

## documentation.nvim

Sessions: 34 · Tage mit Daten: 4 (2026-08-05..2026-08-12) · Funktionen instrumentiert: 107 · Aufrufe gesamt: 2016944

**Module, nach Gesamtaufrufen ihrer Funktionen:**

- `documentation.core.json` — 1600564 (79%)
- `documentation.core.docs` — 255860 (13%)
- `documentation.core.check` — 32883 (2%)
- `documentation.core.doccoverage` — 28459 (1%)
- `documentation.core.scan` — 25484 (1%)
- `documentation.core.lang.lua` — 16006 (1%)

**Top-Funktionen:**

- **`core.json.encode`** — 1600564 Aufrufe
  - 212149x (13%) (<table:map>)
  - 162787x (10%) (<table:empty>)
  - 81609x (5%) (false)
  - +1038787 (65%) weitere, seltenere Muster (nicht einzeln mitgezählt — Obergrenze pro Funktion, damit ein Aufruf mit x-beliebigen Argumenten nicht unbegrenzt Speicher kostet)
- **`core.docs.resolve`** — 117044 Aufrufe
  - 298x (0%) (<table:map>, "setup()", nil)
  - 159x (0%) (<table:map>, "--check", nil)
  - 97x (0%) (<table:map>, "lib.nvim", nil)
  - +116011 (99%) weitere, seltenere Muster (nicht einzeln mitgezählt — Obergrenze pro Funktion, damit ein Aufruf mit x-beliebigen Argumenten nicht unbegrenzt Speicher kostet)
- **`core.docs.missing_member`** — 115012 Aufrufe
  - 298x (0%) (<table:map>, "setup()")
  - 159x (0%) (<table:map>, "--check")
  - 97x (0%) (<table:map>, "lib.nvim")
  - +113982 (99%) weitere, seltenere Muster (nicht einzeln mitgezählt — Obergrenze pro Funktion, damit ein Aufruf mit x-beliebigen Argumenten nicht unbegrenzt Speicher kostet)
- **`core.check.declared_param_names`** — 29453 Aufrufe
  - 29453x (100%) (<table:map>)
- **`core.docs.bare_name`** — 21981 Aufrufe
  - 852x (4%) ("M.setup")
  - 96x (0%) ("M.run")
  - 42x (0%) ("M.render")
  - +20739 (94%) weitere, seltenere Muster (nicht einzeln mitgezählt — Obergrenze pro Funktion, damit ein Aufruf mit x-beliebigen Argumenten nicht unbegrenzt Speicher kostet)
- **`core.scan.split_summary`** — 20294 Aufrufe
  - 8029x (40%) ("")
  - 3x (0%) ("Render and write `module_map.json`/`inde"…)
  - 3x (0%) ("Write `content` to `path`, creating pare"…)
  - +12172 (60%) weitere, seltenere Muster (nicht einzeln mitgezählt — Obergrenze pro Funktion, damit ein Aufruf mit x-beliebigen Argumenten nicht unbegrenzt Speicher kostet)
- **`core.doccoverage.is_documented`** — 16610 Aufrufe
  - 16610x (100%) (<table:map>)
- **`core.doccoverage.params_documented`** — 11771 Aufrufe
  - 11771x (100%) (<table:map>)

---

## fileops.nvim

Sessions: 72 · Tage mit Daten: 8 (2026-08-05..2026-08-12) · Funktionen instrumentiert: 6 · Aufrufe gesamt: 6018

**Module, nach Gesamtaufrufen ihrer Funktionen:**

- `fileops.ops.file` — 6008 (100%)
- `fileops.ops.cycle` — 6 (0%)
- `fileops.config` — 2 (0%)
- `fileops.util.notify` — 2 (0%)

**Top-Funktionen:**

- **`ops.file.ensure_parent`** — 6008 Aufrufe
  - 5893x (98%) ("C:/Users/bartl/AppData/Local/nvim/docs/R"…)
  - 22x (0%) ("E:/repos/runtime-analysis.nvim/docs/ROAD"…)
  - 15x (0%) ("E:/repos/documentation.nvim/docs/ROADMAP"…)
  - +3 (0%) weitere, seltenere Muster (nicht einzeln mitgezählt — Obergrenze pro Funktion, damit ein Aufruf mit x-beliebigen Argumenten nicht unbegrenzt Speicher kostet)
- **`config.get`** — 2 Aufrufe
  - 2x (100%) ()
- **`util.notify.report`** — 2 Aufrufe
  - 2x (100%) (true, nil)
- **`ops.cycle.navigate`** — 2 Aufrufe
  - 1x (50%) ("C:\\Users\\bartl\\AppData\\Local\\nvim\\docs\\R"…, "nex...
  - 1x (50%) ("C:\\Users\\bartl/AppData/Local/nvim/docs/R"…, "next", <...
- **`ops.cycle.open_path`** — 2 Aufrufe
  - 2x (100%) ("C:\\Users\\bartl\\AppData\\Local\\nvim\\docs\\R"…, <tab...
- **`ops.cycle.get_root_dir`** — 2 Aufrufe
  - 2x (100%) (<table:map>)

---

## gopath.nvim

Sessions: 72 · Tage mit Daten: 8 (2026-08-05..2026-08-12) · Funktionen instrumentiert: 27 · Aufrufe gesamt: 11550

**Module, nach Gesamtaufrufen ihrer Funktionen:**

- `gopath.util.path` — 6348 (55%)
- `gopath.truncated.cache` — 2768 (24%)
- `gopath.config` — 1194 (10%)
- `gopath.util.log` — 585 (5%)
- `gopath.util.safe_notify` — 534 (5%)
- `gopath.util.cross` — 22 (0%)

**Top-Funktionen:**

- **`util.path.invalidate_caches`** — 6008 Aufrufe
  - 6008x (100%) ()
- **`config.get`** — 1194 Aufrufe
  - 1194x (100%) ()
- **`truncated.cache.needs_refresh`** — 1057 Aufrufe
  - 1057x (100%) (600)
- **`util.log.debug`** — 557 Aufrufe
  - 17x (3%) ("Cache built: 22871 files indexed")
  - 10x (2%) ("Cache built: 20601 files indexed")
  - 4x (1%) ("Cache built: 20016 files indexed")
  - +483 (87%) weitere, seltenere Muster (nicht einzeln mitgezählt — Obergrenze pro Funktion, damit ein Aufruf mit x-beliebigen Argumenten nicht unbegrenzt Speicher kostet)
- **`truncated.cache._save_to_disk`** — 554 Aufrufe
  - 554x (100%) ()
- **`truncated.cache._finalize_build`** — 554 Aufrufe
  - 554x (100%) (<function>)
- **`truncated.cache.build_async`** — 539 Aufrufe
  - 539x (100%) (<function>)
- **`util.safe_notify.safe_notify_defer`** — 534 Aufrufe
  - 388x (73%) ("[gopath] Building cache from 3 roots...", 2, nil, 50)
  - 146x (27%) ("[gopath] Building cache from 4 roots...", 2, nil, 50)

---

## insights.nvim

Sessions: 177 · Tage mit Daten: 8 (2026-08-05..2026-08-12) · Funktionen instrumentiert: 6 · Aufrufe gesamt: 25974

**Module, nach Gesamtaufrufen ihrer Funktionen:**

- `insights.util.notify` — 18873 (73%)
- `insights.config` — 6280 (24%)
- `insights.devserver` — 821 (3%)

**Top-Funktionen:**

- **`util.notify.create`** — 18873 Aufrufe
  - 119x (1%) ("[usrcmds.who_locks]")
  - 119x (1%) ("[lsp.formatter.conform]")
  - 119x (1%) ("[DiffPeek]")
  - +15735 (83%) weitere, seltenere Muster (nicht einzeln mitgezählt — Obergrenze pro Funktion, damit ein Aufruf mit x-beliebigen Argumenten nicht unbegrenzt Speicher kostet)
- **`config.get`** — 6280 Aufrufe
  - 6280x (100%) ()
- **`devserver.chan_cmd`** — 221 Aufrufe
  - 3x (1%) (35, 66)
  - 3x (1%) (104, 150)
  - 3x (1%) (178, 177)
  - +125 (57%) weitere, seltenere Muster (nicht einzeln mitgezählt — Obergrenze pro Funktion, damit ein Aufruf mit x-beliebigen Argumenten nicht unbegrenzt Speicher kostet)
- **`devserver.consider`** — 221 Aufrufe
  - 6x (3%) (108, "C:\\Users\\bartl\\scoop\\shims\\lazygit.EXE")
  - 6x (3%) (86, "C:\\Users\\bartl\\scoop\\shims\\lazygit.EXE")
  - 6x (3%) (398, "C:\\Users\\bartl\\scoop\\shims\\lazygit.EXE")
  - +114 (52%) weitere, seltenere Muster (nicht einzeln mitgezählt — Obergrenze pro Funktion, damit ein Aufruf mit x-beliebigen Argumenten nicht unbegrenzt Speicher kostet)
- **`devserver.match`** — 221 Aufrufe
  - 219x (99%) ("C:\\Users\\bartl\\scoop\\shims\\lazygit.EXE", <table:#10>)
  - 2x (1%) ("C:\\Program Files\\PowerShell\\7\\pwsh.exe", <table:#10>)
- **`devserver.kill_all`** — 158 Aufrufe
  - 158x (100%) ()

---

## filetree.nvim

Sessions: 52 · Tage mit Daten: 5 (2026-08-08..2026-08-12) · Funktionen instrumentiert: 96 · Aufrufe gesamt: 597102

**Module, nach Gesamtaufrufen ihrer Funktionen:**

- `filetree.features.nav.cwd_mode` — 217337 (36%)
- `filetree` — 179484 (30%)
- `filetree.adapter.neotree` — 136107 (23%)
- `filetree.features` — 23617 (4%)
- `filetree.util.buffer` — 9444 (2%)
- `filetree.util.root` — 9116 (2%)

**Top-Funktionen:**

- **`feature`** — 179462 Aufrufe
  - 179334x (100%) ("cwd_mode")
  - 21x (0%) ("copy_move")
  - 21x (0%) ("open_variants")
- **`features.nav.cwd_mode.badge`** — 179334 Aufrufe
  - 179334x (100%) ()
- **`adapter.neotree.is_open`** — 52568 Aufrufe
  - 52568x (100%) ()
- **`adapter.neotree.get_winid`** — 33622 Aufrufe
  - 33622x (100%) ()
- **`features.nav.cwd_mode.refresh_indicator`** — 17254 Aufrufe
  - 17254x (100%) ()
- **`features.load`** — 11982 Aufrufe
  - 11633x (97%) ("cwd_mode")
  - 158x (1%) ("project_root")
  - 89x (1%) ("marks")
- **`features.require`** — 11635 Aufrufe
  - 11633x (100%) ("cwd_mode")
  - 2x (0%) ("project_root")
- **`features.nav.cwd_mode.resolve`** — 10250 Aufrufe
  - 5182x (51%) ("C:\\Users\\bartl\\AppData\\Local\\nvim\\docs\\R"…)
  - 327x (3%) ("C:\\Users\\bartl/AppData/Local/nvim/docs/R"…)
  - 246x (2%) ("C:\\Users\\bartl\\AppData\\Local\\nvim\\docs\\N"…)
  - +3795 (37%) weitere, seltenere Muster (nicht einzeln mitgezählt — Obergrenze pro Funktion, damit ein Aufruf mit x-beliebigen Argumenten nicht unbegrenzt Speicher kostet)

---

## reposcope.nvim

Sessions: 72 · Tage mit Daten: 6 (2026-08-05..2026-08-12) · Funktionen instrumentiert: 70 · Aufrufe gesamt: 300

**Module, nach Gesamtaufrufen ihrer Funktionen:**

- `reposcope.utils.debug` — 66 (22%)
- `reposcope.ui.actions.status_view` — 34 (11%)
- `reposcope.config` — 23 (8%)
- `reposcope.utils.checks` — 20 (7%)
- `reposcope.state.requests_state` — 19 (6%)
- `reposcope.controllers.provider_controller` — 17 (6%)

**Top-Funktionen:**

- **`utils.debug.is_dev_mode`** — 45 Aufrufe
  - 45x (100%) ()
- **`utils.debug.notify`** — 21 Aufrufe
  - 12x (57%) ("[reposcope] Reading status of 52 reposit"…, 2)
  - 3x (14%) ("[reposcope] No git repositories found in"…, 3)
  - 2x (10%) ("[reposcope] Reading status of 53 reposit"…, 2)
- **`config.get_option`** — 20 Aufrufe
  - 16x (80%) ("provider")
  - 2x (10%) ("logfile_path")
  - 2x (10%) ("sidebar_enabled")
- **`utils.checks.has_binary`** — 20 Aufrufe
  - 20x (100%) ("git")
- **`ui.actions.status_view.render`** — 17 Aufrufe
  - 12x (71%) (<table:#52>)
  - 2x (12%) (<table:#53>)
  - 1x (6%) (<table:#1>)
- **`ui.actions.status_view.show`** — 17 Aufrufe
  - 12x (71%) (<table:#52>, <table:empty>)
  - 2x (12%) (<table:#53>, <table:empty>)
  - 1x (6%) (<table:#1>, <table:empty>)
- **`utils.text.center_text`** — 10 Aufrufe
  - 3x (30%) ("", 65)
  - 1x (10%) ("A versatile plugin for exploring Git-bas"…, 65)
  - 1x (10%) ("This is an open-source project, develope"…, 65)
- **`controllers.provider_controller.get_active_provider`** — 10 Aufrufe
  - 10x (100%) ()

---

## debugging.nvim

Sessions: 72 · Tage mit Daten: 8 (2026-08-05..2026-08-12) · Funktionen instrumentiert: 9 · Aufrufe gesamt: 8669

**Module, nach Gesamtaufrufen ihrer Funktionen:**

- `debugging.views.display` — 6569 (76%)
- `debugging.views.utils` — 2100 (24%)

**Top-Funktionen:**

- **`views.display.get_window_tag`** — 6515 Aufrufe
  - 1511x (23%) (1000)
  - 69x (1%) (1027)
  - 48x (1%) (1003)
  - +4308 (66%) weitere, seltenere Muster (nicht einzeln mitgezählt — Obergrenze pro Funktion, damit ein Aufruf mit x-beliebigen Argumenten nicht unbegrenzt Speicher kostet)
- **`views.utils.is_target_view`** — 1939 Aufrufe
  - 10x (1%) (156)
  - 10x (1%) (135)
  - 9x (0%) (137)
  - +1757 (91%) weitere, seltenere Muster (nicht einzeln mitgezählt — Obergrenze pro Funktion, damit ein Aufruf mit x-beliebigen Argumenten nicht unbegrenzt Speicher kostet)
- **`views.utils.make_focusable`** — 62 Aufrufe
  - 10x (16%) (1006)
  - 9x (15%) (1014)
  - 8x (13%) (1187)
- **`views.utils.force_focus`** — 33 Aufrufe
  - 5x (15%) (1014)
  - 5x (15%) (1006)
  - 4x (12%) (1187)
- **`views.utils.ensure_bottom`** — 33 Aufrufe
  - 5x (15%) (1006, 3, 60)
  - 5x (15%) (1014, 3, 60)
  - 4x (12%) (1124, 3, 60)
- **`views.utils.focus_and_bottom`** — 33 Aufrufe
  - 5x (15%) (1006, 3, 60)
  - 5x (15%) (1014, 3, 60)
  - 4x (12%) (1124, 3, 60)
- **`views.display.execute_and_refresh`** — 25 Aufrufe
  - 24x (96%) ("noice_all", "Noice all", <table:map>)
  - 1x (4%) ("messages", "messages", <table:map>)
- **`views.display.find_window_by_tag`** — 25 Aufrufe
  - 24x (96%) ("noice_all")
  - 1x (4%) ("messages")

---

## language.nvim

Sessions: 72 · Tage mit Daten: 2 (2026-08-06..2026-08-09) · Funktionen instrumentiert: 1 · Aufrufe gesamt: 36

**Module, nach Gesamtaufrufen ihrer Funktionen:**

- `language.config` — 36 (100%)

**Top-Funktionen:**

- **`config.get`** — 36 Aufrufe
  - 36x (100%) ()

---

## cmdlog.nvim

Sessions: 169 · Tage mit Daten: 8 (2026-08-05..2026-08-12) · Funktionen instrumentiert: 7 · Aufrufe gesamt: 4570

**Module, nach Gesamtaufrufen ihrer Funktionen:**

- `cmdlog.core.errors` — 3146 (69%)
- `cmdlog.core.store` — 620 (14%)
- `cmdlog.core.project_history` — 536 (12%)
- `cmdlog.core.stats` — 268 (6%)

**Top-Funktionen:**

- **`core.errors.is_known_bad`** — 3137 Aufrufe
  - 6x (0%) ("nvim -c \"luafile C:/Users/bartl/AppData/"…)
  - 1x (0%) ("cd .\\images.nvim\\")
  - 1x (0%) ("git status")
  - +3100 (99%) weitere, seltenere Muster (nicht einzeln mitgezählt — Obergrenze pro Funktion, damit ein Aufruf mit x-beliebigen Argumenten nicht unbegrenzt Speicher kostet)
- **`core.store.save_json`** — 533 Aufrufe
  - 533x (100%) ("C:\\Users\\bartl\\AppData\\Local\\nvim-data/c"…, <table...
- **`core.project_history.record`** — 268 Aufrufe
  - 25x (9%) ("BindingsPath")
  - 10x (4%) ("Reposcope status $REPOS_DIR")
  - 9x (3%) ("Reposcope status")
  - +144 (54%) weitere, seltenere Muster (nicht einzeln mitgezählt — Obergrenze pro Funktion, damit ein Aufruf mit x-beliebigen Argumenten nicht unbegrenzt Speicher kostet)
- **`core.stats.record`** — 268 Aufrufe
  - 25x (9%) ("BindingsPath")
  - 10x (4%) ("Reposcope status $REPOS_DIR")
  - 9x (3%) ("Reposcope status")
  - +144 (54%) weitere, seltenere Muster (nicht einzeln mitgezählt — Obergrenze pro Funktion, damit ein Aufruf mit x-beliebigen Argumenten nicht unbegrenzt Speicher kostet)
- **`core.project_history.get_git_root`** — 268 Aufrufe
  - 268x (100%) ()
- **`core.store.load_json`** — 87 Aufrufe
  - 87x (100%) ("C:\\Users\\bartl\\AppData\\Local\\nvim-data/c"…, <table...
- **`core.errors.record`** — 9 Aufrufe
  - 2x (22%) ("/Users/bartl/AppData/Local/Temp/claude/C"…, "E492: Not ...
  - 2x (22%) ("noh|call vm#reset()", "E117: Unknown function: VM_Exit")
  - 1x (11%) ("Tableize", "E486: Pattern not found: ['\"][^'\"]*\\zs__"…)

---

## github_stats.nvim

Sessions: 93 · Tage mit Daten: 8 (2026-08-05..2026-08-12) · Funktionen instrumentiert: 56 · Aufrufe gesamt: 25150

**Module, nach Gesamtaufrufen ihrer Funktionen:**

- `github_stats.config` — 8485 (34%)
- `github_stats.storage` — 7031 (28%)
- `github_stats.analytics` — 4878 (19%)
- `github_stats.export` — 1353 (5%)
- `github_stats.dashboard.state` — 1151 (5%)
- `github_stats.api` — 800 (3%)

**Top-Funktionen:**

- **`config.get_storage_root`** — 6545 Aufrufe
  - 6545x (100%) ()
- **`analytics.query_metric`** — 4875 Aufrufe
  - 4875x (100%) (<table:map>)
- **`storage.read_metric_history`** — 4875 Aufrufe
  - 98x (2%) ("StefanBartl/emojis.nvim", "clones")
  - 98x (2%) ("StefanBartl/debugging.nvim", "clones")
  - 98x (2%) ("StefanBartl/diff.nvim", "clones")
  - +2121 (44%) weitere, seltenere Muster (nicht einzeln mitgezählt — Obergrenze pro Funktion, damit ein Aufruf mit x-beliebigen Argumenten nicht unbegrenzt Speicher kostet)
- **`export.format_number`** — 1350 Aufrufe
  - 6x (0%) (113)
  - 4x (0%) (525)
  - 4x (0%) (166)
  - +1220 (90%) weitere, seltenere Muster (nicht einzeln mitgezählt — Obergrenze pro Funktion, damit ein Aufruf mit x-beliebigen Argumenten nicht unbegrenzt Speicher kostet)
- **`config.get`** — 859 Aufrufe
  - 859x (100%) ()
- **`config.get_token`** — 800 Aufrufe
  - 800x (100%) ()
- **`api.fetch_metric_async`** — 800 Aufrufe
  - 8x (1%) ("StefanBartl/buffer-ctx.nvim", "referrers", <function>)
  - 8x (1%) ("StefanBartl/debugging.nvim", "clones", <function>)
  - 8x (1%) ("StefanBartl/emojis.nvim", "paths", <function>)
  - +544 (68%) weitere, seltenere Muster (nicht einzeln mitgezählt — Obergrenze pro Funktion, damit ein Aufruf mit x-beliebigen Argumenten nicht unbegrenzt Speicher kostet)
- **`storage.write_metric`** — 800 Aufrufe
  - 8x (1%) ("StefanBartl/documentation.nvim", "paths", <table:#4>)
  - 8x (1%) ("StefanBartl/github_stats.nvim", "paths", <table:#1>)
  - 8x (1%) ("StefanBartl/emojis.nvim", "views", <table:map>)
  - +679 (85%) weitere, seltenere Muster (nicht einzeln mitgezählt — Obergrenze pro Funktion, damit ein Aufruf mit x-beliebigen Argumenten nicht unbegrenzt Speicher kostet)

---

## cascade.nvim

Sessions: 74 · Tage mit Daten: 8 (2026-08-05..2026-08-12) · Funktionen instrumentiert: 48 · Aufrufe gesamt: 294002

**Module, nach Gesamtaufrufen ihrer Funktionen:**

- `cascade.lists.marker` — 153870 (52%)
- `cascade.core.patterns` — 84162 (29%)
- `cascade.lists.renumber` — 19992 (7%)
- `cascade.util.lib` — 16037 (5%)
- `cascade.config` — 9617 (3%)
- `cascade.core.context` — 7163 (2%)

**Top-Funktionen:**

- **`lists.marker.parse`** — 100631 Aufrufe
  - 16460x (16%) ("", <table:map>)
  - 1218x (1%) ("---", <table:map>)
  - 404x (0%) ("- [ ]  Könnte es nicht eine \"neue art\" "…, <table:map>)
  - +78874 (78%) weitere, seltenere Muster (nicht einzeln mitgezählt — Obergrenze pro Funktion, damit ein Aufruf mit x-beliebigen Argumenten nicht unbegrenzt Speicher kostet)
- **`core.patterns.unordered_class`** — 84162 Aufrufe
  - 84162x (100%) (<table:#3>)
- **`lists.marker.is_blank_line`** — 19586 Aufrufe
  - 2369x (12%) ("")
  - 116x (1%) ("- [ ] finish & checkists & review in nvi"…)
  - 115x (1%) ("  1. dass was wq macht in einem `lib.nvi"…)
  - +15153 (77%) weitere, seltenere Muster (nicht einzeln mitgezählt — Obergrenze pro Funktion, damit ein Aufruf mit x-beliebigen Argumenten nicht unbegrenzt Speicher kostet)
- **`lists.marker.is_continuation`** — 19586 Aufrufe
  - 2369x (12%) ("", 0, 0)
  - 116x (1%) ("- [ ] finish & checkists & review in nvi"…, 0, 0)
  - 115x (1%) ("  1. dass was wq macht in einem `lib.nvi"…, 0, 0)
  - +15154 (77%) weitere, seltenere Muster (nicht einzeln mitgezählt — Obergrenze pro Funktion, damit ein Aufruf mit x-beliebigen Argumenten nicht unbegrenzt Speicher kostet)
- **`util.lib.map`** — 15875 Aufrufe
  - 635x (4%) ("n", "<leader>cx", <function>, <table:map>)
  - 635x (4%) ("n", "<leader>cf", <function>, <table:map>)
  - 635x (4%) ("x", "<leader>cX", <function>, <table:map>)
- **`lists.marker.blank_run`** — 13820 Aufrufe
  - 13820x (100%) (<table:map>)
- **`config.get`** — 9617 Aufrufe
  - 9000x (94%) ("lists")
  - 565x (6%) ("debug")
  - 28x (0%) ("transpose")
- **`lists.renumber.tree`** — 7708 Aufrufe
  - 15x (0%) (2, 2, 2, <table:map>, …+1)
  - 11x (0%) (2, 4, 5, <table:map>, …+1)
  - 5x (0%) (6, 2, 4, <table:map>, …+1)
  - +7621 (99%) weitere, seltenere Muster (nicht einzeln mitgezählt — Obergrenze pro Funktion, damit ein Aufruf mit x-beliebigen Argumenten nicht unbegrenzt Speicher kostet)

---

## markdown.nvim

Sessions: 42 · Tage mit Daten: 8 (2026-08-05..2026-08-12) · Funktionen instrumentiert: 46 · Aufrufe gesamt: 3838791

**Module, nach Gesamtaufrufen ihrer Funktionen:**

- `markdown.hl_options.hl_groups.blockquote` — 3301952 (86%)
- `markdown.core.fold` — 359538 (9%)
- `markdown.config` — 67059 (2%)
- `markdown.scope` — 62184 (2%)
- `markdown.core.slug` — 32295 (1%)
- `markdown.core.refs` — 13165 (0%)

**Top-Funktionen:**

- **`hl_options.hl_groups.blockquote.highlight_line`** — 3301952 Aufrufe
  - 27x (0%) (29, 0)
  - 20x (0%) (29, 1)
  - 2x (0%) (29, 27)
  - +3301845 (100%) weitere, seltenere Muster (nicht einzeln mitgezählt — Obergrenze pro Funktion, damit ein Aufruf mit x-beliebigen Argumenten nicht unbegrenzt Speicher kostet)
- **`core.fold.foldexpr`** — 359534 Aufrufe
  - 4243x (1%) (2)
  - 4148x (1%) (3)
  - 4095x (1%) (4)
  - +271895 (76%) weitere, seltenere Muster (nicht einzeln mitgezählt — Obergrenze pro Funktion, damit ein Aufruf mit x-beliebigen Argumenten nicht unbegrenzt Speicher kostet)
- **`config.feature_enabled`** — 39797 Aufrufe
  - 21872x (55%) ("fenced_scope")
  - 14900x (37%) ("keymaps")
  - 1194x (3%) ("table")
- **`config.get`** — 27262 Aufrufe
  - 27262x (100%) ()
- **`scope.enabled`** — 20754 Aufrufe
  - 20754x (100%) ()
- **`scope.op_enabled`** — 20715 Aufrufe
  - 20676x (100%) ("fold")
  - 32x (0%) ("toc")
  - 3x (0%) ("jump")
- **`scope.row_fence_kind`** — 20676 Aufrufe
  - 185x (1%) (4, 0)
  - 157x (1%) (2, 0)
  - 149x (1%) (3, 0)
  - +19618 (95%) weitere, seltenere Muster (nicht einzeln mitgezählt — Obergrenze pro Funktion, damit ein Aufruf mit x-beliebigen Argumenten nicht unbegrenzt Speicher kostet)
- **`core.slug.heading_anchors`** — 18571 Aufrufe
  - 16027x (86%) (153)
  - 129x (1%) (4)
  - 122x (1%) (5)
  - +1507 (8%) weitere, seltenere Muster (nicht einzeln mitgezählt — Obergrenze pro Funktion, damit ein Aufruf mit x-beliebigen Argumenten nicht unbegrenzt Speicher kostet)

---

## color_my_ascii.nvim

Sessions: 27 · Tage mit Daten: 5 (2026-08-08..2026-08-12) · Funktionen instrumentiert: 36 · Aufrufe gesamt: 20793616

**Module, nach Gesamtaufrufen ihrer Funktionen:**

- `color_my_ascii.config` — 14591980 (70%)
- `color_my_ascii.utils.safe_api` — 5051394 (24%)
- `color_my_ascii.parser` — 897131 (4%)
- `color_my_ascii.cache_manager` — 75001 (0%)
- `color_my_ascii.highlighter` — 48058 (0%)
- `color_my_ascii.fence_hl` — 46948 (0%)

**Top-Funktionen:**

- **`config.get_char_highlight`** — 10360251 Aufrufe
  - 810890x (8%) ("e")
  - 610963x (6%) ("n")
  - 606807x (6%) ("i")
  - +2021310 (20%) weitere, seltenere Muster (nicht einzeln mitgezählt — Obergrenze pro Funktion, damit ein Aufruf mit x-beliebigen Argumenten nicht unbegrenzt Speicher kostet)
- **`config.get`** — 1770163 Aufrufe
  - 1770163x (100%) ()
- **`config.get_keyword_languages`** — 1716251 Aufrufe
  - 147212x (9%) ("nvim")
  - 121869x (7%) ("lua")
  - 8795x (1%) ("config")
  - +1398918 (82%) weitere, seltenere Muster (nicht einzeln mitgezählt — Obergrenze pro Funktion, damit ein Aufruf mit x-beliebigen Argumenten nicht unbegrenzt Speicher kostet)
- **`utils.safe_api.safe_call`** — 1691754 Aufrufe
  - 1398x (0%) (<function>, 25, 40, 31, …+2)
  - 1137x (0%) (<function>, 25, 40, 29, …+2)
  - 946x (0%) (<function>, 25, 40, 30, …+2)
  - +1680024 (99%) weitere, seltenere Muster (nicht einzeln mitgezählt — Obergrenze pro Funktion, damit ein Aufruf mit x-beliebigen Argumenten nicht unbegrenzt Speicher kostet)
- **`utils.safe_api.buf_set_extmark`** — 1619338 Aufrufe
  - 165x (0%) (25, 40, 31, 23, …+1)
  - 91x (0%) (46, 78, 0, 11, …+1)
  - 51x (0%) (25, 40, 30, 23, …+1)
  - +1617987 (100%) weitere, seltenere Muster (nicht einzeln mitgezählt — Obergrenze pro Funktion, damit ein Aufruf mit x-beliebigen Argumenten nicht unbegrenzt Speicher kostet)
- **`utils.safe_api.set_extmark`** — 1619338 Aufrufe
  - 165x (0%) (25, 40, 31, 23, …+4)
  - 91x (0%) (46, 78, 0, 11, …+4)
  - 51x (0%) (25, 40, 30, 23, …+4)
  - +1617985 (100%) weitere, seltenere Muster (nicht einzeln mitgezählt — Obergrenze pro Funktion, damit ein Aufruf mit x-beliebigen Argumenten nicht unbegrenzt Speicher kostet)
- **`parser.tokenize_line`** — 735151 Aufrufe
  - 1355x (0%) ("markdown.nvim")
  - 1172x (0%) ("options.nvim")
  - 969x (0%) ("config/DEFAULTS.lua")
  - +723136 (98%) weitere, seltenere Muster (nicht einzeln mitgezählt — Obergrenze pro Funktion, damit ein Aufruf mit x-beliebigen Argumenten nicht unbegrenzt Speicher kostet)
- **`config.is_function_detection_enabled`** — 733227 Aufrufe
  - 733227x (100%) ()

---

## images.nvim

Sessions: 38 · Tage mit Daten: 6 (2026-08-05..2026-08-11) · Funktionen instrumentiert: 7 · Aufrufe gesamt: 81

**Module, nach Gesamtaufrufen ihrer Funktionen:**

- `images.config` — 43 (53%)
- `images` — 38 (47%)

**Top-Funktionen:**

- **`config.get`** — 43 Aufrufe
  - 43x (100%) ()
- **`hover`** — 23 Aufrufe
  - 23x (100%) ()
- **`show`** — 8 Aufrufe
  - 6x (75%) ("C:\\Users\\bartl\\AppData\\Local\\nvim\\docs\\T"…)
  - 2x (25%) ("C:/Users/bartl/Documents/My Games/Outlaw"…)
- **`browse`** — 3 Aufrufe
  - 3x (100%) ("cwd", nil)
- **`paste`** — 2 Aufrufe
  - 2x (100%) ()
- **`compare`** — 1 Aufrufe
  - 1x (100%) ("cwd", nil)
- **`list`** — 1 Aufrufe
  - 1x (100%) (nil, nil)

---

## Ohne Daten

**Keine Telemetry-Datei gefunden** (nie geladen, oder Telemetrie diese Woche nicht aktiv):

- replacer.nvim
- diff.nvim
- migrate.nvim
- emojis.nvim

**Datei vorhanden, aber keine einzige Funktion aufgezeichnet** (Plugin lief, aber nichts Instrumentiertes wurde aufgerufen — oder die instrumentierten Funktionen liegen tiefer als `deep=true` fasst):

- runtime-analysis.nvim — 253 Sessions, 0 Tage mit einem Eintrag, 0 Funktionsaufrufe
- dap.nvim — 72 Sessions, 0 Tage mit einem Eintrag, 0 Funktionsaufrufe
- pdfport.nvim — 68 Sessions, 0 Tage mit einem Eintrag, 0 Funktionsaufrufe
- recommender.nvim — 17 Sessions, 0 Tage mit einem Eintrag, 0 Funktionsaufrufe
- mdview.nvim — 27 Sessions, 0 Tage mit einem Eintrag, 0 Funktionsaufrufe

---

