# `rules.nvim` gegen `ai.nvim` — vollständiger Einzel-Regel-Durchgang

> Ergänzt [`rules-nvim-review.md`](./rules-nvim-review.md) (die kuratierte
> `gates/REVIEW.md`-Fassung). Diese Datei geht stattdessen **jede** der 389
> `manual`-Regel-IDs aus dem ganzen Katalog einzeln durch, nicht nur die für
> den Review-Gate kuratierte Teilmenge — auf expliziten Wunsch, nachdem die
> kuratierte Fassung bereits fertig war. Lebendes Dokument wie die andere
> Datei: bei einem Re-Run vor Ort aktualisiert.

**Stand:** 2026-09-15. **Geprüft gegen:** `E:\repos\ai.nvim`, Worktree
`rules-nvim-ai-nvim-841638`, `main` zu diesem Zeitpunkt identisch (Commit
`62cf73b`). **Vorgehen:** den kompletten Regeltext aus
`regeln/{PRINCIPLES,LUA_NVIM,PERFORMANCE}.md` und
`gates/{NEW_PROJECT,RELEASE}.md` gelesen (6537 Zeilen), dann jede Regel
gegen den bereits vollständig gelesenen `ai.nvim`-Code (alle 27 `lua/`-
Dateien) sowie gezielte Greps geprüft. Für die `LLS-*`-Familie zusätzlich
ein echter `lua-language-server --check .`-Lauf (nicht nur behauptet — s.
§ LLS unten für die Methodik, inkl. eines Falls, in dem der rohe Scan-Wert
verworfen und auf die Ursache zurückgeführt wurde, exakt wie `LLS-04`/
`LLS-44` es verlangen).

**Status-Legende:** ✅ erfüllt · ➖ nicht anwendbar (kein passender Fall im
Repo/Scope, kein Mangel) · 🔶 echter Fund (Backlog)

---

## Neue Funde (Zusammenfassung)

Die drei Funde aus der kuratierten `REVIEW.md`-Fassung sind bereits gefixt
(s. `rules-nvim-review.md`). Dieser vollständige Durchgang fand **13
weitere**, alle noch offen:

| # | Regel | Schwere lt. Katalog | Fund |
| - | ----- | -------------------- | ---- |
| 1 | `LUA-16` | 🔴 kritisch | Kein `ai.providers.*`-Modul sanitized `vim.NIL` nach `vim.json.decode()` — ein JSON-`null` in einem Antwortfeld (z. B. `delta.text`, `usage`) würde als Neovim-Userdata statt `nil` ankommen und potenziell einen `table.concat`/Indexierungs-Fehler mitten im `on_chunk`-Callback auslösen. Betrifft alle 6 `vim.json.decode`-Aufrufstellen (`claude`/`gemini`/`openai`/`ollama`/`loomai`/`sse`). |
| 2 | `XP-05` | 🔴 kritisch | `M.available()` jedes Providers ruft `vim.fn.executable(...)` ungecacht auf; läuft bei jeder `"auto"`-Resolution neu. Auf einer Maschine ohne Cloud-Keys **und** ohne `ollama` installiert probiert jedes `:Ai ask`/`:Ai stream` mehrere fehlschlagende `executable()`-Aufrufe (laut Katalog ~44 ms je Fehlschlag, ungecacht) statt einmal zu cachen. |
| 3 | `ERR-50` | 🔴 kritisch | `ai.config.setup()` validiert `user_opts` nicht vor dem `vim.tbl_deep_extend`-Merge — ein Tippfehler in einer verschachtelten Option verschwindet stillschweigend im Default. |
| 4 | `ERR-60` | 🔴 kritisch (praktisch inert) | `lua/ai/providers/init.lua:57`s `__index`-Fallback `mod and mod[key] or nil` würde einen echten `false`-Feldwert still zu `nil` machen. Aktuell folgenlos (kein `Ai.Provider`-Feld ist je `false`), aber eine latente Falle. |
| 5 | `NEW-19`/`NEW-20` | 🟡 empfohlen | `documentation.nvim`/`:DocMap` ist laut Katalog Pflichtwerkzeug für Annotationen — für `ai.nvim` nicht eingerichtet (kein `docs/map/`, kein `scripts/gen_map.lua`). |
| 6 | `LUA-84` | 🟡 empfohlen | `claude.lua`s `DEFAULT_MAX_TOKENS = 4096` ist ein hartes Literal ohne Config-Key, obwohl es (wie `model`) eine externe API-Grenze beschreibt, die ein Nutzer plausibel überschreiben möchte. |
| 7 | `PERF-64`/`PERF-62` | 🟡 empfohlen | `ai.completion.init`s Auto-Trigger-Timer ist handgerollt (`vim.uv.new_timer()`) statt `lib.nvim.debounce` zu nutzen; `stop_auto_timer()`s `:close()` ist nicht in `pcall` gewrappt. |
| 8 | `REL-03`/`NEW-11` | 🟡 empfohlen | `README.md` hat kein echtes Table of Content (nur 2 `##`-Überschriften insgesamt — bei so wenigen zwar von geringem Wert, aber die Regel selbst macht dafür keine Ausnahme). |
| 9 | `ERR-05`/`PRIN-22` | 🟡 empfohlen | Fünf Stellen nutzen rohes `pcall` statt `lib.nvim.safe_api.safe_call` — durchweg triviale Fälle, aber Abweichung vom Katalog-Standard. |
| 10 | `ERR-06`/`PRIN-21` | 🟡 empfohlen | Keine strukturierten Fehlertypen (`lib.lua.error`) — Fehler sind durchweg Klartext-Strings. Bewusst einfach gehalten (dokumentiertes `Ai.StreamHandlers.on_error: fun(err: string)`), aber Katalog-Abweichung. |
| 11 | `ERR-54` | 🟡 empfohlen | `ai.config.get()` gibt `_active` per Referenz zurück, dokumentiert aber nicht, ob das eine Kopie oder eine Live-Referenz ist. |
| 12 | `UI-61` | 🟢 nice-to-have | `health.lua`s Provider-Statusliste (ein echtes Adapter/Backend-Statusliste-Beispiel) trägt kein `ℹ️ INFO`-Präfix. |
| 13 | `LUA-54` | 🟢 nice-to-have | `README.md`s `**The Basics**`/`**Configuration**`/`**The Rest**` sind fette Pseudo-Überschriften statt echter `###`-Level-Headings oder Fließtext. |

