# Neovim Startup Benchmarking

Automated benchmarking tools to measure Neovim startup time, UI enter time, memory usage, and plugin performance with statistical analysis.

## Table of content

- [Neovim Startup Benchmarking](#neovim-startup-benchmarking)
  - [📊 Features](#features)
  - [📁 Structure](#structure)
  - [🚀 Installation](#installation)
    - [1. Load the Module](#1-load-the-module)
    - [2. Make Scripts Executable (Linux/macOS)](#2-make-scripts-executable-linuxmacos)
    - [3. Verify Installation](#3-verify-installation)
  - [💻 Usage](#usage)
    - [Commands](#commands)
    - [Examples](#examples)
    - [Command-Line Usage](#command-line-usage)
      - [Windows (PowerShell)](#windows-powershell)
- [Standard: 15 runs with warmup](#standard-15-runs-with-warmup)
- [Custom runs](#custom-runs)
- [With debug output](#with-debug-output)
- [Without warmup](#without-warmup)
- [Combined](#combined)
      - [Linux/macOS (zsh)](#linuxmacos-zsh)
- [Standard: 15 runs with warmup](#standard-15-runs-with-warmup-1)
- [Custom runs](#custom-runs-1)
- [With debug output](#with-debug-output-1)
- [Without warmup](#without-warmup-1)
- [Combined](#combined-1)
  - [📈 Understanding Results](#understanding-results)
    - [Output Format](#output-format)
    - [Metrics Explained](#metrics-explained)
    - [Why is Run 1 Often Slower?](#why-is-run-1-often-slower)
  - [📊 HTML Reports](#html-reports)
  - [🔧 Configuration](#configuration)
    - [Customizing Measurement Logic](#customizing-measurement-logic)
    - [Adjusting Thresholds](#adjusting-thresholds)
  - [🐛 Troubleshooting](#troubleshooting)
    - [Problem: Runs Fail with "TIMEOUT"](#problem-runs-fail-with-timeout)
    - [Problem: HTML Shows All Zeros](#problem-html-shows-all-zeros)
    - [Problem: Scripts Not Found](#problem-scripts-not-found)
    - [Problem: Permission Denied (Linux/macOS)](#problem-permission-denied-linuxmacos)
  - [📚 Best Practices](#best-practices)
    - [Recommended Workflow](#recommended-workflow)
    - [Optimization Tips](#optimization-tips)
  - [🎯 Target Values](#target-values)
  - [📦 Data Export](#data-export)
    - [CSV Format](#csv-format)
    - [JSON Metadata](#json-metadata)
    - [Analysis with Python/Pandas](#analysis-with-pythonpandas)
- [Load data](#load-data)
- [Visualize](#visualize)
  - [🤝 Contributing](#contributing)
  - [🔗 See Also](#see-also)
  - [📄 License](#license)

---

## 📊 Features

- **Automated Measurements**: Runs N benchmark iterations automatically
- **Warmup Run**: Optional warmup to stabilize filesystem/plugin caches
- **Statistical Analysis**: Calculates Mean, Median, Min, Max, and Standard Deviation
- **CSV Export**: Exports raw data for further analysis
- **HTML Reports**: Beautiful visual reports with historical comparisons
- **Memory Tracking**: Monitors memory usage during startup
- **Plugin Profiling**: Identifies slow-loading plugins (>10ms)
- **Timeout Protection**: Automatically kills hanging processes
- **Debug Mode**: Shows detailed Neovim output for troubleshooting
- **Cross-Platform**: Supports Windows (PowerShell) and Unix (zsh)

## 📁 Structure

```
lua/debugging/performance/
├── init.lua                    # Main module with commands
├── scripts/
│   ├── benchmark_nvim.ps1      # PowerShell script (Windows)
│   ├── benchmark_nvim.sh       # zsh script (Linux/macOS)
│   └── benchmark_startup.lua   # Lua measurement script
└── results/
    ├── csv/                    # CSV data + JSON metadata
    └── html/                   # HTML reports
```

## 🚀 Installation

### 1. Load the Module

In your `init.lua`:

```lua
-- Load performance benchmarking
require('debugging.performance').setup()
```

### 2. Make Scripts Executable (Linux/macOS)

```bash
chmod +x ~/.config/nvim/lua/debugging/performance/scripts/benchmark_nvim.sh
```

### 3. Verify Installation

```vim
:BenchmarkTest
```

This will check if all components are properly installed.

## 💻 Usage

### Commands

| Command | Description |
|---------|-------------|
| `:BenchmarkRun [n]` | Run benchmark with n iterations (default: 15) |
| `:BenchmarkRunDebug [n]` | Run benchmark with debug output |
| `:BenchmarkHtml` | Generate HTML report from existing results |
| `:BenchmarkTest` | Verify installation and show diagnostics |

### Examples

```vim
" Standard benchmark with 15 runs
:BenchmarkRun

" Quick benchmark with 5 runs
:BenchmarkRun 5

" Debug mode to troubleshoot issues
:BenchmarkRunDebug 5

" Generate HTML report
:BenchmarkHtml
```

### Command-Line Usage

#### Windows (PowerShell)

```powershell
# Standard: 15 runs with warmup
.\benchmark_nvim.ps1

# Custom runs
.\benchmark_nvim.ps1 -Runs 20

# With debug output
.\benchmark_nvim.ps1 -Runs 5 -Debug

# Without warmup
.\benchmark_nvim.ps1 -Runs 10 -SkipWarmup

# Combined
.\benchmark_nvim.ps1 -Runs 5 -Debug -SkipWarmup
```

#### Linux/macOS (zsh)

```bash
# Standard: 15 runs with warmup
./benchmark_nvim.sh

# Custom runs
./benchmark_nvim.sh 20

# With debug output
./benchmark_nvim.sh 5 --debug

# Without warmup
./benchmark_nvim.sh 10 --skip-warmup

# Combined
./benchmark_nvim.sh 5 --debug --skip-warmup
```

## 📈 Understanding Results

### Output Format

```
Run 1/15... Startup=652.75ms UI=1003.34ms Memory=745.53KB Plugins=127
Run 2/15... Startup=629.43ms UI=1003.62ms Memory=257.90KB Plugins=127
...

=== Results ===

Startup Time (ms):
  Mean:   631.29
  Median: 629.43
  Min:    616.36
  Max:    652.75
  StdDev: 9.23

UI Enter Time (ms):
  Mean:   997.97
  Median: 997.38
  Min:    986.51
  Max:    1011.19
  StdDev: 7.11

Memory Usage (KB):
  Mean:   425.67
  Median: 398.97
  Min:    196.41
  Max:    745.53
  StdDev: 156.32
```

### Metrics Explained

| Metric | Description | Typical Values |
|--------|-------------|----------------|
| **Startup Time** | Total time from launch to full initialization | < 500ms is good |
| **UI Enter Time** | Time until UI is ready for interaction | Usually higher than startup |
| **Memory Usage** | Memory allocated during startup | Depends on plugin count |
| **StdDev** | Consistency of measurements | Lower = more consistent |

### Why is Run 1 Often Slower?

The first run is typically 2-3x slower because:
- Filesystem caches are cold
- Plugins load for the first time
- Lua bytecode gets compiled

**Solution**: The warmup run mitigates this issue.

## 📊 HTML Reports

HTML reports provide:
- Visual statistics cards
- Historical comparisons with previous benchmarks
- Slow plugin identification
- Trend analysis

Generate a report:

```vim
:BenchmarkHtml
```

Then select a CSV file from the picker.

## 🔧 Configuration

### Customizing Measurement Logic

Edit `scripts/benchmark_startup.lua` to:
- Change measurement methods
- Add custom metrics
- Adjust timeout values
- Modify plugin detection logic

### Adjusting Thresholds

In PowerShell/zsh scripts:
- `TIMEOUT`: Maximum time per run (default: 5s)
- `RUNS`: Default number of iterations
- Slow plugin threshold: Currently hardcoded to 10ms

## 🐛 Troubleshooting

### Problem: Runs Fail with "TIMEOUT"

**Causes:**
- Plugins waiting for network/input
- Infinite loops in configuration
- Very slow plugins

**Solutions:**

1. **Increase Timeout**:
   ```vim
   " In benchmark_nvim.ps1 or .sh
   TIMEOUT=10  # Increase to 10 seconds
   ```

2. **Run Debug Mode**:
   ```vim
   :BenchmarkRunDebug 3
   ```

3. **Check Startup Time Manually**:
   ```bash
   nvim --startuptime startup.log +quit
   less startup.log
   ```

### Problem: HTML Shows All Zeros

**Cause**: CSV parsing issue with decimal separators (comma vs. dot)

**Fixed in**: Latest version handles both formats automatically

**Verification**:
```vim
:BenchmarkTest
" Check if CSV files exist and are readable
```

### Problem: Scripts Not Found

**Cause**: Incorrect path or module not loaded

**Solution**:
```lua
-- In init.lua
require('debugging.performance').setup()
```

Then verify:
```vim
:BenchmarkTest
```

### Problem: Permission Denied (Linux/macOS)

**Solution**:
```bash
chmod +x ~/.config/nvim/lua/debugging/performance/scripts/benchmark_nvim.sh
```

## 📚 Best Practices

### Recommended Workflow

1. **Establish Baseline**:
   ```vim
   :BenchmarkRun 20
   ```
   Save this as your reference point.

2. **Make Configuration Changes**:
   - Install new plugins
   - Modify settings
   - Change lazy-loading strategy

3. **Re-Benchmark**:
   ```vim
   :BenchmarkRun 20
   ```

4. **Compare Results**:
   ```vim
   :BenchmarkHtml
   ```
   Select the new benchmark to see % differences.

### Optimization Tips

- **Enable Lazy Loading**: Use Lazy.nvim's `lazy = true`
- **Event-Based Loading**: `event = "BufReadPost"` instead of eager loading
- **Audit Plugins**: Remove unused plugins
- **Profile Deeply**: Use `nvim --startuptime` for detailed analysis
- **Check Memory**: High memory usage might indicate leaks

## 🎯 Target Values

| Scenario | Target Startup | Target Memory |
|----------|----------------|---------------|
| Minimal Config | < 50ms | < 10MB |
| IDE Replacement | < 200ms | < 50MB |
| Full-Featured | < 500ms | < 100MB |

## 📦 Data Export

### CSV Format

```csv
"Run","Startup","UIEnter","Memory"
"1","652.75","1003.34","745.53"
"2","629.43","1003.62","257.90"
...
```

### JSON Metadata

```json
{
  "timestamp": "20260105_231325",
  "runs": 15,
  "startup": {
    "mean": 697.47,
    "median": 672.41,
    "min": 649.46,
    "max": 795.59,
    "stddev": 57.96
  },
  "uienter": { ... },
  "memory": { ... }
}
```

### Analysis with Python/Pandas

```python
import pandas as pd
import matplotlib.pyplot as plt

# Load data
df = pd.read_csv('nvim_benchmark_20260105_231325.csv')

# Visualize
df.plot(x='Run', y=['Startup', 'UIEnter'], kind='line')
plt.ylabel('Time (ms)')
plt.title('Neovim Startup Performance')
plt.show()
```

## 🤝 Contributing

Potential enhancements:
- [ ] Track plugin initialization order
- [ ] Memory leak detection
- [ ] CI/CD integration
- [ ] Comparison mode for A/B testing
- [ ] Historical trend graphs
- [ ] Export to other formats (JSON, SQLite)

## 🔗 See Also

- `:help performance` - This help file
- [Neovim Startup Time Guide](https://neovim.io/doc/user/starting.html#--startuptime)
- [Lazy.nvim Performance Tips](https://github.com/folke/lazy.nvim#-performance)
- [Profiling Neovim](https://neovim.io/doc/user/lua.html#lua-profile)

## 📄 License

Part of the Neovim configuration. See main repository for license.

---

**Quick Start**: `:BenchmarkRun` → Wait → `:BenchmarkHtml` → Enjoy! 🚀
