# Patch: noice.nvim LSP Signature Guards

## Problem
Die originale `noice.nvim/lsp/signature.lua` hat mehrere Probleme:
1. Auto-Open der Signaturen bei TriggerCharacters ist nicht zuverlässig.
2. Buffers werden nicht korrekt geprüft auf Gültigkeit.
3. Typinformationen und Debounce-Handling fehlen teilweise.
4. LuaSnip- und Insert-Mode Trigger sind nicht sauber implementiert.

## Lösung
Ersetzt die Originaldatei durch die gefixte Version `signature_FIXED.lua`, die:
- Typinformationen für SignatureHelp, SignatureInformation, ParameterInformation nutzt.
- Debounce korrekt für Auto-Open implementiert.
- Auto-Open Trigger für Luasnip, InsertMode und Snippets sauber anlegt.
- Buffer- und TriggerChar-Guards verwendet.
- Nachrichtendarstellung (`Docs`, `NoiceText`, `Format`) korrekt handhabt.

## Dateien
- Original: `noice.nvim/lua/noice/lsp/signature.lua`
- Fixed: `patches/nvchad/ui/signature_FIXED.lua`

## Hinweise
- Patch ersetzt direkt die Originaldatei.
- Bei Plugin-Updates kann die Fixed-Version wiederhergestellt werden.
- Debounce-Werte kommen aus der NvChad Config (`Config.options.lsp.signature.auto_open.throttle`).
```

---

**Datei:** `patches/nvchad/ui/noice-ui-lsp-signature-guards.patch`

```diff
*** Original
--- noice.nvim/lua/noice/lsp/signature.lua
+++ Fixed
@@
- (kompletter Originalinhalt der alten signature.lua)
+ (kompletter Inhalt der signature_FIXED.lua)
```

---
