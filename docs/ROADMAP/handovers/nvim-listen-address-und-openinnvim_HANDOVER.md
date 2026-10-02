# NVIM_LISTEN_ADDRESS (rpc_pipe), neotest-Listener und openinnvim (Übergabe)

Stand: 2026-10-02, nach drei Chats. **Nur noch offene Punkte.** Alles Erledigte liegt im
Backlog des WKDBooks (siehe [Wo liegt was](#wo-liegt-was)); die Live-Tests, die du von Hand
machen sollst, stehen in
[`Final_Checks/openinnvim-live-tests-2026-10-02.md`](../Final_Checks/openinnvim-live-tests-2026-10-02.md).

Quellen: die neotest-Aufgabe aus
[`startup-offene-entscheidungen-und-neotest-listener-2026-10-02.md`](../reports/startup-offene-entscheidungen-und-neotest-listener-2026-10-02.md)
(Aufgabe 1; Aufgabe 4 und der Punkt "neotest von Hand bedienen" hängen an derselben
Testanordnung) und die Suche nach dem Windows-Kontextmenü-Eintrag "In Neovim öffnen".

---

## Table of content

  - [Kurzfassung](#kurzfassung)
  - [Wo liegt was](#wo-liegt-was)
  - [Offen und Nachfrage](#offen-und-nachfrage)
  - [Commits dieses Chats](#commits-dieses-chats)

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
- **openinnvim ist fertig gebaut und im Review geprüft** (`E:\repos\openinnvim`): Instanzsuche
  über die Standard-Pipes mit UI-Prüfung, Öffnen per RPC (ohne zweiten `nvim.exe`),
  Ordner in `:Filetree open`, **kein `nvr` mehr** (keine externe Abhängigkeit), beide
  Launcher mit korrektem Quoting. README und `docs/` nach dem Plugin-Standard.
  **Der echte Klick im Explorer ist noch nicht von dir abgenommen.**
- **Installation ist jetzt ein Skript** (`install.ps1`, `uninstall.ps1`): findet `nvim.exe`, kopiert
  nach `%LOCALAPPDATA%\OpenInNvim`, schreibt die Config und die 6 Einträge; die VBS finden ihr
  `.ps1` relativ zu sich selbst, die Junction `C:\tools\OpenInNvim` wird überflüssig. Neu außerdem:
  opt-in Fokus (`FOCUS_TERMINAL`). **Noch nicht ausgeführt** — das machst du (Final_Checks, Teil G).
- **Wirkung auf die echte Sitzung:** Bis du `install.ps1` ausführst, zeigen die Einträge über die
  Junction auf das Repo und benutzen also **schon jetzt** den neuen Launcher (die VBS dort sind
  inzwischen relativ).

---

## Wo liegt was

| Was | Ort |
| --- | --- |
| Repo | `E:\repos\openinnvim`, GitHub `StefanBartl/openinnvim` (alter Name `open-in-nvim` leitet weiter) |
| Offene Arbeit am Tool | `WKDBooks/Development/wkdbook-myplugins/openinnvim/ROADMAP/ROADMAP.md` |
| Bauprotokoll des Launchers | `.../openinnvim/Backlog/FEATURES/2026-10-02_current-instance-launcher.md` |
| Untersuchung `rpc_pipe`, Umzug, Junction-Reparatur, Registry-Prüfung | `.../openinnvim/Backlog/TASKS/2026-10-02_nvim-listen-address-und-kontextmenue.md` |
| neotest-Listener: Messtabellen, Optionen, Wiederholung der Messung | `.../openinnvim/Backlog/TASKS/2026-10-02_neotest-listener-messung.md` |
| Review-Funde (Bug / Sicherheit / Performance), Docs-Standardisierung, PowerShell-5.1-Lehre | `.../openinnvim/Backlog/TASKS/2026-10-02_openinnvim-review.md` |
| Installer, relative VBS, Fokus, **zweiter** Review | `.../openinnvim/Backlog/TASKS/2026-10-02_installer-fokus-zweiter-review.md` |
| Live-Tests für dich | `docs/ROADMAP/Final_Checks/openinnvim-live-tests-2026-10-02.md` |
| Installierte Binaries/VBS der Exe-Variante | `C:\Users\bartl\AppData\Local\OpenInNvim` (kein Repo, nicht angefasst) |

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
- [ ] **`install.ps1` ausführen und den echten Klick im Explorer abnehmen** (Datei/Ordner ×
      current/new, mehrere Instanzen, keine Instanz, Sonderzeichen, Deinstallation) —
      Final-Checks-Liste, erst Vorbereitung und Teil G, dann A–F.
- [ ] **Fokus** (`FOCUS_TERMINAL = $true`) von Hand prüfen (Final_Checks A9b): nur der Win32-Teil
      braucht ein echtes Fenster. Danach entscheiden: opt-in lassen oder Standard.
- [ ] Unabhängiger Blick auf `openinnvim` `d0d1a5d` (Installer, Fokus, relative VBS). Die beiden
      früheren Fix-Commits (`9eb8c7e`, `99946e2`) hatten ihren zweiten Blick (ein Fund, behoben).
- [ ] openinnvim: Setup-`.exe`-Installer (Inno Setup, GitHub Actions) — baut auf `install.ps1` auf;
      Details in der ROADMAP im WKDBook.
- [ ] GitHub-Beschreibung und Topics von `openinnvim` setzen (`NEW-04`, `NEW-05`); `stylua.toml`,
      `.luacheckrc`, CI-Workflow.
- [ ] Aufräumen (optional): User-Variable `NVIM_VBS` zeigt auf ein nicht existierendes
      Verzeichnis und wird nirgends gelesen.
- [ ] Die Messskripte (`NT_ALLOW`/`NT_DUMP`-Hilfsskript und Scratch-Projekte mit 9 bzw. 1000
      Tests) bei Bedarf nach `WKDBooks/.../TOOLS/` legen; sie waren Wegwerf und liegen nicht
      mehr. Die Wiederholung der Messung steht in der Backlog-Datei zur neotest-Messung.

---

## Commits dieses Chats

✅ = durch den ultracode-Review (Reasoning-Stufe `ultracode`, vom Nutzer so gestellt)
abgenommen oder reine Doku.

| Repository | Commit | Beschreibung |
| --- | --- | --- |
| nvim-config | `afe3cee4` ✅ | docs(roadmap): Konkurrenzanalyse abgehakt, drei Reports verlinkt |
| Configs | `f02220f` ✅ | docs: Verweise auf das umbenannte Repo `openinnvim` |
| nvim-config | `0d3ba109` ✅ | docs(handover): NVIM_LISTEN_ADDRESS, neotest-Listener und openinnvim |
| openinnvim | `b5aa51d` ✅ | docs(readme): neuer Repo-Pfad, sichere Junction-Entfernung |
| nvim-config | `e5075b1d` ✅ | docs(handover): Reparatur, PID-Pipe-Suche, Filetree-Plan |
| openinnvim | `28d358c` ✅ | feat(current): Instanzen über Standard-Pipes finden, `:silent`, Fix `(c)`, Tests |
| openinnvim | `41c399f` ✅ | feat(current): Ordner in filetree.nvim (Review fand den `fnameescape`-Fehler, behoben in `9eb8c7e`) |
| openinnvim | `a8698cb` ✅ | fix(ps51): `?:` in verify.ps1 und `"$key:"` in install-context.ps1 |
| openinnvim | `9eb8c7e` ✅ | fix(launchers): Review-Fixes (RPC-Öffnen, verlorenes `$args`, Pfad-Escaping, Tempo); zweiter Blick fand den Pipe-Fehlfall, behoben in `d0d1a5d` |
| nvim-config | `3c01f438` ✅ | docs(handover): Tests grün, Filetree-Ordner |
| nvim-config | `76f5ca5b` ✅ | docs(handover): Review-Ergebnisse |
| openinnvim | `99946e2` ✅ | docs: Standard-README + `docs/`-Struktur, MIT-Lizenz; `nvr` ganz entfernt (zweiter Blick: ok) |
| openinnvim | `d0d1a5d` | feat(install): `install.ps1`/`uninstall.ps1`, relative VBS-Pfade, opt-in Fokus, zweiter Review (Pipe-Fehlfall 3,4 s → 0,4 s); 104 Prüfungen. **Kein Haken**: neuer Code, noch nicht unabhängig geprüft |
| WKDBooks | `1767d31`, `107d316` ✅ | docs(openinnvim): neues Buch mit Backlog und Roadmap; Index-Zeile |
| nvim-config | `82acfb17` ✅ | docs(handover): schlank, Erledigtes ins WKDBook; Live-Test-Checkliste |
| WKDBooks | `9cd608a` ✅ | docs(openinnvim): Installer, Fokus, zweiter Review ins Backlog; Roadmap gekürzt |
| nvim-config | `83f73c2c` ✅ | docs(handover) und Live-Test-Checkliste: Installation per `install.ps1`, Fokus-Test |
| nvim-config | `622d9ff1` ✅ | docs(handover): neotest-Listener, Teilergebnis des Workflows (Code gelesen, Laufzeittest offen) |
| WKDBooks | `3251163` ✅ | docs(tools): neotest-run-probe (Runner, Treiber, Rezept) mit den zwei Windows-Befunden |
| nvim-config | (dieser Commit) ✅ | docs(handover): neotest unter Windows — Läufe scheitern, Prototyp-Fix, Entscheidung |

Zusätzlich ohne Commit: GitHub-Repo `open-in-nvim` umbenannt in `openinnvim`, Klon nach
`E:\repos\openinnvim`; Junction `C:\tools\OpenInNvim` umgesetzt (kein Git).
