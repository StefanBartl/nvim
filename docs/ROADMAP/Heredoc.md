Gute Frage — und ich will dir keine falsche Erklärung geben, also teste ich es kurz statt zu raten:

Apostroph, Delimiter-Wort und Backticks sind es alle nicht. Ich reproduziere den echten Fall mit dem echten Inhalt:

Bash meldete EOF, nicht die Fundstelle — ich reproduziere die Struktur exakt:

Ehrliche Korrektur vorweg: ich habe es zweimal „das Heredoc-Problem" genannt — **das war eine Fehldiagnose.** Ich habe den Fall gerade mit exakt demselben Inhalt und derselben Form nachgestellt, und er läuft durch:

```
Kommando-Datei: 235 Zeilen
== als Skript ausgefuehrt ==      written: 232 lines
== als bash -c (so ruft das Tool auf) ==   written: 232 lines
```

Apostroph im Body, Backticks, eine Zeile die mit dem Delimiter-Wort beginnt — alles einzeln getestet, alles unproblematisch. Der Fehler lag also **nicht** in Bash, sondern im Transport meines Kommandos zur Shell (Serialisierung in `bash -c '…'`). Bashs Meldung `unexpected EOF while looking for matching '` passt dazu: sie sagt „mir ist die Eingabe ausgegangen, während ein Quote offen war" — also *abgeschnitten*, nicht *falsch geschrieben*.

## Was du trotzdem über Heredocs wissen willst

Das ist die eine Unterscheidung, die in der Praxis wirklich beißt:

```bash
cat <<EOF     # unquoted → Shell interpretiert den Body
cat <<'EOF'   # quoted   → alles literal
```

Real gemessen, gleicher Body:

| Body | `<<EOF` | `<<'EOF'` |
|---|---|---|
| `$HOME` | `/c/Users/StefanBartl` | `$HOME` |
| `$(echo HALLO)` | `HALLO` | `$(echo HALLO)` |
| `\$5` | `$5` | `\$5` |

Faustregel: **Text, der so bleiben soll wie er ist → immer `<<'EOF'`.** Skripte, Konfigs, Code, Commit-Messages. Nur wenn du bewusst Variablen einsetzen willst, lässt du die Quotes weg — und `$(...)` im Body wird dann auch wirklich *ausgeführt*.

Zwei weitere echte Stolpersteine:

- **Der Delimiter muss allein und ganz links stehen.** Eingerücktes `EOF` beendet nichts. Wenn du einrücken willst: `<<-'EOF'` — aber das strippt nur **Tabs**, keine Spaces.
- **Wähle einen Delimiter, der im Body nicht vorkommt.** `EOF` ist Konvention, aber wenn dein Text selbst „EOF" am Zeilenanfang enthält, bricht es dort ab.

## Die eigentliche Lehre aus meinem Fall

Nicht „Heredocs sind fragil", sondern: **250 Zeilen Dokument gehören nicht durch die Shell.** Jede Zeile muss dabei durch mindestens zwei Quoting-Ebenen (Tool → `bash -c` → Heredoc), und jede davon kann etwas anfassen. Ich bin dann auf ein Datei-Schreibwerkzeug ausgewichen — kein Shell-Parsing, keine Ebenen.

Für dich übersetzt: für lange Literale eher `$EDITOR datei` oder ein kleines Python-/Node-Skript, das die Datei schreibt, als ein Riesen-Heredoc in einer `-c`-Kommandozeile. Heredocs sind super für 5–30 Zeilen in einem Skript, das auf Platte liegt — genau da haben sie in dieser Sitzung ja auch durchweg funktioniert.
