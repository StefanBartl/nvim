# Bericht: Plugin-Kombinationen für casedesk/WKDBook-Tricentis (2026-09-30)

## Table of content

  - [Bezug zum Vorbericht](#bezug-zum-vorbericht)
  - [0. Klarstellung der Blickrichtung: WKDBook-Tricentis ← Plugins (nicht nur ← casedesk.nvim)](#0-klarstellung-der-blickrichtung-wkdbook-tricentis-plugins-nicht-nur-casedesknvim)
    - [Tier A — arbeitet HEUTE direkt auf WKDBook-Tricentis, ganz ohne casedesk.nvim](#tier-a-arbeitet-heute-direkt-auf-wkdbook-tricentis-ganz-ohne-casedesknvim)
    - [Tier B — braucht casedesk.nvim's semantische Schicht, um sinnvoll zu sein](#tier-b-braucht-casedesknvims-semantische-schicht-um-sinnvoll-zu-sein)
  - [1. Der größte Einzelfund: `ai.nvim` existiert jetzt](#1-der-grte-einzelfund-ainvim-existiert-jetzt)
  - [2. Kombinationen, die der Vorbericht (Einzelplugin-Fokus) nicht zeigt](#2-kombinationen-die-der-vorbericht-einzelplugin-fokus-nicht-zeigt)
    - [2.1 `images.nvim` (OCR) + `media.nvim` (Transkription) + casedesk — eine gemeinsame Textablage statt zwei getrennte](#21-imagesnvim-ocr-medianvim-transkription-casedesk-eine-gemeinsame-textablage-statt-zwei-getrennte)
    - [2.2 `hover.nvim` + `pdfport.nvim` + casedesk.nvim — dieselbe Chromium-Suche dreimal gebaut](#22-hovernvim-pdfportnvim-casedesknvim-dieselbe-chromium-suche-dreimal-gebaut)
    - [2.3 `rules.nvim` als Engine HINTER `doctor.lua` — offene Frage, keine Empfehlung](#23-rulesnvim-als-engine-hinter-doctorlua-offene-frage-keine-empfehlung)
  - [3. Was WKDBook-Tricentis selbst beisteuert (nicht: Plugin-Feature, sondern Rohmaterial)](#3-was-wkdbook-tricentis-selbst-beisteuert-nicht-plugin-feature-sondern-rohmaterial)
  - [4. Korrektur am Vorbericht](#4-korrektur-am-vorbericht)
  - [5. Aufwand/Nutzen — Quick Wins zuerst](#5-aufwandnutzen-quick-wins-zuerst)
  - [Referenzen](#referenzen)

---

## Bezug zum Vorbericht

Ergänzt [casedesk-cross-plugin-features-2026-09-29.md](./casedesk-cross-plugin-features-2026-09-29.md)
(gestern), nicht ersetzt. Der Vorbericht hat sauber vorgearbeitet: Tabelle A
dort (13 bereits integrierte Plugins) bleibt der Stand; Abschnitt C dort
(explizit geprüft & abgelehnt) bleibt größtenteils gültig — mit einer
Korrektur unten (§4).

**Was heute dazukommt, was gestern fehlte:**

1. Eine echte Case-Korpus-Analyse (45 Cases, siehe
   `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/casedesk.nvim/Backlog/FEATURES/case-corpus-analyse-2026-09-30.md`)
   als Faktenbasis statt Vermutung — jeder Vorschlag unten zitiert einen
   echten Case oder eine echte Zahl daraus, nicht "könnte nützlich sein".
2. Der eigentliche Auftrag heute ist **Kombinationen**, nicht einzelne
   Integrationen: WKDBook-Tricentis selbst liefert kein Feature (reiner
   Datenbestand), casedesk.nvim integriert bereits 13 Plugins einzeln — die
   offene Frage ist, wo **mehrere** Plugins zusammen etwas ergeben, das
   keins davon allein könnte, plus eine Aufwand/Nutzen-Einordnung mit
   klaren Quick Wins.

---

## 0. Klarstellung der Blickrichtung: WKDBook-Tricentis ← Plugins (nicht nur ← casedesk.nvim)

Nachtrag zur ursprünglichen Formulierung unten (§1-§4 waren als "was hilft
casedesk.nvim bei der Arbeit" gerahmt): WKDBook-Tricentis ist ein
git-getracktes Verzeichnis aus Markdown + Anhängen (Screenshots, Logs,
PDFs, `.docx`) — **die meisten der 37 anderen Plugins wissen nichts von
"Cases" oder `.case.json` und brauchen das auch nicht**, um direkt auf
diesem Repo etwas zu leisten. casedesk.nvim ist nur das EINE Plugin, das
speziell für dieses Repos Struktur gebaut ist (Case-Ordner, Sidecar,
SLA, Ähnlichkeitssuche); alles andere unten funktioniert bereits *heute*,
ohne dass casedesk.nvim überhaupt installiert sein müsste, einfach weil
WKDBook-Tricentis ein normales git+Markdown-Verzeichnis ist.

---

### Tier A — arbeitet HEUTE direkt auf WKDBook-Tricentis, ganz ohne casedesk.nvim

| Plugin | Was es auf diesem Repo konkret tut |
| --- | --- |
| `filetree.nvim` | Der `Cases/`-, `Workflow/`-, `MyDomains/`-, `Notes/`-, `Terminologie/`-Baum selbst — Navigation, egal ob casedesk je einen Case daraus kennt |
| `markdown.nvim` | TOC/Heading-Navigation auf JEDER `.md`-Datei — `Solution_TEMPLATE.md`, KB-Artikel, Wordings, nicht nur Case-Dateien |
| `mdview.nvim` | Browser-Vorschau einer beliebigen `.md`-Datei — z. B. den neuen `DEX_GPO_Preflight_Checklist.md` oder einen KB-Artikel vor dem Weitergeben gegenlesen |
| `cascade.nvim` | Listen-/Checkbox-Fortsetzung — trifft `Notes/Improvements/General.md`s nummerierte Liste genauso wie `Task.md` |
| `gitsuite.nvim` | Das ganze Repo IST ein Git-Klon — `:Git dashboard`/`blame`/`diff history` funktionieren auf jeder Datei, unabhängig von Cases; direkt nützlich für den Mehr-Maschinen-Sync, den `timeline.lua` schon als Artefaktquelle kennt |
| `spotlight.nvim` | Token-Highlighting in JEDEM Buffer — ein roh eingefügter Log/Activity-Stream, nicht nur ein von casedesk erzeugter |
| `hover.nvim` | Link-/Pfad-Vorschau auf jedem `[Text](./assets/...)`- oder `https://docs.tricentis.com/...`-Link im Repo |
| `images.nvim` | Jeder Screenshot im Repo, geöffnet/OCR'd — unabhängig davon, ob er in einem Case-`assets/`-Ordner oder anderswo liegt |
| `pdfport.nvim` | Jedes PDF im Repo lesbar im Buffer |
| `data.nvim` | `:JSON pretty` auf `.case.json`, aber genauso auf jeden anderen JSON-Blob, der irgendwo im Repo landet |
| `replacer.nvim` | Bulk-Edits über beliebige Dateien des Repos, nicht nur eines Case |
| `language.nvim`, `emojis.nvim` | Rechtschreibung/Emoji-Check auf jedem Buffer im Repo |
| `pickers.nvim` | Fuzzy-Datei-/Grep-Suche über das GANZE Repo |
| `diff.nvim` | Zwei beliebige Dateien/Revisionen des Repos nebeneinander |
| `open.nvim` | Jeden Link/Anhang im Repo mit dem passenden externen Handler öffnen |
| `cmdlog.nvim` | Zeichnet jedes `:`-Kommando auf, das in diesem Repo läuft — auch ohne casedesk |
| `insights.nvim` (nur `:Insights compress`) | Einen beliebigen Ordner des Repos zippen |
| `sessions.nvim` | Eine Session pro geöffnetem Ordner — funktioniert für jeden Unterordner, den man wiederholt aufmacht |

**Das ist die eigentliche Antwort auf "was können meine anderen Plugins
damit machen":** ein Großteil der wkd-Familie behandelt WKDBook-Tricentis
schon heute wie jedes andere ihrer Projekte — Navigation, Vorschau, Suche,
Diff, Rechtschreibung, Anhänge. casedesk.nvim kommt erst dazu, wenn eine
Frage *case-spezifisch* wird ("welcher Case ist das", "wie lange ist er
offen", "welcher andere Case ähnelt ihm").

---

### Tier B — braucht casedesk.nvim's semantische Schicht, um sinnvoll zu sein

`ai.nvim` (der Prompt braucht Case-Kontext: Titel, Activity Stream,
SLA-Status — ohne casedesk nur ein generischer Chat), `similar.lua`/
`solution.lua`-artige Ähnlichkeitssuche (ohne den Case-Begriff keine
sinnvolle Vergleichsmenge), alles SLA-bezogene (Fristen ergeben nur pro
Case Sinn). Das sind casedesk.nvim's eigene Module, keine anderen Plugins
— genau deshalb existiert casedesk überhaupt als eigenes Repo statt als
Sammlung generischer Tools.

---

## 1. Der größte Einzelfund: `ai.nvim` existiert jetzt

`REQUESTS.md`/`ROADMAP.md` (casedesk) gehen davon aus, dass die KI-Anbindung
an einem "noch nicht gebauten `ai.nvim`" hängt. **Das stimmt nicht mehr** —
`ai.nvim` steht (Beta), provider-agnostisch (`require("ai").ask()`/
`.stream()`), und ist bereits mit einem anderen bei casedesk aktiven Plugin
verkettet:

> `ai.nvim`s eigenes README: "Pairs well with **pdfport.nvim**: its
> `claude`/`ollama` extraction backends send their PDFs and page images
> through this plugin's `ask()`, rather than carrying a second hand-written
> curl/provider path of their own."

Das heißt konkret: **casedesk nutzt `pdfport.nvim` schon** (PDF-Anhänge im
Buffer, Vorbericht Tabelle A) — und `pdfport.nvim` selbst kann inzwischen,
über `ai.nvim`, KI-gestützte Extraktion aus genau diesen PDFs. Eine Kette
von drei Plugins, von denen zwei schon in casedesk laufen, ist ohne eigenes
Zutun ein Stück weiter gewachsen. Konkrete Folgefrage (nicht beantwortet,
nur aufgeworfen): nutzt casedesks aktuelle `pdfport`-Einbindung bereits den
AI-Extraktionspfad, oder nur den reinen Text-Extraktor? Wenn Letzteres:
kleiner Konfigurationsschritt, kein neuer Code.

**Was das für drei offene ROADMAP-Punkte bedeutet** (Details je Punkt in
der Case-Korpus-Analyse §5.2/§5.3):

| ROADMAP-Punkt | Vorher | Jetzt |
| --- | --- | --- |
| KI-Anbindung (`:Case ki` ohne Copy-Paste-Umweg) | blockiert auf "kein ai.nvim" | entblockt — Vorbericht §B.1 skizziert bereits die konkrete Umsetzung (`:Case ki --send`) |
| Grounded documentation references (KI-Zitatfinder) | "eigentliche KI-Aufgabe", ungebaut | technisch machbar, aber weiterhin groß — braucht zusätzlich die kuratierte Doku-Link-Bibliothek aus der Case-Korpus-Analyse §4 als Grundlage, sonst zitiert die KI aus Zufallstreffern |
| Log analysis (KI-gestützt) | "hängt an KI-Anbindung UND Anonymisierung" | beide Voraussetzungen jetzt erfüllt: `ai.nvim` existiert, `anonymize.lua` existiert bereits (casedesk) |

**Aufwand/Nutzen:** Anbindung selbst klein-mittel (ein Verb, `ki_import`s
Logik bleibt unverändert, siehe Vorbericht). Der eigentliche Hebel ist
**mittel bis groß**, weil er drei bisher blockierte ROADMAP-Punkte auf
einmal freigibt — aber die Reihenfolge zählt: Anonymisierung **vor**
jedem automatisierten Send ist Pflicht (Kundendaten in Activity Streams),
nicht nur Empfehlung — Vorbericht §B.1 nennt das bereits explizit.

---

## 2. Kombinationen, die der Vorbericht (Einzelplugin-Fokus) nicht zeigt

### 2.1 `images.nvim` (OCR) + `media.nvim` (Transkription) + casedesk — eine gemeinsame Textablage statt zwei getrennte

`media.nvim`s eigener Code-Kommentar (`lua/media/hub/kinds.lua`) ist
explizit: die Sidecar-Konvention für Transkripte (`talk.mp4` →
`talk.mp4.transcript.md`) ist **bewusst** an `casedesk.nvim`s eigene
OCR-Sidecar-Konvention (`.ocr.md`) angelehnt, nicht zufällig gleich. Beide
Plugins wurden mit dem Ziel gebaut, in dasselbe Muster zu passen.

**Was das ermöglicht, was der Vorbericht nur als Einzelfall sah** (§B.8,
"Standbild aus einem Screen-Recording", niedrige Priorität): `similar.lua`
und `solution.lua`s Volltextsuche laufen heute nur über
Markdown-Case-Dateien. Sidecar-Dateien mit demselben `.ocr.md`/
`.transcript.md`-Namensschema liegen als `.md` direkt im Case-Ordner (oder
`assets/`) und wären damit **automatisch** von `:Cases grep`/`similar.lua`
erfasst, ohne dass eine der beiden Suchen dafür etwas Neues lernen müsste —
Bildschirmaufnahme *und* Screenshot landen im selben durchsuchbaren Textpool.

**Aufwand:** klein (keine neue Suchlogik, nur sicherstellen, dass
`media.nvim`s Output tatsächlich im Case-`assets/`-Ordner landet, nicht in
einem projektfremden Cache). **Nutzen:** aktuell niedrig (Screen-Recordings
sind laut Case-Korpus die Ausnahme, kein einziger der 45 Fälle hatte eins),
aber die Fallhöhe ist null — der Mechanismus trägt sich, sobald der erste
Fall auftritt, ohne dass dann noch etwas gebaut werden muss.

---

### 2.2 `hover.nvim` + `pdfport.nvim` + casedesk.nvim — dieselbe Chromium-Suche dreimal gebaut

Codeverifiziert (nicht vermutet): `pdfport.nvim`s eigener Kommentar
(`lua/pdfport/health.lua:336`) sagt wörtlich, dass die "find a real Chromium
executable"-Logik **"für das identische Tool in hover.nvim/casedesk.nvim"**
bereits separat gemessen wurde — drei eigene Plugins mit derselben
Pfad-Heuristik (PATH-Suche reicht auf Windows nicht, feste Liste üblicher
Installationspfade nötig).

**Vorschlag:** eine Funktion in `lib.nvim` (die einzige harte Abhängigkeit
aller drei), die dieses eine Problem einmal löst; `hover.nvim`,
`pdfport.nvim` und `casedesk.nvim`s `export.lua`/`health.lua` rufen sie auf,
statt sie je einzeln zu pflegen. Kein neues Feature — aber jede der drei
Kopien ist eine eigene Stelle, an der ein neuer Chrome-Installationspfad
(Edge-Update, neue Windows-Version) nachgezogen werden muss, und das schon
dreimal statt einmal.

**Aufwand:** klein (reines Refactoring, Verhalten bleibt gleich, Tests
bereits vorhanden in allen drei Repos zum Gegenprüfen). **Nutzen:** klein,
aber die Art Nutzen, die sich über Jahre aufsummiert (drei Wartungsstellen
→ eine). Bester Quick Win dieses Berichts nach dem ai.nvim-Punkt.

---

### 2.3 `rules.nvim` als Engine HINTER `doctor.lua` — offene Frage, keine Empfehlung

Der Vorbericht lehnt `rules.nvim` ab mit der Begründung "Check-Engine für
Code-Regeln/Waivers — Plugin-Entwicklung, nicht Case-Arbeit". Das
`rules.nvim`-eigene README sagt aber allgemeiner: es liest "ein Regelwerk,
das du ihm zeigst", prüft mechanisch Checkbares gegen **"a repo"** (nicht
explizit "Code") und meldet den Rest als Worklist für menschliches Urteil —
genau die Form von `doctor.lua`s eigenem Muster (mechanisch prüfbare
Funde vs. Text-Erwähnungen mit niedrigerer Konfidenz, `doctor.lua`s
eigener Kommentar zu "routing-legacy") UND genau die Form der neuen
Vorschläge aus der Case-Korpus-Analyse (DEX/GPO-Preflight-Checkliste,
Dokumentationsrisiko-Scan, Scope-Heuristik — alle drei "mechanisch teils
prüfbar, teils Urteilssache").

**Nicht geprüft, deshalb keine Empfehlung, nur die Frage:** kann ein
`rules.nvim`-Ruleset gegen einen Case-**Ordner** (Markdown + `.case.json`)
statt gegen Code-Dateien laufen, oder ist die Engine strukturell an
Quellcode-Annahmen (Sprache, AST) gebunden? Falls Ersteres: `doctor.lua`s
sechs Prüfregeln plus die drei neuen Vorschläge wären als Ruleset
formulierbar statt als weiterer Lua-Code-Pfad in casedesk selbst — weniger
Code zu pflegen bei mehr Regeln. Falls Letzteres: Vorbericht bleibt korrekt,
diese Zeile ist erledigt. **Aufwand zum Klären:** eine Stunde,
`rules.nvim`-Doku lesen und einen Testlauf gegen einen Case-Ordner probieren.

---

## 3. Was WKDBook-Tricentis selbst beisteuert (nicht: Plugin-Feature, sondern Rohmaterial)

Der Auftrag stellt richtig fest: WKDBook-Tricentis liefert kein
Plugin-Feature. Was es liefert, ist **Testmaterial mit echten Kennzahlen**,
gegen das sich eine Plugin-Idee sofort validieren lässt statt sie zu raten
— das ist der eigentliche Wert der heutigen Case-Korpus-Analyse für DIESEN
Bericht:

- `pdfport.nvim`/`ai.nvim`s Extraktionspfad ließe sich an echten
  DEX_GPO_Report.html/gpresult.html-Anhängen testen (Cases 948965, 1004926,
  1226959, 1335876), statt an einer synthetischen Datei.
- `hover.nvim`s Link-Preview-Anspruch ("Cursor auf `[Log.txt](../assets/…)`")
  lässt sich an 1201484s echtem `assets/third/`-Ordner (5 Log-/Bild-Dateien)
  gegenprüfen — genau die Art Case, die laut Vorbericht §B.2 der Zielfall
  ist.
- `similar.lua`s TF-IDF-Suche (offene Frage laut ROADMAP: reicht das oder
  braucht es KI) hat mit dem GPO/DEX-Cluster (948965/1226959/1004926) jetzt
  einen echten, klar abgegrenzten Regressionstest: alle drei sollten
  einander als "ähnlich" vorschlagen — tun sie das heute schon (unterschiedliche
  Kundennamen, ähnliche Fachbegriffe), oder ist das der Fall, an dem TF-IDF
  ohne KI scheitert?

Kein neues Feature, aber ein sofort nutzbarer Prüfstand für die drei
größten offenen KI/Suche-Fragen im casedesk-Backlog.

---

## 4. Korrektur am Vorbericht

Abschnitt C dort ordnet `documentation.nvim` und `rules.nvim` pauschal als
"Plugin-Entwicklung, nicht Case-Arbeit" ein und schließt sie deshalb aus.
Das bleibt für `documentation.nvim` richtig (Modul-Karten für annotierten
Lua-Code — hat keinen Bezug zu Markdown-Case-Ordnern). Für `rules.nvim`
ist es nur richtig, WENN die Engine tatsächlich an Code gebunden ist —
siehe die offene Frage in §2.3 oben. Kein Widerspruch, nur eine Präzisierung:
der Vorbericht hatte recht mit der Vermutung, aber (nachvollziehbar,
gestern ohne Case-Korpus-Analyse) ohne die neuen doctor.lua-artigen
Vorschläge, die die Frage heute erst konkret genug machen, um sie zu
stellen.

---

## 5. Aufwand/Nutzen — Quick Wins zuerst

| # | Vorschlag | Aufwand | Nutzen | Typ |
| --- | --- | --- | --- | --- |
| 1 | `ai.nvim` hinter `:Case ki` (Vorbericht §B.1, hier nur aktualisiert: Blocker weg) | klein-mittel | groß (entblockt 3 ROADMAP-Punkte) | Einzelintegration |
| 2 | Chromium-Finder aus `hover.nvim`/`pdfport.nvim`/casedesk in `lib.nvim` bündeln | klein | klein, aber zusammengesetzt über Zeit | Kombination (Refactor) |
| 3 | `hover.nvim` installieren/ausprobieren (Vorbericht §B.2) | ~null | mittel | Einzelintegration |
| 4 | Media-/OCR-Sidecar-Konvention aktiv nutzen (§2.1) | klein | niedrig heute, null Fallhöhe | Kombination |
| 5 | `rules.nvim`-Frage klären (§2.3) | klein (1h) | unklar, aber billig zu klären | Kombination (offen) |
| 6 | `gitsuite.nvim` `:Git blame` in `:Case info` (Vorbericht §B.3) | klein-mittel | mittel (Mehr-Maschinen-Sync-Frage) | Einzelintegration |
| 7 | pdfport-AI-Extraktionspfad-Check (§1, Folgefrage) | ~null (nur nachsehen) | potenziell groß, wenn schon aktiv nutzbar | Kombination (Bestand prüfen) |

**Sofort ohne Code machbar (heute):** #3 und #7 — beides ist "ausprobieren/
nachsehen", kein Schreibaufwand.

---

## Referenzen

- Vorbericht: [casedesk-cross-plugin-features-2026-09-29.md](./casedesk-cross-plugin-features-2026-09-29.md)
- Case-Korpus-Analyse: `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/casedesk.nvim/Backlog/FEATURES/case-corpus-analyse-2026-09-30.md`
- casedesk ROADMAP: `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/casedesk.nvim/ROADMAP/ROADMAP.md`
- Quellcode-Belege: `ai.nvim/README.md:17-21`, `pdfport.nvim/lua/pdfport/health.lua:332-340`, `media.nvim/lua/media/hub/kinds.lua:22-29`, `data.nvim/docs/scope.md:74-79`, `rules.nvim/README.md:24-31`

---

