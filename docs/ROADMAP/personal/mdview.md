# `mdview.nvim`

## Table of content

  - [FINISH](#finish)
  - [Workflow Doc](#workflow-doc)
  - [mdview.nvim Rewrite: Go Relay + Rust/WASM Rendering](#mdviewnvim-rewrite-go-relay-rustwasm-rendering)
    - [Context](#context)
    - [Zielarchitektur](#zielarchitektur)
    - [Phase 1 — Rust/WASM Render+Sanitize-Modul](#phase-1-rustwasm-rendersanitize-modul)
    - [Phase 2 — Go Relay-Server](#phase-2-go-relay-server)
    - [Phase 3 — Client-Integration](#phase-3-client-integration)
    - [Phase 4 — Lua-Integration](#phase-4-lua-integration)
    - [Phase 5 — Build, CI & Distribution](#phase-5-build-ci-distribution)
    - [Nicht im Scope dieses Rewrites](#nicht-im-scope-dieses-rewrites)
    - [Verifikation](#verifikation)

---

## FINISH

- Alle features durchgehjen und die perform,anteste, ideale DEFAULT config zusammenstellen

---

## Workflow Doc

Szenario: In nvim eine markdown file offen, `MDViewStart`:
1. Was passiert dann genau?
2. Was passiert, damit die file das erste Mal im Browser aufgebaut wird?
3. Was  passiert, wenn sich die Datei ändert? Wie wird gesynced?

Welche Protkolle machen wann was?

---

## mdview.nvim Rewrite: Go Relay + Rust/WASM Rendering

---

### Context

mdview.nvim ist aktuell ein Node.js/TypeScript-Server, der Markdown serverseitig rendert (`markdown-it` mit `html: true`) und das Ergebnis roh via WebSocket an den Client schickt, der es ungefiltert per `innerHTML` einfügt ([main.ts:22](src/client/main.ts:22)). Das ist eine offene XSS-Lücke, der Server bindet auf alle Interfaces ([mdviewServer.ts:69](src/server/mdviewServer.ts:69)), es gibt kein Auth/Origin-Check, und Broadcasts gehen ungefiltert an alle verbundenen Clients statt pro Dokument. Das Projekt ist Alpha-Status ohne bestehende Nutzerbasis — ideal für einen Clean-Break-Rewrite statt inkrementeller Patches.

Ziel: **Rendering wandert client-seitig in ein Rust→WASM-Modul** (Rendering + Sanitisierung in einem Schritt, keine Serverbeteiligung mehr am HTML), der verbleibende Server wird ein **dünner Go-Relay** (Datei-Watch + WebSocket-Transport von Rohtext, kein HTML-Handling). Damit sinkt die Angriffsfläche strukturell (kein Rendering-Code mehr mit vollen Rechten auf dem Server-Prozess) und die Performance steigt (kein HTTP-Rendering-Roundtrip pro Tastendruck). Entschieden mit dem Nutzer: **Go** für den Relay (einfacher als Rust für diesen dünnen Layer), **Clean Break** (alter Node-Server wird komplett entfernt), **Prebuilt-Binary-Distribution** über GitHub Releases nach dem `mason.nvim`-Muster (keine Rust/Go-Toolchain beim Endnutzer nötig).

---

### Zielarchitektur

```
Neovim (Lua)
  │  uv.spawn(installierte Go-Binary)
  ▼
Go Relay-Server (native Binary, pro Plattform)
  - bindet nur an 127.0.0.1
  - fsnotify Datei-Watch
  - serviert statisches Client-Bundle (HTML/JS/WASM)
  - WebSocket: pro Dokument-Session eigener "Room", Origin-Check, Session-Token
  - schickt NUR Rohtext (kein HTML)
  ▼
Browser Client (schlankes TS + Rust/WASM-Modul)
  - empfängt Rohtext über WS
  - rendert + sanitisiert in einem WASM-Aufruf (comrak + ammonia, beides Rust-Crates)
  - schreibt NUR sanitisiertes HTML in innerHTML
```

---

### Phase 1 — Rust/WASM Render+Sanitize-Modul

- Neues Cargo-Workspace-Mitglied `native/wasm-render/` (Rust, `crate-type = ["cdylib"]`, Target `wasm32-unknown-unknown`, Build via `wasm-pack`).
- Eine exportierte Funktion `render_markdown(input: &str) -> String`: rendert mit `comrak` (GFM-kompatibel: Tabellen, Strikethrough, Autolinks — Funktionsparität zu bisherigem `markdown-it`), pipet Ergebnis durch `ammonia::clean()` (whitelist-basierte HTML-Sanitisierung, läuft auch unter `wasm32`). Rohes `<script>`/Event-Handler-HTML wird hier hart entfernt, nicht nur escaped.
- `cargo test` deckt Rendering-Fälle (Headings, Codeblöcke, Tabellen, Links) und gezielt XSS-Payloads ab (`<script>`, `onerror=`, `javascript:`-URLs müssen nach `render_markdown` verschwunden sein).
- Output: `wasm-pack build --target web` erzeugt `pkg/` (JS-Glue + `.wasm`), das direkt von Vite eingebunden wird (Vite unterstützt WASM-Assets nativ).

---

### Phase 2 — Go Relay-Server

- Neues Verzeichnis `native/server/` (Go-Modul, `go.mod` mit Modulname passend zum Repo).
- Abhängigkeiten: `github.com/fsnotify/fsnotify` (Datei-Watch, ersetzt `chokidar`), `github.com/coder/websocket` oder `github.com/gorilla/websocket` (WS), Standardbibliothek `net/http` für HTTP/statisches Serving.
- Verantwortlichkeiten (bewusst NICHT: Rendering, NICHT: HTML-Handling):
  - `http.Server` bindet explizit auf `127.0.0.1:<port>` (ersetzt das ungebundene `listen()` aus [mdviewServer.ts:69](src/server/mdviewServer.ts:69)).
  - Statisches Serven von `dist/client` (Nachfolger von [static.ts](src/server/static.ts), inkl. korrektem `Content-Type` für `.wasm`).
  - Port-Auswahl mit Fallback (Äquivalent zu `get-port`): freien Port ab Wunschport suchen, an stdout ausgeben im bestehenden Format `Running on http://localhost:<port>` — das Lua-Pattern-Matching in [runner.lua:148](lua/mdview/adapter/runner.lua:148) bleibt dadurch unverändert funktionsfähig.
  - Pro Dokument (`key`, z. B. absoluter Pfad) ein eigener WS-"Room": Clients abonnieren einen Key beim Connect; Broadcasts gehen nur an Clients desselben Keys (behebt Cross-Contamination-Bug aus Roadmap Bonus-Punkt 5).
  - **Sicherheit:** Origin-Header-Check gegen `http://localhost:<port>` beim WS-Upgrade; Session-Token (von Lua beim Start generiert, per Query-Param an Browser-URL und WS-Handshake übergeben, serverseitig geprüft) gegen fremde Prozesse/DNS-Rebinding.
  - Kein `/render`-Endpoint mehr (entfällt komplett — Rendering passiert nur noch im Client). Server transportiert Rohtext-Updates, die Lua bei Buffer-Änderungen sendet.
- Go-Tests (`testing`-Package, table-driven) für: Port-Fallback-Logik, Room-Zuordnung, Origin-Check-Ablehnung, Token-Validierung.

---

### Phase 3 — Client-Integration

- [main.ts](src/client/main.ts) verschlankt sich: WS-Nachricht mit Rohtext → `render_markdown(text)` aus dem WASM-Modul aufrufen → Ergebnis in `container.innerHTML` (jetzt sicher, da bereits sanitisiert).
- Bestehende Transport-Abstraktion ([transport.interface.ts](src/client/transport/transport.interface.ts), [transportFactory.ts](src/client/transport/transportFactory.ts)) bleibt erhalten und wird weiterverwendet — gutes Pattern, nur `websocket.transport.ts` wird benötigt.
- **Scope-Entscheidung:** `webtransport.transport.ts` und der `DEV_USE_WEBTRANSPORT`-Flag werden entfernt. Für einen reinen Loopback-Tool bringt WebTransport/HTTP3 keinen Mehrwert, erzwingt aber TLS-Zertifikatshandling auch für `localhost` (siehe bereits vorhandene Machbarkeitsnotizen in `doc/Roadmap/WebTransportAPI/`). WebSocket bleibt der einzige Transport.
- Server schickt bei Bedarf weiterhin volle Datei-Inhalte statt Line-Diffs (die Diff-Logik in [session.lua](lua/mdview/core/session.lua) kann später als Bandbreiten-Optimierung reaktiviert werden, ist aber kein Blocker für den Rewrite).

---

### Phase 4 — Lua-Integration

- [runner.lua](lua/mdview/adapter/runner.lua): `M.start_server` bekommt einen neuen Default-Aufrufpfad: statt `cmd="npm"` wird die Binary aus dem lokalen Cache-Verzeichnis gestartet (kein `npm`-Sonderfall, keine `package.json`-Prüfung mehr nötig — dieser Code-Pfad in [runner.lua:67-82](lua/mdview/adapter/runner.lua:67) entfällt).
- Neues Modul `lua/mdview/adapter/install.lua`:
  - Prüft `vim.fn.stdpath("data") .. "/mdview/bin/<version>/mdview-server[.exe]"`.
  - Fehlt die Binary: Download des passenden Release-Assets (Plattform/Arch aus `jit.os`/`vim.uv.os_uname()` ableiten) via `vim.system({"curl", ...})` oder `plenary.curl`, falls Abhängigkeit gewünscht.
  - SHA256-Checksum-Verifikation gegen einen im Release mitgelieferten `checksums.txt`, **bevor** die Binary ausführbar gemacht/gestartet wird.
  - Auf Unix: `chmod +x` nach Verifikation.
- `get_exec.lua` verliert den `npm`→`npm.cmd`-Sonderfall (nicht mehr gebraucht) oder wird ganz entfernt, falls keine andere Nutzung existiert.
- Session-Token-Erzeugung (z. B. `vim.fn.sha256(tostring(os.time()) .. path)`) in Lua, Übergabe an Server-Spawn (Env-Var oder CLI-Arg) und an die Browser-URL, die geöffnet wird.

---

### Phase 5 — Build, CI & Distribution

- `native/server/`: GoReleaser-Konfiguration (`.goreleaser.yml`) für Cross-Compile-Matrix (linux/darwin/windows × amd64/arm64), Ausgabe als GitHub-Release-Assets inkl. `checksums.txt`.
- `native/wasm-render/`: Build-Schritt (`wasm-pack build --release`) wird Teil von `npm run build:client` (Vite bindet das erzeugte `pkg/` ein) bzw. eines neuen Root-Scripts, das Rust vor dem Vite-Build baut.
- [ci.yml](.github/workflows/ci.yml) erweitern um:
  - Go-Job: `go build ./...`, `go vet`, `go test ./...`.
  - Rust-Job: `cargo test`, `wasm-pack build` als Smoke-Test.
  - Bestehender Node-Job schrumpft auf reines Client-Bundling (kein Server-Build/Test mehr, da `src/server` entfällt).
  - Neuer Release-Job (nur bei Tags): GoReleaser + Upload der WASM/Client-Assets.
- Entfernen: `src/server/` komplett (index.ts, mdviewServer.ts, mdviewServer.debounce.ts, render.ts, static.ts), zugehörige `tests/server/`, `tsconfig.server.json`, Node-Server-Dependencies aus `package.json` (`express`, `get-port`, `ws`, `markdown-it`, `markdown-it-anchor`, `micromatch`, `chokidar`, `nodemon`).

---

### Nicht im Scope dieses Rewrites

- Bidirektionales Scrolling, Multi-CWD-Hosting, Session-Handling bei mehreren Dateien (bestehende Roadmap-Punkte) — bleiben offene Folge-Tasks, sind von der Architekturumstellung unabhängig.
- Line-Diff-Optimierung (volle Datei-Übertragung reicht für den Rewrite; bereits vorhandene `session.lua`-Diff-Logik kann später angeschlossen werden).

---

### Verifikation

- `cargo test` im WASM-Crate: Rendering-Korrektheit + gezielte XSS-Payload-Tests (nach `render_markdown` darf kein `<script>`, `onerror=`, `javascript:` mehr im Output sein).
- `go test ./...` im Relay-Modul: Port-Fallback, Room-Isolation (zwei Clients mit unterschiedlichem Key sehen sich nicht gegenseitige Broadcasts), Origin-/Token-Ablehnung.
- End-to-End manuell: Neovim starten, `:MDViewStart` auf einer Markdown-Datei mit eingebettetem `<script>alert(1)</script>` — Browser darf den Alert NICHT auslösen, Inhalt muss trotzdem sichtbar rendern (escaped oder entfernt je nach Ammonia-Whitelist).
- Zwei Dateien gleichzeitig öffnen, in beiden tippen, prüfen dass Updates nicht cross-kontaminieren.
- `npm run build` (neuer, verschlankter Client-Build) + manueller Start der Go-Binary lokal, bevor die Release-Pipeline verifiziert wird.
---
