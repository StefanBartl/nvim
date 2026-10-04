# Handover — Task-System für die wkdbooks

> **Stand 2026-10-04 (nach Runde 36: **Phase 4 — Migration abgeschlossen**).** Phasen 0–3 sind gebaut und auf `main`; **Phase 4 (Migration) läuft**:
> migriert und committet sind `lib.nvim` (Pilot), `lsp.nvim`, `mdview.nvim`, `documentation.nvim`, `casedesk.nvim`,
> `markdown.nvim`, `gopath.nvim`, `github_stats.nvim`, `filetree.nvim`, `images.nvim`, `pdfport.nvim`, `open.nvim`,
> `gitsuite.nvim`, `color_my_ascii.nvim`, `rules.nvim`, `media.nvim`, `ai.nvim`, `ui.nvim`, `debugging.nvim`, `insights.nvim`, `my.nvim`, `language.nvim`, `hover.nvim`, `buffer-ctx.nvim`, `runtime-analysis.nvim`, `data.nvim`, `replacer.nvim`, `cascade.nvim`, `sandbox.nvim`, `reposcope.nvim`, `sessions.nvim`, `emojis.nvim`, `diff.nvim`, `cmdlog.nvim`, `dap.nvim`, `fileops.nvim`, `recommender.nvim`, `filetreepicker.nvim`, `nvim-nexus`, `docmap-desktop` (21), `nvim-config` (26) und `ALL` (+24); `refinder` (kein Plugin, Statussatz), `spotlight.nvim` und
> `migrate.nvim` sind geprüft (keine offene Arbeit, keine Tasks); `pickers.nvim` hat einen einzelnen Task aus einer fremden Runde (seine eigene Runde steht aus). Keine Agenten laufen mehr.
> Nach Runde 19 (`ui`) wurde auf Wunsch kurz angehalten, Runde 20 (`debugging`) lief danach; offen ist nur noch die Politur (Phase 5) und die Entscheidungen der `decision`-Tasks.
>
> **Neu seit dem letzten Stand:** Kategorien (`category`, Filter `--category=`) und Ordner-Tasks mit Assets
> (`<slug>/<slug>.md`, `task attach`/`folderize`), Konzept §12, Regeln R13 und R14 — siehe „Kategorien und Ordner-Tasks“.
> **Entscheidungen** zu den Runden 10–19 stehen im Abschnitt „Offene Entscheidungen“; die zu casedesk, markdown,
> documentation, github_stats, filetree und open.nvim sind im Vault schon eingetragen.
>
> **Konzept (Spec, Regeln R1–R14, Entscheidungen):**
> [Task-System-Konzept.md]($REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/ALL/Task-System-Konzept.md)
> — dort steht das *Warum*; diese Datei sagt, *wo was liegt und was als Nächstes ansteht*.

## Worum es geht

Offene Aufgaben der eigenen Plugins stehen als eine Datei pro Task unter
`<plugin>/ROADMAP/tasks/<slug>.md` (flaches YAML-Frontmatter) im Vault
`$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/`. Pro Plugin wird eine `ROADMAP/TASKS.md`
**generiert** (nie von Hand editieren). Erledigt = Datei nach `Backlog/FEATURES|TASKS/` verschieben.
Die globale `ALL/TASKS.md` wird **nicht** committet, nur bei Bedarf erzeugt.

## Wo was liegt

| Teil | Ort |
|---|---|
| Frontmatter-Modul (generisch) | `lib.nvim`: `lua/lib/nvim/markdown/frontmatter/` (+ `TESTS/frontmatter_spec.lua`) |
| Engine (reines Lua, ohne UI) | nvim-config: `lua/tasks/` (vault, model, scan, index, mutate, check, cli, fsio) + README dort |
| Headless-CLI | nvim-config: `scripts/tasks.lua` — `nvim --headless -u NONE -l scripts/tasks.lua <list\|index\|new\|set\|done\|attach\|folderize\|check\|template\|areas\|export>` (Optionen mit Doppelstrich: `--kind=…`, nicht `kind=…`) |
| `:MyPlugins`-Routen | nvim-config: `lua/bindings/usrcmds/plugin_repos/` (Routen-Datei + `README.md`) |
| Dashboard | nvim-config: neben `plugin_repos/picker.lua` (Snacks-Picker, Fallback ohne Snacks) |
| Specs der Engine | nvim-config: `TESTS/` (Runner `nvim -n -i NONE --headless -u NONE -l TESTS/run.lua`) |
| Migrierte Plugins | Vault, jeweils `ROADMAP/tasks/` + generierte `ROADMAP/TASKS.md`: `lib.nvim` (Pilot, 58), `documentation.nvim` (55), `casedesk.nvim` (28), `lsp.nvim` (14 offen), `mdview.nvim` (11), `markdown.nvim` (6), `github_stats.nvim` (5), `gopath.nvim` (4), `pickers.nvim` (1), `images.nvim` (24), `pdfport.nvim` (7), `open.nvim` (8), `gitsuite.nvim` (5), `color_my_ascii.nvim` (11), `rules.nvim` (7), `media.nvim` (10), `ai.nvim` (15), `ui.nvim` (13), `debugging.nvim` (5), `insights.nvim` (4), `my.nvim` (5), `language.nvim` (10), `hover.nvim` (10), `buffer-ctx.nvim` (8), `runtime-analysis.nvim` (11), `data.nvim` (6), `replacer.nvim` (3), `cascade.nvim` (3), `sandbox.nvim` (2), `reposcope.nvim` (2), `sessions.nvim` (4), `emojis.nvim` (2), `diff.nvim` (2), `cmdlog.nvim` (6), `dap.nvim` (4), `fileops.nvim` (2), `recommender.nvim` (8), `filetreepicker.nvim` (1), `nvim-nexus` (1); einzelne Tasks fremder Runden in `lib.nvim` (+2) |
| Brief für Migrations-Agenten | `C:\Users\bartl\AppData\Local\Temp\claude\…\scratchpad\migration-brief.md` (nur in der Sitzung; Inhalt = Abschnitt „Nächste Schritte“ Punkt 1 dieser Datei) |
| Regeln R1–R14 | Vault-`README.md`, Abschnitt "Open tasks" |
| Env-Link-Prüfung | Vault `TOOLS/scripts/md_lint.lua` löst `$VAR/…`-Links mit `lsp.core.env_links` (lsp.nvim) auf |

