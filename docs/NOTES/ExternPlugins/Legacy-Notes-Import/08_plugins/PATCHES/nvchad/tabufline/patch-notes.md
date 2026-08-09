# nvchad/ui – tabufline: Konsolidierung der lokalen Fixes gegenüber Upstream

## Table of content

  - [1. Gesamtbild](#1-gesamtbild)
  - [2. Bewertung pro Datei](#2-bewertung-pro-datei)
    - [ui/lua/nvchad/tabufline/init.lua](#uiluanvchadtabuflineinitlua)
    - [ui/lua/nvchad/tabufline/lazyload.lua](#uiluanvchadtabuflinelazyloadlua)
  - [3. Patch 3: tabufline/init.lua (notwendig)](#3-patch-3-tabuflineinitlua-notwendig)
  - [4. Patch 4: tabufline/lazyload.lua (optional, defensiv)](#4-patch-4-tabuflinelazyloadlua-optional-defensiv)
  - [5. Zusammengefasst](#5-zusammengefasst)

---

## 1. Gesamtbild

Bei `tabufline` liegen **zwei Klassen von Problemen** vor:

1. **Race-Conditions & stale buffer IDs**

   * ungültige Buffer bleiben in `vim.t.bufs`
   * spätere Operationen (`b`, `bw`, `bufwinid`, `buf_get_name`) crashen

2. **Fehlende Validierungen an Übergängen**

   * Annahme, dass Einträge in `vim.t.bufs` immer gültig sind
   * Annahme, dass `bufs[1]` existiert und gültig ist

Upstream hat **einen Teil der Fixes übernommen** (lazyload.lua), aber:

* `init.lua` ist upstream weiterhin **ungehärtet**
* `lazyload.lua` ist **teilweise**, aber noch nicht vollständig defensiv

Deine gefixte Version ist technisch korrekt und konsistent mit dem, was bereits bei `lsp.signature` gemacht wurde.

---

## 2. Bewertung pro Datei

---

### ui/lua/nvchad/tabufline/init.lua

---

Upstream-Status:

* keinerlei `nvim_buf_is_valid`-Guards
* vertraut blind auf `vim.t.bufs`
* fehleranfällig bei:

  * Preview-Buffern
  * LSP-Fenstern
  * schnellen `bw` / `bd`

Deine Fixes:

* Guard beim Einstieg von `close_buffer`
* Entfernung invalider Buffer aus `vim.t.bufs`
* Validierung von Ziel-Buffer beim Umschalten
* Fallback auf ersten validen Buffer
* Validierung temporärer Buffer bei unlisted cases

Status:

* **Upstream enthält davon nichts**
* Patch ist notwendig und sauber

---

### ui/lua/nvchad/tabufline/lazyload.lua

---

Upstream-Status (neu):

* Guard für `bufs[1]` + `nvim_buf_is_valid`
* damit kein Crash mehr bei `buf_get_name`

Noch offen:

* `vim.t.bufs` kann invalide Einträge enthalten
* keine periodische Bereinigung
* keine Validierung in `BufDelete`-Iteration

Status:

* Upstream-Fix ist korrekt, aber minimal
* kein Konflikt mit zusätzlichen Guards

---

## 3. Patch 3: tabufline/init.lua (notwendig)

Pfad:

```
~/.config/nvim/patches/nvchad-ui-tabufline-init-buffer-guards.patch
```

Inhalt:

```diff
diff --git a/lua/nvchad/tabufline/init.lua b/lua/nvchad/tabufline/init.lua
index upstream..patched 100644
--- a/lua/nvchad/tabufline/init.lua
+++ b/lua/nvchad/tabufline/init.lua
@@
 M.close_buffer = function(bufnr)
   bufnr = bufnr or cur_buf()
+
+  -- Guard: buffer may be invalid but still tracked
+  if not api.nvim_buf_is_valid(bufnr) then
+    local index = buf_index(bufnr)
+    if index then
+      table.remove(vim.t.bufs, index)
+      vim.cmd "redrawtabline"
+    end
+    return
+  end
@@
     elseif curBufIndex and #vim.t.bufs > 1 then
       local newBufIndex = curBufIndex == #vim.t.bufs and -1 or 1
-      vim.cmd("b" .. vim.t.bufs[curBufIndex + newBufIndex])
+      local targetBuf = vim.t.bufs[curBufIndex + newBufIndex]
+
+      if api.nvim_buf_is_valid(targetBuf) then
+        vim.cmd("b" .. targetBuf)
+      else
+        for _, buf in ipairs(vim.t.bufs) do
+          if buf ~= bufnr and api.nvim_buf_is_valid(buf) then
+            vim.cmd("b" .. buf)
+            break
+          end
+        end
+      end
@@
     elseif not vim.bo.buflisted then
       local tmpbufnr = vim.t.bufs[1]
-      if tmpbufnr then
+      if tmpbufnr and api.nvim_buf_is_valid(tmpbufnr) then
         local winid = vim.fn.bufwinid(tmpbufnr)
         winid = winid ~= -1 and winid or 0
         api.nvim_set_current_win(winid)
```

Eigenschaften:

* additive Guards
* keine semantische Änderung im Erfolgsfall
* verhindert alle bekannten Crashpfade

---

## 4. Patch 4: tabufline/lazyload.lua (optional, defensiv)

Dieser Patch ist **optional**, aber konsistent mit deiner Linie.

Pfad:

```
~/.config/nvim/patches/nvchad-ui-tabufline-lazyload-buffer-sanitize.patch
```

Inhalt:

```diff
diff --git a/lua/nvchad/tabufline/lazyload.lua b/lua/nvchad/tabufline/lazyload.lua
index upstream..patched 100644
--- a/lua/nvchad/tabufline/lazyload.lua
+++ b/lua/nvchad/tabufline/lazyload.lua
@@
   callback = function(args)
     local bufs = vim.t.bufs
     local is_curbuf = cur_buf() == args.buf
+
+    -- sanitize buffer list
+    if bufs then
+      for i = #bufs, 1, -1 do
+        if not api.nvim_buf_is_valid(bufs[i]) then
+          table.remove(bufs, i)
+        end
+      end
+    end
```

Nutzen:

* verhindert schleichende Verschmutzung von `vim.t.bufs`
* reduziert Folgefehler in `init.lua`
* konfliktfrei mit Upstream

---

## 5. Zusammengefasst

* `vim.t.bufs` ist kein garantiert valider Zustand
* Preview- und temporäre Buffer werden von Neovim asynchron invalidiert
* tabufline arbeitet tab-lokal, aber buffer-global → Race-Gefahr
* Fixes härten ausschließlich Übergänge ab
* `init.lua`: Patch **erforderlich**
* `lazyload.lua`: Patch **empfohlen**, aber optional
* Fixes sind:
  * upstream-kompatibel
  * minimal-invasiv
  * konsistent mit bereits akzeptierten NvChad-Fixes

---
