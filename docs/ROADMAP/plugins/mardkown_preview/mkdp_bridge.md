# Aktualisiertes Konzept: mkdp_bridge (autoswitchless)

## 1. Kurzüberblick

Man kann das bestehende `mkdp_bridge`-Konzept so aktualisieren, dass das separate `mkdp_autoswitch`-Modul entfallen kann. Stattdessen nutzt man die eingebaute Fähigkeit von `iamcco/markdown-preview.nvim` (combine preview, auto refresh) zusammen mit minimalen Wrapper-Kommandos und einer bedingten Autocommand-Logik, um genau ein Preview-Fenster zu betreiben und es bei Bedarf zu aktualisieren. Die Bridge muss nur noch Neovim öffnen/springen und den Preview-Status über die Wrapper-Kommandos steuern.

---

## 2. Kernänderungen zum vorherigen Konzept

Man kann folgende Vereinfachungen und Änderungen vornehmen:

* Entfernen des separaten `mkdp_autoswitch`-Moduls; keine doppelte Autostart-/Autoswitch-Logik mehr.
* Handler ruft keine internen Autoswitch-APIs mehr auf, sondern steuert die Preview ausschließlich über die neu definierten Wrapper-Kommandos (`MarkdownPreviewWrapper`, `MarkdownPreviewStopWrapper`, `MarkdownPreviewToggleWrapper`).
* Server/Injector-Verhalten bleibt weitgehend gleich (lokaler HTTP-Server, JS-Injection), aber das Handler-Verhalten für das Öffnen von Dateien/Ankern ist schlanker und auf Sicherheit/Validierung fokussiert.
* Tests ersetzen direkte Module-Imports durch Assertionen, die den Wrapper-/plugin-Zustand prüfen.

---

## 3. Angepasste Modulstruktur

Man kann die Modulstruktur vereinfachen:

```
lua/
└─ config/
   └─ markdown_preview/
      ├─ init.lua                  -- behavior-only setup (wrapper commands + mkdp options)
      └─ mkdp_bridge/
         ├─ init.lua              -- entrypoint, starts server if enabled
         ├─ server.lua            -- minimal libuv HTTP listener (local-only)
         ├─ handler.lua           -- Öffnen von Dateien/Ankern; verwendet wrapper commands
         └─ injector.lua          -- JS snippet / injection helpers
```

---

## 4. Datenfluss (aktualisiert)

Man kann den Ablauf so beschreiben:

```text
Browser (Preview) --click--> JS snippet -> HTTP GET http://127.0.0.1:PORT/open?file=...&anchor=...
   ↓
Local HTTP Server (mkdp_bridge.server)
   ↓
handler.open_file(path, anchor)
   ↓
vim.cmd.edit(abs_path) / search(anchor)
   ↓
if preview not open -> call :MarkdownPreviewWrapper
if preview open and bridge wants refresh -> call :MarkdownPreviewToggleWrapper or :MarkdownPreview (silent)
```

---

## 5. Handler-Änderungen (konkretes Beispiel)

Man kann die Handler-Logik so implementieren, dass sie strikt validiert, lokalisiert und die Preview über Wrapper-Kommandos steuert. Unten ein Beispielmodul mit EmmyLua-Annotationen und englischen Kommentaren in den Kommentaren.

```lua
---@module 'config.markdown_preview.mkdp_bridge.handler'
--- Bridge request handler: validate path, open file, jump to anchor,
--- and ensure Markdown preview is started/updated via wrapper commands.

local M = {}

---@param rel_path string path from the browser (possibly relative)
---@param anchor string|nil anchor fragment (without '#')
---@return boolean ok, string|nil err
local function validate_and_resolve(rel_path, anchor)
  -- English comments: resolve to absolute path and validate against project root
  -- This helper returns (true, abs_path) on success or (false, errmsg) on failure.
  local abs = vim.fn.fnamemodify(rel_path or "", ":p")
  local project_root = vim.g.mkdp_bridge_project_root or vim.loop.cwd()
  if not abs or abs == "" then
    return false, "empty path"
  end
  -- ensure file is inside project_root
  if not abs:match("^" .. vim.pesc(project_root)) then
    return false, "outside project root"
  end
  if not vim.loop.fs_stat(abs) then
    return false, "file not found"
  end
  return true, abs
end

--- Open target file and optional anchor, then ensure preview is in the desired state.
--- English comments: main entrypoint used by server to handle GET /open.
---@param rel_path string
---@param anchor string|nil
function M.open_file(rel_path, anchor)
  local ok, res = validate_and_resolve(rel_path, anchor)
  if not ok then
    vim.notify("[mkdp_bridge] open_file failed: " .. (res or "unknown"), vim.log.levels.WARN)
    return
  end
  local abs = res

  -- Open the file in the current window/buffer.
  -- English comment: use edit to create or switch buffer; use bufload to avoid autocommands race.
  pcall(vim.cmd, ("edit %s"):format(vim.fn.fnameescape(abs)))

  -- Jump to anchor if provided.
  if anchor and #anchor > 0 then
    -- English comment: search for the anchor string; prefer exact-match of anchor id if possible.
    pcall(vim.cmd, "silent! normal! gg")
    pcall(vim.fn.search, anchor)
  end

  -- Ensure preview behavior via wrapper commands:
  -- English comment: If preview should auto-refresh on buffer change, ensure it's active.
  -- The wrapper commands manage M._preview_active flag in the config module.
  local preview_module_ok, _ = pcall(require, "config.markdown_preview")
  if preview_module_ok then
    -- If the user has explicitly activated the preview wrapper flag, refresh the preview.
    -- English comment: call user commands silently to avoid noisy output.
    if vim.api.nvim_get_var and pcall(vim.api.nvim_get_var, "mkdp_auto_refresh_via_wrapper") then
      pcall(vim.cmd, "silent! MarkdownPreview")
    else
      -- If preview is not running, start it via wrapper to set the internal flag.
      pcall(vim.cmd, "silent! MarkdownPreviewWrapper")
    end
  end
end

return M
```

