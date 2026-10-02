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
- **neotest-Listener: Messung fertig, Entscheidung offen.** Den Hilfsprozess starten zu lassen
  kostet etwa +75 bis +150 ms, bringt keinen Gewinn und schließt den Listener nicht. Empfehlung:
  A (lassen, dokumentiert) oder D (Listener nach dem Start schließen, nach einem Test).
  Nichts davon wurde geändert.
- **openinnvim ist fertig gebaut und im Review geprüft** (`E:\repos\openinnvim`): Instanzsuche
  über die Standard-Pipes mit UI-Prüfung, Öffnen per RPC (ohne zweiten `nvim.exe`),
  Ordner in `:Filetree open`, **kein `nvr` mehr** (keine externe Abhängigkeit), beide
  Launcher mit korrektem Quoting. README und `docs/` nach dem Plugin-Standard.
  **Der echte Klick im Explorer ist noch nicht von dir abgenommen.**
- **Wirkung auf die echte Sitzung:** `C:\tools\OpenInNvim` ist eine Junction auf das Repo, die
  Kontextmenü-Einträge benutzen also **schon jetzt** den neuen Launcher.

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
| Live-Tests für dich | `docs/ROADMAP/Final_Checks/openinnvim-live-tests-2026-10-02.md` |
| Installierte Binaries/VBS der Exe-Variante | `C:\Users\bartl\AppData\Local\OpenInNvim` (kein Repo, nicht angefasst) |

---

## Offen und Nachfrage

- [ ] **Entscheidung zum neotest-Listener: A oder D.** Siehe Backlog-Datei oben. Für D erst den
      Test aus der Final-Checks-Liste (Teil K): Listener schließen, `<leader>nt*`-Lauf prüfen,
      Ergebnisse und Signs müssen kommen. Ein früher gestarteter Workflow sollte das und den
      positiven Fall des Attach-Fixes (Aufgabe 4) prüfen; **Ergebnisse standen nie hier** — wenn
      sie vorliegen, hier eintragen. Danach die Aufgabe 1 im Startup-Handover als entschieden
      markieren.
- [ ] **Echter Klick im Explorer** (Datei/Ordner × current/new, mehrere Instanzen, keine
      Instanz, Sonderzeichen) — Final-Checks-Liste Teile A–G.
- [ ] Zweiter, unabhängiger Blick auf `openinnvim` `9eb8c7e` (RPC-Öffnen-Pfad, Lib-Pflicht,
      UI-Filter). Der Fix-Commit des Reviews ist selbst nicht unabhängig geprüft.
- [ ] openinnvim: VBS-Pfade relativ, `install.ps1`/`uninstall.ps1`, Setup-`.exe` — Details in der
      ROADMAP im WKDBook. Ändert den Installationsort; vorher Rückfrage. Die Lib
      `open-in-nvim.lib.ps1` ist Pflicht und muss mit installiert werden.
- [ ] openinnvim: Fokus des Terminalfensters nach dem Öffnen (ungelöst, ungetestet).
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
| openinnvim | `9eb8c7e` | fix(launchers): Review-Fixes (RPC-Öffnen, verlorenes `$args`, Pfad-Escaping, Tempo). **Kein Haken**: der Fix-Commit selbst, nicht unabhängig reviewed |
| nvim-config | `3c01f438` ✅ | docs(handover): Tests grün, Filetree-Ordner |
| nvim-config | `76f5ca5b` ✅ | docs(handover): Review-Ergebnisse |
| openinnvim | `99946e2` | docs: Standard-README + `docs/`-Struktur, MIT-Lizenz; `nvr` ganz entfernt (enthält die Code-Änderung am Launcher, daher **kein Haken**) |
| WKDBooks | `1767d31`, `107d316` ✅ | docs(openinnvim): neues Buch mit Backlog und Roadmap; Index-Zeile |
| nvim-config | (dieser Commit) ✅ | docs(handover): schlank, Erledigtes ins WKDBook; Live-Test-Checkliste |

Zusätzlich ohne Commit: GitHub-Repo `open-in-nvim` umbenannt in `openinnvim`, Klon nach
`E:\repos\openinnvim`; Junction `C:\tools\OpenInNvim` umgesetzt (kein Git).
