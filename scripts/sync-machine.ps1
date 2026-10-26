<#
.SYNOPSIS
  Checks (and optionally updates) every repo under $REPOS_DIR so that a
  machine switch never starts on a stale checkout or a stale native build.

.DESCRIPTION
  Per repo: fetch, branch, dirty state, ahead/behind versus origin, and for
  repos with a native build the age of the artifact versus the newest commit
  touching its sources. Read-only by default.

  -Pull   fast-forwards clean repos that sit on their default branch
          (git pull --ff-only). Never touches dirty or diverged repos.
  -Json   print one JSON array (repo, path, state, behind, ahead, dirty,
          pullable, build, hint, command, note) instead of the table; used by
          :MyPlugins machine. Exit code is unchanged.

  Exit code: 0 = everything current, 1 = something needs attention.

.USAGE
  pwsh -File scripts\sync-machine.ps1            # report only
  pwsh -File scripts\sync-machine.ps1 -Pull      # report + fast-forward
  pwsh -File scripts\sync-machine.ps1 -Only tasks-desktop,mdview.nvim
#>
param(
    [switch]$Pull,
    [switch]$Json,
    [string[]]$Only,
    [string]$ReposDir = $env:REPOS_DIR
)

$ErrorActionPreference = 'Continue'

if (-not $ReposDir -or -not (Test-Path $ReposDir)) {
    Write-Host 'REPOS_DIR is not set or missing - run setup-claude-code.ps1 first.' -ForegroundColor Red
    exit 2
}

# Repos that matter for "latest everywhere". Plugins are discovered by the
# *.nvim suffix; the rest is listed explicitly.
$extra = @(
    'tasks-vault', 'rules-vault', 'WKDBooks', 'WKDBook-Tricentis', 'Configs',
    'my-zsh', 'wkd', 'FightingGame', 'Kurse',
    'tasks-desktop', 'rules-desktop', 'docmap-desktop', 'ai-desktop', 'appkit'
)

# Native build artifacts: where the artifact lives, which paths feed it, and
# what to do when it is stale. Builds are never started here.
#   Hint     what to do, for a person to read (may be prose)
#   Command  the one command that builds it, run in the repo folder by
#            `:MyPlugins machine` (B) and copied by b; empty when there is none.
#            The desktop apps build with a script of their repo (the same one
#            installs without -BuildOnly / -SkipInstall, `:MyNative install`). ONE native
#            command, no chain: it has to run in Windows PowerShell 5.1 too
#            (no `&&`), and only the last exit code is reported. It must build
#            exactly the Artifact below and fail with a non-zero exit code.
$natives = @{
    'tasks-desktop' = @{
        Artifact = 'target\release\tasks-hub.exe'
        Sources  = @('crates', 'ui', 'Cargo.lock', 'engine.lock')
        Hint     = 'scripts\build-install.ps1 -BuildOnly   (build and install: without -BuildOnly; tools: :MyNative deps)'
        Command  = 'powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build-install.ps1 -BuildOnly'
    }
    'rules-desktop' = @{
        Artifact = 'target\release\rules-hub.exe'
        Sources  = @('crates', 'ui', 'Cargo.lock')
        Hint     = 'scripts\build-install.ps1 -BuildOnly   (build and install: without -BuildOnly; tools: :MyNative deps)'
        Command  = 'powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build-install.ps1 -BuildOnly'
    }
    'mdview.nvim' = @{
        Artifact = 'native\server\mdview-server.exe'
        Sources  = @('native\server')
        Hint     = 'sh scripts/rebuild-changed.sh HEAD~1 HEAD   (or: node scripts/build-go.mjs; npm run build)'
        Command  = 'node scripts/build-go.mjs'
    }
    'ai-desktop' = @{
        Artifact = 'build\ai-desktop.exe'
        Sources  = @('src', 'CMakeLists.txt')
        Hint     = 'scripts\build-install.ps1 -BuildOnly   (build and install: without -BuildOnly; tools: :MyNative deps)'
        Command  = 'powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build-install.ps1 -BuildOnly'
    }
    'docmap-desktop' = @{
        Artifact = 'src-tauri\target\release\docmap-desktop.exe'
        Sources  = @('src', 'src-tauri', 'engine.lock')
        Hint     = 'scripts\build-install.ps1 -BuildOnly   (build and install: without -BuildOnly; tools: :MyNative deps)'
        Command  = 'powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build-install.ps1 -BuildOnly'
    }
}

function Invoke-Git {
    param([string]$Dir, [string[]]$GitArgs)
    $out = & git -C $Dir @GitArgs 2>&1
    return [pscustomobject]@{ Code = $LASTEXITCODE; Out = ($out -join "`n").Trim() }
}

$names = @()
$names += Get-ChildItem -Path $ReposDir -Directory -Filter '*.nvim' | ForEach-Object { $_.Name }
$names += $extra
$names = $names | Sort-Object -Unique
# With -File a comma list arrives as ONE string; split it ourselves.
if ($Only) { $Only = $Only | ForEach-Object { $_ -split ',' } | Where-Object { $_ } }
if ($Only) { $names = $names | Where-Object { $Only -contains $_ } }

$attention = New-Object System.Collections.Generic.List[string]
$rows = New-Object System.Collections.Generic.List[object]

