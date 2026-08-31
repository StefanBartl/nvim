# Plugin-Roadmaps — Testplan für das Gebaute

Dritte Datei neben [`PLUGIN_ROADMAPS.md`](PLUGIN_ROADMAPS.md) (offene Arbeit)
und [`PLUGIN_ROADMAPS_FINISHED.md`](PLUGIN_ROADMAPS_FINISHED.md) (was gebaut
wurde und warum so). **Diese hier beantwortet die dritte Frage: wie prüfe ich
von Hand nach, dass es tut, was dort steht.**

Jeder Punkt trägt seine Roadmap-ID, damit die drei Dateien sich gegenseitig
auflösen lassen. Reihenfolge ist nach Plugin, nicht nach ID — beim Testen sitzt
man in einem Repo und nicht in einer Chronologie.

> **Nicht zu verwechseln mit
> [`docs/NOTES/PersonelPlugins/TO_CHECK_FEATURES/`](../../../NOTES/PersonelPlugins/TO_CHECK_FEATURES/).**
> Die dortigen Dateien testen ein Plugin **vollständig**, Feature für Feature.
> Diese hier testet nur, **was über diese Roadmap dazugekommen ist** — deutlich
> kürzer, und der richtige Einstieg nach einer Bauphase. Wo eine Feature-Datei
> denselben Punkt ausführlicher behandelt, steht der Verweis dabei.

**Checkbox-Konvention**: `- [ ]` offen, `- [x]` geprüft. Ein Punkt, der nicht
tut was hier steht, gehört als Befund zurück in `PLUGIN_ROADMAPS.md` — nicht
stillschweigend abgehakt.

---

