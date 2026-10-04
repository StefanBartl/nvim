# Handover — Task-System für die wkdbooks

> **Stand 2026-10-04 (Zwischenstand).** Phasen 0–3 sind gebaut und auf `main`; **Phase 4 (Migration) läuft**:
> migriert und committet sind `lib.nvim` (Pilot), `lsp.nvim`, `mdview.nvim`, `documentation.nvim`, `casedesk.nvim`,
> `markdown.nvim`, `gopath.nvim`, `github_stats.nvim`; `pickers.nvim` hat seinen ersten Task. **In Arbeit (Agenten
> laufen):** `filetree.nvim`, `spotlight.nvim`. Danach ist Schluss für diese Sitzung; offen bleiben die übrigen
> Plugins (Größenordnung: `images`, `pdfport`, `open`, `gitsuite`, `color_my_ascii`, `migrate`, `rules`, `media`, `ai`,
> `ui`, `debugging`, … und `docmap-desktop`) und die Politur (Phase 5). **Die gesammelten Entscheidungen für den Nutzer
> stehen im Abschnitt „Offene Entscheidungen“ unten.**
>
> **Konzept (Spec, Regeln R1–R12, Entscheidungen):**
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
| Headless-CLI | nvim-config: `scripts/tasks.lua` — `nvim --headless -u NONE -l scripts/tasks.lua <list\|index\|new\|set\|done\|check\|template\|areas\|export>` |
| `:MyPlugins`-Routen | nvim-config: `lua/bindings/usrcmds/plugin_repos/` (Routen-Datei + `README.md`) |
| Dashboard | nvim-config: neben `plugin_repos/picker.lua` (Snacks-Picker, Fallback ohne Snacks) |
| Specs der Engine | nvim-config: `TESTS/` (Runner `nvim -n -i NONE --headless -u NONE -l TESTS/run.lua`) |
| Migrierte Plugins | Vault, jeweils `ROADMAP/tasks/` + generierte `ROADMAP/TASKS.md`: `lib.nvim` (Pilot, 58), `documentation.nvim` (55), `casedesk.nvim` (28), `lsp.nvim` (14 offen), `mdview.nvim` (11), `markdown.nvim` (6), `github_stats.nvim` (5), `gopath.nvim` (4), `pickers.nvim` (1) |
| Brief für Migrations-Agenten | `C:\Users\bartl\AppData\Local\Temp\claude\…\scratchpad\migration-brief.md` (nur in der Sitzung; Inhalt = Abschnitt „Nächste Schritte“ Punkt 1 dieser Datei) |
| Regeln R1–R12 | Vault-`README.md`, Abschnitt "Open tasks" |
| Env-Link-Prüfung | Vault `TOOLS/scripts/md_lint.lua` löst `$VAR/…`-Links mit `lsp.core.env_links` (lsp.nvim) auf |

## Bedienung (verb-first, kein plugin-first-Shim — entschieden)

