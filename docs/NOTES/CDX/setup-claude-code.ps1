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
    do {
        $reposDir = Read-Host '  REPOS_DIR ist auf dieser Maschine nicht gesetzt. Pfad zur Repos-Wurzel eingeben (z.B. B:\repos)'
        if ($reposDir -and -not (Test-Path $reposDir)) {
            Write-Host "  Pfad '$reposDir' existiert nicht - bitte erneut eingeben." -ForegroundColor Yellow
            $reposDir = $null
        }
    } while (-not $reposDir)
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
        $backup = "$claudeMdTarget.bak-$(Get-Date -Format 'yyyyMMdd-HHmmssfff')"
        Move-Item $claudeMdTarget $backup -Force
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

# --- 3. ~/.claude/settings.json (Merge, ueber gemeinsames Node-Skript) -----
# Merge-Logik lebt in merge-claude-settings.js, geteilt mit
# setup-claude-code.sh (Linux/macOS), damit beide Plattformen nicht
# auseinanderlaufen.

Write-Host "`n[3/3] settings.json"

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Error "node nicht gefunden. Wird sowohl fuer den Merge als auch fuer check-lua-hook.js gebraucht - bitte Node.js installieren und Skript erneut ausfuehren."
}

$templatePath = Join-Path $PSScriptRoot 'settings.global.json'
$settingsPath = Join-Path $claudeDir 'settings.json'
$mergeScript = Join-Path $PSScriptRoot 'merge-claude-settings.js'

node $mergeScript $templatePath $settingsPath $nvimConfig

Write-Host "`nFertig."
