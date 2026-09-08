# my.nvim — was fehlt, um NvChad vollständig zu ersetzen

Stand: 2026-08-29. Ausgangspunkt: das Konzept in
[`nvim.nvim.md`](nvim.nvim.md) (künftiges UI-Plugin, `options.nvim`-Idee) plus
die offene Frage aus `docs/ROADMAP/personal/All/FINISH/MERGED.md`, Liste A:
*"Was fehlt, um nvchad komplett zu ersetzen?"*.

Dieses Dokument beantwortet drei Dinge:

1. **Was NvChad in dieser Config tatsächlich ist** — gemessen, nicht erinnert.
2. **Was pro Domäne zu bauen wäre**, mit Ausbaustufen (Fremdplugin als
   Zwischenschritt, eigenes Plugin als Ziel) und Aufwand/Nutzen je Stufe.
3. **Was der vorhandene Plugin-Bestand (31 Repos) dabei wirklich wert ist** —
   inklusive der Gegenargumente.

Aufwands- und Nutzenklassen sind dieselben wie in
`docs/ROADMAP/personal/All/PLUGIN_ROADMAPS.md`, damit die Zahlen vergleichbar
bleiben.

---

## Table of content

  - [Legende](#legende)
  - [Kurzfassung](#kurzfassung)
  - [Teil 1 — Bestandsaufnahme](#teil-1--bestandsaufnahme)
    - [1.1 Der NvChad-Stack in Zahlen](#11-der-nvchad-stack-in-zahlen)
    - [1.2 Was davon aktiv benutzt wird](#12-was-davon-aktiv-benutzt-wird)
    - [1.3 Was schon abgelöst oder tot ist](#13-was-schon-abgelöst-oder-tot-ist)
    - [1.4 Das Plugin-Bundle: was exklusiv aus NvChad kommt](#14-das-plugin-bundle-was-exklusiv-aus-nvchad-kommt)
  - [Teil 2 — Domänen-Matrix](#teil-2--domänen-matrix)
    - [D1 · Plugin-Bundle ablösen](#d1--plugin-bundle-ablösen)
    - [D2 · nvconfig-Shim — der Enabler](#d2--nvconfig-shim--der-enabler)
    - [D3 · Statusline](#d3--statusline)
    - [D4 · Tabufline](#d4--tabufline)
    - [D5 · base46 (Theme-Engine)](#d5--base46-theme-engine)
    - [D6 · Terminal](#d6--terminal)
    - [D7 · Menü (nvzone/menu + volt)](#d7--menü-nvzonemenu--volt)
    - [D8 · Minty (Farbpicker)](#d8--minty-farbpicker)
    - [D9 · Colorify (Inline-Farben)](#d9--colorify-inline-farben)
    - [D10 · LSP-Beiwerk](#d10--lsp-beiwerk)
    - [D11 · Hot-Reload](#d11--hot-reload)
    - [D12 · Icons](#d12--icons)
    - [D13 · NvDash, Cheatsheet, Options/Mappings/Autocmds](#d13--nvdash-cheatsheet-optionsmappingsautocmds)
  - [Teil 3 — Ausbaustufen](#teil-3--ausbaustufen)
  - [Teil 4 — Plugin-Zuschnitt](#teil-4--plugin-zuschnitt)
  - [Teil 5 — Was der Plugin-Bestand wert ist](#teil-5--was-der-plugin-bestand-wert-ist)
    - [5.1 Distro-Domänen: Abdeckung](#51-distro-domänen-abdeckung)
    - [5.2 Was die 31 Plugins konkret einsparen](#52-was-die-31-plugins-konkret-einsparen)
    - [5.3 Gegenargumente, ehrlich](#53-gegenargumente-ehrlich)
  - [Teil 6 — Gesamtbild und Empfehlung](#teil-6--gesamtbild-und-empfehlung)
  - [Teil 7 — Offene Entscheidungen (braucht dich)](#teil-7--offene-entscheidungen-braucht-dich)

---

## Legende

**Aufwand**:

| | |
|---|---|
| **XS** | unter einer Stunde |
| **S** | wenige Stunden |
| **M** | ein Arbeitstag oder mehr |
| **L** | mehrere Sessions |

**Nutzen**: hoch / mittel / niedrig — gemessen daran, ob der Punkt eine echte
Abhängigkeit auflöst oder einen Defekt schließt (hoch), eine vorhandene
Fähigkeit verbessert (mittel) oder eine bisher nicht vermisste Fähigkeit
hinzufügt (niedrig).

**Stufe**: Ausbauvariante. *Stufe 1* = Zwischenzustand mit Fremdplugin,
*Stufe 2* = eigenes Plugin, *Stufe 0* = so lassen.

---

## Kurzfassung

- NvChad ist hier **fünf Repos mit zusammen ~17.400 LOC**: `NvChad` (629),
  `ui` (3.704), `base46` (9.864), `volt` (1.382), `menu` (805), `minty`
  (1.001). Zum Vergleich: `lua/` dieser Config hat 45.854 LOC, davon 4.460
  im NvChad-nahen eigenen `wkdnvchad/`-Baum.
- **Der Ersatz ist kein einzelnes Projekt, sondern dreizehn getrennte
  Domänen**, von denen vier schon erledigt sind (NvDash, Cheatsheet,
  Options/Mappings/Autocmds, nvim-tree) und sechs für unter einen Arbeitstag
  zu haben sind.
- **Der teure Rest sind genau zwei Dinge: Statusline und Tabline.** Alles
  andere ist entweder XS/S oder gehört fachlich in ein bestehendes eigenes
  Plugin (`lsp.nvim`, `lib.nvim`, `sandbox.nvim`).
- **base46 sollte nicht ersetzt werden.** 9.864 LOC, 95 Themes, 46
  Plugin-Integrationen, ein Byte-Cache mit echtem Startup-Nutzen — und es ist
  ein eigenständiges Repo, das ohne den Rest von NvChad läuft, sobald ein
  ~40-zeiliger `nvconfig`-Shim existiert. Das ist der beste
  Aufwand/Nutzen-Punkt im ganzen Dokument (XS für hoch).
- **Ein lualine-Zwischenschritt wird nicht gebraucht.** `nvchad.stl`
  funktioniert weiter, solange das `ui`-Repo installiert bleibt. Die Kette
  "NvChad-Statusline → lualine → eigene" wäre zweimal migrieren statt
  einmal. Bei der Tabline sieht das anders aus (siehe D4).
- **Der größte Einzel-Hebel ist `wkdnvchad/` → `ui.nvim`.** 4.460 LOC
  eigener Statusline-Module liegen heute in einem Fork-förmigen Config-Baum,
  der weder NvChad noch Plugin ist. Sie in ein Repo zu heben verwandelt
  Sackgassen-Code in ein lieferbares Plugin — und ist gleichzeitig die
  Antwort auf die offene Frage aus `nvim.nvim.md`, was in das UI-Plugin
  gehört.
- **Der Plugin-Bestand ist der Grund, warum das überhaupt realistisch ist**:
  11 von 18 Distro-Domänen sind bereits eigener Code, und der
  Distro-Mechanismus selbst (Spec-Bundle per `import`, Quellsteuerung
  dir/remote/disabled) läuft hier produktiv — `lsp.nvim` macht exakt das,
  was `nvchad.plugins` macht, nur besser.

---

# Teil 1 — Bestandsaufnahme

---

## 1.1 Der NvChad-Stack in Zahlen

Fünf Repos, gezogen über `{ import = "nvchad.plugins" }` in `init.lua:87`
plus den expliziten `NvChad/NvChad`-Spec darüber.

| Repo | LOC | Rolle |
|---|---|---|
| `NvChad/NvChad` (v2.5) | 629 | Plugin-Bundle (17 Specs) + `configs/` (cmp, gitsigns, lspconfig, luasnip, mason, nvimtree, telescope, treesitter) + `options.lua`, `mappings.lua`, `autocmds.lua` |
| `nvchad/ui` (v3.0) | 3.704 | `nvconfig.lua` (Default-Schema), Statusline (4 Varianten), Tabufline, NvDash, Term, Cheatsheet (2 Varianten), Colorify, Theme-Picker, LSP-Signature/Renamer, Mason-UI, cmp-/blink-Format, Icons, Winmes, Telescope-Extensions |
| `nvchad/base46` (v3.0) | 9.864 | Theme-Engine: 95 Themes, 46 Plugin-Integrationen, Highlight-Compiler + Byte-Cache |
| `nvzone/volt` | 1.382 | Float-Render-Bibliothek (Unterbau von menu/minty) |
| `nvzone/menu` | 805 | Kontextmenü |
| `nvzone/minty` | 1.001 | Farbpicker (`:Huefy`, `:Shades`) |
| **Summe** | **~17.385** | |

Der Cache unter `nvim-data/base46/` enthält heute 18 kompilierte Dateien
(`defaults`, `syntax`, `statusline`, `telescope`, `treesitter`, `lsp`,
`git`, `mason`, `whichkey`, `blankline`, `devicons`, `cmp`, `blink`,
`nvimtree`, `nvcheatsheet`, `tbline`, `term`, `colors`).

---

## 1.2 Was davon aktiv benutzt wird

| NvChad-Modul | Wo es hier hängt |
|---|---|
| `base46` | Theme `tokyonight`, Toggle-Paar `vim_default`/`tokyonight` (`wkdnvchad/config/base46.lua`); `dofile`-Cache-Loads in `init.lua:93-95`; `wkdnvchad/usrcmd/themes/` (359 eigene LOC) treibt `load_all_highlights`/`toggle_transparency`/Theme-Liste; `filetree_cwd_mode` liest `base46.get_theme_tb("base_30")` |
| `nvchad.stl.*` | **Die aktive Statusline.** `wkdnvchad/config/init.lua:21` steht auf Variante `"normal"`, also NvChad-Default über `vim.o.statusline` |
| `nvchad.tabufline` | Aktiv; `wkdnvchad/mappings/tabufline/` und `bindings/mappings/buffer_jump.lua` lesen `vim.t.bufs` und rufen `goto_buf` |
| `nvchad.term` | `<A-h>` Float-Terminal (`bindings/mappings/terminal.lua:24`) + ein Menü-Eintrag |
| `nvchad.themes` | `<leader>nvt` Theme-Switcher (`bindings/mappings/nvchad.lua:26`) |
| `nvchad.colorify` | Läuft (nvconfig-Default `enabled = true`, chadrc überschreibt es nicht) |
| `nvchad.lsp.signature` | LspAttach-Handler im eigenen Override `lua/nvchad/au.lua:33` |
| `nvchad.mason` | `:MasonInstallAll` (`lua/nvchad/au.lua:69`) |
| `nvchad.utils.reload` | Hot-Reload beim Speichern (`lua/nvchad/au.lua:62`) |
| `nvchad.cmp` / `nvchad.blink` | Optik des Completion-Menüs über `nvconfig.ui.cmp` |
| `nvchad.icons.devicons` | Devicon-Override im Bundle-Spec |
| `nvzone/menu` + `volt` | `lua/config/menu/**` (601 LOC): Rechtsklick / `<A-b>` |
| `nvzone/minty` | `:Huefy` aus dem Custom-Menü |
| `nvconfig` | Schema, das `chadrc.lua` füttert — **und das `base46` direkt selbst lädt** (`base46/init.lua:3`) |

---

## 1.3 Was schon abgelöst oder tot ist

| NvChad-Modul | Status |
|---|---|
| NvDash | Ausdrücklich abgeschaltet (`plugins/snacks.lua:30-32`), es gibt bewusst gar kein Dashboard |
| Cheatsheet | Keymap auskommentiert (`bindings/mappings/nvchad.lua:25`); `:Bindings` (`bindings/usrcmds/bindings_explorer/`) ist der Ersatz |
| `nvchad.options` | `require` auskommentiert (`lua/options.lua:4`) |
| `nvchad.mappings` | Nirgends referenziert |
| `nvchad.autocmds` | Durch den eigenen Override `lua/nvchad/au.lua` ersetzt (Startup-Grund: der Upstream globt ~450 Dateien, ~600 ms) |
| `nvim-tree.lua` | Installiert, aber ungenutzt — die Config fährt neo-tree + `filetree.nvim` |
| `nvchad.configs.*` | Weitgehend durch eigene Specs überstimmt (treesitter, telescope, gitsigns eigen; cmp/lspconfig/mason über `lsp.nvim`s Pack) |
| Winmes | Einmalige Ankündigungs-Box, irrelevant |

**Vier von dreizehn Domänen sind also bereits erledigt** — ohne dass das
bisher irgendwo als Fortschritt verbucht war.

---

## 1.4 Das Plugin-Bundle: was exklusiv aus NvChad kommt

Entscheidend für D1, weil es die Frage beantwortet, was beim Entfernen des
Imports tatsächlich verschwindet. Geprüft gegen `lua/plugins/**` und
`lsp.nvim/lua/lsp/pack/**`:

**Exklusiv im Bundle (verschwindet ersatzlos):**

- `folke/which-key.nvim` — wird gebraucht (`<leader>wK`, `<leader>wk`)
- `lukas-reineke/indent-blankline.nvim` — wird gebraucht
- `nvzone/volt` — **Achtung**: `nvzone/menu` hat einen eigenen Spec in
  `plugins/nvchad.lua`, `volt` nicht. Ohne volt ist menu kaputt.
- `nvzone/minty`
- Die cmp-Quellen: `cmp-nvim-lsp`, `cmp-buffer`, `cmp-nvim-lua`,
  `cmp_luasnip`, `cmp-async-path`
- `rafamadriz/friendly-snippets` und die LuaSnip-Konfiguration
  (`nvchad.configs.luasnip`)
- Der autopairs-zu-cmp-`confirm_done`-Kleber
- `nvim-tree/nvim-tree.lua` — wird nicht gebraucht, guter Wegfall

**Überlebt (eigener Spec vorhanden), verliert aber die NvChad-`opts`:**

- `plenary.nvim` (10 eigene Referenzen)
- `nvim-web-devicons` (verliert Icon-Override + base46-`devicons`-Cache)
- `conform.nvim`, `gitsigns.nvim`, `mason.nvim`, `nvim-lspconfig`,
  `nvim-cmp`, `telescope.nvim`, `nvim-treesitter`, `nvim-autopairs`
- `base46` und `ui` selbst — die müsstest du dann direkt deklarieren, falls
  du sie behalten willst (was die Empfehlung ist)

---

# Teil 2 — Domänen-Matrix

---

## D1 · Plugin-Bundle ablösen

**Aufwand S · Nutzen hoch**

`{ import = "nvchad.plugins" }` aus `init.lua:87` entfernen und die 17 Specs
selbst deklarieren. Nach 1.4 sind das real nur **sechs neue Spec-Blöcke**
(which-key, indent-blankline, volt, minty, cmp-Quellen-Sammelspec,
friendly-snippets/LuaSnip-Glue) plus zwei direkte Deklarationen für `base46`
und `ui`, wenn die bleiben sollen.

Warum das zuerst kommt: solange der Import steht, ist nicht überprüfbar,
welche Plugin-Optionen aus NvChad stammen und welche aus dieser Config. Nach
dem Schritt ist jeder Spec an genau einer Stelle sichtbar — und alle
weiteren Domänen lassen sich einzeln herausdrehen, ohne dass unklar bleibt,
was mit herausfällt.

Risiko: die stillen `nvchad.configs.*`-`opts` (Telescope-Border,
gitsigns-Zeichen, treesitter-Defaults) fallen weg. Die meisten sind bereits
überstimmt; der Rest ist ein Sichtvergleich vorher/nachher.

*Stufe 0 gibt es hier nicht — das ist die Voraussetzung für alles andere.*

---

## D2 · nvconfig-Shim — der Enabler

**Aufwand XS · Nutzen hoch**

`base46/init.lua:3` und `base46/color_vars.lua:1` machen
`require("nvconfig").base46`. `nvconfig.lua` liegt im **`ui`-Repo**, nicht in
base46. Das ist die einzige Klammer, die verhindert, dass man `ui` entfernt
und base46 behält.

Ein eigenes `lua/nvconfig.lua` (oder später `my.nvconfig`) mit dem
`base46`-Teilbaum plus den paar Feldern, die base46 sonst noch liest, löst
das auf. `chadrc.lua` kann unverändert bleiben oder gleich mit verschmelzen.

Das ist der Punkt mit dem besten Verhältnis im ganzen Dokument: eine
Dreiviertelstunde, und die 9.864 LOC Theme-Engine sind von den 3.704 LOC
UI-Schicht entkoppelt.

---

## D3 · Statusline

**Stufe 1 (lualine): Aufwand S–M · Nutzen niedrig — nicht empfohlen**
**Stufe 2 (eigene): Aufwand M · Nutzen mittel**

Was NvChad liefert: `nvchad.stl.{default,minimal,vscode,vscode_colored}` plus
`stl.utils` (Redraw-Autocmds, Highlight-Gruppen aus base46s
`statusline`-Integration). Aktiv ist `default`.

Was schon da ist — und das ist der springende Punkt: **`lua/wkdnvchad/` sind
4.460 LOC eigener Statusline-Module.** Breadcrumbs, LSP-Symbole
(Document-Symbols + Treesitter-Fallback), `cursor_ctl` mit eigenen
Progress-Kalkulatoren und Renderer, `plugin_summary`, `plugin_progress`,
`neotest_module`, `filetree_cwd_mode`, `formatters`, `casedesk`,
`highlighting`, Separator- und Nerd-Font-Helfer. Sechs Varianten-Configs
(`normal`, `base`, `lspbased`, `custom`, `custom_light`, `custom_minimal`)
liegen fertig daneben und sind derzeit nur nicht aktiviert.

Was fehlt, ist also nicht der Inhalt, sondern **der Rahmen**: Renderer,
Segment-Registry, Highlight-Auflösung, Re-Evaluations-Autocmds, global vs.
fensterlokal (`laststatus = 3`). Realistisch 600–1.200 LOC. Mit
`lib.nvim.ui.hl` (Namespaces, idempotente Definition) und
`lib.nvim.ui.kit.theme` (Token-Schema, Presets, Links auf Standardgruppen)
als Unterbau ist das ein Arbeitstag, keine Wochen — deshalb **M, nicht L**.

**Warum lualine als Zwischenschritt nicht empfohlen ist:** `nvchad.stl`
funktioniert weiter, solange das `ui`-Repo installiert bleibt. Eine
lualine-Phase heißt: einmal auf lualines Komponenten-API portieren, dann noch
einmal auf die eigene. Zweimal migrieren für einen Zwischenzustand, der nicht
besser ist als der jetzige.

Die Kopplung ist ohnehin schwach: `sandbox.nvim`s `statusline.status()` und
`filetree.nvim`s `cwd_mode.component()` liefern beide reinen Klartext ohne
Highlight-Escapes und dokumentieren ausdrücklich drei Konsumenten (nativ,
heirline, lualine). Sie hängen an lualine also **gar nicht** — das ist in
`nvim.nvim.md` bereits festgehalten und bestätigt sich hier.

Zu klären beim Bau: `lib.nvim.ui.statusline` ist **nicht** der Unterbau. Das
ist ein an ein Fenster geheftetes Badge mit Float-Ausweichstrategie unter
`laststatus = 3` — andere Domäne, ersetzt nichts.

---

## D4 · Tabufline

**Stufe 1 (bufferline.nvim / mini.tabline): Aufwand S · Nutzen mittel**
**Stufe 2 (eigene): Aufwand M · Nutzen mittel**

Der eigentliche Lock-in ist nicht das Zeichnen, sondern **`vim.t.bufs`** —
NvChads eigener, tab-lokaler Buffer-Reihenfolgespeicher. Zwei Stellen lesen
ihn direkt: `wkdnvchad/mappings/tabufline/` und
`bindings/mappings/buffer_jump.lua` (das zusätzlich `goto_buf`/`go_to`
aufruft).

Hier ist ein Zwischenschritt **anders zu bewerten als bei der Statusline**:
jede Alternative bringt ihr eigenes Reihenfolgemodell mit, also müssen die
zwei Konsumenten so oder so umgeschrieben werden. Wer die Kopplung früh
brechen will, kann das direkt gegen eine eigene, kleine Buffer-Order-API tun
(gehört fachlich neben `buffer-ctx.nvim` / `sessions.nvim`) und die
Darstellung zunächst offen lassen.

Umfang eines eigenen Tabline-Moduls: Buffer-Liste mit stabiler Reihenfolge,
Close-Semantik, Tree-Offset (die Spalte, die neo-tree freilässt),
Modified-Indikator, Klickbereiche. ~400–700 LOC.

---

## D5 · base46 (Theme-Engine)

**Stufe 0 (behalten): Aufwand XS (nur D2) · Nutzen hoch — empfohlen**
**Stufe 1 (tokyonight + eigene Overrides): Aufwand S–M · Nutzen niedrig**
**Stufe 2 (eigene Engine `theme.nvim`): Aufwand L · Nutzen niedrig — nicht empfohlen**

Der einzige Punkt in diesem Dokument mit klar schlechtem Verhältnis, wenn man
ihn angeht.

Was ein Ersatz kosten würde: 95 Themes, 46 Integrationsdateien (pro Plugin ein
Highlight-Satz), der Compiler und der Byte-Cache (`str_to_cache` → `dofile`,
ein echter Startup-Gewinn), dazu `get_theme_tb("base_30")` (von
`filetree_cwd_mode` benutzt), `toggle_theme`, `toggle_transparency`,
`override_theme` — und der Theme-Picker, für den `wkdnvchad/usrcmd/themes/`
schon 359 eigene LOC hat.

Was ein Ersatz einbrächte: nichts, was heute fehlt.

base46 ist ein **eigenständiges Repo**. Nach D2 läuft es ohne den Rest von
NvChad. Das ist die Antwort: behalten, so wie `gitsigns` oder `treesitter`
behalten werden — kein Distro-Rest, sondern ein normales Fremdplugin mit
klarer Aufgabe.

Stufe 1 (auf `tokyonight.nvim` umsteigen, das ohnehin installiert ist, und
eigene Overrides in `wkdoptions` legen) ist nur dann sinnvoll, wenn dich
konkret stört, dass base46 den Farbraum vorgibt. Dann fällt aber der
Theme-Picker, das Toggle-Paar und `base_30` weg — drei Features, die heute
funktionieren.

---

## D6 · Terminal

**Stufe 1 (snacks.terminal): Aufwand XS · Nutzen mittel**
**Stufe 2 (eigenes Modul): Aufwand S · Nutzen mittel**

`nvchad.term` wird an genau zwei Stellen benutzt: `<A-h>` Float-Toggle und ein
Menü-Eintrag. Die restlichen Term-Keymaps in `bindings/mappings/terminal.lua`
sind auskommentiert.

`snacks.nvim` ist installiert und hat `snacks.terminal` — ein Ein-Zeilen-Tausch.
Für Stufe 2: `lib.nvim.terminal` hat heute nur Helfer (Pfad-Escaping,
Buffer-Erkennung, Kitty-Detection), keinen Toggle-Manager. Ein solcher
(ID-basierte, positionierbare, persistente Terminal-Buffer) sind ~250 LOC und
passen entweder in `lib.nvim.terminal` oder — wegen der Prozessverwaltung —
neben `sandbox.nvim`.

---

## D7 · Menü (nvzone/menu + volt)

**Aufwand S–M · Nutzen mittel**

In `nvim.nvim.md` bereits vorentschieden und hier nur zu bestätigen:
`lib.nvim.ui.kit.menu` existiert und ist getestet (`TESTS/ui_kit_spec.lua`),
`filetree.nvim` hat sein eigenes `context_menu`-Feature. nvzone/menu ist damit
heute ablösbar.

Offen ist der **Nicht-Tree-Teil**: `lua/config/menu/**`, 601 LOC —
Markdown-Menü über `markdown.integrations.menu`, der `<A-b>`-Fallback und der
Dispatcher in `mappings.lua`. Der Inhalt bleibt, der Trigger und das Rendering
wandern von `nvzone/menu` auf `ui.kit.menu`.

Nebeneffekt, der zählt: fällt menu, fällt auch `volt` (1.382 LOC) — es
existiert hier nur als dessen Unterbau. Zwei Repos für einen Umbau.

---

## D8 · Minty (Farbpicker)

**Stufe 0 (fallen lassen): Aufwand XS · Nutzen niedrig**
**Stufe 2 (eigener Picker auf `ui.kit`): Aufwand S · Nutzen niedrig**

`:Huefy` wird nur aus dem Custom-Menü aufgerufen. Wenn du es benutzt, ist ein
eigener HSV-Picker auf `ui.kit.surface` ein überschaubares Nachmittagsprojekt;
wenn nicht, ist der Eintrag zu streichen der ganze Aufwand.

---

## D9 · Colorify (Inline-Farben)

**Stufe 1 (nvim-highlight-colors): Aufwand XS · Nutzen niedrig**
**Stufe 2 (eigenes Modul): Aufwand S–M · Nutzen niedrig**

Läuft heute per nvconfig-Default. Ein eigenes Modul (Extmarks, Hex-/RGB-/
LSP-Farbvariablen, virtueller Text oder Hintergrund) ist ~250–350 LOC — und
`color_my_ascii.nvim` ist der nächstgelegene eigene Codebase dafür, weil es
bereits Highlight-Gruppen auf Buffer-Bereiche anwendet.

Ehrliche Einordnung: das ist Kosmetik. Es blockiert nichts und niemand
vermisst es, wenn es zwei Wochen fehlt.

---

## D10 · LSP-Beiwerk

*(Signature, Renamer, Mason-UI, cmp-Format)*

**Aufwand S je Teil · Nutzen mittel**

Die saubersten "gehört eigentlich woandershin"-Punkte, weil das Zielrepo schon
existiert und die Domäne besitzt:

| Teil | Ziel | Anmerkung |
|---|---|---|
| `nvchad.lsp.signature` | `lsp.nvim` | Signature-Help-Float bei Trigger-Zeichen; `lib.nvim.hover` ist der Unterbau |
| `nvchad.lsp.renamer` | — | Bereits abgedeckt: `inc-rename.nvim` ist über `lsp.pack.ui` installiert |
| `nvchad.mason.install_all` | `lsp.nvim` | `:MasonInstallAll` liest heute `nvconfig.mason.pkgs`; `lsp.nvim` hat mit `mason.ensure_install` schon das passende Options-Feld |
| `nvchad.cmp.format` / `nvchad.blink.config` | `lsp.nvim` | Optik des Completion-Menüs; `lsp.pack.completion*` deklariert beide Engines bereits |

Diese vier zusammen sind der Grund, warum `ui` am Ende leichter fällt als es
nach 3.704 LOC aussieht: ein spürbarer Teil davon gehört gar nicht in ein
UI-Plugin.

---

## D11 · Hot-Reload

**Aufwand XS · Nutzen mittel**

Der Autocmd ist schon eigener Code (`lua/nvchad/au.lua`, der Upstream-Override
wegen des ~600-ms-Globs). Übrig bleibt `nvchad.utils.reload(module)` selbst:
`package.loaded[mod] = nil`, `require`, plus base46-Highlights neu laden. 20–40
Zeilen, gehört nach `lib.nvim.dev` (existiert, enthält bisher nur
`duplicates.lua`).

---

## D12 · Icons

**Aufwand XS · Nutzen niedrig**

`nvchad.icons.devicons` ist eine Override-Tabelle, `nvchad.icons.lspkind` eine
Symboltabelle. Beide sind reine Daten. Kopieren, in `plugins/ui_icons.lua` bzw.
`lsp.nvim` legen, fertig. Der base46-`devicons`-Cache bleibt, solange base46
bleibt.

---

## D13 · NvDash, Cheatsheet, Options/Mappings/Autocmds

**Aufwand 0 · erledigt**

Nichts zu tun (siehe 1.3). Zwei Anmerkungen für später:

- **Dashboard**: es gibt bewusst keins. Falls doch je eins kommen soll, wäre
  die Kombination `color_my_ascii.nvim` (Header) + `sessions.nvim`
  (Projekt/Branch-Wiederaufnahme) + `insights.nvim` (Projektüberblick) +
  `github_stats.nvim` ein Dashboard, das keine Distro hat. Nutzen niedrig,
  Schauwert hoch.
- **Cheatsheet**: `:Bindings` ist inhaltlich weiter als NvChads Grid, weil es
  über die BINDINGS-Dokumente sucht statt über registrierte Keymaps.

---

# Teil 3 — Ausbaustufen

Reihenfolge nach Verhältnis, jede Stufe ist ein gültiger Endzustand — man kann
jederzeit aufhören.

### Stufe 0 — heute

NvChad vollständig installiert, vier Domänen faktisch schon ersetzt, aber alle
fünf Repos hängen drin.

### Stufe 1 — "NvChad ohne NvChad-Core" · Aufwand S–M · Nutzen hoch

D1 (Bundle selbst deklarieren) + D2 (`nvconfig`-Shim) + D11 (reload) + D12
(Icons) + `nvim-tree` fällt weg.

Ergebnis: `NvChad/NvChad` (629 LOC) ist raus. `base46` und `ui` bleiben, aber
als zwei normale, direkt deklarierte Fremdplugins. Jeder Spec dieser Config ist
ab hier an genau einer Stelle sichtbar.

**Das ist der Punkt, an dem man ohne Weiterbau stehen bleiben könnte** und
schon den Großteil des Kontrollgewinns hätte.

### Stufe 2 — "ui entkernen" · Aufwand M · Nutzen mittel

D6 (Terminal → snacks oder eigen) + D10 (LSP-Beiwerk → `lsp.nvim`) + D9
(Colorify) + D7 (Menü → `ui.kit.menu`, damit fällt auch `volt`) + D8 (minty).

Ergebnis: von `ui` werden nur noch Statusline und Tabufline gebraucht.
`nvzone/volt`, `nvzone/menu`, `nvzone/minty` sind raus (3.188 LOC).

### Stufe 3 — `ui.nvim` · Aufwand M–L · Nutzen mittel

D3 (Statusline) + D4 (Tabline). Der `wkdnvchad/`-Baum wird zum Repo.

Ergebnis: `nvchad/ui` ist raus. Übrig bleibt `base46` als einziges
NvChad-Repo — und das ist dann kein Distro-Rest mehr, sondern ein
Colorscheme-Plugin.

### Stufe 4 — `theme.nvim` · Aufwand L · Nutzen niedrig

D5 Stufe 2. **Ausdrücklich nicht empfohlen**, siehe D5. Aufgeführt nur der
Vollständigkeit halber, damit die Entscheidung dokumentiert ist statt
vergessen.

---

# Teil 4 — Plugin-Zuschnitt

Die Frage aus `nvim.nvim.md` ("eigenständiges neues Plugin, oder Teil eines
breiteren künftigen UI-Plugins?") lässt sich nach dieser Analyse beantworten:
**ein UI-Plugin, und ein Meta-Plugin darüber.**

| Repo | Inhalt | Wann |
|---|---|---|
| **`ui.nvim`** | Statusline (Renderer + die 12 vorhandenen `wkdnvchad`-Module), Tabline, Menü-Dispatcher (auf `lib.nvim.ui.kit.menu`), optional Colorify, optional Dashboard | Stufe 2–3 |
| **`options.nvim`** (oder `config.nvim`) | Der deklarative Teil aus dem ersten Abschnitt von `nvim.nvim.md`: Options, Filetype-lokale Settings, die generischen Autocmds. **Nicht** LSP, **nicht** stateful | eigenständig, unabhängig von NvChad |
| **`my.nvim`** | Das Meta-/Distro-Plugin: Spec-Bundle per `import = "my.pack"`, Config-Schema (`myrc`), Startup-Phasen-Orchestrierung | zuletzt, wenn 1–3 stehen |
| ~~`theme.nvim`~~ | base46-Ersatz | nicht bauen (D5) |

**Warum `my.nvim` realistisch ist:** der Mechanismus läuft hier bereits
produktiv. `init.lua:83` macht
`{ "StefanBartl/lsp.nvim", dir = lsppath, import = "lsp.pack" }` — ein eigenes
Plugin, das ein Bündel von Fremd-Specs mitliefert, genau wie `nvchad.plugins`.
Dazu kommt `plugins/control/mode.lua` mit Quellsteuerung pro Repo
(`dir`/`remote`/`disabled`), Maschinenrollen und `:MyPlugins mode <wert>`. Das
ist mehr, als NvChad an dieser Stelle kann.

**Was für `ui.nvim` sofort verwendbar ist:** `lib.nvim.ui.hl` (Namespaces,
idempotente Highlights), `lib.nvim.ui.kit.theme` (Token-Schema, Presets, Links
auf `NormalFloat`/`FloatBorder`/`PmenuSel`), `ui.kit.menu`, `ui.kit.surface`,
`lib.nvim.bindings.{keymap,autocmd,usercmd.composer}`, `lib.nvim.notify`.

**Namenswarnung:** `my.nvim` belegt den Lua-Top-Level-Namespace `my`,
`nvim.nvim` belegt `nvim` — letzteres ist zwar frei, liest sich aber in jedem
`require("nvim.…")` wie ein API-Aufruf. `lib`/`lsp` sind die Präzedenzfälle.
Entscheidung siehe Teil 7.

---

# Teil 5 — Was der Plugin-Bestand wert ist

## 5.1 Distro-Domänen: Abdeckung

Gemessen an dem, was eine Distro liefern muss:

| # | Domäne | Status | Träger |
|---|---|---|---|
| 1 | Manager-Bootstrap | eigen | `init.lua` (lazy + lib.nvim + lsp.nvim, mit dokumentierten Reihenfolge-Fallen) |
| 2 | Spec-Bundle-Mechanismus | eigen, **besser als NvChad** | `lsp.pack`-Muster, `plugins.control.mode` |
| 3 | Options / Autocmds / Keymaps | eigen | `options.lua`, `autocmds/`, `bindings/`, `lib.nvim.bindings.*` |
| 4 | LSP | eigen | `lsp.nvim` (Registry, Capabilities, Workspace-Diagnostics, Formatter-Toggle) |
| 5 | DAP | eigen | `dap.nvim`, `debugging.nvim` |
| 6 | Completion | eigen (Wrapper) | `lsp.pack.completion*` (cmp + blink) |
| 7 | Fuzzy-Finder | eigen (Wrapper) | `pickers.nvim` — engine-agnostisch (telescope/fzf-lua/snacks) |
| 8 | Dateibaum | eigen (Adapter) | `filetree.nvim` über neo-tree/nvim-tree |
| 9 | Git | fremd + eigen | gitsigns/neogit/diffview/fugitive, dazu `diff.nvim` |
| 10 | Sessions | eigen | `sessions.nvim` |
| 11 | Doku / Health / Types | eigen, **weit voraus** | `documentation.nvim`, `runtime-analysis.nvim`, `lib.nvim.health` |
| 12 | Terminal | teilweise | `lib.nvim.terminal` (Helfer), `sandbox.nvim` (Prozesse) |
| 13 | **Statusline** | **fremd** | `nvchad.stl` — Module eigen, Rahmen nicht |
| 14 | **Tabline** | **fremd** | `nvchad.tabufline` |
| 15 | **Theme-Engine** | **fremd** | `base46` (und soll es bleiben) |
| 16 | **Icons** | **fremd** | `nvim-web-devicons` |
| 17 | **Which-key** | **fremd** | `which-key.nvim` |
| 18 | Dashboard | bewusst keins | — |

**11 von 18 eigen, 5 sind die UI-Schale, 2 bewusst fremd.** Die Lücke ist
präzise beschreibbar und liegt vollständig in einer einzigen Schicht.

## 5.2 Was die 31 Plugins konkret einsparen

Nicht "viel Erfahrung", sondern nachprüfbar:

1. **Der Unterbau existiert.** `lib.nvim` liefert bindings-Composer, notify,
   `ui.kit` (18 Komponenten: surface, chooser, menu, form, input, picker,
   preview, prompt, select, toast, viewer, theme, layout …), fs, cross, health,
   store, logger, async, treesitter, hover. Ein neues `ui.nvim` startet nicht
   bei null, sondern bei geschätzt einem Drittel.
2. **Der Distro-Mechanismus läuft produktiv** (siehe Teil 4). Das ist
   üblicherweise der Teil, an dem selbstgebaute Distros scheitern.
3. **Die Konventionen stehen**: `@types`-Bäume, README je Modul,
   `:DocMap check` gegen Doku-Drift, Telemetrie über `runtime-analysis.nvim`,
   `:Recommender perf` für Lua-Anti-Patterns, `migrate.nvim` für
   API-Deprecations. Der echte Preis einer Distro ist Wartung über
   Neovim-Releases hinweg — dieses Werkzeug ist schon bezahlt.
4. **Die Erzählung existiert.** Das "Pairs well with"-Netz in den READMEs ist
   bereits das, was eine Distro ausmacht: ein Satz Plugins, die voneinander
   wissen. Ein `my.nvim` müsste das nicht erfinden, nur verpacken.
5. **Vier Distro-Domänen sind bereits besser gelöst als bei NvChad**
   (Spec-Steuerung, LSP, Picker-Abstraktion, Doku/Health).

## 5.3 Gegenargumente, ehrlich

1. **31 Plugins sind keine Distro.** Eine Distro ist *eine meinungsstarke
   Integration*. Die Integration liegt hier in 45.854 LOC Config
   (`lua/config/**`, `wkdnvchad/**`, `autocmds/**`, `bindings/**`). NvChad zu
   entfernen, ohne zu entscheiden, was davon Plugin-Code wird, verschiebt die
   Kopplung nur.
2. **Die Wartungsfläche wächst.** Heute sind 17.400 LOC das Problem anderer
   Leute. Danach sind sie deins — in Domänen (Highlight-Gruppen,
   Statusline-Redraws, Tabline-Reihenfolge), die notorisch fummelig sind und
   bei Neovim-Releases als Erstes brechen.
3. **Second-System-Risiko bei base46.** Ein gelöstes Problem mit echtem
   Cache-Nutzen neu zu bauen ist der klassische Fehler. Deshalb steht D5 als
   einziger Punkt auf "nicht bauen".
4. **`wkdnvchad/` ist heute Sackgassen-Code.** 4.460 LOC, die weder NvChad noch
   Plugin sind, an einer Fremd-API hängen und deren beste Varianten
   (`lspbased`, `custom`) nicht einmal aktiv sind. Das ist kein Argument gegen
   den Umbau — es ist das stärkste Argument *dafür*, aber es heißt auch: dieser
   Code ist heute kein Guthaben, sondern eine Schuld.
5. **Der Nutzen ist überwiegend Kontrolle, nicht Funktion.** Nach Stufe 3 kann
   Neovim hier nichts, was es heute nicht kann. Wer das als Ziel nicht
   akzeptiert, sollte bei Stufe 1 aufhören — dort ist der Nutzen konkret
   (Übersicht, ein Spec pro Plugin, kein unsichtbares Bündel).

---

# Teil 6 — Gesamtbild und Empfehlung

| Domäne | Stufe | Aufwand | Nutzen |
|---|---|---|---|
| D2 · `nvconfig`-Shim | — | XS | hoch |
| D11 · Hot-Reload nach `lib.nvim.dev` | — | XS | mittel |
| D12 · Icons | — | XS | niedrig |
| D6 · Terminal | 1 (snacks) | XS | mittel |
| D9 · Colorify | 1 (fremd) | XS | niedrig |
| D8 · Minty | 0 (streichen) | XS | niedrig |
| D1 · Plugin-Bundle | — | S | hoch |
| D10 · LSP-Beiwerk → `lsp.nvim` | — | S je Teil | mittel |
| D6 · Terminal | 2 (eigen) | S | mittel |
| D7 · Menü → `ui.kit.menu` | — | S–M | mittel |
| D4 · Tabline | 1 (fremd) | S | mittel |
| D9 · Colorify | 2 (eigen) | S–M | niedrig |
| D3 · Statusline | 2 (eigen) | M | mittel |
| D4 · Tabline | 2 (eigen) | M | mittel |
| D5 · Theme-Engine | 2 (eigen) | L | niedrig |

**Empfehlung:**

- **Jetzt**: D2 + D1. Zusammen S–M, Nutzen hoch. Danach ist `NvChad/NvChad`
  raus und alles Weitere einzeln entscheidbar.
- **Als Nächstes**: die XS-Reihe (D11, D12, D6/1, D8) und D10. Das entkernt
  `ui` so weit, dass nur Statusline und Tabline übrig bleiben.
- **Dann**: D7 — weil es zwei Repos auf einmal erledigt (menu + volt) und weil
  `ui.kit.menu` fertig ist und heute ungenutzt herumliegt.
- **Das eigentliche Projekt**: `ui.nvim` mit D3 + D4. Ein bis zwei Sessions,
  wenn die 12 vorhandenen Statusline-Module übernommen werden.
- **Nicht bauen**: D5 Stufe 2.
- **Kein lualine-Zwischenschritt** (Begründung in D3). Bei der Tabline ist ein
  Zwischenschritt vertretbar, weil `vim.t.bufs` so oder so ersetzt werden muss.

Wenn nur **ein** Nachmittag zur Verfügung steht: D2 + D1. Das ist der Schritt,
der aus "NvChad-Config" eine "Config, die base46 und ui benutzt" macht — und
das ist der Unterschied, der zählt.

---

# Teil 7 — Offene Entscheidungen (braucht dich)

- [ ] **Endzustand festlegen**: Stufe 1 (Kontrolle, kein Neubau), Stufe 3
      (eigene UI-Schale) oder Stufe 4 (alles eigen)? Alles danach hängt daran,
      und Stufe 1 ist ein vollwertiger Endzustand.
- [ ] **Namen**: `ui.nvim` / `options.nvim` / `my.nvim` — oder `nvim.nvim` wie
      im Ausgangskonzept? Namensraum-Kollisionen und Lesbarkeit von
      `require(...)` siehe Teil 4.
- [ ] **`wkdnvchad/` → Repo**: die 4.460 LOC als `ui.nvim` herauslösen, oder
      erst den Rahmen bauen und dann portieren? (Empfehlung: Rahmen zuerst,
      sonst zieht man die NvChad-API mit ins neue Repo.)
- [ ] **Statusline-Variante**: derzeit steht `wkdnvchad/config/init.lua:21` auf
      `"normal"`. Bevor der Rahmen gebaut wird, sollte klar sein, welche der
      sechs Varianten das Ziel ist — sonst wird ein Renderer für Module gebaut,
      die du gar nicht sehen willst.
- [ ] **Dashboard ja/nein** (D13): heute bewusst keins. Falls doch, ist die
      Kombination aus vier eigenen Plugins ein Alleinstellungsmerkmal.
- [ ] **base46 endgültig als Fremdplugin akzeptieren?** Dieses Dokument
      empfiehlt es. Wenn du das anders siehst, ändert sich Teil 3 ab Stufe 3
      grundlegend.

---
