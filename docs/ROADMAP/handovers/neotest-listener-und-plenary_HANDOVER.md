# neotest unter Windows: Listener, NVIM_LISTEN_ADDRESS, scheiternde Läufe (Übergabe)

Stand: 2026-10-03. Abgetrennt aus dem gemeinsamen Handover mit openinnvim (das liegt jetzt in
`E:\repos\openinnvim\docs\HANDOVER.md`). **Nichts hiervon ist eingebaut; es fehlt die Entscheidung
des Nutzers.**

Quelle der Aufgabe:
[`startup-offene-entscheidungen-und-neotest-listener-2026-10-02.md`](../reports/startup-offene-entscheidungen-und-neotest-listener-2026-10-02.md)
(Aufgabe 1; Aufgabe 4 und der Punkt "neotest von Hand bedienen" hängen an derselben Testanordnung).

---

## Table of content

  - [Kurzfassung](#kurzfassung)
  - [Wo liegt was](#wo-liegt-was)
  - [Offen und Nachfrage](#offen-und-nachfrage)

---

## Kurzfassung

- **Niemand liest `NVIM_LISTEN_ADDRESS`** (nicht lib.nvim, kein Repo unter `E:\repos`, nicht die
  Config, nicht Shell-/Terminal-Einstellungen). `rpc_pipe` exportiert sie nur, damit
  neotests Hilfsprozess nicht dieselbe Pipe belegen will. Das Kontextmenü-Tool hängt am
  **Pipe-Namen**, nicht am Export.
- **neotest-Listener: Messung fertig, Entscheidung offen — und der Befund ist größer als die
  Frage.** Den Hilfsprozess starten zu lassen kostet etwa +75 bis +150 ms, bringt keinen Gewinn
  und schließt den Listener nicht. Der Laufzeittest zeigte zusätzlich: **`neotest-plenary`-Läufe
  scheitern in dieser Config unter Windows heute alle** (vererbte `NVIM_LISTEN_ADDRESS` tötet den
  Test-Kindprozess, 9/9 failed; danach hängt er an Backslash-Pfaden im Lua-String). Ein
  Config-Fix im Adapter-Wrapper + `serverstop` (D) lässt alle Läufe mit 8 passed / 1 failed
  durchlaufen. Nichts davon wurde eingebaut; Details unter "Offen".

---

## Wo liegt was

| Was | Ort |
| --- | --- |
| Messtabellen, Optionen A–D, Wiederholung der Messung | `WKDBooks/Development/wkdbook-myplugins/openinnvim/Backlog/TASKS/2026-10-02_neotest-listener-messung.md` |
| Probe-Tool für neotest-Läufe mit der echten Config, samt Befund | `WKDBooks/.../TOOLS/neotest-run-probe.md`, `TOOLS/scripts/neotest-run-probe/` (`3251163`) |
| Untersuchung, wer `NVIM_LISTEN_ADDRESS` liest | `WKDBooks/.../openinnvim/Backlog/TASKS/2026-10-02_nvim-listen-address-und-kontextmenue.md` |
| Betroffene Stellen | `lua/plugins/neotest.lua`, `lua/config/neotest/core/init.lua`, `lib.nvim` `lua/lib/nvim/system/rpc_pipe.lua` |

---

## Offen und Nachfrage

- [ ] **neotest unter Windows: Entscheidung nötig, und sie ist größer als "Listener A oder D".**
      Der Laufzeittest ist jetzt gelaufen (echte Config, headless-Kern, echtes neotest-plenary;
      Werkzeug und Befund: `WKDBooks/.../TOOLS/neotest-run-probe.md`, Skripte
      `TOOLS/scripts/neotest-run-probe/run.ps1`, Commit `3251163`). **Ergebnis: Testläufe mit
      `neotest-plenary` scheitern in dieser Config heute alle, wegen zweier voneinander
      unabhängiger Fehler:**
      1. `lib.nvim` `rpc_pipe` exportiert `NVIM_LISTEN_ADDRESS`; der Test-Kindprozess erbt sie und Neovim
         bricht in C ab (`Failed $NVIM_LISTEN_ADDRESS: address already in use`, Exit 1, keine
         Ergebnisdatei). In neotest: **9/9 failed bei jedem Lauf** (Datei, Datei erneut, nächster Test).
         Ohne Treiber reproduziert (Wegwerf-`nvim --listen`, Plenary-Befehl mit der Variable). Eine
         **leere** Variable nur für den Kindprozess genügt.
      2. Backslash-Pfade im Lua-String `-c "lua _run_tests({file = 'C:\Users\...'})"`: `\U` ist eine
         ungültige Escape-Sequenz, der Kindprozess bleibt headless stehen (idle, nie beendet, pro Lauf ein
         weiterer). Mit Schrägstrichen endet derselbe Befehl nach 0 s. Das zeigt sich erst, wenn 1.
         behoben ist (Option B alleine reicht also nicht: Hilfsprozess läuft, Läufe hängen).
      **Prototyp-Fix (nur Laufzeit, nichts im Repo geändert):** `build_spec` des Adapters umhüllen,
      im Argument `lua _run_tests(` `\` durch `/` ersetzen und `spec.env.NVIM_LISTEN_ADDRESS = ""`
      setzen. Ergebnis: **8 passed / 1 failed (absichtlich rot) bei allen drei Läufen**, ca. 0,5 bis 1,5 s je
      Lauf, der neotest-Hilfsprozess bleibt aus. **Mit zusätzlichem `serverstop`** auf den `localhost:`-Listener
      (Option D) laufen die Läufe unverändert, der Eintrag fehlt danach in `serverlist()` und **geht nicht
      wieder auf** (nach drei Läufen geprüft); `\\.\pipe\nvim-<USERNAME>` bleibt.
      **Zu entscheiden:** (a) nur Config-Fix im Adapter-Wrapper (`lua/plugins/neotest.lua`, lokal, berührt
      kein anderes Plugin) + D, oder (b) zusätzlich `rpc_pipe` ändern (nicht mehr exportieren; dann startet
      der Hilfsprozess, +75 bis +150 ms, Listener in Benutzung, D entfällt) — die Config-Variante (a)
      ist die kleinere und deckt beide Fehler ab. Beides ändert Verhalten und wurde **nicht** eingebaut.
      Ursache von Fehler 2 liegt im Upstream-Plugin (`neotest-plenary/adapter.lua`, `nio.fn.escape(pos.path,
      "'")`): ein Issue/PR wäre angebracht.
      **Nicht geprüft:** Signs nach `serverstop` (der Code spricht dafür: nur der Hilfsprozess benutzt den
      Listener, siehe unten), ein Lauf in einer interaktiven TUI-Sitzung über which-key, mehrere
      Test-Buffer, der positive Fall des Attach-Fixes (Aufgabe 4: Lauf in Datei A, Test-Buffer B öffnen;
      Agent 2 ist nie fertig geworden), die Ausgabe von `neotest.output` im Fehlerfall.
      Code-Lesung (Agent 1): der Listener (`lib/subprocess.lua:33-37`, `serverstart("localhost:0")`) geht
      nur an den Hilfsprozess, der sich per `sockconnect` zurückverbindet; `serverlist`/`serverstop`/
      `rpcrequest`/`sockconnect` kommen sonst nirgends in neotest, `neotest-plenary`, `nvim-nio`,
      `plenary.nvim`, Config oder `rpc_pipe` vor. Läuft der Hilfsprozess nicht, parst neotest im Hauptprozess
      (`treesitter/init.lua:176`). Ein Wiederöffnen gibt es nur über den erzwungenen Neustart des
      Benchmark-Consumers (`consumers/benchmark.lua:33`). Falls D: direkt nach dem Start des Clients,
      mit `pcall`, nur **neue** Einträge schließen, die auf `^localhost:%d+$` (oder `127.0.0.1:`) passen, und
      nur wenn `require("neotest.lib").subprocess.enabled()` falsch ist.
      **Bessere Lösung, im vierten Chat am Quelltext belegt, aber noch nicht gefahren ("Option E"):**
      `subprocess.init()` (`neotest/lib/subprocess.lua:33-37`) ist die **einzige** Stelle, die den
      Listener öffnet und den Hilfsprozess startet, und `client/init.lua:378` ruft sie nur, wenn
      `enabled()` falsch ist. `neotest.lib` greift per `lazy_require` (`lib/require.lua`: `__index`
      ruft `require(module)[key]` zur Laufzeit) auf das Modul zu, also macht
      `require("neotest.lib.subprocess").init = function() end` (nach dem Laden von neotest, vor dem
      Client-Start) den Aufruf zum No-Op: **kein Listener je offen, kein Hilfsprozess, kein
      `serverstop` nötig**, Parsen im Hauptprozess wie heute faktisch. Alle anderen Nutzer von
      `subprocess.*` sind mit `enabled()` abgesichert (`client/init.lua:576`, `treesitter/init.lua:176`,
      `watch/watcher.lua:44`); der Benchmark-Consumer (`force=true`) landet ebenfalls im No-Op.
      Dazu: (ii) `lib.nvim` `rpc_pipe.lua` exportiert `NVIM_LISTEN_ADDRESS` nicht mehr (Option
      `export = false` als Standard; `setup` nimmt aus `init.lua:128` schon eine Opts-Tabelle;
      `is_active()`/`get_address()` haben **keine** Aufrufer außerhalb des Moduls und sollen den
      gestarteten Pipe-Namen statt der Variable melden; README `lua/lib/nvim/system/README.md:116-149`
      und `@types/init.lua:50-55` anpassen). Der Export hat null Leser und tötet jeden Kind-`nvim`
      (`run_all_tests.sh`, `example-plugin/minimal_init.lua` und ein alter gitsigns-Patch entfernen die
      Variable deshalb selbst). Neovim gibt Kindern von sich aus `$NVIM`, nicht
      `NVIM_LISTEN_ADDRESS` (für `vim.fn.system` geprüft: beides leer; für `jobstart`-Kinder noch
      nicht). (iii) Plenary-Shim in `lua/plugins/neotest.lua`: `require("neotest-plenary")` ist die
      Adapter-Tabelle selbst (`init.lua:3`), `build_spec` darauf umhüllen, im Argument
      `lua _run_tests(` nur `\` → `/`; mit (ii) entfällt das `spec.env`. Upstream ist unverändert
      (`origin/HEAD`, `adapter.lua:87` mit `nio.fn.escape(pos.path, "'")`); `run_tests.lua` beendet sich
      nur per `os.exit` **innerhalb** von `_run_tests` (Zeile 39/94), darum der Hänger. (iv) Attach-Gate
      in `lua/config/neotest/core/init.lua:64-71`: `Client:attach` meldet "No running process found",
      wenn `_get_running_adapters(position.id)` leer ist (`client/init.lua:133-136`), `TestRunner:attach`
      sucht den Prozess über die Eltern der Position (`runner.lua:210-218`); der Gate über
      `status_counts(id, { buffer = bufnr }).running > 0` passt dazu. Ein manuelles Attach-Mapping gibt
      es in der Config nicht (nur der Autocmd). Noch zu fahren (Phase 4 des Workflows): S0 heute, S1
      Stub + kein Export + Slash-Shim, S2 Stub + Shim mit `spec.env`, S3 nur Stub (muss 9/9 failed
      bleiben), S4 kein Export ohne Stub (Hilfsprozess läuft), S5 Option D; Attach-Fix positiv/negativ.
      Das Probe-Tool in WKDBooks hat noch keinen `STUB`-Schalter; der Nutzer hat eine Änderung daran im
      vierten Chat abgelehnt — Varianten auf einer Kopie im Scratch fahren.
- [ ] Die Messskripte (`NT_ALLOW`/`NT_DUMP`-Hilfsskript und Scratch-Projekte mit 9 bzw. 1000
      Tests) bei Bedarf nach `WKDBooks/.../TOOLS/` legen; sie waren Wegwerf und liegen nicht
      mehr. Die Wiederholung der Messung steht in der Backlog-Datei zur neotest-Messung.
