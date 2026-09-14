# `rules.nvim` gegen `ui.nvim`: Report + laufende Handover-Akte

> **Ausnahme-Standort:** normalerweise leben Plugin-Roadmaps im Wkdbook
> (`wkdbook-myplugins/ui.nvim/{ROADMAP,handovers}`). Diese Datei ist explizit
> als laufende Handover-Akte für den `rules.nvim`-Review-Durchgang gegen
> `ui.nvim` angefordert und bleibt hier (`nvim/docs/ROADMAP/handovers/`),
> ursprünglich aus `reports/` hierher verschoben (2026-09-14).

## Table of content

- [Teil 1 — erster Lauf, nur Bericht (2026-09-14)](#1-was-rulesnvim-hier-tut)
- [Manueller Teil — Schnell-Check (2026-09-14 ff.)](#manueller-teil-schnell-check-2026-09-14)

## Regeln für diese Session

- Nie mehr als 1 Agent gleichzeitig; bei Bedarf mehrere Runden á 1 Agent.
- Antworten Deutsch, Quellcode (inkl. Kommentare) Englisch.
- Keine Co-Autorenschaft von Claude in Commits.
- Nach jedem fertigen Schritt: committen/pushen/pullen, main bleibt aktuell.
- Docs/README aktualisieren, sofern sinnvoll.
- Code muss luacheck/stylua-grün sein.
- `TOOL-PLACEMENT.md` / `HEREDOC.md` beachten, falls Nebenbei-Tooling entsteht.

## Orte

| Was | Wo |
|---|---|
| Diese Handover-Datei | `nvim/docs/ROADMAP/handovers/rules-nvim-on-ui-nvim.md` |
| Rohdaten (JSON) des ersten Laufs | `nvim/docs/ROADMAP/reports/rules-nvim-on-ui-nvim.json` |
| `ui.nvim`-Repo (Arbeits-Worktree) | `E:\repos\ui.nvim\.claude\worktrees\roadmap-regeln-nvim-manual-0f8fb4` |
| `rules.nvim`-Engine | `E:\repos\rules.nvim` |
| Regelwerk (Quelle) | `E:\repos\WKDBooks\Development\wkdbook-Lua\Checklists` |
| Schnell-Check (10 Punkte) | `.../Checklists/gates/REVIEW.md` |

---

# Teil 1 — erster Lauf, nur Bericht (2026-09-14)

> **Zweck dieses Teils:** `rules.nvim` (das Regel-Engine-Plugin,
> `E:\repos\rules.nvim`) einmal headless gegen den aktuellen `ui.nvim`-Stand
> laufen lassen und das Ergebnis dokumentieren — **keine** Regel wurde in
> diesem Durchgang bearbeitet, kein Code geändert. Stand 2026-09-14, Commit
> `339955d` (nach dem Kreuzfeature-Check-Durchgang, siehe
> [ui-nvim-cross-feature-check.md](ui-nvim-cross-feature-check.md)).

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

### Die vier automatisierten Treffer — alle grün

| ID | Schweregrad | Titel | Ergebnis |
| --- | --- | --- | --- |
| `SEC-01` | 🔴 kritisch | Argv statt Shell-String | ✅ pass — kein `os.execute(`/`io.popen(` im Baum |
| `UI-62` | 🔴 kritisch | Der Healthcheck liegt unter `lua/<modul>/health.lua` | ✅ pass — `lua/ui/health.lua` existiert |
| `LUA-80` | 🟡 empfohlen | Explizite Dateien für pluginseitige Defaults | ✅ pass — `lua/ui/config/DEFAULTS.lua` existiert |
| `SEC-47` | 🟡 empfohlen | Temp-Dateien nur über `vim.fn.tempname()` | ✅ pass — kein manuelles Temp-Datei-Pattern gefunden |

Das ist die ganze mechanisch prüfbare Oberfläche des Review-Gates gegen
diesen Codebestand — kein Fund, keine Handlung nötig.

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

## 5. Nicht Teil dieses Durchgangs

- Keine der 277 manuellen Regeln wurde gegen `ui.nvim`s Code geprüft — das
  wäre ein eigener, deutlich größerer Durchgang (im Kern eine
  Ermessens-Review des ganzen Quellbaums gegen 277 Punkte).
- Kein Code wurde geändert, kein `.rules-waivers.json` angelegt.
- `:Rules gate review` interaktiv (mit lesbarem Buffer-Report und
  Sprungmarken zu jeder Regelquelle) wurde nicht geöffnet — nur die
  headless/JSON-Variante, passend zu "erstmal nur der Report".

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
[rules-nvim-on-ui-nvim.json](../reports/rules-nvim-on-ui-nvim.json) im
`reports/`-Ordner (nur die Report-Prosa ist hierher in `handovers/`
umgezogen, siehe [Manueller Teil](#manueller-teil-schnell-check-2026-09-14)
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

## Fortschritt

| Bereich | Status |
| --- | --- |
| `lua/ui/kit/` (20 Dateien, geteiltes Toolkit) + `lua/ui/contextmenu/` | ✅ Runde 1 fertig, 3 Fixes committet (`5a1f510`) |
| `lua/ui/statusline/` (Module, Renderer) | ✅ Runde 2 fertig, 4 Fixes committet (`97953f5`) |
| `lua/ui/tabline/`, `lua/ui/bindings/` | offen |
| `lua/ui/config/`, `lua/ui/highlights/`, `lua/ui/@types/` | offen |
| Rest (`init.lua`, `health.lua`) | offen |

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

