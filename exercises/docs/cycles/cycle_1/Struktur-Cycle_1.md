# Cycle 1 - Struktur

## Table of content

  - [✅ Erstellte Artifacts:](#erstellte-artifacts)
  - [📁 Finale Dateistruktur:](#finale-dateistruktur)
  - [📊 Inhalt im Detail:](#inhalt-im-detail)
  - [🔧 Installation - 3 Schritte:](#installation-3-schritte)
  - [⚙️ Features pro Exercise:](#features-pro-exercise)
  - [🎮 Gamification Features:](#gamification-features)
  - [📚 Dokumentation:](#dokumentation)

---

## ✅ Erstellte Artifacts:

| # | Artifact ID | Datei(en) | Beschreibung |
|---|-------------|-----------|--------------|
| 1 | `cycle01_metadata` | `metadata.yaml` | Cycle-Metadaten, Objectives, Progression |
| 2 | `cycle01_day01_exercises` | `day_01/exercises.yaml` | 3 Echo Exercises (Redirect, Tee, Variables) |
| 3 | `cycle01_day02_exercises` | `day_02/exercises.yaml` | 3 Grep Exercises (Search, Invert, Regex) |
| 4 | `cycle01_day03_exercises` | `day_03/exercises.yaml` | 3 Find Exercises (Name, Size, Exec) |
| 5 | `cycle01_day04_06_powershell` | `day_04/`, `day_05/`, `day_06/exercises.yaml` | 9 PowerShell Exercises (muss in 3 Dateien aufgeteilt werden) |
| 6 | `cycle01_info_a` | `info_a.md` | Info-Einheit Halbzyklus A (Echo, Grep, Find) |
| 7 | `cycle01_info_b` | `info_b.md` | Info-Einheit Halbzyklus B (PowerShell) |
| 8 | `reference_docs_combined` | `echo.md`, `grep.md`, `find.md` | Reference-Docs (muss in 3 Dateien aufgeteilt werden) |
| 9 | `cycle01_installation_complete` | Installation Guide | Vollständiger Setup Guide |

---

## 📁 Finale Dateistruktur:

```
~/.config/nvim/
├── exercises/cycles/cycle_01/
│   ├── metadata.yaml                    ← Artifact 1
│   └── iteration_1/
│       ├── day_01/exercises.yaml        ← Artifact 2 (Echo: 3 Exercises)
│       ├── day_02/exercises.yaml        ← Artifact 3 (Grep: 3 Exercises)
│       ├── day_03/exercises.yaml        ← Artifact 4 (Find: 3 Exercises)
│       ├── day_04/exercises.yaml        ← Artifact 5 Teil 1 (PS Echo: 3 Exercises)
│       ├── day_05/exercises.yaml        ← Artifact 5 Teil 2 (PS Grep: 3 Exercises)
│       └── day_06/exercises.yaml        ← Artifact 5 Teil 3 (PS Find: 3 Exercises)
│
└── docs/
    ├── cycles/cycle_01/iteration_1/
    │   ├── info_a.md                    ← Artifact 6 (Linux/macOS Info)
    │   └── info_b.md                    ← Artifact 7 (PowerShell Info)
    │
    └── references/commands/
        ├── echo.md                      ← Artifact 8 Teil 1
        ├── grep.md                      ← Artifact 8 Teil 2
        └── find.md                      ← Artifact 8 Teil 3
```

---

## 📊 Inhalt im Detail:

**Exercises**: 18 total (3 pro Tag × 6 Tage)
- Tag 1: Echo Redirect, Tee, Variables
- Tag 2: Grep Search, Invert, Regex
- Tag 3: Find Name/Type, Size, Exec
- Tag 4: PowerShell Out-File, Write-Output, Variables
- Tag 5: PowerShell Select-String, NotMatch, Regex
- Tag 6: PowerShell Get-ChildItem, Where-Object, ForEach-Object

**Info-Einheiten**: 2 total
- Info A: Echo, Grep, Find Grundlagen (~10 Seiten)
- Info B: PowerShell Äquivalente (~8 Seiten)

**References**: 3 total
- echo.md: Operators, Variables, Tee, Examples
- grep.md: Flags, Regex, Context, Examples
- find.md: Tests, Actions, Operators, Examples

---

## 🔧 Installation - 3 Schritte:

**1. Verzeichnisse erstellen:**
```bash
cd ~/.config/nvim
mkdir -p exercises/cycles/cycle_01/iteration_1/day_{01..06}
mkdir -p docs/cycles/cycle_01/iteration_1
mkdir -p docs/references/commands
```

**2. Dateien kopieren:**
- Artifacts 1-7 sind **eins-zu-eins** verwendbar
- Artifact 5 (PowerShell) in **3 Dateien** aufteilen (Tag 4-6)
- Artifact 8 (References) in **3 Dateien** aufteilen (echo, grep, find)

**3. Testen:**
```vim
:lua require("learn_cli").setup()
:LearnCli cycle_01
```

---

## ⚙️ Features pro Exercise:

Jedes Exercise enthält:
- ✅ Task Description mit Expected Result
- ✅ Primary Solution + Alternatives
- ✅ 4-Level Progressive Hints System
- ✅ Validation (7 verschiedene Typen)
- ✅ Scoring (Base + Time Bonus + Hint Penalties)
- ✅ Custom Feedback Messages (Success + Errors)
- ✅ Tags für Kategorisierung
- ✅ Setup für Working Directory / Files

---

## 🎮 Gamification Features:

- **Points**: 100-150 pro Exercise
- **Time Bonuses**: +5 bis +25 für schnelle Lösungen
- **Hint Penalties**: -10 bis -50 je nach Level
- **XP System**: 25 XP pro abgeschlossenem Exercise
- **Streaks**: Täglich tracken
- **Achievements**: Bereit für Integration

---

## 📚 Dokumentation:

- **2 umfangreiche Info-Einheiten** mit:
  - Lernzielen
  - Befehlsübersicht mit Beispielen
  - Häufige Fehler & Tipps
  - Weiterführende Literatur
  - Cheat Sheets

 **3 detaillierte Reference Docs** mit:
  - Syntax & Options
  - Regex Patterns (für grep)
  - Operators & Tests (für find)
  - Viele praktische Beispiele
  - Performance Tipps

---
