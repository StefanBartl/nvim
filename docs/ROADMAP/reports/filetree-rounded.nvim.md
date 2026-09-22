# filetree.nvim — "rounded" Skin-Konzept (ui.nvim-Design)

**Stand:** 2026-09-22, Konzeptphase — Design-Artifact steht (siehe unten), noch **nichts** im Code.
**Auslöser:** Symlink-Marker-Feature (`link_marker`) gebaut, danach die Frage: kann filetree.nvims
Visuals designtechnisch näher an das bringen, was `ui.nvim` in Tabzeile/Statusline schon zeigt?

## Table of content

  - [Kontext](#kontext)
  - [Recherche-Grundlage: was ui.nvim tatsächlich tut](#recherche-grundlage-was-uinvim-tatschlich-tut)
  - [Das Konzept](#das-konzept)
    - [1. Baum-Zeilen-Marker als Chips](#1-baum-zeilen-marker-als-chips)
    - [2. Breadcrumbs: neues Element, nicht nur Restyling](#2-breadcrumbs-neues-element-nicht-nur-restyling)
    - [3. Palette: nichts neu erfinden](#3-palette-nichts-neu-erfinden)
  - [Machbarkeit](#machbarkeit)
  - [Vorgeschlagene Config-Oberfläche](#vorgeschlagene-config-oberflche)
  - [Betroffene Module](#betroffene-module)
  - [Offene Entscheidungen](#offene-entscheidungen)
  - [Artifact (visuelle Referenz)](#artifact-visuelle-referenz)
  - [Aufgabe für eine Umsetzungs-Session](#aufgabe-fr-eine-umsetzungs-session)

---

## Kontext

filetree.nvim ist Adapter-agnostisch — es rendert den Baum selbst nicht, sondern deckt neo-tree/nvim-tree/
netrw/oil.nvim/mini.files ab und deckoriert nur, was es selbst kontrolliert: fünf zeilenbasierte
Extmark-Marker (`git_status`, `size_info`, `link_marker`, `lsp_diagnostics`, copy_move-Clipboard,
siehe `docs/FEATURES/BACKENDS.md#line-resolved-decorations`) und die Breadcrumb-Leiste (Winbar/Float/
Statusline, vollständig filetree-eigener Text, kein Adapter im Weg).

ui.nvim (`E:/repos/ui.nvim`, editierbares Sibling-Repo desselben Users) implementiert in Tabzeile und
Statusline ein durchgängiges, "rundes" Design mit Farben/Icons/Pfeilen. Frage war: lässt sich dieselbe
Sprache sinnvoll auf filetree.nvims eigene Dekorationen übertragen — als optionaler Skin, weich abhängig
von ui.nvim, wie schon heute bei nvim-web-devicons üblich?

---

## Recherche-Grundlage: was ui.nvim tatsächlich tut

Nicht geraten, sondern im Code nachgesehen:

- **`lua/ui/theme/palette.lua`** — `M.accent(key)` liest die Akzentfarbe für einen semantischen Key
  (`project`/`nearest`/`lock`/`manual`/`tree_leads`, dieselben wie `cwd_mode`s Root-Policy-Modi) live aus
  `vim.api.nvim_get_hl()` der `Diagnostic*`-Gruppen des aktiven Colorschemes — **nicht** aus festen
  Hex-Werten. Ein Fallback-Hex pro Key greift nur, falls das Colorscheme die Anker-Gruppe nicht definiert:

|     Key      |     Anker (in Reihenfolge)     | Fallback-Hex |
|--------------|--------------------------------|--------------|
|  `project`   | `DiagnosticHint` → `Function`  |  `#9d7cd8`   |
|  `nearest`   |   `DiagnosticInfo` → `Type`    |  `#e06c9f`   |
|    `lock`    | `DiagnosticError` → `ErrorMsg` |  `#e06c75`   |
|   `manual`   |           `Comment`            |  `#a0a8b7`   |
| `tree_leads` |   `DiagnosticOk` → `String`    |  `#7fd88f`   |

  Dasselbe Muster (`MODE_ANCHORS`/`MODE_FALLBACK_HEX`) existiert für die Statusline-Modus-Chips
  (Normal/Insert/Visual/…). `M.contrast_fg(bg_hex)` wählt schwarz/weiß nach Luminanz, damit Text auf
  jedem Akzent lesbar bleibt.

- **`lua/ui/tabline/styles.lua`** — Chip-Rand-Dekoration als Registry (`rounded`/`square`/`divider`,
  erweiterbar über `M.register(name, fn)`). `rounded` (Default) setzt Nerdfont-Powerline-Kappen
  (`LEFT_CAP`/`RIGHT_CAP`, U+E0B6/U+E0B4) an jede innere Chip-Grenze; das erste Chip bleibt links eckig
  (sitzt direkt an der Leiste), das letzte nur eckig, wenn der sichtbare Lauf wirklich flush ist.

- **`lua/ui/statusline/utils/primitives.lua`** — vier benannte Trenner-Sets: `default`/`round`
  (dieselben Kappen wie oben), `block` (`█`/`█`), `arrow` (U+E0B2/E0B0, klassische Powerline-Pfeile).

- **`lua/ui/statusline/themes/default.lua`** — Modus-Chip als Muster: farbiger Hintergrund + Icon/Label,
  ein Trenner-Glyph blendet in den nächsten Hintergrund über (bewusst nur *ein* Trenner, nicht zwei —
  ein dokumentierter Bugfix im selben Modul).

**Kurzfassung des Designsystems:** farbige Pill-Chips mit optionalen Powerline-Kappen, Farbe live aus dem
Colorscheme abgeleitet (nie hart verdrahtet), Icon+Label pro Segment, austauschbare Trenner-Stile als
Registry.

---

## Das Konzept

### 1. Baum-Zeilen-Marker als Chips

Alle fünf zeilenbasierten Marker sind bereits eigene `virt_text`-Extmarks (siehe
`docs/FEATURES/BACKENDS.md#line-resolved-decorations`) — reine Stylingfrage, keine neue Dateninfrastruktur
nötig. Aktuell: einzelne farbige Zeichen (`●`, `+`, `-`, `⇢`, `⇢!`, …). Vorschlag: dieselben Zeichen/Labels
in eine abgerundete Chip-Fläche setzen (CSS-Pill im Mockup als Stand-in für Nerdfont-Kappen — siehe
"Machbarkeit" unten zum Font-Problem), Farbe weiterhin über bestehende `Diagnostic*`-Highlight-Links,
optional zusätzlich über `ui.theme.palette.accent()`, falls installiert.

`link_marker` (gerade gebaut, sitzt jetzt inline vor dem Node-Icon statt am Zeilenende) wäre der naheliegende
erste Kandidat, weil er am kleinsten/neuesten ist.

---

### 2. Breadcrumbs: neues Element, nicht nur Restyling

Die Breadcrumb-Leiste (`lua/filetree/features/ui/breadcrumbs/`) ist vollständig filetree-eigener Text
(Winbar/Float/Statusline-Modus, `docs/FEATURES/UI.md#breadcrumbs`) — volle Kontrolle, kein Adapter-Rendering
im Weg. Idee, die über reines Restyling hinausgeht: die Akzentfarbe der Breadcrumb-Chips zeigt live, welche
**`cwd_mode`-Root-Policy** gerade aktiv ist (`project`/`nearest`/`lock`/`manual`/`tree_leads` — exakt dieselben
fünf Keys wie `ui.theme.palette.accent()`, siehe Tabelle oben). Das ist heute nirgends sichtbar; man müsste
`:Filetree cwd status` explizit aufrufen. Als Farbsignal in der ohnehin sichtbaren Breadcrumb-Leiste wäre es
beiläufig immer da.

---

### 3. Palette: nichts neu erfinden

Kein neues Farbschema entwerfen — `ui.theme.palette.accent(key)` direkt lesen (soft-required, Fallback auf
die bestehenden `Diagnostic*`-Links, falls ui.nvim fehlt). Deckt sich mit den fünf Fallback-Hex-Werten oben.

---

## Machbarkeit

**Geht:**
- Breadcrumbs — volle Kontrolle, kein Adapter im Weg.
- Alle fünf zeilenbasierten Marker — eigene Extmarks, Styling ist Featureinterne Sache.
- Farb-Ableitung über `ui.theme.palette` (soft dependency, exakt das Muster, das `nvim-web-devicons` in
  mehreren Adaptern schon hat: `pcall(require, ...)`, bei Fehlschlag alter Pfad).

**Geht nicht / Grenzen:**
- Name, Einrückung, Datei-Icon selbst zeichnet neo-tree/nvim-tree — filetree deckoriert daneben, ersetzt
  nichts. Ein Skin kann nicht das Grund-Rendering des Adapters ändern.
- Nerdfont-Powerline-Kappen (`` / ``, U+E0B6/E0B4) sind terminalseitig nicht garantiert vorhanden. `ui.nvim`
  selbst setzt sie fest voraus (Tabline/Statusline sind ohnehin Powerline-Font-Territorium); ein Baum-Skin,
  der auch ohne Nerdfont sauber aussehen soll, bräuchte einen Zeichensatz-Fallback — dieselbe bewusste
  Entscheidung, die `link_marker` schon getroffen hat (reines Unicode statt Nerdfont-Icon, siehe
  `lua/filetree/features/ui/link_marker/init.lua` Modul-Kommentar). Im Browser-Mockup sind die "Kappen"
  deshalb CSS-`border-radius`-Pills, nicht echte Powerline-Glyphen — als Terminal-Skin müsste das nochmal
  neu gedacht werden (evtl. selbst auch auf Pill-artige Klammerung ohne Nerdfont-Zeichen ausweichen, z. B.
  `( )`/`[ ]` als Kappen-Ersatz, oder Nerdfont als Opt-in mit Zeichensatz-Check).
    -> Frage: Wäöre ein experimenteller dritter skin dnekbar, der mir nerdfonts arbeitet?
- `nvim_buf_set_extmark`-Highlight-Gruppen sind Text-Farbe (`fg`) und optional `bg` — ein "Chip" braucht
  einen eigenen `bg`, was pro Skin-Highlight-Gruppe angelegt werden müsste (nicht einfach eine bestehende
  `Diagnostic*`-Gruppe wiederverwenden, die typischerweise keinen `bg` setzt).

---

## Vorgeschlagene Config-Oberfläche

Analog zu `progress_style` (existierende Top-Level-Option, von `filetree.util.progress` zentral gelesen,
kein Pro-Feature-Duplikat):

```lua
require("filetree").setup({
  -- "plain" (Default, heutiges Verhalten) | "rounded" (Chip-Optik, soft-dependent auf ui.nvim)
  decoration_style = "plain",
})
```

Ein neues `filetree.util.decoration_style`-Modul kapselt die Logik ("bin ich rounded? gib mir bg/fg/caps für
key X"), von `git_status`/`size_info`/`link_marker`/`lsp_diagnostics`/copy_move/`breadcrumbs` gemeinsam
gelesen — analog zu `filetree.util.progress`s Rolle für `progress_style`.

---

## Betroffene Module

- `lua/filetree/util/decoration_style/` — **neu**, zentrale Skin-Logik.
- `lua/filetree/features/ui/breadcrumbs/init.lua` — cwd_mode-Farbe, Chip-Rendering.
- `lua/filetree/features/git/git_status/init.lua`
- `lua/filetree/features/ui/size_info/init.lua`
- `lua/filetree/features/ui/link_marker/init.lua`
- `lua/filetree/features/lsp/lsp_diagnostics/init.lua`
- `lua/filetree/features/fileops/copy_move/init.lua` (Clipboard-Marker)
- `lua/filetree/config/schema.lua` / `@types/config.lua` — neue Top-Level-Option `decoration_style`.
- `docs/FEATURES/UI.md`, `docs/configuration.md`, `doc/filetree.txt` (Regenerierung via
  `scripts/gen_vimdoc_reference.lua`).

---

## Offene Entscheidungen

1. **Ganz oder in Schritten?** Die cwd_mode-Breadcrumb-Färbung ist klein und eigenständig sinnvoll — könnte
   vor dem vollen Chip-Skin für alle fünf Marker separat kommen.
     -> das müsste ich mir anschauen. gut wöre wirder konfigurierbarkeit bei dem use, also ganze skins möglich aber man anna uch teile eines sikins konfigurieren, andere skins für teile sanwednen us.. wenn der usrer das möchtre. das wäre auch deshalb wichtig, wenn der user selbst einen skin erzeugen will, dass das möglichst einfach und modular geht
2. **Nerdfont-Frage.** Echte Powerline-Kappen im Terminal vs. reiner Unicode-Fallback (Klammern, oder gar
   kein Kappen-Glyph, nur `bg`-Farbe) — beeinflusst, wie nah am ui.nvim-Original das Ergebnis wirkt.
    -> wenn möglich würde ich beides sagen, ein skin mi und eines ohne nerdfont zusätzlich z plain
3. **Default oder Opt-in?** `link_marker` selbst ist bewusst default-on (kostet nichts extra); ein
   `decoration_style = "rounded"` sollte vermutlich Opt-in bleiben (ähnlich `size_info`), weil es eine
   Geschmacksfrage ist, keine reine Verbesserung.
     -> ja genau, opt-in erstmal

---

## Artifact (visuelle Referenz)

Interaktiver Mockup (Toggle "aktuell"/"rounded" für die Baum-Zeilen, cwd_mode-Auswahl für die Breadcrumb-
Farbe, Paletten-Swatches mit Quellenangabe): <https://claude.ai/artifact/9k2P3fWdnsLd4xmvxg4ow1>
(privat, nur für den Owner-Account sichtbar).

---

## Aufgabe für eine Umsetzungs-Session

```
Aufgabe: filetree.nvim (E:/repos/filetree.nvim) — "rounded" Decoration-Style umsetzen.

Kontext/Konzept: dieser Report (C:/Users/bartl/AppData/Local/nvim/docs/ROADMAP/reports/
filetree-rounded.nvim.md), Artifact-Link darin für die visuelle Referenz.

Baue zuerst NUR Schritt 1 (kleinster eigenständiger Nutzen, siehe "Offene Entscheidungen" #1):
cwd_mode-Farbe in den Breadcrumbs (lua/filetree/features/ui/breadcrumbs/init.lua). Lies die
Akzentfarbe über ui.theme.palette.accent(key) (E:/repos/ui.nvim, soft dependency per pcall,
Fallback auf die bestehenden hl_dir/hl_file-Optionen wenn ui.nvim fehlt oder der aktuelle
cwd_mode-Key nicht auflöst). key kommt aus der aktiven cwd_mode-Policy (project/nearest/lock/
manual/tree_leads) — Modul dafür: lua/filetree/features/nav/cwd_mode/.

Erst NACH Bestätigung, dass Schritt 1 passt: das zentrale lua/filetree/util/decoration_style/-
Modul plus decoration_style-Option (Config-Schema/Types/Docs) für die fünf zeilenbasierten Marker
(git_status, size_info, link_marker, lsp_diagnostics, copy_move) bauen — siehe "Vorgeschlagene
Config-Oberfläche" und "Betroffene Module" im Report.

Kläre VORHER die Nerdfont-Frage (siehe "Offene Entscheidungen" #2) — eigene Empfehlung mit
Begründung, bevor gebaut wird.

Regeln: Antworte auf Deutsch, Code/Kommentare auf Englisch. luacheck und stylua grün (siehe
stylua.toml, .luacheckrc). Docs mitpflegen (docs/FEATURES/*.md, doc/filetree.txt via
scripts/gen_vimdoc_reference.lua neu generieren, --check muss sauber sein). Neue Features im
TESTS/-Ordner testen (Konventionen: TESTS/README.md). Kein Claude-Co-Author in Commits. Wenn
fertig: committen und direkt auf main pushen (siehe git-Historie für Commit-Message-Stil).
```

---

