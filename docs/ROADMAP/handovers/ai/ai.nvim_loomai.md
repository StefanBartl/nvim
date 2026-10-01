# ai.nvim — Handover (nur offene Punkte)

> Ausnahme-Standort: normalerweise leben Plugin-Roadmaps im Wkdbook
> (`wkdbook-myplugins/<plugin>/ROADMAP/ROADMAP.md`, siehe `NEW-14`). Diese
> Datei hier ist explizit angefordert als laufende Handover-Akte für
> `ai.nvim` (+ `loomAI`-Anbindung) und bleibt an diesem Ort
> (`nvim/docs/ROADMAP/handovers/ai/`), nicht im Wkdbook.
>
> **Erledigtes steht nicht hier**, sondern im Backlog:
> `wkdbook-myplugins/ai.nvim/Backlog/FEATURES/FINISHED_ai_loomai.md`
> (zuletzt ergänzt am 2026-10-01 um den Abschnitt "Erledigt seit 2026-09-21").

## Table of content

  - [Feedback](#feedback)
  - [Regeln für diese Session](#regeln-für-diese-session)
  - [Orte](#orte)
  - [Stand 2026-10-01](#stand-2026-10-01)
  - [Offene Punkte](#offene-punkte)
    - [1. ai.nvim im Alltag validieren + Live-Testing](#1-ainvim-im-alltag-validieren--live-testing)
    - [2. Phase 10 — `gates/RELEASE.md` vor dem ersten Tag/Release](#2-phase-10--gatesreleasemd-vor-dem-ersten-tagrelease)
  - [Letzte Session (2026-10-01)](#letzte-session-2026-10-01)

---

## Feedback

## Regeln für diese Session

- Nie mehr als 1 Agent gleichzeitig; bei Bedarf mehrere Runden á 1 Agent, repo-für-repo.
- Antworten Deutsch, Quellcode (inkl. Kommentare) Englisch.
- **Keine Co-Autorenschaft von Claude in Commits** (auch nicht den
  `Co-Authored-By`-Trailer, den die Harness-Vorgabe vorschlägt — die
  Nutzerregel hat Vorrang).
- Nach jedem fertigen Schritt: committen/pushen/pullen, main bleibt aktuell.
  Keine Pull Requests.
- `TOOL-PLACEMENT.md` / `HEREDOC.md` beachten, falls Nebenbei-Tooling entsteht.
- Code muss luacheck/stylua-grün sein (stylua v2.5.2, luacheck 1.2.0, siehe `ci-fleet-conventions`).
- Plugin-Installations-Specs: `vim.fn.stdpath('config')/lua/plugins/personal/init.lua`
  (+ Policy in `plugins/personal/core/source.lua`).
- Erledigte Tasks wandern aus dieser Datei ins Wkdbook-Backlog (s. o.).

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

## Stand 2026-10-01

Alles, was ohne den Nutzer machbar ist, ist erledigt. Was bleibt, braucht
**Nutzer-Input oder eine Umgebung, die diese Maschine nicht hat** (siehe die
Blocker unter den offenen Punkten). `ai.nvim`: 318 Tests grün
(`scripts/test.sh`), luacheck/stylua grün, CI auf ubuntu/windows/macos grün
(letzter Lauf auf `e7509af`, 2026-09-28).

---

## Offene Punkte

### 1. ai.nvim im Alltag validieren + Live-Testing

**Blocker: Nutzer.**

- `ai.nvim` im Alltag benutzen (`<leader>ai{a,s,e}`, dazu `loomai`/`gemini`),
  um v1 vor einem Tag zu validieren.
- [Live-Testing-Plan](../../Final_Checks/ai/live-testing-plan.md) ist seit
  2026-09-23 auf OpenAI/Anthropic/Gemini im ModelRouter und `providers/gemini.lua`
  aktualisiert. Der eigentliche Alltagsdurchlauf (Env-Vars setzen, Schritte
  abhaken) steht aus.
- **`gemini.lua` wurde nie live gegen die echte Gemini-API getestet** (kein
  `GEMINI_API_KEY`, am 2026-10-01 weiterhin nicht gesetzt). Nur die
  loomAI-Seite (`gemini_client.cpp`) wurde mit einem bewusst ungültigen Key auf
  dem Fehlerpfad verifiziert. Happy-Path + Streaming + Safety-Block gegen die
  echte API nachholen.

---

### 2. Phase 10 — `gates/RELEASE.md` vor dem ersten Tag/Release

Bewusst noch nicht abgeschlossen: der Plan verlangt echten Alltagsgebrauch vor
dem Tag (Punkt 1). Automatisch prüfbare `REL-*`-Punkte sind grün.

- **REL-08 (README-Beispiele laufen tatsächlich): erledigt 2026-10-01.**
  `TESTS/ai/docs_examples_spec.lua` (`ai.nvim@2813081`, 12 Tests) zieht die
  Codeblöcke/Tabellen zur Laufzeit aus `docs/*.md` und führt sie aus bzw.
  gleicht sie gegen den Code ab (vollständiger `setup()`-Block == `DEFAULTS`,
  `register()`-/`from_file()`-/`host`-Beispiel, `:Ai`-Subcommands in beide
  Richtungen, `BINDINGS.md`-Keymaps real gemappt, lazy.nvim-Spec,
  `Ai.Attachment`-Felder, `net.curl`-Erweiterung). Per Mutation geprüft
  (4 absichtlich kaputte Docs → jeweils rot). Einziger bewusst nicht
  ausgeführter Rest: das ASCII-Logo im README und die reinen
  Nicht-Lua-Schnipsel in `commands.md` (werden nur auf Subcommand-Namen
  geprüft, nicht „ausgeführt“, da Ex-Befehle ohne Provider nichts bewirken).
- **REL-19 (Windows UND POSIX getestet): teilweise.** Korrektur zum alten
  Stand: die CI läuft **nicht** nur auf `ubuntu-latest`, sondern als Matrix auf
  ubuntu/windows/macos (alle drei grün). Offen bleibt nur das *manuelle*
  Durchklicken unter POSIX — **Blocker:** auf dieser Maschine ist keine
  WSL-Distro installiert (`wsl -l` zeigt nur die Installations-Liste), ein
  Linux-/macOS-Rechner oder eine WSL-Distro wäre nötig. REL-19 hat bewusst kein
  `check`-Feld; ein grüner CI-Lauf auf allen drei OS ist ein Indiz, kein
  Beweis.
- **REL-09/33 (Demo-GIF, Logo/Social-Preview)** — `nice-to-have`, nicht
  begonnen. **Blocker: Nutzer** (GIF-Aufnahme; Social-Preview ist manuell in
  den GitHub-Settings). Im README gibt es bisher nur das ASCII-Logo.
- **REL-32 (Literatur und Referenzen)** — `nice-to-have`, nicht begonnen.
  **Entscheidung nötig:** Abschnitt „Literatur und Referenzen“ im öffentlichen
  README anlegen (Vorschlag: `gp.nvim`, `minuet-ai.nvim`, Provider-Doku) oder
  als „nicht angebracht“ abhaken. Der Vergleich mit Completion-Plugins liegt
  privat in `NOTES/completion-plugin-comparison.md`.
- Danach: Tag/Release selbst.

---

## Letzte Session (2026-10-01)

| Repo | Commit | Was |
|---|---|---|
| `ai.nvim` | `2813081` | `test(docs)`: `docs_examples_spec.lua` (REL-08) + Absatz in `TESTS/README.md` |
| `WKDBooks` | `c377f0b` | Handover-Erledigtes („Erledigt seit 2026-09-21“ + docmap-Auslagerung `loomAI@776a830`) nach `Backlog/FEATURES/FINISHED_ai_loomai.md` verschoben |

Der `WKDBooks`-Commit wurde auf Nutzerwunsch nachträglich ohne
`Co-Authored-By`-Trailer umgeschrieben (vorher `0eee4b8`, force-with-lease auf
`main`).

Weitere Funde: CI-Matrix-Korrektur (s. REL-19); `loomAI@776a830` stand im
Handover noch nirgends (jetzt im Backlog nachgetragen).
