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

---

# Neue Live-Checks (Stand 2026-10-29)

Ergänzung zu Abschnitt 4 oben, ohne ihn zu ändern. Task `filetree.nvim/test-trash-batch-linux-macos`
(Prio 2, Aufwand S, Tags `needs-live-test`, `linux`, `macos`). Die Checkliste im Vault
(`Backlog/TASKS/2026-09-26-test-trash-batch-linux-macos.md`) steht noch auf „Offen“ und wird nach dem
Lauf mit abgehakt. Haken hier und in Abschnitt 4 setzen; Befunde als Zeile unter „Falls rot“, daraus
wird eine `kind: bug`-Task. Code: `lua/filetree/features/fileops/trash/platform.lua`
(`run_mac_batch`, `run_linux_batch`, `M.send_batch`), Commit `filetree.nvim@ecd4dfd`.

**Vorher:** `filetree.nvim` auf allen Zielmaschinen aktuell (Commit notieren: ______); Neovim mit
neo-tree-Backend. Wegwerf-Dateien anlegen (nichts Echtes markieren): eine Handvoll Dateien, dazu eine
mit Leerzeichen, `"` und `\` im Namen (nur macOS-Test). Bedienung: Dateien mit `m` markieren, `d`,
im Dialog **Delete all at once**; `U` stellt wieder her. Prüfen, wo etwas landet: Linux
`~/.local/share/Trash/files` bzw. `gio list trash://`, macOS der Papierkorb im Finder.
Hinweis zur Beobachtung des „ein Aufruf für den ganzen Batch“: Aufrufe z. B. über eine temporäre
Wrapper-Skript-Kette auf `PATH` oder `strace -f -e execve` mitschneiden (Vorschlag, die Task nennt
kein Verfahren).

## Ubuntu (nativ) — offen

- [ ] Mehrere Dateien markieren, `d`, Delete all at once, **mit `gio`**: alle landen im Trash, laut
      Mitschnitt ein `gio trash p1 p2 ...`-Aufruf (nicht N)
- [ ] dasselbe **nur mit `trash-put`** (`gio` aus dem `PATH`): ein `trash-put`-Aufruf, alle im Trash
- [ ] dasselbe **mit keinem von beiden**: XDG-`mv`-Fallback nach `~/.local/share/Trash/files`
      (bzw. `$XDG_DATA_HOME/Trash/files`)
- [ ] Randfall: eine markierte Datei mitten im Batch sperren (Rechte entziehen): nur genau diese wird
      als Fehler gemeldet, der Rest wird nicht blockiert

Bekannt und akzeptiert, **nicht** als Bug melden: im XDG-`mv`-Fallback überschreibt bei gleichnamigen
Dateien aus verschiedenen Ordnern die zweite die erste (galt schon vor dem Batching).

## Arch Linux unter WSL — offen

- [ ] normales Löschen funktioniert weiter (dieser Pfad bleibt sequenziell über den Windows-Weg mit
      `wslpath` und PowerShell, `run_linux_batch` wird hier bewusst **nicht** angesprungen); Regressions-
      Check für den Fix des Bestätigungsdialogs, kein Dialog, der hängt

## macOS (VM) — offen

- [ ] mit der `trash`-CLI (`brew install trash`): ein `trash p1 p2 ...`-Aufruf für den ganzen Batch,
      alle Dateien im Papierkorb
- [ ] ohne die CLI (AppleScript-Fallback über Finder): alle im Papierkorb, mit Dateinamen, die
      Leerzeichen, `"` und `\` enthalten
- [ ] Randfall wie bei Linux: gesperrte bzw. nicht vorhandene Datei mitten im Batch

## Falls rot

- [ ] Plattform, Variante (`gio` / `trash-put` / `mv` / `trash` / AppleScript), Dateiname, Meldung
      von Neovim (`:messages`) festhalten; `kind: bug` in `filetree.nvim` mit `refs:` auf die Zeile

## Danach

- [ ] Ergebnis und eventuellen Fix-Commit in der Task festhalten, Task
      `test-trash-batch-linux-macos` mit `done` schließen, die Vault-Checkliste abhaken

Offene Fragen: Die Task sagt „Ubuntu (native)“ und „macOS (VM)“ ohne zu klären, welche Maschinen du
dafür hast (laut Task: „needs machines the author may not have at hand“). Fehlt eine Plattform, bewusst
als „nicht testbar“ notieren und die Task offen lassen oder aufteilen?

Verwandt, gleiche Area, andere Sitzung: `filetree-live-checks-2026-10-29.md` (Blink, Badges,
Handle-Guard).
