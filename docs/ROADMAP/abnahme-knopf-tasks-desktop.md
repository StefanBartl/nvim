Weiter mit der Task tasks-desktop/abnahme-inbox-als-ansicht-judge-punkte-abhaken-danach-done
(Vault: E:/repos/tasks-vault, Datei tasks-desktop/ROADMAP/tasks/abnahme-inbox-als-ansicht-judge-punkte-abhaken-danach-done.md;
Plan ALL/live-checks-automatisieren-klicker-fuer-neovim-browser-tauri, Etappe verknuepfung; actor: pair).

Ziel: In tasks-desktop eine Ansicht „Abnahme“: alle Live-Check-Tasks mit grünem Testblatt und offenen
judge- oder manual-Punkten; je Task die Snapshots als Text-Raster; Punkte abhaken schreibt über die
Engine in die Task; sind alle abgehakt, bietet die App `done` an (nie automatisch). Der Entwurf wird
mit mir abgestimmt (actor pair): erst den Entwurf vorlegen, dann bauen.

Was es schon gibt (in diesem Chat gebaut, alles auf main):
- testing.nvim `testing sheets report --tasks <vault>` schreibt pro Live-Check-Task einen Block
  `<!-- testing:sheets:begin --> ... <!-- testing:sheets:end -->` in die Task: je Blatt Zustand,
  judge- und manual-Punkte als Checkboxen (ein abgehaktes Kästchen bleibt beim nächsten Lauf erhalten),
  Snapshot-Pfade; letzte Zeile im Block `<!-- testing:sheets:states <id>=<state> ... -->` mit
  red|stale|never|inbox|manual|green (inbox = grün, wartet auf das Urteil). Doku: testing.nvim docs/SHEETS.md.
- tasks.nvim liest die Zustandszeile (`tasks_nvim.sheets`). Der Vertrag `tasks-export/1` hat im
  Task-Eintrag `sheets {state,total,counts,reason?}`. `list --sheet=inbox,manual` filtert, im CLI und
  jetzt auch in `:Tasks list`. `show` und die Dashboard-Zeile zeigen den Zustand.
  Schreiben nur über `call ops` (set_body mit if_match = etag), lesen über `call bodies`.
  Doku: tasks.nvim docs/CONTRACT.md, docs/COMMANDS.md.
- `testing sheets run --task <id>` (`:Tasks sheet-run`) führt die Blätter einer Task sofort aus;
  `:Tasks sheet-ai` ist die KI-Übergabe (Stufe 0).
- Konformitäts-Check K16 in testing.nvim: jedes Blatt zeigt auf eine existierende Task.
- tasks-desktop pinnt die Engine über engine.lock; die Typen kommen aus tasks.nvim contract/tasks-export.d.ts.

Offene Fragen für den Entwurf (bitte als Optionen mit Empfehlung vorlegen):
1. Woher kommen die Inbox-Tasks: `list` mit sheet-Filter über den Vertrag (Feld sheets.state)
   und die Punkte aus dem Body-Block geparst, oder ein eigenes Vertragsfeld für die Punkte?
2. Snapshot-Raster: Die .snap-Dateien liegen im Plugin-Repo (z. B. ui.nvim/TESTS/__snapshots__/sheets/...),
   nicht im Vault. Wie kommt die App daran (Pfad relativ zu REPOS_DIR, oder ein Vertrag von testing.nvim)?
3. Abhaken: das Kästchen im Body-Block per set_body umschreiben (Gefahr: der nächste Report-Lauf),
   oder eine eigene Operation in tasks-ops/1.
4. Folge-Task `tasks-desktop/knopf-testblatt-ausfuehren-in-der-task-ansicht-ueber-den-hub` (blockiert
   durch den Hub): nur abgrenzen, nicht mitbauen.

Regeln wie immer: Deutsch antworten, Code englisch; 1 Agent gleichzeitig; nur eigene Pfade stagen
(parallele Sessions in den Repos); jeder Fix mit Spec, die ohne den Fix rot wird (Sabotage);
luacheck/stylua 0 Warnungen; vor jedem Push git log origin/main..HEAD; CI abwarten;
Tasks-CLI: nvim --headless -u NONE -l E:/repos/tasks.nvim/scripts/tasks.lua <cmd> --vault=E:/repos/tasks-vault;
Abschluss mit done --commits=...; tasks-desktop-Builds nur auf dem privaten Rechner (NVIM_MACHINE_ROLE prüfen).
