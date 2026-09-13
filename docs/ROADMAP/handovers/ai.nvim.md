# ai.nvim — Implementierungsplan & Handover

> Ausnahme-Standort: normalerweise leben Plugin-Roadmaps im Wkdbook
> (`wkdbook-myplugins/<plugin>/ROADMAP/ROADMAP.md`, siehe `NEW-14`). Diese
> Datei hier ist explizit angefordert als laufende Handover-Akte für die
> *Neuanlage* von `ai.nvim` und bleibt an diesem Ort
> (`nvim/docs/ROADMAP/handovers/`), nicht im Wkdbook.

## Regeln für diese Session

- Nie mehr als 1 Agent gleichzeitig; bei Bedarf mehrere Runden á 1 Agent, repo-für-repo.
- Antworten Deutsch, Quellcode (inkl. Kommentare) Englisch.
- Keine Co-Autorenschaft von Claude in Commits.
- Nach jedem fertigen Schritt: committen/pushen/pullen, main bleibt aktuell.
- `TOOL-PLACEMENT.md` / `HEREDOC.md` beachten, falls Nebenbei-Tooling entsteht.
- Code muss luacheck/stylua-grün sein (stylua v2.5.2, luacheck 1.2.0, siehe `ci-fleet-conventions`).
- Plugin-Installations-Specs: `vim.fn.stdpath('config')/lua/plugins/personal/init.lua`
  (+ Policy in `plugins/personal/source.lua`).

## Orte

| Was | Wo |
|---|---|
| Konzept (Quelle dieses Plans) | `nvim/docs/ROADMAP/IDEAS/ai.nvim.md` |
| Öffentliches Repo | `github.com/StefanBartl/ai.nvim` → `E:\repos\ai.nvim` |
| Privat (Roadmap/Notes, nicht fürs öffentliche Repo) | `E:\repos\WKDBooks\Development\wkdbook-myplugins\ai.nvim\{ROADMAP,NOTES}` |
| Diese Handover-Datei | `nvim/docs/ROADMAP/handovers/ai.nvim.md` |
| Transport-Erweiterung | `E:\repos\lib.nvim\lua\lib\nvim\net\curl` |
| loomAI (nativ, Referenz für späteren Provider) | `E:\repos\loomAI` |
| Regelwerk für neue Projekte | `E:\repos\WKDBooks\Development\wkdbook-Lua\Checklists\gates\NEW_PROJECT.md` (+ `PRINCIPLES.md`, `LUA_NVIM.md`) |

## Architektur (aus dem Konzept übernommen)

Zwei Schichten, wie bei `lsp.nvim`:

```
ai.nvim (eigenes Repo)
  Provider-Registry, Kontext-Assemblierung, Chat-/Antwort-UI, :Ai-Composer

lib.nvim.net.curl (Erweiterung, kein neues Modul)
  fetch_stream  — dritte Stufe neben fetch_json/fetch_raw (SSE + NDJSON, zeilenbasiert)
  secret_headers — Header, die nie im curl-argv landen (B2-Fix aus pdfport.nvim, generalisiert)
```

`ai.nvim` hat `lib.nvim` als **harte** Abhängigkeit (`LUA-01`, eigene
Entscheidung vom 26.07.). Genutzte lib.nvim-Bausteine, alle bereits vorhanden
und geprüft (siehe Recherche unten): `lib.nvim.net.curl` (+ Erweiterung),
`lib.nvim.harvest.scope`, `lib.nvim.progress`, `lib.nvim.ui.kit` (`surface`,
`popup{type="note"}`), `lib.nvim.usercmd.composer`, `lib.nvim.notify`,
`lib.nvim.safe_api`.

## Real geprüfter Ist-Stand der Bausteine (nicht aus dem Konzept übernommen, sondern nachgesehen)

- `lib.nvim.net.curl` hat heute `fetch_json`/`fetch_raw`/`download` (+ `_blocking`-Varianten),
  aber **kein** `fetch_stream`, **kein** `secret_headers` — Konzept-Annahme bestätigt, muss gebaut werden.