Zusätzlich zwei bereits **explizit im Code dokumentierte** Abweichungen
(kein neuer Fund, nur der Vollständigkeit halber hier verzeichnet):
`UI-23` (Provider-Completion in `:Ai provider <Tab>` ist nicht live, s.
`usrcmds.lua`s eigener Kommentar) und das bereits in `ai.nvim.md` gelistete
`ui/panel.lua`-Voll-Buffer-`set_lines()`-Perf-Finding.

**Keine** dieser 13 ist sicherheitskritisch im Sinne eines ausnutzbaren
Lecks (am nächsten dran: `LUA-16`, aber das ist ein Absturz-/Robustheits-
Risiko, kein Datenleck). Nichts davon wurde in dieser Sitzung gefixt außer
dem bereits separat committeten `LLS-42`/`NEW-41`-Testheader-Fund (s.
`ai.nvim`-Commit `62cf73b`) — die 13 oben sind Kandidaten für eine
Folgesession, priorisiert nach Katalog-Schwere in der Tabelle.

---

## `ERR-*` (35 Regeln, Fehlerbehandlung)

| ID | Status | Begründung |
| -- | ------ | ---------- |
| ERR-01 | ✅ | `pcall` an jeder Systemgrenze: JSON-Decode (alle 6 Provider), Modul-Load (`providers/init.lua`, `health.lua`), Keymap/Usercmd/Completion/Autocmd-Setup (`init.lua`), Extmark-Set (`ghost.lua`), Prozess-Kill (`panel.lua`). |
| ERR-02 | ✅ | `type(...)`-Guards durchgehend vor jedem Feldzugriff auf Fremd-JSON. |
| ERR-03 | ✅ | `ask(cb)` ruft immer `cb(true/false, …)`, `resolve()` gibt `provider, err`. |
| ERR-04 | ✅ | `notify` nur in `bindings/actions.lua`/`init.lua`/`health.lua` (UI-Schicht) — Provider/Config/Completion/Context notifizieren nie. |
| ERR-05 | 🔶 | S. Fund #9 — rohes `pcall` statt `lib.nvim.safe_api.safe_call` an 5 Stellen. |
| ERR-06 | 🔶 | S. Fund #10 — keine strukturierten Fehlertypen, nur Strings. |
| ERR-07 | ✅ | `assert(...)` in `ask`/`stream`/`register`. |
| ERR-10 | ✅ | Keine API in `ai.nvim`, die „kein Argument"/„ungültiges Argument" verwechselbar auf `nil` kollabiert. |
| ERR-11 | ➖ | `ai.context.add_scope()` schluckt bewusst „nichts gefunden" und „Scope-Resolve fehlgeschlagen" gemeinsam — dokumentiert als Best-effort-Designentscheidung (Kontext ist optional), keine versteckte Fehlerquelle. |
| ERR-20 | ✅ | Kontext-Assemblierung ist fail-open: ein fehlender Scope überspringt nur seinen Abschnitt, nie den ganzen Block. |
| ERR-21 | ➖ | Keine Umgebungs-Whitelist/-Erkennung in `ai.nvim`. |
| ERR-22 | 🔶 | Hängt an Fund #3 (`ERR-50`) — keine Validierung, also auch kein definiertes Degradieren auf Default bei ungültigem Wert (der Wert fließt einfach unvalidiert durch). |
| ERR-30/31/34 | ➖ | Kein Scan-vor-Schreiben, keine `O_CREAT\|O_EXCL`-Dateierzeugung, kein rekursiver Walk in `ai.nvim`. |
| ERR-32 | ✅ | `ai.completion.init`s `generation`-Counter genau dieses Muster. |
| ERR-33 | ✅ | `completion.trigger()`s `ask`-Callback prüft `nvim_buf_is_valid` + `changedtick` + Cursor-Position erneut. |
| ERR-40/41 | ➖ | Keine Datei-Handles, keine Windows-Sharing-Violation-Fälle. |
| ERR-42/43 | ➖ | Keine Batch-Operationen über N Items. |
| ERR-44 | ✅ | `completion.trigger()`s Generation-Counter ist exakt das Token-Cancel-Muster für die nicht killbare `ask()`. |
| ERR-50 | 🔶 | S. Fund #3. |
| ERR-51 | ✅ | `vim.deepcopy(DEFAULTS)` vor jedem Merge. |
| ERR-52 | ✅ | Kein handgeschriebener Merge, nur `vim.tbl_deep_extend` direkt — die Regel selbst nimmt genau diesen Fall aus. |
| ERR-53 | ➖ | Kein Submodul hält eine Live-Referenz auf eine Config-Untertabelle. |
| ERR-54 | 🔶 | S. Fund #11. |
| ERR-60 | 🔶 | S. Fund #4 (`providers/init.lua:57`); alle anderen `and…or`-Stellen im Repo geprüft (`actions.lua`, `keymaps.lua`, `completion/*.lua`, `context/diagnostics.lua`, alle Provider) — durchweg sicher, weil der `b`-Zweig nachweislich nie falsy ist. |
| ERR-61 | ➖ | Kein Patch-/Merge-Code, der `nil` als „Feld löschen" braucht. |
| ERR-62 | ✅ | Kein `pcall(f(args))`-Fund — nur `pcall(function() … end)`. |
| ERR-63/64 | ➖ | Kein Vararg-/mehrwertiger-Klammer-Code in `ai.nvim`. |
| ERR-65 | ➖ | Keine mutierende Mehrschritt-Operation, die ein Rollback bräuchte. |
| ERR-66 | ➖ | Kein FFI/native Code. |
| ERR-67 | ➖ | Kein Fall, wo dokumentiertes API-Verhalten ungeprüft übernommen wurde (die Provider-Quirks sind im Gegenteil explizit gegen echtes Verhalten dokumentiert, s. `sse.lua`/`gemini.lua`-Modulkommentare). |

