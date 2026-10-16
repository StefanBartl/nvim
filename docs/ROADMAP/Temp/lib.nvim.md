Stand 2026-10-16. Das ausführliche Handover liegt im Vault (`tasks-vault/lib.nvim/handovers/session-stand-2026-10-15_HANDOVER.md`, zuletzt `4d0b90d`); der Symlink in `docs/ROADMAP/handovers` zeigt darauf. Diese Datei hält nur, was in diesem Chat noch zu tun ist.

## Noch in diesem Chat zu tun

**1. Reviews (Pflicht, bevor etwas als fertig gilt)**
- `1a5ddb9` (sessions.nvim): `sessions.portable` als Wrapper über `lib.nvim.fs.portable`. Nur CI grün, nicht reviewt.
- `567e60d` (replacer.nvim): `replacer.hooks` setzt auf `lib.nvim.hooks` auf. Nur CI grün, nicht reviewt.
- Prüfpunkte: Spec-Anpassung `"aa"`/`"aaa"` in sessions.nvim (neue Regel vor dem Treffer) und ob replacer wirklich überall `vetoable = alle vier Events` braucht.

**2. Migration, noch offen**
- `documentation.nvim/lang-registry-auf-lib-nvim-registry-umstellen` (M): `lang_registry.lua` auf `lib.nvim.registry`. Dasselbe Vorgehen wie bei replacer: Charakterisierungs-Tests gegen alt und neu.

**3. Tasks, die bereit sind (lib.nvim)**
- `lib.nvim/net-curl-download-cached-obergrenze-fuer-den-cache-alter-gro` (S): Alters- und Größengrenze für den Download-Cache (Vorlage: media.nvim).
- `lib.nvim/window-matches-split-kopierte-matches-im-ledger-behandeln` (S): Vim kopiert Matches bei `:split` ins neue Fenster, das Ledger kennt sie nicht.
- `lib.nvim/scoring-name-delta-pruefung-nur-an-einer-stelle` (XS): Name/Delta-Prüfung an einer Stelle bündeln (vorher prüfen, ob `36bed5d` es schon deckt).
- `lib.nvim/ci-verified-publish-race-bei-zwei-schnell-aufeinanderfolgend` (S, Bug): `publish ci-verified` scheitert am Push, wenn zwei Pushes dicht aufeinander folgen (Tests grün, Branch enthält den Commit trotzdem).
- `lib.nvim/project-scan-missing-parsers-and-tools` (M): laut `next` die nächste, braucht vorher eine kurze Planung (baut auf `lib.nvim.deps` und `treesitter.parser_policy`).

**4. Verbraucher der neuen Bausteine (anderes Repo)**
- `debugging.nvim/health-recent-popup-requirements` (S, entsperrt): nutzt `messages.status()` in `health.lua`.
- testing.nvim Explorer: erster Verbraucher von `keymap.cheatsheet` (Task dafür noch nicht angelegt).
- Rein kosmetisch: `github_stats.nvim/api.lua` könnte `raw_args = { "--max-filesize", … }` durch `max_bytes` ersetzen. Eine Migration auf `download_cached` entfällt (es holt JSON, keine Dateien).

**5. Aufräumen**
- Nach jedem `done` im Vault prüfen, ob ein "value estimates"-Lauf fertige Tasks in `ROADMAP/tasks/` wiederhergestellt hat (`check` meldet dann `duplicate-id`).

## Braucht dich

- `hover.nvim` Mausrad-Zoom (actor=pair, du bestätigst die Tasten).
- `docmap-desktop/rules-api-catalog-and-run` (erst klären, ob es mit der laufenden rules.nvim-Arbeit kollidiert).
- `documentation.nvim/repo-named-paths-outside-root` (Sicherheitsentscheidung).
- ~~`lib.nvim` help-float-Entscheidung~~ erledigt am 2026-10-16: migriert (ui.nvim `834591a`), `spec.quotes`: keine weiteren Verben. Siehe Abschnitt "Chat usrcmd-help-float" unten.
- `testing.nvim/cache-affected-remaining-limits` (zwei Entscheidungen: Lese-Ledger, State-Warn bei `soft`).
- Handchecks: `gx` auf einen Env-Link in einem echten Neovim 0.12 und `live-check-lspsaga-replacements`.
- Entscheidung zum Stern: Alle Code-Commits wurden mit Reasoning "hoch" reviewt, keiner mit `ultracode`. Soll "hoch" für den Stern reichen?

