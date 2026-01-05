<#
.SYNOPSIS
  Automated Neovim startup benchmarking with warmup run
.DESCRIPTION
  Runs Neovim in headless mode N times (+ 1 warmup), extracts startup times,
  calculates statistics (mean, median, min, max, stddev)
.PARAMETER Runs
  Number of benchmark iterations (default: 15, excludes warmup)
.PARAMETER SkipWarmup
  Skip the initial warmup run (not recommended)
.EXAMPLE
  .\benchmark_nvim.ps1 -Runs 20
  .\benchmark_nvim.ps1 -Runs 10 -SkipWarmup
#>
param(
    [int]$Runs = 15,
    [switch]$SkipWarmup
)

# Configuration
$NvimExe = "nvim"
$LuaScript = "$env:USERPROFILE\AppData\Local\nvim\lua\debugging\performance\scripts\benchmark_startup.lua"

# Check if Lua script exists
if (-not (Test-Path $LuaScript)) {
    Write-Error "Benchmark script not found: $LuaScript"
    exit 1
}

# Check if nvim is available
try {
    & $NvimExe --version | Out-Null
} catch {
    Write-Error "Neovim not found in PATH"
    exit 1
}

# Storage for measurements
$StartupTimes = @()
$UIEnterTimes = @()

# Warmup run (unless skipped)
if (-not $SkipWarmup) {
    Write-Host "Running warmup..." -ForegroundColor Cyan

    $StartupFile = "$env:TEMP\nvim_startuptime_warmup.txt"
    $env:NVIM_STARTUPTIME_FILE = $StartupFile

    $null = & $NvimExe --headless --startuptime $StartupFile `
                       -c "luafile $LuaScript" 2>&1

    Start-Sleep -Milliseconds 1500
    Write-Host "Warmup complete`n" -ForegroundColor Green
}

Write-Host "Starting $Runs benchmark runs..." -ForegroundColor Cyan
Write-Host ""

# Run benchmarks
for ($i = 1; $i -le $Runs; $i++) {
    Write-Host "Run $i/$Runs... " -NoNewline

    # Create temp file for startuptime
    $StartupFile = "$env:TEMP\nvim_startuptime_$i.txt"
    $env:NVIM_STARTUPTIME_FILE = $StartupFile

    # Run Neovim - FIXED: Use $LuaScript instead of undefined $LuaScriptLazy
    $Output = & $NvimExe --headless --startuptime $StartupFile `
                         -c "luafile $LuaScript" 2>&1 |
              Where-Object { $_ -match '^\d+\.\d+,\d+\.\d+$' }

    if ($Output -match '^([\d.]+),([\d.]+)$') {
        $Startup = [double]$Matches[1]
        $UIEnter = [double]$Matches[2]

        $StartupTimes += $Startup
        $UIEnterTimes += $UIEnter

        Write-Host "Startup: $($Startup)ms, UI Enter: $($UIEnter)ms" -ForegroundColor Green
    } else {
        Write-Host "FAILED (no valid output)" -ForegroundColor Red
    }

    # Small delay between runs
    Start-Sleep -Milliseconds 300
}

Write-Host ""
Write-Host "=== Results ===" -ForegroundColor Cyan

# Calculate statistics
function Get-Stats($Data) {
    if ($Data.Count -eq 0) {
        return [PSCustomObject]@{
            Mean = 0; Median = 0; Min = 0; Max = 0; StdDev = 0
        }
    }

    $Sorted = $Data | Sort-Object
    $Count = $Sorted.Count
    $Sum = ($Sorted | Measure-Object -Sum).Sum
    $Mean = $Sum / $Count

    $Median = if ($Count % 2 -eq 1) {
        $Sorted[[math]::Floor($Count / 2)]
    } else {
        ($Sorted[$Count / 2 - 1] + $Sorted[$Count / 2]) / 2
    }

    $Min = $Sorted[0]
    $Max = $Sorted[-1]

    $Variance = ($Sorted | ForEach-Object {
        [math]::Pow($_ - $Mean, 2)
    } | Measure-Object -Sum).Sum / $Count

    $StdDev = [math]::Sqrt($Variance)

    [PSCustomObject]@{
        Mean   = [math]::Round($Mean, 2)
        Median = [math]::Round($Median, 2)
        Min    = [math]::Round($Min, 2)
        Max    = [math]::Round($Max, 2)
        StdDev = [math]::Round($StdDev, 2)
    }
}

$StartupStats = Get-Stats $StartupTimes
$UIEnterStats = Get-Stats $UIEnterTimes

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
Write-Host "=== Raw Data ===" -ForegroundColor Cyan
for ($i = 0; $i -lt $StartupTimes.Count; $i++) {
    Write-Host "Run $($i+1): Startup=$($StartupTimes[$i])ms, UIEnter=$($UIEnterTimes[$i])ms"
}

# Export CSV
$CsvPath = "./Resultate/csv/nvim_benchmark_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
$CsvData = for ($i = 0; $i -lt $StartupTimes.Count; $i++) {
    [PSCustomObject]@{
        Run     = $i + 1
        Startup = $StartupTimes[$i]
        UIEnter = $UIEnterTimes[$i]
    }
}
$CsvData | Export-Csv -Path $CsvPath -NoTypeInformation
Write-Host "`nCSV exported: $CsvPath" -ForegroundColor Cyan

# Cleanup temp files
Remove-Item "$env:TEMP\nvim_startuptime_*.txt" -ErrorAction SilentlyContinue