## Bedienung (verb-first, kein plugin-first-Shim — entschieden)

```
:MyPlugins tasks [<area>|all] [--status= --prio= --kind= --category= --tag= --stale=<d> --blocked] [--to=buffer|file:<p>|clipboard|qf] [--format=md|csv]
:MyPlugins tasks index [<area>|--all] [--check]
:MyPlugins task new <area> [title…] [kind= prio= effort= tags= category= status=] [--folder]
:MyPlugins task set <id> key=value…
:MyPlugins task attach <id> <file> [name=]
:MyPlugins task folderize <id>
:MyPlugins task done <id> [done_in=…]
:MyPlugins task template
:MyPlugins task open <id>
:MyPlugins open <area> <tasks|roadmap|backlog|handover|notes|all>
```

Headless zusätzlich: `new … --refs=pfad,repo@sha --lang=de|en` (englische Überschriften), `template --lang=en`;
`set <id> refs=[a, b]` liest die Klammerliste.

Dashboard-Tasten (Listenfenster): `<CR>` öffnen, `<Tab>` markieren, `s`/`p` Status/Prio als Batch, `D` erledigen,
`f` Filter, `e` Export, `r` neu scannen, `gb`/`gr` Backlog/ROADMAP, `g?` Hilfe. **Im Suchfeld** stattdessen
Alt-Kombinationen (Normal- und Insert-Modus): `<M-s>` `<M-p>` `<M-d>` `<M-f>` `<M-e>` `<M-r>` `<M-b>` (Backlog)
`<M-m>` (ROADMAP) `<M-?>`. `<id>` = `<area>/<slug>`.

## Neu seit Runde 22 (Konzept §13, §14)

- **Aufwand und Sortierung:** `--effort=S,M` bzw. `--effort=<=M`; `--sort=default|prio-effort|severity` in CLI `list` und
  `:MyPlugins tasks`; Dashboard-Taste `o` (Suchfeld `<M-o>`) schaltet die Ordnung durch. `prio-effort` ist Status, Prio,
  Aufwand (der Status bleibt vorn, damit `doing` nicht hinter `parked` rutscht).
- **`severity`:** optional `low|medium|high|critical` für bug/security; Filter `--severity=`, Check `unknown-severity` und
  Warnung `severity-without-bug-or-security`; steht NICHT im generierten Index (sonst wären alle Indizes veraltet); CSV hat
  eine neue letzte Spalte.
- **Formular:** `:MyPlugins task new` ohne Bereich öffnet einen Markdown-Formular-Buffer (`<Space>`/`<CR>` haken ab,
  cascade.nvim per pcall, `<C-s>` sendet, `q` bricht ab, `g?` Hilfe), danach die Frage „Attach assets?“ (Ja → Ordner-Task und
  Explorer auf `assets/`). Reines Modul `lua/tasks/form.lua`, UI `plugin_repos/tasks_form.lua`. **Nur headless geprüft**, nicht
  in einem echten Terminal; Abweichungen: `Tags`/`Refs` sind Textzeilen, Tage-Aufwand nicht wählbar, Esc auf die Assets-Frage
  zählt als Nein. Task `ALL/task-new-form` bleibt `open`, bis der Nutzer das Formular ausprobiert hat.
- **Offene Entscheidungen (language, hover):** `language.nvim/translate-engine-failover` (Empfehlung: ja, nur zu selbst
  eingetragenen Engines), `vocabulary-review-from-history` (parken), `translate-path-scope-unsupported` (unterstützen),
  `health-report-ui-nvim`, `docs-vimdoc-install-catch-up` (erst `why`-Text); `hover.nvim/persistent-link-cache`
  (Text-Abruf oder Screenshot? Default `persist=false`, leere Muster) und `hover-copy-content` (erst `:Hover copy`).
  Bug mit Datenverlust: `language.nvim/translate-replace-stale-range` (prio 2).

## Kategorien und Ordner-Tasks (Konzept §12)

- **Kategorien:** optionales Feld `category: [security, docs]`, Werte `bug`, `security`, `performance`, `docs`,
  `ruleset` (`ruleset` = Regelwerk unter `wkdbook-Lua/Checklists/regeln/`, Regel-IDs im freien Feld `rules: [LLS-45]`).
  Wirksam sind: das Feld, `bug` bei `kind: bug`, und Tags, die genauso heißen — die rund 270 bestehenden Tasks sind
  damit ohne Umbau filterbar (Stand: bug 21, security 6, performance 14, docs 11 von 265 offenen). Filter
  `--category=` in CLI, `:MyPlugins tasks` und als Dashboard-Chip; Kategorien grenzen ein, sie sortieren nicht.
  Fehler: `unknown-category`.
