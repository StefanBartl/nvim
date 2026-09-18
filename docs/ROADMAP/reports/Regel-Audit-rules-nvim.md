# Regel-Audit aller `.nvim`-Plugins mit `rules.nvim` — Statusreport

> Stand: 2026-09-18. Lauf über **alle 38 `.nvim`-Repos** unter `$REPOS_DIR` gegen den
> vollständigen Regelkatalog aus
> `$REPOS_DIR/WKDBooks/Development/wkdbook-Lua/Checklists`
> (421 Regeln, 13 Familien), gefahren über die programmatische API von `rules.nvim`
> (`check_family_json`) plus einer Agent-Runde für die nicht-automatisierbaren Regeln.
>
> **Dieser Report setzt nichts um.** Er ist die Befundlage; jeder Fix ist ein eigener Task.

## Table of content

  - [Kurzfassung](#kurzfassung)
  - [Was geprüft wurde und was nicht](#was-geprft-wurde-und-was-nicht)
  - [Teil 1 — Automatische Regeln: 66 Treffer, 10 echte](#teil-1--automatische-regeln-66-treffer-10-echte)
    - [Befund je Regel](#befund-je-regel)
    - [Defekte in den Checks selbst](#defekte-in-den-checks-selbst)
  - [Teil 2 — Bug in `rules.nvim`: Worktrees werden mitgescannt](#teil-2--bug-in-rulesnvim-worktrees-werden-mitgescannt)
  - [Teil 3 — Manuelle Regeln: Befunde je Plugin](#teil-3--manuelle-regeln-befunde-je-plugin)
    - [Die fünf systematischen Muster](#die-fnf-systematischen-muster)
    - [Befunde je Plugin](#befunde-je-plugin)
    - [Was dieser Lauf nicht abdeckt](#was-dieser-lauf-nicht-abdeckt)
  - [Teil 4 — Priorisierte Arbeitsliste](#teil-4--priorisierte-arbeitsliste)
  - [Anhang — Reproduktion](#anhang--reproduktion)

---

## Kurzfassung

Vier Ergebnisse, in absteigender Wichtigkeit:

1. **21 Plugins führen an 37 Stellen Shell-Kommandos aus einer Pfadeingabe aus.**
   `vim.fn.expand()` wertet Backtick-Spans über `&shell` aus; wo das Argument aus einem
   `:Command`-Argument oder einem `vim.ui.input`-Prompt stammt, ist das ein direkter
   Ausführungspfad (`SEC-34`). Der Ersatz existiert seit Langem und wird von 15 der 38
   Repos schon benutzt: `lib.nvim.cross.fs.expand_path` expandiert `~`/`$VAR`/`%VAR%` rein
   als String. Die Migration ist begonnen und nicht zu Ende geführt.
2. **497 bestätigte Regelverstöße über alle 38 Plugins**, aus 541 Rohbefunden nach
   adversarialer Gegenprüfung. Kein Plugin ist sauber. 52% davon sind Fehlerbehandlung
   (ERR), und fünf Regeln erklären 173 der Befunde — es sind also nicht 497 Einzelfehler,
   sondern wenige Gewohnheiten, die sich fleet-weit wiederholen.
3. **Die automatischen Checks produzieren zu 85% Fehlalarme.** 66 Treffer über 38 Repos,
   davon halten 10 einer Prüfung stand. Das liegt nicht an den Plugins, sondern an sechs
   konkreten Defekten in den Checks selbst — vier davon sind eine Zeile im Ruleset.
   Solange die drin sind, ist `:Rules check` als Gate unbenutzbar: wer 26 rote `NEW-49`
   sieht, von denen keiner echt ist, hört auf hinzuschauen. Bitter dabei: `SEC-01` meldet
   fünf Fehlalarme und übersieht den einzigen echten Shell-String-Aufruf im ganzen Fleet
   (`lsp.nvim/lua/lsp/languages/app/dart.lua:81`).
4. **`rules.nvim` scannt `.claude/worktrees/` mit.** `SKIP_DIRS` in `fswalk.lua:20` kennt
   nur `.git` und `.deps`. Jeder Fund wird einmal pro offenem Worktree zusätzlich gezählt —
   gemessen 81 von 134 Treffern der grep-Regeln (60%), bei `documentation.nvim` 68
   `SEC-01`-Treffer statt 17. Ein `:cnext` landet dabei im Arbeitsstand einer fremden
   Session.

Zur Einordnung: 389 der 421 Regeln haben per Design keinen automatischen Verdict.
`:Rules gate review` umfasst 281 Regeln und liefert davon genau **4** Verdikte plus 277
Worklist-Zeilen. Der Katalog ist also zum ganz überwiegenden Teil Handarbeit — Teil 3
dieses Reports ist der erste Durchgang davon.

---

## Was geprüft wurde und was nicht

| | Regeln | Repos | Abdeckung |
|---|---|---|---|
| Automatische Checks | 32 / 32 | 38 / 38 | **vollständig** |
| Manuelle Regeln, `severity = critical` | 76 / 111 | 38 / 38 | vollständig für die review-relevanten Familien |
| Manuelle Regeln, `recommended` / `nice-to-have` | 0 / 313 | — | **nicht geprüft** |

Die 76 geprüften manuellen Regeln sind alle `critical`-Regeln der Familien ERR, LUA, SEC,
XP, PERF, PRIN, UI, CMT, TS, LLS und DEP. Ausgenommen sind die 35 `critical`-Regeln der
Gate-Familien NEW und REL: die gelten beim Projektstart bzw. beim Release, nicht im
laufenden Betrieb, und ihr automatisierter Teil ist in Teil 1 mit drin.

Die restlichen 313 manuellen Regeln (`recommended`/`nice-to-have`) sind **offen**. Sie
einzeln über 38 Repos zu prüfen wäre ein Vielfaches dieses Laufs; sie gehören in eigene,
familienweise Runden.

### Regelkatalog nach Familie

| Familie | gesamt | automatisiert | manuell | davon critical |
|---|---:|---:|---:|---:|
| PERF | 64 | 0 | 64 | 10 |
| LUA | 59 | 1 | 58 | 14 |
| NEW | 50 | 14 | 36 | 18 |
| UI | 41 | 1 | 40 | 4 |
| LLS | 37 | 0 | 37 | 1 |
| PRIN | 37 | 0 | 37 | 6 |
| ERR | 35 | 0 | 35 | 16 |
| REL | 34 | 8 | 26 | 15 |
| SEC | 29 | 2 | 27 | 18 |
| CMT | 16 | 0 | 16 | 1 |
| DEP | 7 | 6 | 1 | 0 |
| XP | 7 | 0 | 7 | 7 |
| TS | 5 | 0 | 5 | 1 |
| **Summe** | **421** | **32** | **389** | **111** |

Die konfigurierten Gates:

| Gate | Regeln | automatisiert | Anteil |
|---|---:|---:|---:|
| `new_project` | 50 | 14 | 28% |
| `release` | 34 | 8 | 24% |
| `review` | 281 | 4 | **1%** |

---

## Teil 1 — Automatische Regeln: 66 Treffer, 10 echte

Alle 32 automatisierten Regeln liefen gegen alle 38 Repos. Nach Abzug der
Worktree-Duplikate (siehe Teil 2) bleiben 66 Treffer. Davon halten 10 einer Prüfung am
Quelltext stand.

Ein „Treffer" ist ein Regel/Repo-Paar: die Regel schlug in diesem Repo an, unabhängig
davon, wie viele Fundstellen sie dort meldete.

| Regel | Severity | Repos | echt | Rauschen |
|---|---|---:|---:|---:|
| `NEW-49` | recommended | 26 | **0** | 26 |
| `NEW-08` | recommended | 15 | 8 | 7 |
| `NEW-45` | recommended | 7 | **0** | 7 |
| `DEP-01` | recommended | 6 | **0** | 6 |
| `SEC-01` | **critical** | 5 | **0** | 5 |
| `DEP-02` | recommended | 3 | **0** | 3 |
| `REL-29` | **critical** | 2 | 2 | 0 |
| `NEW-48` | **critical** | 2 | **0** | 2 |
| **Summe** | | **66** | **10** | **56** |

Bemerkenswert: **jeder einzelne `critical`-Treffer außer `REL-29` ist ein Fehlalarm.**

### Befund je Regel

#### `NEW-49` — `.luacheckrc`: busted-`std` deklarieren · 26 Treffer, 0 echt

Der Check liest `.luacheckrc` und meldet, wenn der String `busted` fehlt. Alle 38 Repos
haben eine `.luacheckrc`; 26 nennen `busted` nicht.

Nachgeprüft, ob das Repo busted-Syntax (`describe(`/`it(`) in `TESTS/` überhaupt benutzt:

- **25 Repos benutzen kein busted.** Sie haben eigene Harnesses (`H.eq`, `check()`,
  eigenständige `TESTS/*.lua`-Skripte). Für sie ist die Regel gegenstandslos.
- **`hover.nvim`** benutzt busted-Syntax, deklariert aber keinen `std` — es schließt
  stattdessen `exclude_files = { "TESTS/*.lua" }` aus. luacheck ist dort grün, weil die
  Tests gar nicht geprüft werden.

Damit ist kein Treffer ein echter Lint-Fehler. `hover.nvim` ist der einzige, über den man
reden kann: `exclude_files` ist die schwächere Lösung (ungelintete Tests) gegenüber
`std = "busted"` (gelintete Tests mit bekannten Globals). Das ist eine
Konventionsentscheidung, kein Bug.

#### `NEW-08` — `/bindings`-Ordner mit `keymaps`/`usrcmds`/`autocmds` · 15 Treffer, 8 echt

Der einzige automatische Check mit nennenswerter Trefferquote — nach Korrektur des Globs.
Der Check sucht ausschließlich `lua/*/bindings/<name>.lua` und übersieht zwei im Fleet
verbreitete Formen:

- die **Verzeichnisform** `lua/*/bindings/usrcmds/` (nutzt `documentation`, `github_stats`,
  `my`, `ui`, `sandbox`, `dap`)
- die **Namensvariante** `usercmds.lua` statt `usrcmds.lua` (nutzt `debugging`, `dap`)

Nach Korrektur beider Formen ergibt sich der tatsächliche Stand:

| Plugin | keymaps | usrcmds | autocmds | Bewertung |
|---|:---:|:---:|:---:|---|
| `dap.nvim` | ✅ | ✅ | ✅ | Fehlalarm |
| `debugging.nvim` | ✅ | ✅ | ✅ | Fehlalarm |
| `documentation.nvim` | ✅ | ✅ | ✅ | Fehlalarm |
| `github_stats.nvim` | ✅ | ✅ | ✅ | Fehlalarm |
| `language.nvim` | ✅ | ✅ | ✅ | Fehlalarm |
| `my.nvim` | ✅ | ✅ | ✅ | Fehlalarm |
| `sessions.nvim` | ✅ | ✅ | ✅ | Fehlalarm |
| `filetree.nvim` | ✅ | ❌ | ✅ | echt |
| `mdview.nvim` | ❌ | ✅ | ✅ | echt |
| `open.nvim` | ✅ | ✅ | ❌ | echt |
| `ui.nvim` | ✅ | ✅ | ❌ | echt |
| `rules.nvim` | ❌ | ✅ | ❌ | echt |
| `runtime-analysis.nvim` | ❌ | ✅ | ❌ | echt |
| `sandbox.nvim` | ❌ | ✅ | ❌ | echt |
| `lib.nvim` | ❌ | ❌ | ❌ | echt |

Auch die acht echten brauchen Judgment: ein Plugin ohne Autocommand-Bedarf braucht keine
`autocmds.lua`. Der Check misst Struktur, nicht Bedarf — das ist bei einer
`recommended`-Strukturregel vertretbar, macht ihn aber zum Worklist-Eintrag, nicht zum
Gate-Kriterium.

#### `NEW-45` — `stylua.toml` im Repo · 7 Treffer, 0 echt

`check = { type = "file_exists", path = "stylua.toml" }`. Alle sieben gemeldeten Repos
(`buffer-ctx`, `color_my_ascii`, `documentation`, `gopath`, `hover`, `lib`,
`runtime-analysis`) haben eine **`.stylua.toml`** — mit führendem Punkt. Stylua akzeptiert
beide Namen; der Check kennt nur einen. Alle sieben haben zusätzlich ein grünes
stylua-Gate in ihrer CI, das ohne Config gar nicht so laufen würde.

#### `DEP-01` — `vim.loop` → `vim.uv` · 6 Treffer, 0 echt

`check = { type = "grep", pattern = "vim%.loop%.", unless = "vim%.uv or vim%.loop" }`.
Die `unless`-Klausel matcht nur die wörtliche Form `vim.uv or vim.loop`. Die im Fleet
tatsächlich verwendete Form ist eine andere:

| Repo | Fundstelle | Bewertung |
|---|---|---|
| `lib.nvim` | `lua/lib/nvim/cross/fs/expand_path/init.lua:16` — `vim.uv and vim.uv.os_homedir() or vim.loop.os_homedir()` | korrekt gegatet, `unless` greift nicht |
| `ui.nvim` | `TESTS/bugfix_regressions_spec.lua:83` — `vim.uv.os_homedir() or vim.loop.os_homedir()` | korrekt gegatet, Testcode |
| `documentation.nvim` | `TESTS/browse_rules_spec.lua:169` — String-Literal in `writefile` | Fixture, kein Aufruf |
| `gopath.nvim` | `resolvers/common/help.lua:2,50` (Doc-Kommentare), `scripts/ci/specs/…:604` (Fixture-String) | kein Aufruf |
| `lsp.nvim` | `TESTS/lsp/*_spec.lua` (6×) — Monkey-Patching von `vim.loop.os_uname` | Testcode, absichtlich |
| `data.nvim` | `TESTS/usrcmds_io_spec.lua:311,313` — `vim.loop.hrtime()` ohne Fallback | Testcode, einziger ungegateter Aufruf |

Produktionscode: eine einzige Fundstelle (`lib.nvim`), und die ist korrekt.

#### `SEC-01` — Argv statt Shell-String · 5 Treffer, 0 echt

`check = { type = "grep", patterns = { "os%.execute%(", "io%.popen%(" } }`. Die Regel
verlangt `vim.system({...})`. Die Treffer:

| Repo | Fundstellen | Bewertung |
|---|---|---|
| `documentation.nvim` | 8× in `scripts/package.lua`, `scripts/bundle_manifest.lua`, `standalone/docmap.lua` | **läuft unter PUC Lua, nicht Neovim** — `vim.system()` existiert dort nicht |
| `documentation.nvim` | 9× in `TESTS/*_spec.lua` (`rm -rf` auf Fixtures) | Testcode |
| `filetree.nvim` | `features/fileops/trash/platform.lua:91` | **Kommentar**: „This used to be an `os.execute()` shell string" |
| `lib.nvim` | `TESTS/deps_spec.lua:766` | Testcode |
| `mdview.nvim` | `TESTS/nvim/{browser,server}_args_spec.lua` | Testcode |
| `runtime-analysis.nvim` | `TESTS/setup_all_spec.lua:210` | Testcode |

Der wichtigste Punkt: `documentation.nvim`s `scripts/` und `standalone/` sind explizit
Neovim-freie PUC-Lua-Programme (im Dateikopf so dokumentiert). Dort ist `io.popen` nicht
die schlechtere von zwei Optionen, sondern die einzige.

#### `DEP-02` — `termopen()` → `jobstart(cmd, { term = true })` · 3 Treffer, 0 echt

Alle drei Fundstellen sind bereits korrekt versionsgegatete Fallbacks im `else`-Zweig,
jeweils mit `---@diagnostic disable-next-line: deprecated`:

- `debugging.nvim` — `tools/proc_trace.lua:146`
- `filetree.nvim` — `features/system/shell_run/init.lua:76`, mit ausführlicher Begründung
  im Kommentar („deprecated since 0.11 … README promises 0.10, so the old call stays")
- `sandbox.nvim` — 4× in den `adapters/{docker,nerdctl,podman,wsl}/…/exec_in_container.lua`

Dass `filetree.nvim` hier meldet, ist im Ruleset seit 2026-09-05 sogar als bekannter
Fehlalarm dokumentiert — der Beleg-Absatz zu `DEP-02` nennt ihn ausdrücklich.

#### `NEW-48` — Testdateien nie unter `lua/<plugin>/` · 2 Treffer, 0 echt

`vim.fn.glob(root .. "/lua/**/*_spec.lua")`. Beide Treffer sind keine Testdateien:

- `pickers.nvim/lua/pickers/plugin_spec.lua` — eine **lazy.nvim-Plugin-Spec**
  (`require("pickers").plugin_spec()`), die absichtlich zur Laufzeit erreichbar sein muss.
- `filetree.nvim/lua/filetree/assets/templates/lua_spec.lua` — ein **Template** mit
  `${module}`/`${filename}`-Platzhaltern, das der Generator ausliefert. Keine lauffähige
  Datei.

Das Wort „spec" ist im Lua-Ökosystem doppelt belegt (Test-Spec vs. Plugin-Spec); ein
reiner Dateinamens-Glob kann die beiden nicht trennen.

#### `REL-29` — Alles committet und gepusht · 2 Treffer, 2 echt

Der einzige Check, der sauber trifft — er misst allerdings den Arbeitsstand zum
Scanzeitpunkt, nicht die Codequalität:

- `casedesk.nvim` — uncommitted: `lua/casedesk/ui/cases.lua`, `lua/casedesk/ui/infocard.lua` u. a.
- `ui.nvim` — uncommitted: `TESTS/ui_kit_spec.lua`

### Defekte in den Checks selbst

Sechs Einzeiler im Ruleset, die zusammen 56 der 66 Treffer erzeugen:

| Regel | Defekt | Fix-Richtung |
|---|---|---|
| `NEW-49` | prüft `busted`-String, ohne zu prüfen ob das Repo busted nutzt; kennt `exclude_files` nicht | Vorbedingung ergänzen: nur prüfen, wenn `TESTS/` busted-Syntax enthält und nicht ausgeschlossen ist |
| `NEW-45` | nur `stylua.toml` | auch `.stylua.toml` akzeptieren |
| `NEW-08` | Glob nur `bindings/<name>.lua` | auch `bindings/<name>/` und `usercmds.lua` |
| `NEW-48` | jede `*_spec.lua` unter `lua/` gilt als Test | Inhalt prüfen (`describe(`/`it(`) statt nur den Namen |
| `DEP-01` | `unless` matcht nur wörtlich `vim.uv or vim.loop` | Muster auf `vim%.uv` in derselben Zeile lockern |
| `SEC-01`, `DEP-02` | kein Kontext: trifft Kommentare, Fixtures, gegatete Fallbacks, Neovim-freien Code | `exclude_paths` (TESTS/, scripts/, standalone/) im grep-Primitive; gegatete Zweige bleiben Handarbeit |

Die drei letzten sind keine reinen Check-Bugs, sondern die dokumentierte Grenze eines
grep-Primitives — `rules.nvim` sagt selbst, dass ein Check „den Kontext nicht bewertet".
Der praktikable Weg dafür ist nicht ein schlauerer Check, sondern
**`.rules-waivers.json` je Repo**. Aktuell hat genau ein Repo eine solche Datei:
`rules.nvim` selbst.
---

## Teil 2 — Bug in `rules.nvim`: Worktrees werden mitgescannt

`lua/rules/engine/fswalk.lua:20`:

```lua
---@type string[]
local SKIP_DIRS = { ".git", ".deps" }
```

`.claude/worktrees/` fehlt. Jede Claude-Code-Session legt dort einen vollständigen
zweiten Checkout des Repos an — der Walk läuft hinein, und jede Fundstelle wird einmal
pro offenem Worktree zusätzlich gemeldet.

Gemessen über die vier grep-basierten Regeln (`SEC-01`, `DEP-01`, `DEP-02` und deren
Muster), Fundstellen mit und ohne `.claude/`:

| Plugin | mit Worktrees | echte | Duplikate | offene Worktrees |
|---|---:|---:|---:|---:|
| `documentation.nvim` | 72 | 18 | **54** | 4 |
| `lsp.nvim` | 12 | 6 | 6 | 1 |
| `filetree.nvim` | 8 | 4 | 4 | 1 |
| `gopath.nvim` | 7 | 3 | 4 | 2 |
| `lib.nvim` | 6 | 2 | 4 | 2 |
| `ui.nvim` | 4 | 1 | 3 | 3 |
| `data.nvim` | 4 | 2 | 2 | 2 |
| `mdview.nvim` | 4 | 2 | 2 | 1 |
| `runtime-analysis.nvim` | 3 | 1 | 2 | 2 |
| **Summe** | **134** | **53** | **81 (60%)** | |

Drei Folgen, jede für sich ein Grund zu fixen:

1. **Die Zahlen sind falsch, und zwar nach oben.** `documentation.nvim` meldet 68
   `SEC-01`-Treffer; echte gibt es 17. Ein Report, dessen Zahl mit der Anzahl offener
   Agent-Sessions schwankt, ist als Gate wertlos.
2. **Der Quickfix-Worklist schickt einen in fremde Arbeitsstände.** Ein `:cnext` landet in
   `…/.claude/worktrees/agitated-faraday-5c07a3/scripts/package.lua` — einem Checkout, der
   zu einer anderen Session gehört. Wer dort editiert, verliert die Änderung beim Aufräumen
   des Worktrees.
3. **Der Walk kostet unnötig Zeit.** Bei vier offenen Worktrees liest `check_family` das
   Repo fünfmal.

Der Fix ist eine Zeile — `.claude` in `SKIP_DIRS` — und würde nebenbei auch `.claude/`s
übrige Inhalte (Session-Transkripte, Scratchpads) aus dem Walk nehmen. Sinnvoll wäre, bei
der Gelegenheit die Liste an den ohnehin vorhandenen zentralen Ignore-Katalog zu hängen:
`lib.nvim.fs.ignore.list` wird in der Plugin-Spec bereits für genau diesen Zweck benutzt
(`neotree-fs-refactor`, `ignore_patterns`), und `fswalk.lua` ruft mit
`lib.nvim.fs.collect_recursive` schon ein Nachbarmodul desselben Namensraums auf.
---

## Teil 3 — Manuelle Regeln: Befunde je Plugin

Für die 389 Regeln ohne automatischen Verdict gibt `rules.nvim` per Definition nur eine
Worklist aus. Dieser Lauf hat die **76 `critical`-Regeln** davon tatsächlich abgearbeitet:
pro Plugin ein Agent, der den Regeltext liest, den Quelltext prüft und jeden Befund mit
Datei und Zeile belegt; danach ein zweiter Agent pro Plugin, der jeden Befund zu
**widerlegen** versucht.

- 541 Rohbefunde, **497 bestätigt**, 44 widerlegt (8%).
- 252 mit `confidence = high` (am Quelltext eindeutig), 233 `medium`, 12 `low`.
- 486 im Produktionscode, 11 in Testcode.
- 38 von 38 Plugins haben mindestens einen Befund; keines ist sauber.

> **Zur Widerlegungsquote.** 8% ist niedrig für eine adversariale Runde. Zwei Gründe, die
> beide zutreffen dürften: die Auditoren mussten jeden Befund schon selbst am Quelltext
> belegen, und der Prüfer beurteilte alle Befunde eines Plugins in einem Durchgang statt
> jeden einzeln. Die Prüfer haben in vielen Fällen nicht widerlegt, sondern **die
> Auswirkung korrigiert** — bei `ai.nvim`s ERR-03 etwa den Befund bestätigt, aber die
> Behauptung „das Panel meldet Erfolg" als falsch nachgewiesen. Diese Korrekturen stehen
> im Anhang. Die `medium`-Befunde sollten vor einem Fix trotzdem einzeln nachgeprüft
> werden.

Die vollständige Liste aller 497 Befunde mit Belegen steht in
**[`Regel-Audit-Befunde.md`](Regel-Audit-Befunde.md)** (ein Abschnitt je Plugin).

### Verteilung nach Familie

| Familie | Befunde | Anteil |
|---|---:|---:|
| ERR — Fehlerbehandlung & Rückgabewerte | 259 | 52% |
| SEC — Sicherheit | 77 | 15% |
| LUA — Lua/Neovim-Fallstricke | 61 | 12% |
| PERF — Performance | 36 | 7% |
| PRIN — Prinzipien | 21 | 4% |
| LLS — LuaLS-Diagnosen | 21 | 4% |
| XP — Cross-Platform | 15 | 3% |
| UI — Oberfläche | 7 | 1% |

### Die fünf systematischen Muster

Diese fünf Regeln erklären zusammen 173 der 497 Befunde. Sie sind nicht 173 Einzelfehler,
sondern fünf Gewohnheiten, die sich über das ganze Fleet wiederholen — und genau deshalb
zentral behebbar.

#### 1. `SEC-34` — `vim.fn.expand()` auf Nutzertext · 21 Repos, 37 Stellen

**Der schwerwiegendste Befund des Laufs, und der mit dem einfachsten Wurzel-Fix.**

`vim.fn.expand()` führt Backtick-Spans über `&shell` aus. Wo das Argument aus einem
Command-Argument oder einem `vim.ui.input`-Prompt kommt, ist das ein direkter
Kommandoausführungs-Pfad aus einer harmlos aussehenden Pfadeingabe:

| Plugin | Fundstelle | Eingangskanal |
|---|---|---|
| `buffer-ctx.nvim` | `format/table_fmt.lua:165` | `:Format table scope=<…>` |
| `casedesk.nvim` | `ui/copy.lua:27` | `:Case copy <src>` bzw. Prompt „Source file" |
| `cmdlog.nvim` | `core/favorites.lua:205`, `:185` | `:Cmdlog import/export <path>` |
| `color_my_ascii.nvim` | `commands/fence/export.lua:165` | `:Fence export <path>` bzw. Prompt |
| `diff.nvim` | `core/resolve.lua:127` (+3) | Pfadargumente |
| `insights.nvim` | `bindings/usrcmds.lua:283` (+2) | Command-Argument |
| `media.nvim` | `bindings/usrcmds.lua:53` (+2) | Command-Argument |
| … | | 21 Repos insgesamt, siehe Anhang |

**Der Ersatz existiert schon.** `lib.nvim.cross.fs.expand_path`
(`lua/lib/nvim/cross/fs/expand_path/init.lua`) expandiert `~`, `$VAR`, `${VAR}` und
`%VAR%` als **reine String-Operation** — keine Shell, keine Backticks, kein `*`/`?`.
Genau der Ersatz, den diese 37 Stellen brauchen.

15 der 38 Repos benutzen ihn bereits (`lib`, `ui`, `reposcope`, `open`, `pickers`,
`cmdlog`, `filetree`, `insights`, `mdview`, `images`, `markdown`, `replacer`, `sessions`,
`fileops`, `gopath`). Die Migration läuft also, sie ist nur nicht zu Ende geführt. Von
141 `vim.fn.expand`-Aufrufen im Produktionscode sind 37 als Verstoß bestätigt; der Rest
läuft auf konstanten oder Vim-internen Strings (`expand("%:p")` und Verwandte) und ist
unbedenklich.

#### 2. `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln" · 30 Repos, 52 Stellen

Die breiteste Klasse — und das Ruleset benennt sie selbst als „häufigste reale Bugklasse
eines ganzen 32-Repo-Sweeps (2026-09-07)". Sie ist also nicht neu, sondern **nachweislich
nicht ausgetrocknet**: der damalige Sweep fand vier Load-Modify-Save-Kollapse und fixte
sie an der Wurzel in `lib.nvim`s `cache/disk.lua`; dieser Lauf findet dieselbe Denkfigur
an 52 anderen Stellen.

Typische Gestalt (aus `cascade.nvim/lua/cascade/cycle/packs/init.lua:54`): ein
`pcall(require, …)` mit `if ok and type(groups) == "table" then … end` und **ohne
else-Zweig** — ein Pack, dessen Modul kaputt ist, liefert exakt dieselbe leere Antwort wie
ein Pack, das legitim nichts beiträgt. Kein Signal, nirgends.

#### 3. `LUA-01` / `ERR-50` / `ERR-22` — optionale Abhängigkeiten und Config · 21 / 24 / 22 Repos

Drei verwandte Muster rund um „was das Plugin über seine Umgebung annimmt":

- **`LUA-01`** (21 Repos): ein nacktes `require("ui.kit")` ohne `pcall`, während die
  eigene `docs/installation.md` `ui.nvim` als *optional* führt. Wer installiert, was die
  Doku „required" nennt, bekommt einen Lua-Traceback auf einem Default-Keymap —
  `cascade.nvim/lua/cascade/cycle/word_cycle.lua:163` ist der klarste Fall, weil
  `:checkhealth cascade` dabei sogar grün meldet. Dieses Muster ist eine direkte Folge der
  ui.nvim-Konsolidierung: die Aufrufe sind dazugekommen, die Doku und die Guards nicht.
- **`ERR-50`** (24 Repos): keine Config-Validierung vor dem Merge. Eine vertippte Option
  wird still übernommen und liegt danach im Config-Baum, wo sie niemand liest —
  `casedesk.nvim/lua/casedesk/config/init.lua:142` nimmt jeden Key an; `case_root` statt
  `cases_root` fällt nirgends auf.
- **`ERR-22`** (22 Repos): ein ungültiger *Wert* degradiert nicht auf den Default.

Kurios und aufschlussreich zugleich: `ai.nvim` hat die Prüfung (`warn_unknown_keys`), und
sie meldet die **eigene dokumentierte Option** `completion.provider` als Tippfehler, weil
`DEFAULTS.lua:64` sie als `provider = nil` schreibt — was in Lua gar keinen Key anlegt.
Die einzige Prüfung im Fleet, die es gibt, ruft bei ihrem eigenen Handbuch „Wolf".

#### 4. `ERR-01` / `ERR-03` — Systemgrenzen und explizite Rückgaben · 20 / 17 Repos

`ERR-01` (32 Stellen): Datei-, Prozess- und Eingabe-Aufrufe ohne `pcall`.
`buffer-ctx.nvim/lua/buffer_ctx/ops/annotation.lua` hat fünfzehn ungeschützte
`fn.input()`-Aufrufe in einer Datei.

`ERR-03` (27 Stellen): der sauberste Einzelfall ist `ai.nvim` — **vier von fünf Providern**
(`claude`, `openai`, `ollama`, `loomai`) melden einen Mid-Stream-Fehler über `on_error`,
setzen aber kein Fehler-Flag; curl endet mit 0, also feuert `on_done` danach als Erfolg.
Der fünfte, `gemini.lua:274`, hat das Flag — mit einem Kommentar, der genau diese Invariante
benennt. Das Muster ist im Repo also verstanden und an vier Stellen nicht angewandt.

#### 5. `XP-01` — roher Pfad als glob-Pattern · 9 Repos, 12 Stellen

`vim.fn.glob`/`globpath` lesen ihr Argument als Pattern: `~`, `[`, `?`, `*`, `{}` werden
interpretiert. Wo ein Verzeichnispfad in ein Pattern konkateniert wird
(`vim.fn.glob(dir .. "/**/*.md")` in `buffer-ctx`, `markdown`, `insights`, `lib`,
`mdview`, `pdfport`), bricht das still — leere Liste, kein Fehler.

Die von der Regel beschriebene Hauptauslöserin, Windows' 8.3-Kurzform (`STEFAN~1`), greift
auf diesem Rechner **nicht**: `bartl` ist kurz genug, dass weder Profil- noch Temp-Pfad
verkürzt werden. Ein Repo- oder Verzeichnisname mit `[`, `?` oder `{}` löst es trotzdem
aus. Der Ersatz `lib.nvim.fs.globbable` existiert, wie bei SEC-34.

### Befunde je Plugin

`high / medium / low` nach Einschätzung des prüfenden Agenten.

| Plugin | high | medium | low | gesamt |
|---|---:|---:|---:|---:|
| `language.nvim` | 14 | 2 | 0 | 16 |
| `mdview.nvim` | 11 | 7 | 0 | 18 |
| `lib.nvim` | 11 | 6 | 0 | 17 |
| `cascade.nvim` | 10 | 4 | 0 | 14 |
| `casedesk.nvim` | 10 | 4 | 0 | 14 |
| `sessions.nvim` | 9 | 4 | 0 | 13 |
| `dap.nvim` | 8 | 12 | 1 | 21 |
| `replacer.nvim` | 8 | 9 | 0 | 17 |
| `insights.nvim` | 8 | 8 | 0 | 16 |
| `debugging.nvim` | 8 | 7 | 0 | 15 |
| `reposcope.nvim` | 8 | 7 | 0 | 15 |
| `sandbox.nvim` | 8 | 7 | 0 | 15 |
| `lsp.nvim` | 8 | 5 | 0 | 13 |
| `open.nvim` | 8 | 5 | 0 | 13 |
| `markdown.nvim` | 8 | 2 | 1 | 11 |
| `cmdlog.nvim` | 7 | 7 | 0 | 14 |
| `color_my_ascii.nvim` | 7 | 6 | 1 | 14 |
| `media.nvim` | 7 | 5 | 2 | 14 |
| `github_stats.nvim` | 7 | 5 | 1 | 13 |
| `diff.nvim` | 7 | 4 | 0 | 11 |
| `rules.nvim` | 7 | 3 | 0 | 10 |
| `buffer-ctx.nvim` | 6 | 10 | 0 | 16 |
| `pdfport.nvim` | 6 | 8 | 1 | 15 |
| `hover.nvim` | 6 | 5 | 0 | 11 |
| `ai.nvim` | 5 | 7 | 1 | 13 |
| `gopath.nvim` | 5 | 8 | 0 | 13 |
| `runtime-analysis.nvim` | 5 | 6 | 1 | 12 |
| `emojis.nvim` | 5 | 6 | 0 | 11 |
| `fileops.nvim` | 5 | 6 | 0 | 11 |
| `recommender.nvim` | 5 | 5 | 0 | 10 |
| `images.nvim` | 4 | 8 | 0 | 12 |
| `pickers.nvim` | 4 | 8 | 0 | 12 |
| `documentation.nvim` | 4 | 7 | 0 | 11 |
| `my.nvim` | 4 | 3 | 0 | 7 |
| `filetree.nvim` | 3 | 7 | 2 | 12 |
| `spotlight.nvim` | 3 | 6 | 0 | 9 |
| `data.nvim` | 2 | 3 | 0 | 5 |
| `ui.nvim` | 1 | 11 | 1 | 13 |

Die Zahl sagt wenig über Qualität: `dap.nvim` führt mit 21, hat aber nur 8 `high`;
`language.nvim` hat 16 Befunde, davon 14 `high`. Große Repos bekommen nicht automatisch
mehr Befunde — `documentation.nvim` (54k LOC) hat 11, `casedesk.nvim` (14k LOC) hat 14.

### Was dieser Lauf nicht abdeckt

- Die **313 manuellen Regeln mit `recommended`/`nice-to-have`** wurden nicht geprüft. Das
  ist die Mehrheit des Katalogs.
- Die 35 `critical`-Regeln der Gate-Familien **NEW und REL** wurden nur insoweit geprüft,
  wie sie automatisiert sind.
- Die Agents haben `TESTS/` überwiegend nur gegriffen, nicht vollständig gelesen; das
  steht in den Abdeckungsnotizen je Plugin im Anhang.
- Ein Agent pro Plugin heißt: **eine** Perspektive auf 76 Regeln. Ein zweiter Durchlauf
  mit anderer Familien-Reihenfolge würde mit ziemlicher Sicherheit weitere Befunde finden.

---

## Teil 4 — Priorisierte Arbeitsliste

Nach Verhältnis von Wirkung zu Aufwand. Nichts davon ist umgesetzt.

### Sofort — ein Fix, fleet-weite Wirkung

1. **`SEC-34`: `vim.fn.expand()` → `lib.nvim.cross.fs.expand_path`** an den 37 bestätigten
   Stellen in 21 Repos. Kommandoausführung aus Pfadeingaben; der Ersatz existiert und wird
   von 15 Repos schon benutzt. Mechanischer Austausch, pro Repo eine Handvoll Zeilen.
2. **`rules.nvim`: `.claude` in `SKIP_DIRS`** (`fswalk.lua:20`). Eine Zeile, beseitigt 60%
   der Rohtreffer und die Quickfix-Sprünge in fremde Worktrees.
3. **`ai.nvim`: `DEFAULTS.lua:64`** — `provider`/`model` als echte Keys anlegen (z. B.
   `false` statt `nil`), sonst meldet die eigene Prüfung die eigene Doku als Tippfehler.
   Dabei gleich den Spiegel-Fehler mitnehmen, den der Prüfer fand: `OPEN_SHAPE_KEYS`
   matcht auf den bloßen Key-**Namen** statt auf den Pfad, deshalb kann ein echter
   Tippfehler in *irgendeiner* verschachtelten Option namens `model` nie auffallen.

### Als Nächstes — Regelqualität, damit das Gate wieder trägt

4. **Die sechs Check-Defekte im Ruleset reparieren** (siehe Teil 1). Solange `NEW-49`,
   `NEW-45`, `NEW-48`, `DEP-01` systematisch falsch melden, ist `:Rules check` als Gate
   nicht benutzbar. Vier davon sind Einzeiler.
5. **`.rules-waivers.json` je Repo anlegen** für die Treffer, die bleiben werden —
   Testcode-Fundstellen von `SEC-01`, die gegateten `DEP-02`-Fallbacks,
   `documentation.nvim`s Neovim-freie `scripts/`. Die Begründungen stehen in Teil 1 und
   können direkt übernommen werden. Aktuell hat genau ein Repo eine solche Datei.
6. **`SEC-01` erweitern** um `vim.fn.system`/`jobstart` mit String-Argument. Der Check
   findet aktuell fünf Fehlalarme und übersieht den einzigen echten Fall im Fleet:
   `lsp.nvim/lua/lsp/languages/app/dart.lua:81`, `vim.fn.jobstart("flutter run", …)`.

### Dann — die breiten Muster, repoweise

7. **`ERR-11`** (30 Repos, 52 Stellen): „leer weil nichts da" von „leer weil kaputt"
   trennen. Die im Ruleset dokumentierte Wurzel-Fix-Strategie von 2026-09-07 gilt weiter:
   wo möglich in `lib.nvim` fixen, nicht im vierten Konsumenten.
8. **`LUA-01`** (21 Repos): `require("ui.kit")` hinter `pcall` mit Fallback — oder
   `ui.nvim` in den betroffenen `docs/installation.md` als *required* ausweisen. Beides ist
   vertretbar, aber Code und Doku müssen dasselbe sagen.
9. **`ERR-03` in `ai.nvim`**: das `failed`-Flag aus `gemini.lua:274` in `claude`, `openai`,
   `ollama` und `loomai` übernehmen. Vier Dateien, ein Muster, im Repo bereits vorhanden.
10. **`ERR-50`/`ERR-22`** (24 / 22 Repos): Config-Key-Prüfung vor dem Merge und
    Degradierung ungültiger Werte auf den Default.

### Strukturell

11. **`NEW-08`**: acht Repos haben wirklich keinen vollständigen `bindings/`-Satz
    (`lib`, `mdview`, `filetree`, `open`, `ui`, `rules`, `runtime-analysis`, `sandbox`).
    Vorher entscheiden, ob die Regel „alle drei immer" meint oder „alle drei, sofern das
    Plugin sie braucht" — der Check kann das nicht unterscheiden.
12. **`sessions.nvim` fehlt in der Installations-Spec** (`lua/plugins/personal/init.lua`).
    37 von 38 Repos sind dort aktiv eingetragen, dieses eine gar nicht.
13. **`REL-29`**: uncommitted changes in `casedesk.nvim` und `ui.nvim` zum Scanzeitpunkt.

---

## Anhang — Reproduktion

Der automatische Teil ist ein Einzeiler pro Repo gegen die programmatische API:

```sh
nvim --clean --headless -u rules_init.lua -l check_all.lua
```

wobei `rules_init.lua` `rules.nvim` und `lib.nvim` in die `runtimepath` hängt und
`setup()` mit demselben `rulesets`-Pfad aufruft, den
`lua/plugins/personal/init.lua:764` konfiguriert, und `check_all.lua` über
`vim.tbl_keys(rules.stats().families)` läuft und je Familie
`rules.check_family_json(fam, target)` aufruft. Beide Skripte waren Wegwerf-Code im
Sinne von `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/TOOLS/TOOL-PLACEMENT.md`
— der Report ist das Ergebnis, es gibt nichts erneut auszuführen. Wenn dieser Lauf
wiederholbar sein soll, gehört er nicht als Skript ins Repo, sondern als `:Rules`-Modus
(„eine Familie gegen alle Sibling-Repos") nach `lib.nvim.dev.*`.

Der manuelle Teil lief als Workflow mit 76 Agents (38 Audits, 38 Gegenprüfungen), je drei
gleichzeitig, gegen eine aus dem Katalog extrahierte Datei mit den Volltexten der 76
`critical`-Regeln.

**Zahlenbasis:** 421 Regeln, 38 Repos, ~390.000 LOC Lua. 66 automatische Treffer nach
Worktree-Bereinigung, 541 manuelle Rohbefunde, 497 nach Gegenprüfung bestätigt.
