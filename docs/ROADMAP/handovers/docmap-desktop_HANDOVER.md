# Handover — docmap-desktop und das Ökosystem: nur offene Aufgaben

**Stand: 2026-10-02.** Hier steht ausschließlich, was noch zu tun oder zu
entscheiden ist, und welche Commits noch auf ein Review warten. Was gebaut
wurde und warum, steht nicht mehr hier:

| Wo | Was |
|---|---|
| [`PLAN.md`]($REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/docmap-desktop/ROADMAP/PLAN.md) | Die Queue (alle drei Repos, nach Aufwand). Hier nur das, was daraus als Nächstes ansteht |
| [`PLAN-DONE.md`]($REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/docmap-desktop/Backlog/FEATURES/PLAN-DONE.md) | Gebaut und begründet — zuletzt L11, L10 P0 und L10 P1 (2026-10-02) |
| [`HANDOVER-HISTORY.md`]($REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/docmap-desktop/Backlog/FEATURES/HANDOVER-HISTORY.md) | Der frühere Inhalt dieses Handovers, unverändert: Releases v0.1 bis v0.5, L10-Entwurf, L11-Stand |
| [`OPERATING_NOTES.md`]($REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/docmap-desktop/ROADMAP/OPERATING_NOTES.md) | Betriebswissen: installierte Tools, Engine neu bauen, Gates, Arbeitsmethode, Stolperfallen |
| [`RULES_AGENT_CONCEPT.md`]($REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/docmap-desktop/ROADMAP/IDEAS/RULES_AGENT_CONCEPT.md) | Konzept L10, mit *As built* zu D4 und D5 |

## Repos auf dem Stand dieser Übergabe

Alle `main`, alle mit `origin` synchron.

| Repo | HEAD | Anmerkung |
|---|---|---|
| `E:\repos\docmap-desktop` | `4774f11` | 15 Commits nach `v0.5.0`; **der Download ist noch `v0.5.0`** |
| `E:\repos\documentation.nvim` | `4bd684e` | CI auf Linux, macOS und Windows grün; `standalone-latest` am 2026-10-02T18:06:23Z neu gebaut |
| `E:\repos\rules.nvim` | `02c5952` | CI grün |
| `E:\repos\github_stats.nvim` | `13fb0a2` | keine CI |
| `E:\repos\runtime-analysis.nvim` | `a450b36` | unverändert |

---

## Offene Aufgaben

### Entscheidungen und Handgriffe für dich

1. **Release schneiden, ja oder nein: `v0.6.0` oder `v0.5.1`.** `main` enthält
   seit `v0.5.0` die Traffic-Features (L11) und sonst nur Doku. Die gebündelte
   Engine ist aktuell (`standalone-latest`, 2026-10-02T18:06:23Z), und
   `RELEASING.md` gilt wie bisher: CI auf dem Bump-Commit grün, Engine-Stand
   prüfen, dann taggen. Ein Release ist öffentlich, deshalb deine Entscheidung.
   Vorher noch nicht gelaufen: `cargo test` im Desktop-Repo (braucht den
   Platzhalter-Sidecar, siehe `OPERATING_NOTES.md`) — der Merge vom 2026-10-02
   wurde nur mit den Frontend-Tests (157 grün) geprüft.
2. **A1 — `v0.5.0` durchklicken.** Es ist öffentlich, ohne dass jemand die App
   geöffnet hat. Die vier Standardpunkte aus `RELEASING.md`, dazu **Add from a
   parent folder** und **View as matrix…**. Findet es etwas, ist `v0.5.1` die
   billige Antwort.
3. **A3 — L11 gegen echte Daten.** Mit deinem Token `:GithubStats fetch`, dann
   die sieben Punkte in `docs/ROADMAP/handovers/github_stats_traffic_integration.md`
   (zwei Maschinen, Plugin fehlt, lazy-loaded, überschriebenes `digest_dir`,
   feindlicher Digest, privates Repo mit Opt-out). Alles ist gebaut und mit
   Fixtures getestet, aber nichts lief gegen einen echten Fetch.
4. **A2 — Discussions einschalten**, sobald *jemand anderes* eine echte Frage
   stellt. Ein Ereignis, keine Aufgabe.
