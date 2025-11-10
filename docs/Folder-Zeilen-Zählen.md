# Zählwerk

## Einzeiler

```powershell
Get-ChildItem -Path . -Recurse -Include *.lua | Where-Object { $_.FullName -notmatch '(\\\.git\\|\\debuglog\\|\\docs\\)' } | Get-Content | Measure-Object -Line | Select-Object -ExpandProperty Lines
```

---

### kürzere Variante

```powershell
(Get-ChildItem -R -Include *.lua | Where-Object { $_.FullName -notmatch '(\\\.git\\|\\debuglog\\|\\docs\\)' } | Get-Content).Count
```

---

### Falls man auch die Anzahl der Dateien sehen möchte

```powershell
$files = Get-ChildItem -Path . -Recurse -Include *.lua | Where-Object { $_.FullName -notmatch '(\\\.git\\|\\debuglog\\|\\docs\\)' }
$lines = $files | Get-Content | Measure-Object -Line
Write-Host "Files: $($files.Count), Lines: $($lines.Lines)"
```

Die Dateien `lazy.lock.json`, `.stylua.toml` und `.gitignore` werden automatisch ausgeschlossen, da der Filter nur `*.lua` Dateien einbezieht.

---

### Alternativ mit `wsl` falls installiert

```bash
wsl find . -name "*.lua" -not -path "*/.git/*" -not -path "*/debuglog/*" -not -path "*/docs/*" -exec wc -l {} + | tail -1
```

---

## Kompletausgaben

### 1. ASCII-Connectoren, Keine Kodierungsabhängigkeit.

```powershell
# ASCII-safe variant of the script
# All comments are in English as requested by the user (code comments must be English).

# Get all .lua files recursively, excluding common folders
$files = Get-ChildItem -Path . -Recurse -Include *.lua | Where-Object {
    $_.FullName -notmatch '(\\\.git\\|\\debuglog\\|\\docs\\)'
}

$fileStats = $files | ForEach-Object {
    # Count lines; suppress read errors
    $lineCount = (Get-Content $_.FullName -ErrorAction SilentlyContinue | Measure-Object -Line).Lines
    [PSCustomObject]@{
        FullPath     = $_.FullName
        RelPath      = $_.FullName.Replace((Get-Location).Path + '\', '')
        Directory    = $_.Directory.FullName
        RelDirectory = $_.Directory.FullName.Replace((Get-Location).Path + '\', '')
        FileName     = $_.Name
        Lines        = $lineCount
    }
}

# Function: Show-Tree
function Show-Tree {
    param(
        $items,
        $prefix = "",
        $isLast = $true
    )

    # Group by first path component; if file is in root, group name is the filename
    $grouped = $items | Group-Object {
        $first = ($_.RelPath -split '\\')[0]
        if ($first) { $first } else { $_.RelPath }
    }
    $count = $grouped.Count
    $index = 0

    foreach ($group in $grouped) {
        $index++
        $isLastItem = ($index -eq $count)
        # Use ASCII connectors to avoid encoding problems
        $connector = if ($isLastItem) { "+--" } else { "|--" }
        $extension = if ($isLastItem) { "    " } else { "|   " }

        # Determine next-level items (skip the first path part)
        $nextLevel = $group.Group | ForEach-Object {
            $parts = ($_.RelPath -split '\\')
            $newPath = ($parts | Select-Object -Skip 1) -join '\'
            if ($newPath) {
                [PSCustomObject]@{
                    RelPath  = $newPath
                    FileName = $_.FileName
                    Lines    = $_.Lines
                }
            }
        }

        if ($nextLevel) {
            # Sum lines for the folder
            $folderLines = ($group.Group | Measure-Object -Property Lines -Sum).Sum
            $folderFiles = $group.Group.Count
            Write-Host "$prefix$connector $($group.Name)/ ($folderLines lines, $folderFiles files)"
            Show-Tree -items $nextLevel -prefix ($prefix + $extension) -isLast $isLastItem
        } else {
            # Single file (no deeper path)
            $file = $group.Group[0]
            Write-Host "$prefix$connector $($file.FileName) ($($file.Lines) lines)"
        }
    }
}

Write-Host ""
Write-Host "=== FILE TREE WITH LINE COUNTS ==="
Show-Tree -items $fileStats

Write-Host ""
Write-Host "=== SUMMARY ==="
$totalLines = ($fileStats | Measure-Object -Property Lines -Sum).Sum
$totalFiles = $fileStats.Count
$totalFolders = ($fileStats | Select-Object -Unique RelDirectory).Count

Write-Host "Total Lines:   " -NoNewline
Write-Host $totalLines
Write-Host "Total Files:   " -NoNewline
Write-Host $totalFiles
Write-Host "Total Folders: " -NoNewline
Write-Host $totalFolders
```

