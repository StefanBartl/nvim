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

Vier Punkte. Stand 2026-09-03, nach einer Runde Handprüfung.

| # | Punkt | Wer | Was genau fehlt |
| --- | --- | --- | --- |
| [1](#1-zoom-von-hand-und-die-tasten-die-nicht-ankommen) | **Zoom von Hand** | du + ich | Der Zoom arbeitet, das Schwenken fühlt sich richtig an — aber `<M-z>` kommt in deinem Terminal **nicht an**. Eine Diagnose und danach vielleicht andere Default-Tasten. |
| [2](#2-office-kehrwoche) | **Office-Kehrwoche** | du | Eine Datei im Cache zurückdatieren, ein Office-Dokument hovern. Befehle stehen unten fertig. |
| [3](#3-ein-auto-modus-pro-zieltyp) | **Auto-Modus pro Zieltyp** | Entscheidung du, Bau ich | Dein Entwurf vom 2026-09-03: von selbst nur Bilder/PDFs, alles andere dazuschaltbar. Einschätzung und ein konkreter Vorschlag unten. |
| [4](#4-languagenvim-ein-wörterbuch-im-hover) | **language.nvim** | du | Ob ein Wörterbuch im Hover überhaupt gewollt ist. Unten neu erklärt, weil die alte Formulierung nicht verständlich war. |

**Erledigt seit der letzten Fassung, mit Datum:**

- **Scharfer PDF-Zoom** — gebaut am 2026-09-03 (`7fdfc09`). Er war der letzte
  Punkt, der weder Hand noch Entscheidung brauchte.
- **Resize von Hand, Texthälfte** — bestätigt am 2026-09-03: es kommen **mehr
  Zeilen** an, nicht nur ein größerer Rahmen. Damit ist die Evidenzzeile
  vollständig (Bildhälfte 2026-09-02).

  **Und meine Anweisung dazu war falsch.** Ich hatte „`+` zweimal drücken"
  geschrieben. Über einem *Text*-Hover ist `+` gar nicht geborgt — dort ist es
  die Motion, die es immer war, also springt der Cursor eine Zeile weiter und
  nimmt dabei den Hover mit. Genau deshalb gibt es die Route `:Hover resize`,
  und genau das stand in `MANUAL-EVIDENCE.md` schon richtig. Ich habe aus dem
  Handover heraus etwas anderes behauptet als das Dokument, das dafür da ist.
- **Lua-Modulwurzel** — entschieden am 2026-09-03: **der Name bleibt.** Keine
  Umbenennung, keine Referenz im README. Stattdessen `docs/NAME-COLLISION.md`
  (`e228dfb`): vier Sätze, englisch, die sagen, dass bei zwei Plugins mit der
  Modulwurzel `lua/hover/` die Ladereihenfolge entscheidet, welches erreichbar
  ist. Nichts zeigt darauf, weil die Notiz nur den interessiert, der schon
  beide installiert hat und sich wundert.
- **Demo-GIF** — von der Liste genommen. Kommt am Schluss für alle `.nvim`-
  Plugins in einem Aufwasch.

---

## Die offenen Punkte, einzeln

### 1. Zoom von Hand, und die Tasten, die nicht ankommen

**Was bestätigt ist (2026-09-03).** Das Schwenken mit `h/j/k/l` „fühlt sich
perfekt an" — deine Worte, und das war die Hälfte, die keine Spec beantworten
kann. Der Zoom selbst arbeitet also: `:Hover zoom` schneidet, `h/j/k/l`
bewegen.

**Was nicht funktioniert.** `<M-z>` tut gar nichts, und stattdessen geht
**which-key** auf und schlägt weitere Tasten vor.

**Das ist ein Befund, kein Rätsel — aber die Ursache steht noch nicht fest.**
Wenn `<M-z>` bei Neovim ankäme und nichts daran gebunden wäre, passierte
schlicht nichts. Dass which-key aufgeht, heißt: Neovim hat etwas anderes
bekommen. Die wahrscheinliche Form ist `<Esc>` gefolgt von `z`, also der
Terminal-Weg für Alt-Akkorde, und `z` ist ein which-key-Präfix (Folds). Genau
diese Verwechslung beschreibt `MANUAL-EVIDENCE.md` als die erste Art, wie das
scheitert — sie sieht aus wie ein Plugin-Fehler und ist keiner.

**Deine Aufgabe: ein Tastendruck.**

```vim
:nnoremap <M-z> <Cmd>echo "M-z kommt an"<CR>
```

Dann `<M-z>` drücken:

- **„M-z kommt an" erscheint** → das Terminal sendet den Akkord. Dann lag es
  daran, dass kein *zoombarer* Hover offen war: über einer Textdatei werden
  die Zoom-Tasten nicht geborgt (nur über Bild und PDF-Seite). Der Screenshot,
  den du geschickt hast, zeigt einen Hover auf `ROADMAP.md` — das wäre die
  Erklärung, und dann ist nichts kaputt.
- **which-key geht wieder auf** → das Terminal sendet den Akkord nicht, und
  keine Konfiguration in diesem Plugin kann daran etwas ändern.

**Was ich übernehme, wenn es der zweite Fall ist.** Andere Default-Tasten,
oder deine eigenen. Der Punkt bei diesen Tasten ist, dass sie **nur geliehen**
sind, solange ein zoombarer Hover offen steht — also ist fast alles frei, was
im Normal-Modus teuer wäre. Sofort und ohne Codeänderung:

```lua
require("hover").setup({
  zoom_keys = { into = ">", out = "<", reset = "=" },
})
```

`>` und `<` sind im Normal-Modus Operatoren, die auf eine Motion warten; als
geliehene Einzeltasten über einem Float sind sie frei und tragen die
Bedeutung schon im Zeichen. Wenn sich das bewährt, würde ich es zum Default
machen — die Alt-Akkorde waren die Wahl unter der Annahme, dass sie überall
ankommen, und diese Annahme ist auf deiner Maschine gerade widerlegt worden.

**Was danach noch offen bleibt.** Das eigentliche Hinsehen: ob der
vergrößerte Ausschnitt **gezeichnet** ankommt, für ein Bild und für eine
PDF-Seite — und bei einer **gescannten** PDF ausdrücklich *ohne* schärfer zu
werden, weil dort nichts mehr zu holen ist. Die Zahlen dazu liefert
`scripts/pdfzoom_probe.lua`; hinsehen kann sie nicht.

### 2. Office-Kehrwoche

**Was fehlt.** Der altersbasierte Sweep des Office-Caches
(`office.cache_days`, Default 7). Alles andere am Office-Pfad ist zweimal
durchgespielt.

**Wie der Sweep funktioniert**, damit die Prüfung nicht am falschen Ende
sucht: er läuft **einmal pro Sitzung**, und zwar erst, wenn in dieser Sitzung
zum ersten Mal wirklich **konvertiert** wird. Ein Dokument, dessen PDF schon
im Cache liegt, löst ihn *nicht* aus. Deshalb braucht die Prüfung zwei
verschiedene Dokumente oder einen Neustart mit einem noch nicht konvertierten.

**Deine Aufgabe, Schritt für Schritt.**

1. Ein Office-Dokument hovern, mit eingeschalteter Konvertierung — das legt
   die erste PDF im Cache an:

   ```vim
   :Hover office on
   ```

   Dann den Cursor auf einen Pfad wie `./Bewerbung_Stefan_Bartl_3S.docx`
   stellen und warten, bis die Seite kommt.

2. Nachsehen, was da liegt, und es um 30 Tage zurückdatieren (PowerShell):

   ```powershell
   $dir = "$env:LOCALAPPDATA\Temp\nvim\hover.nvim\office"
   Get-ChildItem $dir -Filter *.pdf | ForEach-Object { $_.LastWriteTime = (Get-Date).AddDays(-30); $_ }
   ```

   Das druckt die Dateien mit ihrem neuen Datum — merk dir einen Namen.

3. Neovim **neu starten** (der Sweep ist pro Sitzung gemerkt), dann ein
   **anderes** Office-Dokument hovern, wieder mit `:Hover office on`.

4. Nachsehen, ob die zurückdatierte Datei weg ist:

   ```powershell
   Get-ChildItem "$env:LOCALAPPDATA\Temp\nvim\hover.nvim\office" -Filter *.pdf | Select-Object Name, LastWriteTime
   ```

   Erwartung: die alte ist fort, die neue liegt da. Bleibt die alte liegen,
   ist der Sweep nicht gelaufen — dann ist die interessante Frage, ob in
   Schritt 3 überhaupt konvertiert wurde (eine PDF aus dem Cache konvertiert
   nicht).

**Was ich übernehme.** Die Evidenzzeile füllen, und falls die alte Datei
liegen bleibt, die Fehlersuche — der Sweep ist zehn Zeilen, und
`office.cache_days = 0` schaltet ihn ganz ab, was ein guter Gegentest ist.

### 3. Ein Auto-Modus pro Zieltyp

**Dein Entwurf (2026-09-03).** Von selbst hovern sollen nur **Bilder und
PDFs**. Textdateien hinter Markdown-Links und Pfade im Fließtext sollen
einzeln dazuschaltbar sein; „alles an" und „alles aus" soll es weiter geben;
und in der User-Config soll man den Default setzen können.

**Meine Einschätzung: ja, und aus einem Grund, der stärker ist als Geschmack.**
Ein Bild oder eine PDF-Seite ist das Einzige, was der Hover zeigt und was man
sonst *gar nicht* sieht, ohne die Datei zu öffnen. Die ersten Zeilen einer
Textdatei sind eine Abkürzung, kein neuer Anblick. Der Nutzen pro Unterbrechung
ist damit über die Zieltypen sehr ungleich verteilt, und das ist genau die
Achse, an der ein automatischer Trigger geschnitten gehört.

**Was es heute schon gibt — und warum das nicht dasselbe ist.** Die Schalter
sind nach **Fundort** organisiert: `links.enabled` (Markdown-Links),
`paths.enabled` (Pfade im Fließtext), `positions`, `office`, `git`. Dein
Wunsch ist nach **Zieltyp** — und ein Markdown-Link kann auf ein Bild *oder*
auf eine Textdatei zeigen. Die beiden Achsen kreuzen sich also; mit den
heutigen Schaltern ist „nur Bilder, egal wie gefunden" nicht ausdrückbar.

**Mein Vorschlag, konkret.** Eine neue Option neben `mode`, kein neuer Modus:

```lua
require("hover").setup({
  mode = "auto",              -- bleibt der Hauptschalter: auto | manual | off
  auto = { "image", "pdf" },  -- was im auto-Modus von selbst aufgehen darf
})
```

- `auto = true` — alles, das heutige Verhalten und der Default, bis du etwas
  anderes sagst.
- `auto = false` — nichts von selbst; identisch zu `mode = "manual"`.
- `auto = { … }` — eine Liste von Zieltypen (`image`, `pdf`, `office`, `file`,
  `directory`, `url`, `git`, `position`).

Dazu eine Route zum Umschalten während der Sitzung, in der Form, die es schon
gibt (`:Hover links web on`):

```
:Hover auto image on
:Hover auto file off
```

**Zwei Dinge, die ich dabei ehrlich sagen muss.**

1. **Es gibt dann zwei Wege, etwas nicht zu sehen** — `paths.enabled = false`
   und `auto` ohne `file`. Sie bedeuten Verschiedenes, und das gehört
   dokumentiert: `paths.enabled = false` heißt, ein Pfad im Fließtext ist
   *gar kein Ziel* — auch `:Hover show` findet dort nichts. Das `auto`-Gate
   heißt nur, dass der Trigger nicht von selbst fragt; auf `:Hover show`
   bekommst du die Vorschau trotzdem. Das ist eine echte Unterscheidung, keine
   Dopplung — aber eine, die man erklären muss.
2. **Gespart wird das Float, nicht die Arbeit davor.** Um zu wissen, dass
   etwas ein Bild ist, muss der Pfad aufgelöst werden — die Treesitter-Prüfung
   und ein `fs_stat` laufen also weiter. Beides ist gemessen billig (die
   Zahlen stehen im Modulkopf von `hover.bare_path`), aber wer sich davon eine
   *Beschleunigung* verspricht, bekommt eine Beruhigung.

**Deine Aufgabe.** Sagen, ob der Vorschlag so passt — insbesondere, ob `auto`
als Liste von Zieltypen die richtige Form ist, und ob der Default zunächst
`true` bleiben soll (alles wie bisher) oder gleich auf `{ "image", "pdf" }`
gehen soll.

**Was ich übernehme.** Den Bau: Option, Normalisierung der Legacy-Formen,
Route mit Completion, `:checkhealth`-Zeile, Specs, und die Doku in README,
Vimdoc und BINDINGS — die Doku-Spec sagt mir dabei, was ich vergessen habe.

### 4. language.nvim: ein Wörterbuch im Hover

**Erst, was das überhaupt heißt** — die alte Formulierung war unverständlich,
und das war mein Fehler.

language.nvim ist ein Plugin für *natürliche Sprache*: es kann zu einem Wort
die Rechtschreibung, die Grammatik, eine Übersetzung oder Synonyme zeigen.

hover.nvim kann fremde Plugins nach der Stelle fragen, an der der Cursor steht
(„position preview" — documentation.nvim und insights.nvim machen das schon).
Wenn language.nvim sich so anmeldet, dann heißt das: **du stehst mit dem
Cursor auf irgendeinem Wort in einem Fließtext, und es geht ein Float auf, das
dir dieses Wort erklärt.** Nicht auf einem Pfad, nicht auf einem Link — auf
einem gewöhnlichen Wort in einem gewöhnlichen Satz.

**Warum das eine Frage ist und keine Aufgabe.** Bei allem anderen, was dieser
Hover zeigt, gibt es eine billige Prüfung, ob überhaupt etwas da ist: ein Pfad
muss auf eine existierende Datei zeigen, eine URL muss eine URL sein, ein
Container-Image muss wie eines aussehen. Deshalb bleibt der Hover in Prosa
still. **Bei einem Wörterbuch ist jedes Wort ein Treffer** — es gibt keine
Prüfung „lohnt sich hier ein Wörterbuch?", die nicht das Wörterbuch selbst
wäre. Also gibt es nur zwei Zustände: bei *jedem* Wort geht etwas auf, oder es
geht nur auf Nachfrage auf — und dann bei jedem Wort, das du fragst.

**Was sich seit `ac0a372` verbessert hat.** Vorher gewann der erste
registrierte Beitrag, und ein Wörterbuch hätte damit unter `:Hover show` alles
andere verdeckt. Heute wird geblättert (`<M-n>`), es darf hinten stehen und
verdeckt nichts mehr. Der Einsatz der Entscheidung ist also deutlich kleiner
geworden.

**Deine Aufgabe: drei Fragen.**

1. Willst du auf ein Wort zeigen und eine Erklärung bekommen — in Prosa, in
   Markdown, in Kommentaren?
2. Wenn ja: nur auf ausdrückliche Nachfrage (`:Hover show`), oder auch von
   selbst? (Meine Empfehlung: nur auf Nachfrage, und zwar bevor es überhaupt
   gebaut wird.)
3. Und wenn Punkt [3](#3-ein-auto-modus-pro-zieltyp) kommt: soll ein
   Wörterbuch dort ein eigener Zieltyp sein, den man einzeln zuschaltet?

**Was ich übernehme.** Die Verdrahtung, sobald die Antwort ja ist. Sie ist
dieselbe Form wie insights.nvim und sandbox.nvim, beide sind vorgemacht, und
die Regel dafür — wann ein Wort nachschlagenswert ist — gehört nach
language.nvim, nicht hierher.

### Was ich ohne dich tun würde

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
