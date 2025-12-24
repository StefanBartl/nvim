# Troubleshooting - Windows Diff-Format

## Problem: "Patch file does not appear to be a valid unified diff"

### Ursache

Deine Diff-Dateien verwenden **Windows-absolute-Pfade** in den Header-Zeilen:

```diff
--- C:\Users\bartl\AppData\Local\nvim\patches\noice\lsp\old.lua
+++ C:\Users\bartl\AppData\Local\nvim\patches\noice\lsp\FIXED.lua
@@ -38,38 +38,28 @@
```

Das `patch`-Command erwartet aber **relative Pfade** oder einfache Dateinamen:

```diff
--- signature.lua
+++ signature.lua
@@ -38,38 +38,28 @@
```

### Lösung (Automatisch - Version 2.0.1+)

**Das System normalisiert jetzt automatisch!** Keine manuelle Aktion nötig.

Der neue **Preprocessor** erkennt Windows-Pfade und erstellt automatisch temporäre, normalisierte Diff-Dateien.

**Logs prüfen:**

```vim
:lua require("autocmds.patches").show_logs_buffer()
```

Du solltest sehen:

```json
{
  "level": "DEBUG",
  "message": "Normalizing Windows-style diff headers",
  "context": { "target": "..." }
}
```

### Lösung (Manuell - falls Preprocessor fehlschlägt)

#### Option 1: Diff neu erstellen (empfohlen)

```bash
cd ~/.local/share/nvim/lazy/noice.nvim

# Stash oder commit deine Änderungen
git add -A
git commit -m "temp"

# Erstelle Diff mit relativen Pfaden
git diff HEAD~1 lua/noice/lsp/signature.lua > ~/signature.diff

# Kopiere zu Patches
cp ~/signature.diff ~/.config/nvim/patches/noice/lsp/signature/diff.patch
```

#### Option 2: Header manuell ersetzen

Öffne deine Diff-Datei und ändere die Header:

**Vorher:**
```diff
--- C:\Users\Bernhard\...\patches\noice\lsp\old.lua  2025-12-18 ...
+++ C:\Users\Bernhard\...\patches\noice\lsp\FIXED.lua  2025-12-18 ...
```

**Nachher:**
```diff
--- signature.lua
+++ signature.lua
```

**Wichtig:**
* Keine Pfade, nur Dateinamen
* Keine Timestamps (optional)
* Strip-Level in `paths.lua` auf `0` setzen

#### Option 3: Unix-Tool verwenden (WSL/Git Bash)

```bash
# In WSL oder Git Bash
cd /mnt/c/Users/Bernhard/.local/share/nvim/lazy/noice.nvim

# Erstelle Diff
diff -u lua/noice/lsp/signature.lua.orig lua/noice/lsp/signature.lua > ~/signature.patch
```

---

## Problem: Strip-Level falsch

### Symptom

```
patching file signature.lua
can't find file to patch at input line 3
```

### Ursache

Der Strip-Level (`-p<N>`) bestimmt, wie viele Pfad-Komponenten entfernt werden:

```diff
--- a/lua/noice/lsp/signature.lua    # -p1 entfernt "a/"
--- lua/noice/lsp/signature.lua      # -p0 (nichts entfernen)
--- signature.lua                    # -p0 (schon einfacher Name)
```

### Lösung

In `paths.lua`:

```lua
{
  key = "noice-lsp-signature",
  strip = 0,  -- Für einfache Dateinamen
  -- strip = 1,  -- Für a/path/to/file.lua
  -- ...
}
```

**Regel:**
- `strip = 0`: Dateiname direkt oder ohne Präfix
- `strip = 1`: Mit `a/` oder `b/` Präfix
- `strip = 2+`: Tiefere Pfade (`some/deep/path/file.lua`)

---

## Validation-Test

### 1. Manuell testen

```bash
# Windows CMD
cd C:\Users\Bernhard\.local\share\nvim\lazy\noice.nvim

# Dry-Run
patch --dry-run -p0 -i C:\Users\bartl\AppData\Local\nvim\patches\noice\lsp\signature\diff.patch lua\noice\lsp\signature.lua
```

**Erwartetes Ergebnis bei Erfolg:**
```
checking file lua\noice\lsp\signature.lua
```

