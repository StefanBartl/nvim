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

Die beiden Punkte, die Fragen an dich waren, sind beantwortet und gebaut.
Was offen bleibt, sind zwei Handprüfungen — beides eine Minute.
Stand 2026-09-03 nach drei Runden.

| # | Punkt | Wer | Was genau fehlt |
| --- | --- | --- | --- |
| [1](#1-kommt-die-übersetzung-überhaupt-an) | **HTTP 429 hinter der Übersetzung** | du (ein Test) | Der keylose Google-Endpunkt hat bei **jeder** Messung 429 geantwortet. Ob das an dieser Maschine liegt oder an der Leitung, entscheidet ein `:Translate DE cword`. |
| [2](#2-kommt-m-n-an) | **`<M-n>`** | du (ein Test) | Derselbe Akkord-Typ wie `<M-z>`, das nachweislich nicht ankommt. Ungeprüft. |
| [3](#3-was-ich-ohne-dich-tun-würde) | *(ohne dich)* | ich | Nichts Dringendes. |

**Erledigt am 2026-09-03**, in der Reihenfolge, in der es passiert ist:

- **Scharfer PDF-Zoom** — gebaut (`7fdfc09`). Die Messung hat den Punkt
  freigegeben, der als „3,3 s je Schritt" eine Entscheidung war: das war die
  Zeit für eine *ganze* Seite, das sichtbare Fenster kostet 118–140 ms auf
  jeder Stufe.
- **Resize von Hand, Texthälfte** — bestätigt: es kommen mehr **Zeilen** an.
  **Meine Anweisung war falsch** (`+` ist über einem Text-Hover nicht
  geborgt, sondern die Motion, die den Hover mitnimmt); `:Hover resize` ist
  der Weg, und `MANUAL-EVIDENCE.md` stand schon richtig da.
- **Office-Kehrwoche** — bestätigt: eine um 30 Tage zurückdatierte PDF war
  nach dem nächsten Lauf weg, die neue lag da. Wichtig für die
  Wiederholung: es muss ein **anderes** Dokument sein, weil der Sweep einmal
  je Sitzung und nur bei einer echten Konvertierung läuft.
- **Bild-Zoom von Hand** — bestätigt: der Ausschnitt kommt gezeichnet an, und
  `h/j/k/l` fühlt sich richtig an. Getrieben mit `>` / `=`, weil die
  Alt-Akkorde nicht ankommen — genau der Befund, aus dem `21c4932` wurde.
- **Lua-Modulwurzel** — entschieden: der Name bleibt. `docs/NAME-COLLISION.md`
  (`e228dfb`), vier Sätze, keine README-Referenz.
- **Demo-GIF** — von der Liste; kommt am Schluss für alle Plugins zusammen.
- **Auto-Modus pro Zieltyp** — gebaut (`e8cde0e`, `f265f19`). Ausführlich
  unter [Was jetzt von selbst aufgeht](#was-jetzt-von-selbst-aufgeht).
- **Zoom-Tasten** — gebaut (`21c4932`). Default ist `>` hinein, `|` heraus,
  `=` zurück. Deine Wahl, und sie hält der Nachmessung stand; `-` als
  Alternative hätte **nie** funktioniert. Ausführlich unter
  [Was der Zoom jetzt bekommt](#was-der-zoom-jetzt-bekommt).
- **language.nvim** — gebaut (`b592b9f` dort, `150be49` hier). `:Translate DE
  cword` und `:Hover show` über einem Wort. Ausführlich unter
  [Was language.nvim jetzt beiträgt](#was-language-nvim-jetzt-beiträgt).

---

## Was jetzt von selbst aufgeht

**Default seit `e8cde0e`: nur Bilder und PDF-Seiten.** Alles andere wartet
darauf, gefragt zu werden.

```lua
require("hover").setup({
  auto_hover = { "image", "pdf" },   -- der Default
  -- auto_hover = true,              -- alles, wie vorher
  -- auto_hover = false,             -- nichts; wirkt wie mode = "manual"
})
```

Drei Schreibweisen, eine Bedeutung. Eine **Liste** ist eine geschlossene Menge
und ersetzt den Default. Eine **Tabelle** ist additiv (`{ file = true }` heißt
„und Textdateien auch") — so mergen alle anderen Optionen hier, und so
schreibt der Laufzeit-Schalter zurück. `true`/`false` sind die beiden Enden.

Zur Laufzeit: `:Hover auto` listet, was aufgeht und was wartet;
`:Hover auto image` schaltet einen Typ um; `:Hover auto all|none` beides auf
einmal. `:checkhealth hover` sagt es auch — weil ein schmaler Default sich wie
ein Defekt anfühlt: eine Textdatei hovern und nichts bekommen sieht genauso
aus wie ein kaputtes Plugin.

**Drei Dinge, die du wissen musst.**

1. **Position-Previews sind mit aus.** documentation.nvim („was ist dieses
   Modul"), insights.nvim („wer importiert es") antworten jetzt nur noch auf
   `:Hover show`. Das ist der einzige Default hier, der ein echter Kompromiss
   ist statt einer offensichtlichen Wahl — niemand registriert einen
   Position-Beitrag versehentlich, `position = true` wäre also vertretbar
   gewesen. Er ist aus, damit „installieren, und Bilder gehen auf" auch auf
   einer Maschine mit sieben Beiträgern stimmt. Zurück mit
   `:Hover auto position`, dauerhaft in `auto_hover`.
2. **Es spart das Float, nicht die Arbeit davor.** Um zu wissen, dass etwas
   ein Bild ist, muss der Pfad aufgelöst werden. Du bekommst Ruhe, nicht
   Tempo.
3. **Es sperrt den Trigger, nicht das Plugin.** `:Hover show` antwortet für
   jeden Typ. Genau das ist der Unterschied zu `paths.enabled`: das sagt „ist
   gar kein Ziel", `auto_hover` sagt „nicht ungefragt".

**Zu deinen Umbenennungsfragen, mit Begründung — ich habe zwei von drei
umgesetzt und einer widersprochen.**

- **`auto` → `auto_hover`:** übernommen. `auto_open_hover` wäre genauer und
  ist zu lang für etwas, das man in jede Config schreibt.
- **`mode` → „Startmodus":** **nicht** umgesetzt, und das ist der einzige
  Punkt, an dem ich dir widerspreche. `mode` ist nicht der Start-, sondern der
  *aktuelle* Zustand — `:Hover mode manual` schaltet ihn mitten in der
  Sitzung. Ein Name mit „start" darin wäre genau in dem Moment falsch, in dem
  man ihn benutzt.
- **Braucht man `manual` noch?** Du hast dich nicht verzettelt, die Frage ist
  richtig — und die Antwort ist ja, aber aus einem anderen Grund als vorher.
  `manual` ist jetzt die *temporäre* Form von `auto_hover = false`: ein
  Schalter für jetzt gegen eine Einstellung für immer. „Ich lese gerade ein
  Dokument voller Links, Ruhe bitte" ist ein Handgriff; `auto_hover` leeren
  und später wiederherstellen ist keiner. Und `off` bleibt `off` statt
  `no_hover`: kürzer, und es steht schon in jeder Doku.

Was dabei nebenbei herauskam: die Argumentwerte aller Routen liegen im
Doku-Spec in **einem** Topf, und die neuen Typnamen (`missing`, `office`,
`file`, `image`) sind gleichzeitig Routenwörter. `:Hover paths missing` wurde
dadurch zu `paths` gekürzt, und drei Dokumente meldeten eine echte Route als
undokumentiert. Der Spec liest jetzt beide Lesarten — großzügig für „ist das
dokumentiert", streng für „nennt ein Dokument etwas, das es nicht gibt".

---

## Was der Zoom jetzt bekommt

**Default seit `21c4932`: `>` hinein, `|` heraus, `=` zurück.** Deine Wahl,
und die Nachmessung hat sie bestätigt statt nur zugelassen.

**Warum die Alt-Akkorde weg sind.** Sie standen auf einem Satz: ein Akkord
verdrängt nichts. Das stimmt — und ist genau so viel wert, wie das Terminal
bereit ist, den Akkord zu senden. Hier sendet es keinen. Eine Taste, die nichts
verdrängt **und nichts tut**, ist keine billige Taste, sondern eine abwesende.
Wo die Akkorde ankommen, sind sie weiter richtig, und sie sind ein `zoom_keys`
entfernt.

**Was ich vor der Änderung gemessen habe, statt es zu vermuten:**

| Kandidat | Befund |
| --- | --- |
| `\|`, `_`, `>`, `=` | which-keys `Util.norm` gibt sie **unverändert** zurück |
| `<` | wird zu **`<lt>`** normalisiert, während die Zuordnung `<` bleibt — daher „Recursion detected“. Kein Zufall einer Config: jeder mit which-key träfe das |
| `-` | **kann gar nicht funktionieren**, so naheliegend es neben `_` aussieht |

**Der `-`-Befund ist der, den ich dir schulde**, weil er deinen Alternativ-
vorschlag betrifft. `resize_keys.smaller` hält `-`; `borrow()` nimmt die
Resize-Tasten **vor** den Zoom-Tasten; eine doppelt gelistete Taste wird einmal
genommen. Und jedes Hover, für das überhaupt eine Zoom-Taste gebunden wird,
hat ein Bild — die Überschneidung ist also **total**, nicht gelegentlich. `-`
hätte bei jedem Druck resized und nie gezoomt. Das Bild wächst, die Taste sieht
also funktionierend aus, und nur der Ausschnitt ist falsch: die Sorte Fehler,
die am schwersten zuzuordnen ist. Deshalb ist der Befund jetzt zweimal
festgenagelt — als Spec (`TESTS/zoom_spec.lua`, sabotiert: ohne die
Doppelvergabe-Sperre fällt genau diese eine Zusicherung) und als Warnung in
`:checkhealth hover`.

**Warum die drei nicht auf einem Argument stehen.** `>` und `=` sind
**Operatoren**: über einem Float bewegen sie keinen Cursor und schließen von
selbst nicht ab, die Leihe kostet also nichts. `|` ist eine **Motion**, und das
ist das Argument *dafür*, sie zu nehmen: ungebunden springt sie auf Spalte 1,
das Dismiss hängt an `CursorMoved`, der Druck nähme also das Bild weg. Dasselbe
Argument, das `h/j/k/l` machen.

**Für diese Config heisst das:** der `zoom_keys`-Workaround im Plugin-Spec ist
weg (`5522fe3f`), `require("hover").enable()` steht wieder ohne Optionen da.

---

## Was language.nvim jetzt beiträgt

**Zwei Hälften einer Lücke** (language.nvim `b592b9f`). `:Translate` nahm immer
einen *Scope* — Buffer, sichtbarer Bereich, Selection, Verzeichnis — und ein
einzelnes Wort ist keiner davon. Die kleinste nützliche Übersetzung war die
eine Form, die das Plugin nicht konnte.

```
:Translate DE cword     das Wort unter dem Cursor, Sprache getippt, ins Popup
:Hover show             dasselbe Wort, Sprache aus der Config, ins Hover-Float
```

| | Wer nennt die Sprache | Wo landet die Antwort |
| --- | --- | --- |
| `:Translate DE cword` | du, pro Aufruf | das bestehende Popup |
| `:Hover show` | `translate.default_target`, sonst `EN` | ein hover.nvim-Float, blätterbar neben documentation.nvim & Co. |

**Drei Entscheidungen darin, die keine Details sind.**

1. **`on_request`.** Jede Antwort ist eine Anfrage von dieser Maschine an einen
   Übersetzungsdienst, die das Wort unter dem Cursor mitnimmt. Auf dem
   *automatischen* Trigger — der nach jedem Tastendruck plus Ruhe feuert —
   würde Lesen zu einem Strom von Preisgaben, Wort für Wort. Dieselbe Klasse
   wie `links.fetch`, dieselbe Antwort: nur auf ausdrückliche Frage.
   `:checkhealth language` **meldet** das Flag, statt es anzunehmen — ein
   älteres hover.nvim ignoriert ein unbekanntes `on_request`, und das ist der
   eine Fehler hier, den man von außen nicht sähe.
2. **Es blockiert, gemessen statt gehofft.** `position_at` ist synchron: ein
   Beitrag gibt seinen Inhalt zurück oder antwortet nicht. Fünf Wörter, je
   zwei Läufe: **448–929 ms** — dieselbe Größenordnung wie sandbox.nvims
   Container-Abfragen. Gedeckelt bei 2 s statt bei `translate.timeout_ms`
   (8 s): das Budget gehört einem Kommando, das im Hintergrund läuft, dieses
   hält den Editor.
3. **`EN` als Rückfall, `DE` in deiner Config.** Im Plugin bleibt `EN`, weil
   die meisten Leser in ihre eigene Sprache übersetzen und die selten Deutsch
   ist. Der Rückfall sitzt im Hover statt in `DEFAULTS`, weil `nil` dort schon
   etwas heißt: *fragen*, was die Motion-Maps tun. Ein Hover hat keinen Ort
   zum Fragen.

**Achtung, eine Verhaltensänderung in deiner Config:** `default_target = "DE"`
gilt auch für `<leader>lt`. Diese Maps **fragen jetzt nicht mehr** nach der
Sprache, sondern übersetzen direkt nach Deutsch. Für einen einzelnen Lauf in
eine andere Sprache: `translate.keymaps.to.<LANG>` oder `:Translate <lang>`.

**Und der Vorbehalt steht in [Punkt 1](#1-kommt-die-übersetzung-überhaupt-an):**
der keylose Endpunkt hat bei jeder Messung 429 geantwortet.

**Zwei Funde beim Bauen**, beide aus den Klassen, die dieses Projekt kennt:

- **`cword` musste in den *geteilten* Scope-Satz**, sonst liest
  `:Translate DE cword` das `cword` als *zweiten Sprachcode* und übersetzt den
  ganzen Buffer. Der Preis ist, dass `:Spellcheck` es namentlich ablehnen muss
  — und das normalisiert einen Scope an **zwei** Stellen (`run` und
  `open_panel`). In nur eine geschrieben hätte die andere weiter den ganzen
  Buffer geprüft.
- **Der LuaLS-Scan fand +18 `need-check-nil` nach grüner Suite:** eine Prüfung
  auf `scope.region` verengt nichts für ein *späteres Lesen desselben Feldes*.
  Erst binden, dann prüfen. Danach 0, `+0`.

---

## Die offenen Punkte, einzeln

### 1. Kommt die Übersetzung überhaupt an?

**Das ist der einzige echte Vorbehalt am neuen Feature, und er ist gemessen.**
Der keylose Google-Endpunkt (`translate_a/single?client=gtx`), den
language.nvims Default-Engine benutzt, hat am 2026-09-03 bei **jeder** Anfrage
von dieser Maschine **HTTP 429** geantwortet — Googles Seite „your computer or
network may be sending automated queries“, mit und ohne Browser-User-Agent.
`api.datamuse.com` hat in derselben Minute mit 200 geantwortet, das Netz ist
also in Ordnung.

**Was ich nicht weiß:** ob das an deiner Leitung liegt oder an dem Weg, den
meine Werkzeuge nach draußen nehmen. Das entscheidet ein Test:

```
:Translate DE cword     über einem englischen Wort
```

| Was kommt | Bedeutet |
| --- | --- |
| die deutsche Übersetzung | alles gut, der 429 war mein Weg nach draußen |
| „das Ende antwortete mit einer Seite, keiner Übersetzung (Rate-Limit oder Sperre)“ | der Endpunkt sperrt auch dich |

Im zweiten Fall ist das Feature nicht kaputt, sondern die Engine. Ausweg ohne
jede Codeänderung: `translate.engine = "deepl"` mit einem Schlüssel (oder
`$DEEPL_API_KEY`), `"shell"` über `trans`, oder ein eigenes `custom`-Kommando.
Der Hover fragt, was die Provider-Kette auflöst — nicht Google.

Dass der Float die Ursache **benennt** statt „invalid translation response“ zu
sagen, ist genau wegen dieser Messung eingebaut: `vim.json.decode` auf einer
HTML-Seite sagt dasselbe wie ein echter Parse-Fehler, und das sind zwei
verschiedene Probleme mit zwei verschiedenen Lösungen.

### 2. Kommt `<M-n>` an?

**Eine Minute, und aus dem Zoom-Befund folgt der Verdacht.** `<M-z>` erreicht
dieses Terminal nicht — das ist gemessen. `<M-n>` ist derselbe Akkord-Typ und
ist hover.nvims Default, um zwischen mehreren Antworten zu **derselben Stelle**
zu blättern (`position_keys.next`). Genau die braucht man ab jetzt öfter:
über einem dotted name antworten schon documentation.nvim und insights.nvim,
und über einem gewöhnlichen Wort kommt jetzt language.nvim dazu.

```
:nnoremap <M-n> :echo "kommt an"<CR>
```

Kommt nichts, sag Bescheid — dann sucht das denselben Weg wie der Zoom: eine
blanke Taste, die weder Präfix noch Notationszeichen ist. Ich habe den Default
**nicht** eigenmächtig geändert: `<M-n>` wird für *Position*-Hovers geliehen,
und dort verengt nichts am Inhalt die Leihe — eine blanke Taste kostet dort
mehr als beim Zoom. `:Hover next` ist der Weg ohne jede Taste.

### 3. Was ich ohne dich tun würde

- **`hover.scope` als lib.nvim-Helfer** (`REL-31`). Ein Helfer mit einem
  Konsumenten ist ein Helfer, den ein Konsument geformt hat — wieder
  aufgreifen, wenn etwas Zweites dieselbe Frage stellt. `open.nvim` wäre der
  natürliche zweite.
- **Turnusmäßig:** nach jeder Code-Änderung ein LuaLS-Scan, und ein Blick auf
  die CI der Repos, in die ich committe.

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

**Gemessen nach `150be49`:**

| Prüfung | Ergebnis |
| --- | --- |
| Specs | **279 grün**, 0 Fehler, **0 pending** (mit `IMAGES_NVIM_DIR`; ohne sie überspringt der Crop-Check) (bare_git 10, bare_path 48, config 17, docs 13, **registry 74**, resize 19, scope 26, **switches 42**, zoom 30) |
| `stylua --check` / `luacheck` | sauber (35 Dateien) |
| LuaLS (`scan.sh`, echte injizierte Library) | **0 Befunde**, Pass `zoomkeys-post`, `+0` gegen `autohover-fix2`. language.nvim eigener Pass `lang-hover2`, **0**, `+0` gegen `lg_c` |
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
**echter Zoom** für Bilder *und* PDF-Seiten (`>` / `|` / `=`,
`:Hover zoom`, `h/j/k/l` zum Schwenken), ein Schalter-Chooser über lib.nvims
UI-Kit — und seit `c374d5e` ein eigener Hover **ohne Plugin drumherum**
(`setup({ contribute })`).

Einzelheiten im Repo: [README](https://github.com/StefanBartl/hover.nvim),
`docs/BINDINGS.md`, `docs/FEATURES/`.

## Wer beiträgt

**Acht über die Registry** (das Plugin nennt keinen davon beim Namen):
markdown.nvim, migrate.nvim, reposcope.nvim, documentation.nvim,
spotlight.nvim, sandbox.nvim, insights.nvim, **language.nvim** (seit
`b592b9f` / `150be49`).

**Zwei davon sind `on_request`**, und es sind genau die teuren: sandbox.nvim
(eine Container-Engine wecken) und language.nvim (eine Netzanfrage). Ohne das
Flag hätte keines von beiden ehrlich gebaut werden können.

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

- `b592b9f` (language.nvim), `150be49` — **das Wort unter dem Cursor,
  übersetzt.** `:Translate DE cword` und ein `on_request`-Position-Beitrag für
  `:Hover show`. In hover.nvim selbst änderte sich **nichts** außer der
  Integrations-Doku — was der Punkt der Registry-Form ist. Dabei zwei Zähler-
  Drifts gefallen: „Four of those six are position previews“ stand neben einer
  Tabelle mit sieben Zeilen und fünf Previews, und die README nannte sechs
  Beitragende ohne insights.nvim. Ein Zähler neben der Liste, die er zählt, ist
  eine zweite Quelle.
- `21c4932` — **der Zoom bekommt Tasten, die ankommen.** `>` / `|` / `=` statt
  `<M-z>` / `<M-Z>` / `<M-R>`. Dazu ein Health-Check für die Überschneidung
  mit `resize_keys` und ein Fund im Doku-Spec: ein `|` in einer Tabellenzelle
  muss `\|` geschrieben werden, und `tabulated_keys` teilte die Zeile genau
  dort — der Default las sich als leere Liste, und der Spec nannte ein
  richtiges Dokument falsch. Die schlimmste Lage, in der eine Doku-Prüfung
  sein kann.
- `67127be` — drei Evidenzzeilen geprüft (Resize-Text, Office-Kehrwoche,
  Bild-Zoom), und der Befund darunter: **`<M-z>` erreicht Neovim auf dieser
  Maschine nicht**. Auf `:echo` gemappt druckt es nichts, also sendet das
  Terminal den Akkord nicht; was ankommt, ist `<Esc>`+`z`, und which-key geht
  auf dem Präfix auf. Mit `>` und `=` läuft der Zoom, `<` bringt which-key zu
  „Recursion detected" — seine Antwort darauf, dass ein Plugin genau das
  Zeichen bindet, mit dem Vims Tastennotation anfängt.
- `e8cde0e`, `f265f19` — **`auto_hover`: nur Bilder und PDF-Seiten gehen von
  selbst auf.** Die dritte Achse, quer zu den bestehenden Schaltern: die sind
  danach organisiert, *wo* ein Ziel gefunden wurde, diese danach, *was* es
  ist. Ein Markdown-Link kann auf ein Bild oder eine Textdatei zeigen, also
  war „nur Bilder, egal wie geschrieben" vorher nicht sagbar. Dazu ein Fund
  im Doku-Spec (Argumentwerte aller Routen in einem Topf, und die neuen
  Typnamen sind gleichzeitig Routenwörter) und einer vom LuaLS-Scan
  (`health.info` nimmt keine Advice-Liste und verschluckt sie still — dieselbe
  Klasse wie documentation.nvim `9f128bb`).
- `e228dfb` — `docs/NAME-COLLISION.md`: vier Sätze zur Modulwurzel, und die
  Resize-Evidenzzeile ist vollständig. Die Zeile sagt jetzt auch, warum `+`
  nicht der Weg ist, sie zu prüfen — über einem Text-Hover ist `+` die Motion,
  die es immer war, und sie nimmt den Hover mit.
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
