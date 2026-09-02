# hover.nvim — Handover

Stand: **2026-09-02**. Diese Datei ist der **aktuelle Stand**: was das Plugin
ist, wo es steht, und was man wissen muss, um daran weiterzuarbeiten.

Repo: <https://github.com/StefanBartl/hover.nvim> · lokal `E:/repos/hover.nvim`
Branch: **`main`**, alles gepusht.

## Drei Dokumente, drei Fragen

| Wo | Frage | Adressat |
| --- | --- | --- |
| **diese Datei** | wo steht es, und wie arbeite ich daran | ich, beim Wiedereinstieg |
| [hover.nvim-roadmap.md](hover.nvim-roadmap.md) | was kommt als Nächstes, was ist noch nicht entschieden | ich, beim Weiterbauen |
| `hover.nvim/docs/FEATURES/` | **warum** ist ein Feature so, wie es ist | wer mitliest (im Repo, englisch) |

**Ausgemistet am 2026-09-02.** Diese Datei war auf 1 400 Zeilen gewachsen und
führte zehn abgeschlossene Auftragsberichte. Die Begründungen daraus liegen
jetzt im Repo unter `docs/FEATURES/` (`2927e38`), das Offene in der Roadmap.
Die Regel dahinter ist dieselbe wie zwischen den beiden Roadmaps: **jeder
Punkt lebt an genau einer Stelle.**

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

**Gemessen nach `ade6c1f`:**

| Prüfung | Ergebnis |
| --- | --- |
| Specs | **251 grün**, 0 Fehler, **0 pending** (bare_git 10, bare_path 48, config 17, docs 13, registry 71, resize 19, scope 26, switches 30, **zoom 17**) |
| `stylua --check` / `luacheck` | sauber (30 Dateien) |
| LuaLS (`scan.sh`, echte injizierte Library) | **0 Befunde**, Pass `zoom-post2`. Der Weg dorthin: `zoom-post` (nach `9fba190`, nie gelaufen) meldete **+16**, `zoom-fix` und `zoom-post2` je 0 |
| CI | grün auf beiden Runnern |
| Helptags | 33 |

**Die 0 pending sind neu und die Zahl, auf die zu achten ist.** Sie stand
vorher nicht in dieser Tabelle, und genau deshalb konnte ein Spec monatelang
überspringen, ohne dass es jemandem auffiel.

**Was es kann**, in einem Satz je Klasse: Datei- und Verzeichnisvorschauen,
Bilder und PDF-Seiten gezeichnet, Office-Dokumente über LibreOffice (opt-in),
URLs mit optionalem Abruf, Bare Paths mit Zeilen und Ranges
(`init.lua:42`, `file.lua:10-20`), Git-Objekte auf Nachfrage,
Position-Previews fremder Plugins, `:Hover why`, `:Hover pin`, Resize für
**jeden** Hover (`+`/`-` über Bildern, Rad und `:Hover resize` überall),
**echter Zoom** für Bilder (`:Hover zoom`, `h/j/k/l` zum Schwenken), ein
Schalter-Chooser über lib.nvims UI-Kit — und seit
`c374d5e` ein eigener Hover **ohne Plugin drumherum** (`setup({ contribute })`).