---

### Variante mit Box-Drawing Unicode (ästhetisch)

Anleitung:

* Datei als UTF-8 mit BOM speichern (PowerShell 5.1 auf Windows bevorzugt BOM für Konsolenanzeige).
* Vor dem Ausführen in der Konsole evtl. `chcp 65001` setzen und `$OutputEncoding = [System.Text.Encoding]::UTF8` setzen, um Ausgabe-Encoding auf UTF-8 zu stellen.

#### Optional in der Session vor Ausführung:

```powershell
# Set console code page and output encoding for the current session
chcp 65001 > $null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
```

#### Unicode-freundliches Skript (speichern als UTF-8 with BOM):

```powershell
# Unicode box-drawing variant (save this file as UTF-8 with BOM)
# Comments are in English.

$files = Get-ChildItem -Path . -Recurse -Include *.lua | Where-Object {
    $_.FullName -notmatch '(\\\.git\\|\\debuglog\\|\\docs\\)'
}

$fileStats = $files | ForEach-Object {
    $lineCount = (Get-Content $_.FullName -ErrorAction SilentlyContinue | Measure-Object -Line).Lines
    [PSCustomObject]@{
        FullPath     = $_.FullName
        RelPath      = $_.FullName.Replace((Get-Location).Path + '\', '')
        Directory    = $_.Directory.FullName
        RelDirectory = $_.Directory.FullName.Replace((Get-Location).Path + '\', '')
        FileName     = $_.Name
        Lines        = $lineCount
    }
}

function Show-Tree {
    param(
        $items,
        $prefix = "",
        $isLast = $true
    )

    $grouped = $items | Group-Object {
        $first = ($_.RelPath -split '\\')[0]
        if ($first) { $first } else { $_.RelPath }
    }
    $count = $grouped.Count
    $index = 0

    foreach ($group in $grouped) {
        $index++
        $isLastItem = ($index -eq $count)
        # Box-drawing characters (require UTF-8)
        $connector = if ($isLastItem) { "└──" } else { "├──" }
        $extension = if ($isLastItem) { "    " } else { "│   " }

        $nextLevel = $group.Group | ForEach-Object {
            $parts = ($_.RelPath -split '\\')
            $newPath = ($parts | Select-Object -Skip 1) -join '\'
            if ($newPath) {
                [PSCustomObject]@{
                    RelPath  = $newPath
                    FileName = $_.FileName
                    Lines    = $_.Lines
                }
            }
        }

        if ($nextLevel) {
            $folderLines = ($group.Group | Measure-Object -Property Lines -Sum).Sum
            $folderFiles = $group.Group.Count
            # Using Write-Host once per line keeps the color handling simpler; here no colors to avoid console color issues
            Write-Host "$prefix$connector $($group.Name)/ ($folderLines lines, $folderFiles files)"
            Show-Tree -items $nextLevel -prefix ($prefix + $extension) -isLast $isLastItem
        } else {
            $file = $group.Group[0]
            Write-Host "$prefix$connector $($file.FileName) ($($file.Lines) lines)"
        }
    }
}

Write-Host ""
Write-Host "=== FILE TREE WITH LINE COUNTS ==="
Show-Tree -items $fileStats

Write-Host ""
Write-Host "=== SUMMARY ==="
$totalLines = ($fileStats | Measure-Object -Property Lines -Sum).Sum
$totalFiles = $fileStats.Count
$totalFolders = ($fileStats | Select-Object -Unique RelDirectory).Count

Write-Host "Total Lines:   " -NoNewline
Write-Host $totalLines
Write-Host "Total Files:   " -NoNewline
Write-Host $totalFiles
Write-Host "Total Folders: " -NoNewline
Write-Host $totalFolders
```

### Zusätzliche Hinweise:

 Für dauerhafte UTF-8-Unterstützung empfiehlt es sich, die Datei in einem Editor mit expliziter Option "UTF-8 with BOM" zu speichern (z. B. Visual Studio Code: Save with Encoding → UTF-8 with BOM).
 PowerShell 7+ (Core) handhabt UTF-8 deutlich besser; ein Upgrade auf PowerShell 7 ist empfehlenswert, wenn häufig Unicode in Skripten genutzt wird.
 Wenn weiterhin Farben benötigt werden, lassen sich `Write-Host`-Farben wieder einbauen — zuerst das Encoding-Problem lösen.

---
