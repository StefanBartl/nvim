# ai.nvim — Implementierungsplan & Handover

> Ausnahme-Standort: normalerweise leben Plugin-Roadmaps im Wkdbook
> (`wkdbook-myplugins/<plugin>/ROADMAP/ROADMAP.md`, siehe `NEW-14`). Diese
> Datei hier ist explizit angefordert als laufende Handover-Akte für die
> *Neuanlage* von `ai.nvim` und bleibt an diesem Ort
> (`nvim/docs/ROADMAP/handovers/`), nicht im Wkdbook.

## Table of content

  - [Feedback](#feedback)
  - [Regeln für diese Session](#regeln-fr-diese-session)
  - [Orte](#orte)
  - [Architektur (aus dem Konzept übernommen)](#architektur-aus-dem-konzept-bernommen)
  - [Real geprüfter Ist-Stand der Bausteine (nicht aus dem Konzept übernommen, sondern nachgesehen)](#real-geprfter-ist-stand-der-bausteine-nicht-aus-dem-konzept-bernommen-sondern-nachgesehen)
  - [loomAI: Entscheidung & Fallback (Kernpunkt der Aufgabenstellung)](#loomai-entscheidung-fallback-kernpunkt-der-aufgabenstellung)
  - [Phasenplan](#phasenplan)
    - [Phase 0 — Setup ✅](#phase-0-setup)
    - [Phase 1 — Transport-Erweiterung in `lib.nvim` ✅](#phase-1-transport-erweiterung-in-libnvim)
    - [Phase 2 — `ai.nvim` Scaffold ✅](#phase-2-ainvim-scaffold)
    - [Phase 3 — Provider-Registry (`lua/ai/providers/`) ✅](#phase-3-provider-registry-luaaiproviders)
    - [Phase 4 — Kontext-Assemblierung (`lua/ai/context/`) ✅](#phase-4-kontext-assemblierung-luaaicontext)
    - [Phase 5 — UI (`lua/ai/ui/`) ✅](#phase-5-ui-luaaiui)
    - [Phase 6 — Public API + `:Ai`-Composer ✅](#phase-6-public-api-ai-composer)
    - [Phase 7 — Quick-Actions ✅](#phase-7-quick-actions)
    - [Phase 8 — Wiring in nvim-config ✅](#phase-8-wiring-in-nvim-config)
    - [Phase 9 — Follow-up (entkoppelt von v1, NICHT blockierend)](#phase-9-follow-up-entkoppelt-von-v1-nicht-blockierend)
    - [Phase 10 — `gates/RELEASE.md` vor einem ersten Tag/Release](#phase-10-gatesreleasemd-vor-einem-ersten-tagrelease)
  - [Code-Review + Fixes (2026-09-14, nach Phase 8)](#code-review-fixes-2026-09-14-nach-phase-8)
  - [loomai-Provider umgesetzt (2026-09-14, Folgesession)](#loomai-provider-umgesetzt-2026-09-14-folgesession)
  - [loomAI: ModelRouter für klassische Provider (OpenAI/Anthropic/Open Source) — Scoping (2026-09-14)](#loomai-modelrouter-fr-klassische-provider-openaianthropicopen-source-scoping-2026-09-14)
    - [Ist-Stand (verifiziert, 2026-09-14, Code direkt gelesen, nicht angenommen)](#ist-stand-verifiziert-2026-09-14-code-direkt-gelesen-nicht-angenommen)
    - [Was konkret zu bauen ist](#was-konkret-zu-bauen-ist)
    - [Offene Fragen für die Fortsetzungs-Session](#offene-fragen-fr-die-fortsetzungs-session)
  - [Design-Entscheidungen, Gemini, rules.nvim, Live-Testing-Plan (2026-09-14, Folgesession 4)](#design-entscheidungen-gemini-rulesnvim-live-testing-plan-2026-09-14-folgesession-4)
  - [Teil A umgesetzt: loomAI-ModelRouter (2026-09-14, Folgesession 5)](#teil-a-umgesetzt-loomai-modelrouter-2026-09-14-folgesession-5)
  - [Teil B umgesetzt: loomAI-Dashboard Ask/Chat-Testpanel (2026-09-14, Folgesession 6)](#teil-b-umgesetzt-loomai-dashboard-askchat-testpanel-2026-09-14-folgesession-6)
  - [Gemini-Sicherheits-/Korrektheitsfixes (2026-09-14, Folgesession 7)](#gemini-sicherheits-korrektheitsfixes-2026-09-14-folgesession-7)
  - [loomai-ai-nvim-integration.md verifiziert & archiviert (2026-09-14, Folgesession 8)](#loomai-ai-nvim-integrationmd-verifiziert--archiviert-2026-09-14-folgesession-8)
  - [Nächste konkrete Schritte (Stand jetzt, 2026-09-14)](#nchste-konkrete-schritte-stand-jetzt-2026-09-14)
  - [loomAI-Doku-Housekeeping (2026-09-14, Folgesession 9)](#loomai-doku-housekeeping-2026-09-14-folgesession-9)
  - [typepilot.nvim: Scoping-Entscheidung (2026-09-14, Folgesession 10)](#typepilotnvim-scoping-entscheidung-2026-09-14-folgesession-10)

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
| Konzept (Quelle dieses Plans) | `nvim/docs/ROADMAP/IDEAS/ai.nvim.md` |
| Öffentliches Repo | `github.com/StefanBartl/ai.nvim` → `E:\repos\ai.nvim` |
| Privat (Roadmap/Notes, nicht fürs öffentliche Repo) | `E:\repos\WKDBooks\Development\wkdbook-myplugins\ai.nvim\{ROADMAP,NOTES}` |
| Diese Handover-Datei | `nvim/docs/ROADMAP/handovers/ai.nvim.md` |
| Transport-Erweiterung | `E:\repos\lib.nvim\lua\lib\nvim\net\curl` |
| loomAI (nativ, Referenz für späteren Provider) | `E:\repos\loomAI` |
| Regelwerk für neue Projekte | `E:\repos\WKDBooks\Development\wkdbook-Lua\Checklists\gates\NEW_PROJECT.md` (+ `PRINCIPLES.md`, `LUA_NVIM.md`) |
| report was loom ai braucht für ai.nvim (erledigt, archiviert 2026-09-14) | `docs/ROADMAP/personal/All/FINISH/ERLEDIGT/Handover_ERLEDIGT/loomai-ai-nvim-integration.md` |

---

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

---

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
  **Update (2026-09-14, Folgesession): überholt — `/health`+`/ask`+`/ask/stream` jetzt
  vorhanden, siehe [loomai-Provider umgesetzt](#loomai-provider-umgesetzt-2026-09-14-folgesession).**

---

## loomAI: Entscheidung & Fallback (Kernpunkt der Aufgabenstellung)

**Gewählt (wie im Konzept): Option 2 — `ai.nvim` jetzt bauen, loomAI später als vierter Provider.**

**Detaillierte Aufgabenliste für loomAI selbst (was dort konkret fehlt, Endpoint für
Endpoint, Feld für Feld):** [loomai-ai-nvim-integration.md](../../personal/All/FINISH/ERLEDIGT/Handover_ERLEDIGT/loomai-ai-nvim-integration.md)
(2026-09-14, **erledigt und archiviert 2026-09-14** — alle Aufgaben A-F verifiziert
umgesetzt, s. u. "loomai-Provider umgesetzt"). Enthielt auch eine bisher unentdeckte
Design-Frage (`available()`s "muss synchron sein"-Vertrag vs. der hier unten genannte
Netzwerk-Health-Check — echter Widerspruch, siehe Abschnitt 9 dort) und einen echten
Crash-Pfad, falls `stream()` fehlt (`ai/init.lua:150`, ungeguarded) — beides
gegenstandslos, da `loomai.lua` von Anfang an sowohl `available()` (Option a) als
auch `stream()` mitgebaut hat.

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

**Update (2026-09-14, Folgesession): Trigger eingetreten, Entscheidung umgesetzt.**
loomAI hat jetzt `/ask`+`/ask/stream`, `loomai` ist gebaut **und** (auf Anfrage,
über die ursprüngliche Entscheidung hier hinausgehend) in `provider_order`
aufgenommen — die Fallback-Regel "auto durchläuft NIE loomai" gilt damit
**nicht mehr** in dieser Absolutheit. Details:
[loomai-Provider umgesetzt](#loomai-provider-umgesetzt-2026-09-14-folgesession).

---

## Phasenplan

### Phase 0 — Setup ✅
- [x] Konzept, `NEW_PROJECT.md`, `PRINCIPLES.md`, `LUA_NVIM.md` (Auszug), `lua-plugin-tools.md`,
      Muster (`pdfport.nvim/backends`, `lib.nvim/net/curl`, `harvest/scope`, `progress`,
      `ui/kit`, `dap.nvim`-Struktur als Scaffold-Vorlage) gelesen.
- [x] loomAI-Ist-Stand gegengeprüft (siehe oben).
- [x] Diese Handover-Datei angelegt.
- [x] GH-Repo `StefanBartl/ai.nvim` (public) + lokal `E:\repos\ai.nvim` — Remote gesetzt,
      main gepusht (siehe Phase 2).
- [x] `wkdbook-myplugins/ai.nvim/{ROADMAP/ROADMAP.md, NOTES/}` angelegt.

---

### Phase 1 — Transport-Erweiterung in `lib.nvim` ✅
- `fetch_stream`/`secret_headers` implementiert in `lib.nvim/lua/lib/nvim/net/curl/init.lua`,
  committet (`5364c02 feat(net.curl): add fetch_stream and secret_headers`) und bereits
  auf `lib.nvim` `origin/main` gepusht (geprüft 2026-09-14: `main` und `origin/main` deckungsgleich).
- `secret_headers` gilt für `fetch_stream`, `fetch_json` und `fetch_raw` gemeinsam (ein Fix,
  keine Kopie, wie gefordert).
- Enthält einen `-N`/`--no-buffer`-Fix: curl puffert stdout sonst komplett bis Prozessende,
  was Streaming unbrauchbar gemacht hätte (Zeilen kämen alle auf einmal an statt inkrementell).
- Getestet in `lib.nvim/TESTS/curl_spec.lua` gegen einen echten `vim.uv`-TCP-Server (kein
  Mock): Zeilen-für-Zeile-Delivery inkl. Leerzeilen, `secret_headers` erreicht die Leitung,
  `process:kill()` bricht einen laufenden Stream wirklich ab. Suite grün.

---

### Phase 2 — `ai.nvim` Scaffold ✅
Struktur wie geplant vollständig vorhanden: `lua/ai/{config/{DEFAULTS,init},bindings/{keymaps,usercmds,autocmds,actions},@types,health.lua,providers/,context/,ui/}`,
`plugin/ai.lua` (Guard), `TESTS/ai/*_spec.lua` + `scripts/test.sh`, `docs/*.md`,
`README.md`, `LICENSE` (MIT), `.luarc.json`, `.luacheckrc`, `stylua.toml`, `.gitattributes`,
CI (`.github/workflows/ci.yml`: luacheck + stylua + plenary gegen `lib.nvim`+`plenary.nvim`-Checkouts).
Kein `docs/ROADMAP.md` im Repo (`NEW-14` eingehalten, Roadmap lebt in `wkdbook-myplugins`).
Modul-Namespace `require("ai")` wie geplant.

**2026-09-14 committet & gepusht** (in einer vorherigen Sitzung bereits geschrieben, aber
nie eingecheckt gewesen — diese Sitzung hat den Ist-Stand geprüft und verifiziert, dann
committet):
- `b77d014 feat: initial ai.nvim implementation (Phases 1-7)` — 40 Dateien, kompletter
  Scaffold + Phasen 3-7 (siehe unten).
- `f2ebe38 fix: mark scripts/test.sh executable` — CI schlug im ersten Lauf mit Exit 126
  fehl, weil Windows das x-Bit nicht mitschreibt; `git update-index --chmod=+x` behoben.
- **CI grün** (luacheck, stylua --check, plenary-Suite) nach dem Fix, verifiziert per
  `gh run view` gegen `origin/main`.
- Vor dem Commit verifiziert: `luacheck lua TESTS plugin` → 0 Warnings/Errors (22 Dateien),
  `stylua --check` → clean, `scripts/test.sh` lokal (mit `LIB_NVIM_DIR`=`E:\repos\lib.nvim`,
  `PLENARY_DIR`=`...\nvim-data\lazy\plenary.nvim`) → 19/19 Tests grün, Secret-Scan über alle
  Dateien negativ.

**`doc/ai.txt` (Vimdoc, `NEW-13`) nachgetragen** (`b2608f0`, 2026-09-14): CONTENTS-Sektionen
gespiegelt aus `docs/*.md`, Stil wie `pdfport.nvim`/`dap.nvim`. `helptags doc` lokal
generiert und geprüft (`:help ai`, `:help ai.ask()`, `:help :Ai-stream`, `:help ai-scope`,
`:help ai-providers` — alle lösen auf). `.gitignore` neu (`doc/tags`, generiert, nicht
Source). CI grün.

---

### Phase 3 — Provider-Registry (`lua/ai/providers/`) ✅
Lazy-Proxy-Registry nach `pdfport.nvim/backends/init.lua`-Muster, implementiert und getestet
(`TESTS/ai/providers_spec.lua`, 10 Tests grün): `claude.lua`, `ollama.lua`, `openai.lua`,
`init.lua` (Registry + `resolve()` mit fester `auto`-Chain). `loomai` bewusst NICHT enthalten
(s.o., Trigger-Bedingung unverändert offen).

**Echter Bug gefunden + gefixt** (End-to-End gegen die lebende OpenAI-API getestet, mit
einem ungültigen Testschlüssel — reicht, um den Fehlerpfad auszulösen): eine
Auth-Fehlerantwort auf einen Streaming-Request kommt NICHT als SSE-Event zurück, sondern
als mehrzeiliges, pretty-printed JSON — curl selbst beendet sich trotzdem mit Code 0. Naive
`data:`-Zeilenerkennung hätte das still verschluckt (leerer „Erfolg" statt Fehler) — genau
die Fehlerklasse, die dieses Projekt beheben soll. Fix in `claude.lua` + `openai.lua`:
Nicht-`data:`-Zeilen werden gesammelt und erst am Streamende als ein JSON-Block geparst
(siehe `non_data_lines` in beiden Dateien). Nach dem Fix mit echtem API-Call verifiziert:
`on_error` feuert korrekt, `on_done` nicht mehr fälschlich.

---

### Phase 4 — Kontext-Assemblierung (`lua/ai/context/`) ✅
`context/init.lua` (Wrapper um `lib.nvim.harvest.scope`) + `context/diagnostics.lua`
(strukturiert: `Datei:Zeile:[Severity]:Message`, sortiert). Getestet
(`TESTS/ai/context_spec.lua`, 6 Tests grün).

---

### Phase 5 — UI (`lua/ai/ui/`) ✅
`ui/panel.lua` (Streaming-Antwort-Panel über `lib.nvim.ui.kit.surface`) und `ui/badge.lua`
(kurzer Hinweis-Toast, kein Panel). Cancel/Panel-Close killt den laufenden Prozess
(`vim.SystemObj:kill()` gehalten im Stream-Handler) — verbindlich gelöst wie geplant.

---

### Phase 6 — Public API + `:Ai`-Composer ✅
`lua/ai/init.lua`: `require("ai").setup()/.ask(req,cb)/.stream(req,handlers)/.config()`.
`:Ai ask|stream|provider|info` über `lib.nvim.usercmd.composer` (`bindings/usercmds.lua`).
`resolve()` löst `req.provider` (oder Default) zu einem konkreten, verfügbaren Provider auf,
faltet Config-Defaults (Timeout, Provider-spezifisches Modell) und den Kontext-Block ein.

---

### Phase 7 — Quick-Actions ✅
`bindings/actions.lua` + `bindings/keymaps.lua`, Default-Prefix `<leader>a`:
1. `ask` (`<leader>aa`, n/v): Prompt-Eingabe, ggf. mit Selection-Kontext.
2. `quick` (`<leader>as`, n/v): getippte Aufgabe + Kontext sofort streamen (das "neue Idee"
   Quick-Action aus dem Konzept).
3. `explain` (`<leader>ae`, n/v): Badge/Toast statt Chat-Panel (zweite Keymap-Variante aus
   dem Konzept) — **erledigt**, nicht mehr im Backlog (Wkdbook-ROADMAP.md dort veraltet,
   bei nächster Gelegenheit dort den Backlog-Eintrag streichen).

Jede Action einzeln über `config.keymaps[id]` override-/disable-bar (Keymaps-als-Daten-Konvention).

---

### Phase 8 — Wiring in nvim-config ✅
**Kollision bestätigt, vom Nutzer entschieden:** `nvim/lua/config/ai/anthropic/init.lua`
konfiguriert Avante.nvim (ein bereits genutztes, von `ai.nvim` unabhängiges AI-Chat-Plugin)
mit `<leader>aa` (ask), `<leader>ae` (edit), `<leader>ar` (refresh), `<leader>af` (focus),
`<leader>as` (stop). `ai.nvim`s Default-Prefix `<leader>a` hätte auf `aa`/`ae`/`as`
kollidiert (siehe Phase 7). Entscheidung: **Option (b)** — Avante bleibt unangetastet auf
`<leader>a`, `ai.nvim` bekommt in der Lazy-Spec `opts.keymaps.prefix = "<leader>ai"`
(bindet also auf `<leader>aia`/`<leader>ais`/`<leader>aie`).

Umgesetzt in `plugins/personal/source.lua` (`["ai.nvim"] = "dir"`, Sektion 3) und
`plugins/personal/init.lua` (Lazy-Spec direkt nach dem `pdfport.nvim`-Block: `cmd = "Ai"`,
`keys` mirror `ai.bindings.keymaps` wie bei `dap.nvim`s `dap_prefix`/`dap_keys`-Muster,
`dependencies = {"StefanBartl/lib.nvim"}`, `opts.keymaps.prefix = ai_prefix`).

Verifiziert headless (`nvim --headless` gegen die echte Config): `require("ai")` lädt ohne
Fehler über `Lazy load ai.nvim`, `:Ai info` und `:checkhealth ai` laufen ohne Fehler,
`<leader>aia`/`<leader>ais`/`<leader>aie` sind gebunden — keine Kollision mit Avante.

`gates/REVIEW.md`-Schnell-Check nachträglich gegen die kritischen (🔴) Zeilen laufen
lassen (stichprobenartig: `providers/claude.lua`, `ui/panel.lua`, `health.lua`, plus
`grep` über `lua/` auf `os.execute`/`vim.fn.system`/`io.popen`/`_G.`): keine Treffer,
Secrets nie geloggt (nur Presence-Check via `vim.env.*`), `health.lua` nutzt `.info` statt
`.warn` für „Provider nicht verfügbar" (matcht `UI-57`). Keine Abweichungen gefunden, kein
Detail-Abschnitt nötig.

---

### Phase 9 — Follow-up (entkoppelt von v1, NICHT blockierend)
- `pdfport.nvim`s `claude`/`ollama`-Backends auf `ai.nvim` migrieren — behebt B1/B2 dort
  tatsächlich (der ursprüngliche Auslöser des Konzepts). Eigener Task, nach `ai.nvim` v1.
- `loomai`-Provider, sobald loomAI einen Ask-Endpoint hat (s.o.).
- Offene Fragen aus dem Konzept, die hier noch nicht entschieden sind: Format von
  `context.diagnostics` (Rohtext vs. strukturiert) — vorerst strukturiert (Datei:Zeile:
  Severity:Message), da zuverlässiger parsbar; Modell-Registry pro Provider (validierte
  Liste vs. freier String) — vorerst frei, wie im Konzept vorgeschlagen.

---

### Phase 10 — `gates/RELEASE.md` vor einem ersten Tag/Release
Absichtlich noch nicht formal abgeschlossen — der Plan verlangt echten Alltagsgebrauch vor
dem Tag, das lässt sich nicht durch eine einzelne Sitzung ersetzen. Die automatisch prüfbaren
`REL-*`-Punkte aber bereits vorab durchlaufen (2026-09-14, alles grün, keine Änderung nötig):

- REL-01/05/06/07/16/28 (README/`doc/ai.txt`/`docs/BINDINGS.md`/kein `docs/ROADMAP.md`/
  `health.lua`/`LICENSE` vorhanden) — alle ✅.
- REL-13 (kein `dir = vim.env...` im README) — ✅.
- REL-29 (`git status --porcelain` leer) — ✅.
- REL-35 (kein `wkdbook`/`WKDBooks`-Verweis im Repo) — ✅.
- REL-25/26/27 (GitHub-Metadaten: Description, Topics, Default-Branch `main`) — bereits in
  einer früheren Sitzung gesetzt, per `gh repo view` verifiziert, nichts geändert.

**Noch offen, judgment-basiert (kein automatischer Check möglich):**
- REL-03 (Table of Content) — README hat nur 2 H2-Sections (`## Documentation`,
  `## License`); die „Documentation"-Sektion fungiert bereits als Index in `docs/*.md`,
  eine separate TOC wäre bei der Kürze redundant. `recommended`, nicht kritisch — bewusst
  so gelassen, nicht vergessen.
- REL-08 (README-Beispiele laufen tatsächlich) — die Lazy-Spec + `setup()` sind diese
  Sitzung bereits end-to-end gegen die echte nvim-config verifiziert (Phase 8); die übrigen
  Codeblöcke in `docs/*.md` sind zum Teil bewusst illustrativ (z. B. `register()`-Beispiel
  mit `...`-Stub), kein vollständiger Durchlauf jedes einzelnen Snippets.
- REL-19 (Windows UND POSIX getestet) — CI läuft nur auf `ubuntu-latest`; manuell nur unter
  Windows getestet. POSIX-Seite bislang nur durch CI abgedeckt, kein echtes manuelles
  Durchklicken.
- REL-09/33 (Demo-GIF/Logo) — `nice-to-have`, nicht begonnen.
- REL-32 (Literatur und Referenzen) — `nice-to-have`, nicht begonnen.

---

## Code-Review + Fixes (2026-09-14, nach Phase 8)

Multi-Winkel-Review (`/code-review high`) über die gesamte `ai.nvim`-Implementierung
+ `lib.nvim`s `net.curl`-Erweiterung, 10 Findings, 9 gefixt:

- **`providers/init.lua`**: `M.resolve()` rief `p.available()` ungeguarded auf — ein
  Lazy-Proxy mit fehlgeschlagenem `require()` liefert `nil` für jedes Feld, das hätte
  bei jedem `ask()`/`stream()`-Call crashen können. Guard ergänzt (`b34f5cc`, s.u.).
- **`lib.nvim` `config_quote()`**: escapte `\n`/`\r`/`\t`/`\v` nicht, obwohl der eigene
  Docstring eine Ablehnung solcher Werte behauptete — ein API-Key mit trailing Newline
  (z. B. `export KEY=$(cat key.txt)`) hätte die `-K`-Curl-Config aufgebrochen. Jetzt
  escaped, matching curl's eigene Unescape-Regeln.
- **`init.lua`**: `autocmds`-Setup-`pcall` verschluckte Fehler lautlos (anders als die
  zwei `pcall`s direkt darüber) — der `VimLeavePre`-Handler hätte lautlos fehlen können.
- **`lib.nvim`**: `secret_headers` dedupliziert jetzt gegen `opts.headers` (gleicher
  Header-Name hätte sonst doppelt gesendet werden können — einmal sicher, einmal
  Klartext-argv). `fetch_stream`s Docstring dokumentiert jetzt explizit, dass `on_done`
  `obj.code` nicht selbst prüft (anders als `fetch_json`/`fetch_raw`).
- **Dedupliziert**: `ai.providers.sse` (neu) für die SSE-`data:`-Zeilen-Erkennung +
  Fehlerkörper-Recovery, vorher in `claude.lua`+`openai.lua` fast identisch dupliziert.
  `ai.providers.util` (neu) für `env_value()`/`curl_exit_error()`, vorher in allen drei
  Providern dupliziert. `context/init.lua`s dreifach wiederholter
  `scope.resolve`+Append-Block zu einem `add_scope()`-Helper zusammengefasst.
- **Nicht gefixt (bewusst)**: `ui/panel.lua`s `M.append` macht pro Stream-Chunk ein
  volles `set_lines()` statt inkrementell anzuhängen — echter Mechanismus, aber ohne
  Beleg, dass das bei realistischen Antwortlängen tatsächlich ein Problem ist, und
  `lib.nvim.ui.kit.surface` hat aktuell keine günstigere Append-API. Follow-up, falls es
  in der Praxis auffällt.
- **Nebenbefund**: `lib.nvim/TESTS/curl_spec.lua`s Kill-Prozess-Test war seit dem
  `fetch_stream`-Commit (`5364c02`) auf CI (Linux) durchgehend rot, lokal (Windows) aber
  immer grün — Ursache: ein signal-terminierter Prozess muss keinen non-zero `code`
  melden (Linux: `code=0, signal=15`; Windows: `code=1, signal=15`, verifiziert). Assertion
  auf `code ~= 0 or signal ~= 0` korrigiert.

Committet + gepusht: `lib.nvim` (`debed20`, `5828428`), `ai.nvim` (`b34f5cc`).

**Nachtrag (gleicher Tag):** `lib.nvim`s `luacheck`/`stylua`-CI-Jobs waren unabhängig
von diesem Review auf jedem der letzten 5+ Pushes rot (nachweislich schon vor dieser
Session, nicht durch `ai.nvim`-Arbeit verursacht) — auf Nachfrage mit erledigt:
- `luacheck`: `telemetry/init.lua`s `add_target()` shadowte `M.new()`s `opts`-Upvalue
  — umbenannt zu `wrap_opts` (matcht seinen tatsächlichen Typ/jede andere Referenz).
- `stylua`: `telemetry/registry.lua` + `usercmd/composer/check.lua` neu formatiert,
  reine Formatierung, keine Logikänderung (per Diff verifiziert).
- Lokaler `stylua --check .` über das ganze Repo zeigte danach noch weitere Dateien
  (z. B. `cross/open_default/init.lua`) als komplett umgeschrieben — verifiziert als
  reines Windows-Working-Tree-Artefakt (physisches CRLF trotz `eol=lf` in
  `.gitattributes`, `git ls-files --eol` zeigt `i/lf w/crlf`), kein echtes
  Formatierungsproblem; ein frischer Linux-Checkout (wie auf CI) reproduziert das
  nicht. Unangetastet gelassen.
- Committet + gepusht: `750d5e4`. **`lib.nvim`-CI jetzt komplett grün**, inkl.
  `publish-ci-verified`-Branch (läuft nur, wenn alle drei Jobs grün sind).

Test-Stand danach: `ai.nvim` 21/21 (2 neue Regressions-Tests für den `resolve()`-Guard),
`lib.nvim` volle Suite grün (`LIB_TESTS_OK`), inkl. 2 neuer Tests für
`config_quote`-Newline und `secret_headers`/`opts.headers`-Dedup.

---

## loomai-Provider umgesetzt (2026-09-14, Folgesession)

Der in [Phase 9](#phase-9-follow-up-entkoppelt-von-v1-nicht-blockierend) genannte
Trigger ist eingetreten: loomAI hat jetzt `/ask`+`/ask/stream`. In derselben
Sitzung beide Seiten umgesetzt, ausgehend vom detaillierten Report
[loomai-ai-nvim-integration.md](../../personal/All/FINISH/ERLEDIGT/Handover_ERLEDIGT/loomai-ai-nvim-integration.md)
(erledigt, archiviert 2026-09-14).

**loomAI-seitig** (`E:\repos\loomAI`, `src/main.cpp`, `src/ollama_client.hpp/.cpp`):
Aufgabe A-D aus dem Report umgesetzt — `GET /health`, `POST /ask`, `POST
/ask/stream` (SSE, Backend: direkter Ollama-Aufruf, kein `ModelRouter`, `model`
frei/unvalidiert wie in Aufgabe E Option 1 empfohlen), einheitliches
Fehlerformat (Aufgabe D). Server bindet jetzt `127.0.0.1` statt `0.0.0.0`
(Aufgabe F). Kein CMake-Build existierte vorher (Code war nicht kompilierbar)
— neu angelegt: `CMakeLists.txt` + vendorte `third_party/httplib.h` +
`nlohmann/json.hpp`, `README.md` neu. Committet: `91f7b28`.

**`ai.nvim`-seitig**: `lua/ai/providers/loomai.lua` nach dem `ollama.lua`-Muster
(`ask`/`stream`/`available()`). Design-Entscheidung aus Report-Abschnitt 9
getroffen: **Option (a)** — `available()` bleibt synchron
(`vim.fn.executable("curl")`), kein Netzwerk-Call gegen `/health`; ein
unerreichbares loomAI zeigt sich als normaler `ask`/`stream`-Fehler, exakt wie
bei `ollama.lua`. In `providers/init.lua`s `BUILTIN` registriert **und** (auf
Anfrage, Folge-Commit) in `DEFAULTS.lua`s `provider_order` — an letzter
Stelle, damit es nie einen bereits konfigurierten Cloud-/CLI-Provider
verschattet. **Konsequenz:** da `available()` keinen Netzwerk-Check macht,
landet `"auto"` auf einer Maschine ohne `ANTHROPIC_API_KEY`/`OPENAI_API_KEY`/
laufenden Ollama-Daemon jetzt bei `loomai`, selbst wenn dort kein Server läuft
— der Fehler zeigt sich dann als normaler Verbindungsfehler statt „kein
Provider verfügbar", akzeptierter Trade-off, gleiches Verhalten wie
`ollama.lua` bei installierter, aber nicht laufender Ollama-Binary.
Committet: `6931f7d` (Provider), `979db80` (provider_order).

**Review (medium-Effort, wegen „max 1 Agent"-Regel selbst statt über
Subagenten durchgeführt) + 2 Fixes:**
- 🔴 **Kritisch, gefixt**: `ollama_client.cpp`s Stream-Pfad warf eine
  ungefangene `nlohmann::json`-Exception, wenn Ollamas `error`-Feld mal kein
  String ist — der Chunked-Content-Provider-Callback läuft außerhalb von
  httplibs Routing-try/catch (verifiziert per Code-Lesen: `write_response_
  with_content` wird erst nach dem try/catch-Block aufgerufen, und
  `ThreadPool::worker` hat selbst keins), eine Exception dort killt den
  **kompletten Prozess** (`std::terminate` über den Worker-Thread). Live
  reproduziert gegen einen Python-Fake-Server mit `{"error":{"code":500}}`
  statt einem String — Prozess starb, `/health` antwortete danach nicht mehr.
  Fix: `error_text()`-Helper (stringifiziert statt zu werfen) + try/catch als
  zweite Verteidigungslinie um den ganzen Stream-Callback in `main.cpp`.
  Nach dem Fix denselben Angriff erneut gefahren: sauberes SSE-Fehler-Event,
  Prozess bleibt stabil.
- 🟡 `loomai.lua` erkannte Fehler nur bei exakt `type(data.error)=="table"` —
  jede andere Form wäre still als leere Erfolgsantwort durchgerutscht.
  Erweitert auf jedes nicht-`nil` `error`-Feld.
- 🟡 Nicht gefixt (bewusst): `ollama_client.cpp` öffnet pro Request eine neue
  TCP-Verbindung zu Ollama statt sie wiederzuverwenden — bräuchte ein
  durchdachtes Pooling-Design (z. B. thread-lokale Clients), nicht
  unangekündigt reingepatcht. Follow-up, siehe unten.
Committet: `4e2777c` (loomAI), `8d048ec` (ai.nvim).

**Nebenbefund, dritter Bug — nicht in dieser Sitzung gebaut, aber hier
gefunden und gefixt, weil er `:Ai ask` live blockierte:** `lib.nvim.net.curl`s
`fetch_json`/`fetch_raw`/`download` riefen ihren Callback direkt aus
`vim.system`s „fast event context" auf — sobald der Callback UI anfasst (z. B.
`vim.notify` bei einem Fehler in `actions.ask_prompt`), crasht das mit
`E5560: nvim_echo must not be called in a fast event context`. `fetch_stream`
hatte das schon korrekt gelöst (`vim.schedule()`), die drei anderen Tiers nie
— hätte **jeden** Provider getroffen (nicht nur `loomai`), nur nie zuvor live
über den echten `:Ai ask`-Pfad durchgetestet. Gefixt nach demselben Muster,
`curl_spec.lua` weiterhin grün. Committet in `lib.nvim`: `34a4584`. Die
**installierte** Plugin-Kopie (`nvim-data/lazy/lib.nvim`) war zusätzlich so alt,
dass ihr `fetch_stream` komplett fehlte — genau die Lücke, die
`health.lua`s eigener Check dafür vorgesehen hat — beim `git pull --ff-only`
auf den neuen Stand mitgezogen.

**Live verifiziert** (headless `nvim --headless` gegen die echte nvim-Config,
echter loomAI+Ollama-Prozess, nicht `--clean`): `:Ai provider loomai` →
`:Ai info` zeigt `loomai: available`, `provider_order: claude, ollama, openai,
loomai` → `:Ai ask "Reply with exactly the word: PONG"` öffnet den
Antwort-Popup mit der echten Ollama-Antwort. `:Ai stream` als Bonus ebenfalls
verifiziert (Panel füllt sich live, korrekter Endtext) — erst durch den
`lib.nvim`-Fix oben überhaupt in der installierten Plugin-Kopie nutzbar.

Alle vier Repos (`loomAI`, `ai.nvim`, `lib.nvim`, `nvim`-Config) committet und
auf `origin/main` gepusht. Keine Claude-Co-Autorenschaft in den Commits.

---

## loomAI: ModelRouter für klassische Provider (OpenAI/Anthropic/Open Source) — Scoping (2026-09-14)

**Reines Scoping, NICHT umgesetzt.** Aufgehängt an der Feedback-Notiz ganz oben
in dieser Datei: für **`ai.nvim` selbst** ist die Anforderung "klassische Tools
von OpenAI/Anthropic/Open Source unterstützen" bereits vollständig erledigt
(Phase 3: `providers/{claude,ollama,openai}.lua`, gebaut, getestet, auch live
gegen echte APIs — siehe Code-Review-Abschnitt oben). Offen ist das nur noch
auf der **loomAI-Server-Seite** (Punkt 6 unten) — der Server selbst kann
aktuell ausschließlich Ollama. Dieser Abschnitt hält den vollständigen
Rechercheergebnis- und Planungsstand fest, damit bei einer Sitzungsunterbrechung
(Nutzungslimit) nichts verloren geht.

---

### Ist-Stand (verifiziert, 2026-09-14, Code direkt gelesen, nicht angenommen)

- `E:\repos\loomAI\src\main.cpp`: `/ask`-Handler (ca. Zeile 161) und
  `/ask/stream`-Handler (ca. Zeile 198) rufen **hart** `loomai::ollama::ask()`
  (Zeile 176) bzw. `loomai::ollama::ask_stream()` (Zeile 231) auf — kein
  Router, kein Auswahlmechanismus, keine anderen Backend-Clients existieren
  im Code.
- `src/ollama_client.hpp/.cpp` ist das einzige Backend: direkter REST-Client
  gegen Ollamas `POST /api/generate`.
- Der äußere `try/catch` um den gesamten `/ask/stream`-Chunked-Content-Provider-
  Body in `main.cpp` (aus dem `4e2777c`-Crash-Fix, s.o.) fängt bereits jede
  Exception ab, unabhängig vom Backend dahinter — bleibt als Sicherheitsnetz
  bestehen, egal welches Backend künftig darunterhängt.
- Der HTTP-Vertrag ist bereits stabil und wird von `ai.nvim`s
  `lua/ai/providers/loomai.lua` konsumiert: Request `{prompt, system, model,
  timeout_ms}`, Response `{text, provider, stop_reason, usage}`, Fehler
  `{"error":{"message":...}}`. Jede Änderung hier muss entweder
  rückwärtskompatibel bleiben oder `ai.nvim` mit angepasst werden.

---

### Was konkret zu bauen ist

1. **Zwei neue Backend-Clients**, nach dem Muster von `ollama_client.hpp/cpp`:
   - `src/openai_client.hpp/.cpp` — `POST https://api.openai.com/v1/chat/completions`
     (Base-URL konfigurierbar, s. Punkt 2), Auth via
     `Authorization: Bearer $OPENAI_API_KEY`.
   - `src/anthropic_client.hpp/.cpp` — `POST https://api.anthropic.com/v1/messages`,
     Auth via `x-api-key: $ANTHROPIC_API_KEY` **plus** `anthropic-version`-Header
     — anderes Auth-Schema als OpenAI/Ollama, nicht denselben Header-Namen
     wiederverwenden.
   - **Gleiche Env-Var-Namen wie in `ai.nvim`s eigenen `providers/claude.lua`/
     `providers/openai.lua`** verwenden (`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`)
     — Konsistenz zwischen beiden Projekten, kein neues Namensschema erfinden.
2. **"Open Source"-Tools** heißt in der Praxis meist: selbstgehostete Server,
   die das OpenAI-Schema sprechen (vLLM, llama.cpp-Server, LM Studio,
   text-generation-webui). Deckt der `openai_client` mit konfigurierbarer
   Base-URL (Env-Var, analog zu `LOOMAI_OLLAMA_HOST`) automatisch mit ab —
   **kein eigener dritter Client**, außer ein konkretes Tool spricht ein
   eigenes, inkompatibles Schema (dann bei Bedarf einzeln nachziehen, nicht
   vorab spekulativ bauen — "erst einfach, dann komplex", `PRINCIPLES.md`).
3. **Bekannter Bug wird hier mit hoher Wahrscheinlichkeit wiederkehren**: das
   gleiche Problem, das in `ai.nvim`s `claude.lua`/`openai.lua` gefunden und
   gefixt wurde (Code-Review-Abschnitt oben) — eine Auth-/Validierungs-
   Fehlerantwort auf einen *Streaming*-Request kommt bei Anthropic/OpenAI
   NICHT als SSE-Event zurück, sondern als mehrzeiliger, pretty-printed
   JSON-Body; curl selbst beendet trotzdem mit Exit-Code 0. Beide neuen
   C++-Clients brauchen die gleiche "nicht-`data:`-Zeilen sammeln, erst am
   Streamende als ein JSON-Block parsen"-Logik wie `ai.nvim`s
   `lua/ai/providers/sse.lua` (dort bereits als wiederverwendbarer Helper
   extrahiert, siehe Code-Review-Abschnitt "Dedupliziert") — in C++ neu zu
   bauen (keine Lua-Bibliothek wiederverwendbar), aber exakt gleiches Muster.
4. **Modell→Backend-Routing** — offene Design-Entscheidung, Empfehlung
   ausgesprochen, aber **noch nicht vom Nutzer final bestätigt**:
   - **Option (a) — empfohlen**: server-seitig per Modellname-Präfix
     (`claude-*` → Anthropic, `gpt-*`/`o1-*`/`o3-*` → OpenAI, alles andere →
     Ollama/lokal). Ändert den bestehenden `/ask`-Vertrag NICHT — kein
     Anpassungsbedarf in `ai.nvim`s `loomai.lua`.
   - Option (b): neues optionales `provider`-Feld im Request-Body
     (`{"provider": "anthropic", ...}`, Default = aktuelles Verhalten/Ollama).
     Additiv rückwärtskompatibel, aber `ai.nvim`s `loomai.lua` müsste das Feld
     dann auch aktiv setzen können, sonst bleibt es totes Feature.
   - **Empfehlung: (a)**, weil es den bereits stabilen, von `ai.nvim`
     konsumierten Vertrag unangetastet lässt und der "registry entry, not a
     merge"-Scope-Grenze (`ai.nvim`s `docs/scope.md`) treu bleibt.
5. **Crash-Schutz konsistent halten**: der äußere `try/catch` in
   `/ask/stream` fängt zwar bereits alles ab (s. o.), aber jeder neue Client
   sollte trotzdem selbst defensiv Fehlerfelder stringifizieren
   (`error_text()`-Helper-Muster aus dem `4e2777c`-Fix wiederverwenden bzw.
   erweitern), statt sich ausschließlich auf den äußeren Fang zu verlassen —
   gleiche Sorgfaltspflicht wie beim bereits gefundenen kritischen Bug.
6. **Testing**: gleiches Muster wie bei `ai.nvim`s eigener Provider-Arbeit —
   Live-End-to-End gegen die echten APIs, inkl. eines bewusst ungültigen
   Test-Keys, um den Fehlerpfad auszulösen und die Normalisierung ins
   bestehende `{"error":{"message":...}}`-Format zu verifizieren (nicht nur
   Happy-Path).
7. **Doku-Nachzug danach** (Reihenfolge: erst Code+Tests, dann Doku, wie
   bisher durchgehend in diesem Projekt gehandhabt):
   - `loomAI/README.md`: Abschnitt "HTTP-API" (Backend ist dann nicht mehr
     nur "direkter Ollama-Aufruf"), Abschnitt "Stand / was fehlt" (Punkte
     "Kein ModelRouter"/"Kein Anthropic-Client" streichen bzw. aktualisieren).
   - `docs/Guides/ki-agenten-framework-architektur.md`: Phase-1-Checkliste,
     "Anthropic API Client" von `[ ]` auf `[x]`, "Model Router" ggf. auf
     `[x]` falls Option (a) als einfache Präfix-Heuristik zählt (Judgment
     Call bei Umsetzung).

---

### Offene Fragen für die Fortsetzungs-Session

- Bestätigung der Routing-Option: (a) Modellname-Präfix (empfohlen) vs.
  (b) explizites `provider`-Feld — siehe Punkt 4 oben.
- Timeout-/Retry-Verhalten pro Backend identisch zu Ollama übernehmen oder
  API-spezifisch (Anthropic/OpenAI haben eigene Rate-Limit-Header, die man
  auswerten könnte) — bisher nicht durchdacht, `nice-to-have`, nicht
  blockierend für eine erste Version.
- Ob `capabilities` (analog zu `ai.nvim`s `Ai.Provider.capabilities`) auch
  serverseitig gebraucht wird, z. B. um `/ask/stream` für ein Backend ohne
  Streaming-Unterstützung sauber abzulehnen statt zu buffern — aktuell
  brauchen alle drei angedachten Backends (Ollama, OpenAI, Anthropic)
  Streaming nativ, also vorerst nicht relevant; nur falls ein zukünftiges
  Open-Source-Tool kein Streaming kann, müsste das nachgezogen werden.

---

## Design-Entscheidungen, Gemini, rules.nvim, Live-Testing-Plan (2026-09-14, Folgesession 4)

Ausgangspunkt: der Nutzer wollte die meisten Features beider Repos live
testen. Dafür erst ein [Live-Testing-Plan](../../reports/ai/live-testing-plan.md)
geschrieben (`nvim/docs/ROADMAP/reports/ai/live-testing-plan.md`), dabei zwei
echte Befunde gemacht (GPU-Korrektur, ein reproduzierter Bug), dann vier
offene Design-Entscheidungen dem Nutzer vorgelegt (je mit Empfehlung) und
umgesetzt.

**Nebenbefund beim Gegenlesen:** zwischen der letzten und dieser Sitzung lief
bereits `dab3700 refactor(ui): migrate from lib.nvim.ui.kit to ui.nvim` in
`ai.nvim` — Phase 5 oben (`lib.nvim.ui.kit.surface`) ist dadurch historisch
überholt, **absichtlich nicht rückwirkend umgeschrieben** (wie der Rest
dieser Datei: neue Fakten kommen als neuer Abschnitt dazu, alte Einträge
bleiben Zeitkapsel). Aktueller Stand: `ui.nvim` (`StefanBartl/ui.nvim`), s.
`docs/requirements.md`/`docs/installation.md` im `ai.nvim`-Repo. War nicht
Teil dieser Sitzung, nur beim Gegenlesen aufgefallen.

### Design-Entscheidungen (vom Nutzer bestätigt, jeweils die empfohlene Option)

1. **loomAI-ModelRouter-Routing**: Modellname-Präfix (Option a aus dem
   Scoping-Abschnitt oben), **nicht** ein explizites `provider`-Feld. Ändert
   den bestehenden `/ask`-Vertrag nicht.
2. **Gemini-Scope**: **beides** — `ai.nvim` direkt (`providers/gemini.lua`,
   diese Sitzung erledigt, s. u.) **und** später der loomAI-ModelRouter
   bekommt einen dritten Cloud-Client dafür (noch offen, s.
   Umsetzungsplan unten).
3. **loomAI-Dashboard**: ein minimales Ask/Chat-Testpanel bauen (Eingabefeld
   + Provider/Modell-Auswahl + Streaming-Ausgabe) — noch offen, s.
   Umsetzungsplan unten.
4. **`OLLAMA_HOST`-Bug**: sofort fixen — **erledigt**, s. u.

### `ai.nvim`-seitig erledigt (Commit `0db00bd`, gepusht, CI grün)

- **Echter Bug gefixt**: `lua/ai/providers/ollama.lua`s `host()` las
  `OLLAMA_HOST` für die Client-Ziel-URL — das ist aber Ollamas **eigene**
  Variable für die *Server*-Bind-Adresse (typischerweise `0.0.0.0:11434`,
  kein Schema, kein gültiges Client-Ziel). Auf der Test-Maschine live
  reproduziert (`OLLAMA_HOST=0.0.0.0:11434` war dort tatsächlich gesetzt,
  `ollama.lua` hätte daraus `0.0.0.0:11434/api/chat` gebaut). Exakt dieselbe
  Verwechslung, die `loomai.lua` mit `LOOMAI_HOST` (statt `OLLAMA_HOST`)
  bereits bewusst vermieden hatte. Umbenannt auf `AI_OLLAMA_HOST`, Doku
  (`docs/requirements.md`, `doc/ai.txt`) nachgezogen.
- **Gemini-Provider**: `lua/ai/providers/gemini.lua`, strukturell wie
  `claude.lua`/`openai.lua` (SSE-Streaming, `ai.providers.sse`s
  `non_data_lines`/`recover_error_body`-Fehlerbehandlung analog übernommen —
  **nicht** live gegen die echte Gemini-API verifiziert, da kein
  `GEMINI_API_KEY` verfügbar war; das muss die nächste Live-Testing-Runde
  nachholen, s. Testing-Plan). Auth bewusst über den `x-goog-api-key`-Header
  via `secret_headers`, nicht Gemini's übliches `?key=...`-Query-Param — Letzteres
  hätte den Key in curl's argv/Prozessliste sichtbar gemacht, exakt die
  Bugklasse, wegen der es `ai.nvim` überhaupt gibt. In `BUILTIN` und
  `provider_order` (nach `openai`, vor `loomai`). `@types`, Tests
  (`config_spec.lua`, `providers_spec.lua`), alle Docs (`architecture.md`,
  `configuration.md`, `scope.md`, `requirements.md`, `doc/ai.txt`)
  nachgezogen. luacheck/stylua grün, Plenary-Suite 22/22 grün, CI grün.

### rules.nvim gegen `ai.nvim` laufen lassen (erledigt, kein Auftrag mehr offen)

`rules.nvim` (`E:\repos\rules.nvim`) ist ein generischer Regel-Checker; die
wkdbook-Gates `NEW_PROJECT.md` (`NEW-*`) und `RELEASE.md` (`REL-*`) sind seit
2026-09-13 bereits vollständig als `rule`-Blöcke migriert, `REVIEW.md` selbst
ist nur ein Index, aber die Dateien, auf die es verweist
(`regeln/LUA_NVIM.md`, `regeln/PRINCIPLES.md`, `regeln/PERFORMANCE.md`) sind
es ebenfalls (Familien `CMT`/`DEP`/`ERR`/`LLS`/`LUA`/`SEC`/`TS`/`UI`/`XP`,
`PRIN`, `PERF`). Alle drei Gates headless gegen `E:/repos/ai.nvim` laufen
lassen (Setup-Snippet unten, wiederverwendbar):

```lua
require("rules").setup({
  rulesets = { "E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists" },
  gates = {
    new_project = { "NEW" },
    release = { "REL" },
    review = { "CMT","DEP","ERR","LLS","LUA","PRIN","PERF","SEC","TS","UI","XP" },
  },
})
require("rules").run_gate("release", "E:/repos/ai.nvim")  -- interaktiv (quickfix+buffer)
```

**Ergebnis:** kein Gate hat einen automatisch geprüften **kritischen** Fund
(`exit_code=0` bei allen drei). Ein automatisierter `fail` gefunden:
**`NEW-08`** ("`/bindings`-Ordner", `recommended`) erwartet
`lua/*/bindings/{keymaps,usrcmds,autocmds}.lua` — `ai.nvim` hat aber
`bindings/usercmds.lua` (nicht `usrcmds.lua`) und kein `bindings/autocmds.lua`
unter genau diesem Glob-Muster geprüft (tatsächlich existiert
`bindings/autocmds.lua` im Repo — nur der `usrcmds`-vs-`usercmds`-Namensunterschied
lässt den Check gesamt scheitern, `and`-verknüpft). **Reine
Namenskonventions-Frage, kein echter Strukturmangel** — `rules.nvim` selbst
nennt seine eigene Datei `bindings/usrcmds.lua`, `ai.nvim` hat sich für
`usercmds.lua` entschieden; beides ist lesbar, nur inkonsistent mit dem
Katalog. **Nicht behoben** (Umbenennen ist eine reine Konvention-vs-Konvention-
Entscheidung, keine Bugkorrektur) — liegt beim Nutzer, ob `ai.nvim`s Datei an
den Katalog angepasst wird oder der Katalog an gängige Praxis.

Die `review`-Gate-Familien liefern erwartungsgemäß überwiegend `manual`
(judgment-basierte Regeln, kein automatischer Check) — mehrere hundert
Einträge, ein echter Mehrstunden-Task laut `rules.nvim`s eigener Doku, **nicht
in dieser Sitzung durchgearbeitet**. Empfehlung: `:Rules gate review
E:/repos/ai.nvim` interaktiv (Buffer-Report) bei Gelegenheit durchgehen,
nicht als JSON-Dump wie hier.

### Umsetzungsplan: was noch offen ist

**A. loomAI-ModelRouter** (C++, `E:\repos\loomAI`) — vollständig gescoped im
Abschnitt oben, jetzt mit bestätigter Routing-Option (a) und **erweitert um
Gemini als dritten Cloud-Client** (Design-Entscheidung 2):
1. `src/openai_client.hpp/.cpp` (`Authorization: Bearer $OPENAI_API_KEY`).
2. `src/anthropic_client.hpp/.cpp` (`x-api-key: $ANTHROPIC_API_KEY` +
   `anthropic-version`-Header).
3. `src/gemini_client.hpp/.cpp` (`x-goog-api-key: $GEMINI_API_KEY`-Header —
   **nicht** `?key=...` in der URL, gleiche Argv-Sicherheitsbegründung wie
   bei `ai.nvim`s `gemini.lua` oben; Response-Schema
   `candidates[0].content.parts[].text`).
4. Modellname-Präfix-Router in `main.cpp`s `/ask`/`/ask/stream`-Handlern:
   `claude-*`→Anthropic, `gpt-*`/`o1-*`/`o3-*`→OpenAI, `gemini-*`→Google,
   sonst→Ollama (aktuelles Verhalten als Fallback).
5. Non-SSE-Fehlerkörper-Recovery (wie `ai.providers.sse` in Lua) für alle
   drei neuen Clients — mit hoher Wahrscheinlichkeit dieselbe Bugklasse wie
   bei `claude.lua`/`openai.lua`.
6. `error_text()`-Stringify-Helper (aus dem `4e2777c`-Fix) konsequent auch in
   den drei neuen Clients, nicht nur im äußeren `try/catch`.
7. Live-Tests mit echten Keys inkl. Fehlerpfad (ungültiger Key), dann Doku
   (`README.md`, `docs/Guides/ki-agenten-framework-architektur.md`).

**B. loomAI-Dashboard Ask/Chat-Testpanel** (`dashboard/index.html`) —
Design-Entscheidung 3:
1. Neue Karte "Ask" neben "Agenten"/"System": Textarea für den Prompt,
   Select für Provider (`ollama`/`openai`/`anthropic`/`gemini`, sobald A
   steht) bzw. Modellname-Freitext, Submit-Button.
2. `fetch('/ask/stream', {method:'POST', body: JSON.stringify({prompt, model})})`
   + manuelles SSE-Body-Parsing (kein `EventSource` möglich für POST-Bodies —
   `EventSource` unterstützt nur GET; stattdessen `fetch` +
   `response.body.getReader()`, zeilenweise `data:`-Parsing wie in
   `ai.nvim`s `sse.lua`, nur in JS).
3. Ausgabe live in ein `<div>` unterhalb des Eingabefelds anhängen, während
   Tokens eintreffen.
4. Die veraltete "Model: simulation (LLM folgt)"-Badge im System-Status
   entfernen/korrigieren (sie bezieht sich auf den separaten
   Simulations-Agenten, nicht auf `/ask`, s. Testing-Plan Abschnitt 8).
5. Kein Framework nötig — bestehendes Dashboard ist Vanilla-JS/CSS in einer
   einzigen `index.html`, gleicher Stil beibehalten.

**Beide (A, B) sind für eine eigene Sitzung vorgesehen** (C++-Build-/Test-
Zyklen + Browser-Testing lassen sich schlecht in derselben Sitzung mit
mehreren anderen Aufgaben bündeln, und die "max 1 Agent"-Regel erzwingt
ohnehin sequenzielles Arbeiten). Reihenfolge-Empfehlung: A vor B, damit das
Dashboard-Testpanel gegen einen bereits multi-provider-fähigen Server testen
kann, statt zweimal (einmal nur-Ollama, einmal nach A) angepasst werden zu
müssen.

---

## Teil B umgesetzt: loomAI-Dashboard Ask/Chat-Testpanel (2026-09-14, Folgesession 6)

**Alle 5 Punkte aus dem Umsetzungsplan oben erledigt**, direkt im Anschluss
an Teil A, gegen den jetzt bereits multi-provider-fähigen Server getestet
(wie empfohlen).

`dashboard/index.html` (weiterhin Vanilla-JS/CSS, ein File, kein Framework)
bekam eine neue "Ask"-Karte zwischen dem Agenten/System-Grid und dem
Live-Log: Prompt-Textarea, Modell-Eingabefeld mit `<datalist>`-Vorschlägen
(je ein Beispielmodell pro Backend), Senden/Stopp-Buttons, Statuszeile,
Ausgabebereich. Da `EventSource` keinen POST-Body senden kann, läuft das
Streaming über `fetch('/ask/stream', {method:'POST', ...})` +
`response.body.getReader()` mit manuellem `data: <json>\n\n`-Zeilen-Parsing
— dieselbe Zerlegung, die `ai.nvim`s `providers/sse.lua` in Lua macht, hier
in JS nachgebaut. Stopp bricht den laufenden `fetch` über einen
`AbortController` ab.

Die veraltete, seit `/ask`/`/ask/stream` real sind irreführende
"Model: simulation (LLM folgt)"-Badge ist ersetzt durch eine live beim
Laden per `GET /health` befüllte "Backends"-Zeile (`Ollama ✓ OpenAI ✓
Anthropic ✗ Gemini ✗` o. ä.) — zeigt den tatsächlichen Konfigurationsstand
statt eines fest eingetragenen Satzes.

**Live im echten Browser verifiziert** (Claude-Browser-Pane gegen einen
laufenden Server, nicht nur gelesen/angenommen):
- Backend-Zeile lädt korrekt (`Ollama ✓  OpenAI ✓  Anthropic ✗  Gemini ✗`,
  passend zum tatsächlichen Env-Var-Stand dieser Maschine).
- Happy-Path-Streaming gegen den echten Ollama-Daemon (`llama3:8b`,
  "Count from 1 to 5") — Ausgabe füllt sich live, Status wechselt
  "Sende Anfrage..." → "Streaming..." → "Fertig." (grün).
- Fehlerpfad gegen ein nicht konfiguriertes Backend (`claude-3-5-haiku-...`
  ohne `ANTHROPIC_API_KEY`) — Statuszeile zeigt korrekt
  "Fehler: anthropic: ANTHROPIC_API_KEY not set" (rot), Senden-Button wird
  wieder freigegeben.
- Stopp-Button bricht einen laufenden Stream tatsächlich ab (getestet mit
  einem langen Prompt, mitten im Streaming geklickt) — Status "Abgebrochen.",
  nicht nur eine UI-Attrappe.

Committet (`a48c528`) und direkt auf `origin/main` gepusht, lokaler Checkout
`E:\repos\loomAI` synchronisiert — gleiches Vorgehen wie bei Teil A.

**Damit sind beide Teile (A: ModelRouter, B: Dashboard-Testpanel) aus dem
Umsetzungsplan dieser Folgesession-Reihe vollständig erledigt.**

---

## Teil A umgesetzt: loomAI-ModelRouter (2026-09-14, Folgesession 5)

**Alle 7 Punkte aus dem Umsetzungsplan oben erledigt.** Neue Dateien
`src/{openai,anthropic,gemini}_client.hpp/.cpp` nach dem
`ollama_client.hpp/.cpp`-Muster, plus neues `src/model_client.hpp` (geteilte
`loomai::AskResult`-Struktur + `error_text()`/`sse_data_payload()`/
`recover_error_body()` — dieselbe Non-SSE-Fehlerkörper-Wiederherstellung wie
`ai.providers.sse` in Lua, jetzt einmal in C++ statt dreifach kopiert).
`ollama_client.hpp/.cpp` auf die geteilte Struktur umgestellt
(`prompt_eval_count`/`eval_count` → `prompt_tokens`/`completion_tokens`,
reines Umbenennen). `main.cpp`s `/ask`+`/ask/stream` dispatchen jetzt per
Modellname-Präfix (`route_ask`/`route_ask_stream`): `claude-*`→Anthropic,
`gpt-*`/`o1-*`/`o3-*`→OpenAI, `gemini-*`→Google, sonst→Ollama. `/health`
zeigt jetzt zusätzlich `backends: {ollama,openai,anthropic,gemini}` (nur
Presence, nie der Key-Wert).

**Build-Hürde gelöst:** die drei Cloud-Clients brauchen echtes HTTPS
(`cpp-httplib` mit `CPPHTTPLIB_OPENSSL_SUPPORT`) — `ollama_client` kam
bisher ohne aus (nur `http://127.0.0.1`). `CMakeLists.txt` jetzt mit
`find_package(OpenSSL REQUIRED)` + Link gegen `OpenSSL::SSL`/`OpenSSL::Crypto`.
Unter Windows/MSYS2 fand das separat installierte CMake das
mingw64-OpenSSL nicht automatisch — `-DOPENSSL_ROOT_DIR=C:/msys64/mingw64`
nötig, jetzt in `README.md`s Build-Anleitung dokumentiert.

**Echter Bug gefunden + gefixt, beim Live-Testen (nicht beim Schreiben):**
alle drei neuen `ask_stream()`-Implementierungen puffern eingehende Bytes
zeilenweise (Split auf `\n`) — ein finaler Fehlerkörper ohne abschließenden
Zeilenumbruch blieb dadurch unverarbeitet im internen Buffer stecken,
`recover_error_body()` sah eine leere `non_data_lines`-Liste und fiel auf
ein generisches `"HTTP 401: "` zurück statt die echte API-Fehlermeldung zu
zeigen. Live gegen die echte OpenAI-API reproduziert (abgelaufener Key
dieser Maschine löste den Fehlerpfad aus), dann gefixt: verbleibender
Buffer-Inhalt wird beim Stream-Ende zusätzlich in `non_data_lines`
geflusht, bevor die Recovery versucht wird. `ollama_client.cpp` brauchte
das nie — ein fehlgeschlagener Ollama-Stream kommt immer als vollständige,
zeilenumbruch-terminierte NDJSON-Zeile zurück, nie als Body ohne
abschließende Zeile.

**Live verifiziert, alle vier Backends, echte Netzwerk-Calls (nicht
angenommen):**
- **Ollama** (echter Daemon, gepulltes `llama3:8b`): `/ask` und
  `/ask/stream` Happy-Path — korrekte Antwort, korrektes `usage`
  (bestätigt den Feld-Rename), Tokens einzeln beim Streaming.
- **OpenAI**: Fehlerpfad mit dem (abgelaufenen) echten Key dieser Maschine —
  `/ask` und `/ask/stream` liefern die echte OpenAI-Fehlermeldung, kein
  Crash, `/health` antwortet danach weiter normal.
- **Anthropic**: Fehlerpfad mit einem bewusst ungültigen Test-Key (kein
  echter Key auf dieser Maschine verfügbar) — `/ask` und `/ask/stream`
  liefern "API key is invalid.", kein Crash.
- **Gemini**: Fehlerpfad mit einem bewusst ungültigen Test-Key — `/ask` und
  `/ask/stream` liefern "API key not valid. Please pass a valid API key.",
  kein Crash.
- Modellname-Präfix-Routing für alle vier Fälle bestätigt (jede Anfrage kam
  nachweislich beim richtigen Backend an, erkennbar an der jeweils
  Backend-spezifischen Fehlermeldung/Antwort).

**Bewusst nicht (über-)behauptet:** das hier ist ein einfacher
Modellname-Präfix-Router, **nicht** die VRAM-Heuristik/Task-Typ-basierte
`RoutingPolicy` aus `docs/Guides/ki-agenten-framework-architektur.md`
Abschnitt 4.2 — Checkliste dort entsprechend ehrlich aktualisiert (siehe
Commit), nicht als vollständig erledigt markiert.

**Nebenbefund, nicht behoben (kein Teil dieser Aufgabe):** `main.cpp`s
`svr.listen("127.0.0.1", 8080)` prüft seinen Rückgabewert nicht — ein
Bind-Fehler (Port bereits belegt) würde derzeit still verschluckt. Beim
Testen selbst verursacht (zwei über `taskkill` nicht sauber beendete
Hintergrund-Testinstanzen liefen parallel), kein durch diese Sitzung
eingeführtes Verhalten, aber real und noch offen — siehe "Nächste
Schritte" unten.

Doku nachgezogen: `loomAI/README.md` (Build-Anleitung, neue Env-Vars-Tabelle,
`/health`-Beispiel, neuer "ModelRouter"-Abschnitt, "Stand/was fehlt"
aktualisiert, dabei auch einen veralteten Report-Pfad korrigiert —
`reports/loomai-...` → `reports/ai/loomai-...`), `docs/Guides/
ki-agenten-framework-architektur.md`s Phase-1-Checkliste. Committet
(`2f1edba`) und **direkt auf `origin/main`** gepusht (kein PR-Workflow
nötig, eigenes Repo) — die Session lief technisch in einem Git-Worktree
(Sandbox-Vorgabe), das Ergebnis liegt aber wie gewohnt sofort auf `main`.
Lokaler Checkout `E:\repos\loomAI` per `git pull --ff-only` synchronisiert.

---

## Gemini-Sicherheits-/Korrektheitsfixes (2026-09-14, Folgesession 7)

Nutzer-gemeldete Bugliste gegen `ai.nvim`s `gemini.lua` und loomAIs
`gemini_client.cpp` (beide implementieren dieselbe API, gleiche Bugklasse
doppelt) — 6 Punkte, nach Priorität abgearbeitet:

- 🔴 **Correctness, gefixt (beide Dateien)**: Gemini meldet einen
  Safety-/Policy-Block als normale `200`-Antwort mit `promptFeedback.
  blockReason` und ganz ohne `candidates` — `ok=true`/`200` mit leerem Text
  statt eines Fehlers, exakt die "stiller leerer Erfolg statt Fehler"-
  Bugklasse, die dieses Projekt beheben soll. Neuer
  `prompt_block_reason()`-Helper (Lua und C++, identische Logik) erkennt das
  jetzt in `ask`/`stream` (inkl. der Non-SSE-Fehlerkörper-Recovery). Für
  `gemini.lua`s `M.stream()` zusätzlich ein `failed`-Flag ergänzt, damit
  `on_done` nach einem mittendrin gemeldeten `on_error` nicht zusätzlich mit
  einer leeren "Erfolgs"-Antwort feuert.
- 🔴 **Security, gefixt (beide Dateien)**: `model` landet ungeprüft in der
  Request-URL (`/v1beta/models/<model>:generateContent`) — anders als
  Claude/OpenAI, die `model` sicher im JSON-Body verschicken. `cpp-httplib`
  escaped `\r`/`\n`, aber nicht `/` — ein präpariertes `model` hätte den
  authentifizierten Request auf einen beliebigen Pfad bei Google umlenken
  können. Fix: Allowlist-Check (`^[%w%.%-_]+$` bzw. alnum+`.`/`-`/`_` in
  C++) vor jeder URL-Interpolation, in `ask`/`stream` bzw. `ask`/`ask_stream`.
- 🟡 **`gemini_client.cpp`, gefixt**: `usage`-Felder wurden ohne den
  gleichen Schutz wie `error_text()` geparst — ein `null`/nicht-numerischer
  Wert hätte eine ungefangene `json::type_error` ausgelöst. Neuer
  `json_long_or()`-Helper, defensiv wie `error_text()`.
- 🟡 **`gemini_client.cpp`, gefixt**: kein Limit für den internen
  Zeilen-Puffer beim Streaming — eine Antwort ohne Zeilenumbruch hätte ihn
  unbegrenzt wachsen lassen. Jetzt bei 1 MiB gedeckelt, bricht mit sauberer
  Fehlermeldung ab statt endlos zu wachsen.
- 🟡 **`dashboard/index.html`, gefixt**: `scrollTop`+`textContent+=` bei
  jedem einzelnen Stream-Token erzwang ein Reflow pro Token (gleiche Klasse
  wie das bereits zurückgestellte `ui/panel.lua`-Finding, aber hier ein
  anderes, eigenständig fixbares File). Deltas werden jetzt in
  `pendingOutput` gesammelt und einmal pro Animation-Frame geflusht
  (`requestAnimationFrame`), plus ein finaler Flush in `finally`, damit
  beim Abbruch/Fehler/Ende nichts verloren geht.
- ⚪ **Bewusst nicht gefixt**: neue TCP+TLS-Verbindung pro Cloud-Request
  (verschärfte Variante des bereits bekannten, bewusst zurückgestellten
  Ollama-Poolings-Problems, s. u. "Nächste konkrete Schritte" Punkt 5) —
  ein echtes Connection-Pooling-Design ist eine größere architektonische
  Änderung (geteilte Client-Lebensdauer, Thread-Sicherheit), keine
  Bugkorrektur, nicht unangekündigt reingepatcht.

Verifiziert: `ai.nvim`s volle `busted`/`plenary`-Suite grün, `stylua
--check` clean; `gemini_client.cpp` einzeln mit `g++ -Wall -Wextra`
kompiliert (clean, keine Warnungen — kompletter Link braucht OpenSSL, hier
nicht verfügbar); Dashboard-JS mit `node --check` auf Syntaxfehler geprüft.
Committet: `ai.nvim` `ef6b11b` (jetzt auf `main`, `origin/main` gepusht),
loomAI `fd476e8` (Client-Fixes) + `cd9cda5` (Dashboard-Fix), beide direkt
auf `origin/main`.

---

## loomai-ai-nvim-integration.md verifiziert & archiviert (2026-09-14, Folgesession 8)

Nutzer-Anfrage: prüfen, ob der detaillierte Anforderungsreport
[loomai-ai-nvim-integration.md](../../personal/All/FINISH/ERLEDIGT/Handover_ERLEDIGT/loomai-ai-nvim-integration.md)
(Aufgaben A-F) vollständig umgesetzt ist, und falls ja, ihn nach `ERLEDIGT/`
verschieben.

**Ergebnis: ja, vollständig — jeder Punkt direkt im Code gegengeprüft, nicht
nur der Doku vertraut:**

- Aufgabe A (Health): `GET /health` existiert (`main.cpp:214`), liefert
  `{"status":"ready","model_router_ready":true,"backends":{...}}`.
- Aufgabe B (Non-Streaming Ask): `POST /ask` existiert (`main.cpp:236`),
  `{prompt,system,model,timeout_ms}` → `{text,provider,stop_reason,usage}`,
  `400` bei fehlendem `prompt`, `502` bei Backend-Fehler.
- Aufgabe C (Streaming/SSE): `POST /ask/stream` existiert (`main.cpp:273`),
  `data: {"delta":...}` pro Chunk, Fehler mitten im Stream als reguläres
  `data: {"error":...}`-Event statt rohem Verbindungsabbruch, `data:
  [DONE]`-Sentinel am Ende.
- Aufgabe D (Fehlerformat): `send_json_error()` liefert konsistent
  `{"error":{"message":...}}`, nie eine leere `200`.
- Aufgabe E (Modellauswahl): Option 1 (frei/unvalidiert) umgesetzt — `model`
  ist ein beliebiger String, kein `/models`-Endpoint gebaut, wie empfohlen.
- Aufgabe F (Netzwerk/Auth): Server bindet `127.0.0.1` statt `0.0.0.0`
  (`main.cpp:334`), kein Auth nötig, `LOOMAI_HOST`-Basis-URL konfigurierbar.
- Abschnitt 9 (Design-Frage `available()`): entschieden, Option (a) —
  `lua/ai/providers/loomai.lua`s `available()` prüft nur
  `vim.fn.executable("curl")`, kein Netzwerk-Roundtrip.
- Abschnitt 11 (`loomai`-Provider in `ai.nvim`): `loomai.lua` implementiert
  `available()`/`ask()`/`stream()`, registriert in `providers/init.lua`s
  `BUILTIN` und `DEFAULTS.lua`s `provider_order`.
- Abschnitt 12 (Crash-Sorge bei fehlendem `stream()`): gegenstandslos, da
  `stream()` von Anfang an mitgebaut wurde (live verifiziert, s. o.
  "loomai-Provider umgesetzt").

**Nebenbefund beim Gegenlesen der übrigen offenen Punkte:** `NEW-08`
(`bindings/usercmds.lua` vs. `usrcmds.lua`, s. u. "Nächste konkrete
Schritte" Punkt 7) ist ebenfalls bereits erledigt — Commit `2bed0d6`
(bereits auf `origin/main`) hat umbenannt, `ls lua/ai/bindings/` zeigt
jetzt `{keymaps,usrcmds,autocmds,actions}.lua`. War der Handover-Datei
noch nicht bekannt, jetzt oben nachgetragen.

Datei verschoben (`git mv`, Historie erhalten) nach
`docs/ROADMAP/personal/All/FINISH/ERLEDIGT/Handover_ERLEDIGT/
loomai-ai-nvim-integration.md`, mit Archivierungs-Vermerk am Dateikopf.
Alle drei Verweise hier in diesem Handover (Orte-Tabelle, "loomAI:
Entscheidung & Fallback", "loomai-Provider umgesetzt") auf den neuen Pfad
aktualisiert. Committet im `nvim`-Config-Repo (`StefanBartl/nvim`) und auf
`origin/main` gepusht.

---

## Nächste konkrete Schritte (Stand jetzt, 2026-09-14)

Phasen 0-8 erledigt, Code-Review durchgelaufen (9/10 Findings gefixt), `lib.nvim`-CI
komplett grün (inkl. `publish-ci-verified`), `ai.nvim`-CI grün, `doc/ai.txt`
nachgetragen. `loomai`-Provider gebaut, in `provider_order`, live gegen `:Ai
ask`/`:Ai stream` verifiziert (siehe [oben](#loomai-provider-umgesetzt-2026-09-14-folgesession)).
`gemini`-Provider (ai.nvim-seitig) gebaut und gepusht, `OLLAMA_HOST`-Bug
gefixt, `rules.nvim` gegen `ai.nvim` laufen lassen (siehe [oben](#design-entscheidungen-gemini-rulesnvim-live-testing-plan-2026-09-14-folgesession-4)).
**loomAI-ModelRouter (Teil A) fertig und live verifiziert** (siehe
[oben](#teil-a-umgesetzt-loomai-modelrouter-2026-09-14-folgesession-5)):
OpenAI/Anthropic/Gemini als Backends, Modellname-Präfix-Routing, alle vier
Backends live gegen echte APIs getestet. **Gemini-Sicherheits-/
Korrektheitsfixes** (siehe [oben](#gemini-sicherheits-korrektheitsfixes-2026-09-14-folgesession-7))
in `ai.nvim`s `gemini.lua` und loomAIs `gemini_client.cpp`+Dashboard erledigt.
**`loomai-ai-nvim-integration.md`** vollständig verifiziert und nach `ERLEDIGT/`
archiviert (siehe [oben](#loomai-ai-nvim-integrationmd-verifiziert--archiviert-2026-09-14-folgesession-8)),
dabei `NEW-08` (Punkt 7 unten) als bereits erledigt entdeckt und nachgetragen.
Alle Repos (`ai.nvim`, `lib.nvim`, `loomAI`, `nvim`-Config, `WKDBooks`)
committet und gepusht, synchron mit `origin/main`. Offen:

1. `ai.nvim` im Alltag benutzen (`<leader>ai{a,s,e}`, jetzt auch `loomai`/
   `gemini`), um v1 vor einem Tag zu validieren — Live-Testing-Plan dafür
   fertig: [reports/ai/live-testing-plan.md](../../reports/ai/live-testing-plan.md)
   (Achtung: der Testplan geht noch von "loomAI kann nur Ollama" aus, s.
   Punkt 6 unten — beim nächsten Durchgang mit den drei neuen Cloud-Backends
   ergänzen).
2. Phase 10 (`gates/RELEASE.md`) vor dem ersten Tag/Release, danach.
   `rules.nvim`s `release`-Gate zeigt keine automatisierten kritischen
   Lücken (s. o.); die `manual`-Posten aus dem `review`-Gate noch nicht
   durchgearbeitet.
3. Phase 9 (Follow-up, nicht blockierend): `pdfport.nvim`-Migration.
   `loomai`-Provider ist erledigt (s. o.), nicht mehr offen.
4. `ui/panel.lua`s Voll-Buffer-`set_lines()` pro Stream-Chunk (Review-Finding, bewusst
   nicht gefixt) — nur angehen, falls in der Praxis spürbar.
5. loomAIs `ollama_client.cpp`: neue TCP-Verbindung pro `/ask`/`/ask/stream`-Request
   statt Wiederverwendung (Review-Finding, bewusst nicht gefixt) — braucht ein
   durchdachtes Pooling-Design (z. B. thread-lokale Clients), erst bei spürbarem
   Bedarf angehen.
6. ~~loomAI-Dashboard Ask/Chat-Testpanel (Teil B)~~ — **erledigt**, siehe
   [oben](#teil-b-umgesetzt-loomai-dashboard-askchat-testpanel-2026-09-14-folgesession-6).
   Damit sind Teil A und B des ModelRouter-Umsetzungsplans komplett.
7. ~~`NEW-08` (rules.nvim-Fund): `ai.nvim`s `bindings/usercmds.lua` heißt anders
   als der Katalog erwartet (`usrcmds.lua`)~~ — **erledigt** (Commit `2bed0d6
   refactor(bindings): rename usercmds.lua to usrcmds.lua`, bereits auf
   `origin/main`, per `ls` gegengeprüft: `lua/ai/bindings/` enthält jetzt
   `{keymaps,usrcmds,autocmds,actions}.lua`, exakt das vom Katalog erwartete
   Muster).
8. ~~loomAIs `main.cpp`: `svr.listen()`-Rückgabewert wird nicht geprüft, ein
   Bind-Fehler (Port belegt) verschwindet still~~ — **erledigt** (Commit
   `e3c025a`: prüft den Rückgabewert jetzt, loggt auf `stderr` und beendet
   mit Exit-Code 1 statt still durchzulaufen; README-Erwähnung unter
   "Stand/was fehlt" wieder entfernt, Commit `18c0589`).
9. Modellname-Präfix-Liste im loomAI-Router (`gpt-`/`o1-`/`o3-`/`claude-`/
   `gemini-`) ist hartkodiert, keine Config-Möglichkeit — bislang kein
   Bedarf, siehe README "Stand/was fehlt".
10. Diese Datei laufend als Statusprotokoll fortschreiben.

---

## loomAI-Doku-Housekeeping (2026-09-14, Folgesession 9)

Drei Nutzer-Anfragen zu loomAIs Doku-Lage, alle umgesetzt und gepusht:

- **`docs/Guides/setup-guide.md` gehört nicht ins öffentliche Repo** —
  beschreibt eine deutlich größere, nie gebaute Zukunftsvision (Sandbox,
  Orchestrator, Lua-Agent-Scripting, CUDA/GPU, SQLite-State), nicht den
  tatsächlichen Stand des Tools. Nach `E:\repos\WKDBooks\Development\
  wkdbook-loomai\Guides\setup-guide.md` verschoben (loomAI-Commit `a5b707e`,
  WKDBooks-Commit `606238f`), mit Kontext-Vermerk am Dateikopf. **Zweite,
  gleichartige Datei im selben Ordner bemerkt, aber nicht angefasst** (nicht
  angefragt): `docs/Guides/ki-agenten-framework-architektur.md` — gehört
  wahrscheinlich demselben Muster, gehört also vermutlich ebenfalls nicht
  ins öffentliche Repo. Bei Gelegenheit gegenchecken.
- **Cross-Plattform-Prerequisite-Checker** für `setup-guide.md`s
  Voraussetzungsliste geschrieben: `check_prerequisites.py`
  (Python-3-Stdlib, keine Abhängigkeiten), liegt neben der Guide-Datei im
  privaten Repo (da er exakt deren — deutlich größere — Anforderungen
  prüft, nicht die tatsächlichen Build-Voraussetzungen des echten loomAI).
  Prüft `git`/`cmake`(>=3.20, >=3.28 empfohlen)/Compiler
  (clang++>=17 oder g++>=13)/`curl`/`python3`/`podman`(>=4.x) als
  Pflichtchecks (Exit-Code 1 bei Fehlschlag), `nvidia-smi`/`nvcc` nur
  informativ (GPU/CUDA optional). Live getestet (nicht nur geschrieben):
  zwei echte Windows-Quirks beim Testen gefunden und gefixt — `podman.EXE`
  echot seinen eigenen Dateinamen inkl. `.EXE` in `--version`, und ein
  neuerer `nvidia-smi`-Treiber (610.x) hat kein `Driver Version:`-Label
  mehr im Header, nur noch `NVIDIA-SMI <Version>`.
- **`loomAI/README.md` gesplittet**: bestehender deutscher Inhalt nach
  `README.de.md`, neue `README.md` als vollständige, eigenständige
  englische Übersetzung (GitHub-Konvention: `README.md` englisch als
  Default). Dabei zwei echte Fehler gefunden und gefixt: Intro behauptete
  `C++23`, tatsächlich baut `CMakeLists.txt` mit `C++17`; ein Verweis auf
  einen privaten, nicht-öffentlich erreichbaren Report-Pfad
  (`nvim/docs/ROADMAP/reports/loomai-ai-nvim-integration.md`, ohnehin
  längst veraltet, s. o. Folgesession 8) wurde durch einen Verweis auf
  `ai.nvim`s eigenen `loomai.lua`-Modul-Kommentar ersetzt. Außerdem
  ergänzt (vorher nirgends dokumentiert): Geminis Safety-Block-Erkennung +
  Modellname-Validierung (s. Folgesession 7), sowie der
  `svr.listen()`-Rückgabewert-Punkt (Nächste-Schritte-Punkt 8 oben) unter
  "Stand/was fehlt". Committet `b09c73e`, gepusht.

Alle drei Repos (`loomAI`, `WKDBooks`, `nvim`-Config) synchron mit
`origin/main`.

**Nachtrag, gleicher Themenkomplex, kurz danach:** der oben unter Punkt 8
("Nächste konkrete Schritte") genannte `svr.listen()`-Fund wurde auf
Nutzerwunsch gleich mit erledigt -- trivialer 3-Zeilen-Fix (`if
(!svr.listen(...)) { std::cerr << ...; return 1; }`), Syntax mit
`g++ -fsyntax-only` geprüft, committet `e3c025a`, README-Erwähnung unter
"Stand/was fehlt" danach wieder entfernt (war nur solange akkurat, wie der
Bug bestand), Commit `18c0589`. Beides gepusht.

---

## typepilot.nvim: Scoping-Entscheidung (2026-09-14, Folgesession 10)

Nutzer-Anfrage: Konzept-Datei `nvim/docs/ROADMAP/IDEAS/typepilot.nvim.md`
(dünne Provider-Abstraktion für Vervollständigung/Copilot-artige
Vorschläge) analysieren -- eigenes Plugin oder Feature in `ai.nvim`?

**Analyse, zwei getrennte Fragen:**
1. *Braucht es die Provider-Abstraktion neu?* Nein -- `ai.nvim`s
   `providers/{claude,openai,ollama,gemini}.lua` lösen exakt das (Setup +
   Prompt-in/Text-out), plus mehr, was die Notiz noch gar nicht bedacht
   hatte (sicheres Key-Handling über `secret_headers`, SSE-Streaming,
   Timeouts, `available()`). Ein Neubau würde diese Infrastruktur
   duplizieren.
2. *Wohin gehört Inline-Completion (Vorschläge beim Tippen)?* `ai.nvim`s
   eigenes `docs/scope.md` grenzt das explizit aus: *"single-turn
   question/answer and streaming for one plugin call or one editor
   action"*. Ein Vorschlag beim Tippen braucht Debounce/Idle-Trigger,
   Cancel-bei-nächstem-Tastendruck, Ghost-Text-Rendering statt
   Panel/Badge -- ein Merge in `ai.nvim` würde dessen eigene, bewusst enge
   Scope-Grenze verletzen (dieselbe "registry entry, not a merge"-Logik,
   mit der auch `loomAI` bewusst außerhalb gehalten wird).

**Erste Empfehlung (von mir, dann per Zwischenruf vom Nutzer korrigiert):**
ursprünglich hier vorgeschlagen: eigenes Plugin `typepilot.nvim` mit
`ai.nvim` als harter Abhängigkeit, analog zu `ai.nvim`s eigenem Verhältnis
zu `lib.nvim`. **Korrektur des Nutzers, noch in derselben Sitzung:** nein
-- Zielbild ist, `ai.nvim` langfristig zum **einzigen** AI-Plugin
auszubauen (keine mehreren nebeneinander installierten AI-Plugins), und
Completion-artige Vorschläge sind Teil dieses Zielbilds, nicht etwas, das
outgesourct werden soll, nur weil `docs/scope.md` heute so formuliert ist.

**Damit finale Entscheidung: Completion-Vorschläge werden eine neue
Capability *innerhalb* von `ai.nvim`, kein separates Repo.** Das bedeutet
konkret:

- `docs/scope.md` muss überarbeitet werden -- die heutige Formulierung
  ("single-turn question/answer and streaming for one plugin call or one
  editor action") schließt einen automatischen Trigger beim Tippen
  wörtlich aus. Die **eigentliche**, weiterhin gültige Grenze aus diesem
  Dokument ist etwas anderes und bleibt unangetastet: kein autonomer
  Multi-Step-Agent, keine Sandbox, kein Tool-Use/Function-Calling-Loop
  (das bleibt bei `loomAI`/dem Agent-Framework-Projekt). Ein
  Completion-Vorschlag ist technisch weiterhin derselbe Single-Turn-
  Ask/Stream-Aufruf -- nur eine zusätzliche *Trigger-Quelle*
  (Idle-beim-Tippen statt expliziter `:Ai`-Befehl) und ein zusätzlicher
  *Renderer* (Ghost-Text statt Panel/Badge). Die Neuformulierung sollte
  das explizit so einordnen, nicht die Agent/Sandbox-Grenze aufweichen.
- Architektonisch reiht sich das sauber neben die bestehenden Bausteine
  ein, keine Notwendigkeit, Provider-Registry oder Kern-API anzufassen --
  `require("ai").ask()`/`.stream()` bleiben die einzige Schnittstelle zum
  LLM, exakt wie bei jeder bestehenden Quick-Action.

**Konkrete Tasks (in `ai.nvim` selbst, neues Feature-Gebiet, noch nicht
begonnen), aus der Notiz übernommen und an die korrigierte Entscheidung
angepasst:**

1. `docs/scope.md` überarbeiten wie oben beschrieben, bevor Code entsteht
   -- Dokument muss die Richtung tragen, nicht ihr widersprechen.
2. Neues Trigger-Modul (Debounce/Idle beim Tippen, Cancel bei nächstem
   Tastendruck) -- `stream()` liefert ein `vim.SystemObj`, das dafür
   gehalten und bei Bedarf `:kill()`t werden muss, gleiches Muster wie
   `ai.nvim`s eigenes `ui/panel.lua` beim manuellen Cancel schon nutzt.
3. Neue Kontext-Extraktion (Text vor/nach Cursor) als Ergänzung zu
   `lua/ai/context/` -- das bestehende Modul kennt bisher nur
   Buffer/Selection/Diagnostics, keinen cursor-relativen Ausschnitt.
4. Neuer Renderer für Ghost-Text (`vim.api.nvim_buf_set_extmark` mit
   virtual text), als Geschwister-Modul zu `ui/panel.lua`/`ui/badge.lua`,
   nicht als deren Umbau.
5. Accept/Reject-Keymaps, analog zum bestehenden
   `bindings/actions.lua`+`bindings/keymaps.lua`-Muster.
6. `suggest()` selbst braucht keinen Extra-Aufwand für Asynchronität oder
   Timeout -- `require("ai").ask()`/`.stream()` sind bereits Callback-
   basiert asynchron, `req.timeout_ms` ist bereits Teil von `Ai.Request`.
7. `:Ai info`/`health.lua` um Completion-Status erweitern (aktiver
   Provider, Key vorhanden ja/nein -- nie der Key selbst), statt ein
   eigenes `:checkhealth typepilot` zu bauen.
8. Provider-Registrierung von außen ist bereits gelöst
   (`providers.register()`) -- kein neuer Mechanismus nötig.
9. Datenschutz-Prinzip aus der Notiz (kein zentrales Key-Storage, Keys aus
   Env) ist in `ai.nvim`s Providern bereits korrekt umgesetzt
   (`util.env_value()` liest `vim.env`, kein Keyring-Zugriff) -- gilt
   automatisch auch für die neue Capability.
10. **Separat, nicht `ai.nvim`-spezifisch**: die Notiz schlägt vor, das
    Datenschutz-Prinzip (Punkt 9) als allgemeine Regel in
    `personal/All/Checklists.md` festzuhalten, gültig für jedes Plugin mit
    API-Key-Kontakt (`reposcope.nvim`, `github_stats.nvim`, jetzt auch
    diese Capability) -- **diese Datei existiert noch nicht** (per `find`
    gegengeprüft), separat anzulegen, nicht Teil dieser Sitzung.
11. **Vor Implementierungsbeginn**: eigene Scoping-Sitzung für die
    konkrete Architektur (Modul-Zuschnitt, Debounce-Strategie,
    Ghost-Text-API-Details), analog zum loomAI-ModelRouter-Scoping oben --
    diese Sitzung hat nur die Grundsatzfrage geklärt und die Tasks grob
    skizziert, nicht die Feinarchitektur entschieden.
12. Offene Vorfrage, weiterhin unbeantwortet: ob es das überhaupt braucht,
    angesichts fertiger Plugins wie `copilot.lua`, `codeium.vim`,
    `supermaven-nvim`, `minuet-ai.nvim` (Letzteres macht bereits
    Multi-Provider-Completion gegen OpenAI/Claude/Gemini/Ollama,
    inhaltlich nah an der Notiz-Idee -- nicht live verifiziert). Bleibt
    trotz der jetzt gefallenen Scope-Entscheidung eine offene Frage, ob
    parallel geprüft werden soll, was diese Plugins bereits abdecken.

`typepilot.nvim.md` nach `ERLEDIGT/` verschoben (Grundsatzfrage geklärt,
kein aktiver Tracking-Zustand mehr -- die konkreten Tasks oben sind jetzt
hier die Quelle der Wahrheit für den Fortschritt, sobald diese Capability
begonnen wird).

---

