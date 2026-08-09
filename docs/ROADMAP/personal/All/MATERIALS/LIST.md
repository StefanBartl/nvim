# personal nvim plugin list

## Table of content

  - [Pluginlist](#pluginlist)
  - [repos klonen](#repos-klonen)
    - [1. Bash (Git-Bash / Linux / macOS)](#1-bash-git-bash-linux-macos)
    - [2. PowerShell](#2-powershell)
  - [repos entfernen](#repos-entfernen)
    - [1. PowerShell Befehl](#1-powershell-befehl)
    - [2. Bash / Git-Bash Befehl](#2-bash-git-bash-befehl)

---

## Pluginlist

`/buffer-ctx.nvim`
`/cascade,nvim`
`/cmdlog.nvim`
`/color_my_ascii.nvim`
`/dap.nvim`
`/debugging.nvim`
`/diff.nvim`
`/documentation.nvim`
`/emojis.nvim`
`/fileops.nvim`
`/filetree.nvim`
`/github_stats.nvim`
`/gopath.nvim`
`/images.nvim`
`/insights.nvim`
`/language.nvim`
`/lsp.nvim`
`/lib.nvim`
`/markdown.nvim`
`/mdview.nvim`
`/migrate.nvim`
`/open.nvim`
`/pdfport.nvim`
`/pickers.nvim`
`/recommender.nvim`
`/replacer.nvim`
`/reposcope.nvim`
`/runtime-analysis.nvim`
`/sandbox.nvim`
`/sessions.nvim`
`/spotlight.nvim`

---

## repos klonen

---

### 1. Bash (Git-Bash / Linux / macOS)

Dieser Befehl nutzt eine Schleife, entfernt das führende `/` automatisch und klont die Repos nacheinander:

```bash
repos=("/buffer-ctx.nvim" "/cascade,nvim" "/color_my_ascii.nvim" "/debugging.nvim" "/dap.nvim" "/diff.nvim" "/documentation.nvim" "/emojis.nvim" "/fileops.nvim" "/filetree.nvim" "/github_stats.nvim" "/gopath.nvim" "/images.nvim"  "/insights.nvim" "/language.nvim" "/lib.nvim" "/lsp.nvim" "/markdown.nvim" "/mdview.nvim" "/migrate.nvim" "/mygrep.nvim" "/cmdlog" "/sandbox.nvim" "/open.nvim" "/pdfport.nvim" "/pickers.nvim" "/insights.nvim" "/recommender.nvim" "/replacer.nvim" "/reposcope.nvim" "/runtime-analysis.nvim " "/sessions.nvim" "/spotlight.nvim" ); for repo in "${repos[@]}"; do clean_repo=${repo#/}; git clone "git@github.com:StefanBartl/${clean_repo}.git"; done

```

---

### 2. PowerShell

Die PowerShell-Variante säubert den Pfad ebenfalls über `.TrimStart('/')` und jagt die Liste durch eine `ForEach-Object`-Schleife (abgekürzt `foreach`):

```powershell
@("buffer-ctx.nvim", "cascade.nvim", "color_my_ascii.nvim", "debugging.nvim", "dap.nvim", "diff.nvim", "documentation.nvim", "emojis.nvim", "fileops.nvim", "filetree.nvim",  "github_stats.nvim", "gopath.nvim", "images.nvim", "insights.nvim", "language.nvim", "lib.nvim", "lsp.nvim", "markdown.nvim", "mdview.nvim", "migrate.nvim", "cmdlog.nvim", "sandbox.nvim", "open.nvim", "pdfport.nvim", "pickers.nvim", "insights.nvim", "recommender.nvim", "replacer.nvim", "reposcope.nvim", "runtime-analysis.nvim", "sessions.nvim", "spotlight.nvim" ) | ForEach-Object { git clone "https://github.com/StefanBartl/$_.git" }
```

---

## repos entfernen

> ⚠️ **Achtung:** Beide Befehle löschen die Ordner unwiderruflich (sie landen nicht im Papierkorb). Stelle also sicher, dass du dich im richtigen Verzeichnis befindest und keine ungesicherten lokalen Änderungen in den Ordnern liegen.

---

### 1. PowerShell Befehl

In der PowerShell nutzen wir `Remove-Item` mit den Parametern `-Recurse` (löscht Unterordner) und `-Force` (löscht schreibgeschützte Dateien wie die Git-Historie ohne Nachfrage):

```powershell
@("buffer-ctx.nvim", "cascade,nvim", "color_my_ascii.nvim", "debugging.nvim", "dap.nvim", "diff.nvim", "documentation.nvim", "emojis.nvim", "fileops.nvim", "filetree.nvim",  "github_stats.nvim", "gopath.nvim", "images.nvim", "insights.nvim", "language.nvim", "lib.nvim","lsp.nvim", "markdown.nvim", "mdview.nvim", "migrate.nvim", "cmdlog.nvim", "sandbox.nvim", "open.nvim", "pdfport.nvim", "pickers.nvim", "insights.nvim", "recommender.nvim", "replacer.nvim", "reposcope.nvim", "runtime-analysis.nvim", "sessions.nvim", "spotlight.nvim") | ForEach-Object { if (Test-Path $_) { Remove-Item $_ -Recurse -Force } }

```

---

### 2. Bash / Git-Bash Befehl

In der Git-Bash nutzen wir `rm -rf` (recursive + force), um die Verzeichnisse direkt zu entfernen:

```bash
repos=("buffer-ctx.nvim" "cascade,nvim" "color_my_ascii.nvim" "dap.nvim" "debugging.nvim" "diff.nvim" "documentation.nvim" "emojis.nvim" "fileops.nvim" "filetree.nvim" "github_stats.nvim" "gopath.nvim" "images.nvim" "insights.nvim" "language.nvim" "lib.nvim" "lsp.nvim" "markdown.nvim" "mdview.nvim" "migrate.nvim" "cmdlog.nvim" "sandbox.nvim" "open.nvim" "pdfport.nvim" "pickers.nvim" "insights.nvim" "recommender.nvim" "replacer.nvim" "reposcope.nvim" "runtime-analysis.nvim" "sessions.nvim" "spotlight.nvim"); for repo in "${repos[@]}"; do rm -rf "$repo"; done

```

---

