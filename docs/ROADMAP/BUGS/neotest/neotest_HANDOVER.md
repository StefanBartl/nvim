# neotest (Übergabe): was noch offen ist

Stand: 2026-10-03. **Umgesetzt und in der echten TUI bestätigt** (lazy geladen, kein
`localhost`-Listener, Plenary-Läufe unter Windows, stilles Auto-Attach; `lib.nvim` `rpc_pipe`
exportiert `NVIM_LISTEN_ADDRESS` nicht mehr). Diese Datei enthält nur, was noch zu tun ist. Alles
Erledigte, die Befunde, Messungen, Belege und verworfenen Wege stehen im Archiv (siehe
[Wo liegt was](#wo-liegt-was)); nichts davon muss neu erarbeitet werden.

## Table of content

  - [Offen](#offen)
  - [Wo liegt was](#wo-liegt-was)
  - [Kurzfassung des Erledigten](#kurzfassung-des-erledigten)
  - [Live-Tests](#live-tests)

---

## Offen

- [ ] **Upstream melden.** Der fertige Report samt Kommentar für `neotest-plenary#17` und Issue-Text
      für `neotest` (unauthentifizierter `localhost`-Listener) liegt in
      [`../BUGS/UPSTREAM-neotest-windows-plenary-and-listener.md`](../BUGS/UPSTREAM-neotest-windows-plenary-and-listener.md).
      Nicht gepostet, braucht ein ausdrückliches Ja. Vorher entscheiden: Listener-Issue öffentlich
      oder als Security Advisory (Abschnitt "Severity" im Report); "Before filing" abarbeiten. Beim
      Posten Status-Log im Report ergänzen. Wenn upstream behoben ist, den lokalen Workaround
      entfernen (`lua/config/neotest/init/windows_fixes.lua`, Aufruf in `lua/plugins/neotest.lua`).
- [ ] **K8 von Hand (optional):** ein Kontextmenü-Klick (openinnvim) während neotest läuft landet in
      der Hauptsitzung. Nur die Pipe wird gebraucht, `rpc_pipe` ist jetzt ohne Export; die Pipe selbst
      ist mit der echten Config geprüft.
- [ ] **Signs-Optik in der eigenen Sitzung** ansehen (die TUI-Läufe liefen in einem versteckten
      Konsolenfenster mit Test-Projekt, nicht in deiner Sitzung mit deinen Specs).
- [ ] Die Szenarien dieses Chats (Attach-Treiber, TUI-`scenario.lua`/`run.ps1`, Messskripte) lagen im
      Scratchpad und sind nicht abgelegt. Nur bei Bedarf nach `WKDBooks/.../TOOLS/` (TOOL-PLACEMENT.md
      beachten); das Rezept steht im Archiv, Abschnitt 5.

## Wo liegt was

| Was | Ort |
| --- | --- |
| Der Umbau (Code) | `lua/config/neotest/init/windows_fixes.lua`, `lua/config/neotest/core/init.lua`, `lua/plugins/neotest.lua` |
| **Archiv mit allem Erledigten:** Lazy-Load, Befund, Messungen, Belege (headless + echte TUI), verworfene Optionen A-D, Live-Tests, Commits | `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/nvim-config/Backlog/TASKS/neotest-listener-und-windows-laeufe-2026-10-03.md` |
| Upstream-Report mit fertigen Texten | [`../BUGS/UPSTREAM-neotest-windows-plenary-and-listener.md`](../BUGS/UPSTREAM-neotest-windows-plenary-and-listener.md) |
| Probe-Tool für neotest-Läufe mit der echten Config (headless Kern, `-Patch`, `-Stop`, `-Unset`) | `WKDBooks/.../TOOLS/neotest-run-probe.md`, `TOOLS/scripts/neotest-run-probe/` |
| Messtabellen und Optionen im Detail | `WKDBooks/.../openinnvim/Backlog/TASKS/2026-10-02_neotest-listener-messung.md` |
| `rpc_pipe`-Änderung (kein Export, Spec) | lib.nvim `47ba2fc`: `lua/lib/nvim/system/rpc_pipe.lua`, `TESTS/system_rpc_pipe_spec.lua` |
| Startup-Gesamtbild (neotest nur Verweis) | `docs/ROADMAP/reports/startup-und-config-optimierung-analyse-konzept-2026-09-26.md`, `docs/ROADMAP/reports/startup-offene-entscheidungen-und-neotest-listener-2026-10-02.md` |

## Kurzfassung des Erledigten

Damit niemand das Archiv öffnen muss, um den Stand zu kennen:

- **Lazy-Load:** neotest lädt über seine Kommandos, `<leader>nt`-Tasten, eine Testdatei und neo-trees
  `tests`-Quelle (statt ~150 ms nach jedem Start). Eine Testdatei als Argument wartet auf `VeryLazy`.
- **Listener:** neotests `subprocess.init()` (`serverstart("localhost:0")`, unauthentifiziert) wird
  durch einen No-Op ersetzt; neotest parst im Hauptprozess. Der Hilfsprozess hätte +75 bis +150 ms
  gekostet und den Listener nicht geschlossen.
- **Zwei Windows-Fehler in `neotest-plenary`** (beide überlagern sich): vererbte
  `NVIM_LISTEN_ADDRESS` (Kind stirbt in C) und Backslash-Pfade im `-c`-String (Kind hängt für immer).
  Der Shim setzt `\` → `/` und `NVIM_LISTEN_ADDRESS=""` für das Kind. Ergebnis: 8 passed / 1 failed
  bei allen Läufen.
- **Auto-Attach:** `run.attach` nur noch, wenn im Buffer wirklich etwas läuft; sonst stiller
  Client-Start über `get_tree_from_args` (Signs bleiben). Bekannte Grenze: läuft eine Geschwisterdatei
  unter derselben Wurzel, kann einmal "No running process found" erscheinen.
- **`rpc_pipe`:** exportierte `NVIM_LISTEN_ADDRESS` und tötete damit jedes Kind-nvim (system, jobstart,
  Terminal). Jetzt kein Export mehr (Opt-in `export = true`), Pipe-Name unverändert.
- **Falle:** `vim.system` ohne `env` reicht spätere `vim.env`-Schreibzugriffe nicht ans Kind weiter;
  `vim.fn.system`/`jobstart` schon. Beim Testen von Vererbung `vim.fn.system` nehmen.

## Live-Tests

Status: ❌ ungetestet · ✅ wie erwartet · 🔴 Fehler. K1-K7 am 2026-10-03 in der echten TUI geprüft
(verstecktes Konsolenfenster, echte Config, echte Tasten), Details im Archiv.

| # | Was | Status |
| --- | --- | --- |
| K1 | kein `localhost:<port>` in `serverlist()` | ✅ |
| K2 | erster `<leader>nt*`-Druck lädt neotest und läuft | ✅ |
| K3 | roter Test, Summary rendert | ✅ |
| K4 | zwei Läufe, kein hängendes Kind | ✅ |
| K5 | Testbuffer betreten/verlassen ohne Meldung | ✅ |
| K6 | Attach auf laufenden Test | ✅ (nur headless) |
| K7 | Testdatei als Argument/Session: Signs nach dem ersten Frame | ✅ |
| K8 | Kontextmenü-Klick während neotest läuft | ❌ (optional, von Hand) |
