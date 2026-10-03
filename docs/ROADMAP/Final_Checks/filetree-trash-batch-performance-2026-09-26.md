# filetree.nvim: Trash-Batch-Hänger (Windows) + Performance — Fix & Review-Auftrag Linux/macOS

Stand: 2026-09-26 · Status: **Windows gefixt & real getestet · macOS/Linux umgesetzt, aber
ungetestet** (nur Windows-Maschine in der Session verfügbar) · Repo: `filetree.nvim`

## 1. Ausgangsproblem

26 PNGs im Dateibaum markiert, mit `d` → "delete all at once" gelöscht. Zwei Symptome:

1. **Dauerte lange** (~30s für 26 Dateien).
2. **Nicht alle wurden gelöscht** — die Batch-Verarbeitung stoppte bei Item 20/26
   (`fence_left_right.png`), 60s später kam die (unabhängige) "Marks auto-cleared
   after 60s idle"-Meldung, und beim erneuten manuellen Löschen der restlichen 6
   Dateien tauchte ein **Windows-Bestätigungsdialog** ("wirklich löschen?") auf, mit
   dem vorher nichts gemacht wurde. Log-Auszug siehe Anhang.

## 2. Root Cause

`lua/filetree/features/fileops/trash/platform.lua`s Windows-Pfad nutzte
`Shell.Application.Namespace(0).ParseName(path).InvokeVerb('delete')` — das ist exakt
der Explorer-"Löschen"-Befehl, **inklusive** der Recycle-Bin-Bestätigungsrückfrage. Das
PowerShell-Skript läuft aber mit `-NonInteractive`, ganz ohne Fenster — niemand konnte
diesen (unsichtbaren) Dialog je beantworten.

`run_all` in `trash/init.lua` verarbeitet einen Batch als strikte Callback-Kette (Datei
N startet erst, wenn Datei N-1 fertig gemeldet hat — bewusst so wegen der
Watcher-Release-Logik pro Pfad). Sobald eine Datei diesen Dialog auslöste, hing der
Callback für sie in der Luft, und die Kette kam nie bei den folgenden Dateien an — daher
der Stopp bei (20/26). Die Marks-Auto-Clear-Meldung war ein reiner Zufall (unabhängiger
60s-Idle-Timer, ohne Effekt auf die schon laufende Batch-Liste).

Zusätzlich: `lib.nvim.fs.trash` (die geteilte Lib) hat für genau dieses Problem bereits
die richtige Lösung (`Microsoft.VisualBasic.FileIO.FileSystem` mit
`OnlyErrorDialogs`/`SendToRecycleBin`) — filetree.nvim hat aber nie dorthin delegiert,
sondern von Anfang an eine eigene, unabhängige Kopie in `trash/platform.lua` gepflegt,
die diesen Fix nie erhalten hat. Die Doku (`docs/FEATURES/FILEOPS.md`) behauptete
fälschlich "alles via `lib.nvim.fs.trash`" — korrigiert.

**Separat:** Jede Datei spawnt einen eigenen `powershell.exe`-Prozess samt
COM/.NET-Init (~0,3–1,5s, u.a. wegen Windows-Defender-Scan pro neuem Prozess) — das
erklärt die ~30s für 26 Dateien unabhängig vom Hänger-Bug.

## 3. Was gefixt wurde

| Commit | Was |
|---|---|
| `78d4e9f` | Windows: `InvokeVerb('delete')` → `Microsoft.VisualBasic.FileIO.FileSystem` mit `OnlyErrorDialogs` — kein Bestätigungsdialog mehr, damit kein Hänger mehr |
| `9812e9f` | Windows: Multi-Mark-Batch läuft über **einen** PowerShell-Prozess (generiertes Skript, JSON-Ergebnis pro Pfad) statt einen pro Datei — Perf-Fix. Zusätzlich die falsche `lib.nvim.fs.trash`-Doku-Referenz entfernt |
| `ecd4dfd` | macOS/Linux: gleiche Idee, aber einfacher — `trash`/AppleScripts `Finder delete`/`gio trash`/`trash-put`/`mv` akzeptieren bereits mehrere Pfade in einem Aufruf, kein generiertes Skript nötig |

Verifikation Windows: **real** gegen den echten Papierkorb getestet (2 Dateien + 1
Ordner in einem PowerShell-Aufruf, ~860ms, kein Dialog). Alle 396 bestehenden
Unit-Tests grün, stylua/luacheck sauber.

