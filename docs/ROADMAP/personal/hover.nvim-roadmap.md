# hover.nvim — Roadmap (persönlich)

Stand: **2026-09-02**. Angelegt als Auftrag E aus der Sitzung vom selben Tag;
in der Folgesitzung sind [2.1](#21-ein-spec-das-die-doku-gegen-die-quelle-prüft--gebaut-4e1760f)
und die Tastenhälfte von [2.2](#22-zoom-für-bilder--schritte-1-und-2-gebaut-204d083)
gebaut und die LuaLS-Messung nachgeholt worden. Nächster offener Punkt der
Reihenfolge: **2.3**.

Drei Dokumente, drei Adressaten — das ist der Grund, warum es diese Datei
überhaupt gibt:

| Datei | Adressat | Frage |
| --- | --- | --- |
| [hover.nvim.md](hover.nvim.md) | ich, beim Wiedereinstieg | **was ist passiert und warum** |
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

### 2.1 Ein Spec, das die Doku gegen die Quelle prüft — **gebaut** (`4e1760f`)

> **Erledigt am 2026-09-02**, in der Folgesitzung.
> `hover.nvim/TESTS/docs_spec.lua`, neun Prüfungen; die Tabelle dazu steht im
> [Handover unter G](hover.nvim.md#g-ein-spec-das-die-doku-gegen-die-quelle-prüft--erledigt-2026-09-02-4e1760f).
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
auffielen. Inzwischen elf: `204d083` brachte zwei Tastentabellen mit, und die
erste Frage danach war „prüft das jemand?". Genau dafür war der Punkt hier der
erste.*

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

### 2.3 Eine `:checkhealth`-Zeile für `contribute` — winzig, und die neue Zielgruppe braucht sie

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

### 2.5 Ein Memo für Position-Previews — **ungemessen**, und die Hausregel heißt erst messen

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
| ~~**LuaLS**~~ | **zu.** Zweimal auf dem Haupt-Checkout gemessen: Pass `post-b` nach `3e12c9f`, Pass `post-c` nach `4e1760f`. Beide 0 Befunde, Delta `+0`. Die Regel bleibt: **nicht den Worktree scannen** (doppelte Library-Injektion → ~100 unechte `duplicate-doc-field`). |
| **Office-Pfad von Hand** | `docs/MANUAL-EVIDENCE.md`: seit der Cache-Änderung `bba2064` nicht wieder durchgespielt. Keine CI kann das. |
| **Demo-GIF** | `REL-09`, der letzte offene 🟢 des Release-Gates. **Braucht dich** — ich kann nicht aufnehmen. |
| **`on_request` gegen einen laufenden Daemon** | einmal gemacht (Tabelle im Handover), aber genau dort saß `836a15a`, und keine CI hat einen Container-Daemon. |

---

## 4. Aufträge, die woanders liegen

- **bindings-explorer.nvim** — `:Bindings check` deckt die BINDINGS-Tabellen von
  Composer-Plugins **nicht** ab, sieht aber so aus, als täte es das. Verglichen
  wird gegen `nvim_get_commands()`; dort steht nur `Hover`, und alle fünfzehn
  Routenzeilen fallen darauf zusammen. Betrifft jedes Plugin auf
  `usercmd.composer`. Gemessen am 2026-09-02: eine Zeile gelöscht, beide Läufe
  melden „keine Drift". In der Sache dasselbe wie 2.1, eine Ebene höher.
- **gopath.nvim** — siehe 2.4.
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
