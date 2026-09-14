# Live-Testing-Plan: `ai.nvim` + `loomAI` (2026-09-14)

> **Zweck:** ein abhakbarer Plan, um die meisten Features beider Repos live
> zu testen — lokal (Ollama) und cloud (Anthropic/OpenAI, Gemini folgt).
> Alle Angaben hier sind gegen den echten Code und die echte Maschine
> geprüft (nicht angenommen), Stand 2026-09-14.

---

## Table of content

  - [Korrektur zur GPU-Angabe](#korrektur-zur-gpu-angabe)
  - [Ein echter Bug, der Ollama-Tests sofort blockiert](#ein-echter-bug-der-ollama-tests-sofort-blockiert)
  - [0. Voraussetzungen](#0-voraussetzungen)
  - [1. Test-Matrix `ai.nvim`](#1-test-matrix-ainvim)
  - [2. Schritt für Schritt: `claude`](#2-schritt-fr-schritt-claude)
  - [3. Schritt für Schritt: `openai`](#3-schritt-fr-schritt-openai)
  - [4. Schritt für Schritt: `ollama` (lokal, RTX 4070 Super)](#4-schritt-fr-schritt-ollama-lokal-rtx-4070-super)
  - [5. Schritt für Schritt: `loomai`](#5-schritt-fr-schritt-loomai)
  - [6. `auto`-Resolution testen](#6-auto-resolution-testen)
  - [7. Quick-Action-Keymaps (`<leader>ai{a,s,e}`)](#7-quick-action-keymaps-leaderaiase)
  - [8. loomAI-Dashboard (Browser)](#8-loomai-dashboard-browser)
  - [9. Cloud-LLM-Breite: was geht heute, was fehlt](#9-cloud-llm-breite-was-geht-heute-was-fehlt)
  - [10. Bekannte, nicht-blockierende Eigenheiten](#10-bekannte-nicht-blockierende-eigenheiten)
  - [Checkliste zum Abhaken](#checkliste-zum-abhaken)

---

## Korrektur zur GPU-Angabe

Du hattest von einer "RTX 5070 Super 12GB" gesprochen — `nvidia-smi` auf
dieser Maschine zeigt tatsächlich eine **RTX 4070 SUPER, 12282 MiB VRAM**
(Modellname `4070`, nicht `5070`; die "5070"-Serie von Nvidia existiert nicht
in dieser Bezeichnung). Passt auch zum bereits im loomAI-Dashboard
hartkodierten Text `GPU · RTX 4070 Super · CUDA 13` — der ist also **nicht**
veraltet, wie ich zunächst vermutet hatte, sondern korrekt. 12 GB VRAM sind
für ein 7-8B-Modell in Q4/Q5-Quantisierung komfortabel (loomAIs eigener
Default `llama3.1:8b-q5_K_M` passt gut); ein größeres Modell (13B+) wird auf
12 GB eng bis unmöglich, je nach Kontextlänge.

---

## Ein echter Bug, der Ollama-Tests sofort blockiert

Auf dieser Maschine ist `OLLAMA_HOST=0.0.0.0:11434` systemweit gesetzt (das
ist Ollamas **eigene** Bind-Adressen-Variable für den Server, üblich z. B.
bei WSL2-/LAN-Setups). `ai.nvim`s `lua/ai/providers/ollama.lua` liest aber
exakt dieselbe Variable, um daraus die **Client**-Ziel-URL zu bauen
(`host()` → `util.env_value("OLLAMA_HOST", DEFAULT_HOST)`,
[ollama.lua:28](E:/repos/ai.nvim/lua/ai/providers/ollama.lua:28)) — das
Ergebnis wäre die Client-Request-URL `0.0.0.0:11434/api/chat` **ohne**
`http://`-Schema, was fehlschlägt.

Das ist exakt dieselbe Verwechslung, die `loomAI`s eigenes README bereits
bewusst vermieden hat (dort heißt die Variable deshalb `LOOMAI_OLLAMA_HOST`,
nicht `OLLAMA_HOST` — siehe Kommentar dort). `ai.nvim`s `ollama.lua` hat den
gleichen Designfehler, den `loomAI` schon kannte, aber selbst nicht
angewendet. **Live reproduziert** auf dieser Maschine (`ollama list` mit
`OLLAMA_HOST=0.0.0.0:11434` schlägt exakt so fehl).

**Vor dem Ollama-Test einer der beiden Wege nötig:**
- Schnell (nur für die Testsession): `unset OLLAMA_HOST` im Terminal, bevor
  Neovim gestartet wird, **oder** `:Ai ask` mit explizitem `config.model.ollama_host`/
  Override, falls vorhanden (aktuell **nicht** vorhanden, s. u.).
- Sauber (empfohlen, siehe Design-Entscheidungen unten): `ollama.lua` auf
  eine eigene Variable umstellen (z. B. `AI_OLLAMA_HOST`), `OLLAMA_HOST`
  gar nicht mehr lesen — analog zu `loomai.lua`s bereits korrektem
  `LOOMAI_HOST`. Das ist ein echter, kleiner Bugfix, kein Testing-Workaround.

---

## 0. Voraussetzungen

| Was | Status auf dieser Maschine (geprüft 2026-09-14) | Aktion nötig? |
| --- | --- | --- |
| `ai.nvim` in nvim-config gewired | ✅ `plugins/personal/init.lua:1244`, Prefix `<leader>ai` | Nein |
| `lib.nvim` mit `fetch_stream` | ✅ verifiziert in vorherigen Sitzungen | Nein |
| `ANTHROPIC_API_KEY` | ❌ **nicht gesetzt** | Ja — setzen, sonst meldet `claude.lua` "not set" |
| `OPENAI_API_KEY` | ✅ gesetzt | Nein |
| `GEMINI_API_KEY`/`GOOGLE_API_KEY` | ❌ nicht gesetzt, **kein Provider existiert bisher** | Siehe [Abschnitt 9](#9-cloud-llm-breite-was-geht-heute-was-fehlt) |
| `OLLAMA_HOST` | ⚠️ gesetzt auf `0.0.0.0:11434` — **bricht `ollama.lua`**, siehe oben | Ja, s. o. |
| Ollama-Daemon läuft | ❌ kein Prozess gefunden (`tasklist`) | Ja — `ollama serve` |
| Ein Ollama-Modell gepullt | ungeprüft (Verbindung schlug fehl, `ollama list` kam nicht durch) | Ja — mind. `llama3.2` (ai.nvim-Default) oder `llama3.1:8b-q5_K_M` (loomAI-Default) |
| `loomAI` gebaut (`build/loomai(.exe)`) | ungeprüft in dieser Sitzung | Ja, falls nicht vorhanden: `cmake -B build && cmake --build build -j4` |
| `loomAI` läuft | Nein (kein Dauerprozess) | Ja — `./build/loomai` in eigenem Terminal offen lassen |
| GPU/VRAM | ✅ RTX 4070 SUPER, 12 GB, aktuell 770 MiB belegt (praktisch frei) | Nein |

---

## 1. Test-Matrix `ai.nvim`

| Provider | `available()` | `ask()` (Happy Path) | `ask()` (Fehlerpfad) | `stream()` (Happy Path) | `stream()` (Fehlerpfad) |
| --- | --- | --- | --- | --- | --- |
| `claude` | ☐ | ☐ | ☐ (ungültiger Key) | ☐ | ☐ |
| `openai` | ☐ | ☐ | ☐ (ungültiger Key) | ☐ | ☐ |
| `ollama` | ☐ | ☐ | ☐ (Daemon aus) | ☐ | ☐ |
| `loomai` | ☐ | ☐ | ☐ (Server aus) | ☐ | ☐ |
| `auto` | ☐ (resolution order) | — | — | — | — |

Jede Zelle: einmal ausführen, Ergebnis beobachten, abhaken. "Fehlerpfad"
heißt bewusst einen Fehler provozieren (falscher Key, Dienst aus) und
prüfen, dass **eine lesbare Fehlermeldung** erscheint — kein Absturz, kein
stiller Erfolg mit leerer Antwort (das war die Bugklasse, die in Phase 3
bereits gefunden wurde).

---

## 2. Schritt für Schritt: `claude`

1. `ANTHROPIC_API_KEY` setzen (echter Key von `console.anthropic.com`).
2. Neovim (neu) starten, damit der Env-Var-Wert im Prozess ankommt.
3. `:checkhealth ai` → Abschnitt "providers" → `claude` sollte `available`
   zeigen (nur Presence-Check, kein Netzwerk-Call).
4. `:Ai provider claude`, dann `:Ai info` → aktiver Provider = `claude`.
5. `:Ai ask "Reply with exactly the word: PONG"` → Panel/Popup mit `PONG`.
6. `:Ai stream "Count from 1 to 5, one number per line"` → Panel füllt sich
   live, nicht in einem Schlag am Ende.
7. **Fehlerpfad:** `ANTHROPIC_API_KEY` kurz auf einen offensichtlich falschen
   Wert setzen (z. B. `export ANTHROPIC_API_KEY=invalid`), Neovim neu
   starten, `:Ai ask "test"` → erwartete, lesbare Fehlermeldung (kein
   Absturz, keine leere Erfolgsantwort). Das ist genau der Bug, der in
   Phase 3 gefunden und gefixt wurde (`claude.lua`s `non_data_lines`) — hier
   nur nochmal verifizieren, dass er nicht wiederkommt.
8. Echten Key zurücksetzen.

---

## 3. Schritt für Schritt: `openai`

Analog zu `claude`, Key ist bereits gesetzt:

1. `:Ai provider openai`, `:Ai info` prüfen.
2. `:Ai ask "Reply with exactly the word: PONG"`.
3. `:Ai stream "Count from 1 to 5"`.
4. Fehlerpfad wie bei `claude` (Key kurz invalidieren).

---

## 4. Schritt für Schritt: `ollama` (lokal, RTX 4070 Super)

1. **Erst den Bug oben fixen/umgehen** (`OLLAMA_HOST` unsetzen oder
   `ollama.lua` auf eigene Variable umstellen — siehe Design-Entscheidungen).
2. `ollama serve` in einem eigenen Terminal starten (falls nicht schon als
   Dienst läuft).
3. Modell pullen — **Achtung, zwei verschiedene Defaults im Spiel:**
   - `ai.nvim`s `ollama.lua`-Default: `llama3.2` (kleines Modell, ca. 3B).
   - `loomAI`s `ollama_client.hpp`-Default: `llama3.1:8b-q5_K_M`.
   - Für einen vollständigen Test beide pullen: `ollama pull llama3.2` und
     `ollama pull llama3.1:8b-q5_K_M` (Q5, passt komfortabel in 12 GB VRAM).
4. `:Ai provider ollama`, `:Ai info`.
5. `:Ai ask "Reply with exactly the word: PONG"`.
6. `:Ai stream "Count from 1 to 5"` — beobachten, ob Tokens einzeln
   ankommen (NDJSON, nicht SSE — andere Zeilenform als `claude`/`openai`,
   siehe `ollama.lua`s Moduldoc).
7. **Fehlerpfad:** `ollama serve` beenden, `:Ai ask "test"` → lesbarer
   Verbindungsfehler, kein Hänger, kein Absturz.

---

## 5. Schritt für Schritt: `loomai`

1. Bauen, falls `build/` fehlt oder veraltet:
   ```bash
   cmake -B build -DCMAKE_BUILD_TYPE=Debug
   cmake --build build -j4
   ```
2. Starten (eigenes Terminal, offen lassen): `./build/loomai` (bzw.
   `build/loomai.exe`). Konsole zeigt die Endpoint-Liste + Ollama-Ziel.
3. Health-Check von Hand: `curl http://127.0.0.1:8080/health` →
   `{"status":"ready","model_router_ready":true}`.
4. In Neovim: `:Ai provider loomai`, `:Ai info` → sollte `available` zeigen
   (nur `curl`-Executable-Check, kein Netzwerk-Roundtrip — auch wenn der
   Server aus wäre, stünde hier trotzdem `available`, s. Scoping-Abschnitt
   im Handover).
5. `:Ai ask "Reply with exactly the word: PONG"` → geht über loomAI an
   Ollama, Antwort im Panel.
6. `:Ai stream "Count from 1 to 5"`.
7. **Fehlerpfad:** loomAI-Prozess beenden, `:Ai ask "test"` → lesbarer
   Verbindungsfehler (kein Hänger).
8. **Fehlerpfad 2 (loomAI-intern):** loomAI laufen lassen, aber `ollama
   serve` beenden → `:Ai ask` sollte den von loomAI durchgereichten
   Ollama-Fehler zeigen (`"ollama: connection refused"`-artig), nicht
   crashen (das war der `4e2777c`-Fix — hier nochmal live verifizieren).

---

## 6. `auto`-Resolution testen

`config.provider_order` ist aktuell `{claude, ollama, openai, loomai}`.

1. Alle vier Backends gleichzeitig verfügbar machen (Keys gesetzt, Ollama
   läuft, loomAI läuft) → `:Ai provider auto`, `:Ai ask "..."` → sollte
   `claude` benutzen (erstes verfügbares in der Order).
2. `ANTHROPIC_API_KEY` unsetzen, Neovim neu starten → `auto` sollte jetzt
   auf `ollama` fallen (zweites in der Order, sofern `ollama`-Binary auf
   PATH ist — Daemon muss nicht zwingend laufen, `available()` prüft nur
   die Binary).
3. Wichtig zu verifizieren: **kein** Crash, egal welche Kombination aus
   Diensten gerade aus ist — das ist der Kern des `resolve()`-Guards aus
   dem Code-Review vom 2026-09-14.

---

## 7. Quick-Action-Keymaps (`<leader>ai{a,s,e}`)

In einer echten Datei mit Diagnostics (z. B. absichtlich einen Lua-Fehler
reinschreiben, damit `nvim-lint`/LSP etwas meldet):

1. `<leader>aia` (normal mode) → Prompt-Eingabe, Antwort im Panel.
2. Visual Mode: Text markieren, `<leader>aia` → Prompt bezieht die Selection
   als Kontext mit ein (im Panel/der gesendeten Anfrage sichtbar).
3. `<leader>ais` → getippte Aufgabe + Kontext wird sofort **gestreamt**.
4. `<leader>aie` → Badge/Toast statt Panel, kurze Erklärung des aktuellen
   Kontexts.
5. Mit Diagnostics im Buffer: prüfen, dass `context.diagnostics` (Format
   `Datei:Zeile:[Severity]:Message`) tatsächlich im gesendeten Prompt
   ankommt (z. B. testweise gegen `ollama` mit einem Modell, das den
   kompletten Prompt zurück-echot, oder Debug-Logging kurz aktivieren).

---

## 8. loomAI-Dashboard (Browser)

**Wichtig zu wissen, bevor du testest:** das Dashboard (`http://127.0.0.1:8080/`)
zeigt aktuell **ausschließlich** den alten Simulations-Agenten
(`run_simulation_agent()` in `main.cpp`) — Planer/Executor/Human-Status,
Decision-Banner mit Allow/Deny-Buttons. Das ist ein **komplett separater,
fest verdrahteter Codepfad**, der mit `/ask`/`/ask/stream` (den echten
LLM-Endpoints) **nichts zu tun hat**. Es gibt aktuell **keine** Chat-/Ask-UI
im Dashboard, um `/ask` visuell zu testen — das geht nur über `curl` oder
über `ai.nvim` in Neovim.

1. Browser öffnen: `http://127.0.0.1:8080/`.
2. SSE-Verbindungsanzeige oben rechts sollte auf "Verbunden" (grün) wechseln.
3. Nach ein paar Sekunden erscheinen automatisch simulierte Planer/Executor-
   Statuszeilen im Log — das ist erwartetes Verhalten der Simulation, kein
   Zeichen für einen echten Agenten.
4. Nach ~16s erscheint der rote Decision-Banner ("Soll ich jetzt den ersten
   Agent-Container starten?") — Allow/Deny klicken, prüfen dass der Banner
   verschwindet und der Log-Eintrag "Entscheidung gesendet" erscheint.
5. Badge "Model: simulation (LLM folgt)" ist ebenfalls **veraltet/irreführend**
   geworden, seit `/ask`/`/ask/stream` echte Ollama-Calls machen — das
   Dashboard wurde seit deren Einführung nicht mehr angepasst. Siehe
   Design-Entscheidung zur UI unten.

---

## 9. Cloud-LLM-Breite: was geht heute, was fehlt

| Anbieter | In `ai.nvim` direkt | Im (noch nicht gebauten) loomAI-ModelRouter | Heute testbar? |
| --- | --- | --- | --- |
| Anthropic (Claude) | ✅ `providers/claude.lua` | 🔲 geplant (Scoping steht) | ✅ Ja (Key setzen) |
| OpenAI | ✅ `providers/openai.lua` | 🔲 geplant (Scoping steht) | ✅ Ja (Key vorhanden) |
| Ollama (lokal) | ✅ `providers/ollama.lua` | ✅ bereits einziges Backend | ✅ Ja (nach OLLAMA_HOST-Fix) |
| **Gemini** | ❌ **existiert nicht** | ❌ **existiert nicht** | ❌ **Nein — noch kein Provider gebaut, siehe Design-Entscheidungen** |
| Andere Open-Source (vLLM/llama.cpp-Server/LM Studio) | ❌ existiert nicht | 🔲 geplant (über OpenAI-kompatiblen Client) | ❌ Nein |

Gemini testen zu wollen ist also aktuell **blockiert**, bis entschieden ist,
wo ein Gemini-Client gebaut wird (`ai.nvim` direkt, loomAI-Router, oder
beides) — siehe die Design-Entscheidungen, die parallel zu diesem Report
zur Auswahl gestellt werden.

---

## 10. Bekannte, nicht-blockierende Eigenheiten

Diese Dinge sind **bekannt** und **kein neuer Bug** — beim Testen nicht
verwirren lassen:

- `ui/panel.lua` macht pro Stream-Chunk ein volles `set_lines()` statt
  inkrementell anzuhängen — bei langen Antworten evtl. spürbares Ruckeln,
  aber kein Korrektheitsproblem (Review-Finding, bewusst zurückgestellt).
- `loomAI`s `ollama_client.cpp` öffnet pro Request eine neue TCP-Verbindung
  zu Ollama statt sie wiederzuverwenden — bei sehr kurzen, aufeinander-
  folgenden Requests minimal langsamer, kein Korrektheitsproblem.
- Das Dashboard-"GPU"-Badge ist korrekt (RTX 4070 Super, s. o.), das
  "Model"-Badge ("simulation (LLM folgt)") ist veraltet/irreführend (s.
  Abschnitt 8) — beides rein kosmetisch, betrifft nicht `/ask`/`/ask/stream`.
- `loomai.available()` macht **keinen** Netzwerk-Check (nur `curl` auf
  PATH) — ein nicht laufendes loomAI zeigt sich beim Test als normaler
  Verbindungsfehler bei `ask()`/`stream()`, nicht als "nicht verfügbar" in
  `:Ai info`. Bewusste Design-Entscheidung, kein Bug.

---

## Checkliste zum Abhaken

- [ ] `ANTHROPIC_API_KEY` gesetzt
- [ ] `OLLAMA_HOST`-Bug umgangen/gefixt
- [ ] Ollama-Daemon läuft, mind. ein Modell gepullt
- [ ] loomAI gebaut und läuft
- [ ] `claude`: available/ask/stream/Fehlerpfad ✅
- [ ] `openai`: available/ask/stream/Fehlerpfad ✅
- [ ] `ollama`: available/ask/stream/Fehlerpfad ✅
- [ ] `loomai`: available/ask/stream/Fehlerpfad (inkl. loomAI-intern) ✅
- [ ] `auto`-Resolution mit mind. 2 unterschiedlichen Verfügbarkeits-
      Kombinationen getestet
- [ ] `<leader>aia`/`<leader>ais`/`<leader>aie` in normal + visual mode
- [ ] loomAI-Dashboard im Browser geöffnet, SSE + Decision-Flow beobachtet
- [ ] Notiert, welche der "bekannten Eigenheiten" (Abschnitt 10) in der
      Praxis tatsächlich störend auffallen (Grundlage für Priorisierung
      der Follow-up-Tasks)
