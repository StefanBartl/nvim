# hover.nvim — Handover

Stand: **2026-09-03**. **Eine** Datei: Stand, offene Punkte, Arbeitswissen und
Chronik. Vorher waren es zwei (`hover.nvim.md` und `hover.nvim-roadmap.md`),
und sie sagten dasselbe an zwei Stellen verschieden — die offenen Punkte
standen in beiden, die Zoom-Geschichte in beiden. Zusammengeführt am
2026-09-03; was zu einem *gebauten* Feature gehört, steht jetzt im Repo unter
`docs/FEATURES/` und hier nur noch als Zeile mit Commit.

Repo: <https://github.com/StefanBartl/hover.nvim> · lokal `E:/repos/hover.nvim`
Branch: **`main`**, alles gepusht.

**Die Regel, die diese Datei am Leben hält: jeder Punkt lebt an genau einer
Stelle.**

| Wo | Was | Adressat |
| --- | --- | --- |
| **diese Datei** | wo es steht, was offen ist, wie man daran arbeitet | ich, beim Wiedereinstieg |
| `hover.nvim/docs/ROADMAP.md` | was bewusst *nicht* gebaut ist. Führt keine Haken: gebaut heißt **gelöscht** | wer mitliest |
| `hover.nvim/docs/FEATURES/` | **warum** ein Feature so ist, wie es ist (englisch) | wer mitliest |

Wird etwas veröffentlichungsreif, *wandert* es ins Repo und hinterlässt hier
eine Zeile mit Commit — es wird nicht kopiert. Zwei Fassungen desselben
Punktes sind der Anfang jeder Drift, und in diesem Projekt sind daraus schon
fünf Funde geworden.

---

## Was offen ist — die Übersicht

Sieben Punkte. **Sechs brauchen dich**, einer nicht.

