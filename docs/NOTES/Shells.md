# Shell-Cheatsheet: Kniffe, die (fast) überall gleich sind

Gemeint sind bash, zsh, fish, PowerShell (pwsh 7+) und cmd. Wo eine Shell abweicht, steht das dabei.

## Gleich in allen fünf

| Syntax | Bedeutung | Beispiel |
|---|---|---|
| `a \| b` | Pipe: stdout von `a` wird stdin von `b` | `npx vitest run \| more` |
| `> datei` | stdout in Datei schreiben (überschreibt) | `ls > liste.txt` |
| `>> datei` | stdout an Datei anhängen | `echo x >> log.txt` |
| `2> datei` | stderr in Datei umleiten | `cmd 2> err.txt` |
| `2>&1` | stderr in den stdout-Kanal umleiten | `cmd 2>&1 \| more` |
| `> datei 2>&1` | stdout und stderr in dieselbe Datei | `cmd > all.txt 2>&1` |
| `&&` | nächster Befehl nur bei Erfolg (Exit-Code 0) | `build && test` |
| `\|\|` | nächster Befehl nur bei Fehler | `test \|\| echo kaputt` |
| `"text"` | Doppelte Quotes gruppieren Wörter mit Leerzeichen | `cd "My Folder"` |
| `*` und `?` | Wildcards für Dateinamen (cmd gibt sie an das Programm weiter) | `ls *.js` |
| `cd ..` | Eine Ebene hoch | |
| `--` | Ende der Optionen (Konvention der Programme, nicht der Shell) | `rm -- -datei` |

## Fast gleich (mit Ausnahme)

| Syntax | Gilt in | Ausnahme |
|---|---|---|
| `;` Befehle nacheinander | bash, zsh, fish, PowerShell | cmd nutzt `&` |
| `< datei` stdin aus Datei | bash, zsh, fish, cmd | PowerShell kennt es nicht, nimm `Get-Content datei \| cmd` |
| `'text'` Single Quotes (literal) | bash, zsh, fish, PowerShell | cmd kennt nur `"` |
| `$(cmd)` Command Substitution | bash, zsh, PowerShell, fish ≥ 3.4 | cmd hat nichts Vergleichbares |
| `&&` und `\|\|` | alle | PowerShell 5.1 kennt sie nicht, erst ab 7 |
| `cd -` (zurück ins vorherige Verzeichnis) | bash, zsh, fish, PowerShell 7 | cmd nicht |
| `#` Kommentar | bash, zsh, fish, PowerShell | cmd nutzt `REM` oder `::` |

## Typische Fallen (hier unterscheiden sich die Shells)

| Thema | bash/zsh | fish | PowerShell | cmd |
|---|---|---|---|---|
| Variable lesen | `$VAR` | `$VAR` | `$env:VAR` | `%VAR%` |
| Exit-Code des letzten Befehls | `$?` | `$status` | `$LASTEXITCODE` (`$?` ist nur true/false) | `%ERRORLEVEL%` |
| Ausgabe verwerfen | `> /dev/null` | `> /dev/null` | `> $null` | `> NUL` |
| `&` am Zeilenende | Hintergrundprozess | Hintergrundprozess | ungültig (nutze `Start-Job`) | trennt Befehle (sequenziell) |
| `( ... )` | Subshell | Syntaxfehler (nutze `begin; ...; end`) | Gruppierung, liefert das Ergebnis als Wert | Befehlsblock |
| Zeilenfortsetzung | `\` | `\` | `` ` `` (Backtick) | `^` |
| Pipe-Inhalt | Text | Text | **Objekte** | Text |
| stderr in der Pipe | getrennt (ohne `2>&1`) | getrennt | `2>&1` macht aus stderr oft `ErrorRecord`-Objekte | getrennt |

## Merkregeln

1. `cmd > f 2>&1` ist richtig, `cmd 2>&1 > f` ist falsch. Die Reihenfolge zählt: erst stdout umbiegen, dann stderr auf das Ziel von stdout.
2. Exit-Code 0 bedeutet Erfolg, alles andere Fehler. Darauf bauen `&&` und `||` auf.
3. Bei Pfaden mit Leerzeichen immer `"..."`, das funktioniert überall.
4. Wer portabel sein will, bleibt bei `|`, `>`, `>>`, `2>&1`, `&&`, `||` und Doppelquotes.

---
