# Grep Command Reference

## Table of content

  - [Übersicht](#bersicht)
  - [Wichtigste Optionen](#wichtigste-optionen)
    - [Grundlegende Flags](#grundlegende-flags)
    - [Kontext-Flags](#kontext-flags)
    - [Regex-Optionen](#regex-optionen)
  - [Regex Patterns](#regex-patterns)
    - [Basic Regex (default)](#basic-regex-default)
    - [Extended Regex (-E)](#extended-regex-e)
  - [Beispiele](#beispiele)
    - [Einfache Suchen](#einfache-suchen)
    - [Kontext anzeigen](#kontext-anzeigen)
    - [Regex-Patterns](#regex-patterns-1)
    - [Kombinationen](#kombinationen)
  - [Tipps](#tipps)
    - [Performance](#performance)
    - [Spezielle Zeichen escapen](#spezielle-zeichen-escapen)
  - [Exit Status](#exit-status)
  - [Siehe auch](#siehe-auch)

---

## Übersicht

`grep` durchsucht Dateien nach Textmustern.

```bash
grep [OPTIONS] PATTERN [FILE...]
```

## Wichtigste Optionen

### Grundlegende Flags

```bash
-i    # Case-insensitive
-v    # Invertieren (Zeilen OHNE Muster)
-n    # Zeilennummern anzeigen
-c    # Nur Anzahl der Treffer
-l    # Nur Dateinamen mit Treffern
-L    # Nur Dateinamen OHNE Treffer
-h    # Keine Dateinamen (bei mehreren Dateien)
-H    # Dateinamen anzeigen (default bei mehreren)
-r/-R # Rekursiv durch Verzeichnisse
-q    # Quiet (exit status only)
-s    # Fehler unterdrücken
-w    # Nur ganze Wörter
-x    # Nur ganze Zeilen
```

### Kontext-Flags

```bash
-A N  # N Zeilen NACH Match
-B N  # N Zeilen VOR Match
-C N  # N Zeilen um Match (vor + nach)
```

### Regex-Optionen

```bash
-E    # Extended Regex (egrep)
-F    # Fixed strings (kein Regex, fgrep)
-P    # Perl-compatible Regex
-G    # Basic Regex (default)
```

## Regex Patterns

### Basic Regex (default)

```bash
^       # Zeilenanfang
$       # Zeilenende
.       # Beliebiges Zeichen
*       # 0 oder mehr vom vorherigen
\+      # 1 oder mehr (escaped!)
\?      # 0 oder 1 (escaped!)
\|      # ODER (escaped!)
[abc]   # Eines von a, b, c
[^abc]  # Keines von a, b, c
[0-9]   # Ziffer
[a-z]   # Kleinbuchstabe
```

### Extended Regex (-E)

```bash
+       # 1 oder mehr (unescaped!)
?       # 0 oder 1 (unescaped!)
|       # ODER (unescaped!)
{n}     # Exakt n mal
{n,}    # Mindestens n mal
{n,m}   # n bis m mal
(abc)   # Gruppierung
```

## Beispiele

### Einfache Suchen

```bash
# Text in Datei finden
grep "error" app.log

# Case-insensitive
grep -i "ERROR" app.log

# Mit Zeilennummern
grep -n "error" app.log

# Invertiert
grep -v "debug" app.log

# Nur Anzahl
grep -c "error" app.log

# Rekursiv in allen Dateien
grep -r "TODO" .
```

### Kontext anzeigen

```bash
# 2 Zeilen nach Match
grep -A 2 "error" app.log

# 2 Zeilen vor Match
grep -B 2 "error" app.log

# 2 Zeilen um Match
grep -C 2 "error" app.log
```

### Regex-Patterns

```bash
# Zeilen die mit "error" beginnen
grep '^error' app.log

# Zeilen die mit "." enden
grep '\.$' app.log

# ODER (Basic Regex)
grep 'error\|warning' app.log

# ODER (Extended Regex)
grep -E 'error|warning' app.log

# IP-Adressen (vereinfacht)
grep -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' app.log

# Email-Adressen (vereinfacht)
grep -E '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' contacts.txt
```

### Kombinationen

```bash
# Mehrere Dateien
grep "error" *.log

# Mit Piping
cat app.log | grep "error" | grep -v "debug"

# Mit find
find . -name "*.log" -exec grep -l "error" {} \;

# Mit xargs
find . -name "*.log" | xargs grep "error"
```

## Tipps

### Performance

```bash
# -F (fixed strings) ist schneller wenn kein Regex nötig
grep -F "exact.match" huge.log

# --mmap für sehr große Dateien (kann helfen)
grep --mmap "pattern" huge.log
```

### Spezielle Zeichen escapen

```bash
# Punkt (literal)
grep '\.' file.txt

# Dollar-Zeichen
grep '\$' file.txt

# Eckige Klammer
grep '\[' file.txt
```

## Exit Status

```bash
0 - Mindestens ein Match gefunden
1 - Kein Match
2 - Fehler
```

## Siehe auch

- `egrep` - Equivalent zu `grep -E`
- `fgrep` - Equivalent zu `grep -F`
- `sed` - Stream editor
- `awk` - Pattern processing
- regex(7) - Regex syntax

---