5. **Aufräumen, du entscheidest:** lokale Branches in `docmap-desktop`, die schon
   in `main` stecken (`claude/agent-checklist-runner-23f139`,
   `claude/docmap-agent-checklist-architecture-d208fd`,
   `claude/docmap-multi-repo-import-8ec2f5`, `claude/github-stats-traffic-integration-46c7c0`
   lokal **und** auf `origin`), dazu die Worktrees unter
   `.claude/worktrees/` (u. a. `vigorous-swanson-d5cf1d`, `agent-checklist-runner-23f139`,
   `docmap-multi-repo-import-8ec2f5`). Das Löschen auf `origin` ist öffentlich.

### Nächster Bauschritt

6. **L10 P2 — `--api=rules` in `documentation.nvim`** (~1 Session). `catalog` und
   `run` (mechanisch) zuerst, dann `plan` (mit Batching) und `validate`; in
   `--capabilities` auflisten; die Vertrauensentscheidung für Prädikate pro Regel
   durchreichen (`lua_predicates` als Funktion, D5). **Und das Bundle bekommt
   `rules.nvim`:** `bundle_manifest.lua` wird aus einem Lauf von
   `standalone/docmap.lua` gemessen, dieser Lauf berührt die Rules-Engine erst mit
   `--api=rules`; `scripts/package.lua` und `release-engine.yml` brauchen den
   Checkout von `rules.nvim` (wie für `lib.nvim`), und das ist der Teil von
   Entscheidung 4 im Konzept (*eine* Sidecar), der noch nicht gemessen ist.
   Anfang: `standalone/docmap.lua` (`api_route`-Zweig ab Zeile ~340),
   `lua/documentation/core/api.lua`, und `standalone/rules_results.lua` als
   Vorlage für den Aufruf der Engine.

### Danach (Reihenfolge laut Konzept, Größen in Sessions)

7. **L10 P3** (~2) Rules-Tab in dieser App, Datei/Section/Familie, Mehrfachauswahl,
   `.rules.json`, **Trust-Store für Prädikate (Pfad + Hash)**.
   **P4** (~2) `rules.nvim`: `agent/plan`, `agent/validate`, Verdict-Store, `:Rules agent`.
   **P5a** (~2,5) der Lauf: Dialog, Rust-Job-Runner, loomAI-Client, Run-Fenster.
   **P5b** (~1,5) der Chat. **P6** (~1) loomAI: `temperature`, `GET /models`,
   `usage` im Stream (optional). **P7** (~0,5) Checklist-Items als zweiter Input.
8. Der Rest der Queue steht in `PLAN.md`: **M11** (Endpoint-Inventar × Request-Historie)
   und die L-Punkte **L1** bis **L9**; **L1** und **L2** sind laut Plan "nicht als
   Nächstes", weil beides Scope-Entscheidungen sind.

### Kleinere Schulden aus dieser Sitzung

9. **`rules.nvim` braucht einen `ci-verified`-Branch** (das `publish-ci-verified`-Job-Muster
   aus `documentation.nvim`s `ci.yml`). Bis dahin zieht deren CI `rules.nvim`
   von `main`, und ein kaputter Push dort färbt `documentation.nvim` rot.
10. **`popen_git` in `standalone/docmap.lua`** wertet Git-Fehler am Ausgabetext aus
    (`fatal:`/`error:`/`usage:`). Unter PUC 5.4 wäre der echte Exit-Status
    verfügbar (gemessen: 128). Umstellen ändert, was die `--api=`-Routen als
    Fehler behandeln — eigene Entscheidung, nicht nebenbei.
11. **Die On-Demand-Live-Fetch-Idee für L11** ist weder entschieden noch
    bemessen (siehe `GITHUB_STATS_CONCEPT.md`, Abschnitt dazu und Entscheidung 5).
12. **Ein Neovim-Konfig-Repo mit fremden, nicht committeten Änderungen:**
    `docs/ROADMAP/00_ROADMAP.md`, `TASKS.md`, `TSKS_Workstation.md` und die
    `github-stats`-Datendateien sind nicht aus dieser Arbeit. Im WKDBooks
    ebenso `Spickzettel/spickzettel.md` und `TOOLS/scripts/tui-spike/*`.
    Nicht anfassen, bevor klar ist, wem sie gehören.

### Blockiert / nicht vergessen

