# Handover — Task-System für die wkdbooks

> **Stand 2026-10-04 (Zwischenstand, nach Runde 21).** Phasen 0–3 sind gebaut und auf `main`; **Phase 4 (Migration) läuft**:
> migriert und committet sind `lib.nvim` (Pilot), `lsp.nvim`, `mdview.nvim`, `documentation.nvim`, `casedesk.nvim`,
> `markdown.nvim`, `gopath.nvim`, `github_stats.nvim`, `filetree.nvim`, `images.nvim`, `pdfport.nvim`, `open.nvim`,
> `gitsuite.nvim`, `color_my_ascii.nvim`, `rules.nvim`, `media.nvim`, `ai.nvim`, `ui.nvim`, `debugging.nvim`, `insights.nvim`; `spotlight.nvim` und
> `migrate.nvim` sind geprüft (keine offene Arbeit, keine Tasks); `pickers.nvim`, `hover.nvim`, `language.nvim` und
> `replacer.nvim` haben je einzelne Tasks aus fremden Runden (ihre eigene Runde steht aus). Keine Agenten laufen mehr.
> Nach Runde 19 (`ui`) wurde auf Wunsch kurz angehalten, Runde 20 (`debugging`) lief danach; offen sind die kleinen Plugins (Liste
> unter „Nächste Schritte“), `docmap-desktop`, `nvim-config` und die Politur (Phase 5).
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
| Migrierte Plugins | Vault, jeweils `ROADMAP/tasks/` + generierte `ROADMAP/TASKS.md`: `lib.nvim` (Pilot, 58), `documentation.nvim` (55), `casedesk.nvim` (28), `lsp.nvim` (14 offen), `mdview.nvim` (11), `markdown.nvim` (6), `github_stats.nvim` (5), `gopath.nvim` (4), `pickers.nvim` (1), `images.nvim` (24), `pdfport.nvim` (7), `open.nvim` (8), `gitsuite.nvim` (5), `color_my_ascii.nvim` (11), `rules.nvim` (7), `media.nvim` (10), `ai.nvim` (15), `ui.nvim` (13), `debugging.nvim` (5), `insights.nvim` (4); einzelne Tasks fremder Runden in `lib.nvim` (+2), `hover.nvim` (3), `language.nvim` (1), `replacer.nvim` (1) |
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

## Kategorien und Ordner-Tasks (neu, Konzept §12)

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
| WKDBooks | `da40a62` | Konzept §12, Regeln R13 und R14 |
| WKDBooks | `932fac8` | `debugging.nvim`: 5 Tasks (Runde 20); „Offen“ der ROADMAP war das gebaute Recent-Popup, durch Verweis ersetzt (Commit trägt versehentlich einen Claude-Co-Author-Trailer, gepusht) |
| WKDBooks | `c36036a` | `insights.nvim`: 4 Tasks (Runde 21), nur das SYNERGIE-Papier war offen; gebaute Features in FEATURES.md nachgetragen |

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

## Offene Entscheidungen (warten auf den Nutzer)

Offen sind die Runden 10–19 (außer `open.nvim`, dort ist alles entschieden und im Vault eingetragen: Image-Fallback
im Code nachziehen, benannten Browser ohne `cmd.exe` starten, kein doppelter Menüeintrag). Empfehlung jeweils in
Klammern; die Tasks stehen unter `<plugin>/ROADMAP/tasks/<slug>.md`.

- **images.nvim:** `image-suite-decision` (dünne Suite ja/nein — erst die Einzelfunde); Sixel-Backend (nein; Kitty bleibt
  verworfen); Rotate/Flip (nicht anlegen); `gopath-open-action-for-images`, `docmap-graph-as-image`,
  `github-stats-chart-as-image` in die Bereiche gopath/documentation/github_stats umziehen (ja, bei deren Runde);
  `magick-resource-limits`, `draw-payload-cache` (prio 3, schwach belegt: behalten?). Bugs prio 2:
  `paste-powershell-quote-escape` (nur bei Temp-Pfad mit typografischem Quote), `convert-failure-deletes-existing-target`.