- `pdfport.nvim/lua/pdfport/backends/{init,claude}.lua` — Lazy-Proxy-Registry-Muster
  (`make_lazy_backend`) 1:1 als Vorlage für die Provider-Registry brauchbar; `claude.lua`
  zeigt den `-K`-Curl-Config-Datei-Fix (B2) im Detail, den `secret_headers` verallgemeinern soll.
- `lib.nvim.progress.create({title,...})` → Handle mit `update`/`finish`/`cancel`/`on_cancel`/`request_cancel`,
  Style `auto|notify|statusline|fidget|float`.
- `lib.nvim.ui.kit.surface.open({lines,theme,title,...})` → Handle mit `set_lines`/`set_title`/`focus`/`on_close`/`close`.
  `kit.popup({type="note",...})` für kurze Hinweise.
- `lib.nvim.harvest.scope.resolve("buffer"|"range"|"cwd"|"path", opts)` → `Lib.Harvest.Source[]`
  (`file`, `bufnr`, `lines`, `first`).
- `lib.nvim.usercmd.composer.verb(Name, { desc, default, routes = { {path,args,desc,run(ctx)} } })`
  — **aktueller** Pfad ist `lib.nvim.usercmd.composer` (nicht das ältere
  `lib.nvim.bindings.usercmd.composer`, das noch in `dap.nvim` verwendet wird — laut
  `LUA_NVIM.md`-Modultabelle ist `lib.nvim.usercmd.composer` die aktuelle Fundstelle).
