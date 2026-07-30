# Snacks — Keymaps

Plugin-Spec: [lua/plugins/snacks.lua](../../../../../lua/plugins/snacks.lua)
(`folke/snacks.nvim`, `lazy = false`, `priority = 1000`).

`snacks.nvim` selbst liefert **keine** globalen Default-Keymaps aus — jedes im
README/`docs/*.md` gezeigte Mapping ist eine *Vorschlags*-`keys`-Zeile für den
eigenen Lazy-Spec, kein vom Plugin selbst gesetztes `vim.keymap.set`. Damit
sind praktisch **alle** hier gelisteten Bindings **[custom]** — es gibt in
diesem Config keine Snacks-Keymap, die "einfach nur der Plugin-Default" wäre.

**`snacks.setup()` läuft.** `lua/plugins/snacks.lua` hat bewusst **keinen**
eigenen `config`-Block mehr (siehe Kommentar dort, Zeilen 70-79): der Spec
setzt nur `opts = function(_) … end`, und lazy.nvim ruft für Specs ohne
eigenes `config` automatisch `require("snacks").setup(opts)` selbst auf. Ein
expliziter `config`-Stub hier würde diesen impliziten Call **ersetzen** und
damit `opts` (inklusive `picker.win.keys`, den pickers.nvim-internen
Bindings) stillschweigend verwerfen — deshalb fehlt er absichtlich.
- Die in `opts` gesetzten Modul-Flags (`debug.enabled = true`,
  `dim.enabled = false`, `profiler.enabled = false`,
  `quickfile.enabled = true`, `scope.enabled = false`,
  `scratch.enabled = false`, `toggle.enabled = false`, `words.enabled = false`,
  `image.enabled = true`, `bigfile.enabled = false`, `notifier.enabled = false`,
  `picker = picker_config.get_config()`) greifen also **wirklich** — sie
  werden über den impliziten `setup(opts)`-Call an Snacks durchgereicht.