```
:MyPlugins tasks [<area>|all] [--status= --prio= --kind= --tag= --stale=<d> --blocked] [--to=buffer|file:<p>|clipboard|qf] [--format=md|csv]
:MyPlugins tasks index [<area>|--all] [--check]
:MyPlugins task new <area> [title…] [kind= prio= effort= tags= status=]
:MyPlugins task set <id> key=value…
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

Review: Der Code von `2bc2874`, `ef8641fa`, `be270dfa`, `c61cd4f1` wurde durch einen Review-Agenten adversarial
geprüft (13 Befunde behoben). Die Fix-Commits `c6d274c`, `efcab018`, `80ef2946` hat Claude am 2026-10-04 selbst
gelesen (ein Befund → `9ca296e9`), **nicht** per `ultracode`. `ded6d10b` und `04c2aeae` sind ebenfalls nicht per
Agent reviewt.

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
- **gopath.nvim:** keine; optional `cache-load-from-disk-lazy` auf Prio 2, falls `startup-stall-measure` mehr Last zeigt.
- **lsp.nvim / mdview.nvim:** beantwortet (siehe „Entscheidungen“); `live-check-lspsaga-replacements` und
  `scroll-lag-feel-judgement` bleiben Tasks.

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
  - `rules.nvim`: Gegenprobe der Funde NEW-38/NEW-42 (`rules.nvim/handovers/2026-09-13-self-review-fixes.md`) wurde nie
    wiederholt, das Diagnose-Skript meldet weiter `diagnostic count: 0`.
  - `markdown.nvim`: `:checkhealth`-Hinweis, wenn mdview erkannt ist, aber `browser.focus` nicht `"nvim"` oder
    `browser.behavior` nicht `"reuse"` ist (Quelle: `mdview.nvim/ROADMAP/personal/LECTURE.md` Abschnitt 6).
  - `filetree.nvim`: Befehl/Taste, die eine Markdown-Datei eines Baumknotens in mdview öffnet (Quelle: mdview `DONE.md`,
    "filetree.nvim cross-check"; in `filetree.nvim/lua` kein Treffer).
  - `mdview.nvim`-Live-Tests L4, QW1, QW10 stehen als offene Checkboxen in `docs/ROADMAP/Final_Checks/PLUGIN_ROADMAPS_TESTPLAN.md`
    (bewusst keine Tasks, R10).
  - `hover.nvim`: Zoom-Vollbild mit Maus-Markieren/Kopieren und persistenter URL-Cache (stale-while-revalidate) für
    Tricentis-/Microsoft-Doku (Quelle: `docs/ROADMAP/Casedesk/Tasks.md`, nicht in der hover-ROADMAP).
  - `images.nvim`: Windows-OCR-Backend `Windows.Media.Ocr` (casedesk RM-22; Vergleich in `docs/ROADMAP/Casedesk/ocr.md`).
  - `ui.nvim`: Marks-Reihenfolge „auf der Workstation“ (casedesk-ROADMAP §10); Sweep „Cancel löst unabhängige
    Folgeaktion aus“ (`docs/ROADMAP/Final_Checks/workflows-interactive-confirm.md`, gehört nach nvim-config oder ui.nvim).
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

1. **Phase 4 — Migration** weiter, pro Plugin eine Runde (Regel: max. 1 Agent gleichzeitig; in dieser Sitzung wurde
   auf ausdrücklichen Wunsch ausnahmsweise mit 3 gearbeitet): ROADMAP/NOTES/Handover lesen, offene Punkte als
   Task-Dateien (CLI `new … --slug= --lang=`), Prosa bleibt mit Link auf `TASKS.md`. Noch offen nach Menge (Roadmap-KB):
   `docmap-desktop` (188, Desktop-Programm — erst klären, ob es überhaupt in dieses System gehört), `images` (50),
   `pdfport` (43), `open` (41), `gitsuite` (37), `color_my_ascii` (31+33 NOTES), `migrate` (30), `rules` (29), `media`
   (22+63), `ai` (21), `ui` (19), `debugging` (19), danach die kleinen. Vorher sauberer Git-Stand im Vault. Brief für die
   Agenten: Quellen lesen, gegen den Baum nachmessen, Erledigtes nicht anlegen (veraltete „offen“-Angaben mit Beleg
   korrigieren), Bedingungen aus Roadmap-Einträgen in den Task übernehmen, nichts committen; Commit mit expliziten
   Pfaden macht die Hauptsession nach Stichprobe gegen den Code.
2. `lib.nvim/project-scan-missing-parsers-and-tools` und `lsp.nvim/config-unknown-key-warning` bauen (wenn gewünscht).
3. `pickers.nvim`: generische Items-Quelle (`pickers.nvim/generic-items-source`, Konzept §6) bauen.
4. Phase 5: Politur (Statusline, `mdview`, `--stale`, Vault-CI).