- loomAI (`E:\repos\loomAI`, Stand 2026-08-08 laut Konzept, heute nochmal gegengeprüft):
  `src/main.cpp` ist ein `cpp-httplib`-Server mit **nur** `/events` (SSE) und `/decision`,
  spielt einen simulierten Agenten ab (`run_simulation_agent`, Kommentar: "wird später durch
  echten LLM-Agent ersetzt"). Kein `anthropic_client`, kein `model_router`, kein Ollama-Client
  im Code — nur in `docs/Guides/ki-agenten-framework-architektur.md` geplant (Wochen 3-4,
  ungeprüft/nicht garantiert). **Kein `/ask`-artiger Endpoint vorhanden.**

## loomAI: Entscheidung & Fallback (Kernpunkt der Aufgabenstellung)

**Gewählt (wie im Konzept): Option 2 — `ai.nvim` jetzt bauen, loomAI später als vierter Provider.**

- Der `Ai.Provider`-Vertrag (`id`, `available()`, `ask()`, `stream()`, `capabilities`) ist
  so geschnitten, dass ein `loomai`-Provider **nur** eine neue Registry-Datei ist
  (HTTP gegen `localhost:8080` statt direkt gegen Anthropic/OpenAI/Ollama) — kein Rewrite
  an Registry, Kontext-Assemblierung oder UI.
- **v1 von `ai.nvim` implementiert `loomai` NICHT** — es gibt heute keinen Endpoint,
  gegen den man testen könnte; Code gegen eine nicht-existente API ist spekulativ
  (verstößt gegen "Erst einfach, dann komplex", `PRINCIPLES.md`).
- **Fallback-Regel, hart verdrahtet:** `provider = "auto"` durchläuft NIE `loomai` —
  die Auto-Chain ist ausschließlich `{claude, ollama, openai}` (Reihenfolge konfigurierbar
  über `config.provider_order`), unabhängig davon, ob/wann `loomai` registriert wird.
  Ein fehlendes/nicht erreichbares `loomai` darf `ai.nvim` nie blockieren.
- **Trigger, um `loomai` nachzuziehen:** sobald `loomAI` einen `/ask`- oder gleichwertigen
  HTTP-Endpoint hat (Health-Check: `available()` macht einen kurzen `GET` gegen die
  konfigurierte loomAI-Basis-URL). Bei jeder Wiederaufnahme dieses Projekts zuerst
  `E:\repos\loomAI\src\main.cpp` / `docs/Guides/ki-agenten-framework-architektur.md`
  gegenchecken, ob sich das geändert hat (Stand hier: 2026-09-14, nichts vorhanden).
- Dieser Punkt steht auch in `wkdbook-myplugins/ai.nvim/ROADMAP/ROADMAP.md` als offener Posten.

## Phasenplan

### Phase 0 — Setup ✅ (diese Sitzung)
- [x] Konzept, `NEW_PROJECT.md`, `PRINCIPLES.md`, `LUA_NVIM.md` (Auszug), `lua-plugin-tools.md`,
      Muster (`pdfport.nvim/backends`, `lib.nvim/net/curl`, `harvest/scope`, `progress`,
      `ui/kit`, `dap.nvim`-Struktur als Scaffold-Vorlage) gelesen.
- [x] loomAI-Ist-Stand gegengeprüft (siehe oben).
- [x] Diese Handover-Datei angelegt.
- [ ] GH-Repo `stefanbartl/ai.nvim` (public) + lokal `E:\repos\ai.nvim`.
- [ ] `wkdbook-myplugins/ai.nvim/{ROADMAP/ROADMAP.md, NOTES/}` anlegen.

### Phase 1 — Transport-Erweiterung in `lib.nvim`
- `fetch_stream(url, opts, handlers)`: `vim.system` mit Zeilen-Callback (wie
  `lib.nvim.cross.uv.spawn_stream`, nur über HTTP), `handlers = {on_chunk, on_done, on_error}`.
  Muss SSE (`data: {...}`, Ende bei `data: [DONE]`/Verbindungsende) und NDJSON
  (eine JSON-Zeile pro Chunk) roh durchreichen — Parsing der Zeilenform ist Sache von
  `ai.nvim`, nicht von `lib.nvim` (Trennung "Bytes bekommen" vs. "Bytes verstehen").
- `opts.secret_headers`: intern über `-K`-Curl-Config-Tempdatei (wie
  `pdfport.nvim/backends/claude.lua`, `fs_chmod(0600)` best-effort), nie im argv.
  Gilt für `fetch_stream` UND rückwirkend für `fetch_json`/`fetch_raw` (ein Fix, keine
  Kopie — `LUA-02`).
- Tests unter `lib.nvim/TESTS/` (bestehendes Test-Setup nutzen).
- Commit + Push auf `lib.nvim` main.

### Phase 2 — `ai.nvim` Scaffold (`NEW_PROJECT.md`, `NEW-01`…`NEW-50`)
Struktur wie `dap.nvim`/`language.nvim`: `lua/ai/{config/{DEFAULTS,init},bindings/{keymaps,usercmds,autocmds},@types,health.lua,providers/,context/,ui/}`,
`plugin/ai.lua` (Guard), `TESTS/` + `scripts/test.sh`, `doc/ai.txt`, `docs/BINDINGS.md`,
`README.md` (Fassung-3-Template), `LICENSE` (MIT), `.luarc.json` (ohne `workspace.library`,
`workspace.ignoreDir`), `.luacheckrc` (busted-`std` für `TESTS/`), `stylua.toml`
(`line_endings = "Unix"`, passend zu `.gitattributes`), CI (`luacheck`+`stylua`+`plenary`,
Vorlage `dap.nvim/.github/workflows/ci.yml`). **Kein `docs/ROADMAP.md` im Repo** (`NEW-14`).
Modul-Namespace: `require("ai")` (kein Kollisionsrisiko mit installierten Plugins geprüft —
Konzept selbst legt `require("ai")` in der API-Skizze fest).

### Phase 3 — Provider-Registry (`lua/ai/providers/`)
Lazy-Proxy-Registry nach `pdfport.nvim/backends/init.lua`-Muster. `Ai.Provider`-Interface
laut Konzept (`id`, `available()`, `ask(req,cb)`, `stream(req,handlers)`, `capabilities`).
Eingebaut: `claude` (Anthropic Messages API, SSE), `ollama` (lokal, NDJSON), `openai`
(Chat Completions, SSE). `loomai` bewusst NICHT in v1 (s.o.). `M.register(provider)` für
eigene/künftige Provider von außen. Secrets nur aus `vim.env.*`, nie gespeichert
(`:Ai info` zeigt Status, nie den Wert — SEC-Regeln).

### Phase 4 — Kontext-Assemblierung (`lua/ai/context/`)
Dünner Wrapper um `lib.nvim.harvest.scope` (`buffer`/`selection`→`range`/`cwd`) +
eigene `diagnostics`-Funktion (`vim.diagnostic.get()` → nummerierte Liste mit Severity,
NICHT nach `lib.nvim` — zu AI-spezifisch). Baut daraus den Prompt-Kontext-Block.

### Phase 5 — UI (`lua/ai/ui/`)
`lib.nvim.progress` für "Denkt nach…" (Style konfigurierbar), `lib.nvim.ui.kit.surface`
für das Antwort-Panel (bleibt offen, `set_lines()` inkrementell bei jedem Stream-Chunk).
`progress.cancel()`/Panel-Schließen MUSS den laufenden curl-Prozess killen (offene Frage
aus dem Konzept — hier verbindlich lösen: `vim.system`-Handle im Stream-Handler halten,
`:kill()` bei Cancel/Panel-Close).

### Phase 6 — Public API + `:Ai`-Composer
`require("ai").ask(req, cb)` / `.stream(req, handlers)` (API-Skizze aus Konzept).
`:Ai ask [prompt?]`, `:Ai stream [prompt?]`, `:Ai provider <name>` (Completion aus
Registry, live), `:Ai info` — über `lib.nvim.usercmd.composer.verb("Ai", {...})`.

### Phase 7 — Quick-Actions ("neue Idee" im Konzept)
1. Hotkey/Usercmd: aktuellen Kontext (Buffer/Selection/Diagnostics/Quickfix — je nach
   Cursor-Kontext, z. B. in der QF-Liste → deren Einträge) sofort in einen Prompt geben,
   optional Modellwahl, `<CR>` schickt async, Antwort in eigenem Buffer/Panel.
2. Zweiter Keymap, andere Wirkung: kein Chat-Panel, sondern ein `noice`-artiges,
   umrandetes farbiges Badge (kleines "Post-it") oben/unten rechts, das die aktuelle
   Fehlermeldung/den Kontext knapp erklärt — nutzt `kit.popup({type="toast"|"note",...})`.

### Phase 8 — Wiring in nvim-config
`plugins/personal/source.lua` (`MODE["ai.nvim"] = "dir"`), `plugins/personal/init.lua`
(Lazy-Spec + `dependencies = {"StefanBartl/lib.nvim"}` + Keymaps für Phase 7).
Vor Vergabe der Keymap-Präfixe: bestehende `<leader>a*`-Belegung gegenprüfen (Kollision
mit `LUA-95`-Regel: spät geladene Plugins nicht versehentlich überschreiben).

### Phase 9 — Follow-up (entkoppelt von v1, NICHT blockierend)
- `pdfport.nvim`s `claude`/`ollama`-Backends auf `ai.nvim` migrieren — behebt B1/B2 dort
  tatsächlich (der ursprüngliche Auslöser des Konzepts). Eigener Task, nach `ai.nvim` v1.
- `loomai`-Provider, sobald loomAI einen Ask-Endpoint hat (s.o.).
- Offene Fragen aus dem Konzept, die hier noch nicht entschieden sind: Format von
  `context.diagnostics` (Rohtext vs. strukturiert) — vorerst strukturiert (Datei:Zeile:
  Severity:Message), da zuverlässiger parsbar; Modell-Registry pro Provider (validierte
  Liste vs. freier String) — vorerst frei, wie im Konzept vorgeschlagen.

### Phase 10 — `gates/RELEASE.md` vor einem ersten Tag/Release

## Nächste konkrete Schritte (Stand jetzt)

1. GH-Repo anlegen + klonen.
2. Wkdbook-Ordner anlegen.
3. Phase 1 (lib.nvim-Transport) umsetzen.
4. Phase 2 (Scaffold) umsetzen.
5. Phase 3-7 (Registry, Kontext, UI, API, Quick-Actions) umsetzen.
6. Phase 8 (Wiring) umsetzen.
7. Diese Datei laufend als Statusprotokoll fortschreiben.
