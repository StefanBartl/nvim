<#
.SYNOPSIS
  Checks that the tools the self-hosted runners rely on are on this machine, before a job turns red with exit 127.

.DESCRIPTION
  The workflows of the private repos expect their tools on the PATH of the runner process (tasks-vault/TOOLS/
  self-hosted-runner.md, section Prerequisites). A tool that is missing shows up as `command not found` in the
  middle of a job; this script looks first. It also finds the failure of 2026-10-27, where rustup.exe and the
  programs of `cargo install` vanished from ~/.cargo/bin and only the links to rustup.exe stayed: every program
  that ~/.cargo/.crates2.json says is installed must be a real file, and every link must resolve.

  The check sees the PATH of THIS process. A runner keeps the PATH it was started with; after installing a
  tool, stop and start the runners (runners.ps1 stop all, runners.ps1 ensure all).

  One line per tool: ok / MISSING / WARN. Exit code 0 when nothing is MISSING (WARN does not fail), 1 otherwise.

.EXAMPLE
  pwsh scripts/runners.ps1 check
  pwsh scripts/runner_tools_check.ps1 -CargoHome C:\Temp\fake-cargo   # try the cargo check on a copy
#>
param(
  [string] $CargoHome = (Join-Path $env:USERPROFILE '.cargo'),
  [string] $Owner = 'WKDSteve'
)

$ErrorActionPreference = 'Continue'
$script:missing = 0
$script:warned = 0

function Write-Result([string] $state, [string] $name, [string] $detail) {
  if ($state -eq 'MISSING') { $script:missing++ }
  if ($state -eq 'WARN') { $script:warned++ }
  Write-Output (('{0,-8} {1,-16} {2}' -f $state, $name, $detail))
}

function Get-FirstLine([scriptblock] $run) {
  # The first non-empty line. Not the exit code: after Select-Object -First 1 closes the pipe it is not reliable.
  try { $out = & $run 2>&1 | Where-Object { "$_".Trim() } | Select-Object -First 1; return ("$out").Trim() } catch { return $null }
}

# name, command, arguments of the version call, who needs it, how to install it
$tools = @(
  @('git', 'git', @('--version'), 'every workflow', 'Git for Windows (C:\Program Files\Git)'),
  @('gh', 'gh', @('--version'), 'private reads, release-kit, ci_status', 'scoop install gh'),
  @('nvim', 'nvim', @('--version'), 'plugin specs, tasks/rules engines', 'scoop install neovim (0.10 or newer)'),
  @('stylua', 'stylua', @('--version'), 'format gates', 'scoop install stylua'),
  @('luacheck', 'luacheck', @('--version'), 'lint gates', 'luarocks install luacheck (or scoop)'),
  @('python', 'python', @('--version'), 'tools/*.py of every repo', 'python.org (not python3: that is the Store stub)'),
  @('node', 'node', @('--version'), 'ui tests, npx', 'scoop install nodejs'),
  @('npx', 'npx', @('--version'), 'docmap-desktop build (Tauri CLI)', 'comes with node'),
  @('pnpm', 'pnpm', @('--version'), 'tasks-desktop, rules-desktop, appkit ui', 'npm install -g pnpm'),
  @('cargo', 'cargo', @('--version'), 'all Rust repos', 'winget install Rustlang.Rustup'),
  @('rustc', 'rustc', @('--version'), 'all Rust repos', 'winget install Rustlang.Rustup'),
  @('rustfmt', 'cargo', @('fmt', '--version'), 'cargo fmt --check', 'rustup component add rustfmt'),
  @('clippy', 'cargo', @('clippy', '--version'), 'cargo clippy -D warnings', 'rustup component add clippy'),
  @('cargo-audit', 'cargo', @('audit', '--version'), 'supply-chain job', 'cargo install --locked cargo-audit'),
  @('cargo-deny', 'cargo', @('deny', '--version'), 'supply-chain job', 'cargo install --locked cargo-deny'),
  @('jq', 'jq', @('--version'), 'docmap-desktop, release workflows', 'scoop install jq'),
  @('shellcheck', 'shellcheck', @('--version'), 'hygiene jobs (shell scripts)', 'scoop install shellcheck'),
  @('7z', '7z', @('-h'), 'release packaging (zip)', 'scoop install 7zip'),
  @('cmake', 'cmake', @('--version'), 'ai-desktop', 'winget install Kitware.CMake'),
  @('ctest', 'ctest', @('--version'), 'ai-desktop', 'comes with cmake'),
  @('pwsh', 'pwsh', @('-NoProfile', '-Command', '$PSVersionTable.PSVersion.ToString()'), 'steps with shell: pwsh', 'winget install Microsoft.PowerShell')
)

foreach ($t in $tools) {
  $name, $cmd, $args1, $needed, $hint = $t
  if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
    Write-Result -State 'MISSING' -Name $name -Detail "not on PATH - $needed - $hint"
    continue
  }
  $version = Get-FirstLine { & $cmd @args1 }
  # `cargo audit --version` etc. print an error line when the subcommand is not installed
  if (-not $version -or $version -match 'no such command|is not installed|error:|is not recognized') {
    Write-Result -State 'MISSING' -Name $name -Detail "does not run (${version}) - $needed - $hint"
  } else {
    Write-Result -State 'ok' -Name $name -Detail $version
  }
}

