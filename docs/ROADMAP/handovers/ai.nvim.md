# ai.nvim — Implementierungsplan & Handover

> Ausnahme-Standort: normalerweise leben Plugin-Roadmaps im Wkdbook
> (`wkdbook-myplugins/<plugin>/ROADMAP/ROADMAP.md`, siehe `NEW-14`). Diese
> Datei hier ist explizit angefordert als laufende Handover-Akte für die
> *Neuanlage* von `ai.nvim` und bleibt an diesem Ort
> (`nvim/docs/ROADMAP/handovers/`), nicht im Wkdbook.

## Table of content

  - [Regeln für diese Session](#regeln-fr-diese-session)
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

## Nächste konkrete Schritte (Stand jetzt, 2026-09-14)

Phasen 0-8 erledigt, Code-Review durchgelaufen (9/10 Findings gefixt), `lib.nvim`-CI
komplett grün (inkl. `publish-ci-verified`), `ai.nvim`-CI grün, `doc/ai.txt`
nachgetragen. Alle Repos (`ai.nvim`, `lib.nvim`, `nvim`-Config, `WKDBooks`) committet
und gepusht, synchron mit `origin/main`. Offen:

1. `ai.nvim` im Alltag benutzen (`<leader>ai{a,s,e}`), um v1 vor einem Tag zu validieren
   — der einzige noch offene Schritt, der sich nicht durch eine Sitzung ersetzen lässt.
2. Phase 10 (`gates/RELEASE.md`) vor dem ersten Tag/Release, danach.
3. Phase 9 (Follow-up, nicht blockierend): `pdfport.nvim`-Migration, `loomai`-Provider
   sobald verfügbar (Trigger-Check bei jeder Wiederaufnahme, s.o.).
4. `ui/panel.lua`s Voll-Buffer-`set_lines()` pro Stream-Chunk (Review-Finding, bewusst
   nicht gefixt) — nur angehen, falls in der Praxis spürbar.
5. Diese Datei laufend als Statusprotokoll fortschreiben.

---