- Es gibt in diesem Spec kein `dashboard`-Flag mehr und keinen
  `config/snacks/custom_dashboard/*`-Modulbaum: der wurde zusammen mit dem
  Fix entfernt (Commit *"fix(snacks): restore setup() and drop the custom
  dashboard"*). `snacks.dashboard` bleibt auf Upstream-Default (aus) stehen,
  und es gibt aktuell **keine** Snacks-spezifischen Autocmds oder Usercmds in
  diesem Config mehr (kein `Autocmds/Snacks.md`/`Usercmds/Snacks.md`
  entsprechend — beide Dokumente wurden gelöscht, da nichts mehr zu
  dokumentieren war).

---

## Aktiv genutzte Snacks-Module (per `keys =`-Aufrufen)

| Modul | Zweck | Quelle der Keymaps |
|---|---|---|
| `snacks.explorer` | Datei-Explorer | [mappings/standard.lua](../../../../../lua/config/snacks/mappings/standard.lua) |
| `snacks.picker` | Picker-Backend (Command-History, Notifications) — restliche Picker-Bindings laufen über **pickers.nvim**, nicht direkt über Snacks | [mappings/standard.lua](../../../../../lua/config/snacks/mappings/standard.lua) |
| `snacks.debug` | Inspector/Overlay | [mappings/extended.lua](../../../../../lua/config/snacks/mappings/extended.lua) |
| `snacks.dim` | Focus-Scope-Dimmer | dito |
| `snacks.profiler` | Lua-Profiler | dito |
| `snacks.quickfile` | Schnelles File-Rendering beim Start | dito |
| `snacks.scope` | Scope-Jump (Treesitter-Scope) | dito |
| `snacks.scratch` | Scratch-Buffer | dito |

Nicht in `keys` gebunden, aber in `opts` erwähnt bzw. im Ökosystem relevant:
`image` (Inline-Bildrendering, kein eigenes Keymap nötig), `words`, `toggle`,
`bigfile`, `notifier`. Kein `dashboard`-Eintrag (mehr) in `opts` — Snacks'
Dashboard bleibt auf Upstream-Default (aus).

---

## Gruppe: Top Pickers & Explorer

Quelle: [lua/config/snacks/mappings/standard.lua](../../../../../lua/config/snacks/mappings/standard.lua)
(dispatcht größtenteils über `pickers.nvim`, s. Kommentar-Header der Datei —
nur `<leader>F` ruft `snacks.explorer()` direkt).

| Mapping | Aktion | Status | Ziel |
|---|---|---|---|
| `<leader>:` | Command History | [custom] | `pickers.builtins.run("command_history")` |
| `<leader>N` | Notification History | [custom] | `pickers.builtins.run("notifications")` |
| `<leader>F` | File Explorer | [custom] | `require("snacks").explorer()` |

## Gruppe: Find

| Mapping | Aktion | Status | Ziel |
|---|---|---|---|
| `<leader>ff` | Find Files (cwd) | [custom] | `pickers.command` scope `cwd`/`files` |
| `<leader>pro` | Projects | [custom] | `pickers.builtins.run("projects")` |
| `<leader>old` | Recent Files | [custom] | `pickers.builtins.run("recent")` |

## Gruppe: Git

| Mapping | Aktion | Status |
|---|---|---|
| `<leader>gb` | Git Branches | [custom] |
| `<leader>gl` | Git Log | [custom] |
| `<leader>gL` | Git Log Line | [custom] |
| `<leader>gs` | Git Status | [custom] |
| `<leader>gS` | Git Stash | [custom] |
| `<leader>gd` | Git Diff (Hunks) | [custom] |
| `<leader>gf` | Git Log File | [custom] |

## Gruppe: GitHub

| Mapping | Aktion | Status |
|---|---|---|
| `<leader>gi` | GitHub Issues (offen) | [custom] |
| `<leader>gI` | GitHub Issues (alle) | [custom] |
| `<leader>gp` | GitHub Pull Requests (offen) | [custom] |
| `<leader>gP` | GitHub Pull Requests (alle) | [custom] |

## Gruppe: Grep

| Mapping | Aktion | Status |
|---|---|---|
| `<leader>cb` | Buffer Lines | [custom] |
| `<leader>cB` | Grep Open Buffers | [custom] |
| `<leader><leader>` | Grep (cwd) | [custom] |

## Gruppe: Search

| Mapping | Aktion | Status |
|---|---|---|
| `<leader>com` | Commands | [custom] |
| `<leader>fk` | Keymaps | [custom] |
| `<leader>sM` | Man Pages | [custom] |
| `<leader>help` | Help Pages | [custom] |
| `<leader>ch` | Colorschemes | [custom] |

## Gruppe: LSP

| Mapping | Aktion | Status |
|---|---|---|
| `GD` | Goto Definition | [custom] |
| `gD` | Goto Declaration | [custom] |
| `GR` | References (`nowait = true`) | [custom] |
| `GI` | Goto Implementation | [custom] |
| `GY` | Goto Type Definition | [custom] |
| `GAI` | Calls Incoming | [custom] |
| `GAO` | Calls Outgoing | [custom] |
| `<leader>SS` | LSP Symbols | [custom] |
| `<leader>sS` | LSP Workspace Symbols | [custom] |

Alle Einträge dieser sechs Gruppen sind rein `mode = "n"`. Sie rufen **nicht**
Snacks' eigenen Picker direkt, sondern **pickers.nvim** (`builtin(...)` /
`scope_action(...)` in `standard.lua`) — Snacks fungiert hier nur als eines von
mehreren möglichen Picker-Backends (Telescope/fzf-lua/Snacks), aktiv über
`picker = picker_config.get_config()` in `opts`, das dank des impliziten
`setup(opts)`-Aufrufs (s.o.) tatsächlich wirkt. Details zu den
Picker-internen Tasten (Preview-Scroll, History, `<CR>`/`<C-v>`/`<C-x>`/`<C-t>`)
liegen bei **pickers.nvim**, nicht in diesem Dokument.

---

## Gruppe: Snacks-eigene Utility-Keymaps

