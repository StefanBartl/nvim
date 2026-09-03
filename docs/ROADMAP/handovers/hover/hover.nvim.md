# hover.nvim — Handover

Stand: **2026-09-03**. Diese Datei ist der **aktuelle Stand**: was das Plugin
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

**Gemessen nach `1badc86`:**

| Prüfung | Ergebnis |
| --- | --- |
| Specs | **261 grün**, 0 Fehler, **0 pending** (mit `IMAGES_NVIM_DIR`; ohne sie überspringt der Crop-Check) (bare_git 10, bare_path 48, config 17, docs 13, **registry 74**, resize 19, scope 26, switches 30, zoom 24) |
| `stylua --check` / `luacheck` | sauber (30 Dateien) |
| LuaLS (`scan.sh`, echte injizierte Library) | **0 Befunde**, Pass `next-post2`. Der Weg dorthin: `next-post` (nach `ac0a372`) meldete **4**, alle aus dieser einen Änderung — `1badc86` behebt sie, `next-post2` ist 0 |
| CI | grün auf beiden Runnern |
| Helptags | 36 |

**Die 0 pending sind neu und die Zahl, auf die zu achten ist.** Sie stand
vorher nicht in dieser Tabelle, und genau deshalb konnte ein Spec monatelang
überspringen, ohne dass es jemandem auffiel.

**Was es kann**, in einem Satz je Klasse: Datei- und Verzeichnisvorschauen,
Bilder und PDF-Seiten gezeichnet, Office-Dokumente über LibreOffice (opt-in),
URLs mit optionalem Abruf, Bare Paths mit Zeilen und Ranges
(`init.lua:42`, `file.lua:10-20`), Git-Objekte auf Nachfrage,
Position-Previews fremder Plugins — **mehrere für dieselbe Stelle, zum
Durchblättern** (`<M-n>`, `:Hover next`) —, `:Hover why`, `:Hover pin`, Resize für
**jeden** Hover (`+`/`-` über Bildern, Rad und `:Hover resize` überall),
**echter Zoom** für Bilder (`<M-z>` / `<M-Z>` / `<M-R>`, `:Hover zoom`,
`h/j/k/l` zum Schwenken), ein
Schalter-Chooser über lib.nvims UI-Kit — und seit
`c374d5e` ein eigener Hover **ohne Plugin drumherum** (`setup({ contribute })`).

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

## Was offen ist

Wenig, und das meiste bewusst. Ausführlich steht es **einmal**, in der
[Roadmap](hover.nvim-roadmap.md) — hier vollständig, damit niemand sie dafür
öffnen muss.

**Braucht dich: eine Hand oder eine Entscheidung.**

| Punkt | Roadmap | Was genau fehlt |
| --- | --- | --- |
| **Demo-GIF** | §3 | `REL-09`, der letzte offene 🟢 des Release-Gates. Aufnehmen kann ich nicht. |
| **Resize von Hand, Texthälfte** | §3 | `:Hover resize` über einer *Textdatei*: kommen **mehr Zeilen** an, oder wächst nur der Rahmen? Genau die Unterscheidung, für die umbenannt wurde. Die Bildhälfte ist gesehen. |
| **Zoom von Hand** | §3 | Ob der Ausschnitt **gezeichnet** ankommt statt als skaliertes Ganzes — und ob `h/j/k/l` sich beim Schwenken richtig anfühlen. Gedrückt wird `<M-z>`; ein Alt-Akkord, den das Terminal nicht sendet, sieht aus wie ein Bild, das sich nicht zoomen lässt. |
| **Office-Kehrwoche** | §3 | Eine Datei im Cache zurückdatieren, irgendein Office-Dokument hovern (`office.cache_days`, Default 7). Der Rest des Office-Pfads ist zweimal durchgespielt. |
| **Scharfer PDF-Zoom** | §2.6 | Die einzige Hälfte des Zooms, die fehlt, und der einzige Rest im Repo-`ROADMAP.md`. Neu-Rastern bei höherem DPI kostet **3,3 s** — die Zahl ist der Grund, warum es eine Entscheidung ist und kein Ticket. |
| **Lua-Modulwurzel** | §6.1 | Umbenennen oder lassen. Heute klein, wächst mit jedem Konsumenten. |
| **`manual` als Default?** | §6.2 | Produktfrage: soll der Hover von sich aus aufgehen. |
| **language.nvim** | §4 | Die Produktfrage *vor* der Integration: soll `:Hover show` mitten in Prosa immer ein Wörterbuch aufmachen? Seit `ac0a372` **deutlich billiger zu beantworten** — es darf hinten in der Reihenfolge stehen und verdeckt keinen anderen Beitrag mehr. |

