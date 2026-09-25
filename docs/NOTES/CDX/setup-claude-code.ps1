<#
.SYNOPSIS
  Richtet Claude Code auf dieser Maschine gemaess der in diesem Ordner
  versionierten Vorlagen ein (Env-Vars, ~/.claude/CLAUDE.md,
  ~/.claude/settings.json). Idempotent - auf jeder Maschine (und nach jedem
  Pull) erneut ausfuehrbar.

.USAGE
  pwsh -File setup-claude-code.ps1
#>

$ErrorActionPreference = 'Stop'

# CDX -> NOTES -> docs -> nvim-config-root
$nvimConfig = (Get-Item $PSScriptRoot).Parent.Parent.Parent.FullName
$claudeDir  = Join-Path $HOME '.claude'

Write-Host "NVIM_CONFIG = $nvimConfig"

# --- 1. Env-Variablen (User-Scope) -----------------------------------------

function Set-UserEnvVar($name, $value) {
    $current = [Environment]::GetEnvironmentVariable($name, 'User')
    if ($current -eq $value) {
        Write-Host "  $name bereits korrekt gesetzt."
        return
    }
    [Environment]::SetEnvironmentVariable($name, $value, 'User')
    Write-Host "  $name gesetzt: $value"
}

Write-Host "`n[1/3] Env-Variablen"
Set-UserEnvVar -name 'NVIM_CONFIG' -value $nvimConfig

$reposDir = [Environment]::GetEnvironmentVariable('REPOS_DIR', 'User')
if (-not $reposDir) {
    $reposDir = Read-Host '  REPOS_DIR ist auf dieser Maschine nicht gesetzt. Pfad zur Repos-Wurzel eingeben (z.B. B:\repos)'
    Set-UserEnvVar -name 'REPOS_DIR' -value $reposDir
} else {
    Write-Host "  REPOS_DIR bereits gesetzt: $reposDir"
}

Write-Host "  Hinweis: neu gesetzte User-Env-Vars gelten erst in neuen Shells/Sessions."

# --- 2. ~/.claude/CLAUDE.md (Symlink, Fallback Kopie) -----------------------

Write-Host "`n[2/3] CLAUDE.md"
New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null

$claudeMdSource = Join-Path $PSScriptRoot 'CLAUDE.global.md'
$claudeMdTarget = Join-Path $claudeDir 'CLAUDE.md'

$targetItem = Get-Item -Path $claudeMdTarget -ErrorAction SilentlyContinue
$alreadyLinked = $targetItem -and $targetItem.LinkType -and ($targetItem.Target -eq $claudeMdSource)

if ($alreadyLinked) {
    Write-Host "  Symlink bereits korrekt."
} else {
    if (Test-Path $claudeMdTarget) {
        $backup = "$claudeMdTarget.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Move-Item $claudeMdTarget $backup
        Write-Host "  Bestehende CLAUDE.md gesichert nach: $backup"
    }
    try {
        New-Item -ItemType SymbolicLink -Path $claudeMdTarget -Target $claudeMdSource | Out-Null
        Write-Host "  Symlink angelegt: $claudeMdTarget -> $claudeMdSource"
    } catch {
        Copy-Item $claudeMdSource $claudeMdTarget
        Write-Host "  Kein Symlink moeglich (Developer Mode / Admin noetig) - stattdessen kopiert."
        Write-Host "  Bei Aenderungen an CLAUDE.global.md dieses Skript erneut ausfuehren."
    }
}

# --- 3. ~/.claude/settings.json (Merge) -------------------------------------

Write-Host "`n[3/3] settings.json"

$templatePath = Join-Path $PSScriptRoot 'settings.global.json'
$settingsPath = Join-Path $claudeDir 'settings.json'

$nvimConfigForward = $nvimConfig -replace '\\', '/'
$templateJson = (Get-Content $templatePath -Raw).Replace('__NVIM_CONFIG__', $nvimConfigForward)
$template = $templateJson | ConvertFrom-Json

if (Test-Path $settingsPath) {
    $backup = "$settingsPath.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item $settingsPath $backup
    Write-Host "  Bestehende settings.json gesichert nach: $backup"
    $existing = Get-Content $settingsPath -Raw | ConvertFrom-Json
} else {
    $existing = [PSCustomObject]@{}
}

function Test-HasProperty($obj, $name) {
    return [bool]($obj.PSObject.Properties.Match($name).Count)
}

# permissions.allow: Vereinigung, dedupliziert
if (-not (Test-HasProperty $existing 'permissions')) {
    $existing | Add-Member -MemberType NoteProperty -Name permissions -Value ([PSCustomObject]@{ allow = @() })
}
if (-not (Test-HasProperty $existing.permissions 'allow')) {
    $existing.permissions | Add-Member -MemberType NoteProperty -Name allow -Value @()
}
$mergedAllow = @($existing.permissions.allow) + @($template.permissions.allow) | Select-Object -Unique
$existing.permissions.allow = $mergedAllow

# hooks.PostToolUse: Template-Eintraege anhaengen, falls noch nicht vorhanden
if (-not (Test-HasProperty $existing 'hooks')) {
    $existing | Add-Member -MemberType NoteProperty -Name hooks -Value ([PSCustomObject]@{ PostToolUse = @() })
}
if (-not (Test-HasProperty $existing.hooks 'PostToolUse')) {
    $existing.hooks | Add-Member -MemberType NoteProperty -Name PostToolUse -Value @()
}

$existingEntries = @($existing.hooks.PostToolUse)
foreach ($entry in $template.hooks.PostToolUse) {
    $entryCommand = $entry.hooks[0].command
    $alreadyPresent = $false
    foreach ($e in $existingEntries) {
        if ($e.matcher -eq $entry.matcher -and $e.hooks[0].command -eq $entryCommand) {
            $alreadyPresent = $true
            break
        }
    }
    if ($alreadyPresent) {
        Write-Host "  Hook fuer Matcher '$($entry.matcher)' bereits vorhanden - uebersprungen."
    } else {
        $existingEntries = $existingEntries + $entry
        Write-Host "  Hook fuer Matcher '$($entry.matcher)' ergaenzt."
    }
}
$existing.hooks.PostToolUse = $existingEntries

$existing | ConvertTo-Json -Depth 10 | Set-Content -Path $settingsPath -Encoding UTF8
Write-Host "  settings.json geschrieben: $settingsPath"

Write-Host "`nFertig."