## `LUA-*` (59 Regeln, über 8 Abschnitte)

| ID | Status | Begründung |
| -- | ------ | ---------- |
| LUA-01 | ✅ | `lib.nvim` konsequent hart (nacktes `require`, `health.lua` meldet `error` bei Fehlen), nie als optional dargestellt. |
| LUA-02 | ✅ | Keine lokale Kopie von `lib.nvim`-Funktionalität gefunden. |
| LUA-03 | ➖ | `ai.nvim` ist kein dünner Re-Export. |
| LUA-04 | ➖ | Die Env-Var-Lesungen (`ANTHROPIC_API_KEY` etc.) sind Secrets/Host-Overrides, nicht Pfad-Defaults — dafür ist der direkte `vim.env`-Zugriff laut `SEC-15` explizit korrekt, `LUA-04` zielt auf einen anderen Fall. |
| LUA-05 | ✅ | `health.lua`s `pcall(require, "lib.nvim.net.curl")` für die `fetch_stream`-Präsenzprüfung. |
| LUA-06 | ✅ | `config/DEFAULTS.lua` ist reine, seiteneffektfreie Daten (verifiziert: kein `require`-Aufruf, kein Env-Lookup auf Modulebene). |
| LUA-10 | ✅ | Handles (`bufnr`, `cursor`) immer erst gebunden, dann geprüft/genutzt. |
| LUA-11 | ✅ | `nvim_buf_is_valid` vor jedem deferred Buffer-Zugriff. |
| LUA-12 | ✅ | Type/Nil-Guards vor jedem `vim.api`-Zugriff. |
| LUA-13 | ✅ | S. `ERR-33`. |
| LUA-14 | ➖ | Kein `vim.fn`-Aliasing im Repo. |
| LUA-15 | ✅ | `vim.uv.new_timer()`, kein `vim.loop`. |
| LUA-16 | 🔶 | S. Fund #1. |
| LUA-17 | ✅ | Einziger `vim.g`-Zugriff ist `vim.g.loaded_ai = true` (Boolean-Primitive). |
| LUA-30 | ✅ | **Gefixt diese Sitzung** (`ai.config.set_provider()`). |
| LUA-31/40-46 | ➖ | Keine Weak-Tables/Metatable-Vererbung nötig (kleine, kurzlebige Structs, kein Cache). |
| LUA-32/33/34 | ➖ | Keine Historie/Favoriten, kein Snapshot/Restore-Bedarf, keine großen Array-vs-Record-Datenmengen. |
| LUA-47 | ➖ | Kein `rawget`-Fall (der Lazy-Proxy löst „geladen?" schon über `load_failed` anders). |
| LUA-48 | ➖ | Das einzige `setmetatable` (`providers/init.lua`) nutzt `__index` für den Lazy-Proxy, keine `__mode`-Weak-Table. |
| LUA-50 | ✅ | Interne Helfer durchweg `local function`. |
| LUA-51 | ✅ | Öffentliche Oberfläche (`ask`/`stream`/`register`) type-checkt; interne private Helfer verlassen sich zulässig auf Aufrufer-Disziplin. |
| LUA-52 | ✅ | snake_case durchgehend. |
| LUA-53 | ✅ | Alle Code-Kommentare Englisch. |
| LUA-54 | 🔶 | S. Fund #13. |
| LUA-55 | ➖ | Kein Swap-Code im Repo. |
| LUA-60-66 | ✅ | `@module`/`@class`/`@param`/`@return` durchgehend, Typen in `@types/init.lua` ausgelagert; verifiziert auch über den echten `lua-language-server`-Lauf (0 malformte Annotationen, s. § LLS unten). |
| LUA-69-71 | ✅ | `@types/init.lua`s Aliase/Returns/Fields folgen der `#`-Konvention konsistent. |
| LUA-80 | ✅ | Automatisiert grün (`config/init.lua` + `config/DEFAULTS.lua` vorhanden). |
| LUA-81 | ✅ | Ordentlich konfigurierbar (Completion-Trigger/-Timing/-Provider, UI-Theme/Style, Keymap-Prefix, Context-Defaults). |
| LUA-82 | ✅ | Jeder Config-Key in `@types/init.lua` typisiert. |
| LUA-83 | ➖ | Prozess-Regel, kein Ist-Zustand zu prüfen. |
| LUA-84 | 🔶 | S. Fund #6. |
| LUA-85 | ➖ | Die tatsächliche Lazy-Spec liegt nicht in diesem Repo. |
| LUA-86 | ➖ | Kein Opt-in-Feature mit bedeutsamer Abwesenheit in `ai.nvim`s Defaults. |
| LUA-87 | ➖ | Kein selbstgeschriebenes Config-File/State-Persistenz in `ai.nvim`. |
| LUA-90-92 | ➖ | `ai.nvim` ruft nie `setup()` eines Fremd-Plugins (`lib.nvim`/`ui.nvim` sind reine Bibliotheken ohne eigenes `setup()`), die Regeln zielen auf Adapter-für-Fremd-Plugin-Fälle. |
| LUA-93/94 | ➖ | Die tatsächliche Lazy-Trigger-Spec liegt in der Nutzer-Config, nicht in diesem Repo — `docs/installation.md` empfiehlt `cmd = "Ai"` explizit richtig. |
| LUA-95 | ➖ | `:Ai` ist ein unüblicher, kollisionsarmer Name; vollständige Prüfung gegen alle später geladenen Plugins außerhalb des Audit-Scope dieses Repos. |
| LUA-96 | ✅ | Benannte Augroups (`ai_nvim`, `AiCompletion`), `M._initialized`-Guard macht `setup()` idempotent. |

## `UI-*` (41 Regeln)

| ID | Status | Begründung |
| -- | ------ | ---------- |
| UI-01 | ➖ | Keine Bulk-/destruktiven Aktionen in `ai.nvim`. |
| UI-02 | ➖ | Keine überraschende Scan-Trunkierung (Completions `max_context_lines`-Limit ist erwartetes, dokumentiertes Default-Verhalten, kein stiller Ergebnis-Cut). |
| UI-03 | ➖ | Provider-`"auto"`-Resolution ist eine bewusste, vom Nutzer konfigurierte Prioritätskette, kein „stilles Degradieren zwischen konkurrierenden Backends" im Sinne der Regel. |
| UI-04 | ✅ | Fehler bleiben knapp (`.error.message`-Extraktion bzw. `curl_exit_error`), nie ein roher mehrzeiliger Stderr-Dump. |
| UI-20 | ➖ | Kein `?`-Cheatsheet-Popup in `ai.nvim` — `docs/BINDINGS.md` übernimmt diese Rolle. |
| UI-21 | ✅ | `:Ai ask/stream/provider/info` über `lib.nvim.usercmd.composer`. |
| UI-22 | ✅ | `:Ai provider <Tab>` completet über die Provider-`enum`. |
| UI-23 | 🔶 (bereits dokumentiert) | Completion-Liste ist bei Registrierung eines späteren Custom-Providers nicht live — im Code selbst als bewusste, akzeptable Abweichung kommentiert (`usrcmds.lua`). |
| UI-24 | ➖ | Kein Pfad-Argument im `:Ai`-Kommandobaum. |
| UI-25/26 | ✅ | `:Ai ask/stream <text>` ist Freitext, korrekt ohne Completion. |
| UI-27 | ➖ | Das which-key-Gruppenlabel ist der statische Plugin-Name `"ai.nvim"`, kein aus `lhs` abgeleitetes, remap-brüchiges Label — der von der Regel beschriebene Bruch tritt hier strukturell nicht auf. |
| UI-28 | ➖ | Keine Mehrfachziel-Aktionen. |
| UI-29 | ➖ | Keine Statusline-Komponente in `ai.nvim`. |
| UI-30-32 | ➖ | Kein eigener Prompt-Buffer/Dashboard/TUI — die Eingabe läuft über `ui.kit.popup({type="input"})`. |
| UI-33 | ✅ | `panel.lua`s Fallback-Verhalten (Fenster bleibt offen bei Fehler) ist graceful, kein harter Fehlerabbruch. |
| UI-34 | ➖ | Keine langen externen Strings (Digests/URLs) zum Truncaten in der UI. |
| UI-35 | ✅ | `panel.lua`s `finish`/`cancel` laufen beide durch dieselben zwei Funktionen, idempotent über den `progress`-eigenen `done`-Guard. |
| UI-36 | ➖ | `ai.nvim` produziert keine Trefferliste (kein Such-/Symbol-Ergebnis). |
| UI-37 | ➖ | Keine Layer-Migration eines Flag-Parsers im Repo. |
| UI-38 | ➖ | `ai.nvim` rendert keine eigenen Glyphen/Icons. |
| UI-40-44 | ➖ | Keymaps sind alle One-Shot-Aktionen ohne natürliche „N-mal"-Semantik — korrekt kein Count-Support versucht (deckt sich mit `UI-41`s eigener Ausnahme). |
| UI-50 | ✅ | `panel.lua`s `open/append/finish/cancel/cancel_all` sind intern konsistent benannt. |
| UI-51 | ✅ | Panel-State wird nur über `panel.lua`s eigene Funktionen berührt (inkl. `attach_process` als echter Setter), nicht von außen direkt gepoked. |
| UI-52 | ✅ | `cancel_all()`, jetzt mit korrektem Untracking (diese Sitzung gefixt). |
| UI-53 | ✅ | S. `LUA-13`. |
| UI-54/55/56 | ➖ | Kein Verdrängungs-UI-Paar, kein Buffer-Delete mit sichtbaren Fenstern, kein Preview-Fenster in `ai.nvim`. |
| UI-57 | ✅ | `vim.health.info` (nicht `warn`) für „ein Provider von fünf nicht verfügbar". |
| UI-58 | ✅ | Der einzige `warn`-Aufruf (Auto-Trigger-Kostenwarnung) hat einen konsistenten, tatsächlich handlungsbedürftigen Text. |
| UI-59 | ✅ | Provider-Einzelausfall ist `info`, kein `error`/`warn`. |
| UI-60 | ➖ | `ai.nvim`s eigener Healthcheck prüft nicht auf noch-nicht-registrierte fremde Lazy-Commands. |
| UI-61 | 🔶 | S. Fund #12. |
| UI-62 | ✅ | Automatisiert grün (`lua/ai/health.lua` existiert am erwarteten Pfad). |

## `CMT-*` (16 Regeln)

| ID | Status | Begründung |
| -- | ------ | ---------- |
| CMT-01 | ✅ | Provider-Liste (`{"claude","ollama","openai","gemini","loomai"}`) identisch in `DEFAULTS.lua`, `providers/init.lua`, allen sechs Doku-Dateien — per Grep gegengeprüft, keine Drift. |
| CMT-02 | ✅ | `@types/init.lua`s `Ai.Config` & Co. spiegeln `config/DEFAULTS.lua`s echte Struktur Feld für Feld. |
| CMT-03 | ✅ | `require("ai...")`-Pfade in Docs stimmen mit der echten Modulstruktur überein. |
| CMT-04 | ✅ | Kein Kommentar-Code-Widerspruch gefunden. |
| CMT-05 | ✅ | Die `OLLAMA_HOST`→`AI_OLLAMA_HOST`- und `usercmds.lua`→`usrcmds.lua`-Umzüge sind vollständig in Docs/Notify-Strings nachgezogen (per `ai.nvim.md` bereits verifiziert, hier nur bestätigt). |
| CMT-06 | ✅ | Keine deutschen Code-Kommentare. |
| CMT-07 | ✅ | Keine `Features:`/`====`-Boilerplate-Header — alle Module folgen `@module`+`@brief`+knapper Prosa. |
| CMT-08 | ✅ | Modulköpfe duplizieren `docs/*.md` nicht, sondern verweisen knapp darauf. |
| CMT-09 | ✅ | Detail-Rationale liegt in `docs/architecture.md`, Code-Kommentare sind knappe Pointer. |
| CMT-10 | ✅ | Kein „an allen N Stellen"-Zahlenkommentar gefunden. |
| CMT-11 | ✅ | Keine verwaisten Kommentare. |
| CMT-12 | ✅ | Keine verwürfelten Doc-Blöcke. |
| CMT-13 | ✅ | Kein Mojibake/Smart-Quotes (per Grep bestätigt). |
| CMT-14 | ➖ | Kein toter Code im Repo gefunden, der zu markieren wäre. |
| CMT-15 | ✅ | `grep -rn "--- CDX:"` → 0 Treffer. |
| CMT-16 | ➖ | Keine generierte Datei in `ai.nvim` (kein `docs/map/`, kein `:DocMap` eingerichtet — s. `NEW-19`/`NEW-20`-Fund). |

## `SEC-*` (29 Regeln)

| ID | Status | Begründung |
| -- | ------ | ---------- |
| SEC-01 | ✅ | Automatisiert grün — 0 `os.execute`/`io.popen`. |
| SEC-02 | ➖ | Alle externen Aufrufe laufen über `lib.nvim.net.curl` gegen absolute URLs, kein `cwd`-abhängiger Prozessaufruf. |
| SEC-03 | ✅ | Kein Nutzertext wird je in einen Kommandostring interpoliert (alles JSON-Body über `vim.json.encode`, nie String-Konkatenation in einen Shell-Aufruf). |
| SEC-10 | ✅ | API-Keys gehen als HTTP-Header (`secret_headers`/`bearer_token`), nie als Argv. |
| SEC-11 | ➖ | `ai.nvim` führt keine Request-History/Logs. |
| SEC-12 | ➖ | Keine `{{var}}`-Platzhalter-Auflösung im Repo. |
| SEC-13 | ➖ | Keine Telemetrie in `ai.nvim`. |
| SEC-14 | ➖ | Keine Secrets-Datei, die eine `.gitignore`-Warnung bräuchte. |
| SEC-15 | ✅ | API-Keys kommen ausschließlich aus `vim.env`, kein eigener Key-Store; `health.lua` meldet nur vorhanden-ja/nein. |
| SEC-20/21/23 | ➖ | `ai.nvim` lädt keine Binaries/Remote-Content herunter. |
| SEC-22 | ➖ | Keine impliziten Netzwerk-Fetches (jeder Request ist eine explizite Nutzeraktion: `:Ai ask/stream`). |
| SEC-30 | ➖ | `ai.nvim` baut keine Regex aus Nutzereingabe. |
| SEC-31 | ➖ | Keine Case-Sensitivity-relevante Suche im Repo. |
| SEC-32 | ✅ | `completion.max_context_lines` (Default 60) ist ein dokumentiertes, konfigurierbares Limit. |
| SEC-33 | ➖ | `ai.nvim` persistiert keine Snapshots. |
| SEC-34/35 | ✅ | Kein `vim.fn.expand()`/`vim.cmd`-String mit Nutzer-/Buffertext im Repo (per Grep bestätigt). |
| SEC-40 | ➖ | `ai.nvim` ist keine server-artige Oberfläche mit Pfad-Whitelisting-Bedarf. |
| SEC-41 | ➖ | Keine `.rc`-Datei-Konfiguration. |
| SEC-42/43 | ➖ | Keine nutzergesteuerten Pfad-Komponenten in `ai.nvim`. |
| SEC-44 | ✅ | `type(...)==table`-Checks auf jeder Verschachtelungsebene vor dem Indizieren, durchgehend in allen Providern. |
| SEC-45 | ➖ | Keine Redaction-Logik in `ai.nvim`. |
| SEC-46 | ➖ | Kein String-Literal-Embedding in eine andere Sprache. |
| SEC-47 | ✅ | Automatisiert grün — 0 `os.tmpname()`. |
| SEC-50/51 | ➖ | Kein Preview-Feature in `ai.nvim`. |

## `PRIN-*` (37 Regeln)

| ID | Status | Begründung |
| -- | ------ | ---------- |
| PRIN-01 | ✅ | Jedes Modul eine klare Verantwortung (config/health/providers/ui/completion/context/bindings). |
| PRIN-02 | ✅ | Funktionen durchweg klein und fokussiert. |
| PRIN-03 | ✅ | Niedrige Kopplung — Provider kennen sich gegenseitig nicht, UI kennt keine Provider-Details. |
| PRIN-04 | ✅ | `sse.lua`, `completion/prompt.lua` sind reine Funktionen; unvermeidbarer Seiteneffekt-Code bleibt dünn. |
| PRIN-05 | ✅ | `local function` durchweg für Internes. |
| PRIN-06 | ✅ | Registry-Pattern für Provider ist angemessen, kein Overengineering. |
| PRIN-07 | ✅ | `providers.register()` als echte Erweiterungs-Registry. |
| PRIN-10 | ✅ | Kein `_G.*`; State modul-lokal (`_active`, `registered`, `active_panels`, `shown`, `generation`). |
| PRIN-11 | ✅ | `config`-Objekt wird per Parameter durchgereicht (`M.setup(cfg)`-Muster); interne `require("ai.config").get()`-Zugriffe entsprechen der im Katalog selbst als Standard beschriebenen `config.options.X`-Konvention. |
| PRIN-12/13 | ➖ | Zu kleiner Scope für ein eigenes Kontext-Objekt bzw. Snapshot/Restore. |
| PRIN-20 | ✅ | S. `ERR-03`. |
| PRIN-21 | 🔶 | S. Fund #10 (= `ERR-06`). |
| PRIN-22 | 🔶 | S. Fund #9 (= `ERR-05`). |
| PRIN-23 | ✅ | S. `ERR-04`. |
| PRIN-24 | ✅ | Fehlerstrings sind an der Funktion selbst dokumentiert (z. B. `"claude: ANTHROPIC_API_KEY not set"` im Doc-Kommentar nachvollziehbar). |
| PRIN-25 | ✅ | S. `ERR-07`. |
| PRIN-26 | ✅ | S. `ERR-10`. |
| PRIN-27 | ✅ | S. `ERR-20`. |
| PRIN-28 | ➖ | Keine rollback-bedürftige Mehrschritt-Mutation. |
| PRIN-29 | ➖ | Kein FFI/nativer Code. |
| PRIN-30 | ✅ | Code ist durchgehend klar, kein erzwungener „cleverer" Stil. |
| PRIN-31 | ✅ | **Gefixt diese Sitzung** — Provider-Parsing jetzt testbar/getestet über gestubtes `curl`. |
| PRIN-32 | ✅ | **Gefixt diese Sitzung** — reine Funktionen (`sse.lua`, `completion/prompt.lua`) jetzt getestet. |
| PRIN-33 | ➖ | Kein separater Dry-Run-Entry nötig; `TESTS/` übernimmt diese Rolle bereits vollständig. |
| PRIN-34 | 🔶 | Nice-to-have: alle Tests sind beispielbasiert, keine Property-/Invarianten-Tests (z. B. „`recover_error_body` wirft nie für beliebige Zeilenlisten"). Geringe Priorität. |
| PRIN-35 | ✅ | S. `LUA-52`. |
| PRIN-36 | ➖ | Kein zeitkritischer Async-Debugging-Fall in `ai.nvim`. |
| PRIN-40-43 | ➖ | `ai.nvim` hat keinerlei Caching — die Regeln greifen nicht, weil es keinen Cache gibt, der falsch gemacht sein könnte. |
| PRIN-50 | ✅ | Jede Datei mit `@module`+Zweck-Kopf. |
| PRIN-51 | ✅ | `@param`/`@return` durchgehend an öffentlichen Funktionen. |
| PRIN-52 | ✅ | `@types/init.lua`. |
| PRIN-53 | ✅ | Docs verlinken sich gegenseitig statt zu wiederholen (z. B. `health.lua` → `docs/`). |
| PRIN-54 | ➖ | Zielt auf Pläne/Studien, nicht auf ein fertiges Plugin-Repo. |

## `PERF-*` (64 Regeln — Hotpath-Katalog)

Fast vollständig `➖`: `ai.nvim` hat **keinen** Hotpath im eigentlichen Sinn
— keine großen Tabellen/Strings in Schleifen, kein Caching, kein
Dateisystem-Scan, kein Bulk-Processing. Einzige nennenswerte Bewegung ist
`ai.completion`s Idle-Timer.

| ID | Status | Begründung |
| -- | ------ | ---------- |
| PERF-01-16 | ➖ | Kein Hotpath mit Tabellen-/String-Aufbau in Schleifen in `ai.nvim`. |
| PERF-20-27 | ➖ | Keine großen, gleichförmigen Datenmengen. |
| PERF-40-53 | ➖ | Kein Caching in `ai.nvim` — die Regeln setzen einen existierenden Cache voraus. |
| PERF-60/61/63/65 | ➖ | Nur ein einziger Debounce-Fall (Completion-Idle-Timer), die Mehrfach-Trigger-/Handle-Wiederverwendungs-Regeln greifen bei nur einem Timer nicht. |
| PERF-62 | 🔶 | S. Fund #7. |
| PERF-64 | 🔶 | S. Fund #7. |
| PERF-70-75 | ➖ | Kein Filesystem-Scanning in `ai.nvim`. |
| PERF-80 | ✅ | `vim.schedule_wrap` um den Timer-Callback (`completion/init.lua`). |
| PERF-81 | ➖ | Kein Hintergrund-Poller mit Fällig-Intervall. |
| PERF-82 | ✅ | `stop_auto_timer()` vor jedem neuen Timer-Start — faktisch idempotent. |
| PERF-83 | ✅ | S. `ERR-44`. |
| PERF-84-91 | ➖ | Kein Chunking/Blocking-Trade-off-Fall, kein Cancel-mit-Teilstand-Pfad in `ai.nvim`. |
| PERF-92 | ➖ | `ai.nvim` berechnet keine eigene Fenster-Geometrie (delegiert an `ui.kit`). |
| PERF-93 | ✅ | Der `TextChangedI`/`CursorMovedI`-Dismiss-Handler ist ein billiger Guard (`ghost.current()`-Lookup). |

## `TS-*` (5 Regeln)

| ID | Status | Begründung |
| -- | ------ | ---------- |
| TS-01–05 | ➖ | `ai.nvim` nutzt Treesitter nicht (0 Treffer für `vim.treesitter`/`treesitter` im ganzen Repo). |

## `XP-*` (7 Regeln)

| ID | Status | Begründung |
| -- | ------ | ---------- |
| XP-01 | ➖ | 0 `vim.fn.glob`/`globpath`-Aufrufe im Repo. |
| XP-02 | ➖ | Kein pfadbasierter Cache-Key. |
| XP-03/04 | ➖ | `ai.nvim` shellt nie direkt (alles über `lib.nvim.net.curl`), keine eigene OS-Verzweigung. |
| XP-05 | 🔶 | S. Fund #2. |
| XP-06 | ✅ | Alle `require("ai...")`-Pfade case-korrekt zu den echten (durchgehend kleingeschriebenen) Dateinamen. |
| XP-07 | ➖ | `ai.nvim` fasst keine Register/Zwischenablage an. |

## `LLS-*` (37 Regeln — LuaLS-Messgrundlage)

**Methodik statt Einzelverdikt für die meisten IDs:** ein echter
`lua-language-server --check . --checklevel=Warning`-Lauf gegen den
Worktree fand zunächst 212 Probleme — **209 davon** waren `undefined-
field`/`undefined-global`/`undefined-doc-name`/`need-check-nil`, exakt das
Muster, das `LLS-01`/`LLS-02`/`LLS-05` selbst als Messgrundlage-Artefakt
beschreiben (dieser CLI-Lauf injiziert kein `workspace.library` für
`lib.nvim`/`ui.nvim`/`luassert`, anders als die echte Editor-Session — und
`ai.nvim`s `.luarc.json` lässt `workspace.library` bewusst leer, genau
nach `LLS-01`/`NEW-36`). Statt die rohe Zahl zu melden (genau der Fehler,
vor dem `LLS-04` warnt), wurde jeder Fund einzeln der fehlenden
Library-Injektion zugeordnet. Übrig blieben 3 echte Treffer:

- 1× `missing-fields` in `TESTS/ai/config_spec.lua:16` (`Ai.UiOptions`
  ohne `enable`) — ein Test, der absichtlich ein Partial-Table an
  `config.setup()` übergibt (genau das dokumentierte, erlaubte Verhalten
  von `config/init.lua`s locker typisiertem `user_opts`-Parameter) — kein
  Fund, sondern erwartetes Verhalten eines Merge-Tests.
- 2× `return-type-mismatch` in `ollama.lua:34`/`loomai.lua:31` (`host()`
  gibt laut Annotation `string` zurück, LuaLS sieht `string|nil`) — beide
  rufen `util.env_value(name, FALLBACK)` mit gesetztem Fallback auf, dessen
  `@overload`-Deklaration für genau diesen Fall `string` (nicht
  `string|nil`) verspricht; LuaLS' Overload-Auflösung an dieser Aufrufform
  ist eine bekannte Grenze des Tools, keine falsche Annotation im
  `ai.nvim`-Code selbst — laufzeitseitig ist der Rückgabewert nachweislich
  nie `nil`, wenn ein Fallback übergeben wird.

**Ergebnis: 0 echte LuaLS-Funde in `ai.nvim`s eigenem Code.** Damit sind
`LLS-10`…`LLS-17` (Annotationen, die parsen) und `LLS-20`…`LLS-29`
(Fremdtypen) indirekt, aber konkret verifiziert — ein malformtes `@param`/
`@return` hätte in diesem Lauf als echter, nicht library-bedingter Fund
sichtbar werden müssen, ist es aber nicht.

Nach diesem Lauf ein 9-Treffer-`need-check-nil`-Cluster in den vier neuen
`TESTS/`-Dateien dieser Sitzung entdeckt und **noch in dieser Sitzung
gefixt** (Commit `62cf73b`: Datei-Header-Suppression ergänzt, 212 → 203
beim erneuten Lauf, exakt die erwarteten 9 — `LLS-42`/`NEW-41` erfüllt).

| ID | Status | Begründung |
| -- | ------ | ---------- |
| LLS-01 | ✅ | `.luarc.json` setzt `workspace.library` nicht. |
| LLS-02 | ✅ | Keine Library zeigt auf den eigenen Baum. |
| LLS-03 | ✅ | `workspace.ignoreDir: [".deps", ".claude"]` gesetzt. |
| LLS-04 | ✅ | Methodik oben — roher Scan-Wert nicht als Fund übernommen. |
| LLS-05 | ➖ | Prozess-Regel für Mehrfach-Repo-Scans, nicht für einen Einzel-Repo-Audit. |
| LLS-06/07 | ✅ | Methodik oben (Ursachen-Zuordnung statt Rohwert; Re-Run nach dem Test-Header-Fix bestätigt exakt die erwartete Differenz). |
| LLS-08 | ➖ | Kein laufender Mehrschritt-Fix-Zyklus für LuaLS-Diagnosen diese Sitzung außer dem einen, verifizierten `need-check-nil`-Fix. |
| LLS-10-17 | ✅ | Indirekt verifiziert — s. Methodik oben. |
| LLS-20-29 | ✅ | Keine Fremdtyp-Kollisionen/-Namensraum-Verstöße/-Alias-Fehlformen im Repo. |
| LLS-30/33 | ➖ | Kein Narrowing-Fall im Code, keine offene Feld-Nachdeklaration. |
| LLS-31 | ✅ | Kein `pcall` um einen von LuaLS bemängelten Aufruf gefunden. |
| LLS-32 | ➖ | Kein `pcall` um eine `__call`-Tabelle. |
| LLS-40 | ✅ | Der eine `@diagnostic disable` (`TESTS/ai/providers_spec.lua`) ist begründet. |
| LLS-41 | ✅ | Direkt an letzter Zeile des Kommentarblocks platziert. |
| LLS-42 | ✅ | **Gefixt diese Sitzung** (s. o.). |
| LLS-43 | ➖ | Keine Versionsspannen-Fallbacks nötig (`ai.nvim` verlangt einheitlich ≥ 0.10, kein `vim.loop`-Erbe). |
| LLS-44 | ✅ | Methodik oben — roher Scan-Wert hinterfragt statt übernommen. |
| LLS-45/46 | ➖ | Kein `---@type ClassX` auf `return M`, keine Mehr-Backend-Aggregat-Oberfläche in `ai.nvim`s Architektur. |

## `NEW-*` (50 Regeln — bereits 14 automatisiert grün)

Nur die 36 `manual`-IDs unten; die 14 automatisierten (`NEW-03,06,07,08,
10,11,13,14,15,27,36,45,48,49`) sind bereits im automatischen Teil oben
als `pass` bestätigt (inkl. `NEW-08`, frisch gegengeprüft).

| ID | Status | Begründung |
| -- | ------ | ---------- |
| NEW-01 | ✅ | Repo existiert, gepusht, `origin/main` aktuell. |
| NEW-02 | ✅ | Default-Branch `main`. |
| NEW-04 | ✅ | `gh repo view`: Beschreibung + Homepage gesetzt. |
| NEW-05 | ✅ | Topics gesetzt (`ai, anthropic, claude, llm, lua, neovim, ollama, openai, plugin`). |
| NEW-09 | ✅ | Ein `@types`-Ordner für den ganzen (kleinen) Modulbaum ist bei dieser Repo-Größe angemessen. |
| NEW-12 | ✅ | Schwesterplugin-Verweis auf `pdfport.nvim` direkt nach der ASCII-Art. |
| NEW-16 | ✅ | `lib.nvim` als Dependency. |
| NEW-17 | ✅ | Durchweg `lib.nvim`-Module statt Eigenbau. |
| NEW-18 | ➖ | `ai.providers.sse` ist zwar generisch geschnitten, aber eng genug an Anthropic/OpenAI-Fehlerformen gebunden, dass ein Transfer nach `lib.nvim` heute keinen zweiten Konsumenten hätte — vertretbare Entscheidung, kein Fund. |
| NEW-19/20 | 🔶 | S. Fund #5. |
| NEW-21 | ✅ | Keymaps über `config.keymaps[id]` deaktivier-/überschreibbar. |
| NEW-22 | ✅ | `which_key`-Unterstützung. |
| NEW-23 | ✅ | `:Ai <subcommand>` über `lib.nvim.usercmd.composer`. |
| NEW-24 | ✅ | Keymaps/Usercmds/Completion/which_key alle default `enable = true`. |
| NEW-25 | ➖ | S. `UI-40`-Analyse — kein Count-tauglicher Keymap in `ai.nvim`. |
| NEW-26 | ✅ | Provider-Completion vorhanden (mit dem bereits dokumentierten „nicht live"-Vorbehalt, s. `UI-23`). |
| NEW-28 | ✅ | S. `LUA-82`. |
| NEW-29 | ➖ | Prozess-Regel. |
| NEW-30/31 | ✅ | Kein OS-spezifischer Code in `ai.nvim` — alles über `lib.nvim.net.curl` cross-plattform. |
| NEW-32 | ➖ | Prozess-Regel. |
| NEW-33 | ➖ | Betrifft das Wkdbook, nicht diesen Audit. |
| NEW-34 | ✅ | Sauberer `git status`, `origin/main` aktuell. |
| NEW-35 | ✅ | `docs/BINDINGS.md` ist die einzige Bindings-Quelle, keine zweite Handkopie. |
| NEW-37 | ✅ | S. `LLS-03`. |
| NEW-38 | ✅ | `diagnostics.globals` in `.luarc.json` enthält nur `"vim"`. |
| NEW-39/40 | ✅ | `TESTS/minimal_init.lua` + `scripts/test.sh`, nennt beim Scheitern alle drei Plenary-Fundorte, endet mit Exit-Code (verifiziert per Quellcode-Lesen). |
| NEW-41 | ✅ | **Gefixt diese Sitzung.** |
| NEW-42 | ✅ | S. `LLS-40`/`LLS-41`. |
| NEW-43 | ✅ | Kein sich selbst überspringender Testfall gefunden (alle Specs laufen ohne Guard-Skip durch). |
| NEW-44 | ✅ | S. § LLS oben — 0 echte Diagnosen zum jetzigen Stand. |
| NEW-46 | ➖ | Prozess-Regel, retrospektiv nicht prüfbar. |
| NEW-47 | ✅ | Keine Callback-API in `TESTS/` wird synchron aufgerufen (alle Stubs rufen `cb`/`handlers` korrekt asynchron-förmig). |

## `REL-*` (34 Regeln — bereits 8 automatisiert grün)

Nur die 26 `manual`-IDs; die 8 automatisierten (`REL-01,05,06,07,13,16,
28,29`) sind bereits oben als `pass` bestätigt.

| ID | Status | Begründung |
| -- | ------ | ---------- |
| REL-02 | ✅ | ASCII-Art + 6 Badges am README-Beginn. |
| REL-03 | 🔶 | S. Fund #8. |
| REL-04 | ✅ | S. `NEW-12`. |
| REL-08 | ✅ | Die README-Beispiele (`setup()`/`ask()`/`stream()`) decken sich mit der echten, getesteten API. |
| REL-09 | ➖ | Kein Demo-GIF/Video — nice-to-have, für den aktuellen Beta-Stand plausibel noch offen. |
| REL-33 | ➖ | Kein Logo/Social-Preview-Bild — nice-to-have, gleiche Einordnung wie `REL-09`. |
| REL-10 | ✅ | `docs/installation.md` vorhanden. |
| REL-11 | ✅ | `docs/installation.md` zeigt `cmd = "Ai"` explizit. |
| REL-12 | ✅ | `config_spec.lua` verifiziert: `setup()` ohne Argumente liefert sinnvolle Defaults. |
| REL-14/15 | ➖ | Die tatsächliche Plugin-Spec liegt nicht in diesem Repo (wie die Regel selbst festhält). |
| REL-17 | ✅ | `health.lua` prüft echte Wahrheit (Curl-Executable, `fetch_stream`-Präsenz, Provider-Verfügbarkeit), nicht nur Datei-Vorhandensein. |
| REL-18 | ➖ | Regel selbst erlaubt Weglassen, wenn nicht state-of-the-art — hier bewusst nicht verdrahtet. |
| REL-19 | ➖ | Kein Beleg für tatsächliches manuelles Durchklicken auf beiden Plattformen im Repo auffindbar (die Regel selbst sagt, dass sich das nicht automatisiert prüfen lässt) — CI-Grün ist ein Indiz, kein Beweis. |
| REL-20/21/22/23/24 | ✅ | Spiegeln `NEW-21/22/23/24/28`, bereits bestätigt. |
| REL-25/26/27 | ✅ | S. `NEW-04/05/02` (`gh repo view`-Beleg). |
| REL-31 | ➖ | S. `NEW-18`. |
| REL-32 | ➖ | „Literatur und Referenzen" zielt auf Pläne/Studien, nicht auf ein Plugin-README. |
| REL-30 | ➖ | Obsolet laut Katalog selbst (s. `NEW-35`), kein eigener Prüfpunkt mehr. |
| REL-35 | ✅ | `grep -rn "wkdbook\|WKDBooks"` → 0 Treffer in `ai.nvim`. |
