<#
.SYNOPSIS
  Automated Neovim startup benchmarking with statistics
.DESCRIPTION
  Runs Neovim in headless mode multiple times, parses structured Lua output,
  aggregates startup, UI enter, memory and plugin timing metrics,
  and exports CSV + JSON metadata.
#>

param(
    [int]$Runs = 15,
    [switch]$SkipWarmup,
    [switch]$Debug
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

$NvimExe   = "nvim"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LuaScript = Join-Path $ScriptDir "benchmark_startup.lua"

# Use paths from environment (set by init.lua) or fallback to defaults
$ResultsDir = if ($env:NVIM_BENCHMARK_RESULTS_DIR) {
    $env:NVIM_BENCHMARK_RESULTS_DIR
} else {
    Join-Path $env:LOCALAPPDATA "nvim\lua\debugging\performance\results"
}

$CsvDir = if ($env:NVIM_BENCHMARK_CSV_DIR) {
    $env:NVIM_BENCHMARK_CSV_DIR
} else {
    Join-Path $ResultsDir "csv"
}

$HtmlDir = if ($env:NVIM_BENCHMARK_HTML_DIR) {
    $env:NVIM_BENCHMARK_HTML_DIR
} else {
    Join-Path $ResultsDir "html"
}

# Create directories if they don't exist
@($ResultsDir, $CsvDir, $HtmlDir) | ForEach-Object {
    if (-not (Test-Path $_)) {
        Write-Host "Creating directory: $_" -ForegroundColor Cyan
        New-Item -ItemType Directory -Path $_ -Force | Out-Null
    }
}

Write-Host "Using paths:" -ForegroundColor Cyan
Write-Host "  Results: $ResultsDir" -ForegroundColor Gray
Write-Host "  CSV:     $CsvDir" -ForegroundColor Gray
Write-Host "  HTML:    $HtmlDir" -ForegroundColor Gray
Write-Host ""

if (-not (Test-Path $LuaScript)) {
    throw "Lua benchmark script not found: $LuaScript"
}

& $NvimExe --version | Out-Null

# ------------------------------------------------------------
# Storage
# ------------------------------------------------------------

$StartupTimes   = @()
$UIEnterTimes   = @()
$MemoryUsages   = @()
$PluginCounts   = @()
$AllSlowPlugins = @()

# ------------------------------------------------------------
# Warmup
# ------------------------------------------------------------

if (-not $SkipWarmup) {
    Write-Host "Running warmup..." -ForegroundColor Cyan

    $WarmupFile = Join-Path $env:TEMP "nvim_startuptime_warmup.txt"
    $env:NVIM_STARTUPTIME_FILE = $WarmupFile

    & $NvimExe --headless --startuptime $WarmupFile `
        -c "luafile $LuaScript" 2>&1 | Out-Null

    Start-Sleep -Milliseconds 800
    Write-Host "Warmup complete" -ForegroundColor Green
    Write-Host ""
}

# ------------------------------------------------------------
# Benchmark runs
# ------------------------------------------------------------

Write-Host "Starting $Runs benchmark runs..." -ForegroundColor Cyan
Write-Host ""

for ($i = 1; $i -le $Runs; $i++) {

    Write-Host "Run $i/$Runs... " -NoNewline

    $StartupFile = Join-Path $env:TEMP "nvim_startuptime_$i.txt"
    $env:NVIM_STARTUPTIME_FILE = $StartupFile

    $ErrorActionPreference = "Continue"
    $Output = & $NvimExe --headless --startuptime $StartupFile `
        -c "luafile $LuaScript" 2>&1 | ForEach-Object { "$_" }
    $ErrorActionPreference = "Stop"

    if ($Debug) {
        Write-Host ""
        $Output | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
        Write-Host ""
    }

    # Expected Lua line:
    # startup,ui_enter,memory,plugin_count,[{name,time},...]

    $TimingLine = $Output | Where-Object {
        $_ -match '^[\d.]+,[\d.]+,[\d.]+,\d+,.*$'
    } | Select-Object -First 1

    if (-not $TimingLine) {
        Write-Host "FAILED (no valid output)" -ForegroundColor Red
        if (-not $Debug) {
            Write-Host "  Tip: Run with -Debug to see output" -ForegroundColor Yellow
        }
        continue
    }

    if ($TimingLine -match '^([\d.]+),([\d.]+),([\d.]+),(\d+),(.*)$') {

        $Startup     = [double]$Matches[1]
        $UIEnter     = [double]$Matches[2]
        $Memory      = [double]$Matches[3]
        $PluginCount = [int]$Matches[4]
        $SlowJson    = $Matches[5]

        $StartupTimes += $Startup
        $UIEnterTimes += $UIEnter
        $MemoryUsages += $Memory
        $PluginCounts += $PluginCount

        try {
            $AllSlowPlugins += ($SlowJson | ConvertFrom-Json)
        } catch {}

        Write-Host (
            "Startup={0:F2}ms UI={1:F2}ms Memory={2:F2}KB Plugins={3}" -f
            $Startup,
            $UIEnter,
            $Memory,
            $PluginCount
        ) -ForegroundColor Green
    }

    Start-Sleep -Milliseconds 300
}

Write-Host ""

if ($StartupTimes.Count -eq 0) {
    throw "No successful benchmark runs"
}

# ------------------------------------------------------------
# Statistics
# ------------------------------------------------------------

function Get-Stats {
    param([double[]]$Data)

    if ($Data.Count -eq 0) {
        return @{
            Mean = 0; Median = 0; Min = 0; Max = 0; StdDev = 0
        }
    }

    $Sorted = $Data | Sort-Object
    $Count  = $Sorted.Count
    $Mean   = ($Sorted | Measure-Object -Average).Average
    $Min    = $Sorted[0]
    $Max    = $Sorted[-1]

    $Median = if ($Count % 2) {
        $Sorted[[math]::Floor($Count / 2)]
    } else {
        ($Sorted[$Count/2 - 1] + $Sorted[$Count/2]) / 2
    }

    $Variance = ($Sorted | ForEach-Object {
        [math]::Pow($_ - $Mean, 2)
    } | Measure-Object -Sum).Sum / $Count

    [PSCustomObject]@{
        Mean   = [math]::Round($Mean, 2)
        Median = [math]::Round($Median, 2)
        Min    = [math]::Round($Min, 2)
        Max    = [math]::Round($Max, 2)
        StdDev = [math]::Round([math]::Sqrt($Variance), 2)
    }
}

$StartupStats = Get-Stats $StartupTimes
$UIEnterStats = Get-Stats $UIEnterTimes
$MemoryStats  = Get-Stats $MemoryUsages

# ------------------------------------------------------------
# Output
# ------------------------------------------------------------

Write-Host "=== Results ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "Startup Time (ms):" -ForegroundColor Yellow
Write-Host "  Mean:   $($StartupStats.Mean)"
Write-Host "  Median: $($StartupStats.Median)"
Write-Host "  Min:    $($StartupStats.Min)"
Write-Host "  Max:    $($StartupStats.Max)"
Write-Host "  StdDev: $($StartupStats.StdDev)"

Write-Host ""
Write-Host "UI Enter Time (ms):" -ForegroundColor Yellow
Write-Host "  Mean:   $($UIEnterStats.Mean)"
Write-Host "  Median: $($UIEnterStats.Median)"
Write-Host "  Min:    $($UIEnterStats.Min)"
Write-Host "  Max:    $($UIEnterStats.Max)"
Write-Host "  StdDev: $($UIEnterStats.StdDev)"

Write-Host ""
Write-Host "Memory Usage (KB):" -ForegroundColor Yellow
Write-Host "  Mean:   $($MemoryStats.Mean)"
Write-Host "  Median: $($MemoryStats.Median)"
Write-Host "  Min:    $($MemoryStats.Min)"
Write-Host "  Max:    $($MemoryStats.Max)"
Write-Host "  StdDev: $($MemoryStats.StdDev)"

Write-Host ""
Write-Host "=== Raw Data ===" -ForegroundColor Cyan
for ($i = 0; $i -lt $StartupTimes.Count; $i++) {
    Write-Host ("Run {0}: Startup={1:F2}ms, UIEnter={2:F2}ms, Memory={3:F2}KB" -f
        ($i + 1),
        $StartupTimes[$i],
        $UIEnterTimes[$i],
        $MemoryUsages[$i]
    )
}

# ------------------------------------------------------------
# Export
# ------------------------------------------------------------

Write-Host ""

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

$CsvPath = Join-Path $CsvDir "nvim_benchmark_$Timestamp.csv"

Write-Host "Exporting to CSV: $CsvPath" -ForegroundColor Cyan

# Export CSV with proper formatting (use dot as decimal separator)
$CsvContent = @()
$CsvContent += '"Run","Startup","UIEnter","Memory"'

for ($i = 0; $i -lt $StartupTimes.Count; $i++) {
    $CsvContent += ('"{0}","{1}","{2}","{3}"' -f
        ($i + 1),
        ($StartupTimes[$i].ToString("F2", [System.Globalization.CultureInfo]::InvariantCulture)),
        ($UIEnterTimes[$i].ToString("F2", [System.Globalization.CultureInfo]::InvariantCulture)),
        ($MemoryUsages[$i].ToString("F2", [System.Globalization.CultureInfo]::InvariantCulture))
    )
}

$CsvContent | Out-File -FilePath $CsvPath -Encoding utf8

Write-Host "CSV exported successfully" -ForegroundColor Green

# Export JSON metadata
$MetaPath = Join-Path $CsvDir "nvim_benchmark_${Timestamp}_meta.json"

Write-Host "Exporting metadata: $MetaPath" -ForegroundColor Cyan

@{
    timestamp = $Timestamp
    runs      = $Runs
    startup   = @{
        mean   = $StartupStats.Mean
        median = $StartupStats.Median
        min    = $StartupStats.Min
        max    = $StartupStats.Max
        stddev = $StartupStats.StdDev
    }
    uienter   = @{
        mean   = $UIEnterStats.Mean
        median = $UIEnterStats.Median
        min    = $UIEnterStats.Min
        max    = $UIEnterStats.Max
        stddev = $UIEnterStats.StdDev
    }
    memory    = @{
        mean   = $MemoryStats.Mean
        median = $MemoryStats.Median
        min    = $MemoryStats.Min
        max    = $MemoryStats.Max
        stddev = $MemoryStats.StdDev
    }
} | ConvertTo-Json -Depth 5 | Out-File $MetaPath -Encoding utf8

Write-Host "Metadata exported successfully" -ForegroundColor Green

Write-Host ""
Write-Host "Results saved to:" -ForegroundColor Cyan
Write-Host "  CSV:  $CsvPath" -ForegroundColor Gray
Write-Host "  Meta: $MetaPath" -ForegroundColor Gray

# ------------------------------------------------------------
# Cleanup
# ------------------------------------------------------------

Remove-Item "$env:TEMP\nvim_startuptime_*.txt" -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "Benchmark complete! Use :BenchmarkHtml to generate report." -ForegroundColor Green
