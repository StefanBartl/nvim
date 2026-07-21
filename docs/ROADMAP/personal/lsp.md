# `lsp.nvim` — Konzept

Auslagerung von `nvim/lua/lsp/**` in ein eigenständiges Plugin, analog zu
`dap.nvim` (bereits als leeres Repo unter `C:\repos\dap.nvim` angelegt) und
den anderen bereits extrahierten `*.nvim`-Plugins (`filetree.nvim`,
`sessions.nvim`, `pickers.nvim`, ...).

Die Grundsatzentscheidung dazu ist bereits in [nvim.md](./nvim.md) (Abschnitt
„`lsp.nvim` vs. `options.nvim`“, 2026-07-17) getroffen: `lua/lsp/` ist
strukturell dasselbe wie `dap.nvim` — ein **stateful Subsystem** (Registry,
Capabilities, Attach-Handler, Formatter-Toggle, Workspace-Diagnostics-Toggle),
keine deklarativen Settings. Gehört daher **nicht** in `options.nvim`.

---

## Table of Content

- [1. Ist-Zustand](#1-ist-zustand)
- [2. Scope-Abgrenzung](#2-scope-abgrenzung)
- [3. Architektur / Modul-Mapping](#3-architektur--modul-mapping)
- [4. lib.nvim-Integration](#4-libnvim-integration)
- [5. Öffentliche API](#5-öffentliche-api)
- [6. Dokumentationspflichten](#6-dokumentationspflichten)
- [7. Migrationsplan](#7-migrationsplan)
- [8. Brainstorm: fehlende / neue Features](#8-brainstorm-fehlende--neue-features)
- [9. Offene Fragen / Risiken](#9-offene-fragen--risiken)

---

## 1. Ist-Zustand

`lua/lsp/` ist mit ~130 Dateien das größte Subsystem der Config. Grobe
Bestandsaufnahme (Verantwortungsbereiche):

| Bereich | Pfad | Verantwortung |
|---|---|---|
| Core | `core/{registry,attach,handlers,filter,diagnostics,treesitter,util}.lua` | Server-Registry (`ACTIVE`-Liste), `on_attach`/`on_init`, publishDiagnostics-Dedup, Treesitter-Wiring |
| Core (Sonderfälle) | `core/workspace_diagnostics.lua`, `core/root_scope.lua`, `core/root_scope_picker.lua` | Laufzeit-Toggle für `workspace-diagnostics.nvim` (Startup-Freeze-Fix, s. Memory), Multi-Root-Handling |
| Formatter | `formatter/{init,conform}.lua` | Conform-first, LSP-Fallback, View-preserving Format-on-Save mit Toggle |
| Diagnostics | `diagnostics/**` | Commands, Keymaps, Quickfix/Loclist, Navigation |
| Server-Configs | `servers/**` (bashls, lua_ls, gopls, marksman, csharp, clangd, zig, webdev/*, mobiledev/*) | Pro-Server-Setup, `lua_ls` mit eigenem Library-Resolver/Reload/Rootresolver |
| Sprachen | `languages/**` (app, documentation, scripting, systems, webdev) | Filetype-spezifische QoL (Astro-Autocmds/Keymaps/Usercmds, Markdown-Words, ...) |
| Debug-Doctor | `lspdoctor/**` | `:LspDoctor {health,debug,quick,deep,all}` — **noch nicht an `:checkhealth` angebunden** |
| Tools | `tools/{eslint_prettier,lsp_signature,ts_type_lookup,deprecated_help}/**` | Eigenständige Zusatz-Werkzeuge, jeweils mit eigenem `setup()`/`attach()` |
| Usercmds | `usercmds/{completion,formatter,workspace_diagnostics}.lua` | Command-Completion, Wiring |
| Debug Adapters | `debug_adapters/**` | **Fehlplatziert** — DAP ist ein eigenes Protokoll, gehört zu `dap.nvim` |
| Types | `@types/**`, verteilte `@types`-Unterordner | Bereits gut nach Leitfaden strukturiert |

Einstiegspunkt `lsp/init.lua` verdrahtet alles synchron in `M.setup(cfg)`,
inkl. Host-spezifischer Logik (`machine.is("workstation")`,
`config.mason.ensure_install`).

---

## 2. Scope-Abgrenzung

**Geht mit nach `lsp.nvim`:**
Alles aus obiger Tabelle außer `debug_adapters/**`.

**Geht NICHT mit, sondern zu `dap.nvim`:**
`lua/lsp/debug_adapters/**` (bash, node, go, dotnet, webdev/browser). DAP
(Debug Adapter Protocol) ist fachlich unabhängig vom LSP — die einzige
Gemeinsamkeit ist "Mason installiert beides". Aktuell ist
`lsp/debug_adapters/init.lua` ohnehin nur eine Sammlung auskommentierter
`require`s — d.h. faktisch inaktiv. Der Umzug ist reines Verschieben ohne
Funktionsverlust. `dap.nvim` existiert bereits (leeres Repo) — dort passt es
symmetrisch neben eine künftige `core/registry.lua`, `core/attach.lua`-Struktur
für DAP.

**Bleibt im Host (`nvim/`), wird NICHT Teil von `lsp.nvim`:**
- `machine.is("workstation")`-Gating (host-/maschinenspezifisch) → als Opt
  (`use_workspace_diagnostics: boolean`) an `M.setup()` übergeben, nicht intern
  referenzieren.
- `config.mason.ensure_install` (Mason-Paketverwaltung ist ein eigenes,
  Host-Belang) → per Callback/Opt injizieren, nicht `require()`-fest verdrahten.
- NvChad-Kopplung (`nvchad.config.lspconfig.on_attach/on_init`) → falls
  weiterhin gewünscht, als optionaler Adapter (`opts.nvchad_bridge = true`),
  damit `lsp.nvim` auch ohne NvChad nutzbar bleibt (Wiederverwendbarkeit war
  ausdrücklich das Ziel in der `nvim.md`-Entscheidung).

---

## 3. Architektur / Modul-Mapping

Zielstruktur (Ordnernamen ohne führendes `lsp.`-Präfix im Repo, da
`lua/lsp/init.lua` im Plugin selbst die Modulwurzel ist):

```
lsp.nvim/
├── lua/lsp/
│   ├── init.lua                  -- M.setup(opts) — schlank, nur Orchestrierung
│   ├── @types/
│   ├── core/
│   │   ├── registry.lua          -- ACTIVE-Liste konfigurierbar statt hart codiert
│   │   ├── attach.lua
│   │   ├── capabilities.lua
│   │   ├── handlers.lua
│   │   ├── filter.lua
│   │   ├── diagnostics.lua
│   │   ├── treesitter.lua
│   │   ├── workspace_diagnostics.lua
│   │   └── root_scope.lua / root_scope_picker.lua  -- ggf. durch lib.nvim.fs.find_root / polymorphic_rootresolver ersetzen (s. §4)
│   ├── formatter/
│   ├── diagnostics/
│   ├── servers/
│   ├── languages/
│   ├── lspdoctor/                -- + health.lua-Brücke zu :checkhealth
│   ├── tools/
│   └── usercmds/
├── plugin/health.lua (oder lua/lsp/health.lua)  -- :checkhealth lsp
├── README.md
├── doc/lsp.txt
└── docs/ROADMAP.md
```

Die interne Struktur bleibt weitgehend 1:1 — sie ist bereits sauber nach den
Prinzipien aus [Arch&Coding-Regeln.md](./MATERIALS/Arch&Coding-Regeln.md)
organisiert (SRP pro Modul, `@types`-Unterordner, `pcall`-Disziplin). Die
Extraktion ist überwiegend **Verschieben + Entkopplung von Host-Spezifika**,
kein Rewrite.

---

## 4. lib.nvim-Integration

Pflicht laut [Arch&Coding-Regeln.md §NVIM-Config spezifisch](./MATERIALS/Arch&Coding-Regeln.md)
und [Checklist.md](./MATERIALS/Checklist.md). Konkret für `lsp.nvim`:

| Aktuell in `lua/lsp/**` | Ersetzen durch (lib.nvim) | Anmerkung |
|---|---|---|
| `require("lib.nvim.notify").create(...)` | bereits verwendet ✅ | konsistent beibehalten |
| `vim.keymap.set` (diagnostics/keymaps.lua etc.) | `lib.nvim.map` | prüfen: derzeit uneinheitlich, manche Module nutzen es schon (`lspdoctor/init.lua`) |
| eigene `nvim_create_autocmd`-Aufrufe (`formatter/init.lua`) | `lib.nvim.autocmd` | teilweise schon (`Autocmd.create`) |
| `usercmd.create(...)` | `lib.nvim.usercmd` | bereits verwendet ✅ |
| **`lsp/core/root_scope.lua`, `servers/lua_ls/rootresolver.lua`, `servers/marksman/rootresolver.lua`** | `lib.nvim.fs.find_root` / `lib.nvim.fs.polymorphic_rootresolver` | **Konkreter Dedup-Kandidat**: lib.nvim hat bereits einen generischen, mehrfach getesteten Root-Resolver — drei eigene Re-Implementierungen im LSP-Modul sind ein Wartungsrisiko und widersprechen dem Reduce-Reuse-Recycle-Prinzip |
| Caching in `lspdoctor`/`servers/lua_ls` (z. B. Library-Profile) | `lib.nvim.cache` | prüfen ob stdpath("cache")-Nutzung schon konform ist |
| Format-on-Save-Timing, Diagnostics-Refresh | `lib.nvim.debounce` / `lib.nvim.debounce.buffer` | derzeit kein Debouncing sichtbar bei Diagnostics-Handlern — Kandidat für Perf-Verbesserung |
| Memoization (z. B. `get_installed_lsps()` in `usercmds/completion.lua`, das bei jedem Tab-Complete Mason neu abfragt) | `lib.lua.memo` | klarer Kandidat, spart wiederholte `mason-registry`-Scans |
| Lazy-Requires für selten genutzte Tools (`ts_type_lookup`, `deprecated_help`) | `lib.lua.lazy` | aktuell werden alle Tools in `init.lua` synchron geladen, unabhängig von Filetype |
| `vim.ui.select`-artige Auswahl (z. B. `root_scope_picker`, LspDoctor-Modusauswahl) | `lib.hover_select` (falls/wenn in lib.nvim verfügbar — beim Durchsuchen des aktuellen `lib.nvim`-Repos nicht gefunden, ggf. erst noch zu bauen) | **Vorsicht**: vor Verwendung prüfen, ob das Modul im lib.nvim-Stand zum Zeitpunkt der Migration tatsächlich existiert |
| `lib.cross_plattform` / `lib.cross` | `formatter/init.lua` behauptet "Linux/macOS only; no Windows-specific branches" im Kommentar | **Klären**: verstößt gegen MISC-Regel „Cross-Plattform, wo möglich“ — entweder Windows-Pfad ergänzen oder bewusste Ausnahme dokumentieren |

---

## 5. Öffentliche API

Grober Vorschlag (Details erst beim Implementieren final):

```lua
require("lsp").setup({
  servers = { "lua_ls", "gopls", ... },        -- ersetzt hart codierte ACTIVE-Liste
  format_on_save = false,
  use_workspace_diagnostics = false,           -- Host übergibt Machine-Rolle-Entscheidung
  nvchad_bridge = false,                       -- optionaler NvChad-Adapter
  mason_ensure_install = nil,                  -- optionaler Callback statt require()
  tools = {
    eslint_prettier = { enable = true, filetypes = {...} },
    lsp_signature = { enable = true },
    ts_type_lookup = { enable = true },
    deprecated_help = { enable = true },
  },
})
```

Commands (bereits vorhanden, bleiben stabil): `:LspDoctor[!] [mode]`,
`:LspFormat*`, `:LspWorkspaceDiagnostics{Toggle,On,Off,Status,Now}`,
`:LspStartHere`/`:LspStopHere`/`:LspRestartHere` (aus `usercmds/completion.lua`
ableitbar, aktuelle Implementierung der Commands selbst nicht vollständig
gegengelesen — beim Umzug verifizieren).

---

## 6. Dokumentationspflichten

Wie in [NEW_Project.md](./MATERIALS/NEW_Project.md) festgelegt:

- `README.md` (deutsch) — ASCII-Art + Badges + Table of Content (nur H2)
- `/doc/lsp.txt` (englisch, `:h lsp.nvim`-fähig)
- `/docs/ROADMAP.md` — künftige Features, die nicht sofort umgesetzt werden
- **`:checkhealth lsp`** — Pflicht laut Vorgabe. Aktuell existiert nur das
  Custom-Command `:LspDoctor health`; das ist **kein** `:checkhealth`-Provider.
  Sinnvoll: dünner `health.lua`, der `lspdoctor.health.check()` intern
  aufruft und über `vim.health.{ok,warn,error,start}` ausgibt — kein Code-
  Duplikat, nur eine zweite dünne Schnittstelle auf denselben Kern.

---

## 7. Migrationsplan

1. Repo `lsp.nvim` (existiert nicht — im Gegensatz zu `dap.nvim` noch nicht
   angelegt) unter `C:\repos\lsp.nvim` erstellen, Grundgerüst (README, doc,
   ROADMAP, `:checkhealth`) nach Vorlage der anderen `*.nvim`-Repos.
2. `lua/lsp/**` 1:1 kopieren, **außer** `debug_adapters/**` (→ separat nach
   `dap.nvim` verschieben, unabhängig von dieser Migration terminierbar).
3. Host-Kopplungen auflösen (`machine.*`, `config.mason.*`, `nvchad.*`) —
   durch Opts/Callbacks ersetzen, s. §2 und §5.
4. Root-Resolver-Duplikate (`core/root_scope*.lua`,
   `servers/{lua_ls,marksman}/rootresolver.lua`) gegen `lib.nvim.fs.find_root`
   / `polymorphic_rootresolver` prüfen und wo möglich ersetzen.
5. `:checkhealth`-Brücke ergänzen (s. §6).
6. In der Host-Config `require("lsp").setup(...)` durch
   `require("lsp.nvim").setup(...)` (Plugin-Import) ersetzen; alten
   `lua/lsp/`-Ordner erst löschen, wenn das neue Plugin nachweislich lädt
   (`:LspDoctor`, Formatter-Toggle, mind. 2-3 Server manuell getestet).
7. Diesen Roadmap-Eintrag (`lsp.md`) nach Abschluss auf „abgeschlossen“
   setzen, analog zur bestehenden Memory-Notiz zu `lib.nvim` (s.
   `lib-nvim-extraction.md` in der Memory).

---

## 8. Brainstorm: fehlende / neue Features

Ideen, die über den reinen 1:1-Umzug hinausgehen — nicht alle sofort
umsetzen, aber in `docs/ROADMAP.md` des neuen Plugins festhalten:

| Feature | Nutzen | Aufwand |
|---|---|---|
| **Inlay-Hints-Toggle** (`vim.lsp.inlay_hint`, global + per-Filetype) | Aktuell nirgends in `lua/lsp/` referenziert, obwohl seit Neovim 0.10 nativ verfügbar | klein |
| **Code-Action-Indikator** (virtuelles Zeichen/Sign, wenn `textDocument/codeAction` etwas liefert) | Sichtbarkeit ohne manuelles `<leader>ca`-Drücken | mittel |
| **`:LspLog`-Wrapper** (Log-Level-Toggle + Tail-Viewer im Scratch-Buffer, analog zu `lspdoctor`s Renderer) | Debugging von Server-Abstürzen aktuell nur über rohes `vim.lsp.log`-File | klein (Renderer existiert schon in lspdoctor, nur neue Datenquelle) |
| **Auto-Restart mit Backoff** bei Client-Crash | `core/attach.lua` hat aktuell keine Crash-Behandlung | mittel |
| **Formatter-Prioritäts-Konflikte sichtbar machen** | `lspdoctor` hat bereits `formatter_priority`-Option und `show_conflicts`, aber unklar ob das tatsächlich in `formatter/conform.lua` durchgesetzt wird — verifizieren, ob Doku und Verhalten noch übereinstimmen | klein (Audit) |
| **Workspace-Symbol-/Call-Hierarchy-Picker** über `pickers.nvim` statt Ad-hoc-Telescope in `ts_type_lookup` | Konsistente Picker-UI projektweit, `ts_type_lookup` hat aktuell eine eigene Telescope-Anbindung nur für TS | mittel |
| **Per-Projekt-Override** (`.nvim-lsp.json` oder ähnlich im Repo-Root) | Erlaubt z. B. Server X in Projekt Y zu deaktivieren, ohne globale Config zu ändern | mittel-groß |
| **Multi-Root/Monorepo-Workspace-Switcher** als eigenständiges Feature statt implizit in `root_scope_picker` | Formalisiert etwas, das anscheinend schon halb existiert | klein (Aufwertung) |
| **Hover-Cache** via `lib.lua.memo` | Wiederholtes Hover auf derselben Position/Version spart einen LSP-Roundtrip | klein |
| **Test-Entry-Point** (`tools/_test`) | Fehlt komplett laut Durchsicht — widerspricht Testbarkeits-Leitlinie (§6 Arch&Coding-Regeln) | mittel (erste Tests aufsetzen) |
| **Diagnostics-Debounce** bei `textDocument/publishDiagnostics` | `core/handlers.lua` dedupliziert bereits, debounced aber nicht bei sehr chattry Servern (z. B. `ts_ls` bei großen Dateien) | klein |
| **Signature-Help-Modul durch native/lib-Variante ersetzen** | `tools/lsp_signature/**` ist eine komplette Eigenimplementierung (Hover-Formatierung, Highlights, State) — prüfen ob das reduzierbar ist, sobald native `vim.lsp.buf.signature_help`-Fähigkeiten reichen | groß (Rewrite-Risiko, erstmal nur beobachten) |

---

## 9. Offene Fragen / Risiken

- **Windows-Kompatibilität**: `formatter/init.lua` dokumentiert sich selbst
  als "Linux/macOS only". Vor der Extraktion klären, ob das eine bewusste
  Einschränkung ist oder ein Windows-Pfad nachgezogen werden muss (diese
  Workstation läuft laut vorhandener Memory-Notiz zum OneDrive/PowerShell-
  Freeze auf Windows).
- **`lspdoctor` vs. `:checkhealth`**: zwei parallele Diagnose-Wege
  (`:LspDoctor` und künftiges `:checkhealth lsp`) — sollten denselben Kern
  (`lspdoctor/health.lua`) nutzen, nicht divergieren.
- **NvChad-Abhängigkeit**: `core/attach.lua` und `lspdoctor` referenzieren
  `nvchad.config.lspconfig` direkt per `pcall(require, ...)`. Für echte
  Wiederverwendbarkeit (das erklärte Ziel aus `nvim.md`) sollte das ein
  optionaler Adapter werden, kein impliziter Fallback-Pfad.
- **Registry-Liste hart codiert**: `core/registry.lua`s `ACTIVE`-Tabelle ist
  aktuell mit auskommentierten Servern im Sourcecode gepflegt — sollte beim
  Umzug in `opts.servers` wandern (s. §5), sonst bleibt Server-An/Aus weiterhin
  ein Code-Edit statt Konfiguration.