- **Ordner-Tasks:** Task = Datei `tasks/<slug>.md` **oder** Ordner `tasks/<slug>/<slug>.md` mit Assets (Konvention
  `assets/`). Beide Formen nebeneinander; ID und Index-Format unverändert. `task attach <id> <datei>` kopiert nach
  `assets/`, macht aus einem Datei-Task automatisch einen Ordner und liefert den Markdown-Link; `folderize` stellt ohne
  Anhang um; `new --folder` legt gleich einen Ordner an. `done` verschiebt den ganzen Ordner nach
  `Backlog/<bucket>/<datum>_<slug>/<datum>_<slug>.md` und rollt bei einem Fehler zurück (per Spec belegt). `check` meldet
  `slug-conflict` (Datei und Ordner gleichen Namens) und `asset-dangling` (Warnung, `assets/…`-Link ohne Datei).
- **Stand:** gebaut, 12 Specs grün, im echten Vault `check` 0 Befunde. **Nicht getestet:** die Editor-Befehle in einer
  echten Sitzung (nur über die Routen-Spec), Umbenennen offener Buffer bei `attach`/`folderize` mit mehreren Fenstern.
  Das Haupt-Checkout der nvim-config war zuletzt 3 Commits hinter `origin/main` mit uncommitteten github-stats-Daten
  und muss gepullt werden, damit die neuen Befehle dort laufen.

## Commits (alle auf `main`)