**Offen und ohne dich: eine Fehlersuche, die noch läuft.**
documentation.nvims `map`-Gate ist in CI rot — seit `66c429f` (2026-08-31),
lange vor den beiden Hover-Commits, die dort hineingelaufen sind, ohne dass
jemand hingesehen hat. `scripts/ci.sh map` meldet `docs/map/index.html` **und**
`docs/map/module_map.json` als stale; lokal ist derselbe Check nach dem
Neugenerieren grün, und mit `693829c` ist die neu erzeugte Map committet —
CI meldet sie unverändert stale. Das Artefakt hängt also an der Maschine, die
es erzeugt. Vier Ursachen sind ausgeschlossen, der nächste Schritt ist,
den Job sagen zu lassen, *was* sich unterscheidet, statt weiter zu raten:
[Roadmap §4](hover.nvim-roadmap.md#4-auftrge-die-woanders-liegen).

**Ohne dich, wenn Zeit ist:** §2 sagt, was ich als Nächstes bauen würde und in
welcher Reihenfolge. §5 hält fest, was geprüft und *nicht* aufgenommen wurde,
damit es nicht als gute Idee wiederkommt.

§4 ist bis auf language.nvim leer — bindings-explorer, gopath, sandbox, beide
documentation-Punkte und insights sind erledigt. In diesem Absatz steht
absichtlich **keine Zahl** mehr: die vorige („fünf Aufträge") stimmte nicht
mehr, und niemand merkt es einer Zahl an.

---

## Was beim Weiterarbeiten zu wissen ist

- **Regelwerk:** `WKDBooks/Development/wkdbook-Lua/Checklists/`, für dieses
  Repo `gates/NEW_PROJECT.md` (einmal durch, `NEW-01`…`NEW-46`),
  `regeln/LUA_NVIM.md` beim Schreiben.
- **Commits ohne KI-Co-Author** — steht so in `NEW_PROJECT.md` und ist hier so
  gehalten.
- **In dieser Config nur benannte Pfade stagen**, nie `git add -A`. Am
  2026-09-03 hat ein `git add -A` hier drei fremde, schon liegende Änderungen
  in einen Hover-Commit gezogen und mitgepusht: die Quota-Tabelle in
  `docs/ROADMAP/ROADMAP.md` und eine Bindings-Konsolidierung (zwei Dateien
  gelöscht, eine mit 447 Zeilen neu). Nichts ging verloren, aber die
  Commit-Message beschrieb nichts davon. Der Haupt-Checkout ist ein **lebender
  Arbeitsbaum** — hier wird von Hand editiert und andere Sitzungen lassen
  Unfertiges liegen. Die Plugin-Repos sind Worktrees je Sitzung und haben das
  Problem nicht.
- **Nach einem Commit in ein fremdes Repo dessen CI ansehen** (`gh run list`).
  Am 2026-09-03 sind zwei Commits in ein documentation.nvim gelaufen, dessen
  `map`-Gate seit dem 31. August rot war. Die dortige Suite war grün, die
  eigene Prüfung war grün — und keins von beidem ist das Gate.
- **Keine Lizenzdatei** (`NEW-06`, `REL-28`) — bewusst keine angelegt, auch
  wenn pdfport/gopath welche haben.
- **stylua-Stil:** `collapse_simple_statement = "Never"`, wie lib.nvim. Nicht
  wie markdown.nvim (`"Always"`) — der übernommene Code ist in lib.nvims Stil
  geschrieben, und eine Extraktion ist der falsche Moment, den ganzen
  Quelltext umzuformatieren.
- **Tests:** `IMAGES_NVIM_DIR=E:/repos/images.nvim
  LIB_NVIM_DIR=E:/repos/lib.nvim
  PLENARY_DIR=C:/Users/bartl/AppData/Local/nvim-data/lazy/plenary.nvim
  bash scripts/test.sh`

  **`IMAGES_NVIM_DIR` ist aus einem Worktree Pflicht**, nicht Zierde.
  `minimal_init` findet images.nvim über die Variable, ein `.deps/`-Checkout
  oder das *Nachbarverzeichnis* — und aus `.claude/worktrees/<name>/` ist der
  Nachbar der Worktree-Pool, nicht `E:/repos`. Ohne die Variable überspringt
  der Crop-Spec, und zwar als „Success". Dieselbe Form wie die
  LuaLS-Regel „nicht den Worktree scannen": der Worktree ist keine
  wahrheitsgetreue Umgebung.
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
- **`pending` ist jetzt ein Wächter statt eines Merkpostens** (`e5fca52`).
  Vorher stand hier „darauf achten" — und darauf achten hat nicht
  funktioniert: der Crop-Check meldete „kein ImageMagick hier" auf einer
  Maschine, die seit jeher eines hat, und dahinter lagen drei Defekte
  (`ade6c1f`).

  Gemessen am 2026-09-03, und die Zusammenfassung ist schlimmer als gedacht —
  in zwei Formen. `pending()` auf describe-Ebene wird **nirgends** gezählt
  (die Success-Zahl wird nur kleiner). `pending()` **innerhalb** eines `it` —
  die Form, die ein abgesicherter Spec hat — druckt eine Pending-Zeile **und
  zählt den `it` als Success**: `zoom_spec` hat 24 `it`-Blöcke und meldete
  „Success: 24", während einer davon nichts geprüft hat. Der Exit-Code bleibt
  in beiden Fällen 0.

  `scripts/test.sh` benennt sie jetzt nach dem Lauf und bricht ab, außer
  `HOVER_ALLOW_PENDING=1` ist gesetzt. Die CI setzt es — dort ist der
  Crop-Check zu Recht pending —, aber gedruckt wird die Liste auch dort, damit
  ein *neuer* Fall sichtbar ist, wo er nicht fatal sein kann.
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

- `a93dcc3` (insights.nvim) und `693829c` (documentation.nvim) — **die beiden
  Gegenseiten von `ac0a372` sind jetzt dokumentiert.** insights' Verdrahtung
  war von nirgends erreichbar: die Capability-Tabelle der README kannte sie
  nicht (es ist die einzige Fähigkeit ohne Kommando), `configuration.md` nennt
  sich „full `setup()` reference" und führte `hover` nicht, und `BINDINGS.md`
  verspricht jeden Autocmd — der `BufWritePost` des Index stand nicht darin.
  documentation.nvims Seite sagte nirgends, dass für denselben dotted name
  jetzt ein **zweites** Plugin antwortet; wer zwei Antworten bekam, konnte
  nicht wissen, dass die zweite kein Fehler ist.

  Dabei ist dort die generierte Map neu erzeugt worden, weil sie stale war —
  und dabei kam heraus, dass das `map`-Gate in CI seit `66c429f` rot ist.
  **Das Neuerzeugen hat es nicht behoben**, siehe oben unter „Was offen ist".
- `1badc86` — **der erste LuaLS-Lauf über `ac0a372` fand vier Befunde**, alle
  aus dieser einen Änderung. `_open.col` und `_open.position_nth` sind das,
  womit das Blättern dieselbe Stelle erneut fragt, und beide standen nicht in
  `Hover.Open` — drei Befunde für zwei Felder. Der vierte war der Spec-Helfer,
  der `nvim_win_get_buf(float.win())` ohne die Hausform ruft. Wert dieser
  Zeile: die Tabelle oben sagte **0 Befunde**, und das galt für den Stand
  davor. Ein Scan pro Codeänderung, nicht pro Woche.
- `913f2db` — insights.nvim ist verdrahtet, also ist sein Roadmap-Eintrag im
  Repo **gelöscht** statt abgehakt (die Regel dieser Datei). Der Zähler
  („fünf der Kandidaten sind gebaut") ist dabei ganz verschwunden statt
  hochgezählt: er war zweimal falsch, und eine Liste daneben hat ihn ohnehin.
  Auf insights' Seite `3e83705` — ein Position-Beitrag, der aus dem
  gemerkten Scan antwortet und **nie** einen startet: 28 µs oder Schweigen.
- `ac0a372` — **mehrere Plugins dürfen für dieselbe Stelle antworten**, und
  jetzt sind alle lesbar: `<M-n>` / `:Hover next` blättert weiter und hinter
  der letzten wieder nach vorn. Vorher gab `position_at` die *erste* Antwort
  zurück, und wer zweiter registriert war, war unsichtbar — entschieden von
  der Ladereihenfolge. Gezählt wird nichts im Voraus: wer antworten *würde*,
  wüsste man nur, indem man jeden Beitrag bei jedem Hover aufruft.

- `e5aef5c` — die Zoom-Zeile in `MANUAL-EVIDENCE.md` nannte nur die Route.
  Gedrückt wird `<M-z>`, und die erste Art, wie das scheitert, ist genau die,
  für die diese Datei da ist: ein Alt-Akkord, den das Terminal nicht sendet,
  sieht aus wie ein Bild, das sich nicht zoomen lässt.
- `efafb82` — **der Zoom bekommt Tasten** (`<M-z>` hinein, `<M-Z>` heraus,
  `<M-R>` zurück aufs ganze Bild), und **`:Hover pan` heißt `:Hover nav`**
  (samt `pan_keys` → `nav_keys`, `hover.pan` → `hover.nav`). Umbenannt statt
  aliasiert — ein Alias für eine umbenannte Operation ist genau das, was
  `bd72836` erzeugt hat.

  Zwei Dinge daran sind mehr als Umbenennung. **`zoom_keys` musste der
  Legacy-Schreibweise von `resize_keys` wieder abgenommen werden**, und die
  alte Form wird jetzt **gemeldet und ignoriert** statt gefaltet: still
  gefaltet hätte eine Config, die für die alte Bedeutung geschrieben ist, eine
  258-ms-Ausschnittsoperation auf die Taste gelegt, die jemand für einen
  kostenlosen Resize-Schritt gewählt hat. Unterschieden wird an der *Form*
  (`larger/smaller` gegen `into/out/reset`), nicht am Datum. Und `into` statt
  `in`, weil `in` ein Lua-Schlüsselwort ist und sonst in jeder Nutzer-Config
  `["in"]` heißen müsste.

  Dazu zwei weitere Treffer der handgeführten-Listen-Klasse:
  `config.replace_key_lists` führte eine Literalliste unter einem Kommentar,
  der „declared rather than written out" behauptete, und `switches_spec` eine
  zweite handgeschriebene Liste der Routen-Argumentwerte — kürzer als die, die
  `docs_spec` schon hatte. Beide leiten jetzt ab.
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
  `h/j/k/l` (nur solange gezoomt) und `:Hover nav` (damals `:Hover pan`).
  Baut auf
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