**Bei Fehler:**
```
can't find file to patch at input line 3
```

### 2. In Neovim validieren

```vim
:lua require("autocmds.patches").validate_all(function(r) vim.print(r) end)
```

**Erfolgreich:**
```lua
{
  key = "noice-lsp-signature",
  valid = true,
  error = nil
}
```

**Fehlgeschlagen:**
```lua
{
  key = "noice-lsp-signature",
  valid = false,
  error = "Patch file does not appear to be a valid unified diff"
}
```

---

## Best Practices für Windows

### 1. Diff-Erstellung

**Empfohlen (Git):**
```bash
git diff --no-prefix lua/noice/lsp/signature.lua > patch.diff
```

Erzeugt:
```diff
--- lua/noice/lsp/signature.lua
+++ lua/noice/lsp/signature.lua
```

**Alternativ (einfacher Name):**
```bash
git diff lua/noice/lsp/signature.lua | sed 's|[ab]/lua/noice/lsp/||g' > patch.diff
```

Erzeugt:
```diff
--- signature.lua
+++ signature.lua
```

### 2. Path-Handling

Verwende **forward slashes** (`/`) statt backslashes (`\`) in `paths.lua`:

```lua
-- ❌ Vermeiden
patch = "C:\\Users\\Bernhard\\...\\diff.patch"

-- ✅ Empfohlen
patch = "C:/Users/Bernhard/.../diff.patch"

-- ✅ Best Practice (stdpath)
patch = vim.fn.stdpath("config") .. "/patches/noice/lsp/signature/diff.patch"
```

### 3. Line Endings

Windows (`\r\n`) vs Unix (`\n`) Line Endings können Probleme verursachen.

**Check:**
```vim
:set fileformat?
```

**Fix falls nötig:**
```bash
dos2unix patch.diff  # In Git Bash/WSL
```

Oder in Vim:
```vim
:e ++ff=unix patch.diff
:w
```

---

## Debug-Workflow

### 1. Verbose-Modus aktivieren

```lua
require("autocmds.patches").setup({
  verbose = true,
})
```

### 2. Einzelnen Patch testen

```lua
require("autocmds.patches").apply_async({
  keys = { "noice-lsp-signature" },
  callback = function(results)
    vim.print(results[1])
  end
})
```

### 3. Logs analysieren

```vim
:lua require("autocmds.patches").show_logs_buffer()
```

Suche nach:
- `"Normalizing Windows-style diff headers"` → Preprocessor aktiv
- `"Using normalized patch file"` → Temp-Datei erstellt
- `"Patch failed"` → Exit-Code und stderr prüfen

### 4. Temp-Dateien prüfen

Normalisierte Patches werden hier abgelegt:

```
~/.local/share/nvim/cache/patches/temp/
```

Öffne diese Dateien um zu sehen, was tatsächlich an `patch` übergeben wird:

```vim
:e ~/.local/share/nvim/cache/patches/temp/diff.patch
```

---

## Häufige Fehler

### "Reversed (or previously applied) patch detected"

**Bedeutung:** Patch ist bereits angewendet.

**Lösung:** Normal! System überspringt automatisch.

```vim
:lua require("autocmds.patches").get_status({ keys = {"noice-lsp-signature"} })
```

Status sollte `"already_applied"` sein.

### "malformed patch"

**Ursache:** Diff-Format beschädigt oder unvollständig.

**Check:**
1. Datei hat `@@` Hunks?
2. `+` und `-` Zeilen vorhanden?
3. Keine Binärdaten?

**Neuerstellen:**
```bash
git diff --unified=3 lua/noice/lsp/signature.lua > new.patch
```

---

## Support

Bei weiteren Problemen:

1. **Status ausgeben:**
   ```vim
   :lua vim.print(require("autocmds.patches").get_status())
   ```

2. **Logs prüfen:**
   ```vim
   :lua require("autocmds.patches").show_logs_buffer()
   ```

3. **Validierung:**
   ```vim
   :lua require("autocmds.patches").validate_all(function(r) vim.print(r) end)
   ```

4. **Manuelle Patch-Test:**
   ```bash
   patch --dry-run -p0 -i <patch-file> <target-file>
   ```