| Repo | Commit | Inhalt |
|---|---|---|
| lib.nvim | `2bc2874`, `c6d274c` | Frontmatter-Modul; Fix: Zahlen-Strings quoten, Prosa-Blöcke ablehnen, Temp-Name |
| nvim-config | `ef8641fa`, `be270dfa`, `c61cd4f1` | Engine/CLI/Specs, `:MyPlugins`-Routen, Dashboard |
| nvim-config | `efcab018`, `80ef2946`, `9ca296e9` | Fixes: Temp-Name, Warnung bei Titel mit ` #`, kein Fehlalarm bei gequotetem Titel |
| nvim-config | `ded6d10b` | `new --refs/--lang`, `set` mit Klammerliste |
| nvim-config | `04c2aeae` | Dashboard: Alt-Kombinationen im Suchfeld; Collection `vault` entfernt |
| WKDBooks | `b6c8edb` … `1e37d97` | Konzept, Entscheidungen, Pilot, Regeln |
| WKDBooks | `88db92d` | `pickers.nvim`: Task für die generische Items-Quelle |
| WKDBooks | `77b476c` | `lsp.nvim`: 15 Tasks (Phase 4, Runde 1) |
| WKDBooks | `e9d7b9d` | `mdview.nvim`: 11 Tasks (Runde 2) |
| WKDBooks | `7b17bf3` | `md_lint` löst Env-Links auf; `messages-module-cut` entschieden |
| WKDBooks | `06b9584`, `1af295e` | Entscheidungen lsp.nvim (Config-Warnung, Projekt-Scan → lib.nvim) und mdview (Overlays) |
| WKDBooks | `ce538a5` | `markdown.nvim`: 6 Tasks (Runde 5) |
| WKDBooks | `825fc01` | `casedesk.nvim`: 28 Tasks (Runde 4) |
| WKDBooks | `02f2083` | `documentation.nvim`: 55 Tasks (Runde 3) |
| WKDBooks | `e23cd38` | `gopath.nvim`: 4 Tasks (Runde 7), Treesitter-Irrtum in ROADMAP/FEATURES korrigiert |
| WKDBooks | `a9d0d2a` | `github_stats.nvim`: 5 Tasks (Runde 6) |
| WKDBooks | `e8ae2a3` | `spotlight.nvim`: keine offene Arbeit, Statussatz |
| WKDBooks | `36ef7c4` | `filetree.nvim`: 28 Tasks (Runde 8) |
| WKDBooks | `e63b4cb`, `e27b5c8`, `4584776`, `e18a512`, `05e3187` | Entscheidungen casedesk, markdown, documentation, github_stats, filetree |
| WKDBooks | `0037ef2` | `images.nvim`: 24 Tasks (Runde 10), Roadmap-Korrekturen (Flamegraph und ASCII-Fallback sind gebaut) |
| WKDBooks | `c04e5d5` | `pdfport.nvim`: 7 Tasks (Runde 11), Roadmap-Korrekturen |
| WKDBooks | `c134da2`, `8afeefb` | `open.nvim`: 8 Tasks + `lib.nvim/open-default-windows-schemes` (Runde 12); Entscheidungen eingetragen |
| WKDBooks | `978033c` | `gitsuite.nvim`: 5 Tasks + `lib.nvim/fs-watch-filename-normalize` + `replacer.nvim/tests-lint-cleanup` (Runde 13) |
| WKDBooks | `5bba084` | `color_my_ascii.nvim`: 11 Tasks (Runde 14) |
| WKDBooks | `eecbf1f` | `migrate.nvim`: keine offene Arbeit, datierter Hinweis (Runde 15; Plugin-Repo lokal nicht vorhanden) |
| WKDBooks | `ff656a3` | `rules.nvim`: 7 Tasks (Runde 16) |
| WKDBooks | `018ee0f` | `media.nvim`: 10 Tasks + `hover.nvim` (3) + `language.nvim` (1) (Runde 17) |
| WKDBooks | `8fc8953` | `ai.nvim`: 15 Tasks; `pdfport.nvim/openai-extraction-backend` jetzt blockiert durch `ai.nvim/openai-documents-live-check` (Runde 18) |
| WKDBooks | `397310c` | `ui.nvim`: 13 Tasks (Runde 19) |
| nvim-config | `f974551d` | Kategorien und Ordner-Tasks (Engine, CLI, Routen, Dashboard, Specs, Doku) |
| WKDBooks | `3523f02` | `my.nvim`: 5 Tasks (Runde 22) |
| WKDBooks | `914a3ac` | Entscheidungen umgesetzt: 14 neue Tasks, ui.kit-Tasks von lib.nvim nach ui.nvim, Bereich `ALL/ROADMAP/tasks/`, rules-Agentenkette Prio 1, `insights.nvim/telemetry-subcommand-usage` verworfen |
| WKDBooks | `bc9743f` | `language.nvim`: 10 Tasks (Runde 23) |
| WKDBooks | `4a45e66` | `hover.nvim`: 7 neue Tasks (Runde 24) |
| WKDBooks | `76dac4a` | `buffer-ctx.nvim`: 8 Tasks (Runde 25), `anchor-stable-marks` nach Backlog |
| WKDBooks | `f1598d8` | `runtime-analysis.nvim`: 11 Tasks (Runde 26); M11/L4/L5 liegen hier, nicht in documentation.nvim (Handover-Annahme war falsch) |
| WKDBooks | `6b3fdb3` | `data.nvim`: 6 Tasks (Runde 27) |
| WKDBooks | `1e505d6` | `replacer.nvim`: 3 Tasks + neue `FEATURES.md` (Runde 28) |
| nvim-config | `9fbf0e8f`, `98f71820` | Aufwand-Filter + Sortierungen + `severity` (Merge `77e29d05`); Markdown-Formular für `task new` |
| WKDBooks | `112e70d`, `afce473` | Konzept §13 (Aufwand, Sort, severity, R15) und §14 (Formular, E15–E17) |
| WKDBooks | `da40a62` | Konzept §12, Regeln R13 und R14 |
| WKDBooks | `932fac8` | `debugging.nvim`: 5 Tasks (Runde 20); „Offen“ der ROADMAP war das gebaute Recent-Popup, durch Verweis ersetzt (Commit trägt versehentlich einen Claude-Co-Author-Trailer, gepusht) |
| WKDBooks | `c36036a` | `insights.nvim`: 4 Tasks (Runde 21), nur das SYNERGIE-Papier war offen; gebaute Features in FEATURES.md nachgetragen |
| WKDBooks | `a6c42b8`, `939a6e1`, `7040070`, `9cd33d0`, `6b25f83` | `cascade` (3), `sandbox` (2), `reposcope` (2), `sessions` (4), `emojis` (2) — Runden 29–33; überwiegend Checklisten-Tasks (update + run), dazu `sessions.nvim/chip-function-color-no-colorscheme-retint` (Bug) |
| WKDBooks | `7a292d5` | `docmap-desktop`: 21 Tasks (Runde 35), L1–L8/M-Punkte nur noch als Zeiger; Agentenkette P2–P7 als Tasks (rules-*, Prio 1) |
| WKDBooks, nvim-config | `742e111`, `b8bb6da`; `c607cf4e` | Runde 36: `nvim-config` (26) und `ALL` (24) Tasks; `00_ROADMAP.md` mit Task-Verweisen |
| WKDBooks | `9ac2707` … `d3da674` | Runde 34, je Bereich ein Commit: `diff` (2), `cmdlog` (6), `dap` (4), `fileops` (2), `recommender` (8), `refinder` (Statussatz), `filetreepicker` (1), `nvim-nexus` (1) |

Review: Der Code von `2bc2874`, `ef8641fa`, `be270dfa`, `c61cd4f1` wurde durch einen Review-Agenten adversarial
geprüft (13 Befunde behoben). Die Fix-Commits `c6d274c`, `efcab018`, `80ef2946` hat Claude am 2026-10-04 selbst
gelesen (ein Befund → `9ca296e9`), **nicht** per `ultracode`. `ded6d10b`, `04c2aeae` und `f974551d` (Kategorien,
Ordner-Tasks) sind ebenfalls nicht per Agent reviewt; alle Migrationscommits der Runden 10–19 sind nur per Stichprobe
gegen den Code geprüft, nicht per `ultracode`.

## Entscheidungen (2026-10-04, alle umgesetzt)

- Collection `vault` entfernt (Duplikat von `plugins_book`); Einstieg ist `:MyPlugins open <area> …`.
- `lib.nvim/messages-module-cut`: kein Cheatsheet-Modul auf Vorrat, erst beim Bau des Popups (Task `parked`).
- Dashboard-Tasten: Buchstaben nur in der Liste, im Suchfeld Alt-Kombinationen.
- `md_lint`: Env-Links werden aufgelöst und auf Datei und Anker geprüft (statt übersprungen).
- `lsp.nvim/config-unknown-key-warning`: warnen in `:checkhealth lsp` / `config.warnings()` (Task `open`, prio 2).
- Projekt-Scan fehlender Parser/Tools: **nicht** in lsp.nvim, sondern als Modul in lib.nvim
  (`lib.nvim/project-scan-missing-parsers-and-tools`, baut auf `lib.nvim.deps` und `treesitter.parser_policy`).
