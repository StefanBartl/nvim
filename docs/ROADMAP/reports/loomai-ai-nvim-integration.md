# loomAI → `ai.nvim`-Provider: was loomAI konkret bräuchte

> **Zweck dieser Datei:** eine erschöpfende, konkrete Aufgabenliste — nicht "loomAI
> braucht einen Ask-Endpoint" in einem Satz, sondern jedes Feld, jeder Endpoint, jede
> Fehlerform, die `ai.nvim`s Provider-Registry tatsächlich voraussetzt, Zeile für Zeile
> gegen den echten Code auf beiden Seiten geprüft (Stand 2026-09-14).
>
> **Kein Auftrag, keine Priorität, kein Termin.** Diese Datei beschreibt nur *was*
> fehlt, nicht *ob*/*wann* es gebaut wird. Laut Handover-Regel (`nvim/docs/ROADMAP/
> handovers/ai.nvim.md`) bleibt `loomai` in `ai.nvim`s `provider_order` bewusst
> ausgeschlossen, bis das hier existiert — nichts davon ist Voraussetzung für
> `ai.nvim` v1.

---

## Inhaltsverzeichnis

1. [Ist-Stand loomAI](#1-ist-stand-loomai)
2. [Der Vertrag, den `ai.nvim` tatsächlich verlangt](#2-der-vertrag-den-ainvim-tatsächlich-verlangt)
3. [Aufgabe A — Health/Availability](#aufgabe-a--healthavailability)
4. [Aufgabe B — Non-Streaming Ask-Endpoint](#aufgabe-b--non-streaming-ask-endpoint)
5. [Aufgabe C — Streaming-Endpoint (SSE)](#aufgabe-c--streaming-endpoint-sse)
6. [Aufgabe D — Fehlerformat](#aufgabe-d--fehlerformat)
7. [Aufgabe E — Modellauswahl](#aufgabe-e--modellauswahl)
8. [Aufgabe F — Netzwerk/Auth](#aufgabe-f--netzwerkauth)
9. [Offene Design-Frage: `available()` vs. Netzwerk-Health-Check](#9-offene-design-frage-available-vs-netzwerk-health-check)
10. [Was NICHT gebraucht wird](#10-was-nicht-gebraucht-wird)
11. [Danach: der `loomai`-Provider in `ai.nvim` selbst](#11-danach-der-loomai-provider-in-ainvim-selbst)
12. [Trigger — wann das hier aufgegriffen wird](#12-trigger--wann-das-hier-aufgegriffen-wird)

---

## 1. Ist-Stand loomAI

Geprüft direkt im Code, nicht nur im Architekturplan (`E:\repos\loomAI\src\main.cpp`,
`E:\repos\loomAI\docs\Guides\ki-agenten-framework-architektur.md`):

- Server: `cpp-httplib`, hört auf `0.0.0.0:8080`.
- **Zwei Endpoints existieren:**
  - `GET /events` — SSE, liefert Events eines *simulierten* Agenten
    (`run_simulation_agent()`, hartkodierte `sleep`s + Textzeilen wie "Prüfe
    verfügbare Container-Runtime (Podman)..."). Kein LLM-Call dahinter.
  - `POST /decision` — nimmt `{id, answer}` entgegen, quittiert mit `{"ok":true}`.
    Für den Human-in-the-Loop-Decision-Flow des Dashboards, nicht für Prompts.
- **Kein** `ModelRouter`, **kein** `anthropic_client`, **kein** `ollama_client` im
  Code — nur in `docs/Guides/ki-agenten-framework-architektur.md` als "Phase 1:
  Model Integration (Woche 3-4)" geplant, nicht begonnen.
- **Kein Endpoint, der einen Prompt entgegennimmt und eine Antwort zurückgibt.**
  Genau das ist die Lücke, um die es hier geht.

Passend dazu loomAIs eigener Roadmap-Absatz (`ki-agenten-framework-architektur.md`,
Abschnitt 11, "Phase 1"):

```
- [ ] Ollama REST-Client in C++ (HTTP GET/POST via cpp-httplib)
- [ ] Anthropic API Client (streaming SSE-Antworten)
- [ ] Model Router mit einfacher VRAM-Heuristik
- [ ] Erster "Hello World" Agent: sendet Prompt, gibt Antwort zurück
```

Der letzte Punkt dieser Liste — "sendet Prompt, gibt Antwort zurück" — ist inhaltlich
exakt das, was als HTTP-Endpoint exponiert werden müsste. Diese Datei hier
spezifiziert nur, *wie* dieser Endpoint aussehen muss, damit `ai.nvim` ihn ansprechen
kann — nicht, wie der Model Router selbst gebaut wird (das ist loomAIs eigene Sache).

---

## 2. Der Vertrag, den `ai.nvim` tatsächlich verlangt

Wörtlich aus `E:\repos\ai.nvim\lua\ai\@types\init.lua`:

```lua
---@class Ai.Provider
---@field id string
---@field name? string
---@field available fun(): boolean
---@field ask fun(req: Ai.Request, cb: fun(ok: boolean, res_or_err: Ai.Response|string)): nil
---@field stream fun(req: Ai.Request, handlers: Ai.StreamHandlers): vim.SystemObj|nil
---@field capabilities? { vision?: boolean, streaming?: boolean, max_tokens?: integer }

---@class Ai.Request
---@field prompt string
---@field system? string
---@field context? table
---@field provider? string
---@field model? string
---@field timeout_ms? integer

---@class Ai.Response
---@field text string
---@field usage? table
---@field stop_reason? string
---@field provider string

---@class Ai.StreamHandlers
---@field on_chunk? fun(delta: string)
---@field on_done? fun(res: Ai.Response)
---@field on_error? fun(err: string)
```

`ask()`/`stream()` sind **Lua-seitige** Funktionen in `ai.nvim` — ein zukünftiges
`lua/ai/providers/loomai.lua` würde sie implementieren, genau wie `claude.lua`/
`ollama.lua`/`openai.lua` das heute tun (`E:\repos\ai.nvim\lua\ai\providers\`). Was
**loomAI selbst** bereitstellen muss, ist die HTTP-Gegenseite, gegen die dieses
`loomai.lua` dann curl-Requests schickt (über `lib.nvim.net.curl`, exakt wie die
drei bestehenden Provider). Die folgenden Aufgaben beschreiben diese HTTP-Gegenseite.

---

## Aufgabe A — Health/Availability

**Was fehlt:** ein Endpoint, den `ai.nvim` kurz anfragen kann, um zu wissen, ob
loomAI überhaupt läuft und einsatzbereit ist (analog zu `claude.lua`s
`vim.fn.executable("curl") == 1 and api_key() ~= nil`, nur eben für einen
HTTP-Server statt einer lokalen Binary).

**Konkret gebraucht:**
- `GET /health` (oder `/status`) → `200 OK` mit einem kleinen JSON-Body, z. B.:
  ```json
  { "status": "ready", "model_router_ready": true }
  ```
- Muss **schnell** sein (kein Model-Laden, kein VRAM-Check mit Sekunden-Latenz) —
  ein reiner "Prozess lebt und kann einen Request annehmen"-Check.
- Sollte `503`/`{"status":"loading"}` o. Ä. liefern, wenn der Server zwar läuft,
  aber z. B. gerade noch kein Modell geladen hat — `ai.nvim` müsste das als
  "nicht verfügbar" werten, nicht als Fehler.

**Warum:** siehe [Abschnitt 9](#9-offene-design-frage-available-vs-netzwerk-health-check)
— das ist die Stelle, an der `ai.nvim`s eigentliche Anforderung ("`available()` muss
synchron und billig sein, kein Netzwerk-Roundtrip") mit einem HTTP-basierten Provider
in Konflikt gerät. Muss vor der Umsetzung entschieden werden, nicht danach.

---

## Aufgabe B — Non-Streaming Ask-Endpoint

**Was fehlt:** ein Endpoint äquivalent zu Anthropics/OpenAIs Chat-Completion-Call,
für `ai.nvim`s `M.ask()` (nicht-streamend).

**Konkret gebraucht:** `POST /ask` (Name frei wählbar, aber ein einzelner, stabiler
Pfad — kein "erst `/task` einreihen, dann pollen", das passt nicht zu `ai.nvim`s
Ask/Callback-Modell).

Request-Body (JSON), Felder direkt aus `Ai.Request` übernehmbar:

```json
{
  "prompt": "Why does this test fail?",
  "system": "optional system prompt",
  "model": "optional model name/id",
  "context": "optional, bereits als Text zusammengesetzt (ai.nvim baut den Kontext-Block selbst — siehe ai.context.assemble())"
}
```

- `prompt` ist das einzige Pflichtfeld. `ai.nvim` hat den Kontext (Buffer/Selection/
  Diagnostics) zu diesem Zeitpunkt bereits als Text **in** `prompt` eingebettet
  (`ai/init.lua`s `build_prompt()`) — loomAI muss also **keinen** strukturierten
  Kontext-Typ verstehen, nur einen einzelnen langen String.
- `model` optional: loomAIs eigener `ModelRouter` darf selbst entscheiden
  (lokal/cloud), wenn das Feld fehlt — das ist ja gerade der Sinn des Routers.

Response-Body (JSON), 1:1 nach `Ai.Response`:

```json
{
  "text": "the model's full answer",
  "usage": { "...": "provider-spezifisch, wird von ai.nvim nur durchgereicht" },
  "stop_reason": "optional string, z.B. \"end_turn\"",
  "provider": "loomai"
}
```

- `text` ist das einzige Pflichtfeld auf `ai.nvim`-Seite.
- HTTP-Status `200` bei Erfolg. Alles andere (4xx/5xx) wird von `ai.nvim` als
  Fehler behandelt (siehe [Aufgabe D](#aufgabe-d--fehlerformat)).
- Timeout: `ai.nvim` schickt `req.timeout_ms` (Default 60000) an
  `lib.nvim.net.curl.fetch_json` als Curl-Timeout — loomAI muss innerhalb dieser
  Zeit antworten oder die Verbindung wird clientseitig gekappt. Kein serverseitiger
  Timeout-Parameter nötig, aber loomAI sollte selbst nicht ewig hängen (z. B. wenn
  der Model Router lokal auf ein hängendes `ollama` wartet).

---

## Aufgabe C — Streaming-Endpoint (SSE)

**Was fehlt:** ein Streaming-Pendant zu Aufgabe B, für `ai.nvim`s `M.stream()`.

**Wichtig, weil schon einmal vorhanden:** loomAI hat mit `GET /events` bereits
einen SSE-Server-Codepfad (`main.cpp:86-114`, `set_chunked_content_provider`,
`text/event-stream`) — die Mechanik existiert, sie liefert nur die falschen Daten
(Simulations-Events statt Modell-Tokens). Der neue Endpoint kann denselben
cpp-httplib-Mechanismus wiederverwenden.

**Konkret gebraucht:** `POST /ask/stream` (oder `?stream=true` auf demselben
`/ask`-Pfad wie Aufgabe B — beides ist für `ai.nvim` gleich einfach anzusprechen,
solange der Pfad stabil und dokumentiert ist).

- **Format: SSE, `data: <json>\n\n` pro Zeile**, exakt wie Anthropic/OpenAI es
  bereits tun — `ai.nvim`s `lib.nvim.net.curl.fetch_stream` liefert Zeilen roh
  durch (`data:`-Präfix-Erkennung passiert im `loomai.lua`-Provider selbst, nicht
  im Transport, siehe `claude.lua`/`openai.lua` als Vorlage). Ein Chunk-JSON könnte
  z. B. so aussehen:
  ```
  data: {"delta": "Hello"}

  data: {"delta": ", world"}

  data: [DONE]

  ```
  (Das exakte Feld für den Text-Delta ist frei wählbar — `ai.nvim`s Provider-Code
  liest es ohnehin explizit aus, wie `claude.lua`s `decoded.delta.text` oder
  `openai.lua`s `choices[1].delta.content` es heute tun. Wichtig ist nur: **ein
  JSON-Objekt pro `data:`-Zeile**, kein mehrzeiliges JSON pro Event.)
- **`-N`/kein Server-seitiges Puffern**: cpp-httplibs `set_chunked_content_provider`
  macht das bereits richtig (siehe `main.cpp`s bestehender `/events`-Handler) — nur
  sicherstellen, dass das bei echten, potenziell langsam eintreffenden LLM-Tokens
  genauso funktioniert (nicht erst puffern, bis ein ganzer Satz da ist).
- **Bei einem Fehler mitten im Stream** (das exakte Muster, das in
  `claude.lua`/`openai.lua` bereits als echter, gefundener Bug dokumentiert ist,
  siehe `E:\repos\ai.nvim\lua\ai\providers\sse.lua`): **nicht** die HTTP-Verbindung
  einfach mit einem rohen, nicht-SSE-förmigen JSON-Body abbrechen. Stattdessen ein
  reguläres SSE-Event senden, z. B. `data: {"error": {"message": "..."}}`, danach
  den Stream sauber schließen. Das erspart `ai.nvim`s Provider-Code genau die
  Sonderbehandlung, die bei Claude/OpenAI nötig war.
- Ende des Streams: entweder Verbindung schließen (curl erkennt das über
  `on_done`/Prozessende) oder ein explizites `data: [DONE]` senden — beides
  funktioniert mit `ai.nvim`s Transport, ein explizites `[DONE]` ist aber robuster.

---

## Aufgabe D — Fehlerformat

**Was fehlt:** eine konsistente Fehlerantwort für Aufgabe B (nicht-streamend).

**Konkret gebraucht:** bei einem Fehler (Model Router nicht erreichbar, ungültiger
Request, internes Timeout) einen JSON-Body mit mindestens einer menschenlesbaren
Nachricht, z. B.:

```json
{ "error": { "message": "ollama: connection refused" } }
```

- HTTP-Status sollte den Fehler widerspiegeln (`4xx` für einen ungültigen Request,
  `5xx` für einen internen/Model-Router-Fehler) — `ai.nvim`s `curl.fetch_json`
  meldet einen `ok=false` bereits bei jedem Nicht-2xx-Status, das Body-Parsing des
  `error.message`-Felds passiert dann im `loomai.lua`-Provider (exakt wie
  `claude.lua`s `decoded.error and decoded.error.message`).
- **Nie** eine leere `200 OK`-Antwort bei einem internen Fehler — das ist genau
  die Fehlerklasse, die die `sse.lua`-Recovery-Logik bei Claude/OpenAI umgehen
  musste (ein curl-Exit-Code 0 bei einem inhaltlichen Fehler).

---

## Aufgabe E — Modellauswahl

**Was fehlt:** eine Antwort auf die Frage "welche Modelle kann man über loomAI
ansprechen", falls `ai.nvim`s `req.model`/`config.model.loomai` etwas Sinnvolles
tun soll.

**Zwei gangbare Optionen, beide für `ai.nvim` gleich einfach:**
1. **Frei/undokumentiert** (wie aktuell bei `openai.lua`/`ollama.lua`): `model` ist
   ein beliebiger String, loomAI validiert ihn selbst oder ignoriert ihn und lässt
   den `ModelRouter` (VRAM-Budget, Task-Typ) selbst entscheiden. Kein zusätzlicher
   Endpoint nötig — **empfohlen als erster Schritt**, siehe `wkdbook-myplugins/
   ai.nvim/ROADMAP/ROADMAP.md`s offener Punkt "Modell-Registry pro Provider" (dort
   bewusst noch nicht gebaut, aus demselben "erst einfach"-Grund).
2. **Validiert**: `GET /models` listet verfügbare Modell-Ids — nur relevant, falls
   `ai.nvim` später tatsächlich eine validierte Modell-Liste pro Provider bekommt
   (aktuell nicht der Fall, s. o.).

---

## Aufgabe F — Netzwerk/Auth

- **Kein API-Key/Secret nötig**, solange loomAI nur auf `127.0.0.1`/`localhost`
  hört (aktuell `0.0.0.0:8080` laut `main.cpp:136` — für einen reinen
  Editor-Companion-Prozess sollte das eher `127.0.0.1` sein, um nicht versehentlich
  im LAN erreichbar zu sein). Falls loomAI doch einen Auth-Header erwartet: über
  `lib.nvim.net.curl`s `secret_headers`-Mechanismus reichbar (derselbe Weg, den
  `claude.lua` für `x-api-key` nutzt) — kein neuer Transport-Code nötig.
- **Konfigurierbare Basis-URL**: `ai.nvim`-seitig würde das ein
  `config.model.loomai_host`-artiges Feld (Analogie zu `ollama.lua`s
  `OLLAMA_HOST`/`DEFAULT_HOST`), default vermutlich `http://127.0.0.1:8080`.
  loomAI muss dafür nichts weiter tun außer den Port stabil zu halten.
- **CORS ist irrelevant** — `ai.nvim` spricht loomAI über `curl` an (Server-zu-
  Server aus Sicht von loomAI), nicht aus einem Browser heraus. Die bestehenden
  `Access-Control-Allow-Origin: *`-Header in `main.cpp:87` sind nur fürs
  Browser-Dashboard nötig und für diese Integration ohne Bedeutung.

---

## 9. Offene Design-Frage: `available()` vs. Netzwerk-Health-Check

Das ist der einzige Punkt hier, der nicht einfach eine Endpoint-Spezifikation ist,
sondern **vor** der Umsetzung entschieden werden sollte:

- `ai.nvim`s eigener Vertrag (`@types/init.lua:59-61`) verlangt wörtlich: *"`available()`
  must be cheap and synchronous (it runs on every `"auto"` resolution) -- an
  executable-on-PATH / env-var check, not a network round trip."*
- Der bisherige Handover-Eintrag (`nvim/docs/ROADMAP/handovers/ai.nvim.md`,
  Abschnitt "loomAI: Entscheidung & Fallback") sagt dagegen: *"Health-Check:
  `available()` macht einen kurzen `GET` gegen die konfigurierte loomAI-Basis-URL."*

  Das ist ein Widerspruch zum eigenen Interface-Vertrag von `ai.nvim` selbst —
  `ollama.lua`s `available()` löst dasselbe Problem heute, indem es **nur**
  `vim.fn.executable("ollama") == 1` prüft (keine Netzwerk-Anfrage an den Daemon,
  siehe Kommentar dort: *"No network round trip here on purpose -- available()
  runs on every 'auto' resolution and must stay cheap [...] an actually
  unreachable daemon still surfaces as a normal request failure"*).

**Für `loomai.lua` heißt das konkret, eine von zwei Optionen zu wählen, sobald
dieser Task aufgegriffen wird:**
- **(a) Analog zu `ollama.lua`**: `available()` prüft nur etwas synchrones und
  lokales — z. B. ob ein PID-File/Lock-File existiert, das loomAI beim Start
  anlegt, oder schlicht `true` zurückgeben und eine unerreichbare Instanz als
  normalen Request-Fehler durchreichen (loomAI bräuchte dafür **nichts
  Zusätzliches** zu bauen — Aufgabe A entfiele dann sogar).
- **(b) Echter Health-Check**: `available()` macht den kurzen `GET /health`
  aus Aufgabe A trotzdem, weicht damit aber bewusst vom eigenen Interface-Vertrag
  ab (dokumentiert als Ausnahme, mit Begründung im Code-Kommentar) — dann bräuchte
  loomAI den Health-Endpoint wie in Aufgabe A beschrieben.

Empfehlung an dieser Stelle (nicht bindend): **(a)**, aus Konsistenzgründen mit
`ollama.lua` und weil es loomAI-seitig gar nichts erfordert — Aufgabe A wird damit
optional statt zwingend.

---

## 10. Was NICHT gebraucht wird

Explizit **nicht** Teil dieser Integration — loomAIs Dashboard/Sandbox/Multi-Agent-
Maschinerie ist für einen `Ai.Provider` komplett irrelevant:

- Kein `/decision`-Flow, keine Human-in-the-Loop-Checkpoints — `ai.nvim` ist
  Single-Turn Ask/Stream (siehe `docs/scope.md` im `ai.nvim`-Repo), kein
  Agenten-Orchestrator.
- Keine Podman-Sandbox, kein Container-Lifecycle.
- Kein `EventBus`/`DecisionQueue` — `/events` (das bestehende SSE für das
  Dashboard) bleibt unangetastet, der neue Streaming-Endpoint (Aufgabe C) ist ein
  **separater** Pfad, keine Erweiterung von `/events`.
- Keine Frontend-/Dashboard-Änderungen.

Das deckt sich mit `ai.nvim`s eigenem `docs/scope.md`: *"Anything that needs
multi-step planning, a sandbox, or persistent agent state does not fit that
interface and is not meant to [...] the agent framework itself stays a separate
project with its own release cycle, not a mode of `ai.nvim`."*

---

## 11. Danach: der `loomai`-Provider in `ai.nvim` selbst

Sobald Aufgaben A-D umgesetzt sind, ist der `ai.nvim`-seitige Teil **klein** —
eine neue Datei, kein Umbau (das war von Anfang an die Absicht der Registry, siehe
`E:\repos\ai.nvim\lua\ai\providers\init.lua`s Modul-Doc):

- `lua/ai/providers/loomai.lua`, strukturell wie `ollama.lua` (kein API-Key,
  konfigurierbarer Host, NDJSON/SSE-Wahl je nach Aufgabe-C-Entscheidung).
- Eintrag in `providers/init.lua`s `BUILTIN`-Liste.
- **Nicht** automatisch in `DEFAULTS.lua`s `provider_order` — bleibt bewusst
  Opt-in (`config.provider_order = { "claude", "ollama", "openai", "loomai" }`
  explizit setzen), bis loomAI in der Praxis erprobt ist.
- Ein paar Tests analog zu `TESTS/ai/providers_spec.lua`.

Aufwand geschätzt vergleichbar mit `ollama.lua` (144 Zeilen) — der eigentliche
Aufwand dieser gesamten Integration liegt auf loomAI-Seite (Aufgaben A-C), nicht
bei `ai.nvim`.

---

## 12. Trigger — wann das hier aufgegriffen wird

Deckt sich mit dem bereits bestehenden Eintrag in
`wkdbook-myplugins/ai.nvim/ROADMAP/ROADMAP.md` und dem `ai.nvim`-Handover: sobald
loomAI **mindestens** Aufgabe B (Non-Streaming Ask) hat, kann Streaming (Aufgabe C)
als Zweitschritt folgen.

**Präzisierung, per Code geprüft (nicht wie zunächst angenommen):** `require("ai")
.stream()` (`ai/init.lua:150`, `return provider.stream(resolved, handlers)`) ruft
`provider.stream` **ungeguarded** auf — ein `loomai.lua`, das nur `ask()`
implementiert und `stream` weglässt, crasht mit "attempt to call a nil value",
sobald `:Ai stream`/`require("ai").stream()` mit `provider = "loomai"` aufgerufen
wird, statt sauber auf "kein Streaming, capabilities.streaming = false" zu
degradieren. `Ai.Provider`s eigene Typannotation markiert `stream` auch nicht als
optional (kein `?`). Zwei Möglichkeiten, falls Aufgabe C zeitlich später als
Aufgabe B kommt: entweder `loomai.lua` bekommt vorerst einen `stream()`, der intern
auf `ask()` zurückfällt (ein Chunk = die komplette Antwort, `on_chunk` einmalig,
dann `on_done`) — kein Extra-Endpoint nötig, nur ein paar Zeilen im Provider selbst
— oder `ai.nvim`s `M.stream()` bekommt zuerst denselben Guard wie
`providers/init.lua`s `M.resolve()` (siehe Code-Review vom 2026-09-14,
`ai.nvim`-Handover) und degradiert bei fehlendem `stream` auf einen Fehler statt
einem Crash. Beides ist unabhängig von loomAI lösbar; hier nur festgehalten, damit
es nicht als "geht schon irgendwie" missverstanden wird.

Bei jeder Wiederaufnahme dieses Projekts zuerst `E:\repos\loomAI\src\main.cpp` und
`docs/Guides/ki-agenten-framework-architektur.md` erneut gegenchecken, ob sich das
geändert hat.
