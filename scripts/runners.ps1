<#
.SYNOPSIS
  Status, start and stop of the self-hosted GitHub Actions runners of this machine.

.DESCRIPTION
  One runner per private repository lives in %USERPROFILE%\actions-runners\<repo> (made by
  tasks-vault/TOOLS/scripts/self-hosted-runner/setup-runner.ps1, see tasks-vault/TOOLS/self-hosted-runner.md).
  A runner only takes jobs while its process runs; this script is the one way to look at that and to start it,
  for a person, for `:MyPlugins ci runners` and for a Claude Code session that needs a CI run.

  Actions:
    status  one line per runner: <repo> <local: running|stopped> <github: online|offline|missing> [busy]
    start   start the runners that are not running (detached, hidden window); returns at once
    ensure  start, then wait until GitHub reports each one online (-WaitSeconds, default 90)
            start and ensure run the tool check first when a runner is about to be started and warn about
            MISSING/WARN lines (they never stop the start; -SkipCheck leaves the check out)
    stop    stop the runner processes (a running job is cancelled)
    check   are the tools the workflows rely on here (git, gh, nvim, cargo, jq, shellcheck, Inno Setup, ...)? One
            line per tool, exit 1 when one is missing; also finds a ~/.cargo/bin whose programs vanished
            (scripts/runner_tools_check.ps1; takes no repo names)

  Repos: names (tasks.nvim) or `all` (every folder below the runner root). Exit code 0 when every named
  runner is in the wanted state, 1 when not, 2 for wrong usage.

.EXAMPLE
  pwsh scripts/runners.ps1 status all
  pwsh scripts/runners.ps1 ensure tasks.nvim rules.nvim
#>
param(
  [Parameter(Mandatory, Position = 0)] [ValidateSet('status', 'start', 'ensure', 'stop', 'check')] [string] $Action,
  [Parameter(Position = 1, ValueFromRemainingArguments)] [string[]] $Repo = @('all'),
  [string] $Root = (Join-Path $env:USERPROFILE 'actions-runners'),
  [string] $Owner = 'WKDSteve',
  [int] $WaitSeconds = 90,
  [switch] $SkipCheck
)

$ErrorActionPreference = 'Stop'
if ($Action -eq 'check') {
  & (Join-Path $PSScriptRoot 'runner_tools_check.ps1') -Owner $Owner
  exit $LASTEXITCODE
}
if (-not (Test-Path $Root)) { Write-Output "no runners: $Root does not exist"; exit 2 }

$names = if ($Repo -contains 'all') { Get-ChildItem $Root -Directory | Select-Object -ExpandProperty Name } else { $Repo }
foreach ($n in $names) {
  if (-not (Test-Path (Join-Path $Root "$n\run.cmd"))) { Write-Output "unknown runner: $n (no $Root\$n\run.cmd)"; exit 2 }
}

function Get-Listener([string] $name) {
  $dir = (Join-Path $Root $name).ToLowerInvariant()
  Get-CimInstance Win32_Process -Filter "Name = 'Runner.Listener.exe'" |
    Where-Object { $_.ExecutablePath -and $_.ExecutablePath.ToLowerInvariant().StartsWith($dir) }
}

function Get-Remote([string] $name) {
  # missing = GitHub does not know a runner with this machine's name for the repo
  $json = gh api "repos/$Owner/$name/actions/runners" 2>$null
  if ($LASTEXITCODE -ne 0 -or -not $json) { return @{ status = 'unknown'; busy = $false } }
  $r = ($json | ConvertFrom-Json).runners | Where-Object { $_.name -like "*-$name" } | Select-Object -First 1
  if (-not $r) { return @{ status = 'missing'; busy = $false } }
  return @{ status = $r.status; busy = [bool] $r.busy }
}

function Show([string] $name) {
  $local = if (Get-Listener $name) { 'running' } else { 'stopped' }
  $remote = Get-Remote $name
  $line = '{0,-14} local={1,-8} github={2}' -f $name, $local, $remote.status
  if ($remote.busy) { $line += ' busy' }
  [Console]::WriteLine($line)
  return ($local -eq 'running' -and $remote.status -eq 'online')
}

switch ($Action) {
  'status' {
    $ok = $true
    foreach ($n in $names) { if (-not (Show $n)) { $ok = $false } }
    exit ([int] (-not $ok))
  }
  'stop' {
    foreach ($n in $names) {
      Get-Listener $n | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
      # run.cmd / Runner.Worker of this runner go with it; the wrapper cmd exits when the listener does
      Write-Output "$n stopped"
    }
  }
  { $_ -in 'start', 'ensure' } {
    # A runner keeps the PATH of the process that starts it, so this is the moment to look: a tool that is
    # missing now would turn a job red later (exit 127). Only a warning; the runners start in any case.
    # Skipped when every runner runs already (nothing is started) and with -SkipCheck.
    $toStart = @($names | Where-Object { -not (Get-Listener $_) })
    if ($toStart.Count -gt 0 -and -not $SkipCheck) {
      $report = @(& (Join-Path $PSScriptRoot 'runner_tools_check.ps1') -Owner $Owner 2>&1 | ForEach-Object { "$_" })
      $problems = @($report | Where-Object { $_ -match '^(MISSING|WARN)\s' })
      if ($problems.Count -gt 0) {
        Write-Output "warning: the tool check found $($problems.Count) problem(s); the runners start anyway (details: runners.ps1 check, -SkipCheck silences this)"
        $problems | ForEach-Object { Write-Output "  $_" }
      }
    }
    foreach ($n in $names) {
      if (Get-Listener $n) { continue }
      # The runner takes the PATH of this process: scoop shims (stylua, luacheck, gh), Git and nvim must be on it.
      Start-Process -FilePath (Join-Path $Root "$n\run.cmd") -WorkingDirectory (Join-Path $Root $n) -WindowStyle Hidden
      Write-Output "$n started"
    }
    if ($Action -eq 'ensure') {
      $deadline = (Get-Date).AddSeconds($WaitSeconds)
      $pending = @($names)
      while ($pending.Count -gt 0 -and (Get-Date) -lt $deadline) {
        $pending = @($pending | Where-Object { (Get-Remote $_).status -ne 'online' })
        if ($pending.Count -gt 0) { Start-Sleep -Seconds 3 }
      }
      $ok = $true
      foreach ($n in $names) { if (-not (Show $n)) { $ok = $false } }
      exit ([int] (-not $ok))
    }
  }
}