- **pdfport.nvim:** keine Tasks für benannte Fehlertypen (nein), `wkhtmltopdf`/eigenen `typst`-Producer (nicht bauen,
  PDF_CREATE.md korrigieren), echte Tool-Läufe in CI (lassen). Bugs prio 2: `soffice-detect-install-paths`,
  `rasterize-timeout`.
- **gitsuite.nvim:** `own-engine-lazygit-neogit` (verwerfen oder parken, Scope schließt Staging-UI aus);
  `terminal-spawn-helper` (zählen Split-Terminals als zweiter Konsument? ja, dann bauen); `diffview-replacement`
  (Status quo, Fallback diff.nvim genügt); ungetriagte Ideen (`:Git conflict diff`, Hunk-Navigation `]c`/`[c`, Textobjekt
  `ih`) nicht anlegen.
- **color_my_ascii.nvim:** `custom-groups-dead-option` (entfernen, `overrides` reicht); `language-registry-hot-reload`
  (verwerfen); `fence-folding` (vermutlich verwerfen, eher markdown.nvim); „Planned for 2.0.0“ aus `docs/CHANGELOG.md`
  (verwerfen); `visible-range-highlighting` erst nach festem Messfall; `fence-user-event` bleibt geparkt, bis ein
  Verbraucher benannt ist.
- **rules.nvim:** Agent-Strang überhaupt angehen? (erst `agent-plan-validate` und `rules-json-project-config`, beide
  nützen auch ohne Agent); Cross-Plugin-Ideen aus dem BACKLOG nicht anlegen; `rules.nvim/TASK-documentation.nvim.md` ist
  erledigt und gehört nach `Backlog/TASKS/` (verschieben); `diff-ref-completion` geparkt lassen.
- **media.nvim:** `bare-media-command`, `hub-missing-actions`, `hub-office-files` (je `decision`, Empfehlung in den
  Task-Notes); `openai_whisper` als eigene Engine streichen; Oktanten/`chafa` gehört zu images.nvim (nicht anlegen);
  Diarisierung unspezifisch (nicht anlegen). Prio 2: `cache-eviction`, `language.nvim/subtitle-aware-translate-filter`.
- **ai.nvim:** `repo-instructions-and-hooks` (nur System-Prompt-Teil, erst nach `agent-presets`, keine Hooks wegen
  Prompt-Injektion); `readme-literature-section` (anlegen, kurz); Chat-Buffer-Sessions ablehnen (Scope, bleibt loomAI);
  `copilot-provider` (verwerfen, falls kein Bedarf); `:Ai stop` zuerst nur für Streams. `release-v1-tag` ist `blocked`
  ohne `blocked_by`: die Voraussetzungen (Alltagsdurchlauf, Gemini-Live-Test, POSIX-Durchlauf) stehen als Akzeptanz.
- **debugging.nvim:** `views-dead-refresh-sweep` (Status `decision`: tote Refresh-Mechanik `refresh_log_view`, WinEnter/BufWinEnter/FileType-Autocmds, `is_target_view` und die Optionen `delay_messages_ms`, `delay_noice_ms`, `capture_timeout_ms` entfernen? Empfehlung: ja, eigene Config anpassen; `setup()` warnt seit `0cde049` bei unbekannten Schlüsseln); `lib.nvim.messages` hat keinen Statusabruf für `health-recent-popup-requirements` (abwarten). Bug prio 2: `recent-fallback-multiline-crash` (ohne ui.nvim stürzt `<lt>m/n/e` bei mehrzeiligen Meldungen ab, `views/recent.lua:59`); `docs-recent-popup-catch-up` (Doku und `health.lua` „Noice views“ veraltet). `lib.nvim/tagged-scratch-window` ist veraltet (debugging.nvim nutzt `lib.nvim.window.tag`, das Popup ist der zweite Konsument) — Task nachziehen.
- **insights.nvim:** `telemetry-subcommand-usage` (Status `decision`: selbst messen? Empfehlung: nein, nur Host-seitig); `architecture-md-todos-drift` (handgepflegt lassen, nur `todos/` ergänzen); `metrics-docmap-section` geparkt. `readme-documentation-pointer` (Verweis fehlt in beiden READMEs). Info für `filetree.nvim/insights-node-actions`: `insights.compress.compress(path, …)` nimmt einen Pfad, `tree.write_tree/count_files/copy_to_clipboard` arbeiten nur auf dem cwd.
- **ui.nvim:** noice-Ersatz geparkt lassen; `interactive-confirm-sweep` (Status `decision`: Besitzer `ALL` mit neuem
  `ALL/ROADMAP/tasks/` — Konzept §2 erlaubt es, der Ordner existiert noch nicht); `kit-terminal-vs-snacks` (Snacks.terminal
  bleiben); gebündelte Ideen-Tasks `statusline-ambient-ideas`, `sticky-language-gaps` so lassen oder einzeln; `wezterm-bridge`
  (bauen oder verwerfen); Marks-Reihenfolge „Workstation“ gehört in die nvim-config-Runde (`lua/config/marks/defaults.lua`,
  Workstation-Satz hat 5 Einträge, die „Liste von acht Pfaden“ steht nirgends mehr); `Logo im Menü` nicht angelegt;
  von den opt-in-Statusline-Modulen verdrahtet die nvim-config nur `search_count` und `undo_depth` — welche weiteren?
  Bugs prio 2: `context-kotlin-when-branches` (`^struct` in `context/init.lua:168` nimmt den Kotlin-Zweig `1 -> {` weg,
  Suite 1057 ok / 1 rot, die CI sieht es nicht), `screenkey-secret-input-protection` (security, `vim.on_key` sieht
  `inputsecret()`), `docs-ui-subcommands-catch-up` (docs).
