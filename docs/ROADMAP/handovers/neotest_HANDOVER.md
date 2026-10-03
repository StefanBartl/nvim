# neotest (Übergabe): Lazy-Load, Listener, Windows-Läufe, Auto-Attach

Stand: 2026-10-03. **Die einzige Datei zu neotest in dieser Config.** Sie vereint, was vorher auf
drei Orte verteilt war: die Lazy-Load-Arbeit des Startup-Reports, die Aufgaben 1 und 4 des
Entscheidungs-Reports und die Untersuchung vom 2026-10-02/03. Die beiden Reports verweisen nur noch
hierher.

**Was heute gilt:** neotest lädt über eigene Auslöser, öffnet **keinen** `localhost`-Listener mehr
(kein Hilfsprozess), Testläufe mit `neotest-plenary` laufen unter Windows, und der Auto-Attach meldet
nichts mehr, wenn nichts läuft. Umgesetzt in `lua/config/neotest/init/windows_fixes.lua`,
`lua/config/neotest/core/init.lua` und `lua/plugins/neotest.lua`. Was noch fehlt, steht unter
[Offen](#offen).

---

## Table of content

  - [1. Lazy-Load von neotest (Startup-Arbeit)](#1-lazy-load-von-neotest-startup-arbeit)
  - [2. Der Befund vom 2026-10-02/03](#2-der-befund-vom-2026-10-023)
  - [3. Messungen](#3-messungen)
  - [4. Was gebaut wurde](#4-was-gebaut-wurde)
  - [5. Belege (Läufe mit der echten Config)](#5-belege-läufe-mit-der-echten-config)
  - [6. Verworfen und warum](#6-verworfen-und-warum)
  - [Offen](#offen)
  - [Wo liegt was](#wo-liegt-was)
  - [Live-Tests](#live-tests)
  - [Commits zu neotest](#commits-zu-neotest)

---

## 1. Lazy-Load von neotest (Startup-Arbeit)

Aus dem Startup-Report vom 2026-09-26, hierher übernommen.

- **Warum:** neotest kam als Dependency von neo-tree (das `filetree.nvim` auf `VeryLazy` lädt) bei
  jedem Start mit, ca. 150 ms (Adapter, vim-test, nio) direkt nach dem ersten Frame, Tests oder nicht.
- **Jetzt:** Auslöser sind seine Kommandos, seine `<leader>nt`-Tasten, eine Testdatei und neo-trees
  `tests`-Quelle (`config.neotest.neotree.load_with_tests_source`). Der Testdatei-Auslöser ist ein
  eigener Autocmd statt lazys `event` (`lua/plugins/neotest.lua`, `init`): lazys Event kennt kein "nach
  `VimEnter`", eine Testdatei als Argument lud neotest in `BufReadPost`, ca. 190 ms vor dem ersten
  Frame, und der Auto-Attach lief vor der Discovery ("No tests found"). Für eine Testdatei als
  Argument oder aus einer Session wartet der Auslöser deshalb auf `VeryLazy`.
- **Regel dazu** (gilt für jedes Plugin, das von "immer geladen" auf Bedarf umgestellt wird): **jedes**
  Kommando als Auslöser, das es oder seine Dependencies anlegen (hier fehlten zuerst `:Neotest` und die
  `:Test*` von vim-test), und prüfen, was der Auslöser **beim Start** tut.
- **Reviews (drei Runden)** fanden unter anderem: neotest startet den Client auch für offene
  Test-Buffer einer Session (`87a29e20`), und das Trennzeichen der auslösenden Datei muss das von
  neotest sein (`\`), sonst fand `edit E:/…` keine Projektwurzel (0 → 4 Signs, `a28ce217`). Bewusst
  stehen geblieben: die Event-Muster entsprechen `core.is_test_file`; für 100+ Testdateien kann der
  BufEnter-Attach der Discovery zuvorkommen.
- **Von Hand gegenprüfen** (war Entscheidung 4 des Startup-Reports): die Auslöser sind automatisiert
  getestet, nicht bedient. Auffallen würde ein `<leader>nt*`, das beim ersten Druck nichts tut, oder
  fehlende Statuszeichen in einer Testdatei, deren Name auf kein Muster in `lua/plugins/neotest.lua`
  passt. **Steht aus** (siehe [Live-Tests](#live-tests)).

## 2. Der Befund vom 2026-10-02/03

**Der Listener (Aufgabe 1 des Entscheidungs-Reports).** Beim Start des Clients öffnet neotest selbst
`serverstart("localhost:0")`, einen **unauthentifizierten TCP-RPC-Listener**
(`lib/subprocess.lua:36`, aufgerufen aus `client/init.lua:378-380`, ohne Option abschaltbar). Ein
zweiter nvim hat sich im Review ohne Zugangsdaten verbunden und per `nvim_exec_lua` Lua in der Sitzung
ausgeführt. Er öffnet sich schon beim ersten Besuch eines Test-Buffers. Der Hilfsprozess
(`nvim --embed --headless -n -u NONE`, zum Parsen) startete hier nie: `lib.nvim` `rpc_pipe` exportiert
`NVIM_LISTEN_ADDRESS`, das Kind versucht dieselbe Pipe zu belegen und scheitert. Der Listener blieb
also ungenutzt offen. **Den Listener benutzt nur der Hilfsprozess** (er verbindet sich per `sockconnect`
zurück und meldet darüber Ergebnisse); `serverlist`/`serverstop`/`rpcrequest`/`sockconnect` kommen sonst
nirgends in neotest, `neotest-plenary`, `nvim-nio`, `plenary.nvim`, der Config oder `rpc_pipe` vor.

**Niemand liest `NVIM_LISTEN_ADDRESS`** (nicht `lib.nvim`, kein Repo unter `E:\repos`, nicht die
Config, nicht Shell-, Terminal- oder Benutzer-Einstellungen). Der Kontextmenü-Launcher
(openinnvim) hängt am **Pipe-Namen** `\\.\pipe\nvim-<USERNAME>`, nicht an der Variable.

**Zwei voneinander unabhängige Fehler machten jeden `neotest-plenary`-Lauf unter Windows
unbrauchbar** (beide ohne Treiber reproduziert; sie überlagern sich):

1. **Vererbte `NVIM_LISTEN_ADDRESS`.** Der Test-Kindprozess erbt sie, Neovim bricht schon in C ab
   (`nvim.exe: Failed $NVIM_LISTEN_ADDRESS: address already in use`, Exit 1, keine Ergebnisdatei). In
   neotest: **9/9 failed bei jedem Lauf**. Eine **leere** Variable nur für das Kind genügt.
2. **Backslash-Pfade im Lua-String.** neotest-plenary baut
   `-c "lua _run_tests({results = '<tmp>', file = '<pfad>', ...})"` mit `nio.fn.escape(pos.path, "'")`
   (`adapter.lua:87`). Unter Windows ist der Pfad `C:\Users\…`; `\U` ist in LuaJIT eine ungültige
   Escape-Sequenz, das `-c` schlägt fehl, und `run_tests.lua` beendet sich nur per `os.exit`
   **innerhalb** von `_run_tests`: der headless Kindprozess bleibt für immer stehen (idle, 0 s CPU, pro
   Lauf ein weiterer). Mit Schrägstrichen endet dieselbe Kommandozeile nach 0 s. Upstream ist
   unverändert. Zeigt sich erst, wenn Fehler 1 behoben ist (Option B alleine, "nicht mehr exportieren",
   hätte nur den Hänger sichtbar gemacht).

**Auto-Attach (Aufgabe 4).** `lua/config/neotest/core/init.lua` rief bei jedem BufEnter eines
Testbuffers `neotest.run.attach()`, auch wenn nichts lief. Das ergab bei **jedem** Besuch eine Meldung
("No running process found", oder bei 100+ Testdateien "No tests found"). Nebenbei startete dieser
Aufruf den Client und löste die Discovery (die Statuszeichen) aus: ein Gate darf das nicht kappen.

**Neovim gibt Kindern von sich aus `$NVIM`, nicht `NVIM_LISTEN_ADDRESS`** (für `vim.fn.system` geprüft;
beides leer). Die Variable kommt allein aus `rpc_pipe`.

## 3. Messungen

Methode: `scripts/startup-probe/bench.lua 5 tui` (5 Läufe plus Aufwärmlauf, Median / Min / Max), echte
TUI über Pseudo-Terminal, Neovim 0.12.2, Windows 11, STEVESPC. Der "erlaubte Hilfsprozess" kam von
einem Wegwerf-Skript, das bei `VimEnter` `NVIM_LISTEN_ADDRESS` entfernte.

| Szenario | Stoßsumme | längster Stoß | Belegung gesamt |
| --- | ---: | ---: | ---: |
| ohne Testdatei (neotest bleibt ungeladen) | 606 (546-673) | 374 | 1010 |
| 1 Testdatei (9 Tests), Listener wie bisher | 1073 (975-1176) | 596 | 1553 |
| 1 Testdatei (9 Tests), Hilfsprozess erlaubt | 1148 (1139-1298) | 734 | 1640 |
| 100 Specs (1000 Tests), Listener wie bisher | 1128 (1036-1257) | 578 | 1755 |
| 100 Specs (1000 Tests), Hilfsprozess erlaubt | 1277 (1227-1400) | 696 | 1828 |

Einheit ms, Median (Min-Max). Der Hilfsprozess kostet **+75 / +149 ms** Stoßsumme, bringt keinen
sichtbaren Gewinn und schließt den Listener nicht (er verbindet sich an ihn, TCP `Established`).
Grenzen: synthetische Projekte, eine Maschine, Last schwankt (15 % und mehr). Wiederholung und
Scratch-Projekte: `WKDBooks/.../TOOLS/neotest-run-probe.md`.

**Entscheidung dadurch:** Der Hilfsprozess lohnt sich nicht (kostet Zeit, hält den Listener offen).
Also: gar nicht erst öffnen.

## 4. Was gebaut wurde

Alles in dieser Config; `lib.nvim` bleibt unverändert.

1. **`lua/config/neotest/init/windows_fixes.lua`** (neu), aufgerufen aus dem `config` von
   `lua/plugins/neotest.lua` vor `neotest.setup()`:
   - `disable_parse_subprocess()`: ersetzt `require("neotest.lib.subprocess").init` durch eine leere
     Funktion. `init()` ist die **einzige** Stelle, die den Listener öffnet und den Hilfsprozess
     startet; der Client ruft sie nur, solange `enabled()` falsch ist (`client/init.lua:378`), und
     `neotest.lib` erreicht das Modul über `lazy_require` (`lib/require.lua`), das `init` bei jedem
     Aufruf nachschlägt. Alle anderen Nutzer von `subprocess.*` sind mit `enabled()` abgesichert
     (`client/init.lua:576`, `treesitter/init.lua:176`, `watch/watcher.lua:44`); der
     Benchmark-Consumer (`force=true`) landet ebenfalls im No-Op. Neotest parst dann im Hauptprozess,
     wie es hier faktisch schon immer war. **Kein Listener, kein Hilfsprozess, kein `serverstop` nötig.**
   - `fix_plenary_adapter(adapter)`: umhüllt `build_spec` von `require("neotest-plenary")` (das ist die
     Adapter-Tabelle selbst): im Argument `lua _run_tests(` `\` → `/`, und `spec.env` bekommt
     `NVIM_LISTEN_ADDRESS = ""` nur für den Test-Kindprozess.
2. **`lua/config/neotest/core/init.lua`**: der BufEnter-Autocmd fragt über `get_tree_from_args` (startet
   den Client still, Discovery und Signs wie zuvor) nach dem Baum der Datei und ruft `run.attach` nur,
   wenn `M.has_running(neotest, bufnr)` wahr ist (`state.status_counts(id, {buffer = bufnr}).running >
   0`). Buffer und Datei werden vor `vim.schedule` festgehalten, mit neotests Trennzeichen.
3. **`lua/plugins/neotest.lua`**: der Kommentar zum Listener ist entfernt (er stimmt nicht mehr); ein
   Verweis auf diese Datei steht am `config`.

## 5. Belege (Läufe mit der echten Config)

Werkzeug: `WKDBooks/.../TOOLS/scripts/neotest-run-probe/run.ps1` (headless Kern mit der echten Config
über Junction und `XDG_CONFIG_HOME`, `USERNAME` gefälscht, nur eigene Prozesse). Die Läufe vom 2026-10-03:

| Lauf | Ergebnis |
| --- | --- |
| Config vor dem Umbau, drei Läufe (Datei, Datei erneut, nächster Test) | **9/9 failed**, Listener `localhost:<port>` offen |
| Prototyp-Fix nur zur Laufzeit (`-Patch`) | 8 passed / 1 failed (der eine ist absichtlich rot), 0,5-1,5 s je Lauf |
| Prototyp-Fix + `serverstop` (Option D) | unverändert 8/1; Listener danach weg und **nicht wieder offen** |
| **Config nach dem Umbau, ohne Schalter** | **8 passed / 1 failed bei allen drei Läufen**, `subprocess_enabled = false`, in **keinem** Zwischenstand ein `localhost:`-Eintrag in `serverlist()`, kein Hilfsprozess |
| Attach, nichts läuft: alte Logik, vier Besuche zweier Testdateien | **4 Meldungen** "No running process found", Signs 11 → 13 |
| Attach, nichts läuft: neue Logik, dieselben Besuche | **0 Meldungen**, `attach` nie aufgerufen, Discovery und Signs **identisch** (11 → 13) |
| Attach, ein Test in Datei B läuft (7 s), B betreten | `attach` wird aufgerufen (Fall, für den das Feature da ist) |
| Nicht-Testbuffer betreten | `attach` wird nicht aufgerufen |

**Bekannte Grenze des Gates:** neotest zählt als "läuft" auch die **Elternknoten** (Ordner, Wurzel) im
Baum eines Buffers. Läuft irgendwo unter derselben Wurzel ein Test, zeigt `status_counts` auch für eine
Geschwister-Datei `running = 1` (gemessen: Buffer A ohne laufenden Test, B läuft, beide `running = 1`
für den Adapter mit der Wurzel `proj\tests`). Dann feuert `attach` für A und meldet einmal "No running
process found": das alte Verhalten, aber nur noch **während ein Lauf in einer Nachbardatei läuft**, nicht
bei jedem Besuch. Genauer geht es nicht ohne neotests interne Client-API (`Client:is_running`).

## 6. Verworfen und warum

- **A, "so lassen und dokumentieren"**: der Listener bleibt offen, und die Testläufe blieben kaputt.
- **B, `rpc_pipe` exportiert die Variable nicht mehr**: dann startet der Hilfsprozess (+75 bis +150 ms),
  der Listener wäre in Benutzung (`serverstop` unmöglich), und die Läufe hängen weiter an Fehler 2.
  Außerdem berührt es `lib.nvim` (alle Kinder). Nicht nötig, weil Option E beide Fehler lokal löst.
- **C, Client nur auf Abruf**: die Signs in offenen Testbuffern entfielen bis zur ersten Benutzung.
- **D, `serverstop` nach dem Start**: funktioniert (siehe Belege), lässt den Listener aber kurz offen
  und hängt an neotests Internas. Option E verhindert, dass er je entsteht.
- **Ein Gate mit `status_counts` allein, ohne den stillen Client-Start**: hätte die Discovery und damit
  die Statuszeichen gekappt (der alte `attach`-Aufruf war der Auslöser).
- **Das Probe-Tool in WKDBooks um einen `STUB`-Schalter erweitern**: vom Nutzer abgelehnt; die
  Varianten liefen auf Kopien im Scratch, das Tool selbst blieb unverändert.

## Offen

- [ ] **In der echten TUI bedienen:** `<leader>nt*` beim ersten Druck, Statuszeichen in einer
      Testdatei, ein Lauf, Zusammenfassung (`<leader>nts`), Test-Buffer-Wechsel. Alle Belege oben sind
      headless (ohne UI) mit einem `--clean`-Projekt; die echte Sitzung (which-key, Plugins, deine Specs)
      ist nicht geprüft. Siehe [Live-Tests](#live-tests).
- [ ] **Signs nach einem Lauf in der TUI:** headless geprüft sind Counts und Signs vor dem Lauf, nicht
      das Aussehen nach dem Lauf.
- [ ] **Upstream:** Issue/PR an `nvim-neotest/neotest-plenary`: `adapter.lua:87` (Pfade in einem
      Lua-String, unter Windows ungültige Escapes) und an `nvim-neotest/neotest`: der Listener in
      `subprocess.init` ohne Option zum Abschalten (`lib/subprocess.lua:36`). Texte noch nicht
      geschrieben.
- [ ] **`lib.nvim` `rpc_pipe`** exportiert `NVIM_LISTEN_ADDRESS` weiterhin und tötet damit **jedes
      andere** Kind-`nvim` (`run_all_tests.sh`, `example-plugin/minimal_init.lua` und ein alter
      gitsigns-Patch entfernen die Variable deshalb selbst). Für neotest nicht mehr nötig;
      grundsätzlich wäre "nicht exportieren" richtig (null Leser, siehe Abschnitt 2), mit Anpassung von
      `is_active()`/`get_address()` (keine Aufrufer außerhalb des Moduls) und der README
      (`lua/lib/nvim/system/README.md:116-149`, `@types/init.lua:50-55`). Eigene Entscheidung, berührt
      alle Plugins.
- [ ] Die Messskripte (`NT_ALLOW`/`NT_DUMP`-Hilfsskript, Scratch-Projekte mit 9 bzw. 1000 Tests) bei
      Bedarf nach `WKDBooks/.../TOOLS/` legen; sie waren Wegwerf. Die Attach-Szenarien dieses Chats
      (`driver4.lua`, `slow_spec.lua`) lagen im Scratchpad und sind nicht abgelegt.
- [ ] Wurzel der Startup-Frage 5 und die übrigen Punkte des Startup-Reports betreffen neotest nicht und
      stehen weiter dort.

## Wo liegt was

| Was | Ort |
| --- | --- |
| Der Umbau | `lua/config/neotest/init/windows_fixes.lua`, `lua/config/neotest/core/init.lua`, `lua/plugins/neotest.lua` |
| Probe-Tool für neotest-Läufe mit der echten Config (headless Kern, `-Patch`, `-Stop`, `-Unset`), Rezept und Fallen | `WKDBooks/Development/wkdbook-myplugins/TOOLS/neotest-run-probe.md`, `TOOLS/scripts/neotest-run-probe/` |
| Messtabellen und Optionen A–D im Detail | `WKDBooks/.../openinnvim/Backlog/TASKS/2026-10-02_neotest-listener-messung.md` |
| Untersuchung, wer `NVIM_LISTEN_ADDRESS` liest | `WKDBooks/.../openinnvim/Backlog/TASKS/2026-10-02_nvim-listen-address-und-kontextmenue.md` |
| Startup-Gesamtbild (neotest ist dort nur noch ein Verweis) | `docs/ROADMAP/reports/startup-und-config-optimierung-analyse-konzept-2026-09-26.md`, `docs/ROADMAP/reports/startup-offene-entscheidungen-und-neotest-listener-2026-10-02.md` |
| Archiv des Startup-Verlaufs samt drei Reviews | `WKDBooks/Development/wkdbook-myplugins/nvim-config/Backlog/TASKS/startup-und-config-optimierung-2026-09-26.md` |

## Live-Tests

Von Hand in der echten Sitzung. Status: ❌ ungetestet · ✅ wie erwartet · 🔴 Fehler (Notiz!).

| # | Was testen | Erwartung | Status | Notizen |
| --- | --- | --- | --- | --- |
| K1 | Neovim starten, `:echo serverlist()`, dann eine Testdatei öffnen und wieder `:echo serverlist()` | Enthält `nvim.<pid>.0` und die fzf-lua-Pipe, **nie** einen `localhost:<port>`-Eintrag | ❌ | |
| K2 | Erster `<leader>nt*`-Druck der Sitzung (z. B. Testdatei, `<leader>ntf`) | Der Lauf startet beim ersten Druck, Ergebnisse und Statuszeichen kommen | ❌ | |
| K3 | Lauf einer Datei mit einem absichtlich roten Test, danach `<leader>nts` (Zusammenfassung) | Rot/grün stimmt, Zusammenfassung zeigt die Ergebnisse | ❌ | |
| K4 | Nächster Test (`<leader>ntt`), Lauf zweimal hintereinander | Beide Läufe enden (kein hängender `nvim`-Kindprozess in `Get-Process nvim` danach) | ❌ | |
| K5 | Testdatei betreten und verlassen, nichts läuft | Keine Meldung "No running process found" / "No tests found" | ❌ | |
| K6 | Lange laufenden Test starten, dessen Datei betreten | Der Attach geschieht (Ausgabe der laufenden Datei), keine Fehlermeldung | ❌ | |
| K7 | Testdatei als Kommandozeilenargument und als Teil einer Session | Statuszeichen erscheinen nach dem ersten Frame (nicht davor) | ❌ | |
| K8 | Kontextmenü-Klicks (openinnvim) während neotest läuft | Landen in der Hauptsitzung; sie brauchen nur die Pipe | ❌ | |

## Commits zu neotest

| Repo | Commit | Inhalt |
| --- | --- | --- |
| nvim-config | `1e34a249`, `190a896e` | neotest und sandbox.nvim aus der `VeryLazy`-Welle; Review-Fixes (`:Neotest`, vim-test) |
| nvim-config | `737a27b3` | neotest für eine Testdatei als Argument erst nach `VeryLazy` |
| nvim-config | `e80d52f6` | Neotest-Doku in `docs/NOTES/ExternPlugins/Bindings` angepasst |
| nvim-config | `87a29e20` | Client auch für offene Test-Buffer (Session) |
| nvim-config | `a28ce217` | Trennzeichen der auslösenden Datei normalisiert (0 → 4 Signs bei `edit E:/…`) |
| WKDBooks | `3251163` | Probe-Tool `neotest-run-probe` mit den zwei Windows-Befunden |
| nvim-config | (siehe Git-Log) | Umbau: kein Listener, Plenary-Läufe unter Windows, Attach-Gate, diese Datei |