## Dieser Chat bisher (Kurzfassung)

Gebaut und gereviewt in lib.nvim: `fs.write.atomic` (Symlink-Ziel), `spawn_command`/`spawn_shell_command` (Handle zuerst schließen), `markdown.table` (CR je Zeile), `run_argv` (PID-Wiederverwendung unter Windows, Ursache der Flakes), `hooks`, `fs.portable`, `composer.help` (Completion-Werte eigener Typen), `strings.utf8.scrub`, `cache` (`:Lib cache stats`), `git` (skip-worktree, Peel-Pfade auf jedem git), `lua.scoring`, `window.matches`, `messages.status()`, `keymap.cheatsheet`, `lib.nvim.registry`, `window.best_target_window`, `buf_win_tab.tab_buffers`, `treesitter.regions`, `terminal.capabilities`, `net.curl.download_cached`. Migriert: nvim-config (`buffer_jump`), sessions.nvim, replacer.nvim.

## Commits dieses Chats

| Commit | Repo | Beschreibung | Review |
|---|---|---|---|
| `7f5d584` | lib.nvim | fs.write.atomic Symlink, spawn on_exit, table partial CR | ✅ |
| `2142700` | lib.nvim | run_argv: taskkill-Callback signalisiert keinen geschlossenen Job | ✅ |
| `a80002e`, `b825356` | lib.nvim | `lib.nvim.hooks`, `lib.nvim.fs.portable` | ✅ |
| `5db98db`, `cbee792` | lib.nvim | Review-Fixes zu den vorigen | Fix-Commits |
| `5186175`, `d8c4349`, `7431033`, `b8fb8eb`, `3f9a600` | lib.nvim | help-float-Completion, utf8.scrub, cache stats, git-Peel-Test, skip-worktree | ✅ |
| `a9986c1`, `3c9b7de`, `68378c1`, `4569147`, `b7e1498` | lib.nvim | scoring, window.matches, messages.status, keymap.cheatsheet, registry | ✅ |
| `4bf4aa7`, `c3e4d61` (+ `97ce134`, `3dbfd62`, `36bed5d` der anderen Sitzung) | lib.nvim | Review-Fixes und Test-Wartezeit | Fix-Commits |
| `364cc68`, `f9c16a9`, `061f542`, `b15f611`, `247e610` | lib.nvim | best_target_window, tab_buffers, regions, capabilities, download_cached | ✅ |
| `aae5ad9` | lib.nvim | Review-Fixes zu den fünf oberen | Fix-Commit (CI ✅) |
| `efed67f1` | nvim-config | buffer_jump nutzt `tab_buffers` | ✅ |
| `1a5ddb9` | sessions.nvim | `sessions.portable` als Wrapper über `fs.portable` | **offen** (CI ✅) |
| `567e60d` | replacer.nvim | `replacer.hooks` setzt auf `lib.nvim.hooks` auf | **offen** (CI ✅) |
| `06a3976`, `3bec562`, `162a9ba`, `ca57fd3`, `9dca3a9`, `e1c6145`, `a0309a5`, `217c624`, `177bbc0`, `4dfdd91`, `415a492`, `2e5130d`, `8a0df82`, `4d0b90d` | tasks-vault | Tasks auf done, Cache-Task, Handover | ✅ (reine Doku) |

Haken = durch Reasoning über "normal" reviewt; keiner hat einen Stern (ultracode).

## Umgebung und Regeln