Einzelheiten im Repo: [README](https://github.com/StefanBartl/hover.nvim),
`docs/BINDINGS.md`, `docs/FEATURES/`.

## Wer beiträgt

**Sechs über die Registry** (das Plugin nennt keinen davon beim Namen):
markdown.nvim, migrate.nvim, reposcope.nvim, documentation.nvim,
spotlight.nvim, sandbox.nvim.

**Vier namentlich als weiche Abhängigkeit** (hover `pcall`t sie selbst):
gopath.nvim, open.nvim, images.nvim, pdfport.nvim.

Wer was beisteuert und was ohne ihn ausfällt: `docs/INTEGRATIONS.md` im Repo.
Alle sind optional, keiner erforderlich.

## Was offen ist

Wenig, und das meiste bewusst. Es steht **einmal**, in der
[Roadmap](hover.nvim-roadmap.md):

- **§2** — was ich als Nächstes bauen würde, in Reihenfolge.
- **§3** — offene Messungen. Zwei davon brauchen dich: das **Demo-GIF**
  (`REL-09`) und der **Office-Pfad von Hand**.
- **§4** — fünf Aufträge, die in fremden Repos liegen.
- **§6** — offene Entscheidungen: die kollidierende Lua-Modulwurzel, und ob
  `manual` der bessere Default wäre.

---

## Was beim Weiterarbeiten zu wissen ist

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
- **Tests:** `LIB_NVIM_DIR=E:/repos/lib.nvim
  PLENARY_DIR=C:/Users/bartl/AppData/Local/nvim-data/lazy/plenary.nvim
  bash scripts/test.sh`
- **LuaLS messen:** `REPOS_DIR=E:/repos bash scripts/luals-scan/scan.sh <pass>
  hover.nvim`, dann `python scripts/luals-scan/compare.py <pass>`. Die nackte
  `lua-language-server --check`-Zahl ist wertlos (`LLS-01`).
- **Der Scan sieht `TESTS/` mit, und das ist nicht theoretisch — zweimal
  belegt.** Am 2026-09-02 kam `zoom-post` mit **+2** zurück (beide im neuen
  `docs_spec.lua`, behoben in `65ba8dd`) und `resize-post` mit **+7** (alle im
  neuen `resize_spec.lua`, behoben in `bbd9dec`). Beide Male: Suite grün,
  stylua sauber, CI grün — **nur der Scan hat es gesehen.** Ein Spec ist Code,
  und nach dem Schreiben eines gehört ein Lauf dazu, nicht nur nach einer
  Änderung an `lua/`.
- **In einer Spec ist `assert` *luassert*, nicht Lua.** Es gibt mehr als einen
  Wert zurück. `nvim_win_get_position(assert(float.win()))` schickt dadurch
  ein zweites Argument und die API lehnt ab — innerhalb eines `pcall` sieht
  das aus wie „der Test ist fehlgeschlagen", nicht wie ein Arity-Fehler.
  Immer erst an ein `local` binden. Gefunden am 2026-09-02 beim Beheben der
  sieben Befunde oben.
- **Auf `pending` achten, nicht nur auf `Failed`.** Ein Spec, der mit
  plausibler Begründung überspringt, ist die Art fehlender Abdeckung, die man
  am längsten behält: der Crop-Check meldete „kein ImageMagick hier" auf einer
  Maschine, die seit jeher eines hat, und dahinter lagen drei Defekte
  (`ade6c1f`). Die Zahl steht seither in der Messtabelle oben.
- **Beide Laufarten sind jetzt dieselbe Umgebung, und waren es nicht.**
  `PlenaryBustedFile` landet in `test_harness.test_file`, das den Runner
  **ohne Optionen** aufruft — das Kind bekommt `--noplugin` und kein `-u`,
  also nicht `scripts/minimal_init.lua`. Ein Einzeldatei-Lauf hatte damit
  andere Plugins auf dem rtp als der Suite-Lauf. `scripts/test.sh` fährt eine
  Einzeldatei seit `ade6c1f` über `plenary.busted.run` im schon aufgesetzten
  Prozess.
- **Eine Tabelle in einer Lua-Datei nie als Literal mit einem optionalen
  ersten Element bauen.** `{ vim.env.FOO, "a", "b" }` ist bei ungesetztem
  `FOO` ein Loch an Index 1: `#t` meldet 3, `ipairs` läuft **null** mal. Genau
  so hat `minimal_init` seine Fallbacks nie probiert.
- **Git-Bash-Falle:** headless nvim mit einem `/tmp/...`-Pfad **hängt still**,
  statt zu scheitern. Windows-Pfade verwenden. (Steht auch in
  `scripts/luals-scan/scan.sh`.)
- **luals-scan liegt in der Config**, nicht im Plugin-Repo:
  `nvim/scripts/luals-scan/`. Und: **nicht den Worktree scannen** — die
  injizierte Library kommt vom Haupt-Checkout, dieselben `Hover.*`-Klassen
  also zweimal, Ergebnis ~100 unechte `duplicate-doc-field`. Erst den
  Haupt-Checkout nachziehen, dann den scannen.
- **Ein voller Config-Start headless hängt still.** Auch mit Windows-Pfaden.
  Isoliert prüfen (`-u NONE` plus `set rtp+=`) oder interaktiv.
- **In einer Spec ist `assert` *luassert*, nicht Lua.** Es gibt mehr als
  einen Wert zurück, also wird `nvim_win_get_position(assert(float.win()))`
  zu einem zweiten Argument, das die API ablehnt — im `pcall` sieht das aus
  wie ein fehlgeschlagener Test, nicht wie ein Arity-Fehler. Immer erst an
  ein `local` binden.
- **Heredocs mit viel Inhalt sind hier eine Falle.** Ein `<<'PY'`-Block hat
  am 2026-09-02 ein echtes **NUL-Byte** in `preview/media.lua` geschrieben
  (genau der Fehler, den die Extraktion aus lib.nvim einmal beseitigt hatte),
  und ein zweiter ist ab ~140 Zeilen an der Terminator-Erkennung
  gescheitert. Größere Patches als Datei schreiben und mit `python <datei>`
  laufen lassen; danach `open(f,'rb').read().count(bytes([0]))` prüfen.
- **`convert` auf PATH ist Windows' eigenes `convert.exe`**, nicht
  ImageMagick. Immer `magick` aufrufen.
- **Mauseingaben lassen sich headless nicht treiben.** `nvim_input_mouse`
  feuert ohne angehängtes UI **null** Mappings; `feedkeys` mit demselben
  Termcode feuert eines. Was ein echtes Rad angeht, ist deshalb Handprüfung.
- **Die Doku ist spec-geprüft.** `TESTS/docs_spec.lua` liest README, Vimdoc
  und `docs/**/*.md` gegen die Quelle: Schalternamen, alle `:Hover`-Routen in
  beide Richtungen, Zieltypen, Augroups und Highlight-Gruppen, die
  Tastenlisten aus `DEFAULTS`, und die Regeln, die `MANUAL-EVIDENCE.md` über
  sich selbst aufstellt. **Wer eine Option oder Route ergänzt, bekommt vom
  Spec gesagt, welches Dokument fehlt** — verlassen kann man sich darauf für
  alles außer den Integrations-Tabellen, die fremde Plugins beschreiben.
- **Vor dem Bauen messen.** Drei Messungen in diesem Repo haben der Intuition
  widersprochen, die sie prüfen sollten; zweimal war die naheliegende Lösung
  die falsche. Die Zahlen stehen in den Modulköpfen von `hover.scope` und
  `hover.bare_path`, nicht in Commit-Messages, damit sie beim Ändern des Codes
  gelesen werden. Ausführlich: `docs/FEATURES/BARE-PATHS.md`.

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
| Was baue ich als Nächstes, was ist unentschieden | [hover.nvim-roadmap.md](hover.nvim-roadmap.md) |
| Welche Tasten/Kommandos/Autocmds in **dieser** Config | `docs/NOTES/PersonelPlugins/BINDINGS/{Keymaps,Usercmds,Autocmds}/hover.nvim.md` |

## Nach `9fba190`: alle vier Reste erledigt — und drei Funde dabei

**Stand `ade6c1f`.** Die vier Punkte unten sind abgearbeitet. Sie haben mehr
zutage gefördert als erwartet, deshalb steht hier, *was*, und nicht nur *dass*.

### Der Scan hat einen echten Bug gefunden, keinen Lint-Fund

`zoom-post` kam mit **+16** zurück. Zwei davon waren `duplicate-set-field` auf
`init.lua`, und das war ein Fehler mit Wirkung: `8ec5b40` hatte `M.zoom` als
veralteten Alias für `resize` behalten, `9fba190` definierte 73 Zeilen weiter
unten ein **echtes** `M.zoom`, und Lua nimmt die zweite Definition. Der Alias
war ab dem Tag tot; `hover.zoom(delta)` hörte still auf, resize zu bedeuten,
und fing an, ein anderes Feature zu sein — mit anderen Voraussetzungen
(images.nvim plus ImageMagick) und anderen Kosten (258 ms statt keiner).

**Nichts ist fehlgeschlagen.** Suite grün, CI grün, das Vimdoc beschrieb den
echten Zoom korrekt — nur die README behauptete weiter, der Alias leite an
`resize` weiter. Zwei Dokumente widersprachen sich, eines hatte recht. Behoben
in `bd72836`, der Name gehört jetzt eindeutig dem echten Zoom.

Die anderen vierzehn waren dieselbe Form eine Ebene tiefer: `_open` ist
nilable deklariert, `zoomable()` hatte gerade bewiesen, dass es das nicht ist,
und jeder Aufrufer las das Feld danach neu und verlor den Beweis. `zoomable`
gibt jetzt Hover und Target mit heraus. Pass `zoom-fix`: **0 Befunde, +0**.

### Der Crop-Spec meldete überall „pending", und keiner der drei Gründe war ImageMagick

Der Punkt unten stand hier als „`minimal_init` lädt images.nvim nicht in die
Spec, direkt aufgerufen geht es". **Die zweite Hälfte war falsch** — direkt
ging es auch nicht; wer das gemessen hat, hatte `IMAGES_NVIM_DIR` exportiert.
Drei Defekte übereinander:

1. **Ein `nil`-Loch.** `add_optional` baute seine Kandidatenliste als Literal
   mit `vim.env[env_var]` an Position 1. Nicht gesetzt heißt `nil` an Index 1,
   `ipairs` hält dort sofort an — die Schleife lief **null** mal, weder
   `.deps/` noch der Geschwisterpfad wurden je probiert. `#t` meldet für
   `{ nil, "a", "b" }` eine **3**, `ipairs` liefert nichts; deshalb liest es
   sich wie eine dreielementige Liste. `add_dep` zwanzig Zeilen darüber baut
   die Liste sorgfältig und tat das immer.
2. **Zwei verschiedene Umgebungen.** `scripts/test.sh` schickte eine
   Einzeldatei durch `PlenaryBustedFile` → `test_harness.test_file`, und das
   ruft den Runner **ohne jede Option** auf: das Kind bekommt `--noplugin` und
   kein `-u`, also nicht den Bootstrap dieses Repos. Gemessen: images.nvim war
   bei einem Directory-Lauf auf dem rtp und bei einem Einzeldatei-Lauf
   **derselben Datei** nicht. Läuft jetzt über `plenary.busted.run` im schon
   aufgesetzten Prozess; Exit-Code sabotage-geprüft.
3. **Die Fixture.** Mit laufendem Spec fiel er: `fake_png` schreibt einen
   PNG-**Header** ohne Pixel — richtig für `pixel_size`, unmöglich für einen
   Crop. Die Zusicherung hätte auf keiner Maschine mit magick je bestehen
   können. Der Test baut sich jetzt ein echtes 1200×800-Bild mit demselben
   magick, das sein eigener Guard schon bestätigt hat.

**Was davon bleibt, ist eine Regel über das Wort „pending".** Alle drei waren
unsichtbar, weil der Spec einen plausibel klingenden Grund fürs Überspringen
nannte — „kein ImageMagick hier" — auf einer Maschine, die seit jeher eines
hat. Ein Skip mit guter Begründung ist die Art fehlender Abdeckung, die man am
längsten behält.

### Und ein Fund im Doku-Spec selbst

`documented_routes` führte eine handgeschriebene Liste der Argumentwerte, die
ein Dokument hinter einer Route schreiben darf. Sie entstand, als `resize` die
neueste Route war, und `9fba190` erweiterte sie nicht — also meldete das erste
Dokument mit `:Hover zoom out` einen Befehl, den es nicht gebe, gegen einen,
den es gibt. **Vierte Wiederholung dieser Klasse in diesem Repo, und die erste
innerhalb des Specs, der genau dafür geschrieben wurde.** Die Routen
deklarieren `args[].enum` für ihre eigene Completion; die Liste wird jetzt
dort gelesen.

### Die Punkte, wie sie hier standen

Zur Nachvollziehbarkeit stehen sie unverändert:

1. **LuaLS nach `9fba190` messen.** Der Pass steht noch auf `resize-post2`
   (nach `bbd9dec`). Der Zoom hat viel Code gebracht, und die Regel „der Scan
   sieht `TESTS/` mit" hat in dieser Sitzung schon zweimal zugeschlagen:
   ```bash
   cd C:/Users/bartl/AppData/Local/nvim
   REPOS_DIR=E:/repos bash scripts/luals-scan/scan.sh zoom-post hover.nvim
   python scripts/luals-scan/compare.py resize-post2 zoom-post
   ```
2. **`docs/FEATURES/ZOOM.md` schreibt sich noch nicht von selbst.** README,
   Vimdoc und `docs/BINDINGS.md` sind vollständig; die Begründungsseite fehlt,
   und der Stoff dafür steht in der Commit-Message von `9fba190` und in den
   Modulköpfen von `hover.zoom` und `preview.media.zoomed`. `RESIZE.md` sagt
   noch, ein echter Zoom stehe „on ROADMAP.md" — das stimmt jetzt nur noch für
   die PDF-Hälfte und ist beim Schreiben mitzuziehen. Ebenso `docs/ROADMAP.md`:
   der Eintrag „A real zoom — a cropped detail, panned" ist zur Hälfte gebaut,
   übrig ist nur der **scharfe PDF-Zoom**.
3. **Eine Zeile in `docs/MANUAL-EVIDENCE.md` für den Zoom.** Gemessen ist die
   Arithmetik und dass die Ausschnitte geschrieben werden; *gesehen* hat den
   vergrößerten Ausschnitt im Terminal noch niemand.

Und ein vierter Punkt, der eine echte kleine Fehlersuche ist:

4. **`scripts/minimal_init.lua` lädt images.nvim nicht in die Spec.** Ein
   `add_optional("IMAGES_NVIM_DIR", ...)` ist dort eingebaut, und direkt
   aufgerufen funktioniert es (`nvim -u scripts/minimal_init.lua -c 'lua ...'`
   meldet `images.convert=true`). Unter `bash scripts/test.sh` meldet dieselbe
   Prüfung **innerhalb** der Spec `require=false` und `rtp has images: false`.
   Folge: der Spec `hover.zoom … really cuts the source` läuft als *Pending*
   statt zu prüfen — die Zoom-Arithmetik und die Leih-Bedingungen sind
   gedeckt, **der Ausschnitt selbst nicht**. Er ist von Hand bestätigt
   (Sonde, siehe unten), aber die Suite deckt ihn nicht.
   Zum Nachstellen: eine Datei `TESTS/zz_probe_spec.lua` mit einem `it`, das
   `vim.o.runtimepath:find("images")` und `pcall(require,"images.convert")`
   ausgibt, dann einmal mit und einmal ohne `IMAGES_NVIM_DIR` laufen lassen.

**Der Ende-zu-Ende-Beweis, den es gibt**, außerhalb der Suite gegen ein echtes
ImageMagick gelaufen (1200×800-Bild, Quadranten in Rot und Blau):

```
level 1 -> 800x533+200+133      zoom in #1 -> geschrieben: 800x533
level 2 -> 533x355+333+222      zoom in #2 -> 533x355 800x533
level 3 -> 355x237+422+281      zoom in #3 -> 355x237 533x355 800x533
Mitte 0,0 auf Level 2 -> 533x355+0+0   (nicht negativ, ins Bild geschoben)
pan rechts/runter/links -> je ein neues 355x237
reset -> ganzes Bild;  pan ohne Zoom -> false
```

---

## Zuletzt passiert

Umgekehrt chronologisch, nur was den Stand ändert. Die Begründungen stehen in
den Commits und unter `docs/FEATURES/`.

- `ade6c1f` — der Crop-Spec lief nie: ein `nil`-Loch in `minimal_init`, zwei
  verschiedene Umgebungen zwischen Einzeldatei- und Directory-Lauf, und eine
  Fixture ohne Pixel. Alle drei behoben, Suite jetzt mit **0 pending**.
- `a18880a` — `docs/FEATURES/ZOOM.md`, dazu RESIZE.md, `docs/ROADMAP.md` und
  FEATURES/README.md nachgezogen. Der Doku-Spec fand dabei seine eigene
  handgepflegte Liste hinter der Quelle.
- `bd72836` — **zwei Funktionen hießen `zoom`, die zweite gewann.** Der
  `resize`-Alias war seit `9fba190` tot, die README behauptete ihn weiter.
  Gefunden vom LuaLS-Scan, den `9fba190` nie bekommen hatte (+16).
- `9fba190` — **echter Zoom**: `:Hover zoom [in|out|reset]`, Schwenken über
  `h/j/k/l` (nur solange gezoomt) und `:Hover pan`. Baut auf
  `images.convert.crop`, das dafür in images.nvim entstand (`22213de`).
  Nebenbei zwei Funde behoben: Scrollen setzte einen resizeten Hover auf die
  konfigurierte Größe zurück, und `keys.borrow` nimmt jetzt eine
  Handler-Tabelle statt eines dritten Positionsarguments.
- `1234bb2` — die Resize-Handprüfung ist bestätigt (Bildhälfte).
- `8474d14` — `docs/FEATURES/RESIZE.md`: warum es Resize heißt und warum die
  drei Wege verschieden gebunden sind.
- `8ec5b40`, `bbd9dec` — **`zoom` heißt `resize`**, und gilt jetzt für jeden
  Hover statt nur für gezeichnete. `zoom_keys` wird gefaltet, `hover.zoom()`
  bleibt als Alias. Dazu sieben LuaLS-Befunde, die nur der Scan sah.
- `2927e38` — `docs/FEATURES/` angelegt, diese Datei ausgemistet.
- `c11e397`, `83922f0`, `2493e1b`, `204d083` — Resize: Tasten, Route, Mausrad
  mit Zeigerprüfung (damals noch unter dem Namen Zoom).
- `e62f5e9`, `b7c4c45` — `on_request` als wiederholbare Sonde
  (`scripts/onrequest_probe.lua`) plus Evidenzzeile; ein flackernder
  LuaLS-Befund festgenagelt.
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
