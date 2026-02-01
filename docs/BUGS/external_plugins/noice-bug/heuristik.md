
Kurzantwort

• Deine Ausgabe bedeutet: lua\_ls triggert Signature-Help ausschließlich auf „(“ und „,“; es gibt keine separaten retriggerCharacters.
• Das passt exakt zu deinem Befund: „,“ löst zuverlässig aus.
• Zusätzlich triggert bei Noice häufig auch ein Leerzeichen nach „(“, weil Noice intern den letzten „nicht-Leerzeichen“-Char ermittelt (durch Trimmen) und dadurch weiterhin „(“ als letztes Zeichen „sieht“. Das verstärkt das Problem.

Einordnung bezogen auf den Bug

1. Warum „,“ alles triggert
   server\_capabilities.signatureHelpProvider.triggerCharacters = { "(", "," } heißt: Sobald direkt vor dem Cursor „(“ oder „,“ steht, wird Signature-Help angefragt. Viele Server liefern beim Komma entweder „leer“ oder wechselnde Antworten; genau dort entstehen die Fokus/Race-Probleme.

2. Warum Space nach „(“ (scheinbar) triggert
   In Noice wird das letzte Zeichen vor dem Cursor so bestimmt (vereinfacht):

* Text bis zum Cursor holen
* trimmen (Leerzeichen am Ende entfernen)
* letztes Zeichen nehmen

Ergebnis: Nach „(␣“ wird das Space weggetrimmt, übrig bleibt „(“ → erneuter Trigger, obwohl man „nur“ ein Leerzeichen getippt hat. Das erklärt dein „Space löst aus“.

3. „nil“ bei retriggerCharacters
   Es gibt keine zusätzliche Liste für Re-Trigger; Noice nutzt einfach weiterhin die obige Prüfung (und ggf. weitere Events) – bei dir reicht das, um immer wieder an „(“/„,“ zu hängen.

Sofort wirksame, gezielte Gegenmaßnahmen

A) „,“ als Trigger zur Laufzeit entfernen (nur für Signature-Help, nichts Globales)

```lua
---@module 'lsp.signature_triggers_sanitize'
--- Remove noisy trigger characters like ',' from signature help.

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("SigHelpTriggerSanitize", { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    local shp = client and client.server_capabilities and client.server_capabilities.signatureHelpProvider
    if not (shp and shp.triggerCharacters) then return end

    local keep = {}
    for _, ch in ipairs(shp.triggerCharacters) do
      if ch ~= "," then                    -- Entfernt nur das Komma
        table.insert(keep, ch)
      end
    end
    shp.triggerCharacters = keep

    -- Optional: Debug
    vim.notify(("Signature triggers for %s → [%s]"):format(client.name, table.concat(keep, ", ")), vim.log.levels.DEBUG)
  end,
})
```

Wirkung: „(“ triggert weiter, „,“ nicht mehr. Das nimmt deinem reproduzierbaren Problem den häufigsten Auslöser.

B) Noice-Heuristik reparieren: nicht mehr auf „letztes Nicht-Leerzeichen“, sondern wirklich auf das Zeichen vor dem Cursor schauen

```lua
---@module 'plugins.noice_signature_getchar_patch'
--- Patch Noice's signature get_char to NOT trim trailing spaces.

return {
  "folke/noice.nvim",
  config = function()
    local ok, Sig = pcall(require, "noice.lsp.signature")
    if not ok then return end

    -- Replace get_char with a version that reads the actual char before the cursor
    function Sig.get_char(buf)
      -- Use the window that shows 'buf' or current
      local curwin = vim.api.nvim_get_current_win()
      local win = (vim.api.nvim_win_get_buf(curwin) == buf) and curwin or vim.fn.bufwinid(buf)
      if win == -1 then win = 0 end

      local row, col = unpack(vim.api.nvim_win_get_cursor(win))  -- row 1-based, col 0-based
      row = row - 1
      local line = (vim.api.nvim_buf_get_lines(buf, row, row + 1, true)[1] or "")
      -- Char directly BEFORE the cursor; respects spaces and tabs
      if col <= 0 then return "" end
      return line:sub(col, col)
    end
  end,
}
```

Wirkung: Ein Space nach „(“ gilt nicht mehr als „(“. Damit verschwinden die unnötigen Retrigger auf Leerzeichen.

C) Optional: Insert-Mode bewahren (falls in seltenen Fällen noch ein Float kurz Fokus zieht)

```lua
---@module 'ui.insert_mode_guard_min'
--- Minimal guard to re-enter insert if we just typed and focus flipped.

local uv = vim.uv or vim.uv
local last_i = 0
local function now() return uv.now() end

vim.api.nvim_create_autocmd({ "InsertEnter", "InsertCharPre", "TextChangedI" }, {
  group = vim.api.nvim_create_augroup("InsertGuard", { clear = true }),
  callback = function() last_i = now() end,
})

vim.api.nvim_create_autocmd("ModeChanged", {
  group = vim.api.nvim_create_augroup("InsertGuardMode", { clear = true }),
  pattern = "i:*",
  callback = function()
    if (now() - last_i) > 250 then return end
    vim.defer_fn(function()
      local m = vim.api.nvim_get_mode().mode
      if not m:match("^i") then vim.cmd("startinsert") end
    end, 20)
  end,
})
```

Wirkung: Falls Neovim wegen eines Float-Fokus doch noch kurz von Insert → Normal kippt, wird sofort wieder Insert aktiviert.

Warum das alles zusammenpasst

• Deine Capability-Anzeige { "(", "," } erklärt, warum „,“ zuverlässig auslöst.
• Das Noice-Trimming erklärt, warum ein Space nach „(“ „wie (“ behandelt wird.
• Entfernt man „,“ und korrigiert `get_char`, verschwinden die (leeren) Zusatz-Trigger – dadurch sinkt die Chance auf den Fokus-Race, und der Insert-Modus bleibt stabil.
• Der kleine Guard sorgt dafür, dass auch letzte Timing-Kanten (wenn doch mal ein Float kurz Fokus bekommt) ohne sichtbaren Moduswechsel bleiben.

Verifikation

1. Nach A/B neu starten.
2. `:lua for _,c in ipairs(vim.lsp.get_clients({bufnr=0})) do local shp=c.server_capabilities.signatureHelpProvider; if shp then vim.print(c.name, shp.triggerCharacters) end end`
   → Erwartet: nur „(“ bei lua\_ls.
3. Beim Tippen „( “ sollte kein erneuter Trigger mehr auf das Space erfolgen.
4. „,“ innerhalb der Argumentliste triggert nicht mehr.