- Im lib.nvim-Worktree scheitern `telemetry_wrap_spec` (braucht `RUNTIME_ANALYSIS_DIR=E:/repos/runtime-analysis.nvim`) und `git_spec` (Branchname statt `main`); das ist erwartet.
- Vor jedem Push: `stylua --check .` und die Vollsuite abwarten, das Push-Kommando daran binden.
- Backslashes nie durch Heredocs oder Python-Strings, nur per Write/Edit oder `chr(92)`; im Handover/Notizen nicht ausschreiben.
- Eine Sabotage ändert genau eine Stelle; erst dann beweist der neue Test etwas.
- In der nvim-config nur die eigene Datei per Pfad committen (dort liegen fremde uncommittete Änderungen).

---

# Chat usrcmd-help-float und tasks.nvim-Umstellung (2026-10-16)

Handover des Themas: `docs/ROADMAP/handovers/usrcmd-help-float_HANDOVER.md` (Plan `usrcmd-help-float-cheatsheet` ist abgeschlossen, alle seine Tasks sind done).

## Erledigt in diesem Chat

- `spec.quotes`-Rollout entschieden: kein weiteres Verb (nur Verben mit eigenem Quote-Tokenizer, das sind replacer und markdown `table_wrap`). Task done.
- Task `wkdbook-tasks.nvim/tasks-nvim-auf-lib-contract-umstellen` done: tasks.nvim nutzt `lib.nvim.contract.*`, `json.canonical`, `fs.etag/with_lock/create_exclusive` (Kopien gelöscht). Goldens, `digest`, 69 Specs unverändert grün, CI grün in tasks.nvim und tasks-desktop.
- Review-Funde 1 bis 4 der Umstellung behoben (`2e25a03`), die drei Aufräum-Tasks (Funde 5 bis 7) erledigt (`a0d05fc`).
- Entscheidung `:UI`: **migrieren**. `:UI`/`:Theme` sind Composer-Verben (ui.nvim `834591a`, 24 Routen, Spec `TESTS/usrcmd_help_spec.lua`, CI grün). Task done.

## Noch offen (aus diesem Chat)

**1. Funde aus den zwei letzten Reviews, noch nicht behoben, noch keine Tasks**

ui.nvim `834591a` (6 Funde):
- README `lua/ui/bindings/usrcmds/README.md` nennt `<M-h>` als Standardtaste. Falsch: die Composer-Hilfe hat keinen Default, `<M-h>` ist nur die Einstellung der nvim-config. Korrigieren (nach `help.keymap` verweisen).
- `ui_help` (statischer Hilfekasten) ist eine zweite, handgepflegte Liste neben den Routen-Texten: aus `ROUTES` erzeugen oder `:UI help` auf den Float reduzieren.
- Verhaltensänderungen nirgends notiert: `:Theme a b` wird nicht mehr abgelehnt (nimmt nur das erste Wort), ein nacktes `:UI` zeigt den Float statt des Hilfetexts. In README und Changelog nachtragen.
- Die sechs Composer-Typen (`UI_THEME`, `UI_VARIANT`, `UI_TABLINE_STYLE`, `UI_KIT_PRESET`, `UI_SLOT_WORD`, `UI_STICKY_WORD`) werden beim `require` ins globale Typ-Register geschrieben: in `setup()` verlegen oder Namen mit Präfix versehen.
- `STICKY_ARGS` und `ON_OFF` sind zwischen mehreren Routen geteilte Tabellen: pro Route frisch bauen.
- Spec: stellt das Colorscheme nicht zurück, wenn vorher keines gesetzt war; die 24 Routennamen sind fest eingetragen (Fehlermeldung nennt nicht, welcher Name neu ist).

