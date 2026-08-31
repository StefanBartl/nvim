# Plugin-Roadmaps — konsolidierter Report

Stand: 2026-08-30 (Erhebung 2026-08-29). Quelle: `docs/ROADMAP.md` bzw. `docs/ROADMAP/` aus allen 31
`*.nvim`-Repos unter `C:\repos`, plus die drei Dokumente, auf die diese
Roadmaps als eigentliche Warteschlange verweisen (`docmap-desktop/docs/PLAN.md`
sowie die damaligen `images.nvim`-CROSS-PLUGIN- und
`lib.nvim`-dependency-installer-Notizen).

> **Wo die Quellen jetzt liegen.** Am 2026-08-29 wurden sämtliche
> `docs/ROADMAP`-Bäume aus den Plugin-Repos herausgelöst und nach
> `C:\repos\WKDBooks\Development\wkdbook-myplugins\<plugin>\ROADMAP\`
> Verweise mehr darauf, weder Links noch Prosa-Zitate. Dateipfade wie
> `images.nvim/docs/ROADMAP/TERMINALS.md`, die dieser Report weiter unten
> nennt, meinen also den Stand *vor* dem Umzug; die Datei liegt heute unter
> `wkdbook-myplugins/images.nvim/ROADMAP/TERMINALS.md`. Einzige Ausnahme:
> `docmap-desktop/docs/PLAN.md` ist nie umgezogen und liegt weiterhin dort.

Dieser Report erledigt den offenen MERGED.md-Punkt *"Pro offenem
ROADMAP-Punkt einen konkreten Umsetzungsplan ausarbeiten"* für die
Plugin-Seite: er sammelt jeden offenen Punkt, sagt, worin die Umsetzung
konkret besteht, und schätzt Aufwand und Nutzen.

---

## Table of content

  - [TASK an Claude delegieren (Claude soll diesen Punkt nicht bearbeiten!)](#task-an-claude-delegieren-claude-soll-diesen-punkt-nicht-bearbeiten)
  - [Arbeitsmodus](#arbeitsmodus)
  - [Naechster Schritt](#naechster-schritt)
    - [Offen: die Live-Achse braucht eine echte Sitzung](#offen-die-live-achse-braucht-eine-echte-sitzung)
  - [Legende](#legende)
  - [Kurzfassung](#kurzfassung)
  - [1.0 Erledigt](#10-erledigt)
  - [1.1 Quick Wins (XS–S, Nutzen mittel bis hoch)](#11-quick-wins-xss-nutzen-mittel-bis-hoch)
  - [1.2 Mittel (M)](#12-mittel-m)
    - [M10 · `images.nvim` — Sixel-Backend](#m10-imagesnvim-sixel-backend)
    - [M12 · `images.nvim` — Flamegraphs als Bild (`runtime-analysis.nvim`)](#m12-imagesnvim-flamegraphs-als-bild-runtime-analysisnvim)
    - [M14 · `filetree.nvim` — `cwd_mode`-Badge optimieren](#m14-filetreenvim-cwd_mode-badge-optimieren)
    - [M17 · `documentation.nvim` / `runtime-analysis.nvim` / `docmap-desktop` — M11](#m17-documentationnvim-runtime-analysisnvim-docmap-desktop-m11)
  - [1.3 Groß (L)](#13-gro-l)
    - [L1 · `images.nvim` — Kitty-APC-Backend](#l1-imagesnvim-kitty-apc-backend)
    - [L3 · `lsp.nvim` — das Signature-Help-Modul schrumpfen](#l3-lspnvim-das-signature-help-modul-schrumpfen)
    - [L4 · `mdview.nvim` — das nvim-Highlighting im Browser spiegeln](#l4-mdviewnvim-das-nvim-highlighting-im-browser-spiegeln)
    - [L5 · `documentation.nvim`-Verbund — L1 bis L9 aus `PLAN.md`](#l5-documentationnvim-verbund-l1-bis-l9-aus-planmd)
  - [1.4 Braucht dich](#14-braucht-dich)
    - [BD2 · `open.nvim` — die Nicht-Windows-Reveal-Pfade auf echter Hardware prüfen](#bd2-opennvim-die-nicht-windows-reveal-pfade-auf-echter-hardware-prfen)
    - [BD3 · `lib.nvim` — Windows-Elevation im Dependency-Installer](#bd3-libnvim-windows-elevation-im-dependency-installer)
    - [BD4 · `mdview.nvim` — externe Renderer-Website (opt-in)](#bd4-mdviewnvim-externe-renderer-website-opt-in)
    - [BD5 · `mdview.nvim` — PDF-Seiten-Preview im Link-Hover](#bd5-mdviewnvim-pdf-seiten-preview-im-link-hover)
  - [2.1 Repos mit offener Arbeit](#21-repos-mit-offener-arbeit)
    - [`color_my_ascii.nvim` — zwei Konzepte ohne Umsetzungsentscheidung](#color_my_asciinvim-zwei-konzepte-ohne-umsetzungsentscheidung)
  - [2.2 Repos ohne offene Arbeit](#22-repos-ohne-offene-arbeit)
  - [3.1 Die Audit-Dokumente sind veraltet — und zwar systematisch](#31-die-audit-dokumente-sind-veraltet-und-zwar-systematisch)
  - [3.2 `ROADMAP.md` heißt in diesen Repos vier verschiedene Dinge](#32-roadmapmd-heit-in-diesen-repos-vier-verschiedene-dinge)
  - [3.3 Die Warteschlangen liegen zu dritt außerhalb der Roadmaps](#33-die-warteschlangen-liegen-zu-dritt-auerhalb-der-roadmaps)
  - [3.4 Drei Punktpaare hängen aneinander und sollten zusammen gebaut werden](#34-drei-punktpaare-hngen-aneinander-und-sollten-zusammen-gebaut-werden)

---

## TASK an Claude delegieren (Claude soll diesen Punkt nicht bearbeiten!)

In C:/Users/StefanBartl/AppData/Local/nvim/docs/ROADMAP/personal/All/PLUGIN_ROADMAPS.md: lese dir die ersten punkte durch, arbeitsmodi, nächster empfohlener schritt usw. Erkläre mir den Task dann im sinne von Was? Warum? Was bringt es Usern? Aufwand/Nutzen? Empfehlung von dir: Implementieren oder nicht, anders,... Ich netscheide dann, ob wir den punkt imlementieren, ersatzlos streichen oder markiert und begründet zurückstellen. dann gehe den nächsten schritt an oder wenn abgelehnt, such den nächsten von der liste und das geliche nochmal von vorne.

comitte und push/pull immer auf main wenn fertig, damit ich es gleich verwenden kann. wenn fertig, update C:/Users/StefanBartl/AppData/Local/nvim/docs/ROADMAP/personal/All/PLUGIN_ROADMAPS.md - die erledigt task nach C:/Users/StefanBartl/AppData/Local/nvim/docs/ROADMAP/personal/All/PLUGIN_ROADMAPS_FINISHED.md und den nächsten empfohlenen schritt analysieren - dab ei brauchst du aber nicht begrpnden, welche task du nicht machen würdest.

---

## Arbeitsmodus

Wie an dieser Liste gearbeitet wird. Festgehalten, weil die Regeln sonst pro
Sitzung neu verhandelt werden.

- **Ein Commit pro Repo und Thema**, direkt gepusht, damit die Repos
  durchgehend benutzbar bleiben.
- **Ein Punkt nach dem anderen.** Vor der Umsetzung wird der naechste Punkt so
  erklaert, dass die Entscheidung — machen, ueberspringen, anders zuschneiden —
  nachvollziehbar getroffen werden kann. Erst danach wird gebaut.
- **Immer mit Empfehlung.** Zur Auswahl gehoert, welche Option empfohlen wird
  und warum. Eine Liste gleichwertig praesentierter Moeglichkeiten schiebt die
  Arbeit nur weiter, statt sie zu leisten — wer den Code gelesen hat, hat auch
  eine Meinung dazu und schuldet sie.
- **Immer mit konkreter Auswirkung.** Zu jeder Option gehoert, was sich damit
  im taeglichen Gebrauch aendert: welche Taste, welche Ausgabe, welches
  Verhalten — und ausdruecklich auch dann, wenn die Antwort "gar nichts, nur
  die Beschreibung stimmt danach" lautet. Begriffe wie "report-only" oder
  "verkabeln" beschreiben die Arbeit, nicht die Folge; die Folge ist das, was
  die Entscheidung traegt.
- **Erledigtes wandert nach
  [`PLUGIN_ROADMAPS_FINISHED.md`](./PLUGIN_ROADMAPS_FINISHED.md)**, samt der
  Notizen, die beim Bauen angefallen sind. Diese Datei bleibt damit eine Liste
  offener Arbeit und nicht eine Mischung aus beidem.
- **Bindings-Zettel mitpruefen.** Aendert ein Punkt Usercmds, Autocmds oder
  Keymaps wesentlich, gehoert neben die repo-eigenen Docs auch
  `docs/NOTES/PersonelPlugins/BINDINGS/{Keymaps,Usercmds,Autocmds}/<plugin>.md`
  geprueft — das ist der Baum, aus dem `:Bindings browse`/`:Bindings check`
  liest, und der driftet still.
- Mit mir redest du im chat auf deutsch, im Source Code aber alles Englisch - egal ob Code, Kommentare oder Docs.

---

## Naechster Schritt

Stand 2026-08-31. Zuletzt erledigt: **M17/QW6** — Fenced Blocks auf der
generierten Seite, und der Eintrag lag zum ersten Mal nach der *anderen* Seite
daneben: die Features-Tab splittete Fences laengst und warf nur die Sprache
weg. Davor **M13** (`:Image scale`/`optimise`/`convert`), **M11** (OCR, in
beiden Haelften), **M17/M10**, **M9** (Frecency ueber drei Repos), **M17/M7c**
(und im selben Zug **M17/M7b zurueckgestellt**), **M17/M14**, **M17/M9**,
**M17/M8**, **M17/M13**, **Call Hierarchy**, **M5**, **M4a**, **M3**, **M2**,
**M16**, **QW5**, **M1**, **M17/M7**, **M6 + M7**, **QW8**, **QW10**, **QW1**,
**A** und **B**; zurueckgestellt sind ausserdem **M4b** und **M17/M12**.
Notizen zu allen in
[`PLUGIN_ROADMAPS_FINISHED.md`](./PLUGIN_ROADMAPS_FINISHED.md).

**Der documentation-Verbund hat damit ausser den L-Punkten nur noch M17/M11**,
und der steht seit dem 2026-08-31 mit dem Befund da, dass **kein** Repo hier
Routen deklariert, die der Endpoint-Scanner sieht. `images.nvim` hat nur noch
das Sixel-Paket. Was uebrig bleibt, ist duenn — und der naechste Punkt ist der
erste seit Langem, dessen Beschreibung eine **Voraussetzung** unterstellt, die
es nicht gibt.

**Empfohlen: M12 — Flamegraphs als Bild, aber neu zugeschnitten**
(`runtime-analysis.nvim` + `images.nvim` + `documentation.nvim`, Aufwand M,
siehe [1.2](#12-mittel-m)).

*Nachgesehen, und der Eintrag setzt etwas voraus, das fehlt*: in
`runtime-analysis.nvim` gibt es **keinen Flamegraph**. Kein Modul, kein Befehl,
nicht einmal das Wort — `grep -i flame` ueber den ganzen Baum ist leer. „Als
Bild rendern statt als Textbaum" beschreibt also eine Umstellung, die kein
Original hat.

*Aber das Material dafuer liegt da, und zwar genau richtig geschnitten*:
`telemetry/startup.lua` umhuellt das globale `require` und misst jeden
Cache-Miss, mit einem Stack. Jeder Eintrag traegt `depth`, `total_ms` und
`self_ms` — die Selbstzeit ist die Gesamtzeit minus alles, was das Modul
seinerseits nachgeladen hat. Das *ist* die Datenstruktur eines Flamegraphs:
verschachtelte Rechtecke, Breite = Zeit, Tiefe = Verschachtelung. Gerendert
wird sie heute als `M.lines` (Text) und `M.markdown`.

*Der Zuschnitt, der daraus einen M macht statt eines L*: **nicht** „einen
Profiler bauen", sondern „den Require-Baum, der ohnehin gemessen wird, als
SVG zeichnen". Ein drittes `M.svg` neben `lines` und `markdown`, aus denselben
Eintraegen. Danach ist die Kreuzung trivial: eine SVG-Datei zeigt `:Image`
ueber die vorhandene, gecachte SVG→PNG-Umwandlung, und
`documentation.nvim`s Runtime-Abschnitt — der heute nur Text zeigt — bekommt
dasselbe Bild.

*Was vorher zu entscheiden ist*: ob der Graph nach Startup-Zeit **oder** nach
`:RA usage`-Daten gezeichnet wird. Beide haben Stacks, aber nur der
Startup-Baum hat sie vollstaendig; `usage` zaehlt Aufrufe pro Funktion ohne
Elternkette. Der Startup-Baum ist damit der einzige, aus dem heute ein
korrekter Flamegraph faellt — und zugleich der, dessen Frage („warum startet
das so langsam") man tatsaechlich stellt.

---

### Offen: die Live-Achse braucht eine echte Sitzung

Die 260 verbliebenen Befunde sind zu zwei Dritteln
`usercmd-undocumented` (166) — der bekannte Abschnitt mit fremder
Plugin-Infrastruktur, die dieser Korpus nie abdecken sollte. Die 88
`keymap-not-live` sind ueberwiegend fensterlokale Tasten von Plugins, deren
UI headless nicht offen ist. Beides laesst sich nur in einer laufenden,
benutzten Sitzung sinnvoll durchgehen, nicht headless.

**Empfehlung**: nicht angehen, solange niemand danebensitzt. Der Rest der
Reihenfolge steht in Teil 4.

---

## Legende

**Aufwand** (Klassen wie in `docmap-desktop/docs/PLAN.md`, damit die Zahlen
vergleichbar bleiben):

| | |
|---|---|
| **XS** | unter einer Stunde |
| **S** | wenige Stunden |
| **M** | ein Arbeitstag oder mehr |
| **L** | mehrere Sessions |

**Nutzen**: hoch / mittel / niedrig — gemessen daran, ob der Punkt einen
echten Defekt schließt (hoch), eine vorhandene Fähigkeit verbessert (mittel)
oder eine neue, bisher nicht vermisste Fähigkeit hinzufügt (niedrig).

**Braucht dich**: der Punkt lässt sich nicht delegieren, weil er eine
laufende interaktive Session, fremde Hardware, ein anderes Betriebssystem
oder eine Namens-/Scope-Entscheidung verlangt.

---

## Kurzfassung

- **31 Plugins geprüft.** 20 davon haben **keine offene Arbeit** in ihrer
  Roadmap — die Datei ist entweder leer oder sagt ausdrücklich, dass alles
  ausgeliefert ist.
- **Offene Arbeit liegt in 8 Repos**: `lsp.nvim`, `images.nvim`,
  `mdview.nvim`, `open.nvim`, `filetree.nvim`, `gopath.nvim`, `lib.nvim`,
  sowie der Dreier-Verbund `documentation.nvim` / `runtime-analysis.nvim` /
  `docmap-desktop`.
- **Insgesamt 16 offene Punkte**, davon **kein** Quick Win mehr und 4, die
  dich brauchen. `lsp.nvim` hat ausser den L-Punkten **keinen offenen Punkt
  mehr**, `gopath.nvim` ebenfalls keinen. Alle neun Quick Wins (QW1, QW3,
  QW4, QW5, QW6, QW7, QW8, QW9, QW10) sowie **M1**, **M2**, **M3**, **M4a** und
  **M6 + M7** (`lsp.nvim`), **M16** (`lib.nvim` + `pdfport.nvim`) und
  **M17/M7**, **M17/M13**, **M17/M8**, **M17/M9**, **M17/M14**, **M17/M7c**,
  **M17/M10**, **M9** (Frecency ueber drei Repos), **M11** (OCR —
  `:Image ocr` plus `:Case ocr`, `images.nvim` und casedesk), **M13**
  (`:Image scale`/`optimise`/`convert`) und **M17/QW6** (Fenced Blocks auf
  der generierten Seite)
  sind erledigt und stehen unter 1.0, ebenso **M5** —
  der ist als Treesitter-Konfiguration im Config-Repo gelandet statt als
  Plugin-Feature. **M4b**, **M17/M12** und **M17/M7b** sind zurueckgestellt und
  stehen mit Begruendung im selben Dokument. Dass die Summe ueberhaupt faellt,
  ist neu: M17/M7 hatte seine offen gebliebene Haelfte als **M17/M7b**
  hinterlassen und M17/M13 die seine als **M17/M14** — der erste ist jetzt
  geschlossen, ohne gebaut zu werden, weil an seiner Stelle der Befund
  ausgeliefert wurde (**M17/M7c**).
- **Ein Querschnittsbefund, der Zeit spart**: die Audit-Dokumente
  (`Arch&Coding.md`, `Checklist.md`, `Zentral-Prinzipien.md`) in acht Repos
  führten noch Lücken (`❌`), die längst geschlossen waren — stichprobenhaft
  geprüft, und **alle fünf Stichproben waren veraltet**. Am 2026-08-29
  korrigiert; die Dokumente sind seither in
  [`docs/NOTES/RULES.md`](../../../NOTES/RULES.md) aufgegangen. Details in
  Teil 3.
- **Die Bindings-Drift-Achse war zu 2/3 Werkzeugfehler**: von 150
  Source-Achsen-Befunden blieben nach zwei Fixes in `drift.lua` und einer
  frischen Karte 51 echte übrig, und die sind seit 2026-08-30 dokumentiert.
  Siehe „Naechster Schritt".

---

# Teil 1 — Die offene Arbeit, nach Verhältnis sortiert

---

## 1.0 Erledigt

Ausgelagert nach
[`PLUGIN_ROADMAPS_FINISHED.md`](./PLUGIN_ROADMAPS_FINISHED.md), samt den Notizen,
die beim Bauen angefallen sind. Bisher: **QW3**, **QW4**, **QW5**, **QW6**,
**QW7**, **QW8**, **M1**, **M2**, **M3**, **M4a** und **M6 + M7** (alle
`lsp.nvim`), **M5** (nvim-config, als Treesitter-Konfiguration statt als
Plugin-Feature), **QW9**
(`images.nvim`), **QW1** und **QW10** (beide `mdview.nvim`; QW10 fiel beim
Durchtesten von QW1 an), **M16** (`lib.nvim` + `pdfport.nvim`), **M17/M7**
(Phase-0-IR im documentation-Verbund), **M17/M13** (ein `ECOSYSTEM.md`, fuenf
Repos erreichen es), **M17/M8** (`:DocMap impact` nach Runtime-Reichweite),
**M17/M9** (`:DocMap why` × Call-Trees), **M17/M14** (Cross-Repo-Doku-Verweise
per CI), **M17/M7c** (eine Datei, mehrere Modul-Identitaeten — gemeldet statt
geerbt), **M9** (Frecency ueber `lib.nvim` + `pickers.nvim` + `gopath.nvim`),
**M17/M10** (Laufzeit-Evidenz unterdrueckt `unreferenced-module`), **M11**
(OCR — `:Image ocr` in `images.nvim` und `:Case ocr` in casedesk, wo der
Screenshot-Text seither in `:Cases grep` und im `:Case ki`-Prompt landet),
**M13** (`:Image scale`/`optimise`/`convert` — unter `:Image` entschieden,
nicht unter `:File`), **M17/QW6** (Fenced Blocks auf der generierten Seite,
hervorgehoben durch den Tokenizer, den die Quelltext-Ausschnitte schon nutzen)
sowie **A** (Source-Achse von `:Bindings check`, nvim-config) und **B**
(die verbliebenen Audit-Zeilen). **Zurueckgestellt**,
mit Begruendung im selben Dokument: **M4b**, **M17/M12** und **M17/M7b**.

---

## 1.1 Quick Wins (XS–S, Nutzen mittel bis hoch)

**Leer seit 2026-08-30.** Alle neun sind gebaut; QW5 war der letzte. Der
Abschnitt bleibt stehen, damit die Nummerierung der anderen Abschnitte nicht
wandert und ein Querverweis von außen weiter aufgeht.

---

## 1.2 Mittel (M)

---

### M10 · `images.nvim` — Sixel-Backend

**Aufwand M–L · Nutzen mittel**

Für Terminals, die Sixel können, aber kein OSC 1337 (xterm mit
`--enable-sixel-graphics`, mlterm, Windows Terminal ab 1.22). Nach OSC 1337
die zweitgrößte Reichweite.

*Vorbedingung, die dadurch erst Sinn ergibt*: die Terminal-Erkennung via
`ESC [ > q` (XTVERSION, **S**). Solange es genau ein Backend gibt, entscheidet
Erkennung nur, ob eine Warnung erscheint; mit einem zweiten Backend wird sie
zur Voraussetzung. Also: Sixel und XTVERSION-Detection sind ein Paket.

---

### M12 · `images.nvim` — Flamegraphs als Bild (`runtime-analysis.nvim`)

**Aufwand M · Nutzen mittel**

In 60×25 Zellen nur eine grobe Übersicht — aber das Bild landet ohnehin als
gewöhnliche Datei auf der Platte und ist mit Zoom in Browser oder mdview in
voller Auflösung lesbar. Dieselbe Grafik gehört zusätzlich in
`documentation.nvim`, wo der Abschnitt für Runtime-Daten heute nur Text zeigt.

---

### M14 · `filetree.nvim` — `cwd_mode`-Badge optimieren

**Aufwand S–M · Nutzen niedrig**

`component()` liefert das Badge als reinen Text für das, was die Statusline
zeichnet (natives `%{v:lua…}`, heirline oder lualine — alle drei dokumentiert,
keins eine Abhängigkeit). Der Redraw-Pfad rechnet bei jedem Aufruf neu, und
`refresh()` bittet den Host um ein Redraw statt umgekehrt. Es ist das Stück,
das angefasst wird, wenn die persönliche Config je ihr Statusline-Framework
wechselt — bis dahin billig und korrekt zu machen lohnt.

---

### M17 · `documentation.nvim` / `runtime-analysis.nvim` / `docmap-desktop` — M11

**Aufwand je M · Nutzen mittel bis hoch**

Diese drei Repos haben ihre Warteschlange seit 2026-08-20 in genau einem
Dokument: `docmap-desktop/docs/PLAN.md`. Die Roadmaps der beiden
nvim-Plugins sind bewusst nur noch Prosa-Ausblick und verweisen dorthin.
Offen sind dort:

| # | Was | Klasse |
|---|---|---|
| ~~**M7**~~ | ~~Phase-0-IR: besitzender Scope~~ — **erledigt 2026-08-30**, siehe [`PLUGIN_ROADMAPS_FINISHED.md`](./PLUGIN_ROADMAPS_FINISHED.md) | — |
| ~~**M7b**~~ | ~~Eine Datei / viele Module~~ — **zurueckgestellt 2026-08-31**; an seiner Stelle **M7c**, der Befund `file-holds-many-modules`, **erledigt 2026-08-31** | — |
| ~~**M8**~~ | ~~`:DocMap impact`, gewichtet nach Runtime-Reichweite~~ — **erledigt 2026-08-30** | — |
| ~~**M9**~~ | ~~`:DocMap why` × Call-Trees~~ — **erledigt 2026-08-30**, und es war gar kein Runtime-Punkt | — |
| ~~**M10**~~ | ~~Runtime-Evidenz als Check-*Input*~~ — **erledigt 2026-08-31**, und die Haelfte war schon gebaut | — |
| **M11** | Endpoint-Inventar × Request-History × Response-Shape | M |
| ~~**M12**~~ | ~~Runtime-Tab im ausgelieferten Artefakt~~ — **zurueckgestellt 2026-08-30**, die Substanz war gebaut | — |
| ~~**M13**~~ | ~~Ein `ECOSYSTEM.md`, vier Repos lesen es~~ — **erledigt 2026-08-30** | — |
| ~~**M14**~~ | ~~Cross-Repo-Doku-Verweise, per CI geprueft~~ — **erledigt 2026-08-31**, und groesser als beschrieben: die Konfigurationsform fehlte noch | — |
| ~~**QW6**~~ | ~~Fenced Blocks auf der generierten Seite~~ — **erledigt 2026-08-31**, und der Eintrag war zu pessimistisch: die Features-Tab splittete Fences laengst | — |

**M7 ist am 2026-08-30 gebaut** — `owner`/`owner_kind` auf
`Documentation.FunctionInfo`, Schema 6, vierzehn der zwanzig Backend-Dateien
setzen sie, und die Karte gruppiert danach. Was davon offen blieb, war **M7b**:
ein Scope ist kein Knoten, also hat ein Rust-`mod x { … }` weiterhin keine
eigene Identität.

**M7b ist am 2026-08-31 zurueckgestellt**, und die Zahlen sind der Grund.
`Documentation.Node.id` *ist* der repo-relative Pfad — im Walk, in `stats`, in
jeder `id`, im Artefakt: 31 Lua-Dateien des Plugins und 23 Stellen im
Rust-Server haengen daran, das ist ein L und kein M. Der Nutzen im eigenen
Korpus ist dabei null: `docmap-desktop` ist der einzige Rust-Baum, haelt elf
Inline-Module, und es sind elf `mod tests`; Elixir kommt nirgends vor. Und
`PLAN.md` plant den Punkt selbst nicht ein — „not scheduled by that argument
alone" steht dort woertlich, ein Satz, der beim Hochstufen in diesen Report
verlorengegangen war.

**An seiner Stelle ist der kleinere Zuschnitt gebaut: M7c**, der Check
`file-holds-many-modules`. Eine Datei mit mehreren Modul-Identitaeten wird
gemeldet, statt still fuer alle zu antworten — die falsche Identitaet wird
sichtbar, ohne dass die Id-Form der Karte angefasst wird. Auf dem eigenen
Korpus korrekt still, gegen `docmap-desktop` verifiziert.

**M12 ist am 2026-08-30 zurueckgestellt worden**, und der Grund raeumt die
ganze Reihenfolge auf: die Oberfläche, auf die M8 bis M11 angeblich warten,
existiert bereits — `Telemetry` und `Loaded` liegen als Analysis-Werkzeuge auf
der Seite, holen ihre Daten zur Ansichtszeit und antworten auf beiden Hosts.
Offen war nur eine Gruppierungsfrage (eigener Top-Level-Reiter statt zwei
Einträge unter siebzehn), und die trägt sich erst mit dem dritten Bewohner.

**Damit hält nichts mehr etwas anderes auf.** **M8 ist am 2026-08-30 erledigt**
und war genau das, wonach er aussah, nur kleiner: eine Kreuzung zweier
vorhandener Antworten über einen gemeinsamen Schlüssel. **M9 ist am selben Tag erledigt** und
war gar kein Runtime-Punkt: die Call-Kanten liegen seit jeher in jeder
erzeugten Karte, gefehlt hat nur die Traversierung. **M14 ist am 2026-08-31 erledigt** und war
groesser als beschrieben: `external_repos` ist nach Modul-Praefix
geschluesselt, eine Doku-Zitierung nach Repo-Verzeichnisname, und die beiden
fallen ausgerechnet bei `documentation.nvim` auseinander. **Offen ist in
diesem Verbund damit nur noch M11** — eine fehlende Faehigkeit, keine
falsche Auskunft.

**M10 ist am 2026-08-31 erledigt**, und die Haelfte war schon gebaut —
`dead-function` las Telemetrie bereits als Unterdrueckung. Gefehlt hat die
zweite Stelle: `unreferenced-module`, das seinen Vorbehalt selbst im Quelltext
stehen hatte („a module may legitimately be reached only through the
aggregator's string map") und damit `lib.nvim` beschreibt. Gemessen dort: 71
Befunde vorher, 68 nachher, 0 neu erzeugt. **Offen ist in diesem Verbund
damit nur noch M11.**

**M13 ist erledigt** und hat einen neuen Punkt hinterlassen: **M14**, die
Hälfte, die kein Zeiger war — Cross-Repo-Doku-Verweise, per CI geprüft.
`doc-references-missing` löst Code-Bezeichner gegen die eigene Modulkarte auf,
`dead-readme-link` löst Markdown-Links innerhalb *eines* Repos auf und streift
vorher Code-Spans ab. Beide sind korrekt; die dritte Form —
`<repo>/<pfad>` gegen deklarierte Geschwister — fehlt, und `external_repos`
trägt die Zuordnung dafür schon.

---

## 1.3 Groß (L)

---

### L1 · `images.nvim` — Kitty-APC-Backend

**Aufwand L · Nutzen hoch**

Für Kitty und Ghostty. Bringt dort zusätzlich Unicode-Placeholder und damit
**echtes Inline-Rendering im Textfluss** — das eine, was das Plugin heute
grundsätzlich nicht kann. Der größte Fähigkeitssprung auf der ganzen Liste,
und entsprechend teuer.

---

### L3 · `lsp.nvim` — das Signature-Help-Modul schrumpfen

**Aufwand L · Nutzen niedrig**

`tools/lsp_signature/**` ist eine vollständige Eigenimplementierung (~800
LOC). Die Roadmap sagt selbst: "vorerst nur beobachten". Bleibt so.

---

### L4 · `mdview.nvim` — das nvim-Highlighting im Browser spiegeln

**Aufwand M (war L) · Nutzen mittel — die Hälfte des Wegs steht schon**

Aus dem `SCHLACHTPLAN.md`. Vier Schritte, würde die JS-Abhängigkeiten
(hljs/shiki) ersetzen:

1. **gebaut** — `color_my_ascii.highlight_export.runs_for_block(bufnr, block)`
   liefert die Spans eines Fence als row/col/hl_group, gelesen aus den
   `ColorMyAscii`-Extmarks. Genau die Export-Funktion, die der Plan als
   `tokenize_block` beschreibt.
2. **gebaut** — dieselbe Datei löst `hl_group -> #hex` über `nvim_get_hl`
   auf (`resolve_attrs`/`int_to_hex`), heute für `:Fence export --html`.
3. offen — Transport der Spans pro Codeblock an den Client, gebunden an die
   `data-sourcepos` des `<pre>`.
4. offen — der Client legt die Spans um den Code.

*Die eine Einschränkung*: `runs_for_block` liest die Extmarks, die
color_my_ascii selbst gemalt hat — es liefert also nur dort etwas, wo
color_my_ascii den Block schon eingefärbt hat. Die Alternative aus dem Plan
(Treesitter direkt in mdview, allgemeiner, keine Fremdabhängigkeit) bleibt
davon unberührt.

---

### L5 · `documentation.nvim`-Verbund — L1 bis L9 aus `PLAN.md`

**Aufwand je L · Nutzen gemischt**

Jeder Punkt ist zuerst eine **Scope-Entscheidung**, erst danach eine
technische Aufgabe: Call-Edges für die restlichen achtzehn Sprachen (L1),
i18n vollständig (L2), die fünfzehn weiteren Sprachen (L3), API-Traffic als
Messung (L4), Multi-Language-Telemetrie (L5), einen Agenten die Checklisten
laufen lassen (L6), Extension-API Stufe 3 mit Schreibrichtung (L7), zwei
Artefakte in der Seite vergleichen (L8), ganz ohne Neovim (L9).

Vollständige Begründung je Punkt steht in `PLAN.md`; hier nicht dupliziert,
weil dieses Dokument sonst zur zweiten Wahrheit wird — genau das Problem, das
`PLAN.md` 2026-08-20 gelöst hat.

---

## 1.4 Braucht dich

---

### BD2 · `open.nvim` — die Nicht-Windows-Reveal-Pfade auf echter Hardware prüfen

**Aufwand S · Nutzen mittel · braucht einen Linux- und einen macOS-Host**

Der Linux-Zweig wählt inzwischen einen select-fähigen Manager (nautilus,
nemo, `dolphin --select`, thunar, caja) und hält `xdg-open` von Dateien fern —
eine Datei zu übergeben startet sonst deren Standardanwendung statt eines
Dateimanagers. Diese Reihenfolge ist **aus den dokumentierten Flags
abgeleitet, nicht ausgeführt**. macOS `open -R` ist genauso unverifiziert.

---

### BD3 · `lib.nvim` — Windows-Elevation im Dependency-Installer

**Aufwand S · Nutzen mittel · braucht eine Maschine, die Elevation wirklich verlangt**

`choco` will eine elevierte Shell, `winget` wirft eine eigene UAC-Abfrage. Das
aktuelle Design reicht beides an das Terminal weiter, in dem der Nutzer den
Befehl abschickt — die richtige Grenze, aber bisher nur durchdacht, nicht
ausprobiert.

---

### BD4 · `mdview.nvim` — externe Renderer-Website (opt-in)

**Aufwand M · Nutzen niedrig · Entscheidung liegt bei dir**

Rendering optional an eine externe Website auslagern. **Der Vorbehalt**: das
widerspricht dem Loopback-only-Modell, Dokumentinhalt verließe das Gerät. Nur
als ausdrückliches Opt-in mit klarem Datenschutzhinweis denkbar.
`browser.open_url` deckt einen Teil des Bedarfs bereits ab.

*Empfehlung*: ablehnen und aus der Roadmap streichen, oder als "explizit nicht
geplant" festschreiben. Ein offener Punkt, den man aus Prinzip nicht baut,
kostet bei jedem Durchgang erneut Lesezeit.

---

### BD5 · `mdview.nvim` — PDF-Seiten-Preview im Link-Hover

**Aufwand M–L · Nutzen niedrig · bewusst zurückgestellt seit 2026-08-17**

Der Browser-Hover zeigt für `.pdf`-Ziele nur den Dateinamen; der
In-Editor-Hover in `markdown.nvim` rendert dagegen Seite 1 inline, weil
`pdfport.render_page` dort im selben Prozess sitzt. Über den Browser wäre der
Weg: Anfrage in eine Server-Queue, bis zu 250 ms bis Neovim pollt, mehrere
hundert ms für `pdftoppm`, und das PNG landet im Temp-Verzeichnis — also
**nicht** über `/asset` auslieferbar, weil diese Route bewusst auf das
Dokumentverzeichnis begrenzt ist. Ergebnis: rund eine Sekunde Latenz für einen
Hover plus eine neue Route, die die Verzeichnisbindung aufweichen müsste.

*Der saubere Weg, falls je gewollt*: beim Doc-Push vorrendern statt beim Hover
anfragen. Neovim kennt beim Senden die Links, könnte referenzierte PDFs vorab
rastern und die PNGs **neben das Dokument** legen — `/asset` greift dann
unverändert. Preis: Rasterarbeit für PDFs, die niemand hovert, und
Schreibzugriff neben dem Dokument (Cache-Verzeichnis, Aufräumen,
`.gitignore`-Frage).

*Empfehlung*: liegen lassen, bis ein konkreter Fall auftritt.

---

# Teil 2 — Plugin für Plugin

---

## 2.1 Repos mit offener Arbeit

| Plugin | Offen | Schwerpunkt |
|---|---|---|
| `lsp.nvim` | 13 | Feature-Tabelle §14 plus 2 Punkte aus der geretteten LSPDoctor-Analyse |
| `images.nvim` | 8 | Backends (Sixel, Kitty APC), Detection, 5 Cross-Plugin-Kreuzungen |
| `mdview.nvim` | 2 + 1 | 2 Grundsatzfragen (BD4, BD5), plus L4 aus dem SCHLACHTPLAN |
| `lib.nvim` | 2 | eine `deps.health`-Migration, Windows-Elevation |
| `open.nvim` | 1 | plattformabhängig, braucht dich |
| `filetree.nvim` | 1 | Badge-Optimierung |
| `gopath.nvim` | 1 | Frecency (repo-übergreifend) |
| `documentation.nvim`-Verbund | 8 + 9 | zentral in `docmap-desktop/docs/PLAN.md` |
| `color_my_ascii.nvim` | 2 Konzepte | siehe unten |

---

### `color_my_ascii.nvim` — zwei Konzepte ohne Umsetzungsentscheidung

**je M–L · Nutzen mittel**

Die Roadmap sagt korrekt "keine offenen Punkte", aber zwei Konzeptdokumente
unter `docs/ROADMAP/` beschreiben je einen ungebauten Weg:

- **`fence_highlighter_api.md`** — können andere Plugins, externe Apps oder
  CLI-Tools das Highlighting *innerhalb* eines Fence übernehmen oder steuern?
  Zwei Bausteine existieren: `color_my_ascii.api.fences` (stabile,
  sprachagnostische Fence-Erkennung, gecacht pro `(bufnr, changedtick)`, wird
  heute schon von `markdown.nvim` konsumiert) und `color_my_ascii.fence_hl`
  (malt Markerzeilen und Blockinneres). Was fehlt, ist die Übergabe nach außen.
- **`lsp_integration_fence.md`** — zwei Wege zu vollem LSP (Completion, Hover,
  Diagnostics) innerhalb eines Fence.

Beide hängen an L4 (`mdview.nvim`) — und dessen erster Schritt ist
inzwischen gebaut: `color_my_ascii.highlight_export.runs_for_block` gibt die
Spans eines Fence zurück, statt sie nur zu malen, und `to_html` löst die
Highlight-Gruppen nach `#hex` auf. Damit existiert der kleinste sinnvolle
Baustein der Fence-Highlighter-API bereits; offen ist, ihn als *öffentliche*
Schnittstelle zu deklarieren statt als Interna von `:Fence export`.

---

## 2.2 Repos ohne offene Arbeit

Zwanzig Plugins. Aufgeteilt danach, *warum* nichts offen ist — das ist der
Unterschied zwischen "fertig" und "noch nie befüllt":

**Ausdrücklich abgearbeitet** (die Roadmap sagt, dass alles ausgeliefert ist,
und verweist auf ein Feature-Log oder einen Entscheidungsnachweis):

`cascade.nvim`, `color_my_ascii.nvim`, `dap.nvim`, `debugging.nvim`,
`emojis.nvim`, `github_stats.nvim` (alle acht Befunde aus `KONZEPT.md`
gebaut, plus zwei Fixes, die dabei anfielen), `insights.nvim`,
`markdown.nvim`, `migrate.nvim`, `pdfport.nvim` (P0–P3 plus die Verkabelung
der Aufrufer), `pickers.nvim`, `recommender.nvim`, `replacer.nvim` (sehr
lange Shipped-Liste, kein offener Rest), `reposcope.nvim`, `sandbox.nvim`,
`sessions.nvim`

**Leere Roadmap-Datei** (nur Überschrift und Trennlinie — kein Signal, ob
fertig oder nie gepflegt):

`buffer-ctx.nvim`, `cmdlog.nvim`, `diff.nvim`, `language.nvim`,
`lib.nvim/docs/ROADMAP/ROADMAP.md` (die echte lib.nvim-Arbeit steht in
`dependency-installer.md` daneben, nicht in der Roadmap-Datei),
`spotlight.nvim`, `fileops.nvim`

*Befund dazu*: bei diesen sieben ist "keine offene Arbeit" eine Annahme, keine
Aussage. Das ist billig zu reparieren — ein Satz je Datei nach dem Muster, das
`emojis.nvim`, `dap.nvim` und `open.nvim` schon verwenden ("leer aus Absicht,
nicht aus Vernachlässigung"). **Aufwand XS gesamt, Nutzen mittel**, weil es
bei jedem künftigen Durchgang genau diese Rückfrage spart.

---

# Teil 3 — Querschnittsbefunde

---

## 3.1 Die Audit-Dokumente sind veraltet — und zwar systematisch

In acht Repos standen in
`docs/ROADMAP/{Arch&Coding,Checklist,Zentral-Prinzipien}.md` noch Lücken mit
`❌`. Fünf Stichproben, alle geprüft, **alle fünf veraltet**:

| Behauptete Lücke | Tatsächlicher Stand |
|---|---|
| `open.nvim`: kein `.stylua.toml`, kein `.luacheckrc`, keine CI | `.luacheckrc` und `.github/workflows/ci.yml` existieren |
| `open.nvim`: `lib.usercmd` ungenutzt, `platform.lua` rollt Erkennung selbst | `usrcmds.lua` nutzt `lib.nvim.bindings.usercmd.composer`, `platform.lua` delegiert an `lib.nvim.cross.platform.is_*` |
| `pdfport.nvim`: `lib.notify`/`lib.map`/`lib.usercmd`/`lib.autocmd` alle ungenutzt | alle vier laufen über `lib.nvim` |
| `markdown.nvim`: kein `@types/`-Ordner, keine stylua/luacheck/CI | `lua/markdown/@types` existiert, `.luacheckrc` und CI ebenfalls |
| `github_stats.nvim`: kein lokal lauffähiger Test-Runner | `ci.yml` ruft `scripts/test.sh` |

Die Dokumente selbst sagen, ihre Konvention sei "abgearbeitete Befunde werden
entfernt, nicht abgehakt" — genau das ist bei diesen fünf nicht passiert.

**Konsequenz für diesen Report**: die `❌`-Zeilen in den Audit-Dateien wurden
**nicht** als offene Arbeit gezählt. Wer sie als Aufgabenliste liest, arbeitet
Dinge nach, die längst erledigt sind.

**Erledigt am 2026-08-29** (WKDBooks `205f152`): jede `❌`-Zeile in allen
Audit-Dateien wurde einzeln gegen den Code geprüft. Der erste Durchgang hatte
nur einen **VERALTET**-Block vorangestellt und die falschen Zeilen
stehengelassen — also genau das getan, was die Konvention dieser Dokumente
verbietet. Jetzt sind die überholten Befunde korrigiert, und der Block sagt
nur noch, was nachgezogen wurde, plus den Satz, dass ein verbliebenes `❌`
geprüft und weiterhin offen ist.

*Korrigiert*: `open.nvim` und `pdfport.nvim` §6 Testbarkeit (beide führen
"kein `test/`-Verzeichnis" als größte Lücke, beide haben `TESTS/` mit sechs
Specs und CI); `open.nvim` §7 Tooling plus drei Folgestellen im selben
Dokument, die auf "kein Test-Suite geplant" aufbauten; `open.nvim`
`lib.usercmd`/`lib.cross`; `pdfport.nvim` `lib.notify`/`lib.map`/
`lib.usercmd`/`lib.autocmd` plus zwei Folgestellen; `markdown.nvim` A3 und A7;
`github_stats.nvim` `@see` und der Test-Entry.

*Zwei Nebenbefunde*: die alten Blöcke behaupteten, `.stylua.toml` fehle
weiterhin — die Konfiguration liegt in allen vier Repos als `stylua.toml` ohne
Punkt, was stylua genauso liest. Und der Vorwurf, `github_stats`-Specs
referenzierten nicht-existente Module, war ein Lesefehler:
`dashboard.renderer`/`dashboard.navigator` sind keine `require`s, sondern die
`describe`-Überschrift in `TESTS/dashboard_spec.lua:250`.

*Geprüft und bewusst stehengelassen*: `github_stats`' `safe_call`,
strukturierte Fehlertypen, `@error`/`@raises`, Snapshot/Restore und
Tabellen-Vorreservierung (alle fünf zutreffend, drei mit eigener Begründung im
Dokument), sowie `pdfport`s `cleanup_all`.

*Die `🟡`-Zeilen, am 2026-08-30 nachgeholt*: der erste Durchgang hatte sie nur
dort mitgezogen, wo eine korrigierte `❌`-Zeile sie direkt widerlegte. Die
Nachzählung ergab 179 Markierungen, davon 114 Phantome (109 in `gopath.nvim`s
wörtlicher Kopie der *generischen* Vorlage, wo `🟡` „EMPFOHLEN" heißt; vier
Prioritätsspalten in `spotlight.nvim`; eine als `n/a` markierte in
`migrate.nvim`). Die echt prüfbaren Zeilen in `github_stats.nvim`,
`markdown.nvim` und `color_my_ascii.nvim` sind einzeln geprüft und korrigiert
— siehe „Naechster Schritt", Option B. Damit ist Teil 3.1 abgeschlossen.

**Die drei Dokumente sind aufgegangen — Einstieg ist jetzt
[`docs/NOTES/RULES.md`](../../../NOTES/RULES.md).** `Arch&Coding.md`,
`Checklist.md` und `Zentral-Prinzipien.md` sind keine eigenständige
Regelquelle mehr; ihr Inhalt liegt in der einen kanonischen Sammlung, auf die
`RULES.md` verweist (`WKDBooks/Development/wkdbook-Lua/Checklists/` — Belege
unter `belege/`, Regeln unter `regeln/`, Einstieg über dessen `README.md` und
`WORKFLOW.md`). Wer künftig „was gilt hier eigentlich" fragt, liest dort, nicht
in einem Repo-ROADMAP-Ordner.

Zwei Dinge dazu, geprüft am 2026-08-30, damit der Verweis nicht mehr verspricht
als er hält:

- **Die Kopien in den Repos existieren weiter.** Unter
  `wkdbook-myplugins/<plugin>/ROADMAP/` liegen die 27 Dateien (neun Repos mal
  drei) unverändert. Sie sind ab jetzt historischer Stand, keine Quelle — der
  Abschnitt oben über die korrigierten `❌`-Zeilen beschreibt genau diese
  Dateien.
- **`RULES.md` nannte einen Pfad, den es auf dieser Maschine nicht gibt** —
  ein fest verdrahtetes `E:`, während die Sammlung unter `C:` liegt. Am
  2026-08-30 korrigiert, und zwar nicht durch einen anderen festen
  Laufwerksbuchstaben: der Pfad steht jetzt als `<repos>/WKDBooks/...` da, mit
  der Auflösungsregel daneben (`$REPOS_DIR`, sonst `E:`/`D:`/`C:`/`/repos` in
  dieser Reihenfolge) — dieselbe, die `plugins/personal/utils.lua` für die
  Plugin-Checkouts benutzt. Damit stimmt die Datei auf jeder der Maschinen.

---

## 3.2 `ROADMAP.md` heißt in diesen Repos vier verschiedene Dinge

Die Datei ist mal Aufgabenliste, mal Shipped-Log, mal Index über einen Ordner,
mal Prosa-Ausblick, der auf die eigentliche Warteschlange woanders verweist:

| Rolle | Repos |
|---|---|
| **Offene Aufgaben** | `open.nvim`, `mdview.nvim` |
| **Shipped-Log** (nur Erledigtes) | `replacer.nvim`, `reposcope.nvim`, `debugging.nvim`, `gopath.nvim` |
| **Index über `docs/ROADMAP/`** | `color_my_ascii`, `debugging`, `github_stats`, `insights`, `markdown`, `migrate`, `open`, `pdfport`, `filetree` |
| **Prosa-Ausblick, Queue liegt woanders** | `documentation.nvim`, `runtime-analysis.nvim` |
| **Leer** | 7 Repos, siehe 2.2 |

Das ist der Grund, warum diese Analyse nicht durch Überfliegen möglich war: in
`replacer.nvim` sieht eine 40-Zeilen-Liste nach Backlog aus und ist eine
Erledigt-Liste; in `open.nvim` sieht eine 2-Punkte-Liste nach Kleinigkeit aus
und ist die einzige echte offene Arbeit im Repo.

**Empfehlung, unabhängig davon, ob die Repo-Dateien bleiben oder gehen**: eine
Zeile ganz oben in jeder `ROADMAP.md`, die ihre Rolle nennt. Aufwand XS je
Repo.

---

## 3.3 Die Warteschlangen liegen zu dritt außerhalb der Roadmaps

Drei Dokumente tragen deutlich mehr offene Arbeit als sämtliche
`ROADMAP.md`-Dateien zusammen, und keines davon heißt so:

- `docmap-desktop/docs/PLAN.md` — 17 offene Punkte für drei Repos
- `lib.nvim/docs/ROADMAP/dependency-installer.md` — 4 offene Punkte, versteckt
  unter "Recommendation", "Open questions" und "Still worth doing"
- `images.nvim/docs/ROADMAP/CROSS-PLUGIN.md` — 5 offene Kreuzungen, verteilt
  über die Abschnitte "Medium" und "Open"

`PLAN.md` ist dabei kein Versehen, sondern eine bewusste, gut begründete
Zentralisierung (die Queue lag vorher in fünf Dateien und widersprach sich).
Die anderen beiden sind gewachsen.

---

## 3.4 Drei Punktpaare hängen aneinander und sollten zusammen gebaut werden

- **Sixel (M10) und XTVERSION-Detection**: Erkennung lohnt erst mit einem
  zweiten Backend, das zweite Backend braucht Erkennung. Ein Paket.
- **mdview L4 und die `color_my_ascii`-Fence-API**: die Exportfunktion, die
  L4 braucht, ist der erste sinnvolle Schritt der Fence-Highlighter-API — und
  sie steht schon (`highlight_export.runs_for_block`). Was fehlt, ist die
  Entscheidung, sie als öffentliche API zu führen, bevor mdview sie
  konsumiert. Zweimal gebaut wäre es zweimal falsch.
- ~~**`lsp.nvim` M6 und M7**~~ — **erledigt am 2026-08-30, zusammen gebaut,
  und die Kopplung hat gehalten.** `config/init.lua` hatte *eine* Merge-Ebene
  und hat jetzt vier. Der einmal geschriebene Mechanismus, der sonst zweimal
  fällig gewesen wäre: die Ebenen als Daten (`_layers`), Listen aus der Ebene
  gelesen, die sie geliefert hat, und jede Warnung mit der Ebene beschriftet,
  aus der der schlechte Wert kam. Notizen in
  [`PLUGIN_ROADMAPS_FINISHED.md`](./PLUGIN_ROADMAPS_FINISHED.md).

---

# Teil 4 — Empfohlene Reihenfolge

Nicht als Plan, sondern als Vorschlag mit Begründung. Erst das, was etwas
abschließt oder anderes freigibt; dann Nutzen vor Aufwand.

**Das erste Kriterium ist seit dem 2026-08-30 leer**: mit M17/M7 haelt kein
offener Punkt mehr einen anderen auf. Es bleibt Nutzen vor Aufwand.

1. **M12** (Flamegraphs als Bild) — neu zugeschnitten, weil es den
   Flamegraph, den der Eintrag als vorhanden unterstellt, gar nicht gibt;
   die Daten dafuer aber schon. Siehe „Naechster Schritt".
2. Danach nach Bedarf: **M10 + Detection** (`images` Sixel-Paket — mit dem
   dort genannten Vorbehalt), **M14** (`filetree.nvim`). Die Klasse der
   kleinen Punkte ist leer.

**M17/M11** (Endpoint-Inventar × Request-History) steht bewusst nicht in
dieser Reihenfolge: nachgesehen am 2026-08-31 deklariert **kein** Repo dieses
Oekosystems Routen, die der Endpoint-Scanner sieht — der Punkt haette heute
nichts zu kreuzen.

QW1, QW3, QW4, QW5, QW6, QW7, QW8, QW9, QW10, M1, M2, M3, M4a, M6, M7 und die
Call-Hierarchy-Resthälfte von M4 (`lsp.nvim`), M5 (nvim-config), M16
(`lib.nvim` + `pdfport.nvim`), M9 (Frecency ueber drei Repos) sowie M17/M7,
M17/M13, M17/M8, M17/M9, M17/M14, M17/M7c, M17/M10, M17/QW6, M11 (OCR, in
beiden Haelften) und M13 (die drei Bildoperationen) sind erledigt (siehe 1.0). Die Quick-Win-Klasse ist damit leer, und M16 war der letzte reine
S-Punkt, der sich delegieren ließ.

**Nicht angehen, mit Begründung**: L3 (`lsp` Signature-Help — die Roadmap
sagt selbst "vorerst nur beobachten"), BD4/BD5 (`mdview` externe Website und
PDF-Hover — beide teuer, beide klein im Nutzen, beide besser als "explizit
nicht geplant" festgeschrieben als offen gelassen).

**Zurückgestellt, mit Begründung und Wiedervorlage-Bedingung**: M4b (der
Picker-Adapter), M17/M12 (der Runtime-Reiter) und seit dem 2026-08-31 M17/M7b
(ein Scope ist kein Knoten). Alle drei stehen unter
[Zurueckgestellt](./PLUGIN_ROADMAPS_FINISHED.md#zurueckgestellt) statt hier —
sie sind keine offene Arbeit mehr, aber auch nicht gelöscht. M17/M12 kommt mit
dem ersten von M8 bis M11 zurück, M4b mit einem zweiten benutzten Picker, und
M17/M7b meldet sich selbst: sobald ein Baum mit echten Inline-Modulen kartiert
wird, sagt `file-holds-many-modules` es.

---

