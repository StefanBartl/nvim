# Handover: tasks-desktop P2, Paket 2 (axum-Server und Sicherheit)

**Stand 2026-10-11, Abend.** Paket 1 (Fundament) ist fertig, reviewt und gepusht. Dieses Dokument
übergibt Paket 2 an einen neuen Chat. Es ist so geschrieben, dass der neue Chat nichts aus dem
bisherigen Verlauf braucht.

## 0. Start-Prompt für den neuen Chat

> Lies zuerst `E:\repos\WKDBooks\Development\wkdbook-myplugins\wkdbook-tasks.nvim\handovers\tasks-desktop-p2-paket2_HANDOVER.md`
> komplett (Original: `C:\Users\bartl\AppData\Local\nvim\docs\ROADMAP\handovers\tasks-desktop-p2-paket2_HANDOVER.md`).
> Arbeitsordner ist `E:\repos\tasks-desktop`. Mach Paket 2 von P2 (Task
> `wkdbook-tasks.nvim/tasks-app-hub-kern-und-lese-ui`): zuerst die Security-Tests, dann axum-Server,
> Auth und Pairing, `hello`. Baue **keinen** Datenendpunkt, bevor das Review-Gate (Abschnitt 8)
> bestanden ist. Antworte auf Deutsch, Code und Kommentare auf Englisch.

## 1. Auftrag in einem Absatz

Ein lokaler HTTP-Server (Rust, axum) im Crate `tasks-hub`, der nur auf Loopback lauscht, jede
Anfrage gegen Host, Origin und Token prüft und genau zwei Dinge ohne Token ausliefert: die
App-Shell-Statik (noch leer) und `GET /api/tasks/hello`. Ein Pairing-Code kommt nur über einen
lokalen Kanal des Betriebssystems, ist einmal verwendbar, höchstens 60 s gültig und wird per
`POST /auth/exchange` gegen ein Session-Token getauscht. **Es gibt in Paket 2 keinen Endpunkt, der
Task-Daten liefert.** Die Datenendpunkte kommen in Paket 3, nach dem Review-Gate.

Aufwandsschätzung: 2,5 Arbeitstage (Vermutung).

## 2. Was schon steht (Repo `E:\repos\tasks-desktop`, Remote `StefanBartl/tasks-desktop`, privat)

HEAD ist `d312f8a` auf `main`. 43 Tests grün, Clippy mit `-D warnings`, rustfmt sauber.

```
crates/app-core/       Tauri- und tasks-freie Bausteine (hier gehört authn, sse, registry, pathguard hin)
  src/proc.rs          Kindprozess: leere Umgebung, begrenzte Ausgabe, Watchdog (ein Zeitrahmen)
crates/tasks-hub/      lib + bin `tasks-hub`
  src/config.rs        Env, Source/Resolved, FileConfig (+validate), config_dir, load_file
  src/discovery.rs     discover() -> Setup | SetupProblem; Neovim-Probe, Engine-/lib.nvim-Suche
  src/engine/mod.rs    Method, Reply, EngineError, trait Engine, child_env, probe
  src/engine/cli.rs    CliEngine (eine Anfrage in Flug, Queue, Watchdog, Env-Allowlist)
  src/engine/wire.rs   ascii_json (siehe Falle 1)
  src/main.rs          nur `println!(version)` -> hier kommen `serve` und `open` hin
crates/hub-testkit/    fake-nvim (Binary) + Tests: tests/cli_engine.rs, tests/real_engine.rs
e2e/fixture/vault      synthetischer Vault, byte-genau (-text), `tools/make-fixture-vault.lua`
engine.lock            pinnt tasks.nvim (c4f1d11) und lib.nvim (a54108b)
.github/workflows/ci.yml   Windows, Actions per SHA gepinnt (ungetestet, siehe Abschnitt 9)
```

Öffentliche Schnittstellen, die Paket 2 benutzt:

- `tasks_hub::config::{Env, FileConfig, config_dir, load_file}`: `Env::from_process()`, `env.get("X")`
  liefert nur gesetzte, nicht leere Variablen (auf Windows ohne Beachtung der Groß-/Kleinschreibung).