tasks.nvim `a0d05fc` (4 Funde, gering):
- Der gelöschte `tasks_json_spec` war die einzige tasks.nvim-seitige Absicherung der Encoder-Regeln (leeres Objekt vs. Array, NaN/inf/2^53, Escaping von `<`/U+2028): ein kleiner Spec mit den Garantien von tasks-export/1 sollte bleiben.
- `fsio.copy` gibt `M.EXISTS` zurück, das jetzt dem Token von `create_exclusive` gehört: eigene Konstante für `copy` oder das Lib-Token ausdrücklich zurückgeben.
- Über 50 Aufrufstellen `door.failure(ctx.root, ...)` / `door.refuse(...)` und die spät zugewiesene `door`-Variable in `ops.lua` (ein dünner lokaler Helfer wäre kleiner).
- CHANGELOG ohne Zeile für diese Änderung; README nennt noch "44 spec files" (es sind 69).

Vorschlag: die Funde 1 bis 4 aus ui.nvim und die zwei Test-/Konstanten-Funde aus tasks.nvim beheben, den Rest als Tasks (Area `ui.nvim` bzw. `wkdbook-tasks.nvim`) anlegen. Danach die Fix-Commits ohne neues Review (Fix-Commits).

**2. Nicht geprüft**
- Der Option-Float von `:UI` wurde in keiner echten Sitzung angesehen (nur Specs: Routen, Texte, Completion, Dispatch). Einmal in der echten nvim-config `:UI` und `:UI sticky ` mit `<M-h>` ausprobieren.
- tasks-desktop: die lokale Browser-E2E (`pnpm e2e`) lief nicht, weil ein Hub auf Port 17698 läuft (nicht von mir gestartet, nicht beendet). Die E2E lief in der CI (grün). Wer will, stoppt den Hub und fährt sie lokal.
- Der Pin `tasks.nvim 98a1d02` in tasks-desktop gilt noch; neuere tasks.nvim-Commits (`2e25a03`, `a0d05fc`) ändern den Vertrag nicht, ein Nachziehen von `engine.lock` ist nicht nötig.

**3. Fremdes, das ich gesehen und nicht angefasst habe**
- tasks.nvim: ungestagte Änderung in `lua/tasks_nvim/links.lua` (andere Sitzung).
- Vault `check wkdbook-tasks.nvim`: `obsidian-docs` und `obsidian-wikilinks` haben `blocker-freed` (Status `blocked`, alle Blocker erledigt: auf `open` setzen).
- nvim-config: fremde ungestagte Dateien (`docs/NOTES/CDX/templates/PROMPT/Base.md`, ein Plan-File gelöscht).

## Commits dieses Chats

| Commit | Repo | Beschreibung | Review |
|---|---|---|---|
| `5068448` | tasks-vault | spec.quotes-Rollout entschieden, Task done | ✅ (Doku) |
| `6cf07f9` | tasks.nvim | contract/api/host/errors/json auf lib.nvim.contract.* | ⭐ (hoch, 7 Funde) |
| `98a1d02` | tasks.nvim | ops auf contract.ops, fsio auf lib.nvim.fs.* | ⭐ (hoch) |
| `2fe5896` | tasks-desktop | engine.lock auf tasks.nvim `98a1d02` | – (Pin, CI ✅) |
| `f65d003` | tasks-vault | tasks-nvim-auf-lib-contract-umstellen done | ✅ (Doku) |
| `beddf504` | nvim-config | Handover usrcmd-help-float aktualisiert | ✅ (Doku) |
| `2e25a03` | tasks.nvim | Fix der Funde 1 bis 4 | Fix-Commit |
| `481d91c` | tasks-vault | drei Aufräum-Tasks | ✅ (Doku) |
| `a0d05fc` | tasks.nvim | fsio EXISTS/is_exists, ops ohne Wrapper, json-Spec entfernt | reviewt (hoch), 4 Funde **offen** |
| `7bfc62d` (+ Korrektur) | tasks-vault | die drei Tasks done | ✅ (Doku) |
| `834591a` | ui.nvim | `:UI`/`:Theme` als Composer-Verben | reviewt (hoch), 6 Funde **offen** |
| (Vault) | tasks-vault | help-float-ui-usercmd-decision done, Plan abgeschlossen | ✅ (Doku) |

Haken = Review über "normal"; Stern = hoch (ultracode wurde nicht benutzt; ob "hoch" für den Stern reicht, siehe oben).
