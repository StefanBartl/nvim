DocMap coverage confirmed working (31 projects, `nvim-config` resolves correctly). Now let me write up the telemetry concept as requested — including the placement subtlety I found while investigating.

Hier das Konzept — DocMap-Teil ist bereits umgesetzt und verifiziert (31 Projekte, `nvim-config` korrekt aufgelöst), für Telemetrie folgt unten der Entwurf statt Code, wie gewünscht.

## Teil A: Baseline-Telemetrie für die Config (rein config-seitig, kein Plugin-Change)

**Der Haken, den ich beim Durchdenken gefunden habe:** `runtime-analysis.nvim` ist `lazy = false` und lädt in `init.lua` Zeile 59–80, *während* `require("lazy").setup(...)` noch läuft — zu diesem Zeitpunkt ist praktisch **nichts** vom Rest der Config geladen. Die eigentlichen Module (`options`, `autocmds`, `lsp`, …) laufen erst danach über `startup.now(...)`, und `bindings.usrcmds`/`bindings.mappings` sogar erst asynchron bei `startup.on("UIReady", ...)`. Ein `wrap_loaded()`-Aufruf im Plugin-`config()` selbst würde also fast nichts erfassen.

**Richtige Platzierung:** ein eigener, letzter `startup.on("UIReady", ...)`-Block, registriert *nach* der `mappings`-Phase (nach Zeile 196):

```lua
startup.on("UIReady", "telemetry_self", function()
  local telemetry = require("runtime-analysis.telemetry")
  local t = telemetry.new({ namespace = "nvim-config" })
  for _, prefix in ipairs({
    "config", "bindings", "plugins", "autocmds", "lsp",
    "startup", "themes", "machine", "nvchad", "wkdnvchad", "wkdoptions",
  }) do
    t.wrap_loaded(prefix, { module_filter = telemetry.default_module_filter })
  end
  t.start({ profile_args = true })
end)
```

Taucht danach automatisch auf in `:RATelemetry`, `StartAll/StopAll/ResetAll`, `coverage`, `compare`, `snapshot`, Export, HTML-Dashboard — **nur nicht** in `SetupAll`/`SetupAllFull` (Teil B). Derselbe Blind-Spot wie bei echten Plugins bleibt: eine erst später nachgeladene `bindings/mappings/*`-Funktion (z. B. bei erstem Tastendruck) ist ab diesem Zeitpunkt für immer ungewrapped, bis der Wrap manuell erneut läuft.

## Teil B: `SetupAll`/`SetupAllFull`-Unterstützung (echte runtime-analysis.nvim-Erweiterung — nur Konzept)

Neues optionales Feld an `RA.Telemetry.LazyOpts`:

```lua
---@field extra? RA.Telemetry.LazyExtraTarget[]

---@class RA.Telemetry.LazyExtraTarget
---@field namespace string
---@field mains string[]        -- mehrere Root-Prefixe, direkt vom Aufrufer bekannt -- kein lazy.core.loader-Lookup nötig
---@field profile_args? boolean
---@field timing? boolean
---@field persist? boolean
---@field dir? string
```

`telemetry.lazy.candidates()` würde die `extra`-Liste zusätzlich zur lazy.nvim-Auflösung durchlaufen (ein `mains`-Eintrag gilt als "geladen", sobald *irgendeiner* der Prefixe in `package.loaded` auftaucht).

**Der eine echte Bruch:** `RA.Telemetry.SetupAllCandidate.main` ist heute `string` (ein Plugin = ein Root-Modul). Für mehrere Prefixe müsste das zu `string|string[]` werden, und `setup_all.lua`s `setup_one()` bräuchte eine Schleife statt eines einzelnen `wrap_loaded()`-Aufrufs. Kleiner, isolierter Change — aber ein Shape-Wechsel an einem bereits veröffentlichten Typ, deshalb bewusst nicht einfach nebenbei mitgemacht.

Config-seitig dann nur:
```lua
opts.telemetry = require("config.telemetry").build()
opts.telemetry.extra = {{
  namespace = "nvim-config",
  mains = { "config", "bindings", "plugins", "autocmds", "lsp", "startup", "themes", "machine", "nvchad", "wkdnvchad", "wkdoptions" },
  profile_args = true, persist = true,
}}
```

**Offene Fragen, falls das umgesetzt werden soll:** Soll `extra` generisch für beliebige Nicht-lazy.nvim-Ziele bleiben, oder ist "die eigene Config" der einzige Anwendungsfall? Lohnt sich `main: string|string[]` allgemein (auch für reguläre Plugins mit mehreren Root-Modulen)?

Soll ich **Teil A** (Baseline, config-seitig, kein Plugin-Code) jetzt umsetzen? Das ist risikoarm und reversibel — Teil B lasse ich wie gewünscht als Konzept stehen, bis du entscheidest.