- `tasks_hub::discovery::discover(&FileConfig, &Env).await -> Result<Setup, SetupProblem>`;
  `Setup.vault/nvim/engine_dir/lib_dir` sind `Resolved<PathBuf>` mit `Source` (für die Setup-Seite).
- `tasks_hub::engine::{Engine, CliEngine, CliEngineConfig::from_setup(&setup, env), Method, Reply,
  EngineError, probe}`. `Engine::call(method, Option<&Value>)`; `CliEngine::queued()`.
- `app_core::proc::{run, Spec, Output, ProcError}`.
- `EngineError` kennt: `Refused{code,message,retryable,text}` (die Engine hat ein `tasks.error`
  geschickt), `BadRequest`, `Busy`, `Timeout`, `Spawn`, `Process`, `Failed`, `Protocol`,
  `OutcomeUnknown` (nur Writes, der Aufrufer muss neu lesen).

Das Workspace verbietet `unsafe` (`unsafe_code = "forbid"`). Das ist wichtig für die Wahl der
Krypto-/Zufalls-Crates und für Named Pipes (siehe 4.3).

## 3. Verbindliche Beschlüsse (nicht neu verhandeln)

Quelle ist das Konzept `E:\repos\WKDBooks\Development\wkdbook-myplugins\ALL\Tasks-App-Konzept-WebUI-und-Native-2026-10-10.md`,
Abschnitt 13.0 (Beschlüsse) und 5 (Sicherheit).

| Thema | Beschluss |
|---|---|
| Auth | Bearer-Token mit Pairing-Fragment (13.10). Niemals ohne Token. |
| Name | Repo und Arbeitsname `tasks-desktop`, Config-Ordner `tasks-desktop`. Die Task-Slugs `tasks-app-*` bleiben (stabile IDs). |
| Eigenständig | App ist eigenständig und klein (13.18), kein Panel-Modell in P2. |
| Datenklassen | fail-closed, `areas.json` pro Gerät (Paket 3, nicht Paket 2). |
| Engine | einzige Schreibinstanz; der Hub parst keine Frontmatter. |
| KI | nur mit API-Key (nie Abo-Login); in Paket 2 irrelevant. |
| Plattform | Windows zuerst, Linux im CI ab P7, macOS nicht versprechen. |

## 4. Was Paket 2 liefern muss

### 4.1 Pflichtenheft des Servers (Konzept 5.5, Wortlaut sinngemäß)

1. Bind nur `127.0.0.1` (optional `[::1]`), nie `0.0.0.0`.
2. `Host`-Header gegen exakte Allowlist (`127.0.0.1:PORT`, `localhost:PORT`, `[::1]:PORT`), sonst
   403. Exakter Stringvergleich, keine Regex. PORT ist der tatsächlich gebundene Port.
3. Bei jedem Nicht-GET `Origin` exakt prüfen; fehlend oder `null` ablehnen. Bei Same-Origin-GET
   (auch SSE per `fetch`) sendet der Browser keinen `Origin`: dort `Sec-Fetch-Site` nur
   `same-origin` oder `none` verlangen; fehlt der Header, gilt ausschließlich das Bearer-Token und
   `Origin` wird nur geprüft, wenn er vorhanden ist. Zwei Client-Klassen: Browser (Token plus
   Origin/Sec-Fetch-Site) und Programm-Clients (curl, Agenten, `tasks-hub`-CLI: Token, kein Origin,
   kein CORS, kein Cookie). Beide sind im Security-Test abgedeckt.
4. Mutationen nur `POST` mit `Content-Type: application/json` (löst Preflight aus), nie per GET;
   kein CORS, nie `*`.
5. Kein Datenendpunkt ohne Session, auch nicht SSE. Ausnahmen: App-Shell-Statik und
   `GET /api/tasks/hello` (nur Version und Fähigkeiten, keine Daten). Token 256 Bit pro Start,
   konstantzeitiger Vergleich, nie in URL-Query oder Logs.
6. Antwort-Header: `X-Content-Type-Options: nosniff`, `Referrer-Policy: no-referrer`,
   `Cache-Control: no-store` für die API. Die vollständige CSP mit Trusted Types ist Paket 6.
