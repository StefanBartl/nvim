# `rules.nvim` gegen `ui.nvim`: erster Lauf, nur Bericht

> **Zweck dieser Datei:** `rules.nvim` (das Regel-Engine-Plugin,
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
[rules-nvim-on-ui-nvim.json](rules-nvim-on-ui-nvim.json) neben diesem
Report.
