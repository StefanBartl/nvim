# Echo, Grep, Find - Grundlagen

**Willkommen zu Cycle 1, Halbzyklus A!**

In den nächsten 3 Tagen (Tag 1-3) lernst du die wichtigsten Linux/macOS CLI-Befehle für:
- **Tag 1**: Output-Kontrolle mit `echo`
- **Tag 2**: Textsuche mit `grep`
- **Tag 3**: Dateien finden mit `find`

---

## Table of content

  - [🎯 Lernziele](#lernziele)
  - [📖 Befehlsübersicht](#befehlsbersicht)
    - [Echo - Output und Redirection](#echo-output-und-redirection)
      - [Wichtigste Operatoren:](#wichtigste-operatoren)
      - [Variablen](#variablen)
      - [Häufige Fehler](#hufige-fehler)
    - [Grep - Text durchsuchen](#grep-text-durchsuchen)
      - [Syntax](#syntax)
      - [Wichtigste Flags](#wichtigste-flags)
      - [Regex Basics](#regex-basics)
      - [Beispiele](#beispiele)
      - [Kontext-Flags](#kontext-flags)
    - [Find - Dateien finden](#find-dateien-finden)
      - [Syntax](#syntax-1)
      - [Wichtigste Tests](#wichtigste-tests)
      - [Kombinationen](#kombinationen)
      - [Actions](#actions)
      - [Beispiele](#beispiele-1)
  - [🎮 Übungsstruktur](#bungsstruktur)
    - [Tag 1: Echo](#tag-1-echo)
    - [Tag 2: Grep](#tag-2-grep)
    - [Tag 3: Find](#tag-3-find)
  - [💡 Lerntipps](#lerntipps)
    - [Vor den Exercises:](#vor-den-exercises)
    - [Während der Exercises:](#whrend-der-exercises)
    - [Nach den Exercises:](#nach-den-exercises)
  - [📖 Weiterführende Literatur](#weiterfhrende-literatur)
    - [Bücher](#bcher)
    - [Online-Ressourcen](#online-ressourcen)
    - [Man Pages](#man-pages)
  - [🔖 Cheat Sheet](#cheat-sheet)
    - [Quick Reference](#quick-reference)
  - [⚡ Quick Tips](#quick-tips)
    - [Echo](#echo)
    - [Grep](#grep)
    - [Find](#find)

---

## 🎯 Lernziele

Nach diesen 3 Tagen kannst du:
- ✅ Output umleiten und in Dateien speichern (`>`, `>>`, `|`)
- ✅ Text in Dateien suchen mit verschiedenen Flags
- ✅ Dateien nach Name, Typ und Größe finden
- ✅ Befehle auf Suchergebnisse anwenden

---

## 📖 Befehlsübersicht

### Echo - Output und Redirection

**Grundfunktion**: Text ausgeben und umleiten

#### Wichtigste Operatoren:

**`>` - Überschreiben**
```bash
echo "hello" > file.txt
# Erstellt file.txt (oder überschreibt sie)
```

**`>>` - Anhängen**
```bash
echo "world" >> file.txt
# Hängt "world" an existierende Datei an
```

**`|` - Pipe (an nächsten Befehl)**
```bash
echo "test" | wc -c
# Zählt Zeichen in "test"
```

**`tee` - Duplizieren**
```bash
cat input.txt | tee output.txt
# Zeigt auf Bildschirm UND schreibt in Datei
```

#### Variablen

```bash
NAME="Stefan"
echo "Hello $NAME"  # → Hello Stefan
echo 'Hello $NAME'  # → Hello $NAME (nicht expandiert!)
```

**Wichtig**: Doppelte Quotes (`"`) erlauben Expansion, einfache (`'`) nicht!

#### Häufige Fehler

❌ **Mehrfaches `>` funktioniert nicht**
```bash
echo "test" > file1 > file2  # Falsch!
```

✅ **Richtig mit `tee`**
```bash
echo "test" | tee file1 > file2
```

❌ **Variable ohne `$`**
```bash
echo "Hello NAME"  # → Hello NAME (literal)
```

✅ **Variable mit `$`**
```bash
echo "Hello $NAME"  # → Hello Stefan
```

---

### Grep - Text durchsuchen

**Grundfunktion**: Zeilen finden, die ein Muster enthalten

#### Syntax
```bash
grep [OPTIONS] PATTERN FILE
```

#### Wichtigste Flags

**`-v` - Invertieren (Zeilen OHNE Muster)**
```bash
grep -v "error" log.txt
# Zeigt alle Zeilen außer die mit "error"
```

**`-n` - Zeilennummern**
```bash
grep -n "error" log.txt
# 42:error: disk full
```

**`-i` - Case-insensitive**
```bash
grep -i "Error" log.txt
# Findet "error", "Error", "ERROR"
```

**`-E` - Extended Regex**
```bash
grep -E 'error|warning' log.txt
# ODER mit unescaped |
```

#### Regex Basics

**Basic Regex (default)**:
```bash
grep 'error\|warning' log.txt
# | muss escaped werden!
```

**Extended Regex (-E)**:
```bash
grep -E 'error|warning' log.txt
# | ist unescaped
```

**Weitere Regex-Zeichen**:
- `.` - beliebiges Zeichen
- `*` - 0 oder mehr vom vorherigen
- `^` - Zeilenanfang
- `$` - Zeilenende
- `[abc]` - eines von a, b, c
- `[0-9]` - Ziffer

#### Beispiele

```bash
# Zeilen die mit "error" beginnen
grep '^error' log.txt

# Zeilen die mit "." enden
grep '\.$' log.txt

# IP-Adressen finden (vereinfacht)
grep -E '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' log.txt
```

#### Kontext-Flags

```bash
-A N  # N Zeilen NACH dem Match
-B N  # N Zeilen VOR dem Match
-C N  # N Zeilen um Match herum

# Beispiel: Zeige error + 2 Zeilen danach
grep -A 2 "error" log.txt
```

---

### Find - Dateien finden

**Grundfunktion**: Dateisystem durchsuchen nach Kriterien

#### Syntax
```bash
find PATH [OPTIONS] [TESTS] [ACTIONS]
```

#### Wichtigste Tests

**`-name "pattern"` - Nach Name**
```bash
find . -name "*.txt"
# Findet alle .txt Dateien
```

**`-type` - Nach Typ**
```bash
-type f  # Dateien
-type d  # Verzeichnisse
-type l  # Symlinks

find /var -type d  # Alle Verzeichnisse in /var
```

**`-size` - Nach Größe**
```bash
-size +1M   # Größer als 1 MB
-size -100k # Kleiner als 100 KB
-size 50c   # Genau 50 bytes

find . -size +10M  # Dateien > 10 MB
```

**`-mtime` - Nach Änderungsdatum**
```bash
-mtime -7   # Geändert in letzten 7 Tagen
-mtime +30  # Geändert vor mehr als 30 Tagen

find /tmp -mtime +7  # Alte Dateien in /tmp
```

#### Kombinationen

Tests werden mit AND kombiniert:
```bash
find . -type f -name "*.log" -size +1M
# Dateien UND Name endet mit .log UND größer als 1MB
```

#### Actions

**`-exec` - Befehl ausführen**
```bash
find . -name "*.tmp" -exec rm {} \;
# Löscht alle .tmp Dateien

# {} wird durch Dateinamen ersetzt
# \; beendet den exec-Befehl
```

**`-exec` mit `+`** (effizienter):
```bash
find . -name "*.txt" -exec wc -l {} +
# Führt wc einmal mit allen Dateien aus
# Statt einmal pro Datei
```

#### Beispiele

```bash
# Alle Python-Dateien im Home-Verzeichnis
find ~ -name "*.py"

# Leere Dateien finden und löschen
find . -type f -empty -delete

# Dateien mit bestimmten Permissions
find . -type f -perm 644

# Große Log-Dateien älter als 30 Tage
find /var/log -name "*.log" -size +100M -mtime +30

# Dateien zählen
find . -type f | wc -l
```

---

## 🎮 Übungsstruktur

### Tag 1: Echo
- Exercise 1: Redirect und Append (`>`, `>>`)
- Exercise 2: Tee mit Pipe (`|`, `tee`)
- Exercise 3: Variablen nutzen (`$VAR`)

**Ziel**: Output kontrollieren können

### Tag 2: Grep
- Exercise 1: Einfache Suche
- Exercise 2: Invertierte Suche (`-v`)
- Exercise 3: Zeilennummern und Regex (`-n`, Regex)

**Ziel**: Text effizient suchen

### Tag 3: Find
- Exercise 1: Nach Name und Typ (`-name`, `-type`)
- Exercise 2: Nach Größe (`-size`)
- Exercise 3: Mit Exec (`-exec`)

**Ziel**: Dateien finden und verarbeiten

**Pro Tag**: 3 Exercises à ~5 Minuten = 15 Minuten täglich

---

## 💡 Lerntipps

### Vor den Exercises:
1. 📖 Lies diese Info-Einheit aufmerksam
2. 🔖 Markiere dir wichtige Flags
3. 💻 Probiere Beispiele aus (optional)

### Während der Exercises:
1. 🎯 Versuche es erst ohne Hints
2. 📝 Lies Fehlermeldungen genau
3. 💡 Bei Unsicherheit: Hints sind OK!
4. ⏱️ Zeit-Boni gibt es für schnelle Lösungen

### Nach den Exercises:
1. 📊 Prüfe deine Statistiken
2. 🔄 Wiederhole schwierige Exercises
3. 📚 Vertiefe mit weiterführender Literatur

---

## 📖 Weiterführende Literatur

### Bücher
- **"The Linux Command Line"** by William Shotts
  - Kapitel 6: Redirection
  - Kapitel 17: Searching for Files
  - Kapitel 19: Regular Expressions
  - [Online verfügbar](https://linuxcommand.org/tlcl.php)

- **"Learning the bash Shell"** by Cameron Newham
  - Kapitel 7: Input/Output and Command-Line Processing

### Online-Ressourcen

**Dokumentation**:
- [GNU Grep Manual](https://www.gnu.org/software/grep/manual/)
- [Find Command Manual](https://www.gnu.org/software/findutils/manual/)
- [Bash Reference Manual](https://www.gnu.org/software/bash/manual/)

**Tutorials**:
- [Bash Redirections Cheat Sheet](https://catonmat.net/bash-one-liners-explained-part-three)
- [35 Practical Examples of Find](https://www.tecmint.com/35-practical-examples-of-linux-find-command/)
- [Grep Command Examples](https://www.cyberciti.biz/faq/howto-use-grep-command-in-linux-unix/)

**Interaktive Tools**:
- [ExplainShell](https://explainshell.com/) - Befehle erklärt
- [Regex101](https://regex101.com/) - Regex testen
- [RegExr](https://regexr.com/) - Regex lernen

### Man Pages

Die besten Quellen sind oft die lokalen Man Pages:
```bash
man echo
man grep
man find
man bash  # Section über Redirection
```

**Tipp**: Nutze `/SUCHBEGRIFF` um in Man Pages zu suchen, `n` für nächstes Ergebnis.

---

## 🔖 Cheat Sheet

### Quick Reference

| Befehl | Funktion | Beispiel |
|--------|----------|----------|
| `echo "text" > file` | Überschreiben | `echo "neu" > out.txt` |
| `echo "text" >> file` | Anhängen | `echo "mehr" >> out.txt` |
| `cat file \| tee copy` | Duplizieren | `cat a.txt \| tee b.txt` |
| `grep pattern file` | Suchen | `grep "error" log.txt` |
| `grep -v pattern file` | Invertiert | `grep -v "info" log.txt` |
| `grep -n pattern file` | Mit Zeilen# | `grep -n "warn" log.txt` |
| `find . -name "*.txt"` | Nach Name | `find ~ -name "*.pdf"` |
| `find . -type f` | Nur Dateien | `find /var -type f` |
| `find . -size +1M` | Nach Größe | `find . -size +100M` |
| `find . -exec cmd {} \;` | Befehl ausführen | `find . -name "*.tmp" -exec rm {} \;` |

---

## ⚡ Quick Tips

### Echo
- `>` überschreibt, `>>` hängt an
- Variablen: `$VAR` in `"..."`, nicht in `'...'`
- `tee` für Output auf Screen + Datei

### Grep
- `-v` invertiert (Zeilen OHNE Muster)
- `-n` zeigt Zeilennummern
- `-i` ignoriert Case
- Basic: `\|` für ODER, Extended (`-E`): `|` für ODER

### Find
- `-name` mit Quotes: `"*.txt"`
- `-type f` für Dateien, `-type d` für Verzeichnisse
- `-size +1M` größer, `-size -1M` kleiner
- `-exec cmd {} \;` führt cmd pro Datei aus
- `-exec cmd {} +` führt cmd mit allen Dateien aus

---

**Bereit? Dann starte mit Tag 1! 🚀**

Viel Erfolg bei den Exercises! 💪
