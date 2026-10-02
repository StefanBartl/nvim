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

- [ ] **Entscheidung zum neotest-Listener: A oder D.** Siehe Backlog-Datei oben. Für D erst den
      Test aus der Final-Checks-Liste (Teil K): Listener schließen, `<leader>nt*`-Lauf prüfen,
      Ergebnisse und Signs müssen kommen. Ein früher gestarteter Workflow sollte das und den
      positiven Fall des Attach-Fixes (Aufgabe 4) prüfen; **Ergebnisse standen nie hier** — wenn
      sie vorliegen, hier eintragen. Danach die Aufgabe 1 im Startup-Handover als entschieden
      markieren.
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
| nvim-config | (dieser Commit) ✅ | docs(handover) und Live-Test-Checkliste: Installation per `install.ps1`, Fokus-Test |

Zusätzlich ohne Commit: GitHub-Repo `open-in-nvim` umbenannt in `openinnvim`, Klon nach
`E:\repos\openinnvim`; Junction `C:\tools\OpenInNvim` umgesetzt (kein Git).
