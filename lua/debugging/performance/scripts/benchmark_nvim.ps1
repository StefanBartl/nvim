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

$ResultsDir = Join-Path $ScriptDir "Resultate"
$CsvDir     = Join-Path $ResultsDir "csv"

@($ResultsDir, $CsvDir) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -ItemType Directory -Path $_ | Out-Null
    }
}

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
    Write-Host "Warmup run..."

    $WarmupFile = Join-Path $env:TEMP "nvim_startuptime_warmup.txt"
    $env:NVIM_STARTUPTIME_FILE = $WarmupFile

    & $NvimExe --headless --startuptime $WarmupFile `
        -c "luafile $LuaScript" | Out-Null

    Start-Sleep -Milliseconds 800
}

# ------------------------------------------------------------
# Benchmark runs
# ------------------------------------------------------------

for ($i = 1; $i -le $Runs; $i++) {

    Write-Host "Run $i/$Runs..."

    $StartupFile = Join-Path $env:TEMP "nvim_startuptime_$i.txt"
    $env:NVIM_STARTUPTIME_FILE = $StartupFile

    $ErrorActionPreference = "Continue"
    $Output = & $NvimExe --headless --startuptime $StartupFile `
        -c "luafile $LuaScript" 2>&1 | ForEach-Object { "$_" }

    if ($Debug) {
        $Output | ForEach-Object { Write-Host $_ }
    }

    # Expected Lua line:
    # startup,ui_enter,memory,plugin_count,[{name,time},...]

    $TimingLine = $Output | Where-Object {
        $_ -match '^[\d.]+,[\d.]+,[\d.]+,\d+,.*$'
    } | Select-Object -First 1

    if (-not $TimingLine) {
        Write-Host "FAILED" -ForegroundColor Red
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
            "Startup={0}ms UI={1}ms Memory={2}KB Plugins={3}" -f
            $Startup,
            $UIEnter,
            ([math]::Round($Memory, 2)),
            $PluginCount
        ) -ForegroundColor Green
    }

    Start-Sleep -Milliseconds 200
}

if ($StartupTimes.Count -eq 0) {
    throw "No successful benchmark runs"
}

# ------------------------------------------------------------
# Statistics
# ------------------------------------------------------------

function Get-Stats {
    param([double[]]$Data)

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

# ------------------------------------------------------------
# Output
# ------------------------------------------------------------

Write-Host ""
Write-Host "Startup (ms): $($StartupStats | ConvertTo-Json -Compress)"
Write-Host "UI Enter (ms): $($UIEnterStats | ConvertTo-Json -Compress)"

# ------------------------------------------------------------
# Export
# ------------------------------------------------------------

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

$CsvPath = Join-Path $CsvDir "nvim_benchmark_$Timestamp.csv"
(0..($StartupTimes.Count - 1)) | ForEach-Object {
    [PSCustomObject]@{
        Run     = $_ + 1
        Startup = $StartupTimes[$_]
        UIEnter = $UIEnterTimes[$_]
        Memory  = [math]::Round($MemoryUsages[$_], 2)
    }
} | Export-Csv -Path $CsvPath -NoTypeInformation

$MetaPath = Join-Path $CsvDir "nvim_benchmark_${Timestamp}_meta.json"
@{
    timestamp = $Timestamp
    runs      = $Runs
    startup   = $StartupStats
    uienter   = $UIEnterStats
} | ConvertTo-Json -Depth 5 | Out-File $MetaPath -Encoding utf8

Write-Host "CSV:  $CsvPath"
Write-Host "Meta: $MetaPath"

# ------------------------------------------------------------
# Cleanup
# ------------------------------------------------------------

Remove-Item "$env:TEMP\nvim_startuptime_*.txt" -ErrorAction SilentlyContinue