7. Limits: Request-Zeile und Header 8 KiB, Body 1 MiB, Batch 100 Ops, Lese-/Schreibtimeouts,
   Verbindungslimit, Rate-Limit für Mutationen.
8. Routen und Engine-Argumente nur über Whitelist (`Method::parse`); IDs nur `<area>/<slug>`.
9. Keine Settings-Endpunkte für ausführbare Werte (Editor, nvim-Pfad, Plugin-Pfad).
10. Fester Standardport mit Override und Fallback, Registry-Datei, Single-Instance.
11. Engine-Kindprozess mit Umgebungs-Allowlist: schon erledigt in Paket 1 (`child_env`).

### 4.2 Token-Fluss und Pairing (Konzept 3.3 Bootstrap und 5.6)

- Pairing-Code im URL-Fragment (geht nie an Server oder Referrer), `POST /auth/exchange`,
  Session-Token im Speicher oder `sessionStorage` des Tabs.
- Einmalverwendung, TTL höchstens 60 s, nach dem Tausch sofort ungültig. Fragment per
  `history.replaceState` entfernen (UI, Paket 5). Ein Pairing wird **nie** über einen offenen
  HTTP-Endpunkt ausgegeben, nur über einen lokalen Kanal mit Betriebssystem-Rechten.
- Fester Standardport, weil die Origin (Schema, Host, Port) Speicher- und PWA-Identität ist.
  Registry-Datei `<config>/tasks-desktop/hub.json` mit Port, PID, Version, Manifest-URL, **ohne
  Token**. Genau ein Hub je Maschine und Vault.
- SSE: höchstens 4 Streams je Token (429 darüber), erstes Event `hello {rev, seq}`, Heartbeat 15 s.
  Der SSE-Aufbau selbst kommt mit Paket 4, die Route darf in Paket 2 noch fehlen, der
  Same-Origin-Test ohne `Origin`-Header gehört aber zu den Paket-2-Tests.

### 4.3 Offene Designentscheidung: der lokale Kanal für das Pairing