| # | Punkt | Wer | Was genau fehlt |
| --- | --- | --- | --- |
| [1](#1-demo-gif) | **Demo-GIF** | du | `REL-09`, der letzte offene 🟢 des Release-Gates. Aufnehmen kann ich nicht. |
| [2](#2-resize-von-hand-die-texthälfte) | **Resize von Hand: Texthälfte** | du | `:Hover resize` über einer *Textdatei*: kommen mehr **Zeilen** an, oder wächst nur der Rahmen? |
| [3](#3-zoom-von-hand-bild-und-pdf-seite) | **Zoom von Hand** | du | Ob der Ausschnitt **gezeichnet** ankommt. Seit 2026-09-03 in zwei Formen: Bild (Crop) und PDF-Seite (Neu-Rasterung). |
| [4](#4-office-kehrwoche) | **Office-Kehrwoche** | du | Eine Datei im Cache zurückdatieren, ein Office-Dokument hovern (`office.cache_days`, Default 7). |
| [5](#5-die-lua-modulwurzel-kollidiert) | **Lua-Modulwurzel** | du | Umbenennen oder lassen. Heute klein, wächst mit jedem Konsumenten. |
| [6](#6-ist-manual-der-bessere-default) | **`manual` als Default?** | du | Produktfrage: soll der Hover von sich aus aufgehen. |
| [7](#7-languagenvim) | **language.nvim** | du | Die Produktfrage *vor* der Integration. Seit `ac0a372` deutlich billiger zu beantworten. |
| [8](#8-was-ich-ohne-dich-tun-würde) | *(ohne dich)* | ich | `hover.scope` nach lib.nvim, wenn ein zweiter Konsument auftaucht. Sonst: nichts Dringendes. |

**Der scharfe PDF-Zoom ist seit 2026-09-03 gebaut** und aus dieser Liste
verschwunden — siehe [Chronik](#was-zuletzt-passiert-ist). Er war der letzte
Punkt, der weder Hand noch Entscheidung brauchte.

---

## Die offenen Punkte, einzeln

### 1. Demo-GIF

**Was fehlt.** `REL-09` aus dem Release-Gate, und der einzige 🟢, der noch
offen ist. Die README trägt eine ASCII-Nachbildung des Floats: sie erklärt die
Idee, aber nicht das Gefühl — und das Zeigenswerte ist, *wie wenig* der Hover
das Lesen unterbricht. Ein Standbild kann das nicht.

**Deine Aufgabe.** Aufnehmen. Ein paar Sekunden reichen: Cursor über einen
Pfad, Float geht auf, weiterlesen, Float geht zu. Am besten mit einer der
Klassen, die man nicht erwartet — Bild oder PDF-Seite.

**Was ich übernehme.** Alles um die Aufnahme herum: Einbau in die README an
der richtigen Stelle, Alt-Text, Größe, und das Abhaken von `REL-09` im Gate.
Ich kann dir auch ein Skript schreiben, das eine Beispiel-Sitzung immer gleich
aufsetzt, damit die Aufnahme nicht von der zufälligen Buffer-Lage abhängt.

### 2. Resize von Hand: die Texthälfte

**Was fehlt.** `:Hover resize` über einer *Textdatei*. Die Frage ist genau
die, für die das Feature umbenannt wurde: kommen **mehr Zeilen** an, oder
wächst nur der Rahmen um denselben Text?

**Warum keine Spec das beantwortet.** Eine Geometrie-Zusicherung liest die
Fenstergröße zurück — sie sagt, dass der Rahmen die richtige Größe hat, nicht
dass mehr Inhalt darin steht. Genau bei dieser Hälfte sagt sie am wenigsten.

**Stand.** Die **Bildhälfte ist gesehen** (2026-09-02, `1234bb2`): das Bild
folgt der Fläche, statt dass der Rahmen um ein stehendes Bild wächst.

**Deine Aufgabe.** Eine lange Textdatei hovern, `+` zweimal drücken, hinsehen,
ob unten Zeilen dazugekommen sind.

**Was ich übernehme.** Die Zeile in `docs/MANUAL-EVIDENCE.md` mit Datum und
Terminalgröße füllen — die Datei hat eigene Regeln über ihre Zeilen, und ein
Spec prüft sie.

### 3. Zoom von Hand: Bild und PDF-Seite

**Was fehlt.** Ob der vergrößerte Ausschnitt **gezeichnet** im Terminal
ankommt — und ob `h/j/k/l` sich beim Schwenken richtig anfühlen. Das Zweite
ist keine Frage, die man einer Spec stellen kann.

Seit 2026-09-03 sind es **zwei** Handprüfungen, weil es zwei Mechanismen sind:

- **Bild** (`<M-z>`): ein Ausschnitt wird mit ImageMagick geschnitten, ~258 ms
  je Schritt.
- **PDF-Seite** (`<M-z>`): die Seite wird bei höherem DPI **neu gerastert**,
  und nur das sichtbare Fenster, 207–752 ms je Schritt. Zusätzlich lohnt eine
  **gescannte** PDF: dort gibt es kein Mehr an Detail zu holen, das Bild
  darf also größer werden, ohne schärfer zu werden.

**Die erste Art, wie das scheitert, ist kein Fehler im Plugin.** `<M-z>` ist
ein Alt-Akkord, und ein Terminal, das ihn nicht sendet, sieht exakt so aus wie
ein Bild, das sich nicht zoomen lässt. `:nnoremap <M-z> :echo "da"<CR>` klärt
das in einem Tastendruck. Steht auch in `MANUAL-EVIDENCE.md`.

**Deine Aufgabe.** Hovern, zweimal `<M-z>`, hinsehen, schwenken.

**Was ich übernehme (und schon getan habe).** Die Arithmetik ist spec-geprüft,
und der ganze Pfad ist außerhalb der Suite gegen ein echtes Dokument gelaufen:
`scripts/pdfzoom_probe.lua` druckt je Stufe Zeit, Pixelgröße, Hash und **zwei**
Schärfezahlen. Der Lauf vom 2026-09-03 steht in `MANUAL-EVIDENCE.md`. Was die
Sonde nicht kann, ist hinsehen.

### 4. Office-Kehrwoche

**Was fehlt.** Der altersbasierte Sweep des Office-Caches (`office.cache_days`,
Default 7). Eine Datei im Cache zurückdatieren, irgendein Office-Dokument
hovern, und sehen, dass die alte Konvertierung verschwindet.

**Stand.** Der Rest des Office-Pfads ist **zweimal** durchgespielt
(2026-09-02): Konvertierung, Badge, und der Cache, der die Sitzung überlebt —
Neustart, kein zweiter LibreOffice-Start.

**Deine Aufgabe.** Zurückdatieren und hovern. Zwei Befehle.

**Was ich übernehme.** Ich kann dir den Zurückdatier-Befehl für genau deinen
Cache-Pfad fertig hinschreiben, samt der Datei, die man dafür nimmt.

### 5. Die Lua-Modulwurzel kollidiert

**Der Defekt.** `lewis6991/hover.nvim` existiert und ist verbreitet. Die
**Repo**-Namen kollidieren nicht, die **Modulwurzel schon**: beide liefern
`lua/hover/`, und wer beide installiert, bekommt still das, was früher auf der
`runtimepath` liegt. Für ein öffentliches Plugin ist das ein echter Defekt,
kein Schönheitsfehler.

Im Repo steht davon **nichts** — der Einspruch stand einmal in README und
Vimdoc und ist auf deine Anweisung dort entfernt. Er lebt hier weiter, damit
er nicht verlorengeht.

**Was ein Umbenennen kostet**, heute: Verzeichnis `lua/hover/` → `lua/<neu>/`,
ein `sed` über die Require-Pfade, der `Hover.`-Typnamensraum, `:Hover` →
`:<Neu>`, `vim.g.hover_disable`, die drei Highlight-Gruppen, markdown.nvims
fünf Require-Zeilen, die Config-Spec. Kandidaten waren `pathhover.nvim` und
`hoverport.nvim` (Anschluss an `pdfport`).

**Meine Einschätzung:** entscheiden, solange es **sieben** Konsumenten sind.
Jeder weitere Registry-Beitragende macht es teurer, die Kosten sind einmalig,
und der Defekt bleibt.

**Deine Aufgabe.** Die Entscheidung, und der Name.

**Was ich übernehme.** Die Umbenennung selbst — sie ist mechanisch, und die
Doku-Spec sagt mir, welches Dokument ich vergessen habe. Ich würde sie in
einem Commit machen, mit einem Lauf der Suite und einem LuaLS-Scan davor und
danach.

### 6. Ist `manual` der bessere Default?

**Die Frage.** Die Config läuft auf `auto` — der Hover geht von selbst auf.
Der Griff wäre `:Hover mode manual` plus ein `keymaps.show`-Key. Wenn *das*
sich als das Richtige erweist, gehört es in die Config-Spec statt in eine
Sitzung.

**Zwei Dinge haben die Frage inzwischen verschoben.** `:Hover why` sagt, warum
ein Float **nicht** aufging, und das Positions-Gate hat die Hälfte des
Rauschens ohnehin entfernt. Gut möglich, dass die Frage sich erledigt hat.

**Deine Aufgabe.** Das ist eine Beobachtung über Wochen, keine Messung über
Minuten: eine Weile auf `manual` arbeiten und merken, ob dir etwas fehlt.

**Was ich übernehme.** Den Umbau in die Config, wenn die Antwort steht — und
vorher, falls du willst, eine Sitzung lang mitzählen, wie oft ein Float
aufgeht, ohne gelesen zu werden. Das wäre eine Messung statt eines Gefühls,
aber sie kostet dich einen Tag mit einem Zähler im Hintergrund.

### 7. language.nvim

**Die Produktfrage vor der Integration.** Soll ein Druck auf `:Hover show`
mitten in Prosa immer ein Wörterbuch aufmachen? Der Mechanismus
(`on_request`) existiert seit `731bbe2`; was fehlt, ist eine Regel dafür, wann
ein Wort nachschlagenswert ist — und die gehört nach language.nvim, nicht
hierher.

**Warum das nicht „klein" ist.** Der Mechanismus überträgt sich, die
Sparsamkeit nicht. Bei sandbox.nvim entscheidet eine billige Textprüfung *vor*
jedem Prozessstart, ob überhaupt gefragt wird: `init.lua:42` fällt in unter
1 ms durch, weil die letzte Namenskomponente eine Endung trägt. Bei einem
Wort-Nachschlag ist **jedes Wort ein Wort**; es gibt keine solche Vorprüfung,
also ist auch unter `force` jede Position ein Treffer.

**Seit `ac0a372` ist der Einsatz kleiner.** Vorher gewann der erste
registrierte Beitrag, und ein Wörterbuch hätte unter `:Hover show` jeden
anderen Position-Beitrag verdeckt. Jetzt wird geblättert (`<M-n>`), es darf
hinten stehen und verdeckt nichts.

**Deine Aufgabe.** Die Frage: willst du das Wörterbuch im Hover haben.

**Was ich übernehme.** Die Verdrahtung, sobald die Antwort ja ist — sie ist
dieselbe Form wie insights.nvim und sandbox.nvim, und beide sind vorgemacht.

### 8. Was ich ohne dich tun würde

Wenig, und nichts Dringendes.

- **`hover.scope` als lib.nvim-Helfer** (`REL-31` fragt danach). „Ist der
  Cursor in ausführbarem Code?" ist generisch — aber es hat *einen*
  Implementierer, und die Regel, die den Hover aus lib.nvim herausgeschickt
  hat, schneidet in beide Richtungen: ein Helfer mit einem Konsumenten ist ein
  Helfer, den ein Konsument geformt hat. Wieder aufgreifen, wenn etwas
  Zweites dieselbe Frage stellt; `open.nvim` wäre der natürliche zweite.
- **Turnusmäßig:** nach jeder Code-Änderung ein LuaLS-Scan (die Regel unten),
  und ein Blick auf die CI der Repos, in die ich committe.

---

## Wo es steht

**Fertig und öffentlich.** Die Extraktion aus lib.nvim ist abgeschlossen,
`lua/lib/nvim/hover/` dort gelöscht (`5450dd4`). CI grün auf ubuntu-latest
*und* windows-latest. Beide Gates durch: `RELEASE.md` 29 von 32 mit drei
begründeten Ausnahmen, `REVIEW.md` grün.

**Woher es kommt**, weil die Entscheidung sonst nirgends mehr steht: der
Hover war ein Modul in lib.nvim und traf die dortige Ausschlussregel („kein
Feature mit eigener UI, eigenem Zustand und eigener Historie") **dreifach** —
vier `nvim_open_win`, global geliehene Keymaps und eigene Highlight-Gruppen;
LRU, Session-Schalter und On-Disk-Cache; Scroll-Offset und Fetch-Cache. Dazu
3 949 LOC = 8,3 % von lib.nvim, drittgrößtes Modul, in vier Tagen entstanden,
und das einzige, das gleichzeitig Fenster öffnet, Autocmds installiert *und*
Routen mitbringt. Der Präzedenzfall war zweimal gelaufen (`lib.nvim.docmap` →
documentation.nvim, `lib.nvim.telemetry` → runtime-analysis.nvim). Kosten des
Umzugs: neun Module generischer Infrastruktur mit null lib.nvim-Kopplung.

**Gemessen nach `7fdfc09`:**

| Prüfung | Ergebnis |
| --- | --- |
| Specs | **266 grün**, 0 Fehler, **0 pending** (mit `IMAGES_NVIM_DIR`; ohne sie überspringt der Crop-Check) (bare_git 10, bare_path 48, config 17, docs 13, **registry 74**, resize 19, scope 26, switches 30, **zoom 29**) |
| `stylua --check` / `luacheck` | sauber (34 Dateien) |
| LuaLS (`scan.sh`, echte injizierte Library) | **0 Befunde**, Pass `pdfzoom-post`, `+0` gegen `next-post2` |
| CI | grün auf beiden Runnern |
| Helptags | 36 |

**Die 0 pending sind die Zahl, auf die zu achten ist.** Sie stand lange nicht
in dieser Tabelle, und genau deshalb konnte ein Spec monatelang überspringen,
ohne dass es jemandem auffiel.

**Was es kann**, in einem Satz je Klasse: Datei- und Verzeichnisvorschauen,
Bilder und PDF-Seiten gezeichnet, Office-Dokumente über LibreOffice (opt-in),
URLs mit optionalem Abruf, Bare Paths mit Zeilen und Ranges
(`init.lua:42`, `file.lua:10-20`), Git-Objekte auf Nachfrage,
Position-Previews fremder Plugins — **mehrere für dieselbe Stelle, zum
Durchblättern** (`<M-n>`, `:Hover next`) —, `:Hover why`, `:Hover pin`, Resize
für **jeden** Hover (`+`/`-` über Bildern, Rad und `:Hover resize` überall),
**echter Zoom** für Bilder *und* PDF-Seiten (`<M-z>` / `<M-Z>` / `<M-R>`,
`:Hover zoom`, `h/j/k/l` zum Schwenken), ein Schalter-Chooser über lib.nvims
UI-Kit — und seit `c374d5e` ein eigener Hover **ohne Plugin drumherum**
(`setup({ contribute })`).

Einzelheiten im Repo: [README](https://github.com/StefanBartl/hover.nvim),
`docs/BINDINGS.md`, `docs/FEATURES/`.

## Wer beiträgt

**Sieben über die Registry** (das Plugin nennt keinen davon beim Namen):
markdown.nvim, migrate.nvim, reposcope.nvim, documentation.nvim,
spotlight.nvim, sandbox.nvim, insights.nvim.

**Vier namentlich als weiche Abhängigkeit** (hover `pcall`t sie selbst):
gopath.nvim, open.nvim, images.nvim, pdfport.nvim.

Wer was beisteuert und was ohne ihn ausfällt: `docs/INTEGRATIONS.md` im Repo.
Alle sind optional, keiner erforderlich.

---

## Was beim Weiterarbeiten zu wissen ist

Der wertvollste Teil dieser Datei. Jede Regel hier hat mindestens einmal etwas
gefangen.

### Regelwerk und Konventionen

- **Regelwerk:** `WKDBooks/Development/wkdbook-Lua/Checklists/`, für dieses
  Repo `gates/NEW_PROJECT.md` (einmal durch, `NEW-01`…`NEW-46`),
  `regeln/LUA_NVIM.md` beim Schreiben.
- **Commits ohne KI-Co-Author** — steht so in `NEW_PROJECT.md` und ist hier so
  gehalten.
- **Keine Lizenzdatei** (`NEW-06`, `REL-28`) — bewusst keine angelegt, auch
  wenn pdfport/gopath welche haben.
- **stylua-Stil:** `collapse_simple_statement = "Never"`, wie lib.nvim. Nicht
  wie markdown.nvim (`"Always"`) — der übernommene Code ist in lib.nvims Stil
  geschrieben, und eine Extraktion ist der falsche Moment, den ganzen
  Quelltext umzuformatieren.
- **In dieser Config nur benannte Pfade stagen**, nie `git add -A`. Am
  2026-09-03 hat ein `git add -A` hier drei fremde, schon liegende Änderungen
  in einen Hover-Commit gezogen und mitgepusht. Nichts ging verloren, aber die
  Commit-Message beschrieb nichts davon. Der Haupt-Checkout ist ein **lebender
  Arbeitsbaum**; die Plugin-Repos sind Worktrees je Sitzung und haben das
  Problem nicht.
- **Nach einem Commit in ein fremdes Repo dessen CI ansehen** (`gh run list`).
  Zweimal am 2026-09-03 bezahlt: documentation.nvims `map`-Gate war seit dem
  31. August rot, als zwei Commits hineinliefen (behoben, `c26da89`), und
  pdfport.nvim hat eine **stylua-CI ohne `.stylua.toml`** — lokal findet
  `stylua --check` nichts zu tun, die Action prüft mit ihren eigenen Defaults
  und war rot (behoben, `697a5d7`). Das Gate ist, was CI fährt, nicht was der
  Arbeitsbaum nachstellen kann.

### Messen und Prüfen

- **Vor dem Bauen messen.** Vier Messungen in diesem Repo haben der Intuition
  widersprochen, die sie prüfen sollten; zweimal war die naheliegende Lösung
  die falsche, und einmal — beim PDF-Zoom — hat die Messung ein Feature
  freigegeben, das anderthalb Jahre Begründung lang als „zu teuer" galt. Die
  Zahlen stehen in den Modulköpfen von `hover.scope` und `hover.bare_path`,
  nicht in Commit-Messages, damit sie beim Ändern des Codes gelesen werden.
- **Die Messung muss die Operation messen, die das Feature ausführt.** Der
  PDF-Zoom stand mit „3,3 s je Schritt" auf der Roadmap. Das war die Zeit für
  eine **ganze Seite** bei höherem DPI — und ein Zoom zeigt keine ganze Seite.
  Dasselbe Dokument, nur das sichtbare Fenster: 118–140 ms, auf jeder Stufe.
  Die Zahl war richtig gemessen und über das Falsche.
- **Sabotage-Test jede neue Spec** — die Zusicherung zurücknehmen, bestätigen,
  dass sie fällt. Zuletzt: ohne den Skalierungsfaktor fragt Stufe 1 nach
  1072×1398 statt 1608×2097, und genau eine Zusicherung fällt.
- **Den LuaLS-Scan aus dem Config-Repo fahren**, nie auf einem Worktree
  (doppelte Library-Injektion → ~100 unechte `duplicate-doc-field`), und
  **auch nach dem Schreiben einer Spec** — `TESTS/` wird mitgescannt, und eine
  grüne Suite plus grüne CI hat dort schon Befunde versteckt (zweimal am
  2026-09-02: `zoom-post` +2, `resize-post` +7).

  ```bash
  cd C:/Users/bartl/AppData/Local/nvim
  REPOS_DIR=E:/repos bash scripts/luals-scan/scan.sh <pass> hover.nvim
  python scripts/luals-scan/compare.py <voriger-pass> <pass>
  ```

  Die nackte `lua-language-server --check`-Zahl ist wertlos (`LLS-01`).
  **Der Scan ist nicht deterministisch:** am 2026-09-02 meldete ein Lauf einen
  `cast-local-type` auf Quelltext, den der Commit nicht angefasst hatte, und
  ein zweiter Lauf auf identischem Baum null. Ein einzelner `+1` ist keine
  Regression — erst wiederholen, dann suchen. Ein Lauf kostet etwa eine
  Minute je Workspace. Letzter Pass: `pdfzoom-post`.
- **Die Doku ist spec-geprüft.** `TESTS/docs_spec.lua` liest README, Vimdoc
  und `docs/**/*.md` gegen die Quelle: Schalternamen, alle `:Hover`-Routen in
  beide Richtungen, Zieltypen, Augroups und Highlight-Gruppen, die
  Tastenlisten aus `DEFAULTS`, und die Regeln, die `MANUAL-EVIDENCE.md` über
  sich selbst aufstellt — **einschließlich der Zahlen, die ein Dokument über
  sich selbst behauptet.** Zuletzt am 2026-09-03: zwei Dokumente sagten
  „sieben Dinge, die keine CI prüfen kann", während die achte gerade
  dazugekommen war. Verlassen kann man sich darauf für alles außer den
  Integrations-Tabellen, die fremde Plugins beschreiben.

### Fallen, die hier zugeschlagen haben

- **Tests laufen so:**

  ```bash
  IMAGES_NVIM_DIR=E:/repos/images.nvim \
  LIB_NVIM_DIR=E:/repos/lib.nvim \
  PLENARY_DIR=C:/Users/bartl/AppData/Local/nvim-data/lazy/plenary.nvim \
  bash scripts/test.sh
  ```

  **`IMAGES_NVIM_DIR` ist aus einem Worktree Pflicht**, nicht Zierde.
  `minimal_init` findet images.nvim über die Variable, ein `.deps/`-Checkout
  oder das *Nachbarverzeichnis* — und aus `.claude/worktrees/<name>/` ist der
  Nachbar der Worktree-Pool, nicht `E:/repos`. Ohne die Variable überspringt
  der Crop-Spec, und zwar als „Success". Dieselbe Form wie die LuaLS-Regel:
  der Worktree ist keine wahrheitsgetreue Umgebung.
- **Eine Tabelle nie als Literal mit einem optionalen ersten Element bauen.**
  `{ vim.env.FOO, "a", "b" }` ist bei ungesetztem `FOO` ein Loch an Index 1:
  `#t` meldet 3, `ipairs` läuft **null** mal. **Dreimal aufgetreten** — in
  `minimal_init` (wo es drei Defekte hinter einem plausiblen Skip versteckte,
  `ade6c1f`), im Kommentar, den derselbe Commit hinterließ, und in
  `onrequest_probe.lua`, das die kaputte Form behielt (`74f4eb1`). Seither
  gibt es `scripts/probe_deps.lua` und keine Kopie mehr.
- **In einer Spec ist `assert` *luassert*, nicht Lua.** Es gibt mehr als einen
  Wert zurück, also schickt `nvim_win_get_position(assert(float.win()))` ein
  zweites Argument, das die API ablehnt — im `pcall` sieht das aus wie ein
  fehlgeschlagener Test, nicht wie ein Arity-Fehler. Immer erst an ein `local`
  binden.
- **`pending` ist ein Wächter statt eines Merkpostens** (`e5fca52`). Vorher
  stand hier „darauf achten" — und darauf achten hat nicht funktioniert.
  Gemessen am 2026-09-03: `pending()` auf describe-Ebene wird **nirgends**
  gezählt (die Success-Zahl wird nur kleiner); `pending()` **innerhalb** eines
  `it` — die Form, die ein abgesicherter Spec hat — druckt eine Pending-Zeile
  **und zählt den `it` als Success**. Der Exit-Code bleibt in beiden Fällen 0.
  `scripts/test.sh` benennt sie jetzt nach dem Lauf und bricht ab, außer
  `HOVER_ALLOW_PENDING=1` ist gesetzt. Die CI setzt es — dort ist der
  Crop-Check zu Recht pending —, druckt die Liste aber trotzdem, damit ein
  *neuer* Fall sichtbar ist, wo er nicht fatal sein kann.
- **Beide Laufarten sind dieselbe Umgebung, und waren es nicht.**
  `PlenaryBustedFile` landet in `test_harness.test_file`, das den Runner
  **ohne Optionen** aufruft — das Kind bekommt `--noplugin` und kein `-u`,
  also nicht `scripts/minimal_init.lua`. Ein Einzeldatei-Lauf hatte damit
  andere Plugins auf dem rtp als der Suite-Lauf. `scripts/test.sh` fährt eine
  Einzeldatei seit `ade6c1f` über `plenary.busted.run` im schon aufgesetzten
  Prozess.
- **Git-Bash-Falle:** headless nvim mit einem `/tmp/...`-Pfad **hängt still**,
  statt zu scheitern. Windows-Pfade verwenden. (Steht auch in
  `scripts/luals-scan/scan.sh`.)
- **Ein voller Config-Start headless hängt still.** Auch mit Windows-Pfaden.
  Isoliert prüfen (`-u NONE` plus `set rtp+=`) oder interaktiv.
- **Heredocs mit viel Inhalt sind hier eine Falle.** Ein `<<'PY'`-Block hat am
  2026-09-02 ein echtes **NUL-Byte** in `preview/media.lua` geschrieben (genau
  der Fehler, den die Extraktion aus lib.nvim einmal beseitigt hatte), und ein
  zweiter ist ab ~140 Zeilen an der Terminator-Erkennung gescheitert. Größere
  Patches als Datei schreiben und mit `python <datei>` laufen lassen; danach
  `open(f,'rb').read().count(bytes([0]))` prüfen. **Und: ein `replace` ohne
  `assert` ist kein Patch, sondern eine Hoffnung** — am 2026-09-03 sind drei
  von sechs Ersetzungen still nicht gegriffen, und die Datei sah danach
  plausibel aus.
- **`convert` auf PATH ist Windows' eigenes `convert.exe`**, nicht
  ImageMagick. Immer `magick` aufrufen.
- **Mauseingaben lassen sich headless nicht treiben.** `nvim_input_mouse`
  feuert ohne angehängtes UI **null** Mappings; `feedkeys` mit demselben
  Termcode feuert eines. Was ein echtes Rad angeht, ist deshalb Handprüfung.
- **luals-scan liegt in der Config**, nicht im Plugin-Repo:
  `nvim/scripts/luals-scan/`.

---

## Wo was steht

| Frage | Datei |
| --- | --- |
| Was tut es, wie konfiguriere ich es | `README.md` im Repo |
| Welche Taste, welches Kommando, welcher Autocmd | `docs/BINDINGS.md` |
| **Warum** ist das so gebaut | `docs/FEATURES/` — QUIET, BARE-PATHS, CONTRIBUTIONS, RESIZE, **ZOOM** |
| Wer ist wie angebunden, was fällt ohne ihn aus | `docs/INTEGRATIONS.md` |
| Was ist bewusst *nicht* gebaut | `docs/ROADMAP.md` (an Mitlesende) |
| Was kann keine CI prüfen | `docs/MANUAL-EVIDENCE.md` |
| Welche Tasten/Kommandos/Autocmds in **dieser** Config | `docs/NOTES/PersonelPlugins/BINDINGS/{Keymaps,Usercmds,Autocmds}/hover.nvim.md` |
| Was ist passiert, was ist offen, wie arbeite ich daran | **diese Datei** |

---

## Geprüft und *nicht* aufgenommen

Damit es nicht als gute Idee wiederkommt.

- **Text-*Zoom*** — die Ablehnung war richtig, hatte aber die falsche
  Schlussfolgerung. „Die Schriftgröße gehört dem Terminal-Emulator, ein
  größeres Float zeigt *mehr* statt *größer*, das wäre ein anderes Feature und
  müsste anders heißen" — genau das ist am 2026-09-02 passiert: es heißt
  `resize`, und dann gilt es auch für Text. Was dort stand, war kein Argument
  gegen das Feature, sondern gegen seinen Namen.
- **Ein *echter* Zoom für Text.** Bleibt abgelehnt und ist nicht dasselbe:
  einen Ausschnitt vergrößern kann Neovim für Text nicht, weil die Zellgröße
  dem Terminal gehört. Für Bilder ist er seit `9fba190` gebaut, für PDF-Seiten
  seit `7fdfc09`.
- **`contribute` auch für Plugins.** Alle Nutzerbeiträge teilen sich den Namen
  `"user"`; zwei Aufrufer löschen einander still. Ein Plugin hat `register`
  mit eigenem Namen, und das ist kein Umweg, sondern der Punkt.
- **Ein zweiter Cache für Office-Konvertierungen.** Der bestehende überlebt
  seit `bba2064` die Sitzung. Mehr wäre eine Lösung ohne gemessenes Problem.
- **Ein Health-Check, der die Testsuite fährt.** Er würde über die Maschine
  berichten, auf der er zufällig läuft, statt über die Installation. Steht als
  abgelehnt in der Repo-Roadmap und bleibt dort.
- **Ein Memo für Position-Previews** — gemessen am 2026-09-02, und die Antwort
  war nein. Dabei fiel ein Auftrag für documentation.nvim heraus, der inzwischen
  erledigt ist (`bdfbc9f`).
- **Ein „2 von 3"-Zähler beim Durchblättern.** Wer antworten *würde*, wüsste
  man nur, indem man jeden Beitrag bei jedem Hover aufruft — also genau die
  Kosten, die `on_request` vermeidet. Die Taste hängt an der Zahl der
  *Registrierungen*, das Blättern ist das Fragen.

---

## Was zuletzt passiert ist

Umgekehrt chronologisch, nur was den Stand ändert. Die Begründungen stehen in
den Commits und unter `docs/FEATURES/`.

- `7fdfc09` — **der scharfe PDF-Zoom, und die Messung hat das Feature
  freigegeben.** Eine Seite wurde bisher nur skaliert; jetzt wird sie bei
  höherem DPI **neu gerastert** — und zwar nur das sichtbare Fenster. Der
  Roadmap-Eintrag stand mit „3,3 s je Schritt" als Entscheidung statt als
  Ticket, aber das war die Zeit für eine *ganze* Seite: die ganze Seite wächst
  mit dem Quadrat des DPI (176 ms bei 216, 2 653 ms bei 1 094), das Fenster
  nicht (118–140 ms auf jeder Stufe, bis 5 536 DPI). Durch das Plugin gemessen
  207–752 ms je Schritt — dieselbe Größenordnung wie ein Bild-Crop.

  **Schärfer, nicht nur größer**, und das ist gemessen: dasselbe Fenster, neu
  gerastert gegen aus der Basisseite hochskaliert, Laplace-Standardabweichung
  0,81/0,88/0,66/0,22/0,16 gegen 0,37/0,23/0,10/0,03/0,01 über die Stufen 1–5.
  Zeilenweise lesen, nicht spaltenweise: *innerhalb* einer Zeile das Zwei- bis
  Fünfzehnfache an Kantenenergie, *entlang* einer Spalte fallen beide, weil ein
  Ausschnitt mit zwei Buchstaben überwiegend weiß ist.

  Dafür kam `opts.crop` in pdfport (`95d27ab`) — so wie `images.convert.crop`
  für die Bildhälfte entstand. Erkannt wird es über `can_render_page_crop`,
  nicht versucht: ein älteres pdfport ignoriert ein unbekanntes Feld still,
  und die Seite käme bei höherem DPI im selben Float an — eine Taste, die
  sichtbar nichts tut. Die Decke ist ein DPI (2400, ~11×, fünf Stufen) statt
  einer Pixelzahl: eine Vektorseite geht nie aus.
- `74f4eb1` — **dieselbe `nil`-Loch-Falle zum dritten Mal**, diesmal in
  `onrequest_probe.lua`: die Kandidatenliste als Literal mit einer ungesetzten
  Umgebungsvariable an Index 1, `ipairs` hält sofort an, weder `.deps/` noch
  der Nachbarpfad werden je probiert. Die Sonde meldet das Plugin als fehlend,
  während es nebenan liegt. Jetzt `scripts/probe_deps.lua`, eine Quelle.
- `c26da89` (documentation.nvim) — **das `map`-Gate ist zu, und die Ursache war
  keine der vier Vermutungen.** `--check` vergleicht Bytes, und
  `core/external_repos.lua` prüft die *Form* jedes externen Links gegen den
  Checkout, den `.docmap.json` unter `../lib.nvim` nennt. Auf einem Runner
  liegt dort nichts, also fallen 20 von 23 Links auf die flache Form zurück —
  exakt 100 Bytes Unterschied, alle in `tag_links`. Das Artefakt hing daran,
  was *neben* dem Baum liegt. Erste grüne CI dort seit dem 30. August.
- `a93dcc3` (insights.nvim) und `693829c` (documentation.nvim) — die beiden
  Gegenseiten von `ac0a372` sind dokumentiert. insights' Verdrahtung war von
  nirgends erreichbar (die einzige Fähigkeit ohne Kommando fehlte in der
  Capability-Tabelle, `configuration.md` nennt sich „full `setup()` reference"
  und führte `hover` nicht, der `BufWritePost` stand nicht in `BINDINGS.md`);
  documentation.nvims Seite sagte nirgends, dass für denselben dotted name ein
  **zweites** Plugin antwortet.
- `1badc86` — **der erste LuaLS-Lauf über `ac0a372` fand vier Befunde**, alle
  aus dieser einen Änderung. `_open.col` und `_open.position_nth` sind das,
  womit das Blättern dieselbe Stelle erneut fragt, und beide standen nicht in
  `Hover.Open` — drei Befunde für zwei Felder. Der vierte war ein Spec-Helfer
  ohne die Hausform. Ein Scan pro Codeänderung, nicht pro Woche.
- `913f2db` — insights.nvim ist verdrahtet, also ist sein Roadmap-Eintrag im
  Repo **gelöscht** statt abgehakt. Der Zähler („fünf der Kandidaten sind
  gebaut") ist dabei ganz verschwunden statt hochgezählt: er war zweimal
  falsch, und die Liste daneben trägt dieselbe Information.
- `ac0a372` — **mehrere Plugins dürfen für dieselbe Stelle antworten**, und
  jetzt sind alle lesbar: `<M-n>` / `:Hover next` blättert weiter und hinter
  der letzten wieder nach vorn. Vorher gab `position_at` die *erste* Antwort
  zurück, und wer zweiter registriert war, war unsichtbar — entschieden von
  der Ladereihenfolge. Verschmelzen wäre der andere Weg gewesen und ist
  schlechter: `Hover.Content` ist auf *eine* Antwort zugeschnitten, und ein
  Bild lässt sich mit Text gar nicht verschmelzen.
- `e5aef5c` — die Zoom-Zeile in `MANUAL-EVIDENCE.md` nannte nur die Route.
  Gedrückt wird `<M-z>`, und die erste Art, wie das scheitert, ist genau die,
  für die diese Datei da ist: ein Alt-Akkord, den das Terminal nicht sendet,
  sieht aus wie ein Bild, das sich nicht zoomen lässt.
- `efafb82` — **der Zoom bekommt Tasten** (`<M-z>` hinein, `<M-Z>` heraus,
  `<M-R>` zurück), und **`:Hover pan` heißt `:Hover nav`**. Umbenannt statt
  aliasiert — ein Alias für eine umbenannte Operation ist genau das, was
  `bd72836` erzeugt hat. `zoom_keys` musste dabei der Legacy-Schreibweise von
  `resize_keys` wieder abgenommen werden, und die alte Form wird **gemeldet
  und ignoriert** statt still gefaltet: still gefaltet hätte eine alte Config
  eine 258-ms-Operation auf eine Taste gelegt, die jemand für einen kostenlosen
  Resize-Schritt gewählt hat.
- `ade6c1f` — der Crop-Spec lief nie: ein `nil`-Loch in `minimal_init`, zwei
  verschiedene Umgebungen zwischen Einzeldatei- und Directory-Lauf, und eine
  Fixture ohne Pixel (`fake_png` schreibt einen PNG-**Header** ohne Pixel —
  richtig für `pixel_size`, unmöglich für einen Crop). Alle drei behoben,
  Suite seither mit **0 pending**.
- `a18880a` — `docs/FEATURES/ZOOM.md`, dazu RESIZE.md, `docs/ROADMAP.md` und
  FEATURES/README.md nachgezogen. Der Doku-Spec fand dabei seine eigene
  handgepflegte Liste hinter der Quelle.
- `bd72836` — **zwei Funktionen hießen `zoom`, die zweite gewann.** Der
  `resize`-Alias war seit `9fba190` tot, die README behauptete ihn weiter.
  Gefunden vom LuaLS-Scan, den `9fba190` nie bekommen hatte (+16).
- `9fba190` — **echter Zoom** für Bilder: `:Hover zoom [in|out|reset]`,
  Schwenken über `h/j/k/l` und `:Hover nav`. Baut auf `images.convert.crop`,
  das dafür in images.nvim entstand (`22213de`).
- `1234bb2` — die Resize-Handprüfung ist bestätigt (Bildhälfte).
- `8474d14` — `docs/FEATURES/RESIZE.md`: warum es Resize heißt und warum die
  drei Wege verschieden gebunden sind.
- `8ec5b40`, `bbd9dec` — **`zoom` heißt `resize`**, und gilt jetzt für jeden
  Hover statt nur für gezeichnete. Dazu sieben LuaLS-Befunde, die nur der Scan
  sah.
- `2927e38` — `docs/FEATURES/` angelegt, dieses Handover das erste Mal
  ausgemistet.
- `c11e397`, `83922f0`, `2493e1b`, `204d083` — Resize: Tasten, Route, Mausrad
  mit Zeigerprüfung (damals noch unter dem Namen Zoom).
- `e62f5e9`, `b7c4c45` — `on_request` als wiederholbare Sonde
  (`scripts/onrequest_probe.lua`) plus Evidenzzeile; ein flackernder
  LuaLS-Befund festgenagelt. Der Lauf fand drei Dinge: einen sandbox.nvim-
  Auftrag, eine vierte Wiederholung der Doku-Drift-Klasse, und dass der
  LuaLS-Scan flackert.
- `aca73fa` — `:checkhealth` sagt, wer was registriert hat.
- `4e1760f` — der Doku-Spec.
- `3e12c9f` — der Hauptschalter schlägt jetzt `force`: `vim.g.hover_disable`
  war von jeder ausdrücklichen Route aushebelbar, auch von der Keymap eines
  Hosts.
- `87a1017` — zwei Augroups hießen noch nach markdown.nvim.
- `c374d5e` — `contribute`: ein eigener Hover ohne Plugin.
- `a57d390`, `f01511f` — README- und Roadmap-Tabellen, die fünf der sechs
  Integrationen nicht kannten.
- `836a15a` — ein `on_request`-Beitrag war über keinen Weg erreichbar.

### Erledigte Aufträge in fremden Repos

Alle 2026-09-02/03, mit dem Fund, der jeweils der eigentliche Wert war.

- **bindings-explorer.nvim** (nvim-config `861371cf`) — `:Bindings check`
  deckte die BINDINGS-Tabellen von Composer-Plugins **nicht** ab und sah aus,
  als täte es das: verglichen wurde gegen `nvim_get_commands()`, dort steht nur
  `Hover`, und alle Routenzeilen fielen darauf zusammen. Betraf jedes Plugin
  auf `usercmd.composer`, also etwa die halbe Sammlung. Geprüft wird jetzt über
  die **Completion des Kommandos**, Ebene für Ebene.
- **gopath.nvim** (`a7529d1`) — nicht das, was vorhergesagt war: entfernt wurde
  ein 200-ms-LSP-Timeout, den von hier aus niemand sehen konnte.
- **sandbox.nvim** (`deb45bc`) — `engine_utils.get_engine()` wählte nach reiner
  PATH-Anwesenheit und fragte nie, ob die Engine antworten kann; hier gewann
  podman mit gestoppter VM, jeder Ask lehnte nach ~370 ms still ab. Jetzt die
  erste **antwortende** Engine, faul und pro Sitzung gemerkt. Eine *benannte*
  Engine wird nie geprüft: das ist eine Anweisung, keine Vermutung.
- **documentation.nvim** (`bdfbc9f`) — der fehlende Negativ-Cache: `find_map`
  stieg bis zu 24 Verzeichnisebenen auf und cachte im Fehlschlag nichts. In
  jedem Projekt ohne Map zahlte jeder Position-Ask den vollen Aufstieg, um
  nichts zu beantworten — 97,3 µs → **2,9 µs**, der Aufstieg allein war 98 %.
- **documentation.nvim** (`53d600d`) — `out_dir` wurde im Hover ignoriert: wer
  ihn umstellte, bekam **gar keinen** Modul-Hover, und zwar still. Der Entwurf
  hat unterwegs gedreht, und die Messung hat ihn gedreht: erst auf jeder Ebene
  zu fragen kostete 112 µs → 763 µs.
- **insights.nvim** (`00ed488`, `3e83705`) — ein voller Scan kostet 631 ms bis
  1,9 s; jetzt hinterlässt jeder Scan sein Ergebnis und `reverse_lookup` liest
  es: **28 µs** statt 622 ms. Ein kalter Index antwortet `nil` und scannt
  **nie**. Ein Modul, das niemand importiert, ist Schweigen, keine Null.
- **pdfport.nvim** (`95d27ab`, `697a5d7`) — `opts.crop` für den scharfen
  PDF-Zoom, siehe oben.
