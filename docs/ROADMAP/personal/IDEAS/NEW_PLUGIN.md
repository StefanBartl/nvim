# `options.nvim` & `nvchad-ui.nvim` — Konzept

Auslagerung von `nvim/lua/wkdoptions/**` + `nvim/lua/options.lua` sowie
`nvim/lua/wkdnvchad/**` + `nvim/lua/chadrc.lua` in eigenständige Plugins,
analog zu den bereits extrahierten `*.nvim`-Repos (`dap.nvim`, `filetree.nvim`,
`sessions.nvim`, `pickers.nvim`, ...) und zum bereits ausgearbeiteten Konzept
[lsp.md](./lsp.md).

Ausgangsfrage (aus der eigenen Analyse): ein gemeinsames `ui.nvim`/`my.nvim`
für **beide** Bereiche mit einem Schalter, der NvChad optional macht — oder
zwei getrennte Plugins? **Ergebnis dieses Konzepts: zwei getrennte Plugins**,
Begründung in [§2](#2-grundsatzentscheidung-zwei-plugins-statt-eines).

---

## Table of Content

- [1. Ist-Zustand](#1-ist-zustand)
- [2. Grundsatzentscheidung: zwei Plugins statt eines](#2-grundsatzentscheidung-zwei-plugins-statt-eines)
- [3. `options.nvim`](#3-optionsnvim)
- [4. `nvchad-ui.nvim`](#4-nvchad-uinvim)
- [5. Dokumentationspflichten](#5-dokumentationspflichten)
- [6. Migrationsplan](#6-migrationsplan)
- [7. Brainstorm: fehlende / neue Features](#7-brainstorm-fehlende--neue-features)
- [8. Offene Fragen / Risiken](#8-offene-fragen--risiken)

---

## 1. Ist-Zustand

| Bereich | Umfang | Kopplung an NvChad |
|---|---|---|
| `lua/wkdoptions/**` | ~7.900 Zeilen: `hl_config` (CursorLine/Column, Mode-Tinting, Flash, SignColumn-Tint, Terminal-Palette, Breadcrumbs mit LSP/Treesitter/Sprach-Providern, Cword-Occurrences, Indent-Scope), `options_config` (Matchparen, Guicursor, Diff-Profile-Umschalter), `config` (eigenes Live-Config-System: parser/setter/getter/observer), `commands`, `qflist`, `italic_keywords`, `indent_per_ft`, `ui/line_numbers` | **Keine echte Kopplung.** Einzige Treffer beim Grep nach `nvchad` sind zwei Doku-Kommentare ("Create closure for NvChad/Lualine-like statuslines") — beschreiben nur *Kompatibilität*, keine `require("nvchad...")`-Abhängigkeit |
| `lua/options.lua` | ~250 Zeilen, rein deklarativ: `vim.opt`/`vim.o`/`vim.wo`-Settings (Appearance, Clipboard, Indentation, Search, Folding, Performance, Shell/WSL) + zwei `require("lib.nvim.autocmd")`-Blöcke + `require("wkdoptions.ui.line_numbers")` + `require("wkdoptions.set_diff_profile.selector")` | Keine |
| `lua/wkdnvchad/**` | ~3.900 Zeilen: `config` (Base46-Theme-Zusammenstellung, Statusline-Varianten `normal`/`base`/`lspbased`/`custom`), `ui/statusline/**` (LSP-aware Breadcrumbs, Cursor-Progress, Devicons, Formatter, Highlighting), `mappings` (Buffer-/Tab-Navigation inkl. Tabufline), `usrcmd` (`:UI theme/toggle/transparency/status/help` + Theme-Verwaltung) | **Strukturell.** 7 Dateien referenzieren `nvchad.*` direkt (`base46`-Cache, `nvchad.config.lspconfig` via Statusline-LSP-Modul). Das Plugin ersetzt/erweitert explizit NvChads eigene Statusline und Theme-Verwaltung — das ist sein Daseinszweck, keine zufällige Nebenabhängigkeit |
| `lua/chadrc.lua` | 50 Zeilen, delegiert komplett an `wkdnvchad.config.setup()`, mit Fallback bei Fehler | 1:1 NvChad-Integrationspunkt (chadrc ist NvChads eigener Konfigurationsmechanismus) |
| Host (`init.lua`) | `{"NvChad/NvChad", lazy = false, branch = "v2.5"}` + `{import = "nvchad.plugins"}` sind fest in `lazy.setup()` verdrahtet, `lua/nvchad/au.lua` existiert host-seitig | NvChad selbst ist aktuell eine harte Host-Abhängigkeit, nicht nur eine von `wkdnvchad` |

**Wichtiger Befund:** Die Grep-Analyse zeigt eine klare Bruchlinie, die schon in
den Ordnernamen sichtbar ist, aber jetzt auch im Code bestätigt ist:
`wkdoptions` (+ `options.lua`) ist bereits faktisch NvChad-unabhängig,
`wkdnvchad` (+ `chadrc.lua`) ist es strukturell **nicht** und soll es nach
seinem eigenen Zweck auch nicht sein.

---

## 2. Grundsatzentscheidung: zwei Plugins statt eines

### 2.1 Warum kein gemeinsames `ui.nvim`/`my.nvim` mit NvChad-Schalter

Die in der Analyse skizzierte Idee — ein Plugin, das beim Start prüft, ob der
User `nvchad = true`/`false` gesetzt hat, und je nachdem nur den
NvChad-unabhängigen Teil lädt — ist **technisch machbar**
(`pcall(require, "nvchad")` bzw. ein expliziter `opts.nvchad` Schalter in
`setup()` sind Standardmuster, siehe z. B. `nvchad_bridge` im
[lsp.md-Konzept](./lsp.md#5-öffentliche-api)). Sie lohnt sich hier aber nicht:

- Die beiden Bereiche haben laut Grep **keine gemeinsame Code-Basis**, die
  eine Fusion rechtfertigen würde — kein gemeinsam genutztes Modul,
  keine Kreuzabhängigkeit in eine Richtung.
- `wkdnvchad`s gesamter Zweck (Base46-Theme-Layer, NvChad-Statusline-Ersatz)
  *ist* die NvChad-Kopplung. Ein `nvchad = false`-Pfad müsste entweder (a) das
  komplette Modul deaktivieren — dann ist der Schalter nur ein
  Feature-Flag um ein sonst unverändertes Plugin, kein Architekturgewinn — oder
  (b) einen zweiten, NvChad-losen Rendering-Pfad für Theme/Statusline
  mitpflegen, der laut Clean-Code-Leitlinie ("keine Features für
  hypothetische künftige Anforderungen") hier nicht gerechtfertigt ist,
  solange niemand NvChad tatsächlich abschalten will.
- `options.nvim` bräuchte den Schalter gar nicht — es hat schon jetzt keine
  NvChad-Abhängigkeit zu gaten.
- Ein Merge von zwei sauber getrennten Verantwortungsbereichen in ein Plugin
  widerspricht [Arch&Coding-Regeln.md §2](./MATERIALS/Arch&Coding-Regeln.md#2-modularisierung--strukturprinzipien)
  ("Modul = eine Verantwortung").

**Fazit:** zwei Plugins, `options.nvim` (generisch, NvChad-frei) und
`nvchad-ui.nvim` (bewusst NvChad-spezifisch), statt eines künstlich
vereinheitlichten `ui.nvim`.

### 2.2 Zur Idee "NvChad ganz weglassen können"

Das ist am Host, nicht am Plugin-Zuschnitt hängend: `init.lua` bootstrapt
NvChad selbst hart (`lazy = false`, `{import = "nvchad.plugins"}`). Ein
NvChad-freies Setup wäre ein eigenes, deutlich größeres Vorhaben (eigene
Colorscheme-/Statusline-Grundlage ohne Base46, Ersatz für `nvchad.plugins`,
...) und keine Konsequenz dieser Extraktion. Falls das je verfolgt wird: der
von dir vorgeschlagene **Git-Branch** (z. B. `no-nvchad`) ist der richtige
Ansatz dafür, nicht ein Laufzeit-Flag in `nvchad-ui.nvim` — der Branch könnte
dann `nvchad-ui.nvim` durch ein eigenständiges Statusline-/Theme-Setup
ersetzen, während `options.nvim` unverändert weiterläuft (es hängt ja jetzt
schon an nichts NvChad-Spezifischem).

---

## 3. `options.nvim`

### 3.1 Scope

**Geht mit:** alles aus `lua/wkdoptions/**` plus der deklarative Options-Teil
aus `lua/options.lua` (Appearance, Clipboard, Indentation, Search, Folding,
Performance/Latency, Wildignore, Files/Persistence, Diff-Profile-Aufruf,
Shell/WSL-Erkennung).

**Bleibt im Host:**
- Die Workstation-OneDrive/PowerShell-Freeze-Fix-Logik in `options.lua`
  (host-/maschinenspezifisch, siehe Memory
  `workstation-onedrive-powershell-freeze.md`) — falls in `options.nvim`
  gebraucht, als Opt-in-Callback, nicht fest verdrahtet.
- Der Markdown-Foldexpr-Autocmd-Block (`require("markdown.core.fold")`) —
  gehört fachlich zu `markdown.nvim`, nicht zu generischen Editor-Optionen.

### 3.2 Architektur / Modul-Mapping

```
options.nvim/
├── lua/options/
│   ├── init.lua                -- M.setup(opts) — Orchestrierung, ersetzt
│   │                               heutiges wkdoptions/init.lua
│   ├── @types/
│   ├── config/                 -- Live-Config-System (parser/setter/getter/observer)
│   ├── hl_config/               -- CursorLine/Column, Mode-Tinting, Flash,
│   │                               SignColumn-Tint, Terminal-Palette,
│   │                               Breadcrumbs, Cword-Occurrences, Indent-Scope
│   ├── options_config/          -- Matchparen, Guicursor, Diff-Profile
│   ├── commands/
│   ├── qflist/
│   ├── italic_keywords/
│   ├── indent_per_ft/
│   ├── ui/line_numbers/
│   └── declarative/             -- NEU: heutiges lua/options.lua 1:1 hierher,
│                                    als M.setup({ declarative = true }) Teilmodul
├── plugin/health.lua (oder lua/options/health.lua)  -- :checkhealth options
├── README.md
├── doc/options.txt
└── docs/ROADMAP.md
```

Die interne Struktur von `wkdoptions` ist bereits sauber nach SRP organisiert
(eigenes Config-System mit Observer-Pattern, `@types`-Unterordner pro Ebene,
Lazy-Loading via `lib.lua.lazy`) — die Extraktion ist überwiegend Verschieben,
kein Rewrite. Neu ist nur die Integration des bisher freistehenden
`lua/options.lua` als eigenes Teilmodul.

### 3.3 lib.nvim-Integration

| Aktuell | Ersetzen durch / Status |
|---|---|
| `lib.lua.lazy` in `wkdoptions/init.lua` | bereits verwendet ✅ |
| `lib.nvim.autocmd` in `wkdoptions/init.lua`, `options.lua` (Diff-Reset, Markdown-Fold) | bereits verwendet ✅ |
| Eigenes Live-Config-System (`config/core/{parser,setter,getter,observer}.lua`) | prüfen ob Teile davon durch `lib.nvim.cache` (memory.lua) ersetzbar sind, oder ob das eigenständige System bewusst spezifischer ist (Observer-Pattern für Highlight-Reload ist hier feiner als ein generischer Cache) — vermutlich **behalten**, kein 1:1-Duplikat zu lib.nvim |
| Winhighlight-Parsing/Memoisierung (`hl_config/utils/winhighlight.lua`) | prüfen gegen `lib.lua.memo` / `lib.lua.memo.lru` — aktuell eigene Memoisierung, Dedup-Kandidat |
| Diff-Profile-Selector (`set_diff_profile/selector.lua`) | könnte `lib.nvim.ui.kit.select` (der tatsächliche Name des in den Leitlinien als "`lib.hover_select`" bezeichneten Wrappers) nutzen, falls dort künftig eine Auswahl-UI statt reinem `vim.o.diffopt`-Toggle gewünscht ist — aktuell kein `vim.ui.select` im Einsatz, also kein Pflicht-Umbau |
| `lib.nvim.notify` | bislang **nicht** durchgängig sichtbar in `wkdoptions/**` — beim Umzug Audit, ob `vim.notify()`/`print()`-Stellen existieren (Verstoß gegen Arch&Coding-Regeln §NVIM-Config-spezifisch) |
| `lib.map` (`vim.keymap.set`) | `options.lua`/`wkdoptions` haben kaum eigene Keymaps (Modul ist primär Options/Highlights) — vermutlich kein Handlungsbedarf, kurz verifizieren |

### 3.4 Öffentliche API

```lua
require("options").setup({
  highlights = true,
  options = true,
  italic_keywords = true,
  declarative = true,        -- NEU: ersetzt require("options") direkt im Host
  workstation_shell_fix = nil, -- optionaler Callback statt fest verdrahteter
                                -- PSModulePath/OneDrive-Logik (Host bleibt Besitzer)
})
```

Commands (bereits vorhanden, bleiben stabil): `:WKDHighlightSet[!]`,
`:WKDHighlightShow`, `:WKDHighlightList`, `:WKDDiffProfile` — Präfix ggf. auf
`:Options*` vereinheitlichen, siehe [§8](#8-offene-fragen--risiken).

---

## 4. `nvchad-ui.nvim`

Name als Vorschlag — Alternative wäre das schlichtere `nvchad.nvim` (deine
eigene Idee); `nvchad-ui.nvim` vermeidet Verwechslung mit NvChad selbst und
macht den Scope (UI-Layer, nicht Ersatz für NvChad als Ganzes) im Namen
explizit. Endgültige Benennung: deine Wahl.

### 4.1 Scope

**Geht mit:** alles aus `lua/wkdnvchad/**` (Base46-Config, Statusline-Varianten
inkl. LSP-aware Breadcrumbs/Cursor-Progress/Devicons, Mappings/Tabufline,
`:UI`-Usercmd + Theme-Verwaltung) plus `lua/chadrc.lua` als dünner
Host-Adapter.

**Bleibt im Host:** nichts Wesentliches — `chadrc.lua` selbst ist der
Integrationspunkt und bleibt als kurzer Wrapper bestehen
(`return require("nvchad-ui").setup()` statt `require("wkdnvchad.config")`),
analog zum heutigen Stand.

### 4.2 Architektur / Modul-Mapping

```
nvchad-ui.nvim/
├── lua/nvchad_ui/
│   ├── init.lua                 -- M.setup(opts)
│   ├── @types/
│   ├── config/
│   │   ├── init.lua            -- Variant-Auswahl + Assembly
│   │   ├── base46.lua          -- Theme (SINGLE SOURCE OF TRUTH)
│   │   └── statusline/{normal,base,lspbased,custom}.lua
│   ├── ui/statusline/
│   │   ├── cursor_ctl/
│   │   └── modules/{custom,file_icons,formatters,highlighting,lsp,neotest_module,plugin_progress}/
│   ├── mappings/{init,tabufline}.lua
│   └── usrcmd/{init,themes}/
├── plugin/health.lua (oder lua/nvchad_ui/health.lua)  -- :checkhealth nvchad-ui
├── README.md
├── doc/nvchad-ui.txt
└── docs/ROADMAP.md
```

Modulname im Repo: Vorschlag `nvchad_ui` (Underscore statt Bindestrich, da Lua
`require("nvchad-ui")` nicht direkt zulässt) — analog zu `dap.nvim`, dessen
Lua-Modul bewusst `wkddap` statt `dap` heißt, um Namenskollisionen mit der
Abhängigkeit (hier: dem echten `nvchad`-Modul aus `NvChad/NvChad`) zu
vermeiden. `nvchad_ui` kollidiert nicht mit `nvchad.*`, ist also unkritischer
als bei `dap.nvim`, aber Konsistenz mit `require("nvchad_ui").setup(...)`
bleibt sinnvoll.

### 4.3 lib.nvim-Integration

| Aktuell | Ersetzen durch / Status |
|---|---|
| `lib.memo.lru` (laut README: LRU-Caches für Path-Resolution) | bereits verwendet ✅ (verifizieren beim Umzug, ob wirklich `lib.lua.memo.lru` oder eine eigene LRU-Implementierung gemeint ist — README erwähnt `lib.memo.lru`, das aktuell nicht existierende Kurzform ist; korrekter Pfad ist `lib.lua.memo` bzw. `lib.lua.memo.lru`) |
| `lib.cross` (Windows/Linux/macOS, WSL-Erkennung laut README) | verifizieren gegen `lib.nvim.cross` (aktueller Pfad in lib.nvim) — README nennt den älteren Kurznamen |
| `lib.strings`, `lib.map`, `lib.lazy` (laut README "Prerequisites") | Pfade beim Umzug gegen aktuellen lib.nvim-Stand verifizieren (`lib.lua.strings`, `lib.nvim.map`, `lib.lua.lazy`) — die README ist vermutlich älter als die aktuelle lib.nvim-Modulstruktur |
| Devicons-Cache, LSP-Symbol-Cache (`ui/statusline/modules/lsp/**`) | Dedup-Kandidat gegen `lib.nvim.cache` / `lib.lua.memo`, analog zum in [lsp.md §4](./lsp.md#4-libnvim-integration) dokumentierten Hover-Cache-Vorschlag |
| Debounced Statusline-Updates (250ms laut README) | prüfen gegen `lib.nvim.debounce` — falls aktuell eigenhändig implementiert, konsolidieren |
| `nvchad.config.lspconfig`-Referenz im LSP-Statusline-Modul | **Abstimmen mit `lsp.nvim`-Migration** ([lsp.md §2](./lsp.md#2-scope-abgrenzung)): dort ist die NvChad-Kopplung bereits als optionaler `nvchad_bridge`-Adapter vorgesehen. `nvchad-ui.nvim` sollte denselben Adapter-Punkt konsumieren statt eine zweite direkte `nvchad.*`-Referenz zu pflegen |

### 4.4 Öffentliche API

```lua
require("nvchad_ui").setup({
  all = true,               -- ersetzt heutiges { all = true } an wkdnvchad.setup
  statusline_variant = "lspbased", -- "normal"|"base"|"lspbased"|"custom"
  base46 = {
    theme = "tokyonight",
    transparency = false,
    theme_toggle = { "tokyonight", "rosepine" },
  },
  mappings = { all = true, buffers = true, tabs = true },
})
```

`chadrc.lua` bleibt struktura identisch zum heutigen Stand, nur mit
`require("nvchad_ui")` statt `require("wkdnvchad")`:

```lua
-- lua/chadrc.lua nach der Migration
local ok, config = pcall(function()
  return require("nvchad_ui.config").setup()
end)
-- ... Fallback-Logik unverändert
```

Commands: `:UI theme/themes/toggle/transparency[/on/off]/status/help` bleiben
stabil.

---

## 5. Dokumentationspflichten

Für **beide** Plugins, wie in [NEW_Project.md](./MATERIALS/NEW_Project.md)
festgelegt:

- `README.md` (deutsch) — ASCII-Art + Badges + Table of Content (nur H2)
- `/doc/{options,nvchad-ui}.txt` (englisch, `:h`-fähig)
- `/docs/ROADMAP.md` — künftige Features
- **`:checkhealth {options,nvchad-ui}`** — Pflicht. Für `options.nvim`: prüft
  u. a. ob `lib.nvim` vorhanden ist, ob die Diff-Profile/Highlight-Config
  valide geladen wurde. Für `nvchad-ui.nvim`: zusätzlich ob `NvChad/NvChad`
  selbst geladen ist (harte Abhängigkeit, im Gegensatz zu `options.nvim`) und
  ob `nvim-web-devicons` verfügbar ist (README nennt es als Soft-Dep für
  Icon-Farben).
- Beide READMEs verlieren beim Umzug die aktuell auf Englisch verfassten
  Inhalte von `wkdnvchad/README.md` / `wkdoptions/README.md` nicht, sondern
  übersetzen/übernehmen sie — `wkdoptions/README.md` ist schon Deutsch,
  `wkdnvchad/README.md` ist aktuell Englisch und muss laut Vorgabe (Arch&Coding-Regeln
  §5: "Jedes Modul braucht eine README.md in deutscher [Sprache]") ins Deutsche
  übertragen werden.

---

## 6. Migrationsplan

1. Repos `options.nvim` und `nvchad-ui.nvim` unter `C:\repos\` anlegen
   (Grundgerüst: README, doc, ROADMAP, `:checkhealth`, `.luarc.json`,
   `stylua.toml` — Vorlage: `dap.nvim`, das dieselbe Struktur bereits hat).
2. `lua/wkdoptions/**` → `options.nvim/lua/options/**`,
   `lua/wkdnvchad/**` → `nvchad-ui.nvim/lua/nvchad_ui/**` 1:1 kopieren.
3. `lua/options.lua` als neues Teilmodul `options.nvim/lua/options/declarative/init.lua`
   integrieren; Host-spezifische Teile (Workstation-Shell-Fix) als Opt/Callback
   herauslösen (s. [§3.1](#31-scope)).
4. `lua/chadrc.lua` auf `require("nvchad_ui...")` umstellen, 1:1 sonst
   unverändert (Fallback-Pfad bleibt).
5. lib.nvim-Pfade in beiden READMEs/Prerequisites gegen den aktuellen
   `lib.nvim`-Stand verifizieren und korrigieren (s. [§4.3](#43-libnvim-integration)
   — mehrere README-genannte Kurzpfade existieren im heutigen `lib.nvim`-Repo
   so nicht mehr wörtlich).
6. `:checkhealth`-Brücken ergänzen (s. [§5](#5-dokumentationspflichten)).
7. Host-Wiring in `lua/plugins/personal/init.lua` analog zum bestehenden
   `dap.nvim`-Eintrag ergänzen (lokaler Dev-Checkout via
   `personal_utils.local_dev("options.nvim")` /
   `local_dev("nvchad-ui.nvim")`, `event = "VeryLazy"` **nur falls** kein
   Startup-kritischer Pfad betroffen ist — `options.nvim` und `nvchad-ui.nvim`
   werden aktuell in `init.lua` synchron (`startup.now(...)`) vor dem ersten
   Paint geladen, das muss beim Umzug erhalten bleiben, siehe
   [init.lua:138](../../../init.lua) — d. h. **kein** reines `event = "VeryLazy"`
   wie bei `dap.nvim`, sondern weiterhin `startup.now("options", ...)` /
   `startup.now("nvchad-ui", ...)`).
8. `require("wkdoptions")...` / `require("wkdnvchad")...`-Aufrufe in
   `init.lua` und `chadrc.lua` durch die neuen Plugin-Requires ersetzen; alte
   `lua/wkdoptions/`, `lua/wkdnvchad/`, `lua/options.lua` erst löschen, wenn
   das neue Setup nachweislich lädt (Highlights, Diagnostics-Signs, Statusline,
   `:UI`-Commands manuell getestet).
9. Diesen Roadmap-Eintrag nach Abschluss aktualisieren, analog zur
   Memory-Notiz `lib-nvim-extraction.md`.

---

## 7. Brainstorm: fehlende / neue Features

### 7.1 `options.nvim`

| Feature | Nutzen | Aufwand |
|---|---|---|
| **Profil-Presets für `hl_config`** (analog zu `set_diff_profile`) | Aktuell nur Diff hat Profile ("minimal"/"context"/"review"/"strict"); ein ähnliches Preset-System für z. B. Cursorline-Intensität ("minimal UI" vs. "full UI") wäre konsistent | mittel |
| **`:checkhealth`-Audit für Skip-Regeln** | `hl_config/utils/skip.lua` erkennt UI-Buffer per O(1)-Lookup — sollte in `:checkhealth` sichtbar machen, welche Filetypes/Buftypes aktuell geskippt werden, zur Fehlersuche bei "Highlight fehlt in Buffer X" | klein |
| **Persistente User-Overrides** (`:WKDHighlightSet!` schreibt aktuell laufzeitflüchtig?) | Falls nicht bereits vorhanden: Option, gesetzte Werte in eine kleine Datei unter `stdpath("data")` zu persistieren, damit Laufzeit-Änderungen einen Neustart überleben | mittel |
| **Guicursor-Presets** | `options_config` hat Guicursor-Zuordnung zu Highlight-Gruppen — vorkonfigurierte Presets (z. B. "block-only", "classic vim") als Ein-Befehl-Umschalter | klein |

### 7.2 `nvchad-ui.nvim`

| Feature | Nutzen | Aufwand |
|---|---|---|
| **Statusline-Profiling-Command** (`:UI profile`) | README erwähnt `vim.g.wkdnvchad_profile` + manuellen `:lua print(...)`-Aufruf — ein richtiger Usercmd wäre konsistenter mit dem sonstigen `:UI`-Interface | klein |
| **Theme-Preview vor dem Wechsel** | `:UI theme <Tab>` completiert bereits Themennamen; ein kurzer Live-Preview (Farbswatch im Floating-Window) vor dem Commit wäre eine spürbare UX-Verbesserung, ähnlich Colorscheme-Picker-Plugins | mittel |
| **Tabufline-Reorder per Drag** oder zumindest `:UI bufmove <n>` | Aktuelle Mappings decken `<leader>tr`/`<leader>tl`/`<leader>tt` ab, aber kein direktes "Buffer N Positionen weiterschieben" per Command/Count | klein-mittel |
| **Cursor-Progress-Persistenz** | `cursor_ctl.set_mode()` ist laufzeitflüchtig (Cycle durch 5 Modi) — Default-Modus als `setup()`-Opt statt immer bei `"classic"` zu starten | klein |
| **Devicon-Cache-Invalidierung bei Icon-Theme-Wechsel** | `__reset_cache()` existiert schon manuell aufrufbar laut README-Troubleshooting — sollte automatisch bei `:UI theme`-Wechsel mitlaufen, statt manuell dokumentiert zu sein | klein |

### 7.3 `lsp.nvim` — bereits behandelt

Der explizit angefragte Brainstorm zu fehlenden Features in `nvim/lua/lsp/**`
ist bereits ausführlich in [lsp.md §8](./lsp.md#8-brainstorm-fehlende--neue-features)
dokumentiert (Inlay-Hints-Toggle, Code-Action-Indikator, `:LspLog`-Wrapper,
Auto-Restart mit Backoff, Formatter-Prioritäts-Audit, Workspace-Symbol-Picker
über `pickers.nvim`, Per-Projekt-Override, Multi-Root-Switcher, Hover-Cache,
Test-Entry-Point, Diagnostics-Debounce, Signature-Help-Ersatz durch native
API). Ergänzend, nicht dort enthalten:

| Feature | Nutzen | Aufwand |
|---|---|---|
| **Semantic-Tokens-Toggle** (`vim.lsp.semantic_tokens`, global + per-Filetype) | Wie Inlay-Hints aktuell nirgends in `lua/lsp/` referenziert, obwohl nativ verfügbar | klein |
| **Multi-Client-Konfliktanzeige** | Wenn zwei Clients (z. B. `ts_ls` + `eslint`) überlappende Diagnostics/Formatierung liefern, ist aktuell nicht sichtbar, welcher Client "gewinnt" — eine `:LspDoctor conflicts`-Ansicht wäre ein natürliches Zusatzfeature zum bereits geplanten Formatter-Prioritäts-Audit | mittel |
| **Rename-Preview** (`workspace/rename` als Diff über mehrere Dateien vor Ausführung) | Aktuell vermutlich direktes Rename ohne Vorschau — riskant bei großen Workspaces | mittel-groß |

---

## 8. Offene Fragen / Risiken

- **Command-Präfixe:** `options.nvim` erbt `:WKDHighlightSet`/`:WKDOptSet`/
  `:WKDDiffProfile` — beibehalten (Breaking Change für eigene Muscle-Memory
  vermeiden) oder auf `:Options*` vereinheitlichen? Analog für `nvchad-ui.nvim`
 ->auf :Options bzw :UI vereinen  vereinen
  (`:UI` ist schon generisch genug, vermutlich unverändert lassen).
- **README-Drift bei lib.nvim-Pfaden:** Beide READMEs (`wkdnvchad/README.md`
  insbesondere) nennen lib.nvim-Kurzpfade (`lib.memo`, `lib.cross`, `lib.map`,
  `lib.lazy`, `lib.strings`), die im aktuellen `lib.nvim`-Repo unter
  `lib.lua.*`/`lib.nvim.*` liegen. Vor der Migration klären, ob das
  Dokumentations-Drift ist oder ob tatsächlich (noch) über alte Kompat-Aliase
  referenziert wird — sonst wird der Fehler beim Umzug 1:1 mitkopiert.
  -> es gibt mein ülugin lib.nvim das ist gemeint. das soll alas ahard dependendcy dabe sein
- **`nvchad-ui.nvim` als harte NvChad-Abhängigkeit:** anders als bei
  `lsp.nvim` (dort ist die NvChad-Kopplung ein *optionaler* Adapter) ist
  NvChad hier fachlich notwendig, nicht optional. Das sollte im
  `:checkhealth`-Output und in der README unmissverständlich stehen, damit
  niemand versehentlich `nvchad-ui.nvim` ohne NvChad installiert.
- **Startup-Reihenfolge:** `init.lua` lädt `wkdoptions` synchron
  (`startup.now`) *vor* `autocmds` und `lsp`, weil Highlights vor dem ersten
  Paint stehen müssen. Diese Reihenfolge-Abhängigkeit muss beim Umzug auf
  `options.nvim` exakt erhalten bleiben — keine Lazy-Loading-Entscheidung
  treffen, die den First-Paint verzögert (s. [§6 Punkt 7](#6-migrationsplan)).
- **`lsp.nvim`-Abstimmung:** Falls `lsp.nvim` und `nvchad-ui.nvim` in
  unterschiedlicher Reihenfolge extrahiert werden, muss die
  `nvchad_bridge`-Schnittstelle aus [lsp.md](./lsp.md) zuerst stehen, damit
  `nvchad-ui.nvim`s LSP-Statusline-Modul nicht seinerseits eine zweite
  `nvchad.*`-Direktreferenz pflegt.