- `lsp.nvim/live-check-lspsaga-replacements` und `mdview.nvim/scroll-lag-feel-judgement` bleiben Tasks.
- mdview-Overlays: Fokus-Zoom zuerst; Keycast opt-in mit drei Scopes (nur Normal / Insert mit Schutz für Passwortfelder /
  alles) und schnellem Ausblenden, Capture/Formatierung mit `ui.nvim`s `ui.screenkey` teilen; Marker-Umzug als eigener
  Task (`mdview.nvim/overlay-markers-migration`, parked).

## Entscheidungen der Runden 10–22 (2026-10-04, im Vault umgesetzt, `914a3ac`)

Der Nutzer hat die offenen Fragen durchgesprochen; was nicht genannt ist, blieb bewusst unverändert.

- **debugging.nvim:** `views-dead-refresh-sweep` bleibt `decision` — der Nutzer entfernt den Code selbst (Liste im Task);
  `health-recent-popup-requirements` ist `blocked` durch den neuen `lib.nvim/messages-status`.
- **insights.nvim:** `telemetry-subcommand-usage` verworfen (nur Host-seitig messen); `architecture-md-todos-drift` handgepflegt.
- **images.nvim:** `image-suite-decision` erst nach den Einzelfunden; neuer Task `sixel-backend-evaluation` (decision);
  die drei Bereichs-Tasks (gopath/documentation/github_stats) ziehen bei deren Runde um; `magick-resource-limits`,
  `draw-payload-cache` unverändert. `images.nvim/ROADMAP/TERMINALS.md` sagt noch „Sixel has no task“ (nachziehen).
- **pdfport.nvim:** drei `decision`-Tasks (`named-error-types`, `wkhtmltopdf-typst-producers`, `real-tool-runs-in-ci`).
- **gitsuite.nvim:** `terminal-spawn-helper` → `open` (bauen); drei geparkte Ideen (`conflict-diff-three-way`,
  `hunk-navigation`, `hunk-textobject-ih`); `own-engine-lazygit-neogit` und `diffview-replacement` unverändert.
- **my.nvim:** `dead-breadcrumb-config-keys` → `open` (alle fünf Schlüssel entfernen, `lua_table_root` zusammen mit
  `lsp.nvim/lua-table-root-jump`); der Scrubber wandert nach lib.nvim (`lib.nvim/clipboard-utf8-scrubber`,
  `my.nvim/clipboard-scrubber-spec` blockiert darauf).
- **rules.nvim:** Agent-Strang wird angegangen (vier Tasks Prio 1; Kette `agent-plan-validate` + `rules-json-project-config`
  → `agent-verdict-store` → `agent-commands-over-ai-nvim`); `TASK-documentation.nvim.md` nach `Backlog/TASKS/` verschoben.
- **ai.nvim:** `copilot-provider` bleibt; `repo-instructions-and-hooks` nur System-Prompt-Teil, `blocked` durch
  `agent-presets`; Chat-Buffer-Sessions abgelehnt („Nicht geplant“); `:Ai stop` zuerst nur für Streams.
- **ui.nvim / lib.nvim:** `interactive-confirm-sweep` liegt jetzt in `ALL/ROADMAP/tasks/` (`ALL/interactive-confirm-sweep`);
  `history-stack-ui-kit`, `tui-dashboard-kit`, `ui-kit-playground`, `create-on-missing-dialog`, `messages-module-cut` sind
  `ui.nvim/<slug>` (ui.kit maßgeblich, lib.nvim-Kopie nur per Drift-Port). Übrige ui.nvim-Fragen (wezterm-bridge,
  Snacks.terminal, Ideen-Bündel, noice) bleiben offen/unverändert.
- **color_my_ascii.nvim, media.nvim:** keine Änderung; deren Empfehlungen stehen weiter in den Task-Notes.
- **Prio-2-Bugs aus den Runden** (`images`: `paste-powershell-quote-escape`, `convert-failure-deletes-existing-target`;
  `pdfport`: `soffice-detect-install-paths`, `rasterize-timeout`; `ui`: `context-kotlin-when-branches`,
  `screenkey-secret-input-protection`, `docs-ui-subcommands-catch-up`; `debugging`: `recent-fallback-multiline-crash`) sind
  Tasks und warten auf Abarbeitung, keine Entscheidung nötig.
- **Neue Engine-Features (in Arbeit, eigener Worktree-Branch):** Filter `--effort=` und Sortierung `--sort=prio-effort`;
  optionales Feld `severity` (low/medium/high/critical) für bug/security mit `--severity=`, `--sort=severity`.

<details><summary>Ältere Punkte (entschieden, nur zur Historie)</summary>

Empfehlung jeweils in Klammern; die Tasks stehen unter `<plugin>/ROADMAP/tasks/<slug>.md`.

- **casedesk.nvim:** `unconfirmed-outcome-or-status` (Q-4: „Unbestätigt“ als Wert von `case_outcomes` oder vierter
  Status?); `docs-language-plugin-repo` (Q-2: gilt „docs/ komplett Deutsch“ noch? 7 deutsch, Rest englisch);
  `live-tests-run` (Checkliste als Task behalten? 234 Zeilen „ungetestet“ gezählt, der Plan nannte 81);
  `doctor-stale-unconfirmed-live-run` (Prio 1 passt? Lauf verschiebt echte Case-Ordner, nur der Nutzer kann ihn auslösen).
