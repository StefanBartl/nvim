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

## Umsetzung (2026-08-15)

**Teil A und Teil B sind beide umgesetzt** — Teil B im Plugin selbst, weil
der eigentliche Sinn der Sache war, dass *jeder* nvim-Dev seine Config
telemetrieren kann, nicht nur diese hier. Ein config-seitiger Shim hätte
das per Definition nie geleistet.

### Im Plugin (runtime-analysis.nvim) — die eigentliche Funktion

Neues generisches `opts.telemetry.extra`: Targets, die kein Plugin-Manager
auflösen kann (kein Repo, kein Spec, mehrere unabhängige Root-Prefixe statt
einem `main`). Die eigene Config ist der Anwendungsfall, das Feature ist
aber bewusst nicht auf sie zugeschnitten.

```lua
require("runtime-analysis").setup({
  telemetry = {
    extra = {
      { namespace = "nvim-config",
        mains = { "config", "bindings", "plugins", "autocmds", "lsp" },
        profile_args = true },
    },
  },
})
```

- `telemetry/lazy.lua` — `setup_extra()` + `wrap_extra()`; eine Instanz pro
  Target (nicht pro Prefix, sonst schreiben N Instanzen in *eine*
  Cache-Datei), `candidates()` liefert `extra`-Targets mit.
- **Wrap-Zeitpunkt = VimEnter (default).** Genau der Haken aus dem Konzept
  oben, jetzt im Plugin gelöst statt in dieser Config: zur `setup()`-Zeit
  läuft noch `lazy.setup()`, die Config-Module sind fast alle ungeladen.
  `wrap_at = "setup"|"manual"` überschreibt das pro Target.
- **Kein lazy.nvim nötig**: `extra` löst nur über `package.loaded` auf, der
  lazy.nvim-Guard betrifft ausschließlich `plugins`.
- `deep` defaultet für `extra` auf **true** (ein Config-Prefix hat keine
  Fassade, die man stattdessen wrappen könnte).
- `telemetry/setup_all.lua` — läuft über `mains or { main }`; neues
  `run_opts.namespace` grenzt den Lauf auf ein Target ein.
- `telemetry/command.lua` — neue Subcommands **`:RATelemetry setup [ns]`**
  und **`:RATelemetry full [ns]`**; `:RATelemetrySetupAll[Full]` sind jetzt
  deren bare-Form. Damit funktioniert das vom Nutzer gewünschte
  **`:RATelemetry full nvim-config`** (und das normale
  `:RATelemetry setup nvim-config`).
- `SetupAllCandidate.main` blieb `string` (kein `string|string[]`) — der
  Shape-Bruch aus dem Konzept wurde vermieden, `mains` kam additiv dazu.
- Nebenbei gefixt: die Backup-Abfrage vor `SetupAll` prüfte vorhandene Daten
  im Default-Cache-Dir statt im `dir` des Targets — ein Target mit eigenem
  `dir` wurde also ohne Backup-Prompt resettet.
- Docs: `docs/COMMANDS.md`, `docs/BINDINGS.md`,
  `lua/runtime-analysis/telemetry/README.md`.

### In dieser Config

- [lua/config/telemetry.lua](../../../../lua/config/telemetry.lua) —
  `SELF_PREFIXES` (die 11 Prefixe) + `extra`-Block in `build()`. Das ist die
  **einzige** Stelle, an der die Prefix-Liste steht.
- [init.lua](../../../../init.lua) — **keine** eigene Startup-Phase mehr.
  Das Plugin wrappt selbst zum richtigen Zeitpunkt.
- [lua/bindings/usrcmds/telemetry_nvim_config/init.lua](../../../../lua/bindings/usrcmds/telemetry_nvim_config/init.lua)
  — `:RATelemetryNvimConfig[Full]` sind jetzt nur noch **flache Aliases** auf
  `:RATelemetry setup|full nvim-config`. Eine frühere Fassung wrappte selbst,
  was eine zweite Prefix-Liste bedeutet hätte, die stillschweigend
  auseinanderlaufen kann.

### Verifiziert (headless, echte Module)

Multi-Prefix-Wrap über eine Instanz, Zählen, `candidates()` inkl. `mains`
und normalisiertem `deep`, VimEnter-Deferral (Instanz entsteht erst nach
VimEnter, wenn die Config-Module wirklich geladen sind), `:RATelemetry
full nvim-config` end-to-end inkl. erzwungenem Timing, Backup-Prompt
(feuert bei vorhandenen Daten, schreibt Backup, resettet dann), sowie:
Targets ohne geladene Prefixe legen keinen leeren Namespace an,
`extra`-only ohne lazy.nvim funktioniert, malformte Einträge werfen nicht,
und `plugins`-only/`lib_nvim`-only verhalten sich unverändert.
