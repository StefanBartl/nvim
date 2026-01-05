<#
.SYNOPSIS
  Manual test script to diagnose benchmark issues
#>

$ErrorActionPreference = "Continue"

Write-Host "=== Benchmark Diagnostic Test ===" -ForegroundColor Cyan
Write-Host ""

# 1. Check Neovim
Write-Host "1. Checking Neovim..." -ForegroundColor Yellow
try {
    $nvimVersion = & nvim --version 2>&1 | Select-Object -First 1
    Write-Host "   ✅ Neovim found: $nvimVersion" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Neovim not found in PATH" -ForegroundColor Red
    exit 1
}

# 2. Check Scripts
Write-Host ""
Write-Host "2. Checking scripts..." -ForegroundColor Yellow
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LuaScript = Join-Path $ScriptDir "benchmark_startup.lua"
$BenchmarkScript = Join-Path $ScriptDir "benchmark_nvim.ps1"

if (Test-Path $LuaScript) {
    Write-Host "   ✅ Lua script found: $LuaScript" -ForegroundColor Green
} else {
    Write-Host "   ❌ Lua script not found: $LuaScript" -ForegroundColor Red
    exit 1
}

if (Test-Path $BenchmarkScript) {
    Write-Host "   ✅ Benchmark script found: $BenchmarkScript" -ForegroundColor Green
} else {
    Write-Host "   ❌ Benchmark script not found: $BenchmarkScript" -ForegroundColor Red
}

# 3. Check Directories
Write-Host ""
Write-Host "3. Checking directories..." -ForegroundColor Yellow
$ResultsDir = Join-Path $ScriptDir "Resultate"
$CsvDir = Join-Path $ResultsDir "csv"

if (Test-Path $ResultsDir) {
    Write-Host "   ✅ Results directory exists" -ForegroundColor Green
} else {
    Write-Host "   ℹ️  Creating Results directory..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $ResultsDir -Force | Out-Null
}

if (Test-Path $CsvDir) {
    Write-Host "   ✅ CSV directory exists" -ForegroundColor Green
} else {
    Write-Host "   ℹ️  Creating CSV directory..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $CsvDir -Force | Out-Null
}

# 4. Test Neovim with Lua script (single run)
Write-Host ""
Write-Host "4. Testing Neovim with benchmark script..." -ForegroundColor Yellow
$TestFile = Join-Path $env:TEMP "nvim_test_startup.txt"
$env:NVIM_STARTUPTIME_FILE = $TestFile

Write-Host "   Running: nvim --headless --startuptime $TestFile -c 'luafile $LuaScript'" -ForegroundColor DarkGray

try {
    $Output = & nvim --headless --startuptime $TestFile -c "luafile $LuaScript" 2>&1

    Write-Host ""
    Write-Host "   Output received:" -ForegroundColor Cyan
    $Output | ForEach-Object { Write-Host "     $_" }

    # Check for timing line
    $TimingLine = $Output | Where-Object { $_ -match '^\d+\.\d+,\d+\.\d+,\d+\.\d+,\d+,.*$' } | Select-Object -First 1

    if ($TimingLine) {
        Write-Host ""
        Write-Host "   ✅ Valid timing data received!" -ForegroundColor Green
        Write-Host "   Data: $TimingLine" -ForegroundColor Cyan
    } else {
        Write-Host ""
        Write-Host "   ❌ No valid timing data found" -ForegroundColor Red
        Write-Host "   Expected format: startup_ms,ui_enter_ms,memory_kb,plugin_count,slow_plugins_json" -ForegroundColor Yellow
    }

} catch {
    Write-Host "   ❌ Error running Neovim: $_" -ForegroundColor Red
}

# 5. Check startuptime file
Write-Host ""
Write-Host "5. Checking startuptime file..." -ForegroundColor Yellow
if (Test-Path $TestFile) {
    $FileSize = (Get-Item $TestFile).Length
    Write-Host "   ✅ Startuptime file created ($FileSize bytes)" -ForegroundColor Green

    $FirstLine = Get-Content $TestFile -First 1
    Write-Host "   First line: $FirstLine" -ForegroundColor DarkGray
} else {
    Write-Host "   ❌ Startuptime file not created" -ForegroundColor Red
}

# 6. Test full benchmark (1 run)
Write-Host ""
Write-Host "6. Testing full benchmark (1 run, no warmup)..." -ForegroundColor Yellow
Write-Host "   Running: benchmark_nvim.ps1 -Runs 1 -SkipWarmup" -ForegroundColor DarkGray
Write-Host ""

if (Test-Path $BenchmarkScript) {
    & $BenchmarkScript -Runs 1 -SkipWarmup
} else {
    Write-Host "   ⚠️  Benchmark script not found, skipping" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== Test Complete ===" -ForegroundColor Cyan
