
```lua
-- lua/plugins/klingon_notify.lua
---@type LazyPluginSpec
return {
  "stefanbartl/klingon_notify",                    -- oder "dir = '/path/to/klingon_notify'"
  dir = vim.fn.expand("~/path/to/klingon_notify"), -- für lokale Entwicklung
  event = "VeryLazy",
  config = function()
    require("klingon_notify").setup({
      mode = "float", -- "float" | "notify"
      use_icons = true,
      title = "tlhIngan",
      phrases = {
        -- Optional overrides per taste
        success = "Qapla'!",
        error   = "Qagh!",
        warn    = "yIqIm!",
        info    = "De'!",
      },
      float = {
        border = "rounded",
        timeout_ms = 1400,
        winblend = 10,
        title_pos = "left",
      },
    })
  end,
}
```

schnelltest

in Neovim:

:KlingonSuccess

:KlingonError „Parser failed at column 9“

:KlingonWarn „Low disk space“

:KlingonInfo „Build started“

notify-modus aktivieren:

in setup mode = "notify" setzen; bei installiertem rcarriga/nvim-notify wird dieses verwendet, sonst Fallback auf vim.notify.

hinweise zur umsetzung

„Close on any key“ wird über vim.on_key namespaced realisiert und beim Schließen wieder entfernt. Zusätzlich existieren Mappings für <Esc>, q, <CR>, <Space>.

Highlights verlinken standardmäßig auf Diagnostic*-Gruppen (kompatibel mit 0.9+). DiagnosticOk wird, falls nicht vorhanden, auf DiffAdd abgebildet.

Tabellen mit bekannter Länge werden bei Listen als ---@type string[] bzw. local list = { [n] = "" } angelegt; im PoC ist das bei den Float-Zeilen gezeigt.

Anpassbare Titel, Border, Transparenz und Timeout sind in float konfigurierbar.

optionale erweiterungen

Auto-Wrapping und dynamische Breite/Höhe anhand der verfügbaren Spalten mit Berücksichtigung von tabstop/conceallevel.

Adapter, der vim.notify global wrappt, um fremde Meldungen automatisch in klingonische Shouts zu transformieren.

LSP-/Diagnostics-Hooks: bei neuen Diagnostics automatisch warn/error-Shouts auslösen (mit Rate-Limiting).

Soundeffekte per externem CLI (z. B. paplay/afplay) mit optionaler Konfiguration.