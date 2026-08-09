# `ai.nvim` — Konzept (AI-Provider-Schicht + Kontext + UI)

Angelegt 2026-08-08, ausgehend von einer konkreten Frage: was muss man heute
im Sourcecode tun, um in einem eigenen `*.nvim`-Plugin eine AI zu befragen und
die Antwort zu verwerten — und lohnt eine gemeinsame API dafür?

**Konkreter Anlass, kein Gedankenexperiment:** Beim Durchsehen von
`pdfport.nvim/lua/pdfport/backends/{claude,ollama}.lua` als einzigem
Plugin, das heute wirklich eine AI anspricht, fanden sich zwei echte Bugs,
die genau aus dem Fehlen einer gemeinsamen Schicht folgen — beide noch in
derselben Sitzung gefixt (`pdfport.nvim@d92436f`):

- **B1**: Handgebautes JSON-Escaping (`prompt:gsub('"', '\\"')`) escapt
  Anführungszeichen, aber keine Backslashes — jeder Windows-Pfad oder Regex
  im Prompt (`C:\repos\foo`, `\d+`) erzeugte ungültiges JSON, das die API
  ablehnte. In **beiden** Backends identisch kopiert.
- **B2**: Der Anthropic-API-Key stand als `-H "x-api-key: ..."` im curl-argv
  — für die Lebensdauer des Requests in der Prozesstabelle sichtbar
  (Process Explorer/WMI unter Windows, `ps` unter POSIX).

Beides ist kein Einzelfall, sondern das erwartbare Ergebnis, wenn jedes
Plugin seinen eigenen HTTP-Client für AI-Provider von Hand baut.

---

## Wichtigster Befund zuerst: `loomAI` existiert bereits

Bevor hier irgendetwas geplant wird, die gleiche Prüfung wie in
[typepilot.nvim.md](./typepilot.nvim.md): **`E:/repos/loomAI`** ist relevant
und ändert den Zuschnitt.

### Was `loomAI` ist

Kein Neovim-Plugin — ein eigenständiges **C++23-Multi-Agenten-Framework**
mit Podman-Sandbox, SQLite-State, Git-Snapshot/Rollback, HTML/SSE-Dashboard
und Human-in-the-Loop-Entscheidungspunkten. Architekturdokument:
`docs/Guides/ki-agenten-framework-architektur.md` (590 Zeilen, sehr
ausgearbeitet). Enthält bereits geplant:

- Einen **Model Router** (lokal `ollama`/`llama.cpp` mit VRAM-Budget vs.
  Cloud-Anthropic-Fallback nach Task-Typ)
- Einen **Anthropic-API-Client** (`anthropic_client.hpp/.cpp`, SSE-Streaming)
- Eine **Lua-Scripting-Schicht für Agenten-Verhalten** via `sol2`
  (`agents/*.lua`) — *"analog zu Neovim-Architektur!"* steht wörtlich im Doc

### Ist-Zustand (Stand 2026-08-08, geprüft)

Ein Commit, `src/main.cpp` ist 141 Zeilen: ein `cpp-httplib`-Server mit
`/events`-SSE-Endpoint und `/decision`-POST, der einen **simulierten**
Agenten abspielt (`run_simulation_agent()` — Kommentar im Code: *"wird später
durch echten LLM-Agent ersetzt"*). Kein Model Router, kein Anthropic-Client,
kein Ollama-Client existiert im Code — nur in der Architekturplanung.
`loomAI`s eigene Roadmap setzt Model-Integration auf Woche 3-4; danach ist
nichts committet. **`loomAI` ist heute nichts, wovon man abhängen kann.**

### Die Entscheidung

Zwei Optionen, kein Sowohl-als-auch:

1. **Auf `loomAI` warten** — `ai.nvim` erst bauen, wenn dessen HTTP/SSE-API
   steht, dann als dünner Client dagegen sprechen.
2. **`ai.nvim` jetzt bauen**, aber so entworfen, dass `loomAI` später als
   *ein weiterer Provider* in der Registry andockt (`provider = "loomai"`
   spricht dann HTTP gegen `localhost:8080` statt direkt gegen Anthropic),
   ohne Rewrite.

**Gewählt: Option 2.** Der Schmerzpunkt ist heute (`pdfport.nvim`), `loomAI`
ist Wochen bis Monate entfernt, und `documentation.nvim.md` hat bereits
denselben Präzedenzfall gesetzt — AI-generierte `@field`-Beschreibungen
wurden explizit *"in den Kontext von `loomAI`, nicht im Standardpfad"*
verschoben. Diese Config-Wide-Regel gilt genauso hier: **`ai.nvim` deckt
Frage-Antwort/Streaming für einzelne Plugin-Aufrufe ab. Alles, was nach
autonomem Multi-Step-Agent, Sandbox oder Tool-Use riecht, ist explizit
`loomAI`s Aufgabe, nicht `ai.nvim`s.** Diese Grenze steht schon in §Scope
unten.

Cross-Referenz eingetragen: `typepilot.nvim.md`s offene `loomAI`-Frage ist
für den *Provider-Abstraktions*-Teil hiermit beantwortet — siehe dort.

---

## Architektur: zwei Schichten, wie bei `lsp.nvim`

Dieselbe Trennung, die sich beim `lsp.nvim`-Konzept bewährt hat: Transport
in `lib.nvim` (protokollnah, stabil, von allen ~25 Plugins geteilt), Domäne
in einem eigenen Plugin (bewegt sich schnell, Modelle/Endpoints ändern sich
ständig — würde das in `lib.nvim` liegen, risse jede Modellumstellung die
Bibliothek an, die alle Plugins pinnen).

```
┌──────────────────────────────────────────────────────────────────┐
│ ai.nvim  (eigenes Repo)                                          │
│   Provider-Registry, Kontext-Assemblierung, Chat-/Antwort-UI,    │
│   Modell-Auswahl, `:Ai`-Composer-Command                         │
├──────────────────────────────────────────────────────────────────┤
│ lib.nvim.net.curl  (Erweiterung, kein neues Modul)               │
│   `fetch_stream` — dritte Stufe neben fetch_json/fetch_raw.      │
│   `secret_headers` — Header, die NIE ins argv dürfen.            │
└──────────────────────────────────────────────────────────────────┘
```

`ai.nvim` hängt hart von `lib.nvim` ab (deine eigene Entscheidung vom
26.07.: harte Abhängigkeiten sind by design, kein Nachbau von Grundbausteinen)
und **weich** von `lib.nvim.ui.kit`/`harvest`/`progress` — die sind schon da,
werden nur referenziert, nicht neu erfunden (s.u.).

---

## 1. Transport: `lib.nvim.net.curl` erweitern

### `fetch_stream` — die eigentliche Lücke

`lib.nvim.net.curl` hat heute zwei Stufen (`fetch_json`/`fetch_raw`, beide
async+blocking) — beide puffern die komplette Antwort und rufen **einen**
Callback am Ende. Für AI-Antworten ist das der falsche Modus: ein Prompt mit
mehreren Sekunden Antwortzeit fühlt sich ohne Streaming kaputt an, ganz
unabhängig von Korrektheit.

```lua
curl.fetch_stream(url, {
  method = "POST",
  headers = { ["Content-Type"] = "application/json" },
  secret_headers = { ["x-api-key"] = key },   -- siehe unten
  body = json_body,
}, {
  on_chunk = function(raw_line) end,   -- eine Zeile SSE/NDJSON, roh
  on_done  = function(obj) end,        -- vim.SystemCompleted
  on_error = function(err) end,
})
```

Baut auf `vim.system` mit `stdout` als Zeilen-Callback statt Buffer-Sammlung
— dieselbe Grundtechnik wie `lib.nvim.cross.uv.spawn_stream`, nur über HTTP.
Zwei Line-Formate, beide zeilenbasiert, beide bereits mit vorhandenen
Bausteinen zerlegbar:

- **SSE** (Anthropic, OpenAI): Zeilen `data: {...}`, Ende bei
  `data: [DONE]` oder Verbindungsende.
- **NDJSON** (Ollama): eine komplette JSON-Zeile pro Chunk, kein `data:`-Prefix.

`ai.nvim`s Provider-Schicht entscheidet, welches Format geparst wird — die
Transport-Schicht liefert nur rohe Zeilen, genau wie `spawn_stream` das
schon für Prozess-Output tut (Trennung von "Bytes bekommen" und
"Bytes verstehen").

### `secret_headers` — B2 in die Bibliothek heben

Der `-K`-Konfigdatei-Fix aus `pdfport.nvim@d92436f` (API-Key nicht im argv,
sondern in einer `fs_chmod(0600)`-Tempdatei über `curl -K`) ist kein
Anthropic-Spezifikum — **jeder** Provider (OpenAI Bearer-Token, Ollama
optionaler Remote-Key, `loomAI` selbst) hat exakt dasselbe Problem. Diesen
Fix einmal in `curl.lua` bauen (`opts.secret_headers`, intern über `-K`,
Tempdatei-Erzeugung/Löschung/Chmod dort gekapselt) heißt: **kein Backend,
das je danach geschrieben wird, kann diesen Fehler noch machen** — er ist
strukturell ausgeschlossen, nicht nur an einer Stelle behoben.

**Aufwand:** Mittel (Streaming-Parsing + Tests für beide Zeilenformate)
**Nutzen:** hoch — ohne das ist der Rest der Architektur graue Theorie.

---

## 2. Domäne: Provider-Registry

`pdfport.nvim/lua/pdfport/backends/init.lua` hat das Muster bereits fertig
und bewährt: Lazy-Proxies pro Provider (`available()`/`ask()`/`stream()`
laden das echte Modul erst beim ersten Zugriff), Custom-Provider von außen
registrierbar. Fast 1:1 übernehmbar, nur der Payload ändert sich von
"PDF → Text" zu "Prompt+Kontext → Antwort/Stream":

```lua
---@class AiNvim.Provider
---@field id string
---@field available fun(): boolean
---@field ask fun(req: AiNvim.Request, cb: fun(ok, res)): nil
---@field stream fun(req: AiNvim.Request, handlers: AiNvim.StreamHandlers): nil
---@field capabilities { vision?: boolean, streaming?: boolean, max_tokens?: integer }
```

Eingebaute Provider: `claude` (Anthropic Messages API), `openai`, `ollama`
(lokal). `loomai` **als vierter Eintrag, sobald dessen HTTP-API steht** —
architektonisch nur ein weiterer Provider, kein Sonderfall.

`pdfport.nvim`s zwei Backends (233 + 295 Zeilen) schrumpfen dadurch auf
Request-Bau + Response-Parsing, grob je ~40 Zeilen — der ganze
curl/JSON/Tempfile/Fehlerbehandlungs-Teil (heute ~70% jeder Datei) wandert
in `ai.nvim`/`lib.nvim`.

**Aufwand:** Klein (Registry-Grundgerüst, Muster liegt fertig vor)
**Nutzen:** hoch — macht Provider austauschbar ohne Call-Site-Änderung.

---

## 3. Kontext-Assemblierung — größtenteils schon da

Das ist der Teil, der den eigentlichen Nutzen bringt (Buffer/Selection/
Diagnostics → Prompt), und er lässt sich zu einem großen Teil auf
**`lib.nvim.harvest.scope`** aufsetzen statt neu gebaut zu werden:

```lua
context = {
  buffer     = true,   -- harvest.scope.resolve("buffer")
  selection  = true,   -- harvest.scope.resolve("range", {...})
  cwd        = false,  -- harvest.scope.resolve("cwd", { match = "%.lua$" })
}
```

`harvest.scope` liefert bereits `Lib.Harvest.Source[]` mit Datei/Bufnr/Zeilen
+ `first`-Zeilennummer für korrekte Zitate — genau das Shape, das ein Prompt-
Builder braucht. Was fehlt und **nicht** nach `lib.nvim` gehört (zu
AI-spezifisch für eine generische Sammel-Bibliothek): Diagnostics/Quickfix
als Kontext (`vim.diagnostic.get()`, als nummerierte Liste mit Severity
formatiert) — das bleibt eine dünne, ai.nvim-eigene Funktion, kein
`harvest`-Scope-Token.

**Aufwand:** Klein (dünner Wrapper um vorhandenes `harvest.scope`)
**Nutzen:** hoch — ohne Kontext ist es nur ein Chat-Fenster, kein
Editor-Feature.

---

## 4. UI — eigene UI, kein Nachbau

Zwei Bausteine existieren bereits vollständig in `lib.nvim` und werden nur
verdrahtet, nicht neu gebaut:

- **`lib.nvim.progress`** — "Denkt nach…"-Indikator während des Requests,
  4-Funktionen-Kontrakt (`start`/`update`/`finish`/`cancel`), Style
  `"kit"`/`"float"`/`"fidget"`/`"notify"` frei wählbar wie bei
  `replacer.nvim`. Für Streaming: `update()` bei jedem Chunk mit
  Fortschritts-Text (Tokenanzahl o.ä.), `cancel` → bricht den `vim.system`-
  Job der laufenden Anfrage ab (curl-Prozess killen, nicht nur UI schließen).
- **`lib.nvim.ui.kit`** — für ein Antwort-Panel reicht `kit.surface` direkt
  (themter Float, volle Kontrolle über Lifecycle) statt der kanonischen
  `viewer`-Komponente, die bei Fokusverlust automatisch schließt — für ein
  Chat-Panel, das offen bleiben soll während man woanders tippt, ungeeignet.
  Response-Text während des Streams per `surf:set_lines()` inkrementell
  nachziehen.

**Aufwand:** Mittel (Panel-Lifecycle, Streaming-Redraw ohne Flackern)
**Nutzen:** hoch — war explizit gewünscht (kein "nur Text zurückgeben, jedes
Plugin rendert selbst").

---

## API-Skizze

```lua
local ai = require("ai")

ai.ask({
  prompt   = "Warum schlägt dieser Test fehl?",
  system   = "Du bist Senior-Developer.",
  context  = { buffer = 0, selection = true, diagnostics = true },
  provider = "auto",   -- "claude" | "ollama" | "openai" | "loomai" | "auto"
}, function(ok, res)
  -- res.text, res.usage, res.stop_reason
end)

ai.stream({
  prompt = "...", context = { selection = true },
}, {
  on_chunk = function(delta) end,
  on_done  = function(res) end,
  on_error = function(err) end,
})
```

Usercmd (Composer-Pattern, analog `:Lib`/`:Dap`):

```
:Ai ask [prompt?]          -- Prompt-Eingabe (lib.nvim.ui.kit.input) falls leer
:Ai stream [prompt?]       -- wie ask, aber Panel öffnet sofort und füllt sich live
:Ai provider <name>        -- aktiven Provider wechseln
:Ai info                   -- aktiver Provider, Key-Status (NIE der Key selbst), Verfügbarkeit
```

---

## Secrets — dieselbe Regel wie in `typepilot.nvim.md`

> Keine zentrale Key-Verwaltung, keine Speicherung von Keys durch das Plugin.
> Key kommt aus der Umgebung, bleibt lokal.

Gilt hier genauso, plus die konkrete Lehre aus B2: **kein Secret darf je in
einem Prozess-argv landen** — durchgesetzt strukturell über
`curl.secret_headers` (s.o.), nicht per Konvention/Reviewer-Aufmerksamkeit.
`:Ai info` gibt Key-*Status* aus (vorhanden/fehlt), nie den Wert.

---

## Offene Fragen

- [ ] **Streaming-Cancel bei Panel-Schließen**: Wenn der User das Antwort-
      Panel während eines laufenden Streams schließt, muss der curl-Prozess
      mitsterben — sonst läuft eine verwaiste Anfrage im Hintergrund weiter
      (Kosten, offene Verbindung). `progress.cancel()` muss das garantieren,
      nicht nur die UI aufräumen.
- [ ] **`context.diagnostics`-Format**: Rohtext an die AI oder strukturiert
      (Datei:Zeile:Severity:Message als Tabelle)? Strukturiert ist teurer im
      Prompt-Budget, aber die AI parst es zuverlässiger.
- [ ] **Modell-Registry pro Provider**: `opts.model` heute frei-Text
      (`"claude-opus-4-5"`, `"llava"`, …) — soll es eine validierte Liste je
      Provider geben (Health-Check kann dann "Modell X kennt Provider Y
      nicht" melden) oder bleibt es absichtlich offen für neue Modelle ohne
      Plugin-Update?
- [ ] **Wann wird `loomai` als Provider ergänzt**: sobald dessen `/ask`- oder
      äquivalenter HTTP-Endpoint existiert (heute nur `/events` + `/decision`
      für die Dashboard-Simulation) — kein Blocker für den Rest, aber im
      Hinterkopf behalten, damit die Provider-Schnittstelle nicht versehentlich
      etwas annimmt, das ein HTTP-Provider nicht liefern kann (z. B. lokale
      Dateisystem-Zugriffe im Request).

**Gesamtaufwand:** Mittel-Groß (Transport-Erweiterung + Registry + Kontext +
UI, aber jeder Teil einzeln klein und an Bestehendem verankert)
**Gesamtnutzen:** hoch — behebt zwei aktive Bugs sofort (via Migration von
`pdfport.nvim`), macht jedes künftige AI-Feature in jedem `*.nvim`-Plugin zu
einem `require("ai")`-Aufruf statt einer Neuimplementierung.
