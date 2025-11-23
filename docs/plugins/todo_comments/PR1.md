# PR 1

Pfad: `lazy\todo-comments.nvim\lua\todo-comments\highlight.lua`

## Fehlermeldung:

```sh
   Error  21:22:31 msg_show.lua_error Error executing vim.schedule lua callback: .../lazy/todo-comments.nvim/lua/todo-comments/highlight.lua:94: Invalid 'end_col': out of range
stack traceback:
	[C]: in function 'nvim_buf_set_extmark'
	.../lazy/todo-comments.nvim/lua/todo-comments/highlight.lua:94: in function 'add_highlight'
	.../lazy/todo-comments.nvim/lua/todo-comments/highlight.lua:246: in function 'highlight'
	.../lazy/todo-comments.nvim/lua/todo-comments/highlight.lua:155: in function 'fn'
	vim/_editor.lua:366: in function <vim/_editor.lua:365>
```

---

## Ursache / Kurzdiagnose

Der Crash tritt auf, weil `nvim_buf_set_extmark` ein ungültiges `end_col` erhält (größer als die Zeilenlänge oder negativ). Das kann passieren, wenn die Plugin-Logik `finish+1` oder `#line` verwendet, aber `finish` aus irgendeinem Grund außerhalb der tatsächlichen Zeilenlänge liegt (z. B. bei Multibyte-Zeichen, Race-Condition beim Scrollen, oder wenn `M.match` Positionen zurückgibt, die nicht korrekt normalisiert sind).

Drei mögliche Behebungsstrategien (nach Priorität und Aufwand)

---

## 1. Empfohlene langfristige Lösung (Plugin-Fix, upstream PR)

   * Im Plugin `add_highlight` vor dem Aufruf von `nvim_buf_set_extmark` die Spaltenwerte validieren / clampen:

     * `from = math.max(0, from)`
     * `to   = math.min(#line_text, to)`
     * Falls `from > to` dann skippen (kein extmark)
   * Zusätzlich defensiv prüfen, ob `from`/`to` Zahlen sind und `line` existiert.
   * Dieser Fix verhindert Out-of-range-Fehler robust und ist korrekt, weil extmarks immer innerhalb der Zeile liegen müssen.

   Beispiel-Patch (Diff-ähnlich — zur Einreichung als PR an das Plugin):

```diff
--- a/lua/todo-comments/highlight.lua
+++ b/lua/todo-comments/highlight.lua
@@
 local function add_highlight(buf, ns, hl, line, from, to)
-  vim.api.nvim_buf_set_extmark(buf, ns, line, from, {
-    end_col = to,
-    hl_group = hl,
-    priority = 500,
-  })
+  -- Defensive bounds checks: ensure from/to are within the actual line length.
+  local ok, text = pcall(vim.api.nvim_buf_get_lines, buf, line, line + 1, false)
+  if not ok or type(text) ~= "table" or text[1] == nil then
+    return
+  end
+  local line_text = text[1]
+  local max_col = #line_text
+  if type(from) ~= "number" or type(to) ~= "number" then
+    return
+  end
+  from = math.max(0, from)
+  to = math.min(max_col, to)
+  if from > to then
+    return
+  end
+  vim.api.nvim_buf_set_extmark(buf, ns, line, from, {
+    end_col = to,
+    hl_group = hl,
+    priority = 500,
+  })
 end
```

---

## 2. Sofort-Workaround in der eigenen Konfiguration (monkeypatch) — empfohlen als kurzfristige Lösung

   * Falls man nicht sofort upstream patchen möchte, kann man nach `todo.setup(opts)` in der eigenen `config.todo_comments.setup`-Datei die Export-Funktion `highlight` des Plugin-Moduls mit einer pcall-Wrapper ersetzen. Das verhindert den Crash (fängt Fehler ab) und loggt den Fehler, so dass Neovim nicht abstürzt beim Scrollen.

