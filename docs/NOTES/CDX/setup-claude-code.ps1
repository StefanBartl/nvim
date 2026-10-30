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

Write-Host "NVIM_CONFIG_DIR = $nvimConfig"

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
Set-UserEnvVar -name 'NVIM_CONFIG_DIR' -value $nvimConfig
# Alter Name, fuer aeltere Skripte/Notizen weiter gesetzt.
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

# TESTING_TRUST_ROOTS: testing.nvim fuehrt die .testing.lua eines Projekts erst aus, wenn es vertraut ist (Workspace
# trust, docs/CONFIG.md). Alle eigenen Repos unter $REPOS_DIR gelten als vertraut; sonst enden lokale Laeufe
# (scripts/test.sh, :Testing) mit Exit 2. Eine schon gesetzte Liste (mehrere Wurzeln, ';'-getrennt) bleibt stehen.
$trustRoots = [Environment]::GetEnvironmentVariable('TESTING_TRUST_ROOTS', 'User')
if (-not $trustRoots) {
    Set-UserEnvVar -name 'TESTING_TRUST_ROOTS' -value $reposDir
} else {
    Write-Host "  TESTING_TRUST_ROOTS bereits gesetzt: $trustRoots"
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

# NVIM_MACHINE_ROLE (workstation | unset = privater Rechner) wird hier nicht gesetzt: lua/machine.lua der nvim-Config
# liest sie schon, und die Claude-Regeln (CLAUDE.global.md, Abschnitt Maschine) lesen dieselbe Variable. Gelesen wie
# machine.lua: Prozess-Umgebung, lower(), nur bekannte Rollen. Ist sie dort leer, aber im User- oder Machine-Scope
# gesetzt, kennt diese Shell sie nur noch nicht (Neustart noetig).
# BEGIN machine-role
$roleRaw = $env:NVIM_MACHINE_ROLE
$roleNote = ''
if (-not $roleRaw) {
    foreach ($scope in 'User', 'Machine') {
        $scopeValue = [Environment]::GetEnvironmentVariable('NVIM_MACHINE_ROLE', $scope)
        if ($scopeValue) {
            $roleRaw = $scopeValue
            $roleNote = " (nur im $scope-Scope; diese Shell/App kennt sie erst nach einem Neustart)"
            break
        }
    }
}
$machineRole = if ($roleRaw) { $roleRaw.ToLowerInvariant() } else { '' }
$isWorkstation = $machineRole -eq 'workstation'
if ($isWorkstation) {
    Write-Host "  Maschine: workstation (NVIM_MACHINE_ROLE)$roleNote" -ForegroundColor Yellow
} elseif ($machineRole -eq '' -or $machineRole -eq 'default') {
    Write-Host "  Maschine: privater Rechner (NVIM_MACHINE_ROLE$(if ($machineRole) { '=default' } else { ' nicht gesetzt' }))$roleNote"
    if (-not $machineRole -and ($env:USERDOMAIN -eq 'AzureAD' -or $env:COMPUTERNAME -like 'TRI-*')) {
        Write-Host "  Achtung: AzureAD-/TRI-Rechner ohne NVIM_MACHINE_ROLE. Ist das die Workstation, zuerst von Hand setzen:" -ForegroundColor Yellow
        Write-Host "    setx NVIM_MACHINE_ROLE workstation   (dann Terminal/App neu starten und dieses Skript erneut ausfuehren)" -ForegroundColor Yellow
    }
} else {
    Write-Host "  Maschine: unbekannte NVIM_MACHINE_ROLE '$roleRaw'$roleNote - nvim nimmt 'default'; Tippfehler?" -ForegroundColor Yellow
}
# END machine-role

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
Write-Host "  Was auf dieser Maschine schon da ist:"
node (Join-Path $PSScriptRoot 'setup-devtools.js') --status
if ($isWorkstation) {
    Write-Host "  Workstation (CrowdStrike Falcon): nichts Unsigniertes installieren. Mehrere winget-Pakete sind" -ForegroundColor Yellow
    Write-Host "  unsignierte portable Binaries (u. a. ripgrep, fd, stylua). Im Zweifel leer lassen." -ForegroundColor Yellow
}
$profileAnswer = Read-Host '  Profile kommagetrennt (nvim,cpp,rust,web,tauri), all = alle, leer = ueberspringen'
if ($profileAnswer) {
    node (Join-Path $PSScriptRoot 'setup-devtools.js') --profile $profileAnswer
}

Write-Host "`nFertig."
