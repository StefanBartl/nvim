# learn-cli.nvim

## Zweck
Interaktive Lernplattform für CLI-Tools direkt in Neovim: geführte Übungen, Fortschritts-
Tracking und Spaced-Repetition-artige Wiederholung, um CLI-Kommandos einzuüben
(`E:\repos\learn-cli.nvim\README.md:1-3`). Hängt von `lib.nvim` für Notifications und
State-File-I/O ab. **In der aktiven nvim-Config des Nutzers deaktiviert.**

Status-Einschätzung: Das Plugin wirkt unfertig/verwaist. Das README bewirbt eingebaute Übungen
für `grep` UND `sed` (README.md:325-327), tatsächlich existiert unter
`E:\repos\learn-cli.nvim\lua\learn_cli\data\exercises\` nur `grep.lua` — die `sed`-Übung fehlt
komplett im Code. Der letzte Commit datiert auf 2026-07-29 (`660b5c5 First version…` bis
`5df42c5 chore: untrack doc/tags`), während die anderen vier Repos zwei Wochen später (2026-08-07/
08) noch aktiv weiterentwickelt wurden. Die Commit-Historie besteht fast nur aus Refactoring
("delegate X to lib.nvim") ohne neue Features seit der Erstversion — passt zum vom Nutzer selbst
vermerkten Status "disabled".

## Nicht-standard Patterns / Algorithmen

- `E:\repos\learn-cli.nvim\lua\learn_cli\core\scoring.lua:19-84` — `calculate_score` kombiniert
  additive Bonus-/Malus-Terme (Hint-Penalty linear pro Hint, Zeitbonus/-malus über
  Schwellenwert-Verhältnis `duration/target`, Completion-Bonus) und clamped das Ergebnis am Ende
  hart auf `[0, 100]` (Zeile 80) — ein einfaches, aber explizit dokumentiertes heuristisches
  Scoring-Modell, keine "cleveren" Algorithmen, aber sauber in nachvollziehbare `details`-
  Teilsummen zerlegt (Zeile 21-26) statt nur eine Zahl zurückzugeben.
- `E:\repos\learn-cli.nvim\lua\learn_cli\core\scoring.lua:89-129` — `calculate_mastery` begrenzt
  sich bewusst auf die letzten 5 Versuche (Zeile 95: "recent_count = math.min(5, #attempts)")
  statt die gesamte Historie zu mitteln — verhindert, dass alte (evtl. nicht mehr repräsentative)
  Versuche die aktuelle Einschätzung verwässern; plus Konsistenz-Bonus nur bei "alle letzten
  Versuche abgeschlossen UND mindestens 3 Versuche" (Zeile 120), um bei sehr wenigen Datenpunkten
  keinen Bonus zu vergeben.
- `E:\repos\learn-cli.nvim\lua\learn_cli\core\scoring.lua:164-196` — `calculate_adaptive_target`
  begrenzt die angepasste Zielzeit explizit auf `[50%, 200%]` der ursprünglichen Zielzeit
  (Zeile 193) — verhindert, dass ein paar sehr schnelle oder sehr langsame Ausreißer-Versuche die
  Zielzeit ins Absurde verschieben.
- Keine sonstigen besonderen Performance-/Security-/Caching-Patterns gefunden — der Code ist
  funktional geradlinig (State-Maschine + UI-Views), ohne die Art von defensiven Edge-Case-
  Behandlungen oder plattformspezifischen Workarounds, die in lib.nvim/language.nvim auffallen.

## Abgeleitete Guidelines

1. Score-/Bewertungsfunktionen immer eine nachvollziehbare `details`-Aufschlüsselung zurückgeben
   lassen (Basis, Boni, Mali einzeln), nicht nur die Endzahl — erleichtert Debugging und spätere
   Anpassung der Gewichtung.
2. Bei "Mastery"/Trend-Berechnungen aus Historie bewusst ein Fenster (letzte N Einträge) statt der
   Gesamthistorie verwenden, und Bonus-Bedingungen an eine Mindestanzahl Datenpunkte knüpfen, um
   Rauschen bei wenigen Beobachtungen zu vermeiden.
3. Adaptive numerische Ziele (Zeit, Schwierigkeit) immer mit einer harten Ober-/Untergrenze
   relativ zum Ausgangswert clampen, damit Ausreißer keine unsinnigen Zielwerte erzeugen.
4. README-Feature-Listen und tatsächlichen Datenbestand (hier: eingebaute Übungen) im Sync
   halten oder das README als "geplant" kennzeichnen — sonst entsteht der Eindruck von mehr
   Funktionsumfang, als das Plugin bietet.

## Keybindings-Audit
Aus `E:\repos\learn-cli.nvim\lua\learn_cli\user_actions\keymaps.lua:1-39`, config-driven über
`keymaps`-Tabelle (Default-Prefix `<leader>lc`, siehe README.md:138-146):

- `keymaps.toggle_dashboard` → `learn_cli.ui.dashboard.toggle()`.
  - Count: nein — kein sinnvoller Use-Case für ein Dashboard-Toggle.
  - Autocompletion: n.a. (Keymap).
  - Fehlend: keine.
- `keymaps.next_exercise` → `:LearnCLINext`.
  - Count: nein, aber sinnvoll wäre es: `3<leader>lcn` könnte plausibel "3 Übungen vorspringen"
    bedeuten. Aktuell ruft die Keymap immer nur ein einzelnes `:LearnCLINext` ohne Count-Weitergabe
    (`keymaps.lua:24-28`), `vim.v.count` wird nirgends gelesen.
  - Autocompletion: n.a.
  - Fehlend: Count-Unterstützung für Mehrfach-Sprung.
- `keymaps.prev_exercise` → `:LearnCLIPrev` — identische Einschätzung wie `next_exercise`.

`commands.lua:112-161` — `:LearnCLICreateCycle <name> [path]` hat zwar `complete`, aber die
Completion-Funktion ignoriert `arg_lead`/Kontext komplett und liefert immer dieselben drei
statischen Strings `{ "cycle_01", "cycle_02", "cycle_03" }` (Zeile 158-160) — das ist keine echte
Vervollständigung des Cycle-Namens (z.B. aus existierenden Cycles), sondern Platzhalter-artig und
für den zweiten Positional-Parameter (`path`, ein Verzeichnis) fehlt jede Completion (z.B.
`vim.fn.getcompletion(arg_lead, "dir")`, wie es andere Plugins in diesem Audit nutzen).

Andere Kommandos (`:LearnCLIDashboard`, `:LearnCLIStats`, `:LearnCLIReset`, `:LearnCliExport`/
`Import`/`Backup` laut README) haben laut Code keine Autocompletion, was bei reinen No-Arg-
Kommandos unproblematisch ist, bei `Export`/`Import <file>` (laut README, im gelesenen Code aber
nicht gefunden — vermutlich ebenfalls unvollständig implementiert) aber fehlt.

## Ideen für andere Plugins
- Das additive Scoring-mit-details-Muster (`scoring.lua`) ist generisch genug für ein
  `lib.nvim.lua.scoring`-Hilfsmodul: Basis + benannte Boni/Mali-Liste + Clamp, wiederverwendbar
  für jedes Plugin mit Gamification-Elementen.
- Eine "Spaced-Repetition-Queue" als eigenständiges lib.nvim-Modul (Intervall-Berechnung basierend
  auf Erfolgsquote, unabhängig von CLI-Übungen) — ließe sich z.B. für Vokabel-Wiederholung in
  language.nvim (Übersetzungs-Historie) wiederverwenden, statt es CLI-spezifisch in learn-cli.nvim
  gefangen zu halten.