- **Abgeleitete Besitzerfragen:** `lib.nvim` hat fünf Tasks mit „Ort ui.nvim oder lib.nvim?“ (`history-stack-ui-kit`,
  `tui-dashboard-kit`, `ui-kit-playground`, `create-on-missing-dialog`, `messages-module-cut`); `ui.kit` in ui.nvim ist laut
  PLAN maßgeblich, die Frozen-Kopie in lib.nvim ist nicht mehr feature-frei (`message_log.lua` liegt in beiden).

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

1. **Phase 4 — Migration** weiter, pro Plugin eine Runde (Regel: **max. 1 Agent gleichzeitig**). Fertig bis Runde 20
   (`debugging`). Noch offen: die kleinen — `my` (10), `language` (9), `hover` (9),
   `buffer-ctx` (7), `runtime-analysis` (6), `data` (5), `replacer` (3), `cascade` (3), `sandbox` (2), `reposcope` (2),
   `sessions` (1), `emojis` (1) — dann die Bereiche mit leerer oder fehlender Roadmap (`diff`, `cmdlog`, `dap`, `fileops`,
   `recommender`, `refinder`, `filetreepicker`, `nvim-nexus`; kurz prüfen), zuletzt `nvim-config` und `docmap-desktop`
   (188 KB, Desktop-Programm — erst klären, ob es überhaupt in dieses System gehört; die Desktop-Seite des Agent-Konzepts
   P2–P7 aus `rules.nvim` landet dort). Für `hover`, `language` und `replacer` zuerst die schon angelegten Tasks lesen.
   Brief für die Agenten: Quellen lesen, gegen den Baum nachmessen, Erledigtes nicht anlegen (veraltete „offen“-Angaben mit
   Beleg korrigieren), Bedingungen aus Roadmap-Einträgen in den Task übernehmen, `--category=` setzen wo es klar passt,
   Optionen mit Doppelstrich, **CLI aus dem Worktree/aktuellen Stand** (Kategorien und `--folder` gibt es erst ab
   `f974551d`), nichts committen; Commit mit expliziten Pfaden macht die Hauptsession nach Stichprobe gegen den Code. Vorher
   sauberer Git-Stand im Vault (fremde Dateien: `Spickzettel/`, `TOOLS/scripts/tui-spike/`, `wkdbook-takt/` nie anfassen).
2. `lib.nvim/project-scan-missing-parsers-and-tools` und `lsp.nvim/config-unknown-key-warning` bauen (wenn gewünscht).
3. `pickers.nvim`: generische Items-Quelle (`pickers.nvim/generic-items-source`, Konzept §6) bauen.
4. Phase 5: Politur (Statusline, `mdview`, `--stale`, Vault-CI).
