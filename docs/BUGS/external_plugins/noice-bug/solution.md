Hier ist eine minimal-invasive Fassung von `M.on_signature`, die den Fokuswechsel an der Wurzel verhindert. Sie entfernt ausschließlich den programmatischen Fokusversuch über `message:focus()` und zeigt/aktualisiert die Signatur weiterhin – die View-Einstellungen (`enter = false`, `focusable = false`) werden dann zuverlässig respektiert.

```lua
---@param err any
---@param result SignatureHelp
---@param ctx { bufnr: integer }
---@param config table|nil
function M.on_signature(err, result, ctx, config)
  -- Keep behavior compatible with existing call sites
  config = config or {}

  -- If there is no payload, only notify on explicit (non-auto) triggers.
  if not (result and result.signatures and #result.signatures > 0) then
    if not config.trigger then
      vim.notify("No signature help available")
    end
    return
  end

  -- Obtain (or create) the signature Docs message buffer/window.
  local message = Docs.get("signature")

  -- IMPORTANT: Do NOT try to focus the message programmatically.
  -- The previous code path used `message:focus()` here, which may cause the
  -- signature view to become the current window briefly, leading to a mode/focus flip.
  -- We simply (re)render and show the message without any focus attempt.

  -- Provide filetype & message to the formatter
  result.ft = vim.bo[ctx.bufnr].filetype
  result.message = message

  -- Format the incoming LSP SignatureHelp into the Docs message
  M.new(result):format()

  -- If formatting produced no visible content, only notify on explicit triggers.
  if message:is_empty() then
    if not config.trigger then
      vim.notify("No signature help available")
    end
    return
  end

  -- Show/update the signature message. Views configured with `enter=false` and
  -- `focusable=false` will keep the user's focus in the edit window.
  -- `config.stay` semantics remain unchanged.
  Docs.show(message, config.stay)
end
```

Optional als Unified-Diff (zur leichteren Review-Nachvollziehbarkeit):

```diff
diff --git a/lua/noice/lsp/signature.lua b/lua/noice/lsp/signature.lua
--- a/lua/noice/lsp/signature.lua
+++ b/lua/noice/lsp/signature.lua
@@ -1,21 +1,27 @@
 ---@param result SignatureHelp
 function M.on_signature(_, result, ctx, config)
-  config = config or {}
-  if not (result and result.signatures) then
-    if not config.trigger then
-      vim.notify("No signature help available")
-    end
-    return
-  end
+  -- Keep behavior compatible with existing call sites
+  config = config or {}
+  if not (result and result.signatures and #result.signatures > 0) then
+    if not config.trigger then
+      vim.notify("No signature help available")
+    end
+    return
+  end

   local message = Docs.get("signature")

  if config.trigger or not message:focus() then
    result.ft = vim.bo[ctx.bufnr].filetype
    result.message = message
    M.new(result):format()
    if message:is_empty() then
      if not config.trigger then
        vim.notify("No signature help available")
      end
      return
    end
    Docs.show(message, config.stay)
  end
  -- IMPORTANT: do not programmatically focus the message.
  -- We simply (re)render and show it; view options control focus behavior.
  result.ft = vim.bo[ctx.bufnr].filetype
  result.message = message
  M.new(result):format()

  if message:is_empty() then
    if not config.trigger then
      vim.notify("No signature help available")
    end
    return
  end

  -- Show/update without stealing focus; respects `enter=false`/`focusable=false`
  Docs.show(message, config.stay)
 end
```

Anmerkungen für das PR-Description-Feld
• Funktionalität bleibt erhalten: Auto-Open und Aktualisierung der Signatur laufen weiter.
• Der Fokus wird nicht mehr programmgesteuert auf den Signatur-View gesetzt; dadurch gibt es keinen „Fokusdiebstahl“ mehr, selbst wenn Views korrekt mit `enter=false`/`focusable=false` konfiguriert sind.
• Optional kann man in einem separaten Commit noch die Heuristik für das „Zeichen vor dem Cursor“ anpassen (kein Trimmen von Spaces) und/oder besonders laute Trigger wie `,` zur Laufzeit aus der Auto-Open-Liste filtern; das ist aber unabhängig von diesem Kernfix.
