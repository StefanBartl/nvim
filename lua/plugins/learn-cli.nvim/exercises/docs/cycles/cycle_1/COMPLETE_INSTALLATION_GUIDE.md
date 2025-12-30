# 📦 Vollständige Installation: Cycle 1

## Table of content

  - [🗂️ Verzeichnisstruktur](#verzeichnisstruktur)
  - [🚀 Schritt-für-Schritt Installation](#schritt-fr-schritt-installation)
    - [1. Verzeichnisse erstellen](#1-verzeichnisse-erstellen)
    - [2. Dateien erstellen](#2-dateien-erstellen)
      - [Metadata](#metadata)
      - [Tag 1-3 (Linux/macOS)](#tag-1-3-linuxmacos)
      - [Tag 4-6 (PowerShell)](#tag-4-6-powershell)
      - [Info-Einheiten](#info-einheiten)
      - [Reference Docs](#reference-docs)
  - [✅ Installation verifizieren](#installation-verifizieren)
    - [1. Verzeichnisstruktur prüfen](#1-verzeichnisstruktur-prfen)
    - [2. YAML-Syntax validieren](#2-yaml-syntax-validieren)
    - [3. In Neovim testen](#3-in-neovim-testen)
  - [🐛 Troubleshooting](#troubleshooting)
    - [Problem: "Cycle nicht gefunden"](#problem-cycle-nicht-gefunden)
    - [Problem: "Exercise konnte nicht geladen werden"](#problem-exercise-konnte-nicht-geladen-werden)
    - [Problem: "Info-Einheit nicht gefunden"](#problem-info-einheit-nicht-gefunden)
    - [Problem: YAML Parse Error](#problem-yaml-parse-error)
  - [📝 Datei-Checkliste](#datei-checkliste)
  - [🎯 Quick Start nach Installation](#quick-start-nach-installation)
  - [📊 Erwartete Ergebnisse](#erwartete-ergebnisse)
  - [🔄 Weitere Iterationen](#weitere-iterationen)
  - [🎓 Nach der Installation](#nach-der-installation)

---

## 🗂️ Verzeichnisstruktur

```
~/.config/nvim/
├── exercises/
│   └── cycles/
│       └── cycle_01/
│           ├── metadata.yaml                  # Cycle-Metadaten
│           └── iteration_1/
│               ├── day_01/
│               │   └── exercises.yaml         # Tag 1: Echo
│               ├── day_02/
│               │   └── exercises.yaml         # Tag 2: Grep
│               ├── day_03/
│               │   └── exercises.yaml         # Tag 3: Find
│               ├── day_04/
│               │   └── exercises.yaml         # Tag 4: PowerShell Echo
│               ├── day_05/
│               │   └── exercises.yaml         # Tag 5: PowerShell Grep
│               └── day_06/
│                   └── exercises.yaml         # Tag 6: PowerShell Find
│
└── docs/
    ├── cycles/
    │   └── cycle_01/
    │       └── iteration_1/
    │           ├── info_a.md                  # Info-Einheit Halbzyklus A
    │           └── info_b.md                  # Info-Einheit Halbzyklus B
    └── references/
        └── commands/
            ├── echo.md                        # Echo Reference
            ├── grep.md                        # Grep Reference
            └── find.md                        # Find Reference
```

## 🚀 Schritt-für-Schritt Installation

### 1. Verzeichnisse erstellen

```bash
cd ~/.config/nvim

# Exercises
mkdir -p exercises/cycles/cycle_01/iteration_1/day_{01..06}

# Docs
mkdir -p docs/cycles/cycle_01/iteration_1
mkdir -p docs/references/commands
```

### 2. Dateien erstellen

#### Metadata

**Datei**: `exercises/cycles/cycle_01/metadata.yaml`

```bash
cat > exercises/cycles/cycle_01/metadata.yaml << 'EOF'
# [Inhalt aus Artifact "cycle01_metadata" kopieren]
EOF
```

#### Tag 1-3 (Linux/macOS)

**Datei**: `exercises/cycles/cycle_01/iteration_1/day_01/exercises.yaml`
```bash
cat > exercises/cycles/cycle_01/iteration_1/day_01/exercises.yaml << 'EOF'
# [Inhalt aus Artifact "cycle01_day01_exercises" kopieren]
EOF
```

**Datei**: `exercises/cycles/cycle_01/iteration_1/day_02/exercises.yaml`
```bash
cat > exercises/cycles/cycle_01/iteration_1/day_02/exercises.yaml << 'EOF'
# [Inhalt aus Artifact "cycle01_day02_exercises" kopieren]
EOF
```

**Datei**: `exercises/cycles/cycle_01/iteration_1/day_03/exercises.yaml`
```bash
cat > exercises/cycles/cycle_01/iteration_1/day_03/exercises.yaml << 'EOF'
# [Inhalt aus Artifact "cycle01_day03_exercises" kopieren]
EOF
```

#### Tag 4-6 (PowerShell)

**WICHTIG**: Das Artifact "cycle01_day04_06_powershell" enthält ALLE 3 Tage.
Sie müssen es in 3 separate Dateien aufteilen:

```bash
# Tag 4
cat > exercises/cycles/cycle_01/iteration_1/day_04/exercises.yaml << 'EOF'
# [Ersten Teil des Artifacts kopieren - bis zur "---" Trennlinie]
EOF

# Tag 5
cat > exercises/cycles/cycle_01/iteration_1/day_05/exercises.yaml << 'EOF'
# [Zweiten Teil des Artifacts kopieren - zwischen den "---" Trennlinien]
EOF

# Tag 6
cat > exercises/cycles/cycle_01/iteration_1/day_06/exercises.yaml << 'EOF'
# [Dritten Teil des Artifacts kopieren - nach der zweiten "---" Trennlinie]
EOF
```

#### Info-Einheiten

**Datei**: `docs/cycles/cycle_01/iteration_1/info_a.md`
```bash
cat > docs/cycles/cycle_01/iteration_1/info_a.md << 'EOF'
# [Inhalt aus Artifact "cycle01_info_a" kopieren]
EOF
```

**Datei**: `docs/cycles/cycle_01/iteration_1/info_b.md`
```bash
cat > docs/cycles/cycle_01/iteration_1/info_b.md << 'EOF'
# [Inhalt aus Artifact "cycle01_info_b" kopieren]
EOF
```

#### Reference Docs

**WICHTIG**: Das Artifact "reference_docs_combined" enthält ALLE 3 Reference-Docs.
Sie müssen es in 3 separate Dateien aufteilen:

```bash
# Echo
cat > docs/references/commands/echo.md << 'EOF'
# [Ersten Teil kopieren - bis zur zweiten "# ===" Linie]
EOF

# Grep
cat > docs/references/commands/grep.md << 'EOF'
# [Zweiten Teil kopieren - zwischen den "# ===" Linien]
EOF

# Find
cat > docs/references/commands/find.md << 'EOF'
# [Dritten Teil kopieren - nach der letzten "# ===" Linie]
EOF
```

## ✅ Installation verifizieren

### 1. Verzeichnisstruktur prüfen

```bash
tree exercises/cycles/cycle_01
tree docs/cycles/cycle_01
tree docs/references/commands
```

**Erwartete Ausgabe**:
```
exercises/cycles/cycle_01
├── metadata.yaml
└── iteration_1
    ├── day_01
    │   └── exercises.yaml
    ├── day_02
    │   └── exercises.yaml
    ├── day_03
    │   └── exercises.yaml
    ├── day_04
    │   └── exercises.yaml
    ├── day_05
    │   └── exercises.yaml
    └── day_06
        └── exercises.yaml

docs/cycles/cycle_01
└── iteration_1
    ├── info_a.md
    └── info_b.md

docs/references/commands
├── echo.md
├── grep.md
└── find.md
```

### 2. YAML-Syntax validieren

```bash
# Falls yamllint installiert ist
yamllint exercises/cycles/cycle_01/metadata.yaml
yamllint exercises/cycles/cycle_01/iteration_1/day_*/exercises.yaml
```

### 3. In Neovim testen

```vim
:lua require("learn_cli").setup()
:LearnCli
```

**Erwartetes Verhalten**:
1. Dashboard öffnet sich
2. "cycle_01" wird in der Liste angezeigt
3. Bei Auswahl wird info_a.md angezeigt
4. Nach Bestätigung startet das erste Exercise

## 🐛 Troubleshooting

### Problem: "Cycle nicht gefunden"

**Lösung**:
```bash
# Prüfe ob metadata.yaml existiert
ls -la exercises/cycles/cycle_01/metadata.yaml

# Prüfe YAML-Syntax
cat exercises/cycles/cycle_01/metadata.yaml
```

### Problem: "Exercise konnte nicht geladen werden"

**Lösung**:
```bash
# Prüfe ob exercises.yaml existiert
ls -la exercises/cycles/cycle_01/iteration_1/day_01/exercises.yaml

# Prüfe YAML-Syntax
yamllint exercises/cycles/cycle_01/iteration_1/day_01/exercises.yaml
```

### Problem: "Info-Einheit nicht gefunden"

**Lösung**:
```bash
# Prüfe ob info_a.md existiert
ls -la docs/cycles/cycle_01/iteration_1/info_a.md

# Prüfe Dateiinhalt
head docs/cycles/cycle_01/iteration_1/info_a.md
```

### Problem: YAML Parse Error

**Häufige Ursachen**:
- Tabs statt Spaces (YAML erlaubt nur Spaces!)
- Falsche Einrückung
- Fehlende Quotes bei Sonderzeichen
- YAML-Schlüsselwörter ohne Quotes (yes, no, true, false, on, off)

**Lösung**:
```bash
# Tabs durch Spaces ersetzen
expand -t 2 exercises.yaml > exercises_fixed.yaml

# Online YAML Validator nutzen
# https://www.yamllint.com/
```

## 📝 Datei-Checkliste

Stelle sicher, dass alle Dateien existieren:

```bash
# Metadata
[ -f exercises/cycles/cycle_01/metadata.yaml ] && echo "✅ metadata.yaml" || echo "❌ metadata.yaml"

# Exercises
for day in {01..06}; do
  [ -f "exercises/cycles/cycle_01/iteration_1/day_$day/exercises.yaml" ] && echo "✅ day_$day/exercises.yaml" || echo "❌ day_$day/exercises.yaml"
done

# Info Units
[ -f docs/cycles/cycle_01/iteration_1/info_a.md ] && echo "✅ info_a.md" || echo "❌ info_a.md"
[ -f docs/cycles/cycle_01/iteration_1/info_b.md ] && echo "✅ info_b.md" || echo "❌ info_b.md"

# References
for cmd in echo grep find; do
  [ -f "docs/references/commands/$cmd.md" ] && echo "✅ $cmd.md" || echo "❌ $cmd.md"
done
```

## 🎯 Quick Start nach Installation

```vim
" In Neovim
:LearnCli cycle_01

" Oder über Dashboard
:LearnCli
" Dann [1] oder <Enter> auf Cycle 1
```

**Flow**:
1. Info-Einheit A wird angezeigt (drücke `q` zum Starten)
2. Exercise 1 von Tag 1 startet
3. Exercise View öffnet sich rechts
4. Working Directory ist `/tmp/learn-cli/cycle_01/...`
5. Löse das Exercise im Terminal
6. `:LearnCliSubmit` zum Einreichen
7. Bei Erfolg: automatisch nächstes Exercise nach 2 Sekunden

## 📊 Erwartete Ergebnisse

Nach vollständiger Installation hast du:
- ✅ 1 Cycle mit 6 Tagen
- ✅ 18 Exercises (3 pro Tag × 6 Tage)
- ✅ 2 Info-Einheiten
- ✅ 3 Reference Docs
- ✅ Vollständiges Gamification (XP, Scores, Streaks)

**Gesamtdauer**: ~90 Minuten (6 Tage × 15 Minuten)

## 🔄 Weitere Iterationen

Cycle 1 ist derzeit nur für **Iteration 1** ausgearbeitet.

Für **Iteration 2** und **3**:
- Kopiere `iteration_1/` nach `iteration_2/` und `iteration_3/`
- Passe Schwierigkeitsgrad in den Exercise-Dateien an
- Füge neue/erweiterte Flags hinzu
- Erhöhe Komplexität und Points

Oder erstelle neue Iterationen basierend auf den Vorlagen!

## 🎓 Nach der Installation

1. Starte mit `:LearnCli cycle_01`
2. Arbeite Exercises nacheinander durch
3. Nutze Hints wenn nötig (kostet Punkte)
4. Prüfe deinen Progress mit `:LearnCliProgress`
5. Nach Tag 3: Info-Einheit B für PowerShell
6. Nach Tag 6: Cycle wiederholen oder neue Iteration

Viel Erfolg beim Lernen! 🚀