- **markdown.nvim:** `hover-config-passthrough` (`hover` ungeprüft an hover.nvim durchreichen — empfohlen — oder
  Allowlist erweitern); `in-buffer-concealed-rendering` (parked lassen oder als verworfen ins Backlog);
  `handler-ctx-helper`, `vim-port-markdown-vim` (parked lassen oder verwerfen).
- **documentation.nvim:** `per-tab-pdf-export` und `root-slider-other-views` (beide aus der Git-Historie als `parked`
  wiederhergestellt, bleiben?); `runtime-tab-grouping` (Bedingung „dritter Bewohner“ erfüllt — entparken empfohlen);
  Call-Edges/i18n als `open` statt `decision` angelegt, Aufteilung der 18 Sprachen in 6 Tasks nach Scope-Familie
  (passt?); `keyword-card-tab-navigation-live-check` (Task oder nur Checklistenzeile); `ideas-files-stale-entries`
  (veraltete „not built“-Prosa in IDEAS/MULTILANG bereinigen — empfohlen, nach der Migration).
- **github_stats.nvim:** `on-demand-live-fetch` (Status `decision`: bauen oder „no data“ bleibt die Antwort);
  `traffic-digest-e2e-check` (Live-Test als Task oder nur Checkliste); sollen die IDEAS-Features (Thresholds, Groups,
  Webhook, …) als `parked`-Tasks mit `kind: idea` ins Dashboard (bewusst nicht angelegt); `fetch-spawn-throttle`
  (Freeze mit heutiger Allowlist unbekannt, `needs-verification`).
- **filetree.nvim:** `startup-without-neo-tree` (Status `decision`: Umbau für ca. 50–70 ms Startzeit, ja/nein; Verweis
  auch im Startup-Report der nvim-config); die Live-Test-Tasks `test-trash-batch-linux-macos`, `collapse-blink-live-check`,
  `handle-guard-eperm-observation` (R10-Grenzfälle, behalten?); verwerfbare Ideen `spotlight-from-tree`,
  `open-markdown-in-mdview`, `context-menu-image-pdf-group`, `insights-node-actions`; Besitzer von
  `orphaned-asset-report` (filetree oder `images.nvim :Image orphans`). Wichtigster Fund: `powershell-quote-escape`
  (Prio 1, Bug) — typografische Quotes U+2018–U+201B brechen aus PowerShell-Strings aus, `it’s.md` ist unter Windows
  nicht trashbar (`trash/platform.lua`).
- **spotlight.nvim:** Vorschlag `task-status-words-highlight` bewusst nicht angelegt (kein Anknüpfungspunkt); soll er
  trotzdem als `parked`-Idee? Zeile „spotlight.nvim, wie mehrere hl machen, lernen!“ in `00_ROADMAP.md:39` wohl erledigt
  — entfernen?
- **gopath.nvim:** keine; optional `cache-load-from-disk-lazy` auf Prio 2, falls `startup-stall-measure` mehr Last zeigt.
- **lsp.nvim / mdview.nvim:** beantwortet (siehe „Entscheidungen“); `live-check-lspsaga-replacements` und
  `scroll-lag-feel-judgement` bleiben Tasks.

</details>

## Runden 29–34: Muster und Funde

- **Muster:** Viele kleine Plugins hatten keine Roadmap-Punkte, nur die veraltete manuelle Testcheckliste
  (`ALL/manual-test-checklists/<name>.md`, Stand 2026-09-07, null abgehakt). Daraus je zwei Tasks:
  `manual-checklist-update` (open, docs) und `manual-checklist-run` (blocked, needs-user). ROADMAP.md bekam einen Rollen-Kasten
  plus Tabelle „Wo die offene Arbeit hingegangen ist“.
- **Bugs aus Runde 34:** `recommender.nvim/replace-mode-fzf-backend-never-inserts` (severity medium; Autocmd nur auf
  `TelescopePrompt`, fällt hier nicht auf, weil die Config `engine = "telescope"` setzt), `perf-accumulator-false-positives`,
  `perf-tips-accuracy`; `cmdlog.nvim/bindings-catalog-keymaps-is-function`, `preview-edit-abbreviations-not-classified`.
- **Entscheidungen beim Nutzer:** `nvim-nexus/project-go-no-go` (bauen, verwerfen oder Teile nach `pickers.nvim`; Empfehlung im Task),
  `filetreepicker.nvim/numbered-quickpick-mode` (Feature in filetree.nvim, eigenes Plugin oder verwerfen),
  `cmdlog.nvim/vestigial-accessors-and-shell-split`, `dap.nvim/unwired-state-and-registry-api`.
- **Querschnitt, bewusst kein Task:** plenary → busted-Shim (`docs/ROADMAP/IDEAS/IDEAS/testing.md`, M1) betrifft u. a. sandbox.nvim.
- **Nachzuziehen:** `recommender.nvim/docs/architecture.md:41` sagt „No open roadmap items“; Vault `Backlog/README.md` zählt
  „FEATURES (0)“ obwohl `sessions.nvim` dort eine Datei hat; `docs/ROADMAP/Final_Checks/BINDINGS-RUNTIME-CHECKLIST.md`
  führt reposcope `dashboard`/`update` noch (nach gitsuite umgezogen) und kennt `messages` nicht.
- **Vault-Hygiene:** `wkdbook-takt/` (ungetrackt) und uncommittete `language.nvim/…`-Entscheidungen liegen dort fremd; Commits immer
  mit expliziten Pfaden, nie `git add -A`.

