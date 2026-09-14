# `rules.nvim` gegen `ui.nvim`: Report + laufende Handover-Akte

> **Ausnahme-Standort:** normalerweise leben Plugin-Roadmaps im Wkdbook
> (`wkdbook-myplugins/ui.nvim/{ROADMAP,handovers}`). Diese Datei ist explizit
> als laufende Handover-Akte für den `rules.nvim`-Review-Durchgang gegen
> `ui.nvim` angefordert und bleibt hier (`nvim/docs/ROADMAP/handovers/`),
> ursprünglich aus `reports/` hierher verschoben (2026-09-14).

## Table of content

  - [1. Was `rules.nvim` hier tut](#1-was-rulesnvim-hier-tut)
  - [2. Wie ausgeführt](#2-wie-ausgefhrt)
  - [3. Ergebnis: 281 Regeln, 4 automatisiert, 277 manuell](#3-ergebnis-281-regeln-4-automatisiert-277-manuell)
    - [Die vier automatisierten Treffer — alle grün](#die-vier-automatisierten-treffer-alle-grn)
    - [Die 277 manuellen Einträge — nach Familie und Schweregrad](#die-277-manuellen-eintrge-nach-familie-und-schweregrad)
  - [4. Einordnung](#4-einordnung)
  - [5. Nicht Teil dieses Durchgangs](#5-nicht-teil-dieses-durchgangs)
  - [6. Reproduzieren / weiterarbeiten](#6-reproduzieren-weiterarbeiten)
  - [Fortschritt](#fortschritt)
  - [Runde 1 (2026-09-14): `ui.kit/` + `contextmenu/`](#runde-1-2026-09-14-uikit-contextmenu)
  - [Runde 2 (2026-09-14): `ui/statusline/`](#runde-2-2026-09-14-uistatusline)
  - [Runde 3 (2026-09-14): `ui/tabline/` + `ui/bindings/`](#runde-3-2026-09-14-uitabline-uibindings)
  - [Runde 4 (2026-09-14): `ui/config/`, `ui/init.lua`, `ui/health.lua`](#runde-4-2026-09-14-uiconfig-uiinitlua-uihealthlua)
  - [Runde 5 (2026-09-14): `ui/theme/`, `ui/winbar/` — Abschluss](#runde-5-2026-09-14-uitheme-uiwinbar-abschluss)
  - [Nächste Aufgabe: die volle 277-Regel-Ermessens-Review](#nchste-aufgabe-die-volle-277-regel-ermessens-review)
  - [Teil 2 — volle 277-Regel-Ermessens-Review](#teil-2-volle-277-regel-ermessens-review)
    - [Fortschritt (Teil 2)](#fortschritt-teil-2)
    - [Runde 6 (2026-09-14): Familie `ERR` (35 Regeln)](#runde-6-2026-09-14-familie-err-35-regeln)
    - [Runde 7 (2026-09-14): Familie `LUA` (59 Regeln)](#runde-7-2026-09-14-familie-lua-59-regeln)
    - [Runde 8 (2026-09-14): Familie `UI` (41 Regeln)](#runde-8-2026-09-14-familie-ui-41-regeln)
    - [Runde 9 (2026-09-14): Familie `CMT` (16 Regeln)](#runde-9-2026-09-14-familie-cmt-16-regeln)
    - [Runde 10 (2026-09-14): Familie `SEC` (29 Regeln)](#runde-10-2026-09-14-familie-sec-29-regeln)
    - [Runde 11 (2026-09-15): Familie `PRIN` (37 Regeln)](#runde-11-2026-09-15-familie-prin-37-regeln)

---

# Teil 1 — erster Lauf, nur Bericht (2026-09-14)

> **Zweck dieses Teils:** `rules.nvim` (das Regel-Engine-Plugin,
> `E:\repos\rules.nvim`) einmal headless gegen den aktuellen `ui.nvim`-Stand
> laufen lassen und das Ergebnis dokumentieren — **keine** Regel wurde in
> diesem Durchgang bearbeitet, kein Code geändert. Stand 2026-09-14, Commit
> `339955d` (nach dem Kreuzfeature-Check-Durchgang, siehe
> [ui-nvim-cross-feature-check.md](./ui-nvim-cross-feature-check.md)).

---

## 1. Was `rules.nvim` hier tut

`rules.nvim` ist reines Engine — es bringt selbst keine Regeln mit. Das
Regelwerk kommt aus `$REPOS_DIR/WKDBooks/Development/wkdbook-Lua/Checklists`
(**421 Regeln über 13 Familien**, ID-Präfix = Familie), genau die
Konfiguration, die auch `lua/plugins/personal/init.lua` global einträgt:

```lua
rulesets = { vim.env.REPOS_DIR .. "/WKDBooks/Development/wkdbook-Lua/Checklists" },
gates = {
  new_project = { "NEW" },
  release = { "REL" },
  review = { "ERR", "LUA", "UI", "CMT", "SEC", "PRIN", "PERF" },
},
```

Eine Regel ist `{id, severity, check?}`. `check` ist **optional** — die
meisten Regeln in einem echten Regelwerk sind Ermessensfragen
(Architektur, Fehlerbehandlung, Security-Review) und bekommen bewusst
**keinen** automatischen Verdict, nur einen Worklist-Eintrag (ID, Titel,
Fundstelle). Nur vier `check`-Typen sind mechanisch automatisierbar: `grep`,
`file_exists`/`file_absent`, `json_key_absent`, `lua_predicate`.

Für ein **bestehendes** Projekt (kein Neuanlage-, kein Release-Zeitpunkt)
ist das **`review`-Gate** der richtige Einstieg — exakt die Familien, die
`gates/REVIEW.md`s eigener Schnell-Check zitiert:
`ERR` (Fehlerbehandlung), `LUA` (lib.nvim-Nutzung, Neovim-API,
Lazy-Loading/Autocmd-Lebenszyklus, State, Code-Stil, Annotationen),
`UI` (UI/Bedienbarkeit, Buffer-/Window-Management), `CMT`
(Kommentar-Hygiene), `SEC` (Sicherheit), `PRIN` (Prinzipien: Single
Responsibility, keine globalen States, Testbarkeit, …), `PERF`
(Performance).

---

## 2. Wie ausgeführt

Headless, ohne interaktives Neovim, nach dem in
`rules.nvim/docs/BINDINGS.md` dokumentierten CI-Muster:

```sh
nvim --headless --clean -u <minimal_init_mit_rtp_für_rules.nvim+lib.nvim> -c "
  lua local json, code = require('rules').setup({...}); \
       json, code = require('rules').run_gate_json('review', '<ui.nvim-Pfad>')
  -- json in Datei geschrieben, code geprüft
"
```

Geprüfter Pfad: der Arbeits-Worktree
`E:\repos\ui.nvim\.claude\worktrees\nvim-plugin-cross-feature-55b0f5`
(enthält denselben Stand wie `main` nach Commit `339955d` — `.claude/` selbst
ist nicht versioniert und daher im Worktree gar nicht vorhanden, also auch
keine Selbstrekursion durch den `fswalk`-Dateiwalk, der nur `.git`/`.deps`
überspringt).

Das Regelwerk lädt sauber — `require('rules').stats().total == 421`, keine
Parse-Fehler/ID-Kollisionen gemeldet.

---

## 3. Ergebnis: 281 Regeln, 4 automatisiert, 277 manuell

`:Rules gate review` deckt 281 der 421 Regeln ab (`ERR` 35, `LUA` 59, `UI`
41, `CMT` 16, `SEC` 29, `PRIN` 37, `PERF` 64). Davon hat nur eine Handvoll
überhaupt ein `check`-Feld:

| Status | Anzahl |
| --- | --- |
| `pass` | **4** |
| `fail` | 0 |
| `error` | 0 |
| `waived` | 0 |
| `manual` (kein automatischer Check — Worklist-Eintrag) | **277** |

**Exit-Code 0** — keine `critical`-Regel ist fehlgeschlagen oder auf einen
Fehler gelaufen (das ist der einzige Fall, der `check_family_json`/
`run_gate_json` einen Exit-Code `1` geben würde).

---

### Die vier automatisierten Treffer — alle grün

| ID | Schweregrad | Titel | Ergebnis |
| --- | --- | --- | --- |
| `SEC-01` | 🔴 kritisch | Argv statt Shell-String | ✅ pass — kein `os.execute(`/`io.popen(` im Baum |
| `UI-62` | 🔴 kritisch | Der Healthcheck liegt unter `lua/<modul>/health.lua` | ✅ pass — `lua/ui/health.lua` existiert |
| `LUA-80` | 🟡 empfohlen | Explizite Dateien für pluginseitige Defaults | ✅ pass — `lua/ui/config/DEFAULTS.lua` existiert |
| `SEC-47` | 🟡 empfohlen | Temp-Dateien nur über `vim.fn.tempname()` | ✅ pass — kein manuelles Temp-Datei-Pattern gefunden |

Das ist die ganze mechanisch prüfbare Oberfläche des Review-Gates gegen
diesen Codebestand — kein Fund, keine Handlung nötig.

---

### Die 277 manuellen Einträge — nach Familie und Schweregrad

Kein automatischer Verdict, aber ein strukturiertes Arbeitspaket, falls das
als Nächstes vertieft werden soll:

| Familie | 🔴 kritisch | 🟡 empfohlen | 🟢 nice-to-have | Summe |
| --- | --: | --: | --: | --: |
| `ERR` — Fehlerbehandlung | 16 | 18 | 1 | 35 |
| `LUA` — lib.nvim/API/Stil/Annotationen | 14 | 24 | 21 | 59 |
| `UI` — Bedienbarkeit, Buffer/Window | 4 | 28 | 9 | 41 |
| `CMT` — Kommentar-Hygiene | 1 | 12 | 3 | 16 |
| `SEC` — Sicherheit | 18 | 9 | 2 | 29 |
| `PRIN` — Prinzipien | 6 | 20 | 11 | 37 |
| `PERF` — Performance | 10 | 33 | 21 | 64 |
| **Summe** | **69** | **144** | **68** | **281** |

(`SEC`s 18 "kritisch" zählen die zwei bereits automatisiert bestandenen
mit — die Tabelle ist die volle Familiengröße, nicht nur die manuellen
Reste; die vier `pass`-Fälle oben sind in dieser Zählung enthalten.)

---

## 4. Einordnung

- **Kein Fund heißt hier nicht "sauber", sondern "die vier mechanisch
  prüfbaren Punkte sind sauber".** Die eigentliche Substanz des
  Review-Gates (277 von 281 Regeln) ist bewusst ohne automatischen Check —
  das ist `rules.nvim`s erklärtes Design ("never pretends to give an
  automatic verdict on a rule that actually needs human or agent
  judgment"), nicht eine Lücke in diesem Lauf.
- Der schnellste sinnvolle nächste Schritt wäre **nicht** alle 277 Einträge
  auf einmal, sondern `gates/REVIEW.md`s eigener **Schnell-Check** (10
  Punkte, sowohl 🔴 als auch 🟡 gewichtet, deckt die immer wieder gleichen
  Kernfragen ab: Fehlerbehandlung, Type Guards, Buffer/Window-Validierung,
  keine globalen States, Single Responsibility, UI-Cleanup,
  Performance-Hotspots, Annotationen, Kommentar-Drift, Testbarkeit) —
  danach bei Abweichungen gezielt in den jeweiligen Detail-Abschnitt von
  `regeln/LUA_NVIM.md`/`PRINCIPLES.md`/`PERFORMANCE.md` springen.
- `--diff=<ref>` wäre die engere Variante für zukünftige PRs/Commits
  (scoped auf tatsächlich geänderte Dateien statt auf den ganzen
  Bestand) — für diesen ersten Blick auf `ui.nvim` als Ganzes war der
  ungescopte Lauf die richtige Wahl.

---

## 5. Nicht Teil dieses Durchgangs

- Keine der 277 manuellen Regeln wurde gegen `ui.nvim`s Code geprüft — das
  wäre ein eigener, deutlich größerer Durchgang (im Kern eine
  Ermessens-Review des ganzen Quellbaums gegen 277 Punkte).
- Kein Code wurde geändert, kein `.rules-waivers.json` angelegt.
- `:Rules gate review` interaktiv (mit lesbarem Buffer-Report und
  Sprungmarken zu jeder Regelquelle) wurde nicht geöffnet — nur die
  headless/JSON-Variante, passend zu "erstmal nur der Report".

---

## 6. Reproduzieren / weiterarbeiten

```vim
:Rules gate review
```

in einer `ui.nvim`-Session (mit `rules.nvim` + `lib.nvim` auf dem
Runtimepath und der `rulesets`/`gates`-Konfiguration aus
`lua/plugins/personal/init.lua`, die bereits so steht) öffnet denselben
Lauf interaktiv — Quickfix-Liste plus lesbarer Buffer, mit `:Rules show
<id>` zu jeder einzelnen Regelquelle.

Die vollständigen Rohdaten dieses Laufs (alle 281 Einträge, `id`,
`severity`, `status`, `findings`) liegen als
[rules-nvim-on-ui-nvim.json](./rules-nvim-on-ui-nvim.json) direkt neben
dieser Handover-Akte (nur die Report-Prosa ist hierher in `handovers/rules/`
umgezogen, siehe [Manueller Teil](#manueller-teil-schnell-check-2026-09-14-ff)
unten).

---

# Manueller Teil: Schnell-Check (2026-09-14 ff.)

Teil 1 oben hat nur die **4 automatisierbaren** Regeln geprüft (alle grün).
Dieser Teil arbeitet den in [Teil 1 § 4](#4-einordnung) empfohlenen nächsten
Schritt ab: den **Schnell-Check (10 Punkte)** aus `gates/REVIEW.md`, per
Ermessen gegen den kompletten `ui.nvim`-Quellbaum geprüft (93 Lua-Dateien
unter `lua/ui/`, Stand `339955d`) — nicht die vollen 277 Einzelregeln.

Vorgehen: repo-weise/verzeichnisweise Durchgänge (ein Subagent pro Runde,
sequenziell, "nie mehr als 1 Agent gleichzeitig"), Funde werden hier
laufend protokolliert. Bei echten Abweichungen wird — sofern sinnvoll und
risikoarm — gleich gefixt (luacheck/stylua-grün, Commit direkt auf `main`).

---

## Fortschritt

| Bereich | Status |
| --- | --- |
| `lua/ui/kit/` (20 Dateien, geteiltes Toolkit) + `lua/ui/contextmenu/` | ✅ Runde 1 fertig, 3 Fixes committet (`5a1f510`) |
| `lua/ui/statusline/` (Module, Renderer) | ✅ Runde 2 fertig, 4 Fixes committet (`97953f5`) |
| `lua/ui/tabline/`, `lua/ui/bindings/` | ✅ Runde 3 fertig, 4 Fixes + 2 Regressionstests committet (`c2da007`) |
| `lua/ui/config/`, `lua/ui/init.lua`, `lua/ui/health.lua` | ✅ Runde 4 fertig, 5 Fixes + 2 Regressionstests committet (`8e7c1da`) |
| `lua/ui/theme/`, `lua/ui/winbar/` | ✅ Runde 5 fertig, keine Funde |

**Kompletter `lua/ui/`-Baum (93 Lua-Dateien) durch — alle 5 Runden abgeschlossen.**

---

## Runde 1 (2026-09-14): `ui.kit/` + `contextmenu/`

Per-Ermessen-Review gegen den 10-Punkte-Schnell-Check, ein Subagent
(`Explore`, medium). `contextmenu/` und die meisten `kit/`-Module sauber
(durchgängig `pcall`, konsequente `nvim_*_is_valid`-Guards, kein `_G.*`,
keine Shell-Strings, kein `pcall(f(args))`-Antipattern, `table.concat`
statt String-Concat in Schleifen).

Drei echte Funde, alle gefixt, luacheck/stylua grün, volle Testsuite grün
(`scripts/test.sh`), committet + auf `main` gepusht (`5a1f510`):

- **`kit/picker.lua`** (🔴 Kriterium 3, Handle-Validierung in async Callback):
  `finish_close()` stoppte den Debounce-Timer nicht — schloss der Nutzer den
  Picker innerhalb der 80ms-Debounce-Zeit (`<CR>`/`<Esc>`), feuerte der
  Timer trotzdem und rief `on_change("")` auf dem bereits geschlossenen
  Picker auf. Fix: `stop_timer()`-Helper, in `finish_close()` aufgerufen.
- **`kit/chooser.lua`** (🟡 Korrektheit, Drill-down-Re-Anchor): `set_items()`
  berechnete `row`/`col` für den nächsten Menü-Level aus
  `vim.fn.win_screenpos()` (immer Top-Left), ließ aber den bestehenden
  `cfg.anchor` (kann laut `@types/init.lua` bei `relative="mouse"` nahe am
  Bildschirmrand auf `"SW"` auto-geflippt sein) unangetastet — ein
  bottom-angeflipptes Drill-down-Menü wäre beim nächsten Level um seine
  eigene Höhe verrutscht. Fix: `cfg.anchor = "NW"` explizit gesetzt.
- **`kit/surface.lua`** (🟡 Kriterium 6, Cleanup/Resource-Leak): jede
  `surface.open()` legte eine neue, nach `winid` benannte Augroup an; das
  `once = true`-Autocmd entfernt sich selbst, die (dann leere) Gruppe blieb
  aber bestehen — Window-IDs werden in einer Session nie wiederverwendet,
  also akkumulieren sich beliebig viele leere Augroups. Fix: Gruppe wird in
  `Surface:fire_close()` per `nvim_del_augroup_by_id` gelöscht.

Nebenbei ein Kommentar-Drift gefixt (`kit/chooser.lua`): Modulkommentar
sprach von "Four presentation options", tatsächlich sind es fünf
(`hide_cursor`, `single_click`, `close_on_focus_lost`, `flash_on_select`,
`hover`).

Nicht angefasst (außerhalb des 10-Punkte-Scopes, vorbestehend, nicht Teil
dieser Runde): mehrere `need-check-nil`-Diagnosen in `chooser.lua` rund um
`state.surf` nach `M.is_open()`-Guards — wirkt wie eine
`lua_ls`-Typnarrowing-Grenze, kein bestätigter Laufzeit-Bug, nicht vertieft.

---

## Runde 2 (2026-09-14): `ui/statusline/`

Alle Dateien unter `lua/ui/statusline/` (Renderer, `catalog.lua`,
`highlights.lua`, `cursor_ctl/`, alle `modules/*`), gleicher Subagent-Ansatz
(`Explore`, medium). Kernpfad und die Mehrheit der Module sauber
(durchgängig `pcall`, `type()`-Guards, `nvim_buf_is_valid`-Checks vor
async-Callbacks, argv-Arrays statt Shell-Strings, saubere
`BufDelete`/`ColorScheme`-Cache-Invalidierung als etablierte Konvention).

Vier echte Funde, alle gefixt, luacheck/stylua grün, volle Testsuite grün,
committet + auf `main` gepusht (`97953f5`):

- **`modules/github_stats_badge/init.lua`** + **`modules/casedesk/init.lua`**
  (🟡 Korrektheit, Konventionsbruch): beide lasen `nvim_buf_get_name(0)`
  (den *fokussierten* Buffer) statt `primitives.stbufnr()`
  (`vim.g.statusline_winid`s Buffer — die Konvention, der jedes andere
  buffer-bezogene Modul in diesem Verzeichnis folgt). Bei einer inaktiven
  Split-/Preview-Statusline zeigten beide Badges das Repo/den Case des
  fokussierten statt des tatsächlich gerenderten Fensters. Fix: beide auf
  `primitives.stbufnr()` umgestellt.
- **`modules/recommender_badge/init.lua`** (🟡 Kriterium 6, Leck): der
  per-Buffer-Cache (`cache[buf] = {tick, count}`) hatte — anders als
  `since_last_save`/`time_in_buffer`/`lsp`s eigene Caches — keinen
  `BufDelete`/`BufWipeout`-Cleanup und wuchs über die Sessiondauer
  unbegrenzt. Fix: gleicher Autocmd-Cleanup wie bei den Schwestermodulen.
- **`modules/runtime_analysis_ampel/init.lua`** (🟡 Kriterium 7,
  Performance-Hotspot): der Fallback-Zweig für einen Namespace ohne
  laufende Telemetrie-Instanz (`entries_from_disk`) las bei **jedem**
  Statusline-Redraw ungecacht von der Platte (`telemetry.load()`) — anders
  als der In-Memory-Zweig, der laut eigenem Kommentar sicher auf jedem
  Render laufen darf. Fix: 5s-TTL-Cache pro Namespace, gleiches Muster wie
  `github_stats_badge`s eigener `STATS_TTL_SECONDS`.

Keine Funde zu globalem State, Shell-String-Interpolation, veralteten APIs
oder `pcall(f(args))`-Antipattern in diesem Bereich.

---

## Runde 3 (2026-09-14): `ui/tabline/` + `ui/bindings/`

Gezielt nach Geschwistern des Bugtyps gesucht, den der letzte Commit
(`f59e918`) schon einmal gefixt hat (Klick-Handler/Batch-Operation gegen
einen zwischenzeitlich ungültig gewordenen Buffer/ein falsches Fenster).
Fündig geworden — vier echte Funde, zwei davon 🔴, alle gefixt, luacheck/
stylua grün, volle Testsuite grün (inkl. 2 neuer Regressionstests),
committet + auf `main` gepusht (`c2da007`):

- **`ui/tabline/utils.lua` `M.goto_buf`** (🔴 Kriterium 1+3, echtes Sibling
  von `f59e918`): rief `state.goto_buf(bufnr)` ohne `pcall` auf — anders
  als der Schwester-Pfad `close_buffer`, der genau dafür schon gehärtet
  ist (Kommentar erklärt das explizit). Ein Tabline-Klick auf einen Chip,
  dessen Buffer zwischen Render und Klick-Verarbeitung bereits geschlossen
  wurde, warf einen ungefangenen Fehler mitten aus dem Klick-Handler. Fix:
  `pcall` + `notify.warn`, gleiches Muster wie `close_buffer`.
- **`tabufline/state.lua` `M.close_buffer`** (🔴 Kriterium 3, Float-Erkennung
  prüfte das falsche Fenster): die Floating-Window-Erkennung fragte
  `nvim_win_get_config(0)` — das *aktuelle* Fenster, nicht das Fenster, das
  `bufnr` tatsächlich zeigt. Bei einem expliziten `bufnr` (`close_all_bufs`,
  `close_n_buffers`) kann das aktuelle Fenster ein völlig unabhängiges
  Float sein (LSP-Hover, Theme-Picker) — `vim.cmd("bw")` hätte dann dessen
  Buffer weggewiped statt den eigentlichen `bufnr`. Fix: `vim.fn.bufwinid
  (bufnr)` löst das richtige Fenster auf, `nvim_win_close` schließt gezielt
  dieses Fenster.
- **`tabufline/state.lua` `M.close_all_bufs`** (🟡 Kriterium 1,
  Fehlergrenze): die Schleife über alle Buffer hatte keinen
  Per-Iteration-`pcall` — ein fehlschlagender Buffer brach den ganzen
  "close all"-Batch ab, der Rest blieb unbemerkt offen. Fix: `pcall` pro
  Iteration, bewusst ohne `notify` in diesem Low-Level-Modul (Anti-Pattern
  `ERR-04`) — der Batch-Aufrufer (`ui.tabline.utils`) notifiziert bereits
  auf Gesamtfehler.
- **`bindings/keymaps/init.lua`** (🟡 Kriterium 9, Kommentar-Drift): "eight
  actions" im Kommentar, tatsächlich neun registriert (`theme_picker` kam
  offenbar nach dem letzten Update dazu). Fix: Zahl korrigiert.

Zwei neue Regressionstests in `TESTS/bugfix_regressions_spec.lua`
(`goto_buf`- und Float-Fenster-Fix), im etablierten "bug: ..."-Stil dieser
Datei.

Keine Funde zu globalem State, Shell-Strings, veralteten APIs oder
`pcall(f(args))` in diesem Bereich; der restliche Code (Renderer,
Highlights, Styles, Usercmd-Dispatcher) sauber.

---

## Runde 4 (2026-09-14): `ui/config/`, `ui/init.lua`, `ui/health.lua`

Der Setup-/Config-Merge-Pfad — läuft einmal pro Session, aber Fehler dort
betreffen die ganze Session. Fünf echte Funde, zwei davon 🔴, alle gefixt,
luacheck/stylua grün, volle Testsuite grün (inkl. 2 neuer Regressionstests),
committet + auf `main` gepusht (`8e7c1da`):

- **`config/init.lua`** (🔴 Kriterium 2, kein Type-Guard): `setup({ theme =
  ... })`/`setup({ tabline = ... })` mergten einen Nicht-Tabellen-Override
  direkt in `vim.tbl_deep_extend`, ohne Guard — ein naheliegender Tippfehler
  (`tabline = false`) ließ `setup()` mit einem ungefangenen Lua-Error
  abbrechen. Fix: `type(...) == "table"`-Guard mit `notify.warn`-Fallback,
  analog zu `load_statusline_config`s bestehendem Muster.
- **`config/init.lua`** (🔴 Kriterium 6, Config-Merge/Referenz-Leck): ohne
  `tabline`-Override war `config.ui.tabline` **dasselbe Tabellenobjekt**
  wie `ui.config.DEFAULTS().tabline` — `vim.tbl_deep_extend` kopiert nur
  Keys, die in mehr als einer Quelle vorkommen, ein Key wie `tabline`
  (nur in einer Quelle) wird per Referenz übernommen. Exakt dieselbe
  Bugklasse, die dem Projekt laut `config/statusline/lsp.lua`s eigenem
  Kommentar schon einmal einen echten Vorfall beschert hat — jede spätere
  In-Place-Mutation der zurückgegebenen Config hätte den geshippten
  Default dauerhaft für jeden folgenden `setup()`-Aufruf verseucht. Fix:
  `vim.deepcopy()` vor dem Merge.
- **`ui/init.lua`** (🔴 Kriterium 1, kein `pcall` im Entry-Point):
  `M.setup()` verkabelte `keymaps`/`usrcmds`/`contextmenu` ohne jeden
  `pcall` — scheiterte eines, liefen die anderen beiden gar nicht erst,
  ohne Erklärung. Fix: jeder der drei Aufrufe einzeln `pcall`'d + notified.
- **`health.lua`** (🟡 Zusatzkriterium, `warn` bei erwartetem
  Lazy-Loading-Zustand): "`:UI is not registered`" nutzte `health.warn()`
  für den normalen Vor-`setup()`-Zustand — der `usrcmds`-Eintrag direkt
  daneben nutzt für denselben Fall bereits korrekt `health.info()`. Fix:
  auf `health.info()` heruntergestuft (mit Hinweistext in der Message
  selbst, da `vim.health.info()` anders als `.warn()`/`.error()` nur einen
  Parameter akzeptiert und ein zweites Argument stillschweigend verwirft).
- **`config/DEFAULTS.lua`** (🟡 Kriterium 9, Kommentar-Drift): "Two groups"
  im Kommentar, tatsächlich drei (`theme`/`statusline`/`tabline`) plus ein
  viertes, separat behandeltes `modules`. Fix: Zahl korrigiert.

Zwei neue Regressionstests in `TESTS/bugfix_regressions_spec.lua` für das
Referenz-Leck (Identität + In-Place-Mutation gegen `DEFAULTS.tabline`
geprüft).

---

## Runde 5 (2026-09-14): `ui/theme/`, `ui/winbar/` — Abschluss

Letzte Runde, keine Funde. `winbar/init.lua` (der im Auftrag vermutete
Kandidat für einen "Fenster inzwischen geschlossen"-Bug) löst das bereits
korrekt: `vim.schedule` + `nvim_win_is_valid()`-Check unmittelbar vor dem
`vim.wo[winid].winbar`-Zugriff im Callback. `theme/palette.lua` und
`theme/transparency.lua` durchgängig `pcall`-abgesichert um
`nvim_get_hl`/`nvim_set_hl`, kein globaler State, keine veralteten APIs.

**Damit ist der komplette `lua/ui/`-Baum (93 Lua-Dateien, alle 5 Runden)
durch den 10-Punkte-Schnell-Check aus `gates/REVIEW.md` gelaufen.**
Gesamtbilanz: 16 echte Funde (5× 🔴, 11× 🟡), alle gefixt, 4 neue
Regressionstests, luacheck/stylua durchgehend grün, volle Testsuite nach
jeder Runde grün, jede Runde einzeln committet und direkt auf `main`
gepusht (`5a1f510`, `97953f5`, `c2da007`, `8e7c1da`). Die volle
277-Regel-Ermessens-Review (Teil 1 § 5) bleibt weiterhin offen — dieser
Durchgang deckte bewusst nur den 10-Punkte-Schnell-Check ab, wie in
Teil 1 § 4 empfohlen.

---

## Nächste Aufgabe: die volle 277-Regel-Ermessens-Review

Der Schnell-Check oben deckt nur die 10 immer wiederkehrenden Kernfragen
ab. Die vollen 277 manuellen Regeln (Teil 1 § 3) sind feingranularer und
bisher **nicht** gegen `ui.nvim`s Code geprüft — eigener, deutlich größerer
Durchgang. Aufteilung nach Familie (🔴/🟡/🟢, Summe):

| Familie | Worum es geht | 🔴 | 🟡 | 🟢 | Summe |
| --- | --- | --: | --: | --: | --: |
| `ERR` | Fehlerbehandlung: strukturierte Fehlertypen, "kein Wert" vs. "falscher Wert", Stale-State/TOCTOU, Config-Merge-Reihenfolge, Batch-Best-effort | 16 | 18 | 1 | 35 |
| `LUA` | lib.nvim-Nutzung statt Eigenbau, Neovim-API-Konventionen, Lazy-Loading/Autocmd-Lebenszyklus, State-Management, Annotationen/Typen | 14 | 24 | 21 | 59 |
| `UI` | Bedienbarkeit, Buffer-/Window-Management, Handle-Validierung, Cleanup | 4 | 28 | 9 | 41 |
| `CMT` | Kommentar-Hygiene: Kopf-Tags, `@class`-Drift, Enumerationen aus der Quelle, kein ortsfremdes Wissen | 1 | 12 | 3 | 16 |
| `SEC` | Sicherheit: Argv statt Shell-String, Secrets, Downloads, Regex-Escaping, Pfad-Sanitizing (2 der 18 🔴 bereits automatisiert grün, siehe Teil 1) | 18 | 9 | 2 | 29 |
| `PRIN` | Prinzipien: Single Responsibility, keine globalen States, Kopplung/Kohäsion, Testbarkeit | 6 | 20 | 11 | 37 |
| `PERF` | Performance: Hotpath-Allokation, Micro-Optimierung nur gemessen, Treesitter vs. Regex | 10 | 33 | 21 | 64 |
| **Summe** | | **69** | **144** | **68** | **281** |

(281 statt 277, weil die Tabelle die volle Familiengröße zählt — die 4
bereits automatisiert bestandenen Regeln aus Teil 1 sind darin enthalten.)

**Für den nächsten Chat, zum Copy-Paste (Stand vor Runde 6 — inzwischen durch
[Teil 2](#teil-2-volle-277-regel-ermessens-review) unten überholt, hier nur
noch als Referenz für den ursprünglichen Auftragstext stehen gelassen):**

> Mach weiter mit der vollen 277-Regel-Ermessens-Review von `rules.nvim`
> gegen `ui.nvim`, siehe
> `C:\Users\bartl\AppData\Local\nvim\docs\ROADMAP\handovers\rules-nvim-on-ui-nvim.md`
> (Teil 1 = Ausgangsbericht, der Schnell-Check darunter ist bereits
> erledigt). Gehe familienweise vor (`ERR`, `LUA`, `UI`, `CMT`, `SEC`,
> `PRIN`, `PERF`), ein Subagent pro Runde (nie mehr als 1 gleichzeitig),
> gegen die volle Regelliste aus
> `E:\repos\WKDBooks\Development\wkdbook-Lua\Checklists\regeln\` (bzw.
> `:Rules show <id>` pro Regel). Rohdaten aller 281 Einträge (`id`,
> `severity`, `findings`) liegen in
> `nvim\docs\ROADMAP\reports\rules-nvim-on-ui-nvim.json`. Bei echten
> Funden: fixen, luacheck/stylua grün, Tests grün, committen + direkt auf
> `main` pushen, Handover-Datei nach jeder Runde fortschreiben.

---

# Teil 2 — volle 277-Regel-Ermessens-Review

Arbeitet die in [Teil 1 § "Nächste Aufgabe"](#nchste-aufgabe-die-volle-277-regel-ermessens-review)
beschriebene volle Review ab: alle 277 manuellen Regeln (281 mit den 4
bereits automatisiert bestandenen), familienweise, ein `Explore`-Subagent
pro Runde (Recherche/Analyse, keine Edit-Tools) — Fixes, luacheck/stylua,
Tests und Commit macht danach die Hauptsession selbst, exakt wie in Teil 1
etabliert.

Regeldefinitionen: `ERR`/`LUA`/`UI`/`CMT`/`SEC` stehen alle in
`E:\repos\WKDBooks\Development\wkdbook-Lua\Checklists\regeln\LUA_NVIM.md`
(als `#### \`<ID>\` — <Titel>`-Abschnitte mit `id = "..."`-Codeblock); `PRIN`
in `PRINCIPLES.md`, `PERF` in `PERFORMANCE.md` desselben Ordners. Die
vollständige ID-Liste (mit Severity) liegt in
[rules-nvim-on-ui-nvim.json](./rules-nvim-on-ui-nvim.json) (Pfad korrigiert
gegenüber dem Copy-Paste-Text oben — die Datei liegt neben dieser
Handover-Akte in `handovers/rules/`, nicht in `reports/`).

---

## Fortschritt (Teil 2)

| Familie | Regeln | Status |
| --- | --: | --- |
| `ERR` | 35 | ✅ Runde 6 fertig, 3 Fixes committet (`27b5391`) |
| `LUA` | 59 | ✅ Runde 7 fertig, 5 Fixes committet (`f7a73ef`) |
| `UI` | 41 | ✅ Runde 8 fertig, 2 Fixes committet (`a26c960`) |
| `CMT` | 16 | ✅ Runde 9 fertig, 3 Fixes committet (`37fedc1`) |
| `SEC` | 29 | ✅ Runde 10 fertig, 1 Fix committet (`834c343`) |
| `PRIN` | 37 | ✅ Runde 11 fertig, 2 Fixes committet (`cbfc489`) |
| `PERF` | 64 | offen |

---

## Runde 6 (2026-09-14): Familie `ERR` (35 Regeln)

Ein `Explore`-Subagent hat alle 35 `ERR`-IDs einzeln gegen `LUA_NVIM.md`
nachgeschlagen und per Ermessen gegen den `ui.nvim`-Code geprüft (gezielte
Greps pro Regel-Muster, nicht alle 93 Dateien komplett gelesen). `ERR-30/31/
34/40/41/21` haben mangels Angriffsfläche (kein Dateisystem-/Prozess-/
Terminal-Handling im Code) keine Fundstelle — sauber mangels relevantem
Code, nicht "geprüft und bestanden". `pcall(f(args))`-Antipattern (`ERR-62`),
Vararg-Verlust (`ERR-63`), Mehrwert-Kappung (`ERR-64`) sauber.

Drei echte Funde, alle gefixt, luacheck/stylua grün, volle Testsuite grün,
committet + auf `main` gepusht (`27b5391`):

- **`ui/config/init.lua`** (🔴 ERR-51/53/54, Referenz-Leck — Geschwister von
  Runde 4s `tabline_config`-Fund): `theme_config = require("ui.config.theme")`
  und der von `variants.resolve()` aufgelöste Statusline-Preset sind beide
  dasselbe `require()`-gecachte Modul-Tabellenobjekt bei jedem `M.setup()`-
  Aufruf — exakt dieselbe Bugklasse, die für `tabline_config` in Runde 4
  bereits präventiv gefixt wurde (mit explizitem Kommentar zu genau diesem
  Muster), hier aber bei den zwei Geschwister-Pfaden übersehen. Ein aktueller
  In-Place-Mutator wurde nicht gefunden — das Risiko ist wie beim
  Ursprungsfund präventiv. Fix: `vim.deepcopy()` für `theme_config` beim
  `require()` und für das von `load_statusline_config()` zurückgegebene
  Preset.
- **`ui/config/init.lua`** (🔴 ERR-50, kein Type-Guard/Validierung):
  `M.setup(user_opts)` prüfte nie, ob `user_opts` unbekannte Top-Level-Keys
  enthält — ein Tippfehler (`themes` statt `theme`) ließ den Override
  stillschweigend verschwinden, ohne jede Fehlermeldung. Fix:
  `KNOWN_SETUP_KEYS`-Tabelle (`theme`/`tabline`/`variant`), `notify.warn` bei
  jedem unbekannten Key.
- **`statusline/modules/lsp/symbols/document_symbols.lua`** (🟡 ERR-32,
  Stale-State/TOCTOU): `on_result()` stempelte `cache.version` mit dem Tick
  **zum Antwortzeitpunkt** statt mit dem Tick, für den die Anfrage gestellt
  wurde. Ein zweiter Edit, während die Anfrage noch läuft (der `cache.
  pending`-Guard verhindert einen zweiten Request), ließ die verspätete
  Antwort für den *neuen* Tick als frisch gelten — die Breadcrumb-Position
  blieb auf dem alten Dokumentstand eingefroren, bis der nächste Edit
  passiert. Fix: Tick vor `vim.lsp.buf_request` einfangen (`req_tick`), in
  `on_result` diesen Snapshot statt `current_tick(bufnr)` stempeln.

Ein architektureller Hinweis wurde bewusst **nicht** umgesetzt: `ui.nvim`
nutzt `lib.nvim`s `safe_api`/`lib.lua.error` (strukturierte Fehlerobjekte)
nirgends, sondern wiederholt stattdessen konsequent das plugin-eigene
`pcall` + `notify.warn(tostring(err))`-Muster (~170 Stellen, ERR-05/06). Das
ist in sich konsistent und deckt sich mit `docs/BINDINGS.md`s eigenem
"a failure notifies and returns rather than raising"-Muster — wirkt wie
bewusste Hauskonvention, nicht Versehen; ein Umbau auf strukturierte
Fehlerobjekte über ~170 Call-Sites wäre ein eigener, großer und riskanter
Umbau, kein Ein-Runden-Fix. Nicht angefasst.

---

## Runde 7 (2026-09-14): Familie `LUA` (59 Regeln)

Ein `Explore`-Subagent hat alle 58 zu prüfenden `LUA-*`-IDs (LUA-80 übersprungen
— bereits automatisiert `pass`) einzeln gegen `LUA_NVIM.md` nachgeschlagen
und geprüft. Viele Regeln ohne Angriffsfläche (keine schwachen Tabellen,
kein eigenes State-File, kein Fremd-`setup()`-Aufruf) — sauber mangels
relevantem Code. Autocmd-Lebenszyklus (`LUA-96`), Datei-Tags (`LUA-60`),
`@types`-Auslagerung (`LUA-63/66`), `lib.nvim`-Abhängigkeit (`LUA-01/04/05/06`)
durchgängig sauber.

Zwei echte Funde, einer gefixt (5 Dateien), einer bewusst nicht verändert:

- **`statusline/modules/{github_stats_badge,recommender_badge,casedesk,
  sandbox_ambient,session_status}/init.lua`** (🔴 LUA-92, Lazy-Loading
  unterlaufen): fünf Badge-Module gateten ihre Soft-Dependency-Präsenzprüfung
  mit `pcall(require, "<plugin>.<mod>")` **innerhalb der Render-Funktion**,
  die schon beim allerersten Statusline-Redraw läuft — bevor das jeweilige
  Fremd-Plugin über seinen eigenen Lazy-Trigger (`cmd`/`event`/`ft`) laden
  kann. `filetree_cwd_mode/init.lua` hatte exakt denselben Bug bereits
  einmal gefixt (`package.loaded["filetree"]` statt `require`, mit
  Kommentar: „a require here PULLS filetree.nvim in before the first
  paint — measured at ~202ms") — die fünf Module wiederholten das ungefixte
  Muster. Fix: alle fünf auf `package.loaded[...]` + `type(...) == "table"`-
  Guard umgestellt, mit Verweis-Kommentar auf `filetree_cwd_mode`. Innere
  `require`s, die erst laufen *nachdem* die Präsenz bereits über
  `package.loaded` bestätigt ist (z. B. `recommender.analyzers.<name>`,
  `casedesk.sla`/`.meta`), unverändert gelassen — das sind keine
  Erst-Eager-Loads mehr.
- **`bindings/usrcmds/init.lua:581` — `:Theme`-Alias** (🟡 LUA-95, generischer
  Usercmd-Name ohne Kollisionsprüfung): geprüft, **bewusst nicht geändert**.
  `:Theme` ist ein sehr generischer Name, den auch andere Theme-/Colorscheme-
  Plugins beanspruchen könnten; `lib.nvim.bindings.usercmd.create()` setzt
  `force = true` als *dokumentierten* Default (idempotente Neuerstellung bei
  Config-Hot-Reload) und führt bereits eine Provenienz-Registry (`records`)
  — die von LUA-95 verlangte Transparenz existiert also schon auf
  `lib.nvim`-Ebene, nur nicht als Kollisions-*Warnung*. `:Theme` ist zudem
  öffentlich dokumentiertes API (`bindings/usrcmds/README.md:23`) — eine
  Umbenennung wäre ein Breaking Change für jeden Host, der es bereits nutzt,
  gegen ein rein spekulatives Kollisionsrisiko. Abgewogen und stehen
  gelassen.

Alle Fixes: luacheck/stylua grün, volle Testsuite grün, committet + auf
`main` gepusht (`f7a73ef`).

---

## Runde 8 (2026-09-14): Familie `UI` (41 Regeln)

Ein `Explore`-Subagent hat alle 40 zu prüfenden `UI-*`-IDs (UI-62 übersprungen
— bereits automatisiert `pass`) geprüft. Viele Regeln ohne Angriffsfläche
(kein Scan-Cap/Backend-Fallback/CLI-Fehler-Mapping, kein which-key/
Custom-Dashboard/Quickfix-Producer in diesem Code) — sauber mangels
relevantem Code. `health.lua` (aus Runde 4), Count-Handling in
`keymaps/init.lua`, `Surface:close()`/`fire_close()`-Guards durchgängig
sauber.

Zwei echte Funde gefixt, zwei bewusst nicht verändert (Details unten),
luacheck/stylua grün, volle Testsuite grün, committet + auf `main` gepusht
(`a26c960`):

- **`bindings/keymaps/tabufline/{state,init}.lua`** (🔴 UI-01, "einmal
  bestätigen, nicht einmal pro Item"): `close_all_bufs()` und
  `close_n_buffers(n>1)` liefen jeweils in einer Schleife über
  `state.close_buffer()`, das pro modifiziertem Buffer sein eigenes
  `confirm bd<bufnr>` auslöst — ein `<leader>bq` bei 5 offenen, ungesicherten
  Buffern zeigte 5 sequenzielle Save-Dialoge. Fix: `close_buffer(bufnr,
  skip_confirm)` um einen `skip_confirm`-Parameter erweitert (force-closed
  über `bd!` statt `confirm bd`, wenn gesetzt); ein neuer
  `needs_close_confirm()`-Helper (exportiert als `M.__needs_close_confirm`)
  zählt vorab, wie viele Buffer im Batch tatsächlich einen Dialog auslösen
  würden; bei mindestens einem wird **ein** `vim.fn.confirm()` für den
  gesamten Batch gezeigt (Ja → alle mit `skip_confirm=true` schließen, Nein
  → ganzer Batch abgebrochen). `close_n_buffers` approximiert die Menge der
  betroffenen Buffer konservativ über `vim.t.bufs` (die exakte
  Traversal-Reihenfolge über wiederholtes `prev()` vorab zu simulieren wäre
  unverhältnismäßig aufwendig für den Grenzfall eines gelegentlichen
  Over-Ask).
- **`statusline/modules/helpers/nerd_fonts.lua`** (🟡 UI-38, unzuverlässige
  Nerd-Font-Erkennung): toter Code (0 Call-Sites) — `nerdf_sep_or_fallback()`
  entschied per `vim.fn.strdisplaywidth()`-Heuristik statt über
  `vim.g.have_nerd_font`, exakt das von der Regel namentlich verworfene
  Muster ("es gibt keine verlässliche Laufzeit-Erkennung… strdisplaywidth
  liefert für jeden Codepoint 1, Glyph oder Tofu gleichermaßen"). Da
  ungenutzt: Datei komplett entfernt statt eine nie aufgerufene Funktion zu
  reparieren.

Zwei weitere Funde geprüft, bewusst **nicht** verändert:

- **UI-38 (breiter, `statusline/utils/primitives.lua:88-167`):** die
  produktiv genutzten Git-/LSP-Icons im Default-Theme sind hartkodierte
  Nerd-Font-Codepoints ganz ohne `vim.g.have_nerd_font`-Gate — anders als
  der oben entfernte tote Code aber echter, seit Langem genutzter Pfad.
  Ein Fix bräuchte ein komplettes ASCII-Fallback-Glyphenset über
  potenziell jedes Icon-nutzende Modul (Statusline **und** Tabline/
  Devicons/Contextmenu) hinweg — ein eigener Design-/Umbau-Durchgang, kein
  Ein-Runden-Bugfix; nicht angefasst.
- **UI-20/UI-21 (`bindings/usrcmds/init.lua`):** Hilfetext, Completion-Liste
  und Dispatcher-`actions`-Tabelle sind drei unabhängig gepflegte Kopien
  derselben 13 Subcommands, statt über `lib.nvim.usercmd.composer` (Dispatch
  + Completion + Doku aus einer Struktur) zu laufen. Ein Umbau auf den
  Composer wäre eine Neuarchitektur des gesamten `:UI`-Dispatchers mit
  echtem Regressionsrisiko für ein funktionierendes, gut abgedecktes Modul
  — kein risikoarmer Ein-Runden-Fix; nicht angefasst.
- **UI-56 (`kit/preview.lua:170`, schwacher Randfall):** `M.render()`
  ersetzt bei jedem Tastendruck den kompletten Preview-Buffer-Inhalt ohne
  `winsaveview()`/Cursor-Erhalt. Geringe Praxisrelevanz (Theme-Gallery-
  Preview, kein Haupt-Editier-Fenster, selten gescrollt) — nicht angefasst.
- **UI-95 / `:Theme`-Alias** bereits in Runde 7 unter `LUA-95` bewertet und
  bewusst stehen gelassen (öffentlich dokumentiertes API, Breaking-Change-
  Risiko gegen spekulative Kollisionsgefahr).

---

## Runde 9 (2026-09-14): Familie `CMT` (16 Regeln)

Ein `Explore`-Subagent hat alle 16 `CMT-*`-IDs geprüft — alle 51 `---@class`-
Deklarationen im Baum gegen ihre jeweiligen `M`-Tabellen abgeglichen, jede
Zahlwort-/Aufzählungs-Stelle in Kommentaren gegen den echten Code geprüft,
`@module`-Pfade gegen echte `require`-Pfade, AI-Boilerplate/Smart-Quotes/
verwaiste Kommentare durchsucht. Die drei bereits in früheren Runden
gefixten Drifts (`chooser.lua` fünf Optionen, `keymaps/init.lua` neun
Aktionen, `DEFAULTS.lua` drei Gruppen) verifiziert — weiterhin korrekt.

Drei echte Funde, alle gefixt, luacheck/stylua grün, volle Testsuite grün,
committet + auf `main` gepusht (`37fedc1`):

- **`health.lua` `check_modules()`** (🟡 CMT-01, blinder Fleck in der
  Submodul-Enumeration): zählte von Hand nur `keymaps` und `usrcmds` auf,
  `menu` (`ui.contextmenu`) fehlte komplett — obwohl `Ui.Modules` es als
  dritten `ui.setup()`-Flag dokumentiert, `ui/init.lua` es tatsächlich
  verdrahtet, und `contextmenu.is_enabled()`s eigener Kommentar wörtlich
  sagt „For `:checkhealth` and tests" — health.lua ruft diese Funktion aber
  nirgends auf. Fix: dritten Eintrag ergänzt, der `require("ui.contextmenu")
  .is_enabled()` liest (kein `package.loaded`-Gate wie bei den anderen
  beiden, da `menu` ein Opt-**out** ist, das schon per Default an ist, nicht
  ein Opt-in, das `setup()` erst lädt — `require()` hier hat keinen
  Nebeneffekt, siehe Kommentar im Fix).
- **`contextmenu/@types/init.lua`** (🟡 CMT-02, `@class`-Drift): `Ui.
  ContextMenu` deklarierte nur 8 der 10 tatsächlich exportierten Funktionen
  — `set_enabled`/`is_enabled` fehlten, obwohl beide öffentliches, in
  `contextmenu/README.md` dokumentiertes API sind. Fix: beide `---@field`-
  Zeilen ergänzt.
- **`bindings/usrcmds/init.lua:577`** (🟢 CMT-05, veralteter Usercmd-`desc`):
  `:UI`s Beschreibungstext nannte nur die ursprünglichen zwei Subcommands
  (Theme, Transparenz), obwohl der Dispatcher inzwischen 13 abdeckt. Fix:
  Text auf `:UI help`-Verweis umgestellt statt alle 13 einzeln aufzuzählen
  (vermeidet die nächste Drift-Quelle).

Alles andere sauber: die übrigen 48 `@class`/`@field`-Paare, alle
`@module`-Pfade, `ui.tabline.modules`' "vier Schlüssel", die vier
Statusline-Presets, `ui.statusline.catalog` gegen das reale `modules/`-
Verzeichnis, AI-Boilerplate-Header, Smart Quotes/Mojibake, verwaiste
Kommentare.

---

## Runde 10 (2026-09-14): Familie `SEC` (29 Regeln)

Ein `Explore`-Subagent hat alle 27 zu prüfenden `SEC-*`-IDs geprüft (`SEC-01`/
`SEC-47` übersprungen — bereits automatisiert `pass`). Bestätigt: `ui.nvim`
ist reine Statusline/Tabline/Theme-UI ohne Downloadpfad, Secrets-Handling,
Server-Oberfläche oder persistierte Snapshots — 26 der 27 Regeln sauber
mangels Angriffsfläche. Die einzigen externen Prozessaufrufe sind reine
`git`-Argv-Aufrufe (Branch-Namen aus `git branch`-Output selbst — Git
verbietet Refs, die mit `-` beginnen, kein Argument-Injection-Vektor);
der einzige dynamische `vim.cmd(...)`-Stringbau (`variant/init.lua:29`)
speist sich ausschließlich aus einer geschlossenen, nur host-befüllten
Registry (`ui.config.variants.list()`), nicht aus Nutzer-Freitext.

Ein echter Fund, dokumentiert statt architektonisch verändert, luacheck/
stylua grün, volle Testsuite grün, committet + auf `main` gepusht
(`834c343`):

- **`kit/preview.lua`** (🔴 SEC-50, "Preview führt aus statt zu lesen" —
  plausibel, kein akuter Exploit): `:KitPreview`s Config-Buffer wird bei
  **jedem** `TextChanged`/`TextChangedI` komplett per `loadstring()` +
  `pcall()` ausgeführt, ganz ohne Opt-in oder sichtbare Warnung, dass der
  Bufferinhalt Code ist. Fügt ein Nutzer einen Codeschnipsel aus einer
  ungeprüften Quelle ein ("füg das hier ein für ein cooles Theme"), läuft
  er sofort mit vollem `vim.*`/`os.*`-Zugriff — anders als bei bewusster
  `:lua`-Eingabe im Kommandozeilenmodus passiert das schon beim bloßen
  Tippen/Einfügen. Bewusst **nicht** architektonisch verändert: die
  Live-Auswertung ist der eigentliche Zweck dieses Tools (ein REPL-artiger
  Theme-Playground, kein Preview von tatsächlich fremdem/externem Inhalt —
  der Nutzer befüllt den Buffer selbst, lokal, nach explizitem `:KitPreview`-
  Aufruf), ein Wechsel auf einen expliziten Trigger („updates as you type"
  ist der dokumentierte Kernpunkt) wäre ein Verhaltensumbau, kein Bugfix.
  Fix: sichtbare Warnzeile im in-Buffer-`REFERENCE`-Block ergänzt ("this
  buffer's contents are executed as Lua on every edit… never paste in a
  config snippet from a source you have not read").

---

## Runde 11 (2026-09-15): Familie `PRIN` (37 Regeln)

Ein `Explore`-Subagent hat alle 37 `PRIN`-IDs einzeln gegen `PRINCIPLES.md`
nachgeschlagen und per Ermessen geprüft (gezielte Greps/Reads, nicht alle
93 Dateien komplett gelesen). Architektur-Grundprinzipien (Modul-/
Funktionsverantwortung, Kopplung/Kohäsion, reine Funktionen, private
Helfer, Registries, Snapshot/Restore, globaler State, Fehlerbehandlungs-
philosophie, Naming, Caching-Disziplin, Doku-Verträge) sind über die
weit überwiegende Mehrheit der 37 Regeln sauber — `PRIN-13` (Snapshot/
Restore) wurde sogar als Positivbeispiel identifiziert
(`config/init.lua`s `__save_state()`/`__restore_state()`, aus einem
früheren echten Bugfix entstanden). `PRIN-29` (native Crashes) mangels
FFI/Nativecode im Baum moot.

Zwei echte Funde, beide gefixt, luacheck/stylua grün, volle Testsuite
grün, committet + auf `main` gepusht (`cbfc489`):

- **`bindings/usrcmds/init.lua`** (🟡 PRIN-03, Duplizierte Dispatch-/
  Completion-Tabellen): der `actions`-Table im Dispatcher und die
  `subcommands`-Liste in `complete()` waren zwei unabhängig gepflegte
  Literal-Arrays derselben 13 Subcommand-Namen — anders als `variant`/
  `tabline-style`, die für ihre *zweite* Ebene bereits live aus der
  jeweiligen Registry (`.list()`) lesen, blieben die 13 Top-Level-Namen
  zwei disjunkte Kopien. Ein neuer Subcommand in der einen Tabelle ohne
  die andere hätte entweder Dispatch ohne Completion oder Completion ohne
  Dispatch (`"Unbekannter Befehl"`) ergeben. Fix: beide Stellen lesen jetzt
  aus einer einzigen geordneten `SUBCOMMANDS`-Registry (`{name, fn}`-Paare),
  aus der `actions` (Dispatch-Map) und `subcommand_names` (Completion-Liste)
  abgeleitet werden — strukturell nicht mehr divergierbar. Bewusst *nicht*
  der größere `usrcmds.README`/Composer-Umbau aus Runde 8 (UI-20/UI-21) —
  dieser Fix behebt exakt die PRIN-03-Divergenzgefahr, ohne den
  Dispatcher-Aufbau neu zu architektieren.
- **`statusline/modules/lsp/init.lua`** (🟢 PRIN-51, fehlender Doku-Vertrag):
  `M.mode_band_group()` und `M.render_breadcrumbs_lspfirst()` waren die
  einzigen zwei von 93 Dateien gefundenen öffentlichen Funktionen ganz ohne
  `---@return`, während ihre direkten Nachbarn in derselben Datei
  (`M.hl_open`, `M.render_breadcrumbs_inherit_lspfirst`) bereits annotiert
  sind. Fix: `---@return string` bei beiden ergänzt.

Alles andere in `PRIN` sauber bzw. mangels Angriffsfläche moot (keine
`_G.*`-Nutzung, kein verstecktes globales `vim.g.*`-Ownership, Caching
durchgängig explizit benannt und mit Invalidierungspfad — bereits in
Runde 2 vertieft geprüft, jede der 93 Dateien mit Kopf-Kommentar,
`@types`-Auslagerung durchgängig genutzt).

---