Das Konzept lässt drei Wege offen ("Named Pipe oder Unix-Socket des Hubs, oder eine Datei mit
Benutzer-ACL in der Config"). **Das ist die einzige echte Weichenstellung in Paket 2.**
Randbedingung: `unsafe` ist verboten, also keine eigenen Windows-Security-Attributes.

Mein Vorschlag (nicht bindend, aber begründet):

- Der laufende Hub legt beim Start eine **Control-Datei** `<config>/tasks-desktop/control.secret`
  an (256 Bit, Hex), nur der Benutzer darf sie lesen (Unix: Modus 0600 beim Anlegen; Windows:
  `%APPDATA%` vererbt eine Benutzer-ACL, im Test prüfen und in der Doku benennen).
- `tasks-hub open` liest die Datei und ruft `POST /api/control/pair` mit dem Secret auf (nur
  Programm-Client-Klasse, kein `Origin`). Der Hub antwortet mit einem Pairing-Code (einmal, 60 s)
  und die URL `http://127.0.0.1:PORT/#pair=<code>` wird geöffnet oder gedruckt.
- Das Control-Secret ist ein **anderes** Geheimnis als jedes Session-Token und gibt keinen Zugriff
  auf Daten, nur auf "Pairing ausgeben".
- Restrisiko, das in `docs/SECURITY.md` stehen muss: andere Prozesse desselben Benutzers sind laut
  Bedrohungsmodell T2 ausdrücklich nicht abgedeckt.

Verworfen oder nachrangig: Named Pipe (`tokio::net::windows::named_pipe` gibt keine ACL-Kontrolle
ohne `unsafe`), Pairing im Terminal des Hubs ausgeben (taugt für `serve` im Vordergrund, nicht für
Autostart und Tray).

Wenn der neue Chat anders entscheidet, gehört die Begründung in `docs/SECURITY.md` und in den
P2-Task.

## 5. Reihenfolge und Testliste (Test-first)

Die Tests entstehen **vor** den Routen. Sie gehören nach `crates/hub-testkit/tests/security.rs`.

**Wichtig:** Für Host-, Origin-, Request-Zeilen- und Body-Tests keinen High-Level-HTTP-Client
verwenden, der normalisiert (er würde `Host`, Header-Länge und Content-Type "reparieren"). Rohe
Requests über `tokio::net::TcpStream` schreiben (tokio ist schon Abhängigkeit, kein neuer Client).

Mindestens diese Tests, jeder gegen einen echten, auf Port 0 gebundenen Server:

| # | Test | Erwartung |
|---|---|---|
| 1 | Falscher `Host` (`evil.example`, `127.0.0.1` ohne Port, `127.0.0.1:1`, `0x7f.1`, `127.0.0.1.evil`) | 403 |
| 2 | `localhost:PORT`, `127.0.0.1:PORT`, `[::1]:PORT` | werden angenommen |
| 3 | POST mit `Origin: null`, ohne `Origin`, mit fremdem `Origin` | 403 |
| 4 | Fehlendes oder falsches Token auf jeder Datenroute | 401 |
| 5 | GET auf Datenroute ohne Session | 401 |
| 6 | POST mit `Content-Type: text/plain` und `application/x-www-form-urlencoded` | 415 |
| 7 | Body 2 MiB | 413, Verbindung bleibt nutzbar oder wird sauber geschlossen |
| 8 | Überlange Request-Zeile (> 8 KiB) und überlange Header | 414 oder 431, kein Absturz |
| 9 | `hello` ohne Token | 200, enthält **keine** Task-Daten, keinen Vault-Namen, keinen Pfad |
| 10 | App-Shell-Statik ohne Token | 200 |
| 11 | Pairing: Code einmal verwendbar, zweiter Tausch scheitert | 200, dann 401 |
| 12 | Pairing: Code nach TTL (Test mit kurzer, injizierbarer TTL) | 401 |
| 13 | Pairing: Code per HTTP **nicht** abrufbar (kein offener Endpunkt gibt einen aus) | alle Wege 401/404 |
| 14 | Control-Secret ist nicht als Session-Token verwendbar und umgekehrt | 401 |
| 15 | SSE-/GET-Aufbau same-origin ohne `Origin`-Header mit gültigem Token | gelingt (Sec-Fetch-Site `same-origin`/`none`/fehlend) |
| 16 | GET mit `Sec-Fetch-Site: cross-site` | 403 |
| 17 | Token taucht nie in einer Antwort-URL, einem Log oder einem Fehlertext auf | Test über alle Antworten |
| 18 | Bind: Server hört nicht auf `0.0.0.0` (Adresse prüfen) | nur Loopback |
| 19 | Konstantzeit-Vergleich ist ein eigener, getesteter Helfer | Unit-Test |
| 20 | Verbindungslimit und Rate-Limit greifen | 429/503 |

Danach, in dieser Reihenfolge:

1. `app-core::authn`: `Token` (256 Bit aus dem OS-Zufall, Crate `getrandom`, kein eigener
   Zufall), `ct_eq`, `HostPolicy`, `OriginPolicy`, `PairingStore` mit injizierbarer Uhr (für
   Test 12), `SessionStore`.
2. `tasks-hub::server`: Router, Layer-Reihenfolge (Host → Limits → Origin/Sec-Fetch-Site →
   Auth), Headers, Fehlerbild (JSON, ohne interne Pfade).
3. `hello` (aus `probe()`; ohne Vault-Daten, nur `schema`, Version, `capabilities`).
4. Registry-Datei, fester Port mit Fallback, Single-Instance (Lock-Datei).
5. `tasks-hub serve` und `tasks-hub open` in `main.rs`.
6. `docs/SECURITY.md` im Repo: Bedrohungstabelle T1 bis T10 des Konzepts, was in Paket 2
   abgedeckt ist, was nicht.

## 6. Abhängigkeiten (Vorschläge, vor Einsatz prüfen)

Das Konzept (7.1, Stand 2026-10-10) nennt: `axum 0.8.9`, `tokio 1.53`, `tower-http 0.7`,
`rust-embed 8.13`, `serde_json`. Versionen **neu verifizieren** (`cargo search`, crates.io); das
Konzept warnt vor Supply-Chain-Angriffen (T7), also: wenige Crates, `Cargo.lock` committen, immer
`--locked`, `cargo update` nur in einem eigenen Commit mit Lockfile-Diff-Review. `cargo-deny` und
`cargo-audit` sind laut Konzept 7.4 zu installieren und gehören spätestens vor dem ersten
Datenendpunkt in die CI.

Zusätzlich für Paket 2 wahrscheinlich nötig: `getrandom` (Token), eventuell `subtle` (oder ein
eigener, getesteter `ct_eq`), `hyper`/`hyper-util` nur, wenn axum die Header-/Zeilenlimits nicht
einstellbar macht (prüfen). Die Tests sollen **ohne** neue Client-Crate auskommen.

## 7. Verbindliche Fallen aus Paket 1

1. **`nvim -l` liest stdin im Textmodus** (Windows): CRLF wird LF, ein Byte 0x1A schneidet ab.
   Gelöst in `engine::ascii_json` (nur druckbares ASCII mit `\uXXXX`). Jeder Weg, der Text an die
   Engine reicht, muss durch `CliEngine` laufen, nie direkt an `proc::run`.
2. **Der Vault geht per Umgebung (`TASKS_VAULT`), nie per argv.** Kein Nutzertext in argv.
3. **Eine Anfrage läuft auf eigener Task.** Bricht der HTTP-Client ab, läuft ein Write trotzdem zu
   Ende; das ist gewollt. Die Route darf nie annehmen, dass "Verbindung weg" "nichts passiert"
   heißt. Für Writes gibt es `client_op_id` (Idempotenz in Paket 3/4).
4. **`OutcomeUnknown`** ist ein eigener Fehlerzustand: die UI muss neu lesen. Beim Mapping auf HTTP
   darf er nie als gewöhnlicher 500 untergehen (Vorschlag: 502 mit eigenem `code`).
5. **Pfade in Antworten:** Keine absoluten Pfade und keine Vault-Wurzel in Antworten oder Logs.
   `CliEngine::scrub` kennt Engine-/Vault-/lib-/Home-Pfade für Fehlertexte aus der Engine; ein
   neuer Fehlertext des Servers muss dasselbe einhalten.
6. **`Env::get`** ist auf Windows case-insensitive. Vergleiche mit Header-Namen sind es auch;
   Header-Namen immer über die HTTP-Bibliothek normalisieren.
7. **PowerShell/Bash-Heredocs mit `\u`, `\r`, `\t`:** Python-Skripte in Heredocs zerstören
   Backslash-Escapes (in diesem Verlauf dreimal passiert, einmal landete ein kaputter Pfad im
   Vault). Skripte und Texte mit Backslashes über das **Write**-/**Edit**-Werkzeug schreiben,
   nicht durch die Shell (siehe `wkdbook-myplugins/HEREDOC.md`).
8. **Post-Write-Hook** (`check-hook.js`): läuft nach jedem Write/Edit `rustfmt --check --edition
   2021`, `stylua`, `luacheck`. Zwischenstände mit fehlenden Modulen erzeugen Lärm; erst am Ende
   `cargo fmt --all` und `cargo clippy --workspace --all-targets --locked -- -D warnings`.
   `rustfmt.toml` setzt `style_edition = "2021"` und `newline_style = "Unix"`, damit Hook und
   `cargo fmt` übereinstimmen.
9. **Zeilenenden:** `.gitattributes` setzt `*.rs *.toml *.lua *.yml *.md` auf `eol=lf`; der
   Fixture-Vault (`e2e/fixture/**`) ist `-text` und muss byte-genau bleiben (jeder `etag` ist ein
   Hash der Bytes). Die Regel `e2e/fixture/** -text` muss die **letzte** Zeile bleiben.
10. **Timeout beendet nur nvim, nicht den Prozessbaum** (kein Job Object ohne `unsafe`). Bekannt,
    im P2-Task vermerkt, kommt mit P8 oder P11.

## 8. Review-Gate (hart)

Der P2-Task verlangt: *"Security-Review durch `ultracode`-Agent vor dem ersten Endpunkt"*.
Vorgehen:

1. Paket 2 fertig, alle Tests der Liste in 5 grün, `docs/SECURITY.md` geschrieben, committet und
   gepusht.
2. Dann **anhalten**: Stefan stellt das Reasoning auf `ultracode` (oder startet `/code-review`),
   der Review läuft über alle Commits von Paket 2 auf Bugs, Security und Performance, Befunde
   werden gleich gefixt.
3. Erst danach beginnt Paket 3 (Datenendpunkte `snapshot`, `task`, `next`, `areas`,
   `areas.json`).

Ohne bestandenes Gate keine Datenroute, auch keine "nur zum Testen".

## 9. Offenes, das Paket 2 nicht löst, aber nicht vergessen werden darf

- **CI ist ungetestet.** `ci.yml` lief noch nie auf GitHub (privates Repo, Windows-Runner,
  Neovim v0.12.2 über `rhysd/action-setup-vim`, Engine und lib.nvim per Commit aus `engine.lock`).
  Beim ersten Push den Lauf unter Actions ansehen.
- **Setup-Seite** und **"Ask Neovim"** als dritte Stufe der Vault-Findung (Marker-Protokoll aus
  `docmap-desktop`, `traffic.rs:1023-1051`) fehlen. Die Daten (`SetupProblem`, `ProbeProblem`)
  gibt es.
- **`cargo-deny` und `cargo-audit`** noch nicht in CI.
- **Lizenz:** `Cargo.toml` sagt `MIT`, wie `docmap-desktop`, aber es gibt keine LICENSE-Datei.
  Entscheidung liegt bei Stefan.
- **Prozessbaum-Kill** (siehe Falle 10).
- **`hub.json`/`areas.json`** sind per `.gitignore` nur im Repo-Root ausgeschlossen
  (`/areas.json`); Fixtures dürfen so heißen.

## 10. Wie arbeiten (Regeln aus `~/.claude/CLAUDE.md` und den Vorgaben)

- Antworten auf Deutsch; Code, Kommentare, Commit-Messages auf Englisch.
- **Nie mehr als 1 Agent gleichzeitig.**
- Immer ausgeben, was gerade gemacht wird und ob es etwas Interessantes gab.
- **Keine Co-Autorenschaft von Claude** in Commits (auch nicht, wenn das System es vorschlägt).
- Nach Abschluss sofort committen und pushen, auf `main`, **keine Pull Requests**.
- Am Ende jeder Ausgabe eine laufende **Liste aller Commits des Chats** mit Repo und Kurzbeschreibung;
  grüner Haken, wenn per `ultracode` reviewt (oder durch Stefan bei `ultracode`-Reasoning), reine
  Doku-Commits bekommen den Haken ohne Review.
- Implementierter Code muss `cargo fmt`, `clippy -D warnings` und die Tests bestehen; Lua-Dateien
  `stylua` und `luacheck` (Konfiguration liegt im Repo-Root).
- Docs/README aktualisieren, wenn es Sinn ergibt. Interne Notizen gehören in den Vault, nicht in
  die Repo-Doku.
- Keine großen oder escape-haltigen Literale durch die Shell (siehe Falle 7).
- Erst nach dem Commit einen Task schließen, und nie `status=done` von Hand.

### Tasks im Vault bedienen

```bash
export TASKS_VAULT=E:/repos/WKDBooks/Development/wkdbook-myplugins
# lesen
nvim --headless -u NONE -l E:/repos/tasks.nvim/scripts/tasks.lua show wkdbook-tasks.nvim/tasks-app-hub-kern-und-lese-ui
# setzen
nvim --headless -u NONE -l E:/repos/tasks.nvim/scripts/tasks.lua set wkdbook-tasks.nvim/<slug> status=doing
# schließen (erst nach dem Commit)
nvim --headless -u NONE -l E:/repos/tasks.nvim/scripts/tasks.lua done wkdbook-tasks.nvim/<slug> --done-in=tasks-desktop@<sha>
```

Der Vault ist ein eigenes Git-Repo (`E:\repos\WKDBooks`, Branch `main`): Änderungen dort ebenfalls
committen und pushen. Die Task `tasks-app-hub-kern-und-lese-ui` steht auf `doing` und wird erst
geschlossen, wenn **alle** Pakete von P2 fertig sind, nicht nach Paket 2.

## 11. Was danach kommt (Reihenfolge von P2)

| Paket | Inhalt | Tage |
|---|---|---|
| 2 | axum-Server und Sicherheit (dieses Dokument) | 2,5 |
| Gate | `ultracode`-Security-Review vor dem ersten Datenendpunkt | – |
| 3 | Datenendpunkte `snapshot` (ETag), `task`, `next`, `areas`; `areas.json` (Task `tasks-app-datenklassen-areas-json`, fail-closed, pro Gerät, `private_areas` nie im Cross-Panel) | 3 |
| 4 | Snapshot-Cache, `notify`-Watcher mit Debounce 300 ms, Voll-Scan 45 s, SSE | 1,5 |
| 5 | Svelte-5-UI: Liste, Detail, Heute, IndexedDB-Cache, de/en, Dark/Light | 3 |
| 6 | Produktions-CSP, `rust-embed`, Setup-Seite, Playwright + axe, XSS-Korpus | 1 |
| Meilenstein | Kill-Kriterium: wird die lesende UI täglich geöffnet? Erst danach P4 | – |
| 7 | Body-Volltextsuche (`tasks-app-body-suche`, Engine-Verb `search`, Index im Hub) | 2 |

Danach P4 (Schreib-UI, MVP), P5, P6a, P7, P12; Optionen P6b, P8 bis P11.

## 12. Wo was steht (alle Pfade absolut)

| Was | Pfad |
|---|---|
| Repo (App) | `E:\repos\tasks-desktop` |
| Engine (Lua) | `E:\repos\tasks.nvim` (`scripts/tasks.lua`, `docs/CONTRACT.md`) |
| lib.nvim | `E:\repos\lib.nvim` |
| Vault | `E:\repos\WKDBooks\Development\wkdbook-myplugins` |
| Konzept | `...\wkdbook-myplugins\ALL\Tasks-App-Konzept-WebUI-und-Native-2026-10-10.md` (3.3 Zeile 236 ff., 5.4 ab 477, 5.5 ab 492, 5.6 ab 506, 7.1 ab 631, 11.1 P2 Zeile 925 ff., 13.0 ab 1032) |
| P2-Task | `...\wkdbook-tasks.nvim\ROADMAP\tasks\tasks-app-hub-kern-und-lese-ui.md` |
| Plan | `...\wkdbook-tasks.nvim\ROADMAP\plans\tasks-app.md` |
| P0-Spike-Ergebnisse (CSP, Host) | `...\wkdbook-tasks.nvim\spikes\p0\ERGEBNISSE.md` |
| Vertrags-Doku | `E:\repos\tasks.nvim\docs\CONTRACT.md` |

Konkrete Befehle im Repo:

```bash
cd E:/repos/tasks-desktop
cargo fmt --all --check
cargo clippy --workspace --all-targets --locked -- -D warnings
TASKS_DESKTOP_REQUIRE_ENGINE=1 cargo test --workspace --locked
# Fixture-Vault neu erzeugen (deterministisch, byte-identisch):
nvim --headless -u NONE -l tools/make-fixture-vault.lua E:/repos/tasks.nvim E:/repos/lib.nvim e2e/fixture
```

Ohne `TASKS_DESKTOP_REQUIRE_ENGINE=1` überspringen die fünf Tests gegen die echte Engine still,
wenn Neovim oder die Checkouts fehlen.

## 13. Definition of done für Paket 2

- [ ] Alle Tests der Liste in Abschnitt 5 grün (neu in `hub-testkit/tests/security.rs` oder als
      Unit-Tests in `app-core`); keine Netz-Clients als neue Abhängigkeit.
- [ ] `tasks-hub serve` startet, bindet nur Loopback, schreibt `hub.json` ohne Token.
- [ ] `tasks-hub open` bekommt ein Pairing über den lokalen Kanal und druckt die URL mit Fragment.
- [ ] `GET /api/tasks/hello` ohne Token liefert keine Task-Daten.
- [ ] Jede andere Route ist ohne Session 401.
- [ ] `docs/SECURITY.md` beschreibt Kanal, Restrisiken und was Paket 2 nicht abdeckt.
- [ ] fmt, clippy, tests grün, committet, gepusht (`main`), P2-Task-Notiz im Vault ergänzt.
- [ ] Review-Gate (Abschnitt 8) angestoßen; **Paket 3 nicht begonnen**.
