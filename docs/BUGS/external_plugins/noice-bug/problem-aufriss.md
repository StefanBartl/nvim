# Kernaussage

Das Problem liegt nicht „im LSP von Neovim“ und auch nicht (primär) am Insert-Mode, sondern im Signatur-Renderpfad von Noice selbst: Beim Aktualisieren/Zeigen der Signatur benutzt Noice den vorhandenen Docs-Message-View und ruft dabei einen Fokuspfad auf (konkret über `message:focus()` in `on_signature`). Dieser Aufruf kann den aktuellen Fensterfokus kurzzeitig auf das Signatur-Float verschieben. Das passiert unabhängig davon, ob der Ziel-View mit `enter=false` und `focusable=false` konfiguriert ist, denn diese Flags verhindern lediglich Benutzereingabe-Fokus, aber nicht, dass ein Plugin programmatisch per `nvim_set_current_win()` den Fokus wechselt. Ergebnis: Fokus springt ins Signatur-Fenster; ist die Antwort leer, sieht man das Float oft gar nicht – der Fokuswechsel hat aber bereits stattgefunden.

Zusätzlich verstärkend wirken zwei Faktoren:
• `triggerCharacters` des Servers enthalten bei `lua_ls` „(“ und „,“; das „,“ triggert häufig „leere“ Antworten.
• Die Noice-Heuristik für „letztes Zeichen vor dem Cursor“ behandelt ein Space nach „(“ oft weiterhin als „(“ (Retrigger).

# Konsequente Einordnung

• Verursacher: Noice-Signaturpfad (Kombination aus Auto-Open-Triggern und einem Fokusversuch im Docs-Flow).
• Nicht die Ursache: LSP-Capabilities an sich, Neovims LSP-Client, Insert-Mode.
• Warum `enter=false`/`focusable=false` nicht reichen: Sie verhindern Benutzereingaben in das Float, aber nicht, dass Code den Fokus kurz umsetzt.

# Minimal-invasiver Fix „an der Wurzel“

Ziel: Signatur aktiv lassen, aber jeglichen Fokusversuch im Signatur-Pfad unterbinden.

1. `on_signature` so patchen, dass `message:focus()` nicht mehr aufgerufen wird und die Anzeige ohne Fokusnahme erfolgt.
2. Optional: „,“ als Trigger zur Laufzeit entfernen, um „leere“ Retrigger zu eliminieren.
3. Optional: `get_char` so patchen, dass Spaces nicht „weggetrimmt“ werden (kein Retrigger nach „(␣“).

Nachfolgend ein lauffähiges Override, das ausschließlich Noice’ Signatur-Pfad beruhigt. Es lässt die Signatur aktiv, aber verhindert Fokus-Sprünge – selbst wenn Views auf `focusable=false` stehen.

```lua
---@module 'plugins.noice_signature_root_fix'
--- Keep Noice's LSP signature help active without stealing focus.

---@type LazyPluginSpec
return {
  "folke/noice.nvim",
  -- 1) Views/Routing optional (schadet nicht), Kernfix kommt im config-Block
  opts = function(_, opts)
    opts = opts or {}
    opts.views = vim.tbl_deep_extend("force", {
      sig_nofocus = {
        backend = "popup",
        enter = false,        -- never move focus into the popup
        focusable = false,    -- not focusable at all
        border = { style = "rounded" },
        win_options = {
          winblend = 0,
          number = false, relativenumber = false,
          cursorline = false, signcolumn = "no", foldcolumn = "0",
        },
      },
    }, opts.views or {})
    opts.routes = opts.routes or {}
    table.insert(opts.routes, {
      filter = { event = "lsp", kind = "signature" },
      view = "sig_nofocus",
    })
    return opts
  end,

  config = function(_, opts)
    require("noice").setup(opts)

    -- 2) Root-Fix: on_signature ohne message:focus()
    local okSig, Sig = pcall(require, "noice.lsp.signature")
    local okDocs, Docs = pcall(require, "noice.lsp.docs")
    local okUtil, Util = pcall(require, "noice.util")
    if not (okSig and okDocs and okUtil) then
      vim.notify("noice signature patch: internals unavailable", vim.log.levels.WARN)
      return
    end

    local ctor = Sig.new

    --- Override: do NOT call message:focus(); never programmatically focus the float.
    ---@param err any
    ---@param result any
    ---@param ctx { bufnr: integer }
    ---@param config table|nil
    Sig.on_signature = Util.protect(function(err, result, ctx, config)
      config = config or {}
      if not (result and result.signatures) then
        -- no spam on auto triggers; silently ignore empty results
        return
      end

      local message = Docs.get("signature")

      -- No message:focus() here on purpose.
      result.ft = vim.bo[ctx.bufnr].filetype
      result.message = message
      ctor(result):format()

      if message:is_empty() then
        return
      end

      -- Show/update without focus; the routed view 'sig_nofocus' has enter=false/focusable=false.
      Docs.show(message, config.stay)
    end)

    -- 3) Optional: remove ',' from triggerCharacters at runtime (cuts empty retriggers)
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("NoiceSig_TrimComma", { clear = true }),
      callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data and args.data.client_id or -1)
        local shp = client and client.server_capabilities and client.server_capabilities.signatureHelpProvider
        if not (shp and shp.triggerCharacters) then return end
        local keep = {}
        for _, ch in ipairs(shp.triggerCharacters) do
          if ch ~= "," then table.insert(keep, ch) end
        end
        shp.triggerCharacters = keep
      end,
    })

    -- 4) Optional: stricteres get_char (kein Trim von Spaces nach '(')
    local okSig2, Sig2 = pcall(require, "noice.lsp.signature")
    if okSig2 then
      function Sig2.get_char(buf)
        local curwin = vim.api.nvim_get_current_win()
        local win = (vim.api.nvim_win_get_buf(curwin) == buf) and curwin or vim.fn.bufwinid(buf)
        if win == -1 then win = 0 end
        local row, col = unpack(vim.api.nvim_win_get_cursor(win))
        row = row - 1
        if col <= 0 then return "" end
        local line = (vim.api.nvim_buf_get_lines(buf, row, row + 1, true)[1] or "")
        return line:sub(col, col)    -- exact char before cursor, spaces included
      end
    end
  end,
}
```

Erläuterung zum Patch
• Kernpunkt ist das Entfernen von `message:focus()` in `on_signature`. Genau dort entsteht der programmatische Fokuswechsel, der `focusable=false` umgeht.
• Der View bleibt explizit `enter=false/focusable=false`, damit auch kein späterer Fokuswechsel erfolgen kann.
• Das optionale Entfernen von „,“ reduziert leere/unnötige Retrigger; das optionale `get_char` verhindert Space-Retrigger nach „(␣)“. Beides senkt die Wahrscheinlichkeit, überhaupt in die kritische Code-Stelle zu geraten.

Verifikation

1. Neovim neu starten, nur Noice+LSP aktiv lassen.
2. In Lua in Klammern tippen; Signatur erscheint, der Fokus bleibt im Edit-Fenster.
3. `,` innerhalb der Parameterliste triggert nicht mehr (falls das Trimmen aktiv ist).
4. Keine Fokus- oder Modus-Sprünge mehr, selbst wenn die Signatur leer wäre.

Kurz: Das Problem ist Noice-intern im Signatur-Flow; „focusable=false“ reicht nicht, solange irgendwo im Pfad programmatisch fokussiert wird. Der obige Patch unterbindet genau diesen Schritt und lässt die Funktionalität ansonsten unangetastet.

Kurzantwort
Das Problem sitzt hauptsächlich im Zusammenspiel aus Noice-Signatur-Auto-Open und Neovims Fokus/Modus-Semantik, verschärft durch die Triggerliste des Servers (bei lua\_ls: „(“, „,“). Es ist kein genereller Fehler der LSP-Schnittstelle in Neovim, sondern eine UX-Kante in Noice’ Signaturpfad: zu aggressive/fehleranfällige Trigger + ein Fokusversuch im Signatur-Code führen dazu, dass Neovim kurz den Float als aktives Fenster behandelt und dadurch den Insert-Modus verlässt.

Ausführliche Einordnung

1. Beteiligte Komponenten
   • LSP-Server (lua\_ls): liefert `triggerCharacters = { "(", "," }`.
   • Noice LSP signature auto\_open: registriert Autocmds (TextChangedI/InsertEnter …), prüft das Zeichen vor dem Cursor und fordert Signature Help an.
   • Noice Darstellung: baut ein `Docs`-Message-Objekt und zeigt es in einem Popup-View.
   • Neovim: wechselt in den Normalmodus, sobald der Fokus in ein nicht-insert-fähiges Floatfenster wechselt – selbst wenn das nur sehr kurz passiert.

2. Was passiert in problematischen Situationen
   • Innerhalb der Klammern löst „,“ zuverlässig aus; oft liefert der Server darauf sehr wenig oder gar nichts.
   • Zusätzlich wird nach „( “ häufig trotzdem getriggert, weil die Implementation des „Zeichen vor Cursor“ in Noice das nachfolgende Leerzeichen ausblendet und wieder „(“ „sieht“.
   • Beim Anzeigen/Aktualisieren der Signatur versucht Noice, ein bestehendes Message-Fenster zu „fokussieren“ bzw. dessen Präsenz zu prüfen; an genau dieser Stelle kann der Fokus des Editorfensters transient auf den Float kippen.
   • Ergebnis: Insert-Modus bricht ab, der Cursor scheint „ins Popup zu springen“. Selbst wenn der Float per View-Optionen `enter=false`/`focusable=false` geöffnet werden soll, kann der Moduswechsel bereits vorher passiert sein.

3. Warum die üblichen Tweaks nicht zuverlässig helfen
   • `enter = false`/`focusable = false` wirken erst auf der Ebene des fertigen Popup-Fensters. Wenn davor ein Fokusversuch stattfindet (z. B. Re-Fokus auf ein bestehendes Docs-Fenster), ist der Modus bereits weg.
   • Eigener View + Route ändert den Render-Ort, aber nicht die Auslöselogik und auch nicht den Fokusversuch.
   • Handler-Overrides greifen in neueren Neovim-Versionen nur begrenzt, weil Noice selbst den Renderpfad kapselt.

4. Warum gerade „,“ so wichtig ist
   • „,“ ist ein offizieller Trigger von lua\_ls, aber in vielen Signatur-Kontexten liefert der Server darauf wenig/leer. Leere/wechselnde Antworten erhöhen die Chance auf Race-Conditions im Anzeigepfad.
   • Entfernt man „,“ aus den Triggern zur Laufzeit, verschwinden viele der „leeren“ Aufrufe, das System bleibt ruhiger, und der Fokusflipper tritt seltener auf. Das erklärt, warum dein reproduzierbarer „Komma-Fall“ der Schlüssel ist.

5. Warum dein Guard das leere Fenster „unterdrückt“, aber der Modus dennoch kippt
   • Der Guard verhindert, dass der Float den Fokus behält, und damit sieht man das Fenster nicht mehr oder nur noch flüchtig.
   • Der Moduswechsel ist jedoch schon beim ersten, ganz kurzen Fokuswechsel passiert; ohne ein gezieltes anschließendes `startinsert` bleibt man im Normalmodus. Daher „kein Fokusklau mehr sichtbar, aber Modus ist weg“.

6. Verantwortlichkeit nach Schichten
   • Neovim LSP/Capabilities: korrekt; das Verhalten ist by-design (Trigger-Zeichen liefert der Server).
   • LSP-Server (lua\_ls): ebenfalls korrekt; „,“ als Trigger ist erlaubt, aber UX-mäßig rau.
   • Noice: hier liegt die UX-Ursache. Zwei Punkte sind kritisch:
   – Heuristik für das „letzte Zeichen“ (Trimmen von Leerzeichen führt zu übermäßigem Triggern nach „( “).
   – Ein Fokusversuch im Signatur-Anzeigepfad (z. B. beim Re-Benutzen eines bestehenden Docs-Fensters).
   • Externe Plugins: können das Timing verschärfen, sind aber nicht die Hauptursache.

7. Ort einer nachhaltigen Korrektur
   • In Noice’ Signatur-Pfad:
   – Trigger-Heuristik konservativer gestalten (kein Trimmen am rechten Rand; wirklich das Zeichen direkt vor dem Cursor prüfen).
   – Auf jegliche Fokusnahme im Signature-Anzeigepfad verzichten, insbesondere keine impliziten `:focus()`-Versuche bei Auto-Open.
   – Sicherstellen, dass beim Aktualisieren einer bestehenden Signatur nie ein `set_current_win`-Pfad erreicht wird.
   • Ergänzend: Zur Laufzeit „,“ aus `triggerCharacters` entfernen oder als „retrigger only“ behandeln.

8. Praktisch belastbare Workarounds bis zu einem Upstream-Fix
   • „,“ aus den Triggern filtern (nur zur Laufzeit, pro Client/Buffer) und die Noice-„get\_char“-Heuristik so patchen, dass Spaces nicht getrimmt werden.
   • Optionaler Mode-Guard, der innerhalb eines sehr kurzen Fensters nach Insert-Aktivität automatisch in den Insert-Modus zurückkehrt, falls es doch zum Modus-Flip kam.
   • Noice-Patch, der den Signatur-Anzeigepfad ohne Fokusversuch ausführt.

Fazit
Man sollte das Problem als Noice-seitige UX-Regression im Signature-Auto-Open betrachten, die durch serverseitige Trigger („,“) begünstigt wird und durch Neovims legitimes „Mode-wechsel-bei-Fokuswechsel“ sichtbar wird. Der saubere Fix liegt im Noice-Signaturpfad: keine Fokusnahme bei Auto-Open und präzisere Trigger-Erkennung.

