# Neovim Startup Benchmarking

Automatisierte Benchmarking-Tools zur Messung der Neovim-Startzeit und UI-Enter-Zeit mit statistischer Auswertung.

## Table of content

  - [📊 Features](#features)
  - [📁 Struktur](#struktur)
  - [🚀 Installation](#installation)
    - [1. Skripte platzieren](#1-skripte-platzieren)
    - [2. Skript ausführbar machen (Linux/macOS)](#2-skript-ausfhrbar-machen-linuxmacos)
  - [💻 Verwendung](#verwendung)
    - [Windows (PowerShell)](#windows-powershell)
    - [Linux/macOS (zsh)](#linuxmacos-zsh)
  - [📈 Beispiel-Output](#beispiel-output)
  - [📊 Metriken erklärt](#metriken-erklrt)
    - [Startup Time](#startup-time)
    - [UI Enter Time](#ui-enter-time)
    - [Warum ist Run 1 oft langsamer?](#warum-ist-run-1-oft-langsamer)
  - [🔧 Konfiguration](#konfiguration)
    - [Lua-Skript anpassen](#lua-skript-anpassen)
    - [Eigene Metriken hinzufügen](#eigene-metriken-hinzufgen)
  - [🐛 Troubleshooting](#troubleshooting)
    - [Problem: Skript bleibt hängen](#problem-skript-bleibt-hngen)
    - [Problem: "No valid output"](#problem-no-valid-output)
    - [Problem: UI Enter Time unrealistisch hoch](#problem-ui-enter-time-unrealistisch-hoch)
    - [Problem: Timeout bei jedem Run](#problem-timeout-bei-jedem-run)
  - [📚 Best Practices](#best-practices)
    - [Empfohlene Workflow](#empfohlene-workflow)
    - [Optimierungs-Tipps](#optimierungs-tipps)
  - [🎯 Zielwerte](#zielwerte)
  - [📦 CSV-Export](#csv-export)
  - [🤝 Contributing](#contributing)
  - [🔗 Siehe auch](#siehe-auch)

---

## 📊 Features

- **Automatisierte Messungen**: Führt N Benchmark-Runs automatisch durch
- **Warmup-Run**: Optional vorgelagerter Warmup-Lauf für stabilere Ergebnisse
- **Statistische Auswertung**: Berechnet Mean, Median, Min, Max und Standardabweichung
- **CSV-Export**: Exportiert Rohdaten für weitere Analysen
- **Timeout-Protection**: Automatisches Killing von hängenden Prozessen
- **Debug-Modus**: Zeigt detaillierte Neovim-Ausgaben für Troubleshooting
- **Cross-Platform**: Unterstützt Windows (PowerShell) und Unix (zsh)

## 📁 Struktur

```
debugging/performance/scripts/
├── benchmark_nvim.ps1              # PowerShell-Skript (Windows)
├── benchmark_nvim.sh               # zsh-Skript (Linux/macOS)
├── benchmark_startup.lua           # Lua-Messskript für Neovim
└── README.md                       # Diese Datei
```

## 🚀 Installation

### 1. Skripte platzieren

```bash
# Linux/macOS
mkdir -p ~/.config/nvim/lua/debugging/performance/scripts
cd ~/.config/nvim/lua/debugging/performance/scripts

# Windows
mkdir $env:USERPROFILE\AppData\Local\nvim\lua\debugging\performance\scripts
cd $env:USERPROFILE\AppData\Local\nvim\lua\debugging\performance\scripts
```

### 2. Skript ausführbar machen (Linux/macOS)

```bash
chmod +x benchmark_nvim.sh
```

## 💻 Verwendung

### Windows (PowerShell)

```powershell
# Standard: 15 Runs mit Warmup
.\benchmark_nvim.ps1

# Custom Anzahl Runs
.\benchmark_nvim.ps1 -Runs 20

# Mit Debug-Output
.\benchmark_nvim.ps1 -Runs 5 -Debug

# Ohne Warmup
.\benchmark_nvim.ps1 -Runs 10 -SkipWarmup

# Kombiniert
.\benchmark_nvim.ps1 -Runs 5 -Debug -SkipWarmup
```

### Linux/macOS (zsh)

```bash
# Standard: 15 Runs mit Warmup
./benchmark_nvim.sh

# Custom Anzahl Runs
./benchmark_nvim.sh 20

# Mit Debug-Output
./benchmark_nvim.sh 5 --debug

# Ohne Warmup
./benchmark_nvim.sh 10 --skip-warmup

# Kombiniert
./benchmark_nvim.sh 5 --debug --skip-warmup
```

## 📈 Beispiel-Output

```
Running warmup...
Warmup complete

Starting 5 benchmark runs...

Run 1/5... Startup: 1682.73ms, UI Enter: 756.27ms
Run 2/5... Startup: 639.93ms, UI Enter: 612.80ms
Run 3/5... Startup: 635.72ms, UI Enter: 608.39ms
Run 4/5... Startup: 635.77ms, UI Enter: 609.25ms
Run 5/5... Startup: 625.87ms, UI Enter: 605.24ms

=== Results ===

Startup Time (ms):
  Mean:   844.00
  Median: 635.77
  Min:    625.87
  Max:    1682.73
  StdDev: 419.39

UI Enter Time (ms):
  Mean:   638.39
  Median: 609.25
  Min:    605.24
  Max:    756.27
  StdDev: 60.12

=== Raw Data ===
Run 1: Startup=1682.73ms, UIEnter=756.27ms
Run 2: Startup=639.93ms, UIEnter=612.80ms
Run 3: Startup=635.72ms, UIEnter=608.39ms
Run 4: Startup=635.77ms, UIEnter=609.25ms
Run 5: Startup=625.87ms, UIEnter=605.24ms

CSV exported: ./nvim_benchmark_20260105_093748.csv
```

## 📊 Metriken erklärt

### Startup Time
Die **Gesamtstartzeit** von Neovim, gemessen vom Start bis zur vollständigen Initialisierung aller Plugins. Dies wird aus der `--startuptime`-Datei extrahiert oder von Lazy.nvim bereitgestellt.

**Typische Werte:**
- ⚡ **< 50ms**: Exzellent (minimale Config, wenige Plugins)
- ✅ **50-200ms**: Gut (moderate Config)
- ⚠️ **200-500ms**: Akzeptabel (viele Plugins)
- 🐌 **> 500ms**: Optimierung empfohlen

### UI Enter Time
Die Zeit bis zum **UIEnter-Event** - wenn Neovim bereit ist, UI-Operationen durchzuführen. Dies ist oft früher als die totale Startup-Zeit, da viele Plugins lazy-loaded werden.

**Interpretation:**
- Niedrigere UI Enter Time = Schnellere initiale Reaktionsfähigkeit
- Große Differenz zu Startup Time = Viel lazy-loading (gut für Performance)

### Warum ist Run 1 oft langsamer?

Der erste Run ist häufig 2-3x langsamer als die folgenden, da:
- Dateisystem-Caches noch nicht warm sind
- Plugins zum ersten Mal geladen werden
- Lua-Bytecode kompiliert wird

**Lösung:** Deshalb führen wir einen Warmup-Run durch!

## 🔧 Konfiguration

### Lua-Skript anpassen

Das Lua-Skript `benchmark_startup.lua` verwendet mehrere Messmethoden:

1. **Lazy.nvim Stats** (wenn verfügbar)
2. **--startuptime Datei** (Fallback)
3. **vim.loop.hrtime()** (für UI Enter Time)

Bei Bedarf kannst du die Priorität ändern oder zusätzliche Metriken hinzufügen.

### Eigene Metriken hinzufügen

```lua
-- In benchmark_startup.lua
local custom_metric = 0.0

-- Deine Messung hier
pcall(function()
  -- Beispiel: Plugin-Ladezeit
  local my_plugin = require("my_plugin")
  if my_plugin.stats then
    custom_metric = my_plugin.stats.load_time
  end
end)

-- Output erweitern
io.write(string.format("%.2f,%.2f,%.2f\n",
  startup_time, ui_enter_time, custom_metric))
```

## 🐛 Troubleshooting

### Problem: Skript bleibt hängen

**Lösung:**
1. Verwende Debug-Modus: `-Debug` (PowerShell) oder `--debug` (zsh)
2. Prüfe, ob Neovim plugins auf Input warten
3. Teste mit minimal config: `nvim --clean`

```bash
# Test ohne Config
nvim --clean --headless -c "lua print('test'); vim.cmd('qa!')"
```

### Problem: "No valid output"

**Ursachen:**
- Lua-Skript-Pfad falsch
- Lua-Fehler im Skript
- Neovim-Version zu alt (< 0.5)

**Debug:**
```powershell
# Manueller Test (Windows)
$env:NVIM_STARTUPTIME_FILE="$env:TEMP\test.txt"
nvim --headless --startuptime "$env:TEMP\test.txt" `
     -c "luafile $env:USERPROFILE\AppData\Local\nvim\lua\debugging\performance\scripts\benchmark_startup.lua"
```

```bash
# Manueller Test (Linux/macOS)
export NVIM_STARTUPTIME_FILE="/tmp/test.txt"
nvim --headless --startuptime /tmp/test.txt \
     -c "luafile ~/.config/nvim/lua/debugging/performance/scripts/benchmark_startup.lua"
```

### Problem: UI Enter Time unrealistisch hoch

**Ursache:** Alte Version des Lua-Skripts verwendet `reltimefloat()` statt `vim.loop.hrtime()`

**Lösung:** Aktualisiere `benchmark_startup.lua` auf die neueste Version.

### Problem: Timeout bei jedem Run

**Ursachen:**
- Plugin wartet auf Netzwerk/Input
- Infinite Loop in Config
- Sehr langsame Plugins

**Lösung:**
1. Erhöhe Timeout im Skript (Zeile `TIMEOUT=5` → `TIMEOUT=10`)
2. Identifiziere langsame Plugins: `nvim --startuptime startup.log`
3. Deaktiviere verdächtige Plugins temporär

## 📚 Best Practices

### Empfohlene Workflow

1. **Baseline erstellen**
   ```bash
   ./benchmark_nvim.sh 20 > baseline.txt
   ```

2. **Config-Änderungen testen**
   ```bash
   # Nach Plugin-Installation/Konfiguration
   ./benchmark_nvim.sh 20 > after_changes.txt
   ```

3. **Vergleichen**
   ```bash
   diff baseline.txt after_changes.txt
   ```

### Optimierungs-Tipps

- **Lazy-loading aktivieren**: Nutze Lazy.nvim's `lazy = true`
- **Event-based loading**: `event = "BufReadPost"` statt eager loading
- **Plugin-Audit**: Entferne ungenutzte Plugins
- **Startuptime analysieren**: `nvim --startuptime startup.log` für Details

## 🎯 Zielwerte

Je nach Use-Case:

| Szenario | Ziel Startup Time |
|----------|-------------------|
| Minimal-Config | < 50ms |
| IDE-Ersatz | < 200ms |
| Full-Featured | < 500ms |

## 📦 CSV-Export

Die CSV-Dateien enthalten alle Rohdaten und können mit Tools wie Excel, R, Python/Pandas analysiert werden:

```python
import pandas as pd
import matplotlib.pyplot as plt

# Daten laden
df = pd.read_csv('nvim_benchmark_20260105_093748.csv')

# Visualisieren
df.plot(x='Run', y=['Startup', 'UIEnter'], kind='line')
plt.ylabel('Time (ms)')
plt.title('Neovim Startup Performance')
plt.show()
```

## 🤝 Contributing

Mögliche Erweiterungen:

- [ ] Memory-Usage-Tracking
- [ ] Plugin-spezifisches Profiling
- [ ] HTML-Report-Generator
- [ ] Vergleichs-Modus für A/B-Tests
- [ ] CI/CD-Integration

## 🔗 Siehe auch

- [Neovim Startup Time Guide](https://neovim.io/doc/user/starting.html#--startuptime)
- [Lazy.nvim Performance Tips](https://github.com/folke/lazy.nvim#-performance)
- [Profiling Neovim Startup](https://neovim.io/doc/user/lua.html#lua-profile)
