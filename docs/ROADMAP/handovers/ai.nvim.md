# ai.nvim — Implementierungsplan & Handover

> Ausnahme-Standort: normalerweise leben Plugin-Roadmaps im Wkdbook
> (`wkdbook-myplugins/<plugin>/ROADMAP/ROADMAP.md`, siehe `NEW-14`). Diese
> Datei hier ist explizit angefordert als laufende Handover-Akte für die
> *Neuanlage* von `ai.nvim` und bleibt an diesem Ort
> (`nvim/docs/ROADMAP/handovers/`), nicht im Wkdbook.

## Table of content

  - [Regeln für diese Session](#regeln-fr-diese-session)
  - [Status (Stand: dieser Sitzung, vor Weiterarbeit hier angehalten)](#status-stand-dieser-sitzung-vor-weiterarbeit-hier-angehalten)
  - [Orte](#orte)
  - [Architektur (aus dem Konzept übernommen)](#architektur-aus-dem-konzept-bernommen)
  - [Real geprüfter Ist-Stand der Bausteine (nicht aus dem Konzept übernommen, sondern nachgesehen)](#real-geprfter-ist-stand-der-bausteine-nicht-aus-dem-konzept-bernommen-sondern-nachgesehen)
  - [loomAI: Entscheidung & Fallback (Kernpunkt der Aufgabenstellung)](#loomai-entscheidung-fallback-kernpunkt-der-aufgabenstellung)
  - [Phasenplan](#phasenplan)
    - [Phase 0 — Setup ✅ (diese Sitzung)](#phase-0-setup-diese-sitzung)
    - [Phase 1 — Transport-Erweiterung in `lib.nvim`](#phase-1-transport-erweiterung-in-libnvim)
    - [Phase 2 — `ai.nvim` Scaffold (`NEW_PROJECT.md`, `NEW-01`…`NEW-50`)](#phase-2-ainvim-scaffold-new_projectmd-new-01new-50)
    - [Phase 3 — Provider-Registry (`lua/ai/providers/`)](#phase-3-provider-registry-luaaiproviders)
    - [Phase 4 — Kontext-Assemblierung (`lua/ai/context/`)](#phase-4-kontext-assemblierung-luaaicontext)
    - [Phase 5 — UI (`lua/ai/ui/`)](#phase-5-ui-luaaiui)
    - [Phase 6 — Public API + `:Ai`-Composer](#phase-6-public-api-ai-composer)
    - [Phase 7 — Quick-Actions ("neue Idee" im Konzept)](#phase-7-quick-actions-neue-idee-im-konzept)
    - [Phase 8 — Wiring in nvim-config](#phase-8-wiring-in-nvim-config)
    - [Phase 9 — Follow-up (entkoppelt von v1, NICHT blockierend)](#phase-9-follow-up-entkoppelt-von-v1-nicht-blockierend)
    - [Phase 10 — `gates/RELEASE.md` vor einem ersten Tag/Release](#phase-10-gatesreleasemd-vor-einem-ersten-tagrelease)
  - [Nächste konkrete Schritte (Stand jetzt)](#nchste-konkrete-schritte-stand-jetzt)

---

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

## Status (Stand: dieser Sitzung, vor Weiterarbeit hier angehalten)

**Fertig und verifiziert (echte Tests, keine Annahmen):**

- `lib.nvim`: `fetch_stream` + `secret_headers` in `lua/lib/nvim/net/curl/init.lua`
  gebaut, inkl. `-N`/`--no-buffer`-Fix (curl puffert stdout sonst komplett, bis der
  Prozess endet — hätte Streaming unbrauchbar gemacht). Tests in `TESTS/curl_spec.lua`
  (echter `vim.uv`-TCP-Server, kein Mock) — u. a. Zeilen-für-Zeile-Delivery inkl.
  Leerzeilen, `secret_headers` erreicht die Leitung, `process:kill()` bricht einen
  laufenden Stream wirklich ab. Komplette Suite grün (`LIB_TESTS_OK`), luacheck/stylua
  grün. **Committet + gepusht auf `lib.nvim` main** (`5364c02`).
- `ai.nvim`-Repo angelegt (`github.com/StefanBartl/ai.nvim`, public, lokal
  `E:\repos\ai.nvim`), Branch `main` — **noch nicht gepusht** (siehe „Nächster Schritt").
  Vollständiges Scaffold nach `NEW_PROJECT.md`: `.luarc.json`/`.luacheckrc`/
  `stylua.toml`/`.gitattributes`/`LICENSE`(MIT)/CI-Workflow/`TESTS/`+Runner.
  Kern-Implementierung (nicht nur Gerüst): `lua/ai/{config,@types,providers/{init,
  claude,ollama,openai},context/{init,diagnostics},ui/{panel,badge},bindings/{keymaps,
  usercmds,autocmds,actions},health,init}`, `plugin/ai.lua`.
  - Provider-Registry (Lazy-Proxy wie `pdfport.nvim/backends`), `claude`/`ollama`/`openai`
    real implementiert (kein `loomai` — bewusst, siehe unten).
  - **Echter End-to-End-Test gegen die lebende OpenAI-API** (in dieser Session
    vorhandener `OPENAI_API_KEY`, ungültiger Testschlüssel reicht für den Zweck):
    dabei einen **echten Bug gefunden und gefixt** — eine Auth-Fehlerantwort auf
    einen Streaming-Request kommt NICHT als SSE-Event, sondern als
    mehrzeiliges, pretty-printed JSON, curl selbst beendet sich trotzdem mit
    Code 0. Naive `data:`-Zeilenerkennung verschluckte das still (leerer
    „Erfolg" statt Fehler) — genau die Fehlerklasse, die dieses Projekt beheben
    soll. Fix in `claude.lua`+`openai.lua`: Nicht-`data:`-Zeilen werden
    gesammelt und am Streamende als ein JSON-Block geparst. Nach dem Fix mit
    echtem API-Call verifiziert: `on_error` feuert korrekt, `on_done` nicht mehr
    fälschlich.
  - Quick-Actions aus dem Konzept umgesetzt: `<leader>as` (Kontext + Task,
    gestreamt), `<leader>ae` (Badge/Post-it, kein Panel), `<leader>aa` (Ask).
  - Streaming-Cancel-Frage aus dem Konzept **verbindlich gelöst**: `ai.ui.panel`
    hält den `vim.SystemObj`, killt ihn bei explizitem Cancel UND beim Schließen
    des Panels UND bei `VimLeavePre` (`bindings/autocmds.lua`).
  - Tests: `TESTS/ai/{config,providers,context}_spec.lua`, 19 Tests, alle grün
    (echter plenary-Lauf gegen `E:\repos\lib.nvim` + `nvim-data/lazy/plenary.nvim`).
    luacheck (0/0) und stylua grün.
  - Docs geschrieben: `README.md` (Fassung-3-Template, ASCII-Art mit pyfiglet
    gegengeprüft), `docs/{README,requirements,installation,quickstart,
    configuration,commands,BINDINGS,scope,architecture,health}.md`.
- Wkdbook: `wkdbook-myplugins/ai.nvim/{ROADMAP/ROADMAP.md,NOTES/loomai-integration.md}`
  angelegt, committet + gepusht (WKDBooks main, `3da43bf`).

**Noch offen (bewusst hier gestoppt, nicht abgebrochen):**

- [ ] `ai.nvim` initial committen + auf `github.com/StefanBartl/ai.nvim` main pushen
      (bisher nur lokal, noch kein einziger Commit im Repo).
- [ ] `doc/ai.txt` (Vimdoc, `NEW-13`) — noch nicht geschrieben.
- [ ] Phase 8 — Wiring in `nvim-config`: `plugins/personal/source.lua`
      (`MODE["ai.nvim"] = "dir"`) + `plugins/personal/init.lua` (Lazy-Spec). Vor
      Vergabe von `<leader>a*` bestehende Belegung gegenprüfen (`LUA-95`) — **noch
      nicht geprüft**.
- [ ] `gates/REVIEW.md`-Schnell-Check einmal drüberlaufen lassen, bevor as Wiring
      erfolgt.
- Phase 9/10 (loomai-Provider, pdfport.nvim-Migration) bleiben wie geplant
  zurückgestellt, siehe Wkdbook-ROADMAP.

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

---

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

---

### Phase 3 — Provider-Registry (`lua/ai/providers/`) ✅
Lazy-Proxy-Registry nach `pdfport.nvim/backends/init.lua`-Muster, implementiert und getestet
(`TESTS/ai/providers_spec.lua`, 10 Tests grün): `claude.lua`, `ollama.lua`, `openai.lua`,
`init.lua` (Registry + `resolve()` mit fester `auto`-Chain). `loomai` bewusst NICHT enthalten
(s.o., Trigger-Bedingung unverändert offen).

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

### Phase 8 — Wiring in nvim-config ❌ noch offen
**Kollision geprüft und BESTÄTIGT, vor dem Wiring zu lösen:**
`nvim/lua/config/ai/anthropic/init.lua` belegt bereits `<leader>aa` (ask), `<leader>ae`
(edit), `<leader>ar` (refresh), `<leader>af` (focus), `<leader>as` (stop) — ein Ad-hoc-
Anthropic-Setup von vor `ai.nvim`. `ai.nvim`s Default-Prefix `<leader>a` kollidiert direkt
auf `aa`/`ae`/`as` (siehe Phase 7). Vor dem Wiring in `plugins/personal/{source,init}.lua`
entscheiden:
  - (a) `config/ai/anthropic` ablösen/entfernen, sobald `ai.nvim` produktiv ist (vermutlich
    genau der Vorgänger, den `ai.nvim` ersetzen soll — gegenchecken, ob das zutrifft), oder
  - (b) `ai.nvim`s `keymaps.prefix` in der Lazy-Spec auf einen anderen Präfix legen
    (z. B. `<leader>ai` o.ä.).
Noch nicht umgesetzt: `plugins/personal/source.lua` (`MODE["ai.nvim"] = "dir"`),
`plugins/personal/init.lua` (Lazy-Spec + `dependencies = {"StefanBartl/lib.nvim"}`).

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
Noch nicht begonnen — erst nach Phase 8 (Wiring, damit v1 tatsächlich im Alltag benutzt
wurde, bevor getaggt wird).

## Nächste konkrete Schritte (Stand jetzt, 2026-09-14)

Phasen 0-7 sind erledigt, committet (`b77d014`, `f2ebe38`) und auf `origin/main` gepusht,
CI grün. Offen:

1. **Phase 8 — Kollisionsentscheidung zuerst**: `config/ai/anthropic` (nvim-config) vs.
   `ai.nvim`-Default-Prefix `<leader>a` klären (ablösen oder Prefix verschieben, s.o.),
   dann `plugins/personal/{source,init}.lua` wiring.
2. Danach `ai.nvim` im Alltag benutzen, um v1 vor einem Tag zu validieren.
3. Phase 10 (`gates/RELEASE.md`) vor dem ersten Tag/Release.
4. Phase 9 (Follow-up, nicht blockierend): `pdfport.nvim`-Migration, `loomai`-Provider
   sobald verfügbar (Trigger-Check bei jeder Wiederaufnahme, s.o.).
5. Kleinigkeit: `wkdbook-myplugins/ai.nvim/ROADMAP/ROADMAP.md` — den Backlog-Eintrag zur
   zweiten Keymap-Variante ("noice-artiges Badge") streichen, ist mit `explain`
   (Phase 7) bereits umgesetzt.
6. Diese Datei laufend als Statusprotokoll fortschreiben.

---

