# Echo Command Reference

## Table of content

  - [Übersicht](#bersicht)
  - [Redirection Operators](#redirection-operators)
  - [Wichtige Optionen](#wichtige-optionen)
  - [Escape-Sequenzen (mit -e)](#escape-sequenzen-mit-e)
  - [Variablen](#variablen)
  - [Tee](#tee)
  - [Command Substitution](#command-substitution)
  - [Beispiele](#beispiele)
  - [Siehe auch](#siehe-auch)

---

## Übersicht

`echo` gibt Text auf stdout aus.

```bash
echo [OPTIONS] [STRING...]
```

## Redirection Operators

| Operator | Bedeutung | Beispiel |
|----------|-----------|----------|
| `>` | Überschreiben | `echo "text" > file.txt` |
| `>>` | Anhängen | `echo "text" >> file.txt` |
| `\|` | Pipe zu anderem Befehl | `echo "text" \| wc -c` |
| `2>` | Stderr umleiten | `command 2> errors.log` |
| `&>` | Stdout + Stderr | `command &> output.log` |

## Wichtige Optionen

```bash
-n    # Kein newline am Ende
-e    # Escape-Sequenzen interpretieren
-E    # Escape-Sequenzen NICHT interpretieren (default)
```

## Escape-Sequenzen (mit -e)

```bash
echo -e "Line1\nLine2"   # → 2 Zeilen
echo -e "Tab\there"      # → Tab-Zeichen
echo -e "\033[31mRed\033[0m"  # → Farbiger Text
```

## Variablen

```bash
NAME="World"
echo "Hello $NAME"           # → Hello World
echo "Hello ${NAME}!"        # → Hello World!
echo 'Hello $NAME'           # → Hello $NAME (literal)
```

## Tee

```bash
# Output auf Screen UND in Datei
echo "test" | tee file.txt

# An Datei anhängen
echo "test" | tee -a file.txt

# Mehrere Dateien
echo "test" | tee file1.txt file2.txt

# Stderr auch
command 2>&1 | tee log.txt
```

## Command Substitution

```bash
echo "Today is $(date)"
echo "Files: $(ls | wc -l)"
```

## Beispiele

```bash
# Einfacher Text
echo "Hello World"

# Mehrere Argumente
echo One Two Three

# In Datei schreiben
echo "Log entry" > app.log

# An Datei anhängen
echo "Another entry" >> app.log

# Mit Variable
USER="Alice"
echo "Welcome, $USER!"

# Multiline
echo "Line 1
Line 2
Line 3"

# Mit tee (sichtbar + speichern)
echo "Important" | tee important.txt
```

## Siehe auch

- `printf` - Formatierte Ausgabe
- `cat` - Dateien ausgeben
- bash(1) - Shell builtin commands

---