foreach ($name in $names) {
    $dir = Join-Path $ReposDir $name
    if (-not (Test-Path (Join-Path $dir '.git'))) {
        if ($extra -contains $name) {
            $rows.Add([pscustomobject]@{ Repo = $name; Path = $dir; State = 'MISSING (clone it)'; Note = ''; Behind = 0; Ahead = 0; Dirty = 0; Pullable = $false; Build = ''; Hint = ''; Command = '' })
            $attention.Add("$name : not cloned on this machine")
        }
        continue
    }

    $fetch = Invoke-Git $dir @('fetch', '--quiet', '--prune')
    $branch = (Invoke-Git $dir @('rev-parse', '--abbrev-ref', 'HEAD')).Out
    $dirty = (Invoke-Git $dir @('status', '--porcelain')).Out
    $upstream = Invoke-Git $dir @('rev-parse', '--abbrev-ref', '@{u}')

    $ahead = 0; $behind = 0
    if ($upstream.Code -eq 0) {
        $cnt = (Invoke-Git $dir @('rev-list', '--left-right', '--count', 'HEAD...@{u}')).Out -split '\s+'
        $ahead = [int]$cnt[0]; $behind = [int]$cnt[1]
    }

    $notes = New-Object System.Collections.Generic.List[string]
    $state = 'ok'

    if ($fetch.Code -ne 0) { $state = 'FETCH FAILED'; $notes.Add('offline or no access'); $attention.Add("$name : fetch failed") }
    elseif ($upstream.Code -ne 0) { $state = 'NO UPSTREAM'; $notes.Add("branch $branch"); $attention.Add("$name : $branch has no upstream") }
    else {
        if ($ahead -gt 0) { $state = 'UNPUSHED'; $notes.Add("$ahead ahead"); $attention.Add("$name : $ahead unpushed commit(s) - push before leaving this machine") }
        if ($behind -gt 0 -and $ahead -eq 0 -and -not $dirty -and $Pull -and ($branch -eq 'main' -or $branch -eq 'master')) {
            $p = Invoke-Git $dir @('pull', '--ff-only', '--quiet')
            if ($p.Code -eq 0) { $state = 'PULLED'; $notes.Add("fast-forwarded $behind") ; $behind = 0 }
            else { $state = 'PULL FAILED'; $notes.Add($p.Out); $attention.Add("$name : pull --ff-only failed") }
        }
        elseif ($behind -gt 0) {
            if ($ahead -gt 0) { $state = 'DIVERGED' }
            elseif ($state -eq 'ok') { $state = 'BEHIND' }
            $notes.Add("$behind behind")
            $attention.Add("$name : $behind behind origin (run with -Pull or pull by hand)")
        }
    }
    if ($dirty) {
        $n = ($dirty -split "`n").Count
        if ($state -eq 'ok') { $state = 'DIRTY' }
        $notes.Add("$n uncommitted file(s)")
        $attention.Add("$name : $n uncommitted file(s) - commit/push or stash before leaving")
    }
    if ($branch -ne 'main' -and $branch -ne 'master') { $notes.Add("on branch $branch") }

    $buildState = ''; $buildHint = ''; $buildCommand = ''
    # Native build freshness: artifact older than the newest source commit.
    if ($natives.ContainsKey($name)) {
        $nat = $natives[$name]
        $art = Join-Path $dir $nat.Artifact
        if (-not (Test-Path $art)) {
            $notes.Add('build MISSING'); $buildState = 'missing'; $buildHint = $nat.Hint; $buildCommand = $nat.Command
            $attention.Add("$name : no build at $($nat.Artifact) - $($nat.Hint)")
        } else {
            $srcArgs = @('log', '-1', '--format=%ct', '--') + $nat.Sources
            $ct = (Invoke-Git $dir $srcArgs).Out
            if ($ct -match '^\d+$') {
                $srcTime = [DateTimeOffset]::FromUnixTimeSeconds([int64]$ct).UtcDateTime
                $artTime = (Get-Item $art).LastWriteTimeUtc
                if ($artTime -lt $srcTime) {
                    $notes.Add('build STALE'); $buildState = 'stale'; $buildHint = $nat.Hint; $buildCommand = $nat.Command
                    $attention.Add("$name : build older than its sources - $($nat.Hint)")
                } else { $notes.Add('build current'); $buildState = 'current' }
            }
        }
    }

    $isMain = ($branch -eq 'main' -or $branch -eq 'master')
    $dirtyCount = 0
    if ($dirty) { $dirtyCount = ($dirty -split "`n").Count }
    $rows.Add([pscustomobject]@{
        Repo = $name; Path = $dir; State = $state; Note = ($notes -join ', ')
        Behind = $behind; Ahead = $ahead; Dirty = $dirtyCount
        Pullable = [bool]($behind -gt 0 -and $ahead -eq 0 -and $dirtyCount -eq 0 -and $isMain)
        Build = $buildState; Hint = $buildHint; Command = $buildCommand
    })
}

if ($Json) {
    ConvertTo-Json -InputObject @($rows.ToArray()) -Compress -Depth 3
    if ($attention.Count -eq 0) { exit 0 } else { exit 1 }
}

$rows | Select-Object Repo, State, Note | Format-Table -AutoSize | Out-String | Write-Host

if ($attention.Count -eq 0) {
    Write-Host 'Everything current - safe to work on this machine.' -ForegroundColor Green
    exit 0
}
Write-Host 'Needs attention:' -ForegroundColor Yellow
$attention | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
exit 1