# Git Bash by the full 8.3 path the workflows name: `shell: bash` is the WSL launcher on this machine.
$bash = 'C:\PROGRA~1\Git\bin\bash.exe'
if (Test-Path $bash) { Write-Result -State 'ok' -Name 'git-bash' -Detail "$bash (8.3 name works)" }
else { Write-Result -State 'MISSING' -Name 'git-bash' -Detail "$bash not found - the workflows name this path; Git must be in C:\Program Files and 8.3 names enabled (dir /x C:\)" }

# python3 resolves to the Microsoft Store stub on this machine; the workflows say `python`.
$py = Get-Command python -ErrorAction SilentlyContinue
if ($py -and $py.Source -like '*\WindowsApps\*') { Write-Result -State 'WARN' -Name 'python' -Detail "resolves to the Store stub ($($py.Source))" }

# gh: logged in, and able to read a private repo (the runners clone private sources with this login)
if (Get-Command gh -ErrorAction SilentlyContinue) {
  $null = & gh api "repos/$Owner/appkit" --jq .name 2>&1
  if ($LASTEXITCODE -eq 0) { Write-Result -State 'ok' -Name 'gh-login' -Detail "can read $Owner/appkit (private)" }
  else { Write-Result -State 'MISSING' -Name 'gh-login' -Detail "cannot read $Owner/appkit - gh auth login / gh auth setup-git" }
}

# Inno Setup (ai-desktop installer)
$iscc = @(
  (Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6\ISCC.exe'),
  (Join-Path $env:ProgramFiles 'Inno Setup 6\ISCC.exe'),
  (Join-Path $env:LOCALAPPDATA 'Programs\Inno Setup 6\ISCC.exe')
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if ($iscc) { Write-Result -State 'ok' -Name 'inno-setup' -Detail $iscc }
else { Write-Result -State 'MISSING' -Name 'inno-setup' -Detail 'ISCC.exe not found - ai-desktop installer - winget install JRSoftware.InnoSetup --scope user' }

# Chrome for the Playwright browser tests of tasks-desktop and rules-desktop
$chrome = @(
  (Join-Path $env:ProgramFiles 'Google\Chrome\Application\chrome.exe'),
  (Join-Path ${env:ProgramFiles(x86)} 'Google\Chrome\Application\chrome.exe'),
  (Join-Path $env:LOCALAPPDATA 'Google\Chrome\Application\chrome.exe')
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if ($chrome) { Write-Result -State 'ok' -Name 'chrome' -Detail $chrome }
else { Write-Result -State 'WARN' -Name 'chrome' -Detail 'not found - browser tests of tasks-desktop and rules-desktop (pnpm e2e) need the system Chrome' }

# Windows PowerShell 5.1 (the release-kit install script is tried under it)
if (Test-Path "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe") { Write-Result -State 'ok' -Name 'powershell-5.1' -Detail 'present' }
else { Write-Result -State 'MISSING' -Name 'powershell-5.1' -Detail 'powershell.exe not found' }

# The cargo folder: a link must resolve, and every program `cargo install` recorded must be a real file.
$bin = Join-Path $CargoHome 'bin'
if (-not (Test-Path $bin)) {
  Write-Result -State 'MISSING' -Name 'cargo-bin' -Detail "$bin does not exist"
} else {
  # Test-Path and File.Exists both answer true for a link whose target is gone (they look at the link itself),
  # so the target is looked at: a relative one is relative to the folder of the link.
  $dangling = @(Get-ChildItem $bin -Force | Where-Object {
      if (-not $_.LinkType) { return $false }
      $target = @($_.Target)[0]
      if (-not [System.IO.Path]::IsPathRooted($target)) { $target = Join-Path $bin $target }
      -not (Test-Path -LiteralPath $target -PathType Leaf)
    } | ForEach-Object { $_.Name })
  if (-not (Test-Path (Join-Path $bin 'rustup.exe'))) {
    Write-Result -State 'MISSING' -Name 'rustup.exe' -Detail "not in $bin - the links (cargo.exe, rustc.exe, ...) point at it; $($dangling.Count) of them dangle"
  } elseif ($dangling.Count -gt 0) {
    Write-Result -State 'MISSING' -Name 'cargo-links' -Detail "dangling: $($dangling -join ', ')"
  } else {
    Write-Result -State 'ok' -Name 'cargo-links' -Detail 'rustup.exe is there and every link resolves'
  }
  $crates2 = Join-Path $CargoHome '.crates2.json'
  if (Test-Path $crates2) {
    $installs = (Get-Content -Raw $crates2 | ConvertFrom-Json).installs
    $gone = New-Object System.Collections.Generic.List[string]
    foreach ($prop in $installs.PSObject.Properties) {
      foreach ($b in $prop.Value.bins) {
        if (-not (Test-Path -LiteralPath (Join-Path $bin $b) -PathType Leaf)) { $gone.Add("$b (" + ($prop.Name -split ' ')[0] + ')') }
      }
    }
    if ($gone.Count -gt 0) { Write-Result -State 'MISSING' -Name 'cargo-install' -Detail "recorded in .crates2.json but not in bin: $($gone -join ', ') - cargo install --locked <crate>@<version>" }
    else { Write-Result -State 'ok' -Name 'cargo-install' -Detail "$(@($installs.PSObject.Properties).Count) recorded programs are all files in bin" }
  }
}

Write-Output ('')
Write-Output ("missing: $script:missing, warnings: $script:warned (this process's PATH; a running runner keeps the PATH it was started with)")
exit ([int] ($script:missing -gt 0))