---

## 6. Server / Injector (kleine Anpassungen)

Man kann die Server-Implementierung beibehalten, jedoch:

* Bind nur an `127.0.0.1`.
* Parse nur einfache GET-Requests `GET /open?file=...&anchor=...`.
* Sanitize URL-decoding mit `vim.fn.escape` / `vim.fn.fnameescape` und `vim.fn.url_decode` (oder manueller decoding routine).
* Implementiere optionalen Fallback-Port (0 → system assigned) wenn gewünschter Port belegt.
* Injector-JS bleibt minimal und verhindert remote-URLs (http/https) und Cross-origin-requests werden vom Browser blockiert, aber Fetch an localhost ist in den meisten Setups erlaubt.

Beispiel-JS (keine Änderungen notwendig gegenüber ursprünglichem Snippet, nur robustere URL-encoding empfohlen).

---

## 7. Setup / Konfiguration (empfohlen)

Man kann die Konfiguration in `config.markdown_preview.init` als behavior-only behalten; exemplarisch:

* `vim.g.mkdp_auto_start = 1`
* `vim.g.mkdp_auto_close = 0`
* `vim.g.mkdp_combine_preview = 1`
* `vim.g.mkdp_combine_preview_auto_refresh = 1`
* Wrapper-Kommandos: `MarkdownPreviewWrapper`, `MarkdownPreviewStopWrapper`, `MarkdownPreviewToggleWrapper` wie bereits implementiert.
* Neuer optionaler globaler: `vim.g.mkdp_bridge_project_root` oder in setup-opts `bridge_project_root`.

Beispiel-Aufruf im zentralen Setup:

```lua
require("config.markdown_preview").setup{
  enable_bridge = true,
  bridge_port = 9876,
  bridge_project_root = vim.fn.getcwd(),
}
```

---

## 8. Tests & CI (angepasst)

Man kann Tests vereinfachen:

* `tools/_test_bridge.lua` ruft `curl 'http://127.0.0.1:PORT/open?file=README.md#intro'`.
* Assertions prüfen: `vim.fn.expand("%:t") == "README.md"` und `vim.fn.search("intro") > 0`.
* Zusätzliche Tests prüfen, dass Wrapper-Kommandos existieren und dass `mkdp_combine_preview` gesetzt ist.
* CI-Hook prüft: kein `_G`-State, pcall-Schutz bei I/O, Port-Fallback, und server bind auf 127.0.0.1.

---

## 9. Sicherheit & Hardening (konkret)

Man kann folgende Maßnahmen standardmäßig einbauen:

* Bind an `127.0.0.1` only.
* Pfad-Whitelist: nur Dateien unter `bridge_project_root` zulassen.
* Limit request size / only accept small GET lines.
* Keine Ausführung von Shell-Befehlen; nur `vim`-APIs und `pcall`-geschützte I/O.
* Optional: Token-Query-Param für lokale Härtung (`?t=...`) falls Port öffentlich wird (nicht empfohlen als primärer Schutz).

---

## 10. Risiken und Mitigations (aktualisiert)

Man kann die Risiken wie folgt adressieren:

* Port-Kollision → Fallback auf dynamischen Port und informative Notification.
* Plugin-HTML-Layout-Änderung → Injector sollte idempotent sein: suche `<head>`/`</body>` und injiziere nur wenn Snippet nicht bereits vorhanden (z. B. Query-Suffix).
* Browser-Security → Dokumentation hinzufügen, dass lokale fetch an 127.0.0.1 in einigen Browser/OS-Setups beschränkt sein kann.
* Pfad-Manipulation → vollständige Pfad-Normalisierung und strenge Projekt-Root-Matching.

---

## 11. Checkliste (konkret, nur die geänderten Punkte markiert)

Man kann die Checkliste so aktualisieren (✓ bedeutet empfohlen):

| Check                                     | Status/Kommentar |
| ----------------------------------------- | ---------------- |
| @module, @param, @return in allen Dateien | ✓                |
| Kein _G-State                             | ✓                |
| Nur `localhost`-Binding                   | ✓                |
| Pfad-Validierung vorhanden                | ✓                |
| Fehlerbehandlung via pcall                | ✓                |
| Tests unter `tools/_test_bridge.lua`      | ✓ (updated)      |
| Optionales Logging (`bridge.debug`)       | optional         |
| HTML-Injection idempotent und überprüft   | ✓                |
| Kein Bedarf für `mkdp_autoswitch`-Modul   | ✓ (removed)      |

---

## 12. Migrationsempfehlungen

Man kann schrittweise migrieren:

1. Aktivieren der neuen `config.markdown_preview`-Setup mit Wrapper-Kommandos (wie bereits vorhanden).
2. Deaktivieren oder Entfernen des alten `mkdp_autoswitch`-Moduls aus der Runtime (bevorzugt: feature-flag `enable_old_autoswitch = false`).
3. Deploy `mkdp_bridge`-server + handler, aber initial im "log-only" Modus (nur Notifications) laufen lassen, um false-positives zu erkennen.
4. Nach Verifikation `open_file`-Workflow aktivieren und CI-Tests laufen lassen.

---

## Literatur

* iamcco/markdown-preview.nvim – Source
* Neovim luv/libuv examples for minimal servers
* mhinz/neovim-remote (nvr) als optionaler alternativer Ansatz

---
