# Find Command Reference

## Table of content

  - [Übersicht](#bersicht)
  - [Wichtigste Tests](#wichtigste-tests)
    - [Nach Typ](#nach-typ)
    - [Nach Name](#nach-name)
    - [Nach Größe](#nach-gre)
    - [Nach Zeit](#nach-zeit)
    - [Nach Permissions](#nach-permissions)
    - [Nach Eigentümer](#nach-eigentmer)
    - [Weitere Tests](#weitere-tests)
  - [Operators](#operators)
  - [Actions](#actions)
  - [Beispiele](#beispiele)
    - [Einfache Suchen](#einfache-suchen)
    - [Nach Größe](#nach-gre-1)
    - [Nach Zeit](#nach-zeit-1)
    - [Kombinationen](#kombinationen)
    - [Mit -exec](#mit-exec)
    - [Printf](#printf)
  - [Tipps](#tipps)
    - [Performance](#performance)
    - [Sicherheit](#sicherheit)
  - [Siehe auch](#siehe-auch)

---

## Übersicht

`find` durchsucht Verzeichnisbäume nach Dateien/Verzeichnissen.

```bash
find [PATH...] [EXPRESSION]
```

**Expression** besteht aus: Tests, Actions, Operators

## Wichtigste Tests

### Nach Typ

```bash
-type f     # Regular file
-type d     # Directory
-type l     # Symbolic link
-type b     # Block device
-type c     # Character device
-type p     # Named pipe (FIFO)
-type s     # Socket
```

### Nach Name

```bash
-name "pattern"      # Name (mit Wildcards)
-iname "pattern"     # Name, case-insensitive
-path "pattern"      # Voller Pfad
-ipath "pattern"     # Pfad, case-insensitive
```

### Nach Größe

```bash
-size N[cwbkMG]
  c - bytes
  k - kilobytes
  M - megabytes
  G - gigabytes

-size 100c      # Exakt 100 bytes
-size +100k     # Größer als 100 KB
-size -1M       # Kleiner als 1 MB
```

### Nach Zeit

```bash
-mtime N    # Geändert vor N Tagen
-atime N    # Accessed vor N Tagen
-ctime N    # Status geändert vor N Tagen
-mmin N     # Geändert vor N Minuten
-amin N     # Accessed vor N Minuten

-mtime -7   # Geändert in letzten 7 Tagen
-mtime +30  # Geändert vor mehr als 30 Tagen
```

### Nach Permissions

```bash
-perm mode      # Exakte Permissions
-perm -mode     # Mindestens diese Bits
-perm /mode     # Irgendein Bit gesetzt

-perm 644       # Exakt 644
-perm -644      # Mindestens rw-r--r--
```

### Nach Eigentümer

```bash
-user NAME      # Besitzer
-group NAME     # Gruppe
-uid N          # User ID
-gid N          # Group ID
```

### Weitere Tests

```bash
-empty          # Leere Dateien/Verzeichnisse
-newer FILE     # Neuer als FILE
-readable       # Lesbar
-writable       # Schreibbar
-executable     # Ausführbar
```

## Operators

```bash
! EXPRESSION    # NOT
-not EXPRESSION # NOT (alternative)
EXPR1 -a EXPR2  # AND (default)
EXPR1 -and EXPR2
EXPR1 -o EXPR2  # OR
EXPR1 -or EXPR2
\( EXPR \)      # Gruppierung
```

## Actions

```bash
-print          # Ausgabe (default)
-print0         # Mit null-terminator
-printf FORMAT  # Formatierte Ausgabe
-ls             # Wie ls -dils
-delete         # Löschen (VORSICHT!)
-exec CMD {} \; # CMD pro Datei
-exec CMD {} +  # CMD mit allen Dateien
-ok CMD {} \;   # Wie -exec, aber mit Bestätigung
-prune          # Nicht in Verzeichnis absteigen
```

## Beispiele

### Einfache Suchen

```bash
# Alle .txt Dateien
find . -name "*.txt"

# Nur Dateien, nicht Verzeichnisse
find . -type f -name "*.log"

# Case-insensitive
find . -iname "*.TXT"

# In bestimmtem Verzeichnis
find /var/log -name "*.log"
```

### Nach Größe

```bash
# Größer als 100 MB
find . -type f -size +100M

# Kleiner als 1 KB
find . -type f -size -1k

# Zwischen 1 und 10 MB
find . -type f -size +1M -size -10M

# Leere Dateien
find . -type f -empty
```

### Nach Zeit

```bash
# Geändert in letzten 7 Tagen
find . -type f -mtime -7

# Älter als 30 Tage
find . -type f -mtime +30

# Geändert in letzten 24 Stunden
find . -type f -mmin -1440

# Neuer als bestimmte Datei
find . -newer reference.txt
```

### Kombinationen

```bash
# .log Dateien größer als 10 MB
find . -name "*.log" -size +10M

# .txt oder .md Dateien
find . \( -name "*.txt" -o -name "*.md" \)

# Nicht in .git Verzeichnissen
find . -name ".git" -prune -o -type f -print

# Nur bestimmte Tiefe
find . -maxdepth 2 -name "*.txt"
```

### Mit -exec

```bash
# Alle .tmp löschen
find . -name "*.tmp" -delete
# Oder:
find . -name "*.tmp" -exec rm {} \;

# Zeilen zählen in allen .txt
find . -name "*.txt" -exec wc -l {} \;

# Batch-Modus (ein Aufruf)
find . -name "*.txt" -exec wc -l {} +

# Mit Bestätigung
find . -name "*.tmp" -ok rm {} \;

# Kopieren
find . -name "*.jpg" -exec cp {} /backup/ \;

# Mit xargs (effizienter)
find . -name "*.log" -print0 | xargs -0 wc -l
```

### Printf

```bash
# Custom Format
find . -type f -printf "%p\t%s bytes\n"

# Mit Datum
find . -type f -printf "%TY-%Tm-%Td %p\n"
```

## Tipps

### Performance

```bash
# Tests nach Wahrscheinlichkeit ordnen
# Schnell zuerst:
find . -name "*.txt" -size +1M -mtime -7

# -prune für große Verzeichnisse
find . -name node_modules -prune -o -name "*.js" -print
```

### Sicherheit

```bash
# Vorsicht mit -delete!
# Besser erst testen:
find . -name "*.tmp"
# Dann löschen:
find . -name "*.tmp" -delete

# Mit -exec und Spaces in Namen
# Nutze {} in Quotes:
find . -name "*.txt" -exec cat "{}" \;
```

## Siehe auch

- `locate` - Schnellere Alternative (nutzt DB)
- `fd` - Modernes find-Alternative
- `xargs` - Build and execute commands
- find(1) - Full manual

---
