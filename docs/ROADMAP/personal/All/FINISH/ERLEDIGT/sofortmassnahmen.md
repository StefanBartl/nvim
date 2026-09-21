# CI-Sofortmaßnahmen — erledigt am 2026-09-21

> Ausgelagert aus [testing.md §D.9.0](../../../../LONG_RUN/IDEAS/testing.md#d90-sofortmaßnahmen-ohne-specnvim-je--1-tag)
> am 2026-09-20 und am 2026-09-21 vollständig ausgerollt: alle sechs
> Maßnahmen in allen 39 Plugin-Repos. Das Einmal-Werkzeug
> `scripts/ci_hardening.py` ist danach gelöscht worden; die Commits
> `ci: add job timeouts, failure log artifacts, …` je Repo bleiben als Beleg.

## Table of content

- [Status je Maßnahme](#status-je-maßnahme)
- [Rollout-Protokoll](#rollout-protokoll)
- [Was dabei zutage kam](#was-dabei-zutage-kam)
- [Nachprüfung der Rollout-Commits](#nachprüfung-der-rollout-commits)
- [Bewusst offen geblieben](#bewusst-offen-geblieben)
- [Lehren für den nächsten Flotten-Rollout](#lehren-für-den-nächsten-flotten-rollout)

## Status je Maßnahme

| # | Maßnahme | Status | Umsetzung |
|---|---|---|---|
| 1 | `timeout-minutes` in allen Workflows | **erledigt** | 15 min je Job, 30 min bei Build-/Install-Jobs (`cargo`, `wasm-pack`, `npm ci/install`, `tree-sitter build`, `goreleaser`, `apt-get`) |
| 2 | `-n -i NONE` in allen Runner-Aufrufen | **erledigt** | `ci.yml`, `scripts/test.sh`, `scripts/ci.sh`; zusätzlich `swapfile=false` + `shadafile="NONE"` in jeder `minimal_init.lua` (deckt plenarys Kind-Prozesse ab) |
| 3 | Log-Artefakt bei Fehlschlag | **erledigt** | `tee`-Wrap der Test-Steps + `upload-artifact@v7` (Node 24) mit `if: failure()`, 14 Tage Aufbewahrung; im Ernstfall bestätigt (emojis, diff, filetree luden Logs hoch) |
| 4 | `docs/TESTS/` → `TESTS/` (NEW-48) | **erledigt (war schon)** | kein Repo hatte mehr `docs/TESTS/` |
| 5 | `.deps/`-Refs pinnen | **erledigt** | siehe unten: Runde 1 (lib/runtime-analysis/hover + Third-Party auf SHA), Runde 2 (ui/documentation/pickers) |
| 6 | `run_all_tests.sh`: `$NVIM` streichen, `-n` | **erledigt** | `env -u NVIM -u NVIM_LISTEN_ADDRESS`, `nvim -n --clean …` |

## Rollout-Protokoll

**Runde 1 (2026-09-21).** 39 Repos (das Dokument nannte 38; `gitsuite.nvim`
kam danach dazu) in sechs Batches: erst ein Kanarienvogel aus drei
verschiedenen Repos (`cmdlog`, `sandbox`, `lib`), CI auf drei Plattformen
abgewartet, dann 8 + 8 + 8 + 8 + 3, `ui.nvim` einzeln über ein Worktree.
Vor dem ersten Schreiben wurde jeder Workflow im Speicher transformiert und
mit PyYAML geladen (gültiges YAML, `timeout-minutes` an jedem Job,
Idempotenz) — ein kaputtes YAML wäre in allen Repos gleichzeitig rot
geworden.

**Runde 2 (2026-09-21).** `publish-ci-verified`-Job in `ui.nvim`,
`documentation.nvim` und `pickers.nvim` (`needs:` = alle Gate-Jobs), CI
grün abgewartet, `git ls-remote` bestätigte die drei Branches, dann
`ref: ci-verified` in 18 Checkouts über 15 Repos. Ein weiterer Checkout
(`diff.nvim` in `gitsuite`, siehe unten) bleibt ungepinnt. filetree.nvims
Kommentar zum fehlenden `ui.nvim`-Pin ist entfernt.

Endstand: `scripts/ci_status.sh` — 35 von 39 Repos vollständig grün, die
vier übrigen waren vorher schon rot (siehe nächster Abschnitt). Ein
erneuter Dry-Run des Transformers ändert nichts mehr (idempotent).

## Was dabei zutage kam

- **`pickers.nvim` war unter macOS rot, und dahinter steckte ein echter
  Fehler:** `browse.rename` verglich Buffernamen nur mit dem übergebenen
  Pfad. macOS benennt einen über `/var/folders/…` geöffneten Buffer
  `/private/var/folders/…`, der Buffer folgte der Umbenennung also nie.
  `browse.rename` löst den Realpath jetzt vor dem Verschieben auf; zusätzlich
  vergleichen zwei Test-Checks über `realpath`. Ohne diese Korrektur hätte
  `pickers.nvim` nie `ci-verified` veröffentlicht (`needs:` blockiert bei
  rotem Gate-Job).
- **Vier Repos waren schon vor dem Rollout rot** — identische Jobs und
  Steps vor und nach der Änderung, also nicht durch den Rollout verursacht:

  | Repo | Rot in | Ursache |
  |---|---|---|
  | `diff.nvim` | macOS, „Run spec suite" | Spec-Fehler, nicht untersucht |
  | `emojis.nvim` | ubuntu, „Run TESTS suite" | 1 Spec schlägt fehl (885 Checks liefen) |
  | `fileops.nvim` | `lint`, `stylua --check` | Formatabweichung in `TESTS/cycle_edge_spec.lua:280` |
  | `filetree.nvim` | ubuntu + macOS, „Run test suites" | nicht untersucht |

## Nachprüfung der Rollout-Commits

Review aller 60 Commits des Rollouts am selben Tag (Diff-Anomalien,
Modusänderungen, Endstand aller 42 Workflows per PyYAML, echte CI-Läufe).
Keine Sicherheitslücke gefunden: kein Secret in den gewrappten Steps, der
Publish-Job läuft nur auf `push` nach `main` mit Schreibrecht nur auf Job-
Ebene, und außer `checkout`, einem Compare-Aufruf der GitHub-API und
`git push` führt er nichts aus. Behoben:

| Fund | Wirkung | Fix |
|---|---|---|
| `actions/upload-artifact@v4` läuft auf Node 20 (nur per Zwangsumstellung des Runners) | bei roten Läufen Warnung; fällt der Notbehelf weg, ginge das Failure-Log genau dann verloren, wenn man es braucht | `@v7` (Node 24) in allen 51 Log-Steps, Inputs unverändert |
| `buffer-ctx.nvim`: Matrix hat neben `os` die Achse `nvim` (ubuntu stable + nightly) | Artefaktname `test-output-test-ubuntu-latest` doppelt; `upload-artifact` ab v4 lehnt Duplikate ab, ein Log ginge verloren | Name trägt jetzt `matrix.nvim` |
| `publish-ci-verified` (ui/documentation/pickers) schrieb bedingungslos, was zuletzt fertig wurde | zwei Pushes, die außer der Reihe fertig werden, setzen `ci-verified` auf den älteren Commit zurück; alle gepinnten Konsumenten testen dann gegen veralteten Code | Compare-API vorab: bei `behind`/`identical` bleibt der Branch unberührt, bei fehlendem Branch oder `diverged` (Force-Push auf `main`) wird publiziert |
| `documentation.nvim/scripts/publish_map.sh` und `replacer.nvim/Makefile` starteten `nvim` ohne `-n -i NONE` | Maßnahme 2 war nur für Workflows, `test.sh` und `ci.sh` umgesetzt | Flags ergänzt |
| Log-Artefakte ohne Ablaufdatum | 90 Tage Standard-Aufbewahrung für Logs, die nur kurz nützen | `retention-days: 14` |

Im Ernstfall bestätigt: der rote `emojis`-Lauf lud sein Artefakt mit `v7` hoch
(Ablauf 2026-10-05) und meldet keine Node-20-Warnung mehr; `pickers.nvim`
zog `ci-verified` mit dem neuen Guard auf den neuen Commit.

## Bewusst offen geblieben

- **Publish-Guard für die älteren `publish-ci-verified`-Jobs** in
  `lib.nvim`, `hover.nvim` und `runtime-analysis.nvim` (nicht aus diesem
  Rollout, aber dieselbe Reihenfolge-Schwäche; Vorlage: der Job in
  `pickers.nvim`). `runtime-analysis.nvim` wartet außerdem nicht auf den
  `map`-Job.
- **13 Kind-Prozess-Spawns in Specs** (`"--headless"` in `casedesk`, `cmdlog`,
  `insights`, `language`, `media`, `pdfport` u. a.) starten `nvim` ohne
  `-n`/`--clean`. Nur plenarys Kinder sind über `minimal_init.lua` abgedeckt.
  Nicht angefasst: Testcode in vielen Repos ohne belegten Nutzen; erst
  prüfen, ob eines davon Dateien öffnet (E326-Risiko).
- **Weitere Aktionen mit Node-20-Verdacht (nicht geprüft), die nicht aus
  diesem Rollout stammen:** die Build-Artefakte in `mdview.nvim` (WASM) und
  `documentation.nvim/release-engine.yml` (`engine-linux`, `engine-windows`)
  liegen noch auf `upload-artifact@v4` und müssen mit ihrem
  `download-artifact@v4` als Paar angehoben werden; außerdem `setup-node@v4`,
  `setup-go@v5`, `cache@v4`, `upload-pages-artifact@v3`, `deploy-pages@v4`,
  `configure-pages@v5` und zweimal `checkout@v4`. Wie bei lib.nvim vorher:
  erst die Annotation eines echten Laufs lesen, dann gezielt anheben.

- **`diff.nvim` hat keinen `ci-verified`-Branch** (Konsument: `gitsuite`).
  Er lässt sich erst veröffentlichen, wenn seine macOS-Suite grün ist; dann
  `publish-ci-verified`-Job ergänzen (Vorlage: lib.nvims `ci.yml`) und den
  Checkout in `gitsuite` von Hand auf `ref: ci-verified` setzen.
- **Timeout-Werte** (15/30) sind Heuristik; ein Repo mit langsamem
  macOS-Runner kann knapp werden — dann gezielt hochsetzen, nicht global.
- **`TESTS/run.lua`-Kopfkommentare** nennen weiterhin die alten Aufrufe ohne
  `-n` — Dokumentationsdrift, kein Funktionsproblem.
- **Third-Party-Pins veralten bewusst** (Stand 2026-09-20-HEAD; „bump
  deliberately, not by drifting"): ein späteres Anheben ist ein eigener,
  sichtbarer Commit.

## Lehren für den nächsten Flotten-Rollout

- Kanarienvogel aus **unterschiedlich geformten** Repos vor dem Rest; die
  echte CI, nicht nur Dry-Run, ist der Test.
- Bei roten Repos nie „rot nach dem Rollout" mit „rot wegen des Rollouts"
  verwechseln: Jobs und Steps von `HEAD~1` und `HEAD` gegenüberstellen.
- `NOTE`-Zeilen des Transformers erscheinen **vor** der `==`-Zeile ihres
  Repos, nicht danach.
- Nach jedem Flotten-Push den **Diff gegen die Commit-Message** halten: ein
  Fix-Skript, das den Repo-Namen aus dem Ordnernamen ableitet, tat im
  Worktree (`ci-review-fix`) für `ui.nvim` stillschweigend nichts, während die
  Message den Fix ankündigte. Aufgefallen ist es erst beim Gegenzählen des
  Endstands auf `origin/main`.
- Ein `publish-ci-verified` mit `needs:` auf alle Gate-Jobs veröffentlicht
  nur bei grünen Gates: erst den CI-Status des Publishers prüfen, dann den
  Job ergänzen, Branch per `git ls-remote` bestätigen und erst danach
  Konsumenten pinnen.
