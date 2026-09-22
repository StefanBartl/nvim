# ai.nvim — Handover (nur offene Punkte)

> Ausnahme-Standort: normalerweise leben Plugin-Roadmaps im Wkdbook
> (`wkdbook-myplugins/<plugin>/ROADMAP/ROADMAP.md`, siehe `NEW-14`). Diese
> Datei hier ist explizit angefordert als laufende Handover-Akte für
> `ai.nvim` (+ `loomAI`-Anbindung) und bleibt an diesem Ort
> (`nvim/docs/ROADMAP/handovers/ai/`), nicht im Wkdbook.

## Table of content

  - [Feedback](#feedback)
  - [Regeln für diese Session](#regeln-fr-diese-session)
  - [Orte](#orte)
  - [Offene Punkte](#offene-punkte)
    - [1. ai.nvim im Alltag validieren + Live-Testing](#1-ainvim-im-alltag-validieren-live-testing)
    - [2. Phase 10 — `gates/RELEASE.md` vor dem ersten Tag/Release](#2-phase-10-gatesreleasemd-vor-dem-ersten-tagrelease)
    - [3. ui/panel.lua: Voll-Buffer-set_lines pro Stream-Chunk](#3-uipanellua-voll-buffer-set_lines-pro-stream-chunk)
    - [4. loomAI: Connection-Pooling zu Ollama und Cloud-Backends](#4-loomai-connection-pooling-zu-ollama-und-cloud-backends)
    - [5. loomAI-ModelRouter: Präfix-Liste, Timeout/Retry, Capabilities](#5-loomai-modelrouter-prfix-liste-timeoutretry-capabilities)
  - [Erledigt seit 2026-09-21](#erledigt-seit-2026-09-21)

---

## Feedback

## Regeln für diese Session

- Nie mehr als 1 Agent gleichzeitig; bei Bedarf mehrere Runden á 1 Agent, repo-für-repo.
- Antworten Deutsch, Quellcode (inkl. Kommentare) Englisch.
- Keine Co-Autorenschaft von Claude in Commits.
- Nach jedem fertigen Schritt: committen/pushen/pullen, main bleibt aktuell.
- `TOOL-PLACEMENT.md` / `HEREDOC.md` beachten, falls Nebenbei-Tooling entsteht.
- Code muss luacheck/stylua-grün sein (stylua v2.5.2, luacheck 1.2.0, siehe `ci-fleet-conventions`).
- Plugin-Installations-Specs: `vim.fn.stdpath('config')/lua/plugins/personal/init.lua`
  (+ Policy in `plugins/personal/source.lua`).

---

## Orte

| Was | Wo |
|---|---|
| Konzept | `nvim/docs/ROADMAP/IDEAS/ai.nvim.md` |
| Öffentliches Repo | `github.com/StefanBartl/ai.nvim` → `E:\repos\ai.nvim` |
| Privat (Roadmap/Notes, nicht fürs öffentliche Repo) | `E:\repos\WKDBooks\Development\wkdbook-myplugins\ai.nvim\{ROADMAP,NOTES}` |
| Diese Handover-Datei | `nvim/docs/ROADMAP/handovers/ai/ai.nvim_loomai.md` |
| Transport-Erweiterung | `E:\repos\lib.nvim\lua\lib\nvim\net\curl` |
| loomAI (Server, Router, Dashboard) | `E:\repos\loomAI` |
| Regelwerk für neue Projekte | `E:\repos\WKDBooks\Development\wkdbook-Lua\Checklists\gates\NEW_PROJECT.md` (+ `PRINCIPLES.md`, `LUA_NVIM.md`) |
| Live-Testing-Plan | `docs/ROADMAP/personal/All/FINISH/Final_Checks/ai/live-testing-plan.md` |

---

## Offene Punkte

Stand 2026-09-23. Alles andere (Phasen 0-8, Code-Review, loomai-Provider,
ModelRouter, Dashboard-Testpanel, Gemini, Completion-Capability, rules.nvim-
Durchgänge, `pdfport.nvim`-Migration, sowie die vier Punkte unter
[Erledigt seit 2026-09-21](#erledigt-seit-2026-09-21)) ist erledigt.

---

### 1. ai.nvim im Alltag validieren + Live-Testing

- `ai.nvim` im Alltag benutzen (`<leader>ai{a,s,e}`, dazu `loomai`/`gemini`),
  um v1 vor einem Tag zu validieren.
- [Live-Testing-Plan](../../personal/All/FINISH/Final_Checks/ai/live-testing-plan.md)
  **aktualisiert (2026-09-23):** ging noch von "loomAI kann nur Ollama" und
  "kein Gemini-Provider" aus — Abschnitt 9 und die Test-Matrix sind jetzt um
  die drei Cloud-Backends (OpenAI/Anthropic/Gemini) im ModelRouter sowie um
  `providers/gemini.lua` ergänzt. Der eigentliche Alltagsdurchlauf (Env-Vars
  setzen, Schritte abhaken) steht weiterhin aus.
- **`gemini.lua` wurde nie live gegen die echte Gemini-API getestet** (kein
  `GEMINI_API_KEY` vorhanden, am 2026-09-23 weiterhin nicht gesetzt). Nur die
  loomAI-Seite (`gemini_client.cpp`) wurde mit einem bewusst ungültigen Key auf
  dem Fehlerpfad verifiziert. Happy-Path + Streaming + Safety-Block gegen die
  echte API nachholen.

---

### 2. Phase 10 — `gates/RELEASE.md` vor dem ersten Tag/Release

Bewusst noch nicht abgeschlossen: der Plan verlangt echten Alltagsgebrauch vor
dem Tag (Punkt 1). Automatisch prüfbare `REL-*`-Punkte sind grün. Offen,
judgment-basiert:

- REL-08 (README-Beispiele laufen tatsächlich) — Lazy-Spec + `setup()` sind
  end-to-end gegen die echte nvim-Config verifiziert, die übrigen Codeblöcke in
  `docs/*.md` sind zum Teil bewusst illustrativ (z. B. `register()`-Beispiel mit
  `...`-Stub), kein vollständiger Durchlauf jedes Snippets.
- REL-19 (Windows UND POSIX getestet) — CI läuft nur auf `ubuntu-latest`;
  manuell nur unter Windows getestet. POSIX-Seite bislang nur durch CI
  abgedeckt, kein manuelles Durchklicken.
- REL-09/33 (Demo-GIF/Logo) — `nice-to-have`, nicht begonnen.
- REL-32 (Literatur und Referenzen) — `nice-to-have`, nicht begonnen.
- Danach: Tag/Release selbst.

---

### 3. ui/panel.lua: Voll-Buffer-set_lines pro Stream-Chunk

`ui/panel.lua` (`panel.surface:set_lines(panel.lines)`, Zeile ~93) schreibt pro
Stream-Chunk den kompletten Buffer neu statt inkrementell anzuhängen. Bewusst
nicht gefixt (kein Beleg, dass es bei realistischen Antwortlängen ein Problem
ist; `ui.nvim`/Surface hatte keine günstigere Append-API). Nur angehen, falls es
in der Praxis spürbar wird.

---

### 4. loomAI: Connection-Pooling zu Ollama und Cloud-Backends

`src/ollama_client.cpp` (`make_client()`) und die drei Cloud-Clients öffnen pro
`/ask`/`/ask/stream`-Request eine neue TCP-Verbindung (bei den Cloud-Clients
zusätzlich TLS-Handshake). Bewusst nicht gefixt: ein echtes Pooling braucht ein
Design (geteilte Client-Lebensdauer, Thread-Sicherheit, z. B. thread-lokale
Clients), keine Bugkorrektur. Erst bei spürbarem Bedarf angehen.

---

### 5. loomAI-ModelRouter: Präfix-Liste, Timeout/Retry, Capabilities

Alle drei sind `nice-to-have`, nicht blockierend:

- Die Modellname-Präfix-Liste (`gpt-`/`o1-`/`o3-`/`claude-`/`gemini-`) ist
  hartkodiert, keine Config-Möglichkeit — bislang kein Bedarf.
- Timeout-/Retry-Verhalten pro Backend: aktuell identisch zu Ollama übernommen.
  API-spezifisch wäre möglich (Anthropic/OpenAI haben eigene Rate-Limit-Header,
  die man auswerten könnte) — bisher nicht durchdacht.
- Server-seitige `capabilities` (analog `Ai.Provider.capabilities`), z. B. um
  `/ask/stream` für ein Backend ohne Streaming sauber abzulehnen statt zu
  buffern — heute nicht relevant, alle vier Backends streamen nativ; erst falls
  ein zukünftiges Open-Source-Tool kein Streaming kann.

---

## Erledigt seit 2026-09-21

- **loomAI: `ki-agenten-framework-architektur.md`.** Gehörte demselben Muster
  wie das bereits ausgelagerte `setup-guide.md` (beschreibt eine deutlich
  größere, nie gebaute Zukunftsvision) — nach
  `WKDBooks\Development\wkdbook-loomai\Guides\` verschoben (`loomAI@0938b73`,
  `WKDBooks@043f31b`), README dort nachgezogen, die drei Code-/Doc-Verweise im
  öffentlichen Repo (`model_client.hpp`, `ollama_client.hpp`,
  `docmap-checklist-agent.md`) zeigen jetzt auf den neuen Ort
  (`loomAI@0938b73`).
- **Datenschutz-Prinzip.** Existiert bereits als `SEC-15` in
  `WKDBooks\...\wkdbook-Lua\Checklists\regeln\LUA_NVIM.md` — kanonisch, keine
  neue `personal/All/Checklists.md` nötig. Beleg-Zeile war nur gegen das
  ungebaute `typepilot.nvim`-Konzept referenziert; jetzt durch drei tatsächlich
  gebaute, geprüfte Plugins ersetzt: `ai.nvim` (`providers/{openai,claude,
  gemini}.lua` + `providers/util.lua:57-64`, env-only; `health.lua:76-108`,
  Presence-only), `reposcope.nvim` (`utils/env.lua:13-24`, `health.lua:89-95`),
  `github_stats.nvim` (`config/init.lua:204-240`, `health.lua:88-101`)
  (`WKDBooks@425a4a7`).
- **Completion: Abgleich mit fertigen Completion-Plugins.** Vergleich
  geschrieben: `WKDBooks\...\wkdbook-myplugins\ai.nvim\NOTES\
  completion-plugin-comparison.md` (`WKDBooks@e5fb4b2`). Ergebnis: `copilot.lua`
  /`codeium.vim`/`supermaven-nvim` sind Single-Vendor-Hosted-Modelle, keine
  Überschneidung mit `ai.nvim`s BYOK-Design. `minuet-ai.nvim` überschneidet
  sich tatsächlich (auch BYOK, auch Chat-Prompt-Trick für Chat-only-Backends),
  ist aber auf der Completion-Achse deutlich weiter ausgebaut (echtes FIM für
  FIM-fähige Modelle, Multi-Suggestion-Cycling, Throttle/Debounce, Kontext-
  Fenster, Streaming) — bewusst kein Vorbild für `ai.nvim`s Scope (reine
  Ein-Vorschlag-Wiederverwendung der bestehenden `ask()`-Pipeline), höchstens
  Referenz, falls der jetzige Ansatz sich als zu eng erweist. Keine weitere
  Aktion.
- **Wkdbook-ROADMAP: Pfad-Verweis.** Bereits korrekt — bei Prüfung am
  2026-09-23 zeigten alle vier Fundstellen in
  `wkdbook-myplugins\ai.nvim\{FEATURES.md,ROADMAP/ROADMAP.md,Backlog/FEATURES/
  {typepilot.nvim.md,FINISHED_ai_loomai.md}}` bereits auf
  `handovers/ai/ai.nvim_loomai.md`. War wohl schon in einem früheren Durchgang
  mit erledigt worden, nur hier nicht abgehakt.

---

