# Schlachtplan: alle fünf Plugins/Apps live gegen einen echten Claude-Account testen

> Anlass: $250 API-Guthaben erhalten — guter Zeitpunkt, `ai.nvim`, `loomAI`,
> `rules.nvim`, `documentation.nvim` und `docmap-desktop` einmal vollständig
> gegen einen echten Claude-Account zu konfigurieren und durchzutesten,
> inklusive Agent-Modus und `rules.nvim` ("Rulers"). Dieser Report ist ein
> **Plan zum Selbst-Ausführen** auf der eigenen Maschine — die Recherche
> unten läuft in einer Cloud-Session ohne Zugriff auf die lokale Maschine,
> Env-Vars oder laufende Prozesse, deshalb sind alle "Status"-Angaben aus
> vorhandenen Repo-Dokumenten übernommen (mit Quellenangabe), nicht frisch
> selbst gemessen. Stand der Recherche: 2026-09-25.

---

## Inhaltsverzeichnis

- [0. Die wichtigste Unterscheidung zuerst: zwei völlig verschiedene "Claude-Zugänge"](#0-die-wichtigste-unterscheidung-zuerst-zwei-völlig-verschiedene-claude-zugänge)
- [1. Kurzübersicht: wer hat überhaupt eine Claude-Anbindung, und welche Art](#1-kurzübersicht-wer-hat-überhaupt-eine-claude-anbindung-und-welche-art)
- [2. `ai.nvim` (direkter API-Provider)](#2-ainvim-direkter-api-provider)
- [3. `loomAI` (ModelRouter-Server + Dashboard)](#3-loomai-modelrouter-server--dashboard)
- [4. `rules.nvim` ("Rulers") — keine eigene Anbindung, Agent-Modus über Claude Code selbst](#4-rulesnvim-rulers--keine-eigene-anbindung-agent-modus-über-claude-code-selbst)
- [5. `documentation.nvim` — der echte Agent-Modus-Zugang (MCP-Server)](#5-documentationnvim--der-echte-agent-modus-zugang-mcp-server)
- [6. `docmap-desktop` — reiner Viewer, keine eigene Anbindung](#6-docmap-desktop--reiner-viewer-keine-eigene-anbindung)
- [7. Der komplette Schlachtplan in Reihenfolge](#7-der-komplette-schlachtplan-in-reihenfolge)
- [8. Kostenrisiko und Absicherung](#8-kostenrisiko-und-absicherung)
- [9. Offene Punkte, die dieser Plan bewusst nicht löst](#9-offene-punkte-die-dieser-plan-bewusst-nicht-löst)
- [10. Referenzen](#10-referenzen)

---

## 0. Die wichtigste Unterscheidung zuerst: zwei völlig verschiedene "Claude-Zugänge"

Bevor irgendetwas konfiguriert wird, lohnt sich diese Unterscheidung, weil sie
bestimmt, wofür die $250 API-Guthaben überhaupt greifen:

| Zugangsart | Was es ist | Wofür genutzt | Abrechnung |
| --- | --- | --- | --- |
| **Anthropic API-Key** (`ANTHROPIC_API_KEY`, von `console.anthropic.com`) | Direkter, pay-as-you-go-abgerechneter HTTP-Zugriff auf die Messages API | `ai.nvim`s `claude`-Provider, `loomAI`s ModelRouter (Präfix `claude-`) | **Zieht auf das API-Guthaben** |
| **Claude-Account/Abo** (Claude Code, Claude Desktop, claude.ai) | Der Account, mit dem man sich in Claude Code/Claude Desktop anmeldet | MCP-Clients (z. B. `documentation.nvim`s MCP-Server als Tool-Quelle für Claude Code im Agent-Modus) | Läuft über das Abo/den Plan, **nicht** automatisch über das API-Guthaben — außer Claude Code ist explizit auf einen eigenen `ANTHROPIC_API_KEY` umgestellt |

Kurz: Nur `ai.nvim` und `loomAI` verbrauchen unmittelbar das neue Guthaben.
`documentation.nvim`s MCP-Anbindung (der eigentliche "Agent-Modus"-Test) läuft
über den Claude-Account/die Claude-Code-Session selbst, unabhängig vom
API-Guthaben, sofern Claude Code nicht separat auf API-Billing umgestellt
wurde.

---

## 1. Kurzübersicht: wer hat überhaupt eine Claude-Anbindung, und welche Art

| Plugin/App | Direkte Claude-API-Anbindung | Agent-Modus-Anbindung (MCP) | Status im Code |
| --- | --- | --- | --- |
| `ai.nvim` | ✅ `lua/ai/providers/claude.lua` (Anthropic Messages API, Streaming, Vision, Dokumente) | ❌ nicht vorgesehen (bewusste Scope-Grenze, siehe `docs/scope.md`) | Fertig, verdrahtet in der Config, aber laut vorhandenem Live-Testing-Plan **nie gegen einen echten Key getestet** |
| `loomAI` | ✅ `src/anthropic_client.cpp`, ModelRouter-Präfix `claude-` | ⚠️ Dashboard zeigt "Agent-Modus", ist aber **reine Simulation** (`run_simulation_agent()`), keine echte LLM-Anbindung | ModelRouter fertig; Dashboard-Agent-Anzeige veraltet/irreführend |
| `rules.nvim` | ❌ keine | ❌ keine eigene — Output ist für einen externen Agenten (z. B. Claude Code) gedacht | Fertig (Alpha), rein mechanischer Checker |
| `documentation.nvim` | ❌ keine | ✅ echter MCP-Server (`lua/documentation/mcp/`), Tools für Modul-Karte, Call-Graph, Findings | Fertig, seit 2026-08-11 (Phase 1 des V1-Erweiterungsplans), **noch nie live gegen einen echten MCP-Client getestet** laut Repo-Doku |
| `docmap-desktop` | ❌ keine | ❌ keine | Reiner Viewer für documentation.nvim-Maps |

Die Einschätzung des Nutzers war also korrekt: `rules.nvim` und
`docmap-desktop` haben keine eigene Claude-Anbindung. `documentation.nvim`
hat sehr wohl eine — nur eben MCP statt einer direkten API-Anbindung wie
`ai.nvim`.

---

## 2. `ai.nvim` (direkter API-Provider)

**Quelle:** `docs/ROADMAP/Final_Checks/ai/live-testing-plan.md` in diesem
Repo — dort existiert bereits ein sehr ausführlicher, abhakbarer Testplan
(Stand zuletzt aktualisiert 2026-09-23). Dieser Report dupliziert ihn nicht,
sondern fasst nur zusammen, was für den aktuellen Anlass (echter Claude-Key,
$250 Guthaben) relevant ist, und verweist für Details dorthin.

### 2.1 Ausgangslage laut vorhandenem Plan

- `ai.nvim` ist bereits in `lua/plugins/personal/init.lua:1368` verdrahtet
  (Prefix `<leader>ai`, `event = "InsertEnter"` wegen Inline-Completion).
- `ANTHROPIC_API_KEY` war zum Zeitpunkt der letzten Prüfung (2026-09-23)
  **nicht gesetzt** — das ist exakt die Lücke, die die $250 Guthaben jetzt
  schließen.
- Ein bekannter, unabhängiger Bug blockiert `ollama`-Tests
  (`OLLAMA_HOST=0.0.0.0:11434` kollidiert mit `ai.nvim`s eigener Lesart
  derselben Variable) — betrifft `claude` nicht, aber wichtig, falls im
  selben Durchgang auch `auto`-Resolution getestet wird.

### 2.2 Konfigurationsschritte (neu, für den echten Key)

1. Einen echten Anthropic-API-Key unter `console.anthropic.com` erzeugen
   (falls das $250-Guthaben dort verwaltet wird — sonst den Ort prüfen, an
   dem das Guthaben tatsächlich liegt).
2. `ANTHROPIC_API_KEY` als Umgebungsvariable dauerhaft setzen (Shell-Profil,
   nicht nur für eine Session), damit Neovim sie beim Start sieht.
3. Neovim neu starten (Env-Vars werden nur beim Prozessstart gelesen).
4. `:checkhealth ai` → Abschnitt "providers" → `claude` sollte als
   `available` erscheinen (reiner Presence-Check, kein Netzwerk-Call).

### 2.3 Testreihenfolge (Kurzform — Details in Abschnitt 2 des vorhandenen Plans)

1. `:Ai provider claude`, `:Ai info` → aktiver Provider bestätigen.
2. `:Ai ask "Reply with exactly the word: PONG"` → Antwort im Panel.
3. `:Ai stream "Count from 1 to 5, one number per line"` → Streaming live
   beobachten (nicht alles auf einmal am Ende).
4. Fehlerpfad: Key kurz auf einen ungültigen Wert setzen, `:Ai ask "test"`
   → lesbare Fehlermeldung, kein Absturz, keine leere Erfolgsantwort.
5. Inline-Completion (`<C-\><C-a>` im Insert-Mode) einmal gegen `claude`
   ausprobieren (Abschnitt 11 des vorhandenen Plans, Punkt 6 — Provider auf
   `"claude"` umstellen).
6. `auto`-Resolution: mit `claude` als erstem verfügbaren Provider in
   `provider_order` prüfen, dass `:Ai provider auto` tatsächlich `claude`
   wählt.

### 2.4 Bekannter offener Punkt

`GEMINI_API_KEY` war laut demselben Plan ebenfalls nie live getestet — nicht
Teil dieses Anlasses (kein Anthropic-Guthaben betroffen), aber erwähnenswert,
falls im selben Rutsch alle Cloud-Provider durchgetestet werden sollen.

---

## 3. `loomAI` (ModelRouter-Server + Dashboard)

### 3.1 Konfiguration

1. Bauen, falls `build/` fehlt oder veraltet (siehe `README.md` im loomAI-Repo):
   ```bash
   mkdir -p third_party/nlohmann
   curl -sL https://github.com/nlohmann/json/releases/download/v3.11.3/json.hpp \
       -o third_party/nlohmann/json.hpp
   curl -sL https://raw.githubusercontent.com/yhirose/cpp-httplib/v0.15.3/httplib.h \
       -o third_party/httplib.h
   cmake -B build -DCMAKE_BUILD_TYPE=Debug
   cmake --build build -j4
   ```
2. `ANTHROPIC_API_KEY` muss gesetzt sein (derselbe Key wie bei `ai.nvim`,
   loomAI liest ihn eigenständig für seinen `anthropic_client.cpp`).
3. Starten und laufen lassen: `./build/loomai` (eigenes Terminal offen
   lassen — kein Daemon-Modus).
4. `curl http://127.0.0.1:8080/health` → `backends.anthropic` sollte `true`
   zeigen, sobald der Key gesetzt ist.

### 3.2 Testreihenfolge

1. Ein Modell mit Präfix `claude-` direkt gegen `/ask` schicken:
   ```bash
   curl -s http://127.0.0.1:8080/ask \
     -H 'Content-Type: application/json' \
     -d '{"model":"claude-opus-4-5","prompt":"Reply with exactly the word: PONG"}'
   ```
2. Denselben Test über `ai.nvim`s `loomai`-Provider laufen lassen
   (`:Ai provider loomai`, Modell auf ein `claude-*`-Modell stellen, falls
   das Plugin das erlaubt — sonst nur den direkten `curl`-Test nutzen) und
   vergleichen, ob die Antwort identisch durchkommt.
3. `/ask/stream` mit demselben Modell testen (SSE, `data: {"delta": "..."}`-
   Zeilen).
4. Fehlerpfad: Key kurz invalidieren, `/health` sollte `anthropic: false`
   zeigen; `/ask` mit einem `claude-*`-Modell sollte einen lesbaren
   Konfigurationsfehler zurückgeben, keinen Absturz.

### 3.3 Wichtig: das Dashboard ist **kein** Agent-Modus-Test

Das Browser-Dashboard (`http://127.0.0.1:8080/`) zeigt Planer/Executor/
Decision-Banner — das sieht nach einem echten Agenten aus, ist aber laut
`src/main.cpp` (`run_simulation_agent()`, Kommentar im Code: *"Simulations-
Agent (wird später durch echten LLM-Agent ersetzt)"*) eine **fest verdrahtete
Simulation**, komplett getrennt von `/ask`/`/ask/stream`. Das Dashboard mit
dem echten Claude-Account zu "testen" ergibt aktuell keinen Sinn — es gibt
dort schlicht noch keine echte LLM-Anbindung zu testen. Das als **erwartetes
Ergebnis** vorab notieren, damit es beim Test nicht als Bug missverstanden
wird.

---

## 4. `rules.nvim` ("Rulers") — keine eigene Anbindung, Agent-Modus über Claude Code selbst

`rules.nvim` ruft selbst nie ein LLM auf. Es liest Regelsätze (eigene
Markdown-Dateien mit ` ```rule ` -Blöcken), prüft, was sich mechanisch prüfen
lässt (vier Check-Typen: `file_exists`, `grep`, `errline`, `lua_predicate`,
`json_key`), und meldet den Rest als offene Punkte — bewusst **ohne** ein
automatisches Urteil über Regeln zu fällen, die menschliches oder
Agenten-Urteilsvermögen brauchen (`README.md`: *"it never pretends to give
an automatic verdict on a rule that actually needs human or agent
judgment"*).

Das heißt: "im Agent-Modus testen" bedeutet hier **nicht**, `rules.nvim`
selbst mit einem Claude-Key zu konfigurieren (es gibt dafür keine Option),
sondern zu prüfen, dass ein Agent (Claude Code selbst, oder `ai.nvim`, das
den Report als Kontext bekommt) den maschinenlesbaren Output sinnvoll
weiterverarbeiten kann.

### 4.1 Konfiguration

Bereits verdrahtet in `lua/plugins/personal/init.lua:781` mit den drei
Gates `new_project`/`release`/`review`, `rulesets` zeigt auf
`$REPOS_DIR/WKDBooks/Development/wkdbook-Lua/Checklists`. Keine
Claude-spezifische Konfiguration nötig.

### 4.2 Testreihenfolge

1. `:Rules check --family=DEP` (oder eine andere Familie) → Report im
   Standard-Format (Quickfix/Buffer, je nach `report/`-Backend).
2. `:Rules check --family=DEP --format=json` → maschinenlesbarer JSON-Report
   (`report/json.lua`), jeder Eintrag mit `id`/`severity`/`status`/
   `findings`.
3. `:Rules gate review` → alle Familien aus dem `review`-Gate
   (`ERR/LUA/UI/CMT/SEC/PRIN/PERF`) auf einmal.
4. **Der eigentliche Agent-Modus-Test:** den JSON-Report (oder die
   `manual`-Status-Einträge daraus) als Kontext in eine echte Claude-Session
   geben — entweder direkt in Claude Code (diese Session selbst kann das)
   oder über `ai.nvim`s `:Ai stream` mit dem JSON als angehängtem Kontext —
   und beurteilen lassen, ob Claude sinnvolle Einschätzungen zu den
   `manual`-Regeln liefert, die `rules.nvim` bewusst nicht selbst entscheidet.
5. `:Rules stats` und `:Rules show <ID>` als Ergänzung, um zu prüfen, dass
   Navigation zur Regel-Quelle funktioniert (nicht Claude-relevant, aber
   Teil des "alles einmal anfassen"-Anlasses).

---

## 5. `documentation.nvim` — der echte Agent-Modus-Zugang (MCP-Server)

Das ist der Plugin-Teil, der tatsächlich einen echten Claude-Account (Claude
Code oder Claude Desktop) als MCP-Client braucht — unabhängig vom
API-Guthaben. Quelle: `docs/mcp.md` im `documentation.nvim`-Repo, Feature
seit 2026-08-11 ("Phase 1 des V1-Erweiterungsplans"), laut derselben Doku
noch nie live gegen einen echten MCP-Client verifiziert (nur per Testsuite,
`TESTS/mcp_spec.lua`, gegen simulierte JSON-RPC-Nachrichten).

### 5.1 Konfiguration

1. In der MCP-Konfiguration des Claude-Clients (Claude Code: projekt- oder
   userweite `mcp` bzw. `.mcp.json`-Konfiguration; Claude Desktop:
   `claude_desktop_config.json`) einen Eintrag ergänzen:
   ```json
   {
     "mcpServers": {
       "documentation": {
         "command": "nvim",
         "args": ["--headless", "-l", "scripts/mcp_server.lua"],
         "cwd": "/pfad/zum/eigenen/repo"
       }
     }
   }
   ```
   `cwd` auf das Repo zeigen lassen, dessen Modul-Karte abgefragt werden
   soll (z. B. `ai.nvim` selbst, oder `documentation.nvim` auf sich selbst
   angewendet als erster Test).
2. Wichtig laut Moduldoc (`lua/documentation/mcp/init.lua`): der Server
   erwartet, dass **kein anderer Code** auf stdout schreibt (kein
   `print()`), sonst korrumpiert das den JSON-RPC-Stream. Für einen ersten
   Test lieber ein "sauberes" Repo ohne exotische Autocommands verwenden.
3. Der Scan läuft beim Start (`install()`), nicht lazy — bei einem großen
   Baum kann der erste Handshake spürbar dauern; das ist erwartetes
   Verhalten, kein Hänger.

### 5.2 Testreihenfolge

1. Den MCP-Server von Hand starten und beobachten, dass er auf eine Zeile
   wartet (kein Absturz, kein sofortiges Beenden):
   ```bash
   nvim --headless -l scripts/mcp_server.lua
   ```
   (Interaktiv wirkt das "hängend" — das ist beabsichtigt, siehe `docs/mcp.md`.)
2. Diesen Server in Claude Code als MCP-Server registrieren (Schritt 5.1),
   Claude Code neu starten/die Verbindung neu aufbauen lassen.
3. In einer echten Claude-Code-Session (mit diesem Account) prüfen, dass
   die Tools sichtbar sind: `docmap_modules`, `docmap_node`,
   `docmap_requires`, `docmap_required_by`, `docmap_callees`,
   `docmap_callers`, `docmap_findings`, `docmap_rescan`, `docmap_checklist`.
4. Mindestens einen Tool-Aufruf pro Kategorie live durchspielen, z. B.:
   - "Zeig mir alle Module unter `lua/ai/providers`" → `docmap_modules`
     mit `prefix`.
   - "Was hängt von `providers/claude.lua` ab?" → `docmap_required_by`.
   - "Welche Drift-Findings gibt es aktuell?" → `docmap_findings`.
5. Fehlerpfad bewusst provozieren: eine ungültige Node-ID anfragen lassen →
   sollte als `isError`-Tool-Result zurückkommen (für das Modell sichtbar
   und korrigierbar), nicht als JSON-RPC-Fehler, der den Client-seitigen
   Fehlerpfad triggert.
6. Nach einer Dateiänderung im Zielrepo `docmap_rescan` aufrufen lassen und
   prüfen, dass die neuen Zahlen ankommen (kein automatisches File-Watching
   — bewusste Design-Entscheidung, siehe `docs/mcp.md`).
7. Bewusst **nicht** erwarten, dass ein Tool `@verified`-Einträge im
   Checklist-Format schreibt — `docmap_checklist` ist read-only, das
   Schreiben bleibt laut `PROTOCOLS_AND_AGENTS.md` explizit Menschen
   vorbehalten (Trennung von prüfender und geprüfter Instanz).

---

## 6. `docmap-desktop` — reiner Viewer, keine eigene Anbindung

Kein LLM-Bezug im Code. Der Test hier hat nichts mit dem Claude-Account zu
tun, gehört aber zum "alles einmal anfassen"-Anlass, weil die App die
Ergebnisse von `documentation.nvim` (inklusive dem, was über MCP erzeugt
oder als Grundlage genutzt wurde) sichtbar macht.

### 6.1 Konfiguration

1. `documentation.nvim`s Standalone-Engine-Binary muss vorhanden sein (die
   App führt sie aus, ersetzt sie nicht — siehe App-README, Abschnitt
   "Get the app").
2. Die App selbst per Release-Installer installieren oder aus dem Repo
   bauen (`src-tauri/`, Rust-Toolchain nötig für den Eigenbau).

### 6.2 Testreihenfolge

1. App starten, ein Projekt hinzufügen (z. B. `ai.nvim` oder
   `documentation.nvim` selbst), Map generieren lassen.
2. Prüfen, dass die generierte Map dieselben Daten zeigt, die auch über den
   MCP-Server (Abschnitt 5) abgefragt wurden — ein einfacher
   Konsistenz-Check zwischen "Agent sieht X über MCP" und "Mensch sieht X im
   Viewer".
3. Kein gesonderter Claude-Account-Test nötig oder möglich — diese App
   bewusst außen vor lassen, wenn es nur um den Account-Test geht.

---

## 7. Der komplette Schlachtplan in Reihenfolge

Empfohlene Reihenfolge für eine einzelne Testsession, von "kostenlos/lokal"
zu "kostet Guthaben" zu "braucht den Account statt API-Key":

1. **`rules.nvim`** zuerst (Abschnitt 4) — kostenlos, keine Abhängigkeiten,
   verifiziert nur, dass die Rule-Engine selbst intakt ist, bevor sie als
   Kontext für einen Agenten dient.
2. **`documentation.nvim` MCP-Server** (Abschnitt 5) — läuft über den
   Claude-Account, nicht über das API-Guthaben; als zweites testen, um zu
   wissen, ob die Account-Seite grundsätzlich funktioniert, bevor Geld für
   API-Calls ausgegeben wird.
3. **`docmap-desktop`** (Abschnitt 6) — kurzer Konsistenz-Check gegen das,
   was der MCP-Server gerade gezeigt hat.
4. **`ai.nvim` mit `claude`-Provider** (Abschnitt 2) — erster Punkt, der
   tatsächlich das API-Guthaben verbraucht. Klein anfangen (ein `:Ai ask`
   mit kurzer Antwort), bevor Streaming/Completion/`auto`-Resolution folgen.
5. **`loomAI` mit Anthropic-Backend** (Abschnitt 3) — letzter Schritt, weil
   er `ai.nvim`s Ergebnis als Vergleichsbasis nutzt (derselbe Key, derselbe
   Provider, zwei verschiedene Codepfade — Abweichungen wären ein Bug in
   einem der beiden).

---

## 8. Kostenrisiko und Absicherung

- Jeder `:Ai ask`/`:Ai stream`-Aufruf gegen `claude` und jeder
  `/ask`-Aufruf gegen loomAIs `claude-*`-Präfix zieht auf das API-Guthaben.
  Für reine Funktionstests reichen sehr kurze Prompts (`"Reply with exactly
  the word: PONG"`) — bewusst so kurz halten, nicht mit langen
  Streaming-Antworten oder großen Attachments (PDF/Bild) anfangen.
- `completion.trigger = "auto"` in `ai.nvim` (Abschnitt 11 im vorhandenen
  Live-Testing-Plan) löst bei jeder Tippunterbrechung einen API-Call aus —
  laut diesem Plan bewusst nur kurz und am besten gegen `ollama`
  ausprobieren, nicht dauerhaft mit `claude` kombinieren.
- Der MCP-Server (`documentation.nvim`) verbraucht kein API-Guthaben — die
  Kosten dort (falls welche anfallen) hängen am Claude-Code/Claude-Desktop-
  Plan, nicht an diesem Key.

---

## 9. Offene Punkte, die dieser Plan bewusst nicht löst

- **`OLLAMA_HOST`-Bug** in `ai.nvim`s `ollama.lua` (kollidiert mit Ollamas
  eigener Server-Bind-Variable) — betrifft `claude`-Tests nicht direkt, aber
  relevant, sobald `auto`-Resolution mit allen Backends getestet wird. Siehe
  vorhandenen Live-Testing-Plan, Abschnitt "Ein echter Bug, der
  Ollama-Tests sofort blockiert".
- **loomAI-Dashboard zeigt weiterhin nur die Simulation** — kein Ticket
  dafür in diesem Report, nur die Erwartung dokumentiert (Abschnitt 3.3),
  damit es beim Testen nicht mit einem Bug verwechselt wird.
- **`GEMINI_API_KEY`** war laut vorhandenem Plan nie live getestet — nicht
  Teil dieses Anlasses, aber ein naheliegender nächster Schritt, falls auch
  dafür Guthaben vorhanden ist.
- Dieser Report wurde **nicht** gegen die tatsächliche lokale Maschine
  verifiziert (Cloud-Session ohne Zugriff auf lokale Env-Vars/Prozesse) —
  alle "Status"-Spalten stammen aus vorhandenen Repo-Dokumenten. Die
  eigentliche Live-Verifikation (Abschnitte 2–6) ist der nächste Schritt,
  lokal auszuführen.

---

## 10. Referenzen

- `ai.nvim`: `docs/ROADMAP/Final_Checks/ai/live-testing-plan.md` (dieses
  Repo) — der bereits vorhandene, sehr ausführliche Testplan für
  `ai.nvim`/`loomAI`.
- `ai.nvim`: `docs/scope.md`, `docs/quickstart.md`, `docs/configuration.md`,
  `lua/ai/providers/claude.lua`.
- `loomAI`: `README.md`, `src/main.cpp` (`run_simulation_agent`),
  `src/anthropic_client.cpp`.
- `rules.nvim`: `README.md`, `lua/rules/bindings/usrcmds.lua`,
  `lua/rules/report/json.lua`.
- `documentation.nvim`: `docs/mcp.md`, `lua/documentation/mcp/init.lua`,
  `lua/documentation/mcp/tools.lua`, `PROTOCOLS_AND_AGENTS.md`.
- `docmap-desktop`: `README.md` (Abschnitte "Get the app", "What already
  exists, and what this adds").
