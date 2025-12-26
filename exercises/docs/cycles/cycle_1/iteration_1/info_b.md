# PowerShell Äquivalente - echo, grep, find

**Willkommen zu Halbzyklus B!**

In den nächsten 3 Tagen (Tag 4-6) lernst du die PowerShell-Äquivalente zu den Linux/macOS Befehlen:
- **Tag 4**: `Write-Output` / `Out-File` (statt echo)
- **Tag 5**: `Select-String` (statt grep)
- **Tag 6**: `Get-ChildItem` (statt find)

---

## Table of content

  - [🎯 Warum PowerShell?](#warum-powershell)
  - [📖 Befehlsübersicht](#befehlsbersicht)
    - [Write-Output / Out-File (Echo-Äquivalent)](#write-output-out-file-echo-quivalent)
      - [Grundkonzepte](#grundkonzepte)
      - [Out-File (> und >> Äquivalent)](#out-file-und-quivalent)
      - [Variablen](#variablen)
      - [Tee-Object](#tee-object)
      - [Vergleich: Bash vs PowerShell](#vergleich-bash-vs-powershell)
    - [Select-String (Grep-Äquivalent)](#select-string-grep-quivalent)
      - [Syntax](#syntax)
      - [Grundlegende Suche](#grundlegende-suche)
      - [Wichtigste Parameter](#wichtigste-parameter)
      - [Regex in PowerShell](#regex-in-powershell)
      - [Vergleich: grep vs Select-String](#vergleich-grep-vs-select-string)
    - [Get-ChildItem (Find-Äquivalent)](#get-childitem-find-quivalent)
      - [Syntax](#syntax-1)
      - [Grundlegende Suche](#grundlegende-suche-1)
      - [Filter](#filter)
      - [Where-Object (find -size/-mtime Äquivalent)](#where-object-find-size-mtime-quivalent)
      - [ForEach-Object (find -exec Äquivalent)](#foreach-object-find-exec-quivalent)
      - [Properties nutzen](#properties-nutzen)
      - [Vergleich: find vs Get-ChildItem](#vergleich-find-vs-get-childitem)
  - [🎮 Übungsstruktur](#bungsstruktur)
    - [Tag 4: Write-Output / Out-File](#tag-4-write-output-out-file)
    - [Tag 5: Select-String](#tag-5-select-string)
    - [Tag 6: Get-ChildItem](#tag-6-get-childitem)
  - [💡 PowerShell-spezifische Konzepte](#powershell-spezifische-konzepte)
    - [Pipeline & Objekte](#pipeline-objekte)
    - [Verb-Noun Pattern](#verb-noun-pattern)
    - [Aliase](#aliase)
    - [Hilfe-System](#hilfe-system)
  - [📖 Weiterführende Literatur](#weiterfhrende-literatur)
    - [Online-Ressourcen](#online-ressourcen)
    - [Bücher](#bcher)
  - [🔖 Cheat Sheet](#cheat-sheet)
    - [Quick Reference](#quick-reference)
  - [⚡ PowerShell Quick Tips](#powershell-quick-tips)
    - [Output](#output)
    - [Select-String](#select-string)
    - [Get-ChildItem](#get-childitem)

---

## 🎯 Warum PowerShell?

PowerShell ist:
- ✅ Cross-Platform (Windows, Linux, macOS)
- ✅ Objekt-orientiert (nicht text-basiert)
- ✅ Konsistent strukturiert (Verb-Noun Pattern)
- ✅ Mächtige Skriptsprache

---

## 📖 Befehlsübersicht

### Write-Output / Out-File (Echo-Äquivalent)

#### Grundkonzepte

**PowerShell arbeitet mit Objekten**, nicht nur Text!

```powershell
# Text ausgeben
Write-Output "Hello World"

# Oder kürzer (implizit):
"Hello World"
```

#### Out-File (> und >> Äquivalent)

**Überschreiben**:
```powershell
"hello world" | Out-File out.txt
# Oder mit Alias:
"hello world" > out.txt
```

**Anhängen**:
```powershell
"second line" | Out-File out.txt -Append
# Oder mit Alias:
"second line" >> out.txt
```

#### Variablen

```powershell
$Name = "Stefan"
Write-Output "Hello $Name"  # → Hello Stefan
"Hello $Name"               # → Hello Stefan

# Einfache Quotes (literal):
'Hello $Name'               # → Hello $Name
```

**Wichtig**: In PowerShell sind Variablen mit `$` prefix!

#### Tee-Object

```powershell
Get-Content input.txt | Tee-Object copy.txt
# Zeigt auf Screen UND schreibt in Datei
```

#### Vergleich: Bash vs PowerShell

| Bash | PowerShell |
|------|------------|
| `echo "text"` | `Write-Output "text"` oder `"text"` |
| `echo "x" > file` | `"x" \| Out-File file` oder `"x" > file` |
| `echo "x" >> file` | `"x" \| Out-File file -Append` oder `"x" >> file` |
| `cat file \| tee copy` | `Get-Content file \| Tee-Object copy` |
| `NAME="value"` | `$Name = "value"` |
| `echo "$NAME"` | `"$Name"` oder `Write-Output "$Name"` |

---

### Select-String (Grep-Äquivalent)

**Grundfunktion**: Text in Dateien suchen

#### Syntax
```powershell
Select-String -Pattern "MUSTER" -Path "DATEI"
```

#### Grundlegende Suche

```powershell
# Einfache Suche
Select-String -Pattern "error" data.txt

# Oder kürzer:
Select-String "error" data.txt

# Mit Pipeline:
Get-Content data.txt | Select-String "error"
```

#### Wichtigste Parameter

**`-NotMatch` (wie grep -v)**:
```powershell
Select-String -Pattern "error" -NotMatch data.txt
# Zeilen OHNE "error"
```

**`-CaseSensitive` (default ist case-INsensitive!)**:
```powershell
Select-String -Pattern "Error" -CaseSensitive data.txt
```

**`-Context` (wie grep -A/-B)**:
```powershell
Select-String "error" data.txt -Context 2,3
# 2 Zeilen VOR, 3 Zeilen NACH
```

#### Regex in PowerShell

PowerShell nutzt **.NET Regex** (sehr mächtig!):

```powershell
# ODER mit |
Select-String -Pattern "error|warning" log.txt

# Zeilenbegin ^
Select-String -Pattern "^error" log.txt

# Zeilenende $
Select-String -Pattern "error$" log.txt

# Zeichenklassen
Select-String -Pattern "[0-9]{1,3}\.[0-9]{1,3}" log.txt
```

**Wichtig**: In PowerShell ist `|` IMMER ODER (keine Escape nötig)!

#### Vergleich: grep vs Select-String

| grep | Select-String |
|------|---------------|
| `grep "pattern" file` | `Select-String "pattern" file` |
| `grep -v "pattern" file` | `Select-String "pattern" file -NotMatch` |
| `grep -n "pattern" file` | `Select-String "pattern" file` (zeigt automatisch Zeilen!) |
| `grep -i "pattern" file` | Default! (case-insensitive) |
| `grep -E "a\|b" file` | `Select-String "a\|b" file` (Regex default) |

---

### Get-ChildItem (Find-Äquivalent)

**Grundfunktion**: Dateien und Verzeichnisse finden

#### Syntax
```powershell
Get-ChildItem -Path "VERZEICHNIS" [PARAMETER]
```

**Alias**: `ls`, `dir`, `gci`

#### Grundlegende Suche

```powershell
# Alle Dateien im aktuellen Verzeichnis
Get-ChildItem

# Rekursiv (wie find)
Get-ChildItem -Recurse

# Nur Dateien
Get-ChildItem -File

# Nur Verzeichnisse
Get-ChildItem -Directory
```

#### Filter

**`-Filter` (schnellste Methode)**:
```powershell
Get-ChildItem -Path . -Recurse -Filter *.txt
# Alle .txt Dateien
```

**`-Include` (flexibler, aber langsamer)**:
```powershell
Get-ChildItem -Path . -Recurse -Include *.txt,*.log
# Mehrere Patterns
```

#### Where-Object (find -size/-mtime Äquivalent)

**Nach Größe filtern**:
```powershell
Get-ChildItem -Recurse -File | Where-Object Length -gt 1MB
# Dateien größer als 1 MB

# Oder ausführlich:
Get-ChildItem -Recurse -File | Where-Object { $_.Length -gt 1MB }
```

**Nach Datum filtern**:
```powershell
# Geändert in letzten 7 Tagen
Get-ChildItem -Recurse -File | Where-Object LastWriteTime -gt (Get-Date).AddDays(-7)

# Älter als 30 Tage
Get-ChildItem -Recurse -File | Where-Object LastWriteTime -lt (Get-Date).AddDays(-30)
```

#### ForEach-Object (find -exec Äquivalent)

```powershell
# Zeilen in allen .log Dateien zählen
Get-ChildItem -Recurse -Filter *.log | ForEach-Object {
    (Get-Content $_.FullName).Count
}

# Mit Ausgabe:
Get-ChildItem -Recurse -Filter *.log | ForEach-Object {
    "$($_.Name): $((Get-Content $_.FullName).Count) lines"
}
```

**`$_` ist das aktuelle Objekt in der Pipeline!**

#### Properties nutzen

Get-ChildItem liefert **Objekte** mit vielen Properties:

```powershell
Get-ChildItem | Select-Object Name, Length, LastWriteTime

# Verfügbare Properties:
Get-ChildItem | Get-Member
```

Wichtige Properties:
- `Name` - Dateiname
- `FullName` - Voller Pfad
- `Length` - Größe in Bytes
- `Extension` - Dateiendung (.txt, .log)
- `LastWriteTime` - Letztes Änderungsdatum
- `CreationTime` - Erstellungsdatum

#### Vergleich: find vs Get-ChildItem

| find | Get-ChildItem |
|------|---------------|
| `find . -name "*.txt"` | `Get-ChildItem -Recurse -Filter *.txt` |
| `find . -type f` | `Get-ChildItem -Recurse -File` |
| `find . -type d` | `Get-ChildItem -Recurse -Directory` |
| `find . -size +1M` | `Get-ChildItem -Recurse \| Where-Object Length -gt 1MB` |
| `find . -mtime -7` | `Get-ChildItem -Recurse \| Where-Object LastWriteTime -gt (Get-Date).AddDays(-7)` |
| `find . -exec cmd {} \;` | `Get-ChildItem -Recurse \| ForEach-Object { cmd $_ }` |

---

## 🎮 Übungsstruktur

### Tag 4: Write-Output / Out-File
- Exercise 1: Out-File und Append
- Exercise 2: Write-Output Basics
- Exercise 3: PowerShell Variablen

**Ziel**: Output in PowerShell kontrollieren

### Tag 5: Select-String
- Exercise 1: Einfache Suche
- Exercise 2: NotMatch (invertiert)
- Exercise 3: Regex

**Ziel**: Text mit PowerShell suchen

### Tag 6: Get-ChildItem
- Exercise 1: Rekursive Suche mit Filter
- Exercise 2: Where-Object für Größe
- Exercise 3: ForEach-Object

**Ziel**: Dateien finden und verarbeiten

---

## 💡 PowerShell-spezifische Konzepte

### Pipeline & Objekte

**Bash**: Text-basiert
```bash
ls -l | grep txt
# Grep durchsucht TEXT-Output von ls
```

**PowerShell**: Objekt-basiert
```powershell
Get-ChildItem | Where-Object Extension -eq ".txt"
# Where-Object filtert OBJEKTE mit Property Extension
```

### Verb-Noun Pattern

PowerShell Cmdlets folgen Verb-Noun:
- `Get-ChildItem` (Get = Verb, ChildItem = Noun)
- `Select-String` (Select = Verb, String = Noun)
- `Out-File` (Out = Verb, File = Noun)

Häufige Verbs:
- `Get-` - Etwas holen
- `Set-` - Etwas setzen
- `New-` - Etwas erstellen
- `Remove-` - Etwas löschen
- `Select-` - Etwas auswählen
- `Where-` - Filtern
- `ForEach-` - Iterieren

### Aliase

Viele Bash-Befehle haben PowerShell-Aliase:
```powershell
ls    → Get-ChildItem
dir   → Get-ChildItem
cat   → Get-Content
echo  → Write-Output
```

**Tipp**: Nutze `Get-Alias` um Aliase zu sehen!

### Hilfe-System

```powershell
Get-Help Get-ChildItem
Get-Help Get-ChildItem -Examples
Get-Help Get-ChildItem -Full
Get-Help Get-ChildItem -Online
```

---

## 📖 Weiterführende Literatur

### Online-Ressourcen

**Offizielle Dokumentation**:
- [PowerShell Documentation](https://docs.microsoft.com/en-us/powershell/)
- [About Files (Konzepte)](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/)
- [Select-String Docs](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/select-string)
- [Get-ChildItem Docs](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/get-childitem)

**Tutorials**:
- [PowerShell 101](https://docs.microsoft.com/en-us/powershell/scripting/learn/ps101/00-introduction)
- [PowerShell for Bash Users](https://docs.microsoft.com/en-us/powershell/scripting/learn/ps101/appendix-a)

### Bücher
- **"Learn PowerShell in a Month of Lunches"** by Don Jones & Jeffrey Hicks
- **"PowerShell Cookbook"** by Lee Holmes

---

## 🔖 Cheat Sheet

### Quick Reference

| Task | PowerShell | Bash |
|------|------------|------|
| Text ausgeben | `Write-Output "text"` | `echo "text"` |
| In Datei schreiben | `"text" \| Out-File file` | `echo "text" > file` |
| An Datei anhängen | `"text" \| Out-File file -Append` | `echo "text" >> file` |
| Variable setzen | `$Var = "value"` | `VAR="value"` |
| Variable nutzen | `"$Var"` | `"$VAR"` |
| Text suchen | `Select-String "pattern" file` | `grep "pattern" file` |
| Invertiert suchen | `Select-String "p" file -NotMatch` | `grep -v "p" file` |
| Dateien finden | `Get-ChildItem -Recurse -Filter *.txt` | `find . -name "*.txt"` |
| Nach Größe filtern | `Get-ChildItem \| Where-Object Length -gt 1MB` | `find . -size +1M` |
| Befehl pro Datei | `Get-ChildItem \| ForEach-Object { cmd }` | `find . -exec cmd {} \;` |

---

## ⚡ PowerShell Quick Tips

### Output
- `Out-File` mit `-Append` zum Anhängen
- `>` und `>>` funktionieren auch in PowerShell
- `Tee-Object` für Output + Datei gleichzeitig

### Select-String
- Default ist **case-insensitive**
- Nutze `-CaseSensitive` für genaue Suche
- Regex funktioniert direkt (kein `-E` nötig)
- `-Context N,M` für N Zeilen vor, M nach

### Get-ChildItem
- `-Filter` ist schneller als `-Include`
- `-File` und `-Directory` zum Filtern nach Typ
- `Where-Object` für komplexe Filter
- `$_` in Scriptblocks ist das aktuelle Objekt

---

**Bereit für PowerShell? Dann starte mit Tag 4! 🚀**

Viel Erfolg! 💪