13. **Phase 4 (UI-Politur) in `documentation.nvim`** — die Typografie-Skala (16
    verschiedene `font-size`-Werte gemessen) und Zebra-Streifen brauchen eine
    visuelle Prüfung. Aus demselben Grund sind zwei fertige Dinge **nicht
    visuell geprüft**: das eingeklappte Engine-Panel und das Kanten-Popup im
    Aufrufgraphen. Beides ist syntaktisch und strukturell geprüft; jemand sollte
    es in einem echten Fenster ansehen. `docmap-desktop/tools/preview/` löst das
    nur für die Oberfläche der App (Layout wird dort gemessen), nicht für die von
    `documentation.nvim` generierte Seite, und ein Browser ist nicht WebView2.
14. **Phase 6 (gehostetes Web, richtig)** braucht ein Multi-Tenant-Vertrauensmodell,
    das es nirgends gibt. Die statische Hälfte ist fertig.

---

## Commits, die noch ein Review brauchen

Reine Doku-Commits sind ausgenommen (kein Review nötig). Ein Review ist ein
`ultracode`-Agent oder ein von dir gestellter Review-Lauf; Haken erst danach.

| Review | Repo | Commit | Was | Worauf es sich zu schauen lohnt |
|---|---|---|---|---|
| ☐ | `rules.nvim` | [`02c5952`](https://github.com/StefanBartl/rules.nvim/commit/02c5952) | L10 P0: Parser (`text`/`title`/`section`/`agent`), Sandbox, `lua_predicates` | `util/sandbox.lua`: `jit.off()`/`jit.on()` und `debug.sethook` während des Parsens, Wiederherstellung von Hook und JIT bei Fehler, `rebind` über `setfenv` und über den `_ENV`-Upvalue (nur PUC getestet, per Probe), Weak-Table `created_here`. `engine/parser.lua`: Fence-Tracking mit Backtick-Länge und `outer_fence`, `place()` (Titel vs. Section), `validate_agent` (`vim.islist` bei leerem Table). Die Grenze "Fähigkeiten, nicht Ressourcen" ist dokumentiert — prüfen, ob sie reicht |
| ☐ | `documentation.nvim` | [`b90ad9d`](https://github.com/StefanBartl/documentation.nvim/commit/b90ad9d) | L10 P1: Shim für die Engine, `vim.log`-Fix, Paritäts-Gate, Fixtures, CI-Checkout | `standalone/vim_shim.lua`: `readfile` (CR/BOM/`max`), `glob` (Algorithmus, Dotfiles, `**`, Sortierung), der `normalize`-Port gegen Neovims Quelle, `fnamemodify(":p")` (gemessene Eigenheiten), `fn.system` (Windows-Quoting mit zusätzlichem Anführungszeichen-Paar, Exit-Status, Verweigerung unter LuaJIT), `fs_scandir`/`entries()`-Prüfung per `attributes`. `scripts/ci.lua`: der neue Gate-Schritt und sein Skip/Fail-Verhalten in CI. `.github/workflows/ci.yml`: Checkout von `rules.nvim` auf `main`. `.gitattributes`: `-text` für die Fixtures. Dass ein Commit zwei Anliegen trägt (CI-Fix und P1), war dem Verwoben-Sein in `vim_shim.lua` geschuldet |
| ☐ | `documentation.nvim` | [`4bd684e`](https://github.com/StefanBartl/documentation.nvim/commit/4bd684e) | `glob` ignoriert Groß-/Kleinschreibung auch auf macOS | `folds_case()`: Erkennung über `io.popen("uname -s")`, Zwischenspeicher, Verhalten wenn `popen` fehlschlägt (dann nicht-faltend) |
| ☐ | `docmap-desktop` | `faf4f91`, `409af1f`, `4774f11` | Traffic: Opt-out-Fix, `cargo fmt`, Detail-Dialog (P2) — in einer früheren Sitzung entstanden, in dieser auf `main` gebracht | Reviewstatus ist in dieser Sitzung nicht bekannt. Zusammen 832 Zeilen in 15 Dateien; `4774f11` ist der Kern: `src/main.js`, die `src-tauri`-Befehle `traffic_detail`/`open_in_editor`, die Sparkline, und dass Referrer und Seitentitel nur über `textContent` ins DOM kommen |

Ebenfalls auf `main` und aus der früheren Sitzung, Reviewstatus unbekannt:
`02b84fc` und `2a8d561` (Traffic P1).

**Die Doku-Commits dieser Sitzung** (kein Review nötig): WKDBooks `11e11cb`,
`8444e8a`, `8d041c9` und der Commit mit diesem Umzug; nvim-Konfig `301e213d`,
`cf0c8e9f`, `7d1c76c5`, `d580b57a`, `44af8458` und der Commit mit diesem Handover.