```lua
---@module 'config.todo_comments.setup'
-- Monkeypatch todo-comments' highlight method to guard against out-of-range extmarks.
-- This wrapper will catch runtime errors and avoid crashing the editor on scroll.
local M = {}

local todo_ok, todo = pcall(require, "todo-comments")
if not todo_ok then
  function M.setup(_) end
  return M
end

-- existing setup code omitted for brevity...
-- after calling todo.setup(opts) do the monkeypatch:

-- Protect highlight function to avoid 'Invalid end_col' fatal errors
local ok_hl, hl_mod = pcall(require, "todo-comments.highlight")
if ok_hl and type(hl_mod.highlight) == "function" then
  local orig_highlight = hl_mod.highlight
  hl_mod.highlight = function(buf, first, last, event)
    local ok, err = pcall(orig_highlight, buf, first, last, event)
    if not ok then
      -- Notify once for debugging and silently skip highlighting for this update.
      -- Use WARN level so it appears in :messages but doesn't spam too loudly.
      vim.schedule(function()
        vim.notify("todo-comments highlight error (suppressed): " .. tostring(err), vim.log.levels.WARN)
      end)
      -- best-effort fallback: clear namespace range so we don't leave stale extmarks
      pcall(vim.api.nvim_buf_clear_namespace, buf, require("todo-comments.config").ns, first, last + 1)
    end
  end
end

-- export setup as before
function M.setup(opts)
  -- original setup logic...
  todo.setup(opts)
  -- apply monkeypatch (code above) — ensure executed after todo.setup
end

return M
```

---

### Hinweise zur Monkeypatch-Variante

* Diese Lösung unterdrückt den Crash und informiert per Notification — sie behebt nicht die Ursache, ist aber sicher für den Alltag.
* Die Wrapper-Strategie hält die Plugin-Highlights am Laufen ohne Editor-Crash; sie ist nützlich, bis ein upstream-Fix integriert ist.

---

## 3. Konfigurations-Workaround (reduce risky highlight modes)

   * Manche Optionen (`keyword = "wide"`, `before`, `after`) erweitern das Highlight auf `finish+1` oder `#line`. Wenn das Problem erst seit der Maßnahme mit exaktem Pattern/`wide` auftritt, kann man temporär `keyword = nil`, `before = ""`, `after = ""` setzen. Das reduziert die Wahrscheinlichkeit, dass `end_col` über die Zeilenlänge hinausgeht.
   * Diese Variante ändert das visuelle Verhalten und ist weniger ideal als ein Bugfix.

---

## Konkrete Empfehlungen

* Kurzfristig: Monkeypatch in die `config.todo_comments.setup` einbauen (Variante 2). Damit verschwindet der Crash sofort.
* Mittelfristig: Ein minimaler upstream-Patch (Variante 1) ist sauber und sollte als PR eingereicht werden; darin die `add_highlight`-Validierung ergänzen. Das ist robust gegenüber allen Edgecases (multibyte, race conditions, falsche match-returns).
* Langfristig: Tests / Repro-Schritte dokumentieren und dem Plugin-Repo als Issue anhängen (inkl. Beispiel-Datei, in der das Verhalten beim Scrollen reproduzierbar ist).

Debug-Checks, die man jetzt ausführen kann

```vim
" 1) Zeige welchen Bereich highlight() bearbeiten wollte (in debug wrapper vor pcall einfügen)
:lua print(vim.inspect({buf=buf, first=first, last=last}))

" 2) Prüfe Zeilenlänge an problematischer Stelle:
:lua local lines = vim.api.nvim_buf_get_lines(0, <line>, <line>+1, false); print(#lines[1])

" 3) Test: manuell extmark setzen mit großen end_col um Neovim-Fehler zu reproduzieren:
:lua vim.api.nvim_buf_set_extmark(0, vim.api.nvim_create_namespace('tmp'), <line>, 0, { end_col = 9999 })
```

Abschließender Hinweis für PR

* In der PR-Beschreibung kurz die Ursache erklären (invalid end_col), den Patch zeigen (bounds checks) und ein kleines reproduzierbares Beispiel beilegen, falls möglich. Maintainer werden so schneller reviewen und mergen.

---
