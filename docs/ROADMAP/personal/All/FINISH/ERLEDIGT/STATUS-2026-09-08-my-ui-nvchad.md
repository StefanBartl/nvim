# Status-Report: `my.nvim.md`, `NEW_PLUGIN.md`, `nvim.nvim.md` — 2026-09-08

Ausgangslage: drei IDEAS-Dokumente zum Themenkomplex "NvChad ablösen /
`wkdoptions`+`wkdnvchad` auslagern". Dieser Report hält fest, was davon
tatsächlich im Code umgesetzt ist (gegen den Live-Stand von `nvim/` und
`$REPOS_DIR` geprüft, nicht nur gegen die Doku-Behauptungen), und was offen
bleibt. Die drei Quelldateien werden danach nach
`docs/ROADMAP/personal/All/FINISH/ERLEDIGT` verschoben.

---

## Umgesetzt

### 1. `options.nvim` → `my.nvim` (privates Repo) — fertig
`lua/wkdoptions/**` und `lua/options.lua` existieren im Config-Baum nicht
mehr (verifiziert: beide Pfade sind weg). Der Code liegt jetzt in
`E:/repos/my.nvim` (eigenständiges Repo mit `lua/my/`, `doc/`, `docs/`,
`TESTS/`) und ist über `lua/plugins/personal/init.lua` sowie `init.lua`
eingebunden. Die Umbenennung von `options.nvim`/`config.nvim` (Arbeitstitel
in `nvim.nvim.md`/`NEW_PLUGIN.md`) auf `my.nvim` ist vollzogen; die
Startup-Phasen `options` + `wkdoptions` sind laut `NEW_PLUGIN.md`-Kopfnotiz
zu einer Phase `my` zusammengelegt.

Laufende Doku/Protokoll für dieses Plugin lebt bereits woanders:
`$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/my.nvim/`.

### 2. Drei Detailfragen aus `NEW_PLUGIN.md` beantwortet
Laut der Kopfnotiz in `NEW_PLUGIN.md`, durch die Umsetzung geklärt:
- **README-Drift bei lib.nvim-Pfaden** war reiner Doku-Drift — der Code
  benutzte bereits die aktuellen `lib.lua.*`/`lib.nvim.*`-Pfade, nur die
  READMEs nannten alte Kurznamen.
- **Command-Präfixe**: auf ein Compound-Kommando `:My` vereinheitlicht
  (elf Kommandos, drei Präfixe → eines).
- **`nvchad.*`-Referenzen**: gemessen nur zwei Symbole
  (`nvchad.stl.utils`, `nvconfig`), nicht sieben wie ursprünglich vermutet
  — die Abkopplungsaufgabe für das UI-Plugin ist kleiner als angenommen.

### 3. `no_name_guard` nach `filetree.nvim` portiert
Der Guard existiert jetzt als eigenes Feature
(`E:/repos/filetree.nvim/lua/filetree/features/nav/no_name_guard/`,
verifiziert), inklusive `is_stray_no_name()`/`find_named_buffer()` in
`util/buffer.lua`, verdrahtet in Registry/Defaults/Types/Autocmd-Katalog.
Bleibt aber **inaktiv in der Live-Config**, bis die in `NVIM_CFG_CLEANUP`
offene "Liste 1" (neo-tree → filetree.nvim) tatsächlich vollzogen ist — der
Host fährt `lua/config/neotree/` noch direkt.

### 4. Rechtsklick-Menü im Dateibaum
`filetree.nvim` hat sein eigenes `context_menu`-Feature (2026-08-01), das
den neo-tree-Zweig aus `config/menu/mappings.lua` ersetzt hat. Das war
schon vor diesem Report als erledigt in `nvim.nvim.md` vermerkt und ist die
alleinige Lösung für den Tree-Bereich.

---

## Nicht umgesetzt / offen

### 1. `ui.nvim` (vormals `nvchad-ui.nvim`) — nicht gebaut
`lua/wkdnvchad/**` und `lua/chadrc.lua` existieren im Host **unverändert**
(verifiziert). NvChad ist weiterhin eine harte Abhängigkeit:
`init.lua:67` (`"NvChad/NvChad"`) und `init.lua:87`
(`{ import = "nvchad.plugins" }`) sind unangetastet. Das ist der komplette
Umfang von `my.nvim.md` (Teil 1–7, Domänen D1–D13) plus den `nvchad-ui.nvim`-
Teil von `NEW_PLUGIN.md` — nichts davon ist begonnen.