## Runde 35–36: Funde und Entscheidungen beim Nutzer

- **docmap-desktop:** `release-v0-6-1-decision` (die Review-Fixes `3d0af4a`…`c3b1a9a` stecken nicht in `v0.6.0`; Empfehlung: erst
  Live-Tests, dann ein Patch); lokaler Checkout 4 Commits hinter `origin/main`, gemergter Worktree/Branch aufzuräumen
  (`stale-worktree-and-merged-branch-cleanup`); `--api=rules`/`popen_git`-Tasks liegen hier, könnten nach `documentation.nvim`;
  Chat (P5b) und Checklisten-Eingabe (P7/L6) auf Prio 2 statt 1.
- **nvim-config / ALL:** elf `decision`-Tasks, vor allem `ALL/spec-nvim-m0-falsification` (hängt `replace-plenary-test-harness` und
  `test-nvim-neotest-extraction` dran), `nvim-config/license-and-readme-decision`, `upstream-neotest-reports` (nur nach Ja),
  `ALL/strip-claude-coauthor-from-history` (Force-Push nur nach Ja; nvim-config 4 von 2185, WKDBooks 19 Trailer — Ursache: die
  Attribution-Vorgabe der Umgebung widerspricht der Nutzerregel).
- **Bug mit Prio 2:** `nvim-config/ci-stylua-red-learn-plan-viewer` (CI auf `main` seit ca. 10 Läufen rot, `stylua --check` auf
  `learn_plan_viewer/init.lua` bestätigt).
- **Korrekturen:** neotest-plenary-Windows-Fehler ist per Shim (`windows_fixes.lua`) behoben, offen nur das Upstream-Melden;
  `filetree` ohne neo-tree verworfen (2026-10-04); `:BindingsRuntimeChecklist` schreibt in einen nicht mehr existierenden Ordner
  (`bindings-checklist-update`).
- **Offene Fragen zu `00_ROADMAP.md`:** `docs\ROADMAP\LONG_RUN` existiert nicht; spotlight-Zeile erledigt?; wkd-/Lern-/Lebensziele
  bewusst außerhalb des Task-Systems; später auf Prosa + Task-IDs kürzen (R1/R2)?

## Offen / nicht verifiziert

- **Nicht geprüft:** nur unter Windows 11 gelaufen (ubuntu/macOS ungetestet); die nvim-config-Specs laufen
  nicht in der CI. Dashboard headless geprüft, aber `D` mit echtem `ui.kit.confirm`, Clipboard am echten Provider
  und Maus sind ungetestet; die Alt-Kombinationen im Suchfeld sind nur per `nvim_feedkeys` getestet, nicht in einem
  echten Terminal (manche Terminals senden Alt anders).
- **Vorbestehend rot:** `stylua --check` meldet einen Diff in
  `lua/bindings/usrcmds/learn_plan_viewer/init.lua` (nicht Teil dieser Arbeit).
- **Nicht gebaut:** `fs.watch`-Refresh und Frecency im Dashboard; Statusline-Zähler; `--stale` mit
  `refs:`-Prüfung; CI-Check für den Vault.
- **Pilot-/Migrationsqualität:** ca. 40 der `lib.nvim`-Tasks tragen `needs-verification`; Prios, `parked` und
  `decision` sind in allen migrierten Plugins Interpretation der Quellen (steht jeweils in den Notes).