## Table of content

  - [Vorbereitung](#vorbereitung)
  - [`lsp.nvim`](#lspnvim)
  - [`mdview.nvim`](#mdviewnvim)
  - [`images.nvim` (+ casedesk)](#imagesnvim--casedesk)
  - [`documentation.nvim` / `runtime-analysis.nvim`](#documentationnvim--runtime-analysisnvim)
  - [`color_my_ascii.nvim`](#color_my_asciinvim)
  - [`gopath.nvim` / `pickers.nvim` / `lib.nvim`](#gopathnvim--pickersnvim--libnvim)
  - [nvim-config](#nvim-config)
  - [Nicht von Hand prüfbar — und was stattdessen gilt](#nicht-von-hand-prfbar--und-was-stattdessen-gilt)

---

## Vorbereitung

Einmalig, bevor irgendetwas davon Sinn ergibt.

- [ ] **`:Lazy update`** für alle beteiligten Plugins. `mdview.nvim` läuft
      dabei durch seinen `build`-Hook (`npm ci && npm run build:go && npm run
      build`) — **beide** Teile zählen: das Relay hat für L4 eine Route
      dazubekommen, der Client für SEL und L4 neuen Code. Ein reines
      Client-Update lässt L4 still auf highlight.js zurückfallen.
- [ ] **`:checkhealth`** für `lsp`, `images`, `mdview`, `documentation` — die
      externen Werkzeuge unten (tesseract, ImageMagick) melden sich dort, bevor
      ein Kommando daran scheitert.
- [ ] Externe Abhängigkeiten, nur für die Punkte, die sie brauchen:
      **tesseract** (M11 OCR), **ImageMagick** (M13 scale/optimise/convert).

---

## `lsp.nvim`

Der größte Block. Ein Buffer mit laufendem Sprachserver ist die Voraussetzung
für fast alles hier — `:Lsp status` sagt, ob einer da ist.

### QW3 · Inlay-Hints-Toggle

- [ ] `:Lsp hints` schaltet Inlay-Hints im aktuellen Buffer um; `<leader>th`
      tut dasselbe, `<leader>tH` global.
- [ ] **Die eigentliche Prüfung ist die Zweistufigkeit**: mit global `enable =
      true` und `filetypes = { lua = false }` sind Hints überall **außer** in
      Lua an. Ein fehlender Filetype-Schlüssel erbt die globale Einstellung —
      „keine Meinung" und „hier ausdrücklich aus" sind verschiedene Zustände.
      Genau das kann eine Liste nicht, und deshalb ist es eine Map.

### QW7 · „installed vs. attached" im Healthcheck

- [ ] `:checkhealth lsp` zeigt vier Zahlen in einer Kette: **installed →
      configured → set up → attached**, plus welche der laufenden Clients
      *diesen* Buffer bedienen.
- [ ] Bei einem schweren Server über vielen Buffern erscheint eine Warnung.
      Zum Provozieren: viele Dateien desselben Filetyps öffnen (`:args **/*.ts`,
      `:argdo edit`).

### QW8 · Multi-Root-/Monorepo-Workspace-Switcher

- [ ] `:Lsp root [pick|show|add|remove|list]` — bare `:Lsp root` ist `show`.
      `<leader>lsp` ist `pick`, `<leader>lsw` fügt einen Workspace-Folder hinzu.
- [ ] **Im Monorepo prüfen, nicht im Einzelprojekt** — das ist der Fall, für den
      es gebaut wurde. Nach `:Lsp root pick` muss der Server die Dateien des
      neuen Teilbaums bedienen, **ohne Neustart**.
- [ ] Wenn weder `pick` noch die erkannte Wurzel passt: `:Lsp root add` legt den
      Ordner als Workspace-Folder dazu, statt die Wurzel zu verbiegen — das ist
      der Weg, den der Punkt eigentlich gebaut hat (eine vierte
      `root_scope`-Strategie hätte hier nichts getan).

### M2 · Code-Action-Indikator

- [ ] Cursor auf eine Zeile mit verfügbarer Code-Action (eine Diagnostic ist der
      einfachste Fall) → Indikator erscheint. `<leader>tl` schaltet ihn um,
      `<leader>tL` global.
- [ ] **Die Kind-Allowlist ist der Punkt, nicht ein Detail davon**: der
      Indikator darf *nicht* bei jeder beliebigen Action angehen (ungefiltert
      liefern viele Server ständig etwas). Auf einer unauffälligen Zeile ohne
      Diagnostic muss er dunkel bleiben — leuchtet er dauernd, ist die Allowlist
      umgangen und der Indikator wertlos.

### M3 · Auto-Restart mit Backoff bei Client-Crash

- [ ] Server-Prozess von außen abschießen (Task-Manager / `taskkill`) → er wird
      neu gestartet, mit wachsendem Abstand bei wiederholtem Absturz.
- [ ] **Absturz gegen Absicht**: `:Lsp restart` und `:Lsp stop` dürfen den
      Supervisor **nicht** auslösen — ein gewollter Stopp ist kein Crash.
      Das ist die schwierige Hälfte des Punktes und der wahrscheinlichste
      Regressionsort.
- [ ] `:LspDoctor startup` zeigt den Versuchszähler; `:Lsp recover` den
      manuellen Weg. Beide zählen **denselben** Zähler — zwei Stellen, die
      unabhängig zählen und sich widersprechen, war die vermiedene Falle.

### M4a + Call Hierarchy · Picker

- [ ] `:TypeDefPick` und `<leader>wos` öffnen **dieselbe** Oberfläche (vorher
      zwei verschiedene Backends).
- [ ] `lsc` zeigt, wer das Symbol unter dem Cursor aufruft; `lsC`, was es
      aufruft.

### M6 + M7 · Profile-Presets und Per-Projekt-Override

- [ ] `:Lsp status` nennt das aktive Profil **und** die Ebene, aus der jeder
      Wert kommt.
- [ ] Per-Projekt-Override: einen Server in *einem* Projekt abschalten, ohne die
      globale Config anzufassen → in einem anderen Projekt läuft er weiter.
- [ ] **Die Ebenen sind der Test**: eine Warnung über einen schlechten Wert muss
      sagen, aus welcher Ebene er stammt. Ohne diese Beschriftung ist eine
      vierstufige Merge-Kette nicht debuggbar.

### M1 · `:LspDoctor probe`

- [ ] `:LspDoctor probe` gibt den angehängten Clients einen Buffer, den sie
      nicht parsen können, und meldet, ob Diagnostics zurückkommen.
- [ ] **Wozu es da ist**: eine saubere Datei und eine tote Pipeline sehen beide
      wie eine leere Gutter aus. `probe` unterscheidet sie — als einziger der
      sechs Reports, und deshalb ist er nicht Teil von `:LspDoctor all`.

---

## `mdview.nvim`

Ausführlicher (inklusive der älteren Features) in
[`TO_CHECK_FEATURES/mdview.md`](../../../NOTES/PersonelPlugins/TO_CHECK_FEATURES/mdview.md),
Abschnitte 3b und 3c.

### SEL · Visuelle Auswahl im Browser spiegeln

- [ ] `:MDView` auf einer Markdown-Datei, dann `:MDView selection` (Default ist
      **aus**).
- [ ] `v` + Bewegung → die Hervorhebung folgt der wachsenden Auswahl, über
      Zeilenenden hinweg. `V` → ein Balken pro Zeile, jeder auf Textbreite.
      `CTRL-V` → ein Spaltenband. `<Esc>` → weg.
- [ ] **Innerhalb eines Codeblocks markieren** — der Weg dorthin ist ein anderer
      (Codeblöcke tragen keine Inline-Quellpositionen, die Zeilenstruktur des
      Blocks wird benutzt) und genau der Fall, den eine README-Führung trifft.
- [ ] `:MDView selection` erneut → die gezeichnete Hervorhebung verschwindet,
      statt im Tab hängen zu bleiben.
- [ ] *Bekannte Grenze, kein Fehler*: an Markup-Rändern kann die Hervorhebung
      ein, zwei Zeichen abweichen — `**fett**` ist in der Quelle vier Zeichen
      breiter als im Browser. In Codeblöcken und Fließtext ist sie exakt.

### L4 · `highlighter = "nvim"`

- [ ] `highlighter = "nvim"` in der mdview-Spec, Neustart. Ein Dokument mit
      einem ```lua- **und** einem ```yaml-Block öffnen.
- [ ] Der lua-Block ist **wie der Puffer daneben** gefärbt; der yaml-Block
      anders — der geht an highlight.js, weil color_my_ascii's Fence-Map yaml
      nicht kennt. **Diese Mischung auf einer Seite ist das erwartete Ergebnis**,
      nicht ein Fehler: 31 Fence-Tags gegen ~190 Sprachen.
- [ ] `:colorscheme` in nvim wechseln, ein Zeichen ändern (damit ein Push
      passiert) → der Browser zieht nach.
- [ ] **Browser-Tab neu laden** → die Blöcke kommen **sofort** gefärbt zurück,
      nicht erst nach der nächsten Bearbeitung. (Dafür speichert das Relay die
      letzten Spans pro Raum; ephemer wäre hier falsch gewesen.)
- [ ] Ohne `color_my_ascii.nvim`: alles fällt auf highlight.js zurück, nichts
      bricht.

### QW1 · `any_file`

- [ ] `experimental.any_file = true`, eine **Nicht**-Markdown-Datei öffnen,
      `:MDView start` → sie erscheint als ein einzelner, nach Dateiendung
      gefärbter Codeblock statt durch den Markdown-Renderer.
- [ ] Die Torwächter greifen weiter: ein Terminal-, Hilfe- oder Quickfix-Buffer,
      eine Binärdatei und mdviews eigener Log-Buffer werden **nicht** gepusht.

### QW10 · Lokal gebautes Relay unter Windows

- [ ] `npm run build:go`, dann `:MDView start` → das Relay startet aus dem
      Checkout. Der Fehler damals war die fehlende `.exe`-Endung; wenn `:MDView
      diagnose` den Pfad des gespawnten Binaries zeigt, ist er geprüft.

---

## `images.nvim` (+ casedesk)

### M11 · OCR

- [ ] `:Image ocr` auf einem Bild mit Text → der Text landet in einem
      Markdown-Scratch-Split. Braucht `tesseract`; `--lang=deu` überschreibt die
      konfigurierte Sprache.
- [ ] **Die größere Hälfte ist casedesk, nicht Übersetzung**: `:Case ocr` legt
      den erkannten Text so ab, dass ihn `:Cases grep` findet und der
      `:Case ki`-Prompt ihn sieht. Vorher war ein Screenshot für **jedes**
      textbasierte casedesk-Feature unsichtbar. Test: einen Screenshot an einen
      Case hängen, `:Case ocr`, dann nach einem Wort aus dem Bild greppen.

### M13 · Bildoperationen als Dateioperationen

Alle drei brauchen ImageMagick und schreiben **neben** die Quelle, nie darüber.

- [ ] `:Image scale 50%` → `photo.png` wird zu `photo.scaled.png`. Auch
      `800x600`, `800x`, `x600`, `800x600!` prüfen.
- [ ] `:Image optimise` → `photo.optimised.png`, kleiner. **Ein Ergebnis, das
      nicht kleiner ist, wird gelöscht und gemeldet** — das ist die
      interessante Zeile, nicht der Erfolgsfall.
- [ ] `:Image convert png` → gleicher Stamm, anderes Format. `convert pdf` nimmt
      denselben Weg wie `:Image export`.
- [ ] Ohne Argument arbeiten alle auf dem Bild **unter dem Cursor** — das ist
      der Grund, warum sie unter `:Image` liegen und nicht unter `:File`.

### M12 · Flamegraph als Bild

- [ ] `:RATelemetry flamegraph` → der Startup-Require-Baum als SVG. Breite ist
      Gesamtzeit, Tiefe ist Require-Verschachtelung, eine Farbe pro Modulwurzel.
- [ ] Mit installiertem `images.nvim` wird sie **im Terminal** gezeichnet (dessen
      SVG→PNG-Pfad), sonst an den System-Opener übergeben. Beide Wege einmal
      sehen, indem man `:Image show <pfad>` von Hand aufruft.

---

## `documentation.nvim` / `runtime-analysis.nvim`

### M17/M8 · `:DocMap impact` nach Runtime-Reichweite

- [ ] Ein paar Zeilen ändern, `:DocMap impact` → die betroffenen Funktionen,
      **nach tatsächlicher Aufrufhäufigkeit sortiert** statt alphabetisch. Ohne
      Telemetriedaten bleibt es eine Liste; mit ihnen wird es eine Rangfolge.

### M17/M9 · `:DocMap why` × Call-Trees

- [ ] `:DocMap why <a> <b>` beantwortet **„was ruft was"**, nicht „was lädt was".
      Die beiden Ketten sind leicht zu verwechseln — der require-Graph ist die
      andere Frage.
- [ ] Die Call-Kanten stecken in jeder erzeugten Karte; es braucht **keine**
      Telemetrie und kein zusätzliches Plugin dafür.

### M17/M14 · `sibling-reference-missing`

- [ ] Einen Verweis der Form `<repo>/<pfad>` in eine Doku schreiben, der ins
      Leere zeigt → `:DocMap check` meldet ihn. Der Anlass waren neun tote
      `docs/ECOSYSTEM.md`-Verweise, jeder tot ab der Sekunde seines Entstehens.
- [ ] Gegenprobe: ein gültiger Geschwister-Verweis darf **nicht** gemeldet
      werden.

### M17/M7c · `file-holds-many-modules`

- [ ] `:DocMap check` gegen ein Repo mit Inline-Modulen (`docmap-desktop` ist
      der Fall, an dem es verifiziert wurde) → eine Datei mit mehreren
      Modul-Identitäten wird gemeldet, statt still für alle zu antworten.
- [ ] Auf dem eigenen Korpus muss der Check **still bleiben** — ein Check, der
      überall anschlägt, wird ignoriert.

### M17/M10 · Laufzeit-Evidenz unterdrückt `unreferenced-module`

- [ ] `:DocMap check` gegen `lib.nvim`: dessen Oberfläche läuft über eine
      Namens-zu-Modulpfad-Tabelle, es gibt dort **kein** literales `require`.
      Diese Module dürfen nicht mehr dauerhaft als verdächtig gemeldet werden,
      sofern Telemetrie belegt, dass sie geladen waren.
- [ ] Gemessen wurde: 71 Befunde vorher, 68 nachher, **0 neu erzeugt** — die
      letzte Zahl ist die wichtige.

### M17/QW6 · Fenced Blocks auf der generierten Seite

- [ ] `:DocMap serve` (oder das erzeugte Artefakt) öffnen: ein Codeblock in
      einer Feature-Beschreibung ist als solcher gerendert **und die Sprache ist
      erhalten** — vorher wurde sie ein Zeichen vor dem Gebrauch weggeworfen.
- [ ] Auch im `@description`-Rumpf eines Moduls und in `@example` prüfen; das
      waren die beiden Oberflächen, die vorher gar nicht an Fences trennten.

### M12b · Analysis → Startup

- [ ] In der generierten Seite: Reiter **Analysis → Startup**, mit dem
      Flamegraph **eingebettet** (nicht nachgeladen) — er braucht deshalb kein
      `:DocMap serve`, anders als Telemetry und Loaded.
- [ ] **Die `--check`-Ausnahme ist der heikle Teil**: ein fremdes Repo darf sich
      dadurch nicht dauerhaft als „stale" melden. Ein `:DocMap check` in einem
      Repo ohne Startup-Daten muss ruhig bleiben.

---

## `color_my_ascii.nvim`

### Öffentliche Highlight-API (aus L4)

- [ ] `:lua =vim.tbl_keys(require("color_my_ascii").highlight)` → `runs_for_block`
      und `attrs_for_group`, ohne dass `setup()` von Hand aufgerufen wurde.
- [ ] `:lua =require("color_my_ascii").highlight.attrs_for_group("Comment")` →
      Farben als `"#rrggbb"`-Strings, und ein **nicht** gesetztes Attribut fehlt,
      statt einen Default zu bekommen.
- [ ] **Der eigentliche Test ist der Konsument**: wenn L4 oben richtige Farben
      zeigt, stimmt diese API. Zeigt der Browser ungefärbte Blöcke, wo der Puffer
      gefärbt ist, ist hier die erste Stelle zum Nachsehen.

---

## `gopath.nvim` / `pickers.nvim` / `lib.nvim`

### M9 · Frecency für Alternate-Vorschläge

- [ ] Zwischen Alternate-Dateien hin- und herspringen. Nach einigen Sprüngen
      stehen die **häufig und zuletzt** benutzten Ziele oben, nicht die
      alphabetisch ersten.
- [ ] Die Frecency-Daten liegen in `lib.nvim` und werden von `pickers.nvim` und
      `gopath.nvim` geteilt — der Test ist, dass beide **dieselbe** Rangfolge
      zeigen, nicht zwei eigene.

### M16 · `deps.health`-Migration

- [ ] `:checkhealth pdfport` → die Werkzeugprüfung kommt aus `deps.health`, mit
      demselben Format wie bei `images.nvim` und `language.nvim`. Acht
      handgerollte `check_exe`-Aufrufstellen sind verschwunden; sichtbar ist das
      an der einheitlichen Ausgabe.

---

## nvim-config

### M5 · Sprung zur umschließenden Struktur

- [ ] `[u` setzt den Cursor auf den Kopf der Struktur, in der er steht; nochmal
      gedrückt eine Ebene weiter raus. `]u` dasselbe abwärts, zum schließenden
      Ende.
- [ ] In einer Funktion klettert es `for` → `if` → `function`; in einer
      Konfigurationstabelle Tabellenkopf um Tabellenkopf.
- [ ] Prüfen in **mehreren Sprachen** — die Queries liegen in
      `after/queries/{lua,json,python,rust,toml,yaml}/textobjects.scm`, und eine
      fehlende Query fällt sonst erst im Alltag auf.
- [ ] Es ist eine **Konfiguration**, kein Feature-Modul: `[b`/`]b` und `[s`/`]s`
      aus derselben Familie müssen unberührt weiter funktionieren.

### A · Source-Achse von `:Bindings check`

- [ ] `:Bindings check` läuft und meldet die verbliebenen echten Befunde. Von
      ursprünglich 150 blieben nach zwei Werkzeugfixes **51** übrig — kommt eine
      wesentlich größere Zahl zurück, ist eher das Werkzeug verdächtig als die
      Config.
- [ ] Stichprobe gegen den Notizbaum: ein gemeldeter Keymap fehlt dort
      tatsächlich, ein nicht gemeldeter steht dort.

---

## Nicht von Hand prüfbar — und was stattdessen gilt

Vollständigkeitshalber, damit niemand danach sucht.

| Punkt | Warum nicht | Was stattdessen zählt |
|---|---|---|
| **QW4** Diagnostics-Debounce | 150 ms sind nicht fühlbar | 18 Specs; das Fenster ist **leading-edge** — der erste Push kommt sofort, nur die Nachzügler werden gebündelt. Ein trailing debounce hätte ausgerechnet den wichtigen Push verzögert |
| **QW5** Hover-Cache | ein gesparter Roundtrip ist unsichtbar | 6 Specs; LRU mit Kapazität 32, Schlüssel `(bufnr, changedtick, row, col)`. Wiederholter Hover auf derselben Position bei unverändertem Buffer darf keinen neuen Request auslösen |
| **QW6** `formatter_priority` | bewusst **report-only** | Der Key ordnet `formatters_by_ft` **nicht** um — das ging nicht, weil dort Werkzeugnamen stehen. Er wird nur berichtet, und genau das ist jetzt dokumentiert statt implizit |
| **QW9** reposcope-Kreuzung | eine Messung, kein Feature | **Card endgültig abgelehnt**: `opengraph.githubassets.com` limitiert auf 100/IP, danach 900 s Sperre — vier von zwölf kamen als 429 zurück. Die README-Bild-Hälfte blieb offen |
| **M16**, **M17/M13**, **B**, **AUDIT** | Doku-/Struktur-Arbeit | Prüfbar nur durch Lesen: ein `ECOSYSTEM.md`, das fünf Repos erreichen; korrigierte Audit-Zeilen; die Bindings-Zettel gegen den Quelltext |
| **BD4** | abgelehnt, nicht gebaut | Steht als „explicitly not planned" in der Repo-Roadmap von mdview |
| **BD2**, **BD3**, **BD5** | offen, brauchen fremde Hardware oder einen Anlass | siehe `PLUGIN_ROADMAPS.md`, Abschnitt 1.4 |

---

## Wenn etwas nicht stimmt

1. In [`PLUGIN_ROADMAPS_FINISHED.md`](PLUGIN_ROADMAPS_FINISHED.md) den Eintrag
   zur ID lesen — dort steht, **was genau** gebaut wurde und was bewusst nicht.
   Ein gutes Drittel der Einträge korrigiert die ursprüngliche Beschreibung;
   die Erwartung kann also am falschen Text hängen.
2. Prüfen, ob der Punkt eine Vorbedingung hat, die hier oben unter
   *Vorbereitung* steht (Rebuild, externes Werkzeug).
3. Bleibt es ein echter Befund: als offener Punkt zurück in
   [`PLUGIN_ROADMAPS.md`](PLUGIN_ROADMAPS.md), mit der ID des ursprünglichen
   Punktes im Text — sonst geht der Zusammenhang beim nächsten Durchgang
   verloren.