Konkret weiterhin offen, sortiert nach `my.nvim.md`s eigener
Ausbaustufen-Reihenfolge:
- **Stufe 1** (D1 Plugin-Bundle selbst deklarieren, D2 `nvconfig`-Shim,
  D11 Hot-Reload, D12 Icons, `nvim-tree` fällt weg) — nicht begonnen.
  `nvzone/menu`, `nvzone/volt`, `nvzone/minty` sind weiterhin über
  `lua/plugins/nvchad.lua` gespeckt (verifiziert).
- **Stufe 2** (D6 Terminal, D10 LSP-Beiwerk → `lsp.nvim`, D9 Colorify,
  D8 Minty) — nicht begonnen. **D7 Menü → `ui.kit.menu` ist erledigt**
  (2026-09-08, s. u.).
- **Stufe 3** (`ui.nvim`: D3 Statusline, D4 Tabline aus den 4.460 LOC
  `wkdnvchad/`-Statusline-Modulen) — nicht begonnen; das ist das
  eigentliche "Projekt" laut Empfehlung in `my.nvim.md` Teil 6.
- **Stufe 4** (eigene Theme-Engine) — bewusst nicht empfohlen, bleibt aus.

### 2. Allgemeines (Nicht-Tree) Rechtsklick-Menü — **erledigt 2026-09-08**
`lua/config/menu/**` lebt weiterhin in der persönlichen Config (kein eigenes
Plugin — das hing an der offenen „Kommt das UI-Plugin?"-Frage und hängt
weiter daran), **rendert aber nicht mehr über `nvzone/menu`**: die Öffnung
läuft durch `lib.nvim.contextmenu.open` mit `renderer = "kit"`, gezeichnet
von `lib.nvim.ui.kit.menu`. Headless gegen die echte Config verifiziert —
volles Menü bei `package.loaded["menu"] == nil`.

`nvzone/menu` ist nur noch installiert, weil `volt`/`minty` daran hängen;
`lua/plugins/nvchad.lua` ist auf eine Spec ohne `config`-Hook geschrumpft,
das Menü-Setup sitzt in einer eigenen `UIReady`-Phase in `init.lua`.

`nvzone/menu` ist seit `nvim@3de0ee968` auch **deinstalliert** — die
Annahme, `volt`/`minty` hingen daran, war falsch: NvChad deklariert alle
drei, und nichts im Plugin-Baum ruft noch `require("menu")`.

Die Optik ist seit `lib.nvim@66a0f00` an nvzone/menu angeglichen: Pad-Spalte
an jeder Kante, eingerückte Trenner, versteckter Cursor, Einfachklick wählt,
Klick daneben schließt. Zwei Punkte der Analyse waren keine Lücken — die
Auswahl-Zeile war nie zu kurz, und die „unsichtbaren Icons" waren schlicht
nie gesetzt.

Handovers (Details, Funde, offene Punkte) liegen in WKDBooks unter
`wkdbook-myplugins/lib.nvim/handovers/ERLEDIGT/` —
`menu-kit-renderer.md` (Renderer-Swap) und `menu-visual-polish.md` (Optik).
Commits `lib.nvim@8023d5b`/`3fe3d00`/`66a0f00`,
`nvim@49c270930`/`3de0ee968`.

### 3. `neotest`-Config nicht extrahiert
`lua/config/neotest/**` lebt weiterhin im Host (verifiziert). In
`nvim.nvim.md` als eigenständiges/`dap.nvim`-Sibling-Kandidat vorgeschlagen,
kein Repo dafür angelegt.

### 4. Offene Grundsatzfragen (aus `my.nvim.md` Teil 7 und `NEW_PLUGIN.md` §8)
- ~~**Endzustand**~~ — **faktisch beantwortet.** Stufe 1 (nur Kontrolle) vs.
  Stufe 3 (eigene UI-Schale) vs. Stufe 4 — nie formal entschieden, aber durch
  die tatsächliche Arbeit beantwortet: `ui.nvim` baut durchgehend Stufe 3
  (eigene Statusline/Tabline/Theme-Schale, nicht nur Kontrollfunktionen).
- **Namen**: `ui.nvim` scheint laut `NEW_PLUGIN.md`-Kopfnotiz bereits
  gesetzt (öffentlich, ersetzt den Arbeitstitel `nvchad-ui.nvim`); `my.nvim`
  ist real. Innerhalb `NEW_PLUGIN.md` selbst sind die Commands nachträglich
  auf `:Options` bzw. `:UI` vereinheitlicht worden (Inline-Antwort im
  Dokument) — das war zum Zeitpunkt des Ur-Textes noch offen.
  „lib.nvim als **harte** Abhängigkeit" für das künftige `ui.nvim`/`options`-
  Umfeld ist ebenfalls bereits als Antwort im Dokument vermerkt (Inline-
  Antwort zu §8, README-Drift-Punkt).