- **Vorgemerkt für die Runde des jeweiligen Plugins:**
  - `rules.nvim`: Gegenprobe NEW-38/NEW-42 **erledigt** (Runde 16): `TESTS/checks_spec.lua:5` trägt die
    `duplicate-set-field`-Unterdrückung (`1ebf0e5`), live `diagnostic count: 0`, Kontrollkopie ohne den Fix 7 Diagnosen,
    NEW-38 per A/B-Test widerlegt. Kleiner Fund am Skript selbst: `Headless-Diagnose-Gegenprobe.md` liest `_G.VERIFY_PATH`,
    wird aber mit der Umgebungsvariable aufgerufen.
  - `markdown.nvim`: `:checkhealth`-Hinweis, wenn mdview erkannt ist, aber `browser.focus` nicht `"nvim"` oder
    `browser.behavior` nicht `"reuse"` ist (Quelle: `mdview.nvim/ROADMAP/personal/LECTURE.md` Abschnitt 6).
  - `filetree.nvim`: Befehl/Taste, die eine Markdown-Datei eines Baumknotens in mdview öffnet (Quelle: mdview `DONE.md`,
    "filetree.nvim cross-check"; in `filetree.nvim/lua` kein Treffer).
  - `mdview.nvim`-Live-Tests L4, QW1, QW10 stehen als offene Checkboxen in `docs/ROADMAP/Final_Checks/PLUGIN_ROADMAPS_TESTPLAN.md`
    (bewusst keine Tasks, R10).
  - Aus der filetree-Runde (jetzt alle Tasks): `images.nvim/paste-powershell-quote-escape`,
    `open.nvim/netrw-banner-lines` und `open.nvim/image-handler-system-fallback`, `lib.nvim/open-default-windows-schemes`
    (**nicht behoben**: `cross.open_default` verstümmelt auf Windows Nicht-http-Schemes; in
    `filetree.nvim/system-open-via-lib-open-default` steht noch „prüfen, ob behoben“ — Antwort nachtragen);
    `gopath.nvim/fs-cache-daemon` sollte einen Rückverweis auf `filetree.nvim/own-tree-engine` bekommen; nvim-config
    `00_ROADMAP.md` („Claude Tasks“) mit den filetree-Task-IDs verlinken.
  - `hover.nvim`: Zoom-Vollbild mit Maus-Markieren/Kopieren und persistenter URL-Cache (stale-while-revalidate) für
    Tricentis-/Microsoft-Doku (Quelle: `docs/ROADMAP/Casedesk/Tasks.md`, nicht in der hover-ROADMAP); dazu die drei
    Tasks aus der media-Runde (`video-seek-seconds`, `broken-link-notify`, `vlc-system-player-live-test`) — nicht
    doppelt anlegen. `hover.nvim` hat noch keine ROADMAP-Migration.
  - `language.nvim`: `subtitle-aware-translate-filter` kommt aus der media-Runde; Roadmap sonst nicht migriert.
  - `replacer.nvim`: `tests-lint-cleanup` kommt aus der gitsuite-Runde; Roadmap-Prosa nicht migriert.
  - `ai.nvim`: das Handover `docs/ROADMAP/handovers/ai/ai.nvim_loomai.md` führt weiter eine eigene Tabelle A1–D1 ohne
    Task-IDs (R9); `scripts/test.sh <datei>` überspringt im Einzeldateimodus echte data.nvim/gitsuite-Tests still
    (GS-21 bestätigt; dieselbe Falle ist bei anderen Plugins mit `add_optional_dep` ungeprüft).
  - `ui.nvim`: das Vault-Buch (`FEATURES.md`, `NOTES.md`) kennt notify, zen, windowpicker, colorpicker, keys, menu und
    `kit.message_log` nicht (Notiz im Task `docs-ui-subcommands-catch-up`); eine Demo-GIF für hover (REL-09) wäre mit
    `ui.screenkey` aufnehmbar — als Hinweis in die hover-Runde.
  - `media.nvim`: in `Final_Checks/media/` der nvim-config steht Abschnitt 9 noch auf „ungeprüft“, obwohl der echte
    whisper.cpp-Lauf am 2026-09-17 stattfand (`a2adf38`).
  - `docmap-desktop` (Desktop-Programm, nicht nvim): die Roadmap dort führt L1, L2, L3, L8, M7b, M12 doppelt, die jetzt
    Tasks in `documentation.nvim` sind — dort Zeiger statt Kopien setzen; offene Live-Tests A1/A3, A2 (Tripwire), L6, L7,
    L10, L11, I18N-4, Cross-Repo-Dashboard; Folge-Tasks, falls `github_stats.nvim/on-demand-live-fetch` gebaut wird.
  - `runtime-analysis.nvim`: M11 (Endpoint-Inventar × Request-History), L4, L5 aus `documentation.nvim`.
  - nvim-config: Save-Cursor/Fold-Bugreport (`bugreports/save-cursor-and-fold-reset.md`, Ursache offen);
    Altkopie `docs/ROADMAP/Casedesk/HANDOVER.md` weicht um eine Tabellenzeile vom Vault-Original ab; „gopath
    `load_from_disk` aus `setup()`“ steht noch in `startup-offene-entscheidungen-und-neotest-listener-2026-10-02.md`
    (jetzt Task `gopath.nvim/cache-load-from-disk-lazy`).
- **Bekannte Eigenheiten:** Titel mit ` #` werden nach YAML-Regel abgeschnitten (`check` warnt, außer der Titel ist
  gequotet); Namespace `tasks` ist generisch (bei Kollision umbenennen); `tasks index --check` im Editor führt die
  volle Regelprüfung aus, im CLI nur die Staleness; `new` hat kein `--blocked_by` (erst `new --status=blocked`, dann
  `set blocked_by=…`); der Slug entsteht aus dem ganzen Titel (bei langen Titeln `--slug=` angeben).
- **`md_lint`-Rest:** die Alt-Meldungen in der lsp-ROADMAP (TOC-Anker mit `&`, Beispiel-Links im Envlinks-Report) sind
  vorbestehend und betreffen die Anker-Konvention bzw. absichtlich kaputte Beispiele.

## Nächste Schritte

1. **Phase 4 — Migration: abgeschlossen** (Runden 1–36, alle Bereiche geprüft). Offene Lücken in migrierten Bereichen, die
   noch keinen Task haben: `media.nvim` (`Final_Checks/media/live-testing-plan.md`, Abschnitt 9 steht auf „ungeprüft“, obwohl der
   whisper.cpp-Lauf am 2026-09-17 war), `ui.nvim` (`Final_Checks/ui.nvim.md`, 9 Punkte Sticky-Context), `lib.nvim`
   (`Final_Checks/modifier-keymaps.md` §8), Badge-Modul für `nvim-config/learn-plan-viewer-statusline-badge`;
   `gopath.nvim/fs-cache-daemon` ohne Rückverweis auf `filetree.nvim/own-tree-engine`; `filetree.nvim/system-open-via-lib-open-default`
   weiter ungeklärt.
2. `lib.nvim/project-scan-missing-parsers-and-tools` und `lsp.nvim/config-unknown-key-warning` bauen (wenn gewünscht).
3. `pickers.nvim`: generische Items-Quelle (`pickers.nvim/generic-items-source`, Konzept §6) bauen.
4. Phase 5: Politur (Statusline, `mdview`, `--stale`, Vault-CI).
