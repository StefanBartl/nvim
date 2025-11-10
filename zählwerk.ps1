# Unicode box-drawing variant (save this file as UTF-8 with BOM)

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