Verifikation macOS/Linux: **nur strukturell** — Plattformerkennung und
`vim.fn.executable` gemockt, geprüft dass für jeden Zweig (gio vorhanden, nur
trash-put, weder-noch → XDG-`mv`-Fallback, `trash`-CLI vorhanden, AppleScript-Fallback,
Teilausfall-Zuordnung bei gemeinsamem Exit-Code) die richtigen argv/AppleScript-Aufrufe
gebaut werden. **Nicht** gegen echte `gio`/`trash-put`/`trash`/`osascript`-Binaries
gelaufen — dafür stand in der Session nur eine Windows-Maschine zur Verfügung.

## 4. Offen: Review-Auftrag für echtes Linux/macOS

Betroffene Stelle: `lua/filetree/features/fileops/trash/platform.lua`,
Funktionen `run_mac_batch`, `run_linux_batch`, `M.send_batch`.

### Ubuntu (nativ)

- Mehrere Dateien markieren (`m`), `d` → "Delete all at once" — landen alle im Trash?
- Mit `gio` installiert: läuft `gio trash p1 p2 p3 ...` in einem Aufruf (nicht N mal)?
- Ohne `gio`, mit `trash-put`: gleiche Prüfung für `trash-put`.
- Ohne beides (XDG-Fallback): landen die Dateien unter
  `$XDG_DATA_HOME/Trash/files` (bzw. `~/.local/share/Trash/files`)? **Bekannte
  Einschränkung, nicht neu durch dieses Batching:** zwei gleichnamige Dateien aus
  verschiedenen Ordnern kollidieren dort (die zweite überschreibt die erste beim
  `mv`) — das galt vorher genauso pro Einzelaufruf, nur jetzt eben im selben
  Batch-Aufruf.
- Randfall: eine der markierten Dateien ist währenddessen gesperrt/ohne Berechtigung —
  wird das sauber als Fehler für genau diese eine Datei gemeldet, ohne den Rest des
  Batches zu verhindern?

### Arch Linux via WSL

- **Wichtig:** WSL nutzt weiterhin den sequenziellen Windows-Pfad (`wslpath` +
  PowerShell pro Datei) — der neue `run_linux_batch` wird unter WSL **nicht**
  angesprungen (bewusst außerhalb des Scopes, siehe Abschnitt 5). Trotzdem prüfenswert:
  funktioniert Löschen unter WSL nach dem `InvokeVerb`-Fix weiterhin normal (kein
  Regressions-Check nötig für Batching, aber für den Bestätigungsdialog-Fix, der auch
  den WSL-Pfad betrifft, da `trash_windows` darunter aufgerufen wird)?

### macOS (VM)

- Mit `trash`-CLI (`brew install trash`) installiert: ein `trash p1 p2 p3 ...`-Aufruf
  für den ganzen Batch?
- Ohne `trash`-CLI (AppleScript-Fallback über Finder): landen alle Dateien im
  Papierkorb? Insbesondere mit Pfaden, die Leerzeichen, `"` oder `\` enthalten
  (AppleScript-String-Escaping).
- Randfall wie bei Linux: eine gesperrte/nicht vorhandene Datei mittendrin.

## 5. Mögliches Follow-up (nicht Teil dieser Runde)

WSL selbst batcht nicht (nutzt weiterhin den Windows-Pfad sequenziell pro Datei, inkl.
`wslpath`-Konvertierung). Falls WSL-Nutzer regelmäßig große Batches löschen, wäre ein
`run_windows_batch`-Äquivalent für vorher gesammelt konvertierte WSL-Pfade ein
sinnvoller Nachtrag — aktuell nicht umgesetzt, da aus dem ursprünglichen Bug-Report
(native Windows-Pfade) nicht ableitbar.

## Anhang: Original-Log (Auszug)

```
Info  09:34:32 notify.info [filetree.trash] FT_Cheatsheet_25092026.md (0/26)
Info  09:34:33 notify.info [filetree.trash] ROADMAP-1787215848.png (1/26)
...
Info  09:35:00 notify.info [filetree.trash] fence_left_right.png (20/26)
Info  09:35:22 notify.info [filetree.marks] Marks auto-cleared after 60s idle
```

Danach manuell die restlichen 6 gelöscht, inkl. Bestätigungsdialog bei einer Datei;
ein späterer, offenbar wieder aufgewachter Lauf der ursprünglichen Kette meldete für
die bereits manuell gelöschten Dateien `path does not exist` — konsistent mit der
Root-Cause-Erklärung in Abschnitt 2.