- ~~**`wkdnvchad/` → Repo**~~ — **faktisch beantwortet.** Rahmen zuerst, wie
  empfohlen: der Umzug am 2026-09-08 war ein reiner Prefix-Rename, danach
  schrittweise umgebaut (Schritte 3-6, alle in `ui.nvim`s ROADMAP/README
  protokolliert).
- ~~**Statusline-Variante**~~ — **teilweise überholt, teilweise offen.** Die
  Varianten-Frage selbst ist entschieden: von sechs auf vier generische
  Presets konsolidiert (`default`/`minimal`/`lsp`/`blocks`, 2026-09-12) plus
  ein Registry-Mechanismus, über den ein Host eine eigene, plugin-spezifische
  Variante unter eigenem Namen registrieren kann (`:UI variant`). Welches
  Preset **für den Host** (diese Config) das Ziel ist, sobald Schritt 7
  kommt, ist weiterhin offen — reine Geschmacksfrage, siehe
  `ui.nvim/docs/configuration.md`.
- **Dashboard ja/nein**: weiterhin bewusst keins.
- ~~**base46 als Fremdplugin akzeptieren**~~ — **veraltet, anders entschieden
  (2026-09-12).** `my.nvim.md` empfahl es ausdrücklich (D5, Stufe 0); Schritt
  6 der `ui.nvim`-Entkopplung hat sich fürs Gegenteil entschieden: base46
  ist komplett raus, `ui.theme.palette` leitet Akzentfarben stattdessen aus
  den Highlight-Gruppen des aktiven Colorschemes ab. Details in
  `ui.nvim`s README (Schritt-6-Eintrag) und
  `wkdbook-myplugins/ui.nvim/handovers/`.

### 5. `nvim.nvim.md`s Autocmd→Plugin-Mapping
Rein analytisch, keine offenen Handlungspunkte außer den zwei notierten
Duplizierungsfunden (Kitty-Padding doppelt in `general`+`terminals`,
`last_loc` doppelt in `general`+`text`) — beide noch nicht bereinigt,
unabhängig von der Plugin-Frage.

---

## Kurzfassung für die Wiederaufnahme

**Überholt (2026-09-12) — tatsächlich lief es anders.** Die hier empfohlene
Reihenfolge (D2 `nvconfig`-Shim + D1 Plugin-Bundle) wurde nicht der
Einstieg. Stattdessen lief `ui.nvim`s eigene Roadmap durch: Schritte 3-5
(NvChad-Symbole ersetzen, eigener Render-Entrypoint, `nvchad.tabufline`
ersetzen, alle 2026-09-08), Schritt 6 (base46 → `ui.theme.palette`,
2026-09-12), plus am selben Tag ein Bug-Sweep, die
Statusline-Preset-Konsolidierung (sechs → vier generische Presets) und die
Winbar-Entscheidung (`ui.nvim` besitzt den `vim.wo.winbar`-Write, `my.nvim`
steuert bei — dasselbe Muster wie bei `vim.diagnostic.config`). `ui.nvim`
braucht inzwischen weder NvChad noch base46 für Statusline, Tabline oder
Theme. Einziges verbliebenes großes Stück: **Schritt 7, Host-Wiring** —
`NvChad/NvChad` ist in dieser Config weiterhin eine harte Abhängigkeit,
`lua/wkdnvchad/**`/`lua/chadrc.lua` unangetastet.

Aktueller, vollständiger Stand: `ui.nvim`s eigenes README + ROADMAP
(`wkdbook-myplugins/ui.nvim/`), `my.nvim`s HANDOVER + ROADMAP
(`wkdbook-myplugins/my.nvim/`) — nicht mehr dieses Dokument oder
`my.nvim.md`.

---

**Diese Datei wird hiermit nach `FINISH/ERLEDIGT` verschoben**, wie in der
Kopfzeile angekündigt. Was von hier aus noch offen bleibt, unabhängig von
der `ui.nvim`/`my.nvim`-Frage:

- Schritt 7 (Host-Wiring: `chadrc.lua` ersetzen, `NvChad/NvChad` als
  Hard-Dependency entfernen) — bewusst noch nicht angefasst.
- `neotest`-Config nicht extrahiert (Abschnitt "Nicht umgesetzt" Punkt 3).
- Zwei Duplizierungsfunde (Kitty-Padding, `last_loc`) — Abschnitt 5.
