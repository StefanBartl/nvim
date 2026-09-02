# hover.nvim — Roadmap (persönlich)

## Table of content

  - [Intro](#intro)
  - [1. Abgrenzung: was in welche der beiden Roadmaps gehört](#1-abgrenzung-was-in-welche-der-beiden-roadmaps-gehrt)
  - [2. Was ich als Nächstes bauen würde, in dieser Reihenfolge](#2-was-ich-als-nchstes-bauen-wrde-in-dieser-reihenfolge)
    - [2.1 Ein Spec, das die Doku gegen die Quelle prüft — **gebaut** (`4e1760f`)](#21-ein-spec-das-die-doku-gegen-die-quelle-prft-gebaut-4e1760f)
    - [2.2 Zoom für Bilder — **Schritte 1 und 2 gebaut** (`204d083`)](#22-zoom-fr-bilder-schritte-1-und-2-gebaut-204d083)
      - [Die ursprüngliche Reihenfolge, zur Begründung](#die-ursprngliche-reihenfolge-zur-begrndung)
    - [2.3 Eine `:checkhealth`-Zeile für `contribute` — **gebaut** (`aca73fa`)](#23-eine-checkhealth-zeile-fr-contribute-gebaut-aca73fa)
    - [2.4 gopath: ein billiger Früh-Ausstieg — fremdes Repo, größter Hebel hier](#24-gopath-ein-billiger-frh-ausstieg-fremdes-repo-grter-hebel-hier)
    - [2.5 Ein Memo für Position-Previews — **gemessen, und die Antwort ist nein**](#25-ein-memo-fr-position-previews-gemessen-und-die-antwort-ist-nein)
  - [3. Messungen, die offen sind](#3-messungen-die-offen-sind)
  - [4. Aufträge, die woanders liegen](#4-auftrge-die-woanders-liegen)
  - [5. Geprüft und *nicht* aufgenommen](#5-geprft-und-nicht-aufgenommen)

---

## Intro

Stand: **2026-09-02**. Angelegt als Auftrag E aus der Sitzung vom selben Tag;
seither sind [2.1](#21-ein-spec-das-die-doku-gegen-die-quelle-prüft--gebaut-4e1760f),
die Tastenhälfte von [2.2](#22-zoom-für-bilder--schritte-1-und-2-gebaut-204d083)
und [2.3](#23-eine-checkhealth-zeile-für-contribute--gebaut-aca73fa) gebaut und
die LuaLS-Messung nachgeholt worden.

Danach war der nächste Griff **eine Messung, keine Implementierung** — und die
ist gelaufen: [2.5](#25-ein-memo-für-position-previews--gemessen-und-die-antwort-ist-nein)
ist gemessen und **abgelehnt**, mitsamt einem Auftrag, der dabei herausfiel und
in [Abschnitt 4](#4-aufträge-die-woanders-liegen) steht.

**Damit ist Abschnitt 2 leer.** Was offen bleibt, wartet auf etwas, das nicht
hier liegt: [2.4](#24-gopath-ein-billiger-früh-ausstieg--fremdes-repo-größter-hebel-hier)
auf gopath.nvim, ein neuer Auftrag auf documentation.nvim. Der zweite neue,
**sandbox.nvim, ist noch am selben Tag erledigt worden** (`deb45bc`).

Die dritte der offenen Messungen — die einzige, die dich nicht braucht — ist
seither gelaufen: der **`on_request`-Pfad gegen eine echte Engine**
(`b7c4c45`), diesmal als wiederholbare Sonde statt ad hoc, mit der Zeile im
Repo statt nur hier. Sie hat drei Dinge gefunden, alle im
[Handover unter J](./hover.nvim.md#j-die-on_request-messung-gelaufen-und-sie-hat-drei-dinge-gefunden-b7c4c45-e62f5e9):
einen sandbox.nvim-Auftrag (Abschnitt 4), eine vierte Wiederholung der
Doku-Drift-Klasse, und dass **die LuaLS-Messung flackert**.

**Damit brauchen beide verbliebenen Messungen dich** (Demo-GIF, Office-Pfad
von Hand) — siehe [Abschnitt 3](#3-messungen-die-offen-sind).

Drei Dokumente, drei Adressaten — das ist der Grund, warum es diese Datei
überhaupt gibt:

| Datei | Adressat | Frage |
| --- | --- | --- |
| [hover.nvim.md](./hover.nvim.md) | ich, beim Wiedereinstieg | **was ist passiert und warum** |
| `hover.nvim/docs/ROADMAP.md` | wer mitliest oder das Plugin benutzt | **was ist bewusst noch nicht gebaut** |
| diese hier | ich, beim Weiterbauen | **was würde ich als Nächstes tun, und warum das** |

---

## 1. Abgrenzung: was in welche der beiden Roadmaps gehört

Das ist der eigentliche Auftrag hinter E — ohne Regel driften die zwei
auseinander, und genau das war am 2026-09-02 schon passiert: die Repo-Datei
führte sandbox.nvim als offen, obwohl seit `3647a17` verdrahtet.

| | Repo-Roadmap | diese Datei |
| --- | --- | --- |
| **Inhalt** | ein Konzept, und was vorher entschieden sein müsste | Aufwand/Nutzen, meine Empfehlung, die Reihenfolge |
| **Erledigtes** | wird **gelöscht** — die Datei führt keine Haken | bleibt stehen, mit Commit: der Wert ist die Begründung, nicht der Status |
| **Zahlen** | so viel, wie die Entscheidung trägt | die Messung selbst, mit Datum und Maschine |
| **Fremde Repos** | höchstens „blockiert, und zwar nicht auf unserer Seite" | mit konkretem Auftrag und Adressat |
| **Unfertiges** | gehört nicht hinein | gehört hierher, ausdrücklich als solches markiert |

**Die Regel gegen Drift: jeder Punkt lebt in genau einer der beiden.** Wird
etwas veröffentlichungsreif, *wandert* es ins Repo und hinterlässt hier eine
Zeile mit Commit — es wird nicht kopiert. Zwei Fassungen desselben Punktes
sind der Anfang jeder Drift, und diese Sitzung hat vier davon gefunden.

---

## 2. Was ich als Nächstes bauen würde, in dieser Reihenfolge

---

### 2.1 Ein Spec, das die Doku gegen die Quelle prüft — **gebaut** (`4e1760f`)

> **Erledigt am 2026-09-02**, in der Folgesitzung.
> `hover.nvim/TESTS/docs_spec.lua`, neun Prüfungen; die Tabelle dazu steht im
> [Handover unter G](./hover.nvim.md#g-ein-spec-das-die-doku-gegen-die-quelle-prüft--erledigt-2026-09-02-4e1760f).
> Die Begründung unten bleibt stehen — sie ist der Wert dieses Eintrags, nicht
> der Haken.
>
> **Was der Einbau gefunden hat**, alles behoben im selben Commit: das Vimdoc
> nannte neun beanspruchbare Zieltypen statt zehn (`git` fehlte, obwohl
> `registry.preview_for` auch dafür läuft), `docs/INTEGRATIONS.md` nannte den
> Befehl `:Hover off`, den es nicht gibt, und `docs/installation.md` sprach
> von „all seven switches" auf der Seite, die `:Hover status` erklärt.
>
> **Zwei Abweichungen vom Vorschlag unten.** Die Zieltypen werden nicht gegen
> `classify` geprüft, sondern gegen die deklarierte Union `Hover.Target.type`
> — `classify` erzeugt neun der zehn, `git` kommt aus `bare_git`, und geprüft
> gehört, was der Dispatcher zu sehen bekommt. Dazu kamen drei Prüfungen, die
> hier nicht standen: jede ausgeschriebene Schalterzahl in jedem Dokument, die
> Augroup-Tabelle und die Highlight-Tabelle. Die letzten beiden, weil genau
> dort der jüngste Fehler saß (`87a1017`).

**Der Anlass ist gezählt, nicht befürchtet.** Am 2026-09-02 waren gleichzeitig
falsch: die Schalterliste von `hover.set()` im Vimdoc (sieben von neun), drei
handgezählte Zahlen in `docs/INTEGRATIONS.md`, eine Überschrift dort („the only
registry contributor today", bei sechs), und in `docs/ROADMAP.md` „Four of the
candidates are built" bei fünf.

Vier Stellen, eine Klasse — dieselbe, die den Code dreimal getroffen hat
(`usrcmds.route_path`, `switches.effective`, `preview/office.lua`), nur eine
Stufe schlechter: **im Code deckt irgendwann eine Spec sie auf, in der Doku
niemand.**

Was ohne Markdown-Parser prüfbar ist:

- **Die Schalternamen im Vimdoc** gegen `switches.names()`. Eine Zeile, per
  Pattern extrahiert, als Menge verglichen.
- **Die `:Hover`-Routentabelle** in README und Vimdoc gegen das, was
  `usercmd.composer` tatsächlich registriert. Die Routen-Deklaration ist Daten;
  daraus eine Namensmenge zu ziehen ist billig.
- **Die Zieltypen, die ein Preview beanspruchen kann** (`image`, `pdf`, …)
  gegen `classify`.

**Nicht** prüfbar und deshalb bewusst außen vor: die Integrations-Tabellen. Sie
beschreiben fremde Plugins, und ein Spec, das dafür alle sechs lädt, prüft die
Installation statt die Doku.

**Aufwand:** ein Spec-File, drei Extraktoren. **Nutzen:** die einzige Klasse,
die sich hier vierfach wiederholt hat, wird ab dann laut. **Empfehlung: als
Erstes** — es ist die Voraussetzung dafür, dass alles Folgende dokumentiert
*bleibt*, statt dokumentiert worden zu sein.

*Tatsächlich geworden: ein Spec-File, acht Extraktoren, neun Prüfungen — die
Schätzung lag zu niedrig, weil beim Schreiben drei weitere prüfbare Listen
auffielen. Inzwischen dreizehn: `204d083` brachte zwei Tastentabellen mit, und
die erste Frage danach war „prüft das jemand?"; `b7c4c45` zwei weitere, weil
`docs/MANUAL-EVIDENCE.md` als einziges Dokument außerhalb der Reichweite lag
und prompt gedriftet war. Genau dafür war der Punkt hier der erste.*

---

### 2.2 Zoom für Bilder — **Schritte 1 und 2 gebaut** (`204d083`)

> **Erledigt am 2026-09-02.** `+` und `-` über eine eigene Leih-Bedingung;
> `hover.zoom(delta)` ist öffentlich. Offen bleiben **3 (Mausrad)** und **4
> (scharfes PDF)**, beide jetzt in `hover.nvim/docs/ROADMAP.md` — sie sind
> Konzepte mit einer offenen Vorfrage, und damit gehören sie dorthin.
>
> **Die Messung, die die Bauform entschieden hat** (echtes Neovim,
> 1200×675-Bild, Defaults 80×20, 2026-09-02):
>
> | Terminal | Schritte hinein | Bildfläche |
> | --- | --- | --- |
> | 210×55 | fünf | 71×20 → 181×51 Zellen |
> | 80×24 | **keiner** | 20 Zeilen sind schon `lines - 4` |
>
> Daraus: **keine Zoom-Grenze im Code**, weil jede Zahl auf einem der beiden
> falsch wäre. Ein wirkungsloser Schritt wird zurückgenommen. Die 1,25 pro
> Schritt kommen aus derselben Messung — bei 1,5 wären es zwei Schritte statt
> fünf, also ein Schalter statt eines Reglers.
>
> **Punkt 2 war wie vermutet die eigentliche Arbeit**, nur mit einer anderen
> Bedingung als hier angenommen: `content.canvas`, nicht `content.image_path`
> — das ist, was der Zoom ändert, und es deckt die PDF-Seite mit ab. Der
> Sabotage-Test bestätigt die Falle: hängt man den Zoom an `content.scroll`,
> fällt es in beide Richtungen gleichzeitig.
>
> **Und ein Nachtrag zur Reihenfolge unten:** die PDF-Kollision, mit der
> „Bilder zuerst" begründet war, gibt es nicht. Sie galt für die
> Scroll-Tasten; Zoom hat eigene. PDF-Seiten zoomen seither mit, gratis und
> unscharf.

---

#### Die ursprüngliche Reihenfolge, zur Begründung

Der Umfang steht (Auftrag F im Handover): **Bilder und Screenshots**,
PDF-Seiten optional, Text gar nicht. Die technische Fassung steht dort
ausführlich und im Repo kurz. Hier nur, was die Reihenfolge bestimmt:

1. **`+` / `-` über die bestehende Leihe** (`bindings/keymaps.lua`). Braucht
   weder `getmousepos()` noch `mouse=a` noch ein fokussierbares Float. Der
   ganze Zoom ist dann `_open.zoom` → `preview_opts` → die zwei Schranken in
   `canvas_cells`.
2. **Eine eigene Leih-Bedingung für Bilder.** `keys.borrow` installiert für ein
   Bild heute *gar nichts*, weil es an `content.scroll` hängt und ein Bild das
   nicht hat. Das ist die eigentliche Arbeit — nicht das Zeichnen.
3. **Mausrad** als Kür, mit `getmousepos()` in einer globalen Map.
4. **PDF scharf** nur, wenn es sich ergibt: `render_page` nimmt `opts.dpi`, und
   der Seiten-Cache müsste das DPI in den Schlüssel nehmen (heute Pfad, mtime,
   Seitennummer).

**Aufwand:** 1+2 klein, 3 mittel, 4 klein-aber-eigen. **Empfehlung:** 1 und 2
zusammen, dann benutzen, bevor 3 kommt.

*1 und 2 sind zusammen gebaut (`204d083`). „Dann benutzen, bevor 3 kommt"
steht — und die Zeile in `docs/MANUAL-EVIDENCE.md` ist bewusst auf `never`
datiert: gemessen ist die Geometrie, gesehen hat das Bild in der größeren
Fläche noch niemand.*

---

#### Die Tastenfrage für Schritt 3, entschieden am 2026-09-02

**Anlass:** beim Nachlesen fiel auf, dass `zoom_keys` in den Config-Notes
(`docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/hover.nvim.md`) **gar nicht
standen** — seit `204d083` geliehen, in hover.nvims eigener `docs/BINDINGS.md`
dokumentiert, in meiner Übersicht nicht. Nachgetragen; die Akkord-Tabelle
steht dort.

Was für den Ausbau feststeht, als Aussage über **diese** Config:

| Akkord | Status |
| --- | --- |
| `<C-+>` / `<C-->` | **ausgeschlossen** — allgemeines Fenster-Zoom |
| `<C-ScrollWheel>` | **ausgeschlossen** — dieselbe Erwartung, auch wo es hier nicht zoomt |
| `<M-->` | **vergeben** (cascade.nvim, Bullet Points) und bleibt |
| `<M-+>` | frei, aber ohne Partner — ein Regler mit einer Richtung ist keiner |
| `<M-ScrollWheelUp/Down>` | **frei, und damit der Kandidat für Schritt 3** |
| `<S-+>` / `<S-->`, `<C-S-+>` / `<C-S-->` | frei, **aber ungeprüft** |

**Die ungeprüfte Stelle.** Neovim nimmt `<S-+>` an und hält es von `+`
getrennt (mit `maparg` nachgemessen). Ob das *Terminal* es sendet, ist eine
andere Frage: auf deutscher Tastatur ist Shift+`+` das Zeichen `*`, und ohne
Kitty-Keyboard-Protokoll kommt nie ein `<S-+>` an. WezTerm kann das Protokoll
— plausibel, ungeprüft, und der Test kostet eine Minute
(`:nnoremap <S-+> :echo "kommt an"<CR>`). **Erst messen, dann darauf bauen.**

**Und das eigentlich Fehlende ist kein Akkord, sondern eine Route.**
`hover.zoom(delta)` ist öffentlich, aber es gibt **keine `:Hover`-Route**
dafür — anders als bei `scroll`. Damit ist Zoom heute *nur* über die geliehene
Taste erreichbar, also nur, solange ein Float mit Bild offen ist und nur mit
`+`/`-`. Ein `:Hover zoom in|out` wäre der kleinere Bau als das Mausrad und
löst das Akkord-Problem ganz, weil es keinen braucht. **Empfehlung: die Route
vor dem Mausrad**, und `<M-ScrollWheelUp/Down>` danach.

---

### 2.3 Eine `:checkhealth`-Zeile für `contribute` — **gebaut** (`aca73fa`)

> **Erledigt am 2026-09-02.** `registry.contributors()`, zwei Health-Zeilen,
> sieben Specs; die Einzelheiten stehen im
> [Handover unter H](./hover.nvim.md#h-eine-checkhealth-zeile-für-contribute--erledigt-2026-09-02-aca73fa).
>
> **Gegen die eigene Empfehlung gebaut.** Unten stand „sobald `contribute` das
> erste Mal wirklich benutzt wird", und benutzt worden ist es nicht. Das ist
> keine Kleinigkeit, sondern genau die Umgehung, gegen die die Hausregel
> geschrieben ist — festgehalten, damit die nächste Lesung dieser Datei nicht
> glaubt, der Vorbehalt sei eingetreten.
>
> **Was die Vermutung dann doch getragen hat:** `has_sources()` ist die
> Funktion, die auf „ist meiner registriert?" zu antworten scheint, und sie
> antwortet in *beide* Richtungen falsch — `false` für einen Beitrag, der ein
> Position-Preview ist, `true` (über markdown.nvim) für einen, der nie ankam.
> Beides steht jetzt als Spec da. Das war unten nicht aufgeschrieben und ist
> das eigentliche Argument für den Punkt gewesen.
>
> **Zwei Abweichungen vom Vorschlag unten.** Es ist nicht *eine* Health-Zeile,
> sondern eine je registriertem Namen plus eine für den leeren Fall; und der
> Accessor gibt Zahlen statt Funktionen zurück, weil er sonst ein zweiter Weg
> wäre, einen Beitrag aufzurufen — außerhalb des `pcall`, der einen kaputten
> Beitrag vom Rest fernhält.

Seit `c374d5e` kann ein Nutzer einen Hover aus der eigenen Config beitragen.
Die erste Frage danach ist „ist meine Funktion überhaupt registriert?", und
darauf gibt es heute **keine Antwort**: der Healthcheck meldet unter „optional
contributors" nur, ob *eine* Link-Source existiert.

Es fehlt ein Accessor in der Registry — `contributors()`, Namen plus Anzahl je
Art. Den gibt es bewusst noch nicht: das Modul hatte bisher keine
Introspektion, und eine ohne Konsumenten wäre Ballast. Jetzt gäbe es einen.

**Aufwand:** ein Accessor, eine Health-Zeile, ein Spec. **Empfehlung: bauen,
sobald `contribute` das erste Mal wirklich benutzt wird** — vorher ist es eine
Vermutung darüber, was jemand fragen wird.

---

### 2.4 gopath: ein billiger Früh-Ausstieg — fremdes Repo, größter Hebel hier

Der Befund ist gemessen und steht seit `c9faf86` in gopaths eigener Doku: ein
**fehlschlagendes** `resolve_at_cursor` kostet **13,2 ms**, ein erfolgreiches
deutlich unter 500 µs. Weil der automatische Trigger überwiegend Prosa sieht,
sind die Fehlschläge die Population.

Deshalb fragt hover auf dem Timer nur, wenn der Token nach etwas aussieht, das
gopath lösen könnte (`...` / `…`, oder gar kein Slash). **Das kostet echte True
Positives:** ein relativer Pfad, der irgendwo sonst im Projekt liegt, hovert
automatisch nicht mehr — nur noch auf `:Hover show`.

Bekommt gopath einen billigen „dieser Token kann nicht auflösen"-Ausstieg,
**fällt `gopath_can_help` ersatzlos weg**, und diese True Positives kommen
zurück. Es ist der einzige Punkt der Liste, dessen Nutzen hier entsteht und
dessen Arbeit woanders liegt.

**Adressat:** gopath.nvim. **Empfehlung:** dort einplanen, hier nichts tun —
die Gate-Zeile ist richtig, solange die Messung gilt.

---

### 2.5 Ein Memo für Position-Previews — **gemessen, und die Antwort ist nein**

> **Gemessen am 2026-09-02.** Beide Messungen stehen im
> [Handover unter I](./hover.nvim.md#i-die-messung-für-25--gelaufen-und-die-antwort-ist-nein),
> die Werkzeuge unter `nvim/scripts/hover-position-probe/`.
>
> **Die Wiederholung ist real und ungebremst.** Ein Ask pro Tastendruck-und-
> Ruhe, ausnahmslos, ob der Cursor sich bewegt hat oder nicht; `position_at`
> läuft vor jeder Unterdrückungsprüfung, und ein offenes Float hält nichts auf
> (ein *gepinntes* schon). Im skriptgesteuerten Lauf: 16 Asks, 7 verschiedene
> Schlüssel, **9 Wiederholungen**. Die Quote ist mein Gestenmix, nicht der
> eines Menschen — welche Gesten wiederholen, steht im Handover.
>
> **Und trotzdem nein, weil die zweite Messung die erste erledigt hat.** Ein
> Ask kostet mit allen drei echten Beiträgen **26,3 µs**. Bei
> `updatetime = 200` sind das ~132 µs/s, **0,013 % eines Kerns** — gegen ein
> fehlschlagendes `gopath.resolve_at_cursor` mit 13,2 ms, dem 500-fachen der
> ganzen Pipeline. Ein Memo spart davon einen Bruchteil und handelt sich die
> Fehlerfläche ein, die der Text unten selbst benennt: ein veralteter Eintrag
> wäre eine *falsche* Antwort, keine alte. **Keine Häufigkeit könnte das
> drehen**, und deshalb ist die Zählung, die hier gefordert war, nicht mehr
> nötig.
>
> **Ein Detail, das die Bauform betroffen hätte:** ein rein zeilenweiser
> Schlüssel träfe öfter (11 statt 9) und wäre falsch — drei der vier
> ausgelieferten Beiträge lesen das Token *unter* dem Cursor. Die Spalte
> gehört in den Schlüssel, falls der Punkt je wiederkommt.
>
> **Fast danebengegriffen:** der erste Durchlauf tastete Spalte 0 ab und ergab
> 3,7 µs — Faktor 7 zu schön, weil Spalte 0 Einrückung ist und beide
> Token-Prüfungen dort sofort ablehnen. Eine Kostenmessung muss dort messen,
> wo der Cursor steht.

`position_at` fragt bei jedem Trigger jeden Beitrag erneut. Gecacht wird
bewusst nichts: eine Position hat keine Identität, an der ein Cache hinge, und
was ein Position-Preview sagt, kann vom ganzen Buffer abhängen — ein veralteter
Eintrag wäre eine *falsche* Antwort, keine alte.

Der Gedanke: ein Memo über `(bufnr, row, col, changedtick)` hat genau diese
Schwäche nicht, weil `changedtick` jede Bufferänderung erfasst. Und
`CursorHold` feuert nach *jedem* Tastendruck gefolgt von Ruhe, Cursorbewegung
oder nicht — derselbe Beitrag wird an derselben Stelle also wiederholt gefragt.

**Hier greift die Hausregel.** Drei Messungen in diesem Repo haben der
Intuition widersprochen, die sie prüfen sollten; zweimal war die naheliegende
Lösung die falsche. Ungemessen ist das eine Vermutung über eine Wiederholung,
deren Häufigkeit ich nicht kenne. **Erst zählen** — wie oft wird dasselbe
`(bufnr, row, col, changedtick)` in einer echten Sitzung zweimal gefragt —,
dann entscheiden.

---

## 3. Messungen, die offen sind

| Was | Warum offen |
| --- | --- |
| ~~**LuaLS**~~ | **zu**, aber mit einem neuen Vorbehalt. Fünfmal auf dem Haupt-Checkout gemessen: `post-b` nach `3e12c9f`, `post-c` nach `4e1760f`, `post-d` nach `aca73fa`, `post-e`/`post-e2` nach `b7c4c45`, `post-f` nach `e62f5e9`. **`post-e` meldete 1 Befund auf Quelltext, den der Commit nicht angefasst hatte; `post-e2` auf identischem Baum meldete 0.** Der Scan ist also nicht deterministisch — ein einzelner `+1` ist kein Beweis, ein zweiter Lauf kostet eine Minute und entscheidet. Die Stelle ist mit `e62f5e9` festgenagelt. Die Regel bleibt: **nicht den Worktree scannen** (doppelte Library-Injektion → ~100 unechte `duplicate-doc-field`). |
| **Office-Pfad von Hand** | `docs/MANUAL-EVIDENCE.md`: seit der Cache-Änderung `bba2064` nicht wieder durchgespielt. Keine CI kann das. |
| **Demo-GIF** | `REL-09`, der letzte offene 🟢 des Release-Gates. **Braucht dich** — ich kann nicht aufnehmen. |
| ~~**`on_request` gegen einen laufenden Daemon**~~ | **zu.** Am 2026-09-02 gegen Docker Engine 29.5.3 gelaufen, jetzt als Sonde (`hover.nvim/scripts/onrequest_probe.lua`) statt ad hoc, mit der Zeile in `docs/MANUAL-EVIDENCE.md` statt nur im Handover. 566/558/294/0 ms, Engine-Aufrufe 2/2/1/0, auf dem automatischen Trigger jedes Mal still. Wieder fällig, wenn sich am `on_request`-Pfad etwas ändert — der Lauf kostet eine Minute. |

---

## 4. Aufträge, die woanders liegen

- **bindings-explorer.nvim** — `:Bindings check` deckt die BINDINGS-Tabellen von
  Composer-Plugins **nicht** ab, sieht aber so aus, als täte es das. Verglichen
  wird gegen `nvim_get_commands()`; dort steht nur `Hover`, und alle fünfzehn
  Routenzeilen fallen darauf zusammen. Betrifft jedes Plugin auf
  `usercmd.composer`. Gemessen am 2026-09-02: eine Zeile gelöscht, beide Läufe
  melden „keine Drift". In der Sache dasselbe wie 2.1, eine Ebene höher.
- **gopath.nvim** — siehe 2.4.
- ~~**sandbox.nvim**~~ — **erledigt am 2026-09-02** (sandbox.nvim `deb45bc`).
  `engine_utils.get_engine()` wählte nach reiner PATH-Anwesenheit und fragte
  nie, ob die Engine antworten kann; hier gewann podman mit gestoppter VM,
  jeder Ask lehnte nach ~370 ms still ab, die laufende Docker-Engine wurde nie
  gefragt. Jetzt nimmt die Erkennung die erste **antwortende** Engine —
  `get_live_engine`, faul und pro Sitzung gemerkt, weil eine Lebendprüfung
  ~385 ms kostet und beim Start nichts zu suchen hat. Eine *benannte* Engine
  (`opts.engine`, `.sandboxrc`, `:Sandbox engine set`) wird nie geprüft: das
  ist eine Anweisung, keine Vermutung. Verifiziert mit derselben Sonde, die
  den Fehler fand — sie wählt jetzt docker und antwortet. Zwei Funde nebenbei:
  `container_commands_buffer` las `config.options.engine` direkt und ignorierte
  damit still beide Overrides, und der LuaLS-Scan des Repos stand auf 5 statt
  0 (vier davon aus `3647a17`, nach dem „auf 0"-Commit hereingekommen und nie
  gescannt). Alles behoben, Scan wieder 0.
- **documentation.nvim** — `find_map` in `lua/documentation/hover.lua:54` steigt
  bis zu **24 Verzeichnisebenen** mit je einem `uv.fs_stat` nach
  `docs/map/module_map.json` auf, **ohne negativen Cache**: `_maps` merkt sich
  nur erfolgreiche Ladungen. In jedem Projekt ohne generierte Map — hover.nvim
  selbst ist eines — zahlt jeder einzelne Position-Ask den vollen Aufstieg.
  Gemessen am 2026-09-02: **24,2 von 26,3 µs der gesamten Pipeline, 92 %**,
  gegen 1,0 µs für spotlight.nvim und 2,4 µs für migrate.nvim. Dieselbe Form
  wie 2.4 — der Nutzen entsteht hier, die Arbeit liegt dort. Ein negativer
  Cache pro Startverzeichnis genügt.
- **language.nvim** — die Produktfrage *vor* der Integration: soll ein Druck auf
  `:Hover show` mitten in Prosa immer ein Wörterbuch aufmachen? Der Mechanismus
  (`on_request`) existiert seit `731bbe2`; was fehlt, ist eine Regel dafür, wann
  ein Wort nachschlagenswert ist, und die gehört dorthin.
- **insights.nvim** — braucht einen Cache-Index, bevor „wer importiert dieses
  Modul" eine Hover-Frage sein kann. Jede Abfrage scannt heute neu.

---

## 5. Geprüft und *nicht* aufgenommen

- **Text-Zoom.** Die Schriftgröße gehört dem Terminal-Emulator. „Zoom" hieße
  dort „größeres Float", also *mehr* statt *größer* — ein anderes Feature, das
  auch anders heißen müsste.
- **`contribute` auch für Plugins.** Alle Nutzerbeiträge teilen sich den Namen
  `"user"`; zwei Aufrufer löschen einander still. Ein Plugin hat `register` mit
  eigenem Namen, und das ist kein Umweg, sondern der Punkt.
- **Ein zweiter Cache für Office-Konvertierungen.** Der bestehende überlebt seit
  `bba2064` die Sitzung. Mehr wäre eine Lösung ohne gemessenes Problem.
- **Ein Health-Check, der die Testsuite fährt.** Steht als abgelehnt in der
  Repo-Roadmap und bleibt dort: er würde über die Maschine berichten, auf der
  er zufällig läuft, statt über die Installation.

---