Quelle: [lua/config/snacks/mappings/extended.lua](../../../../../lua/config/snacks/mappings/extended.lua).
Alle rufen ihr Submodul über einen `safe_call(mod, fn, ...)`-Dispatcher auf
(pcall-geschützt, `notify.warn`/`notify.error` bei Fehlern statt Crash).

| Mapping | Aktion | Status | Ziel |
|---|---|---|---|
| `<leader>ud` | Snacks Debug: Inspector öffnen | [custom] | `snacks.debug.open()` |
| `<leader>uD` | Snacks Debug: Overlay togglen | [custom] | `snacks.debug.toggle()` |
| `<leader>uf` | Snacks Dim: Focus-Scope togglen | [custom] | `snacks.dim.toggle()` |
| `<leader>ps` | Snacks Profiler: Start | [custom] | `snacks.profiler.start()` |
| `<leader>pS` | Snacks Profiler: Stop | [custom] | `snacks.profiler.stop()` |
| `<leader>pr` | Snacks Profiler: Report | [custom] | `snacks.profiler.report()` |
| `<leader>uq` | Snacks Quickfile: Deaktivieren (Session) | [custom] | `snacks.quickfile.disable()` |
| `]s` | Snacks Scope: Nächster | [custom] | `snacks.scope.jump_next()` |
| `[s` | Snacks Scope: Vorheriger | [custom] | `snacks.scope.jump_prev()` |
| `<leader>ns` | Snacks Scratch: Öffnen | [custom] | `snacks.scratch.open()` |
| `<leader>nS` | Snacks Scratch: Neu | [custom] | `snacks.scratch.new()` |

Hinweis: `opts.dim.enabled`, `opts.profiler.enabled` und `opts.scope.enabled`
sind in `plugins/snacks.lua` auf `false` gesetzt — dank des impliziten
`setup(opts)`-Aufrufs (siehe oben) greift das auch tatsächlich, d. h. `dim`,
`profiler` und `scope` sind hier disabled. Die zugehörigen Keymaps sind zwar
registriert und rufen ihr Submodul bei Bedarf lazy auf (`safe_call`), die
Submodule selbst tun aber standardmäßig nichts Sichtbares, solange sie
disabled bleiben.

---

## Registrierung — technischer Ablauf

`keys = require("config.snacks.mappings").get_all_keys()` in
[lua/plugins/snacks.lua](../../../../../lua/plugins/snacks.lua) sammelt zwei
Quellen ein ([mappings/init.lua](../../../../../lua/config/snacks/mappings/init.lua)):

1. `config.snacks.mappings.standard` (Picker/Explorer, s.o.)
2. `config.snacks.mappings.extended` (Snacks-Utility, s.o.)

Da `lazy = false`, setzt Lazy.nvim diese Keymaps beim Start unmittelbar als
echte `vim.keymap.set`-Aufrufe (nicht nur als Lazy-Load-Trigger).

Es gibt kein `config/snacks/custom_dashboard/*` mehr und keinen separaten
`config/snacks/usrcmds/`-Baum (im Gegensatz z. B. zu Harpoon) — der Kommentar
in `plugins/snacks.lua` erklärt das: *"config.snacks.usrcmds removed: every
command it exposed now has an engine-agnostic equivalent in
pickers.builtins, reached via `:Pickers builtin <name>`"*. Die frühere
Snacks-eigene Command-/Dashboard-Schicht ist damit vollständig zugunsten von
**pickers.nvim** aufgegeben.

## Offene Fragen / Unsicherheiten

- Tatsächlicher Enabled-Zustand von `debug`, `image`, `quickfile` und
  `picker` zur Laufzeit folgt jetzt direkt den `opts` in `plugins/snacks.lua`
  (dank des impliziten `setup(opts)`-Aufrufs) — nicht einzeln zur Laufzeit
  nachverifiziert (z. B. per `:lua print(vim.inspect(Snacks.config))`),
  aber der Mechanismus selbst ist geklärt und kein offener Punkt mehr.
