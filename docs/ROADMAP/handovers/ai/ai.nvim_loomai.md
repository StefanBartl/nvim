# ai.nvim — Handover (nur offene Punkte)

> Ausnahme-Standort: normalerweise leben Plugin-Roadmaps im Wkdbook
> (`wkdbook-myplugins/<plugin>/ROADMAP/ROADMAP.md`, siehe `NEW-14`). Diese
> Datei hier ist explizit angefordert als laufende Handover-Akte für
> `ai.nvim` (+ `loomAI`-Anbindung) und bleibt an diesem Ort
> (`nvim/docs/ROADMAP/handovers/ai/`), nicht im Wkdbook.
>
> **Hier stehen nur offene Tasks.** Alles Erledigte (inkl. Session-Logs,
> Commit-Tabellen, Review-Ergebnisse) liegt im Wkdbook-Backlog:
> `wkdbook-myplugins/ai.nvim/Backlog/FEATURES/FINISHED_ai_loomai.md`
> (zuletzt ergänzt 2026-10-02, Abschnitt „Session 2026-10-01/02“).

## Table of content

  - [Regeln für diese Session](#regeln-für-diese-session)
  - [Orte](#orte)
  - [Report: offene Tasks und Fixes](#report-offene-tasks-und-fixes)
  - [A. Braucht den Nutzer / andere Hardware](#a-braucht-den-nutzer--andere-hardware)
  - [B. Entscheidung nötig](#b-entscheidung-nötig)
  - [C. Autonom machbar (Folgesession)](#c-autonom-machbar-folgesession)
  - [D. Release](#d-release)

---

## Regeln für diese Session

- Nie mehr als 1 Agent gleichzeitig; bei Bedarf mehrere Runden á 1 Agent, repo-für-repo.
- Antworten Deutsch, Quellcode (inkl. Kommentare) Englisch.
- **Keine Co-Autorenschaft von Claude in Commits** (auch nicht den
  `Co-Authored-By`-Trailer, den die Harness-Vorgabe vorschlägt — die
  Nutzerregel hat Vorrang).
- Nach jedem fertigen Schritt: committen/pushen/pullen, main bleibt aktuell.
  Keine Pull Requests.
- Erledigte Tasks wandern aus dieser Datei ins Wkdbook-Backlog (s. o.), hier
  bleiben nur offene.
- `TOOL-PLACEMENT.md` / `HEREDOC.md` beachten, falls Nebenbei-Tooling entsteht.
- Code muss luacheck/stylua-grün sein (stylua v2.5.2, luacheck 1.2.0, siehe `ci-fleet-conventions`).
- Plugin-Installations-Specs: `vim.fn.stdpath('config')/lua/plugins/personal/init.lua`
  (+ Policy in `plugins/personal/core/source.lua`).

---

## Orte

| Was | Wo |
|---|---|
| Konzept | `nvim/docs/ROADMAP/IDEAS/ai.nvim.md` |
| Öffentliches Repo | `github.com/StefanBartl/ai.nvim` → `$REPOS_DIR/ai.nvim` |
| Privat (Roadmap/Notes/Backlog, nicht fürs öffentliche Repo) | `$REPOS_DIR/WKDBooks\Development\wkdbook-myplugins\ai.nvim\{ROADMAP,NOTES,Backlog}` |
| Erledigt-Archiv | `...\ai.nvim\Backlog\FEATURES\FINISHED_ai_loomai.md` |
| Diese Handover-Datei | `nvim/docs/ROADMAP/handovers/ai/ai.nvim_loomai.md` |
| Transport-Erweiterung | `$REPOS_DIR/lib.nvim\lua\lib\nvim\net\curl` |
| loomAI (Server, Router, Dashboard) | `$REPOS_DIR/loomAI` |
| Regelwerk für neue Projekte | `$REPOS_DIR/WKDBooks\Development\wkdbook-Lua\Checklists\gates\NEW_PROJECT.md` (+ `PRINCIPLES.md`, `LUA_NVIM.md`) |
| Release-Gate | `$REPOS_DIR/WKDBooks\Development\wkdbook-Lua\Checklists\gates\RELEASE.md` |
| Live-Testing-Plan | `docs/ROADMAP/personal/All/FINISH/Final_Checks/ai/live-testing-plan.md` |

---

## Report: offene Tasks und Fixes

Stand 2026-10-02. `ai.nvim`: 319 Tests grün (`scripts/test.sh`),
luacheck/stylua grün, CI auf ubuntu/windows/macos grün (letzter Lauf
`1815932`). Alles, was ohne den Nutzer machbar war, ist erledigt; die Liste
unten ist vollständig (nichts steht woanders offen).

| # | Task | Art | Blocker / Aufwand |
|---|---|---|---|
| A1 | Alltagsdurchlauf (Env-Vars, Live-Testing-Plan abhaken) | Validierung | Nutzer |
| A2 | `gemini.lua` live gegen echte Gemini-API | Validierung | Nutzer: `GEMINI_API_KEY` |
| A3 | REL-19: manuelles POSIX-Durchklicken | Release-Gate | Linux/macOS-Rechner oder WSL-Distro (keine installiert) |
| A4 | REL-09/33: Demo-GIF, Logo, Social-Preview | Release (nice-to-have) | Nutzer (Aufnahme; Social-Preview manuell in GitHub-Settings) |
| B1 | REL-32: Abschnitt „Literatur und Referenzen“ im öffentlichen README? | Release (nice-to-have) | Entscheidung |
| C1 | Frische „trockene“ Abschlussrunde für den Docs-Spec | Review | klein, 1 Agent |
| C2 | Docs-Spec vereinfachen statt weiter härten | Refactor | mittel |
| C3 | `doc/ai.txt` automatisch gegen `docs/*.md` prüfen | Test | klein–mittel |
| C4 | CI nach Ubuntu-26-Migration prüfen | CI | ab 2026-10-19 |
| D1 | Tag/Release | Release | erst nach A1–A3 |

---

## A. Braucht den Nutzer / andere Hardware

### A1. ai.nvim im Alltag validieren

- `ai.nvim` im Alltag benutzen (`<leader>a{a,s,r,o,O,e}`, dazu `loomai`/`gemini`),
  um v1 vor einem Tag zu validieren.
- [Live-Testing-Plan](../../Final_Checks/ai/live-testing-plan.md) ist seit
  2026-09-23 auf OpenAI/Anthropic/Gemini im ModelRouter und
  `providers/gemini.lua` aktualisiert. Der eigentliche Durchlauf (Env-Vars
  setzen, Schritte abhaken) steht aus.

### A2. `gemini.lua` live testen

`gemini.lua` wurde nie gegen die echte Gemini-API getestet (kein
`GEMINI_API_KEY`, am 2026-10-02 weiterhin nicht gesetzt). Nur die loomAI-Seite
(`gemini_client.cpp`) wurde mit einem bewusst ungültigen Key auf dem Fehlerpfad
verifiziert. Nachholen: Happy-Path, Streaming, Safety-Block.

### A3. REL-19 — manuelles POSIX-Durchklicken

Die CI-Matrix (ubuntu/windows/macos) ist grün — REL-19 hat aber bewusst kein
`check`-Feld, ein grüner CI-Lauf ist ein Indiz, kein Beweis. Offen: reale
Workflows (`:Ai ask/stream/rewrite`, Panel, Completion, `:checkhealth ai`) auf
einem POSIX-System einmal von Hand durchgehen. Auf dieser Maschine ist keine
WSL-Distro installiert (`wsl -l` zeigt nur die Installations-Liste).

### A4. REL-09 / REL-33 — Demo-GIF und Logo

`nice-to-have`. Im README gibt es bisher nur das ASCII-Logo. GIF unter
`/assets/` (oder MP4 per Dummy-Issue, siehe `RELEASE.md`); Social-Preview-Card
manuell in den GitHub-Settings plus Bilddatei im Repo, per Markdown-Bild im
README eingebunden.

---

## B. Entscheidung nötig

### B1. REL-32 — Literatur und Referenzen

`nice-to-have`, „wo angebracht“. Entweder Abschnitt `## Literatur und
Referenzen` im öffentlichen README anlegen (Vorschlag: `gp.nvim`,
`minuet-ai.nvim`, Provider-Doku) oder als „nicht angebracht“ abhaken. Der
Vergleich mit Completion-Plugins liegt privat in
`NOTES/completion-plugin-comparison.md` (nicht fürs öffentliche Repo).

---

## C. Autonom machbar (Folgesession)

Alle Punkte betreffen `TESTS/ai/docs_examples_spec.lua` (REL-08-Spec,
~690 Zeilen) bzw. `doc/ai.txt` in `$REPOS_DIR/ai.nvim`.

### C1. Frische Abschlussrunde (loop-until-dry)

Der ultracode-Review des Spec endete in der 2. Workflow-Runde am Rundenlimit
(3), nicht „trocken“. Die Funde der letzten Runde (alle `low`/Qualität der
Fehlermeldungen) wurden behoben (`ai.nvim@1815932`, lokal + CI-Matrix grün),
aber von keinem frischen Reviewer mehr gesehen. Eine weitere sequentielle
Runde (1 Agent: Review -> Skeptiker -> ggf. Fix) bis kein neuer Fund kommt.

### C2. Spec vereinfachen

Durch die Härtung wuchs der Spec von ~380 auf ~690 Zeilen (u. a. ein
registry-unabhängiger `nvim_get_keymap`-Scan über alle Modi mit Selbsttest).
Bei weiterem Bedarf lieber vereinfachen (Helfer bündeln, Scan kürzen) als noch
einen Scan ergänzen. Bewusst akzeptiert, nicht zu fixen: `register()`-Beispiel
wird per exaktem Text gepatcht (`...`-Stub), Blocksuche per Substring, Soft-Deps
(`pcall(require, ...)`) fallen aus der `require`-Suche der Dependency-Prüfung.

### C3. Vom Spec nicht abgedeckt (bewusst, in `TESTS/README.md` benannt)

Prosa, die Spalten Action-id/Beschreibung und die Autocmds-Tabelle in
`BINDINGS.md`, die übrigen Tabellen der Docs, das Root-`README.md` und
`doc/ai.txt` (der `:help ai`-Text, von Hand gepflegt). Besonders `doc/ai.txt`
war nachweislich driftanfällig (am 2026-10-01 deutlich hinter `docs/*.md`,
nachgezogen in `ai.nvim@6bc2b0d`) — ein kleiner Test, der Konfig-Block,
Subcommands und Keymap-Tabelle der Vimdoc gegen `docs/*.md`/`DEFAULTS`
abgleicht, würde den nächsten Drift fangen. Zusätzlich nicht sichtbar:
buffer-lokale Keymaps.

### C4. CI nach Ubuntu-26-Migration

Die CI-Annotation meldet: das Label `ubuntu-latest` wechselt ab 2026-10-19
auf Ubuntu 26. Danach einen CI-Lauf von `ai.nvim` prüfen (luacheck-Lua-5.1-
Setup, stylua-Action, plenary-Job) und ggf. nachziehen.

---

## D. Release

Phase 10 (`gates/RELEASE.md`) bewusst noch nicht abgeschlossen: der Plan
verlangt echten Alltagsgebrauch vor dem Tag. Automatisch prüfbare
`REL-*`-Punkte sind grün (REL-08 erledigt, s. Backlog). Offen: A1–A3 (und
optional A4/B1), danach Tag/Release selbst.
