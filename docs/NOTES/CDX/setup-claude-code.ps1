<#
.SYNOPSIS
  Richtet Claude Code auf dieser Maschine gemaess der in diesem Ordner
  versionierten Vorlagen ein (Env-Vars, ~/.claude/CLAUDE.md,
  ~/.claude/settings.json). Idempotent - auf jeder Maschine (und nach jedem
  Pull) erneut ausfuehrbar.

.USAGE
  pwsh -File setup-claude-code.ps1
  pwsh -File setup-claude-code.ps1 -Workstation   # IS_WORKSTATION=1 ohne Rueckfrage
  pwsh -File setup-claude-code.ps1 -Private       # IS_WORKSTATION=0 ohne Rueckfrage
#>

param(
    [switch]$Workstation,
    [switch]$Private
)

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

# RULES_VAULT: Wurzel des Repos rules-vault (Regelwerke, rulesets/lua und rulesets/native).
$rulesVault = [Environment]::GetEnvironmentVariable('RULES_VAULT', 'User')
if (-not $rulesVault) {
    $candidate = Join-Path $reposDir 'rules-vault'
    if (Test-Path $candidate) {
        Set-UserEnvVar -name 'RULES_VAULT' -value $candidate
    } else {
        Write-Host "  RULES_VAULT nicht gesetzt und $candidate fehlt: Repo rules-vault klonen, dann das Skript erneut ausfuehren." -ForegroundColor Yellow
    }
} else {
    Write-Host "  RULES_VAULT bereits gesetzt: $rulesVault"
}

# TASKS_VAULT: Wurzel des Repos tasks-vault (Task-Vault: Areas mit ROADMAP/tasks, Backlog, Notizen, TOOLS). Der Hub
# von tasks-desktop und die CLI von tasks.nvim lesen sie; der Vault ist seit 2026-10-12 ein eigenes Repo, nicht
# mehr ein Ordner in WKDBooks. Auf jeder Maschine liegt er unter $REPOS_DIR/tasks-vault.
$tasksVault = [Environment]::GetEnvironmentVariable('TASKS_VAULT', 'User')
if (-not $tasksVault) {
    $candidate = Join-Path $reposDir 'tasks-vault'
    if (Test-Path $candidate) {
        Set-UserEnvVar -name 'TASKS_VAULT' -value $candidate
    } else {
        Write-Host "  TASKS_VAULT nicht gesetzt und $candidate fehlt: Repo tasks-vault klonen, dann das Skript erneut ausfuehren." -ForegroundColor Yellow
    }
} else {
    Write-Host "  TASKS_VAULT bereits gesetzt: $tasksVault"
}

# IS_WORKSTATION: 1 = Tricentis-Workstation (kein unsigniertes Programm bauen, installieren oder starten, EDR), 0 =
# privater Rechner. Wird einmal pro Maschine festgelegt und nie aus dem Rechnernamen erraten; Code und Regeln lesen nur
# diese Variable. Ist sie nicht gesetzt, gilt die Maschine als unbekannt (dann nachfragen).
$isWorkstation = [Environment]::GetEnvironmentVariable('IS_WORKSTATION', 'User')
if ($Workstation -and $Private) {
    Write-Error '-Workstation und -Private schliessen sich aus.'
} elseif ($Workstation) {
    Set-UserEnvVar -name 'IS_WORKSTATION' -value '1'
} elseif ($Private) {
    Set-UserEnvVar -name 'IS_WORKSTATION' -value '0'
} elseif ($isWorkstation -in @('0', '1')) {
    Write-Host "  IS_WORKSTATION bereits gesetzt: $isWorkstation"
} else {
    $answer = Read-Host '  Ist das die Tricentis-Workstation? (j = ja, n = privater Rechner)'
    Set-UserEnvVar -name 'IS_WORKSTATION' -value $(if ($answer -match '^(j|ja|y|yes)$') { '1' } else { '0' })
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

Write-Host "`n[optional] Dev-Toolchains (nvim/cpp/rust/web/tauri) per winget installieren?"
$profileAnswer = Read-Host '  Profile kommagetrennt eingeben (z.B. nvim,rust,web) oder leer lassen zum Ueberspringen'
if ($profileAnswer) {
    node (Join-Path $PSScriptRoot 'setup-devtools.js') --profile $profileAnswer
}

Write-Host "`nFertig."
