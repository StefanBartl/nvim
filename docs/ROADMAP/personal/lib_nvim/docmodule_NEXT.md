# docmap — was als Nächstes, mit Blick auf Doxygen & Co.

Fortsetzung von [`docmodule.md`](docmodule.md), das mit "praktisch alles
geplante ist ✅" endete (Stand 2026-07-28, `476d62e`). Diese Datei ist der
Neustart: nicht "was war noch offen", sondern "was fehlt noch, wenn man
`docmap` gegen Doxygen und verwandte Werkzeuge hält" — bewusst getrennt von
der Historie in `docmodule.md`, damit die (jetzt über 1250 Zeilen lange)
chronologische Datei nicht weiterwächst.

**Methode:** Doxygens Feature-Liste durchgegangen (Quelle: eigene Kenntnis +
`doxygen.nl/manual/features.html`-Struktur), jedes Feature gegen das
abgeglichen, was `docmap` bereits hat (siehe `lib.nvim`s
`lua/lib/nvim/docmap/README.md`), plus ein Seitenblick auf drei verwandte,
aber andersartige Werkzeuge:
**ctags/gutentags** (reine Sprung-Datenbank, kein Rendering), **Sourcetrail**
(interaktiver Graph-Explorer, kein Doku-Generator), **LDoc/LuaDoc** (Lua-native
Doxygen-Alternativen, textuell, keine Graphen). Jede Idee unten sagt explizit,
welches Vorbild sie hat und warum sie (nicht) lohnt — im Stil der bereits
getroffenen Nicht-Entscheidungen (D4, O2) in `docmodule.md`: eine begründete
Ablehnung ist genauso ein Ergebnis wie ein Task.

## Was schon Doxygen-Parität hat (zur Einordnung, nicht neu)

Call-/Include-Graphen, Klassenhierarchie, Kollaborationsdiagramm (Types-View),
Todo/Bug/Test/Deprecated-Listen, A-Z-Funktionsindex, Cross-Referenzen (`@see`),
Diff zwischen Revisionen (Doxygen hat das *nicht* — eigene Ergänzung), Graphviz-
Export. Fehlt bewusst: Quelltext-Browser (D4), PDF/LaTeX/RTF-Export (keine
realistische Zielgruppe für ein Neovim-Plugin), Doxywizard-artige GUI-Konfig
(widerspricht der `config.lua`-als-Code-Philosophie).

---

## Ein fünfter Tab: "Analysis" — ein Werkzeugkasten statt Einzelfeatures

Nutzeranfrage (2026-07-28): ein fünfter Tab neben Tree/Hierarchy/Notes/Index,
der beim Anklicken eine eigene Sub-Toolbar aufklappt — verschiedene
"Analyse-Werkzeuge" nebeneinander, von einfach (Testabdeckung) bis komplexer,
was für Lua-Softwareprojekte sinnvoll sein kann. Bewusst mit Blick auf
Doxygen & Co., aber auch mit eigenen, neuen Ideen.

**Warum ein eigener Tab und nicht vier Einzelfeatures verstreut über Header,
Notes und Findings:** R2 (Testabdeckung), R4 (Doku-Abdeckung), R5
(Parameter-Namensabgleich) und R6 (Fan-in/Fan-out-Hotspots) — alle vier
bereits weiter unten als Einzelkandidaten gelistet — sind strukturell
dasselbe: eine Kennzahl oder ein Ranking, berechnet über die bereits
vorhandene IR, ohne eigene Graph-Darstellung. Sie einzeln im Header, in Notes
und in Findings zu verstreuen ist genau das Muster, das beim Notes-Tab schon
einmal bewusst vermieden wurde ("vier Tabs, die meist leer sind, sind vier
Tabs Rauschen" — dieselbe Begründung gilt hier für vier verstreute
Kennzahlen statt eines Orts, an dem man sie erwartet).

**Architektur:** kein neues UI-Paradigma nötig — genau das Muster, das der
Hierarchy-Tab schon hat. Dort wählt eine Toolbar zwischen fünf *Views*
(Modules/Types/Inheritance/Deps/Calls), die dieselbe Box-Layout-Engine
unterschiedlich befüllen. Analysis wählt zwischen mehreren *Panels*, die
keine Graph-Boxen zeichnen, sondern Tabellen/Listen/einfache Balken — näher
am Notes-Tab als am Hierarchy-Tab, UI-technisch also eher "ein Panel-Slot mit
Werkzeugauswahl" als "ein Diagramm mit View-Achse". Jedes Werkzeug ist eine
reine Funktion `ir -> Ergebnis`, dieselbe Form wie ein `Lib.Docmap.Check`,
nur dass das Ergebnis eine Tabelle statt eine Finding-Liste ist — passt zur
bestehenden `extra_checks`-Erweiterbarkeit, ein `extra_analyses`-Äquivalent
wäre naheliegend, damit auch ein konsumierendes Plugin eigene Werkzeuge
andocken kann, im selben Geist wie `opts.extra_checks`.

### Werkzeug-Kandidaten

| Werkzeug | Vorbild / Herkunft | Nutzen für Lua-Projekte |
|---|---|---|
| **Testabdeckung** | eigene Idee (R2 unten) | welche Funktionen tauchen in keiner Spec auf |
| **Doku-Abdeckung** | eigene Idee (R4 unten) | eine Zahl statt verstreuter Findings |
| **Parameter-Drift** | Erweiterung von `undocumented-param` (R5) | Doku, die dem Code hinterherhinkt |
| **Fan-in/Fan-out-Hotspots** | eigene Idee (R6) | "was bricht am meisten, wenn ich es anfasse" |
| **Zyklomatische Komplexität** | klassische Statik-Metrik (McCabe), kein Doxygen-Feature | **✅ Erledigt (2026-07-28, `fd27b90`)** |
| **Code-Duplikate** | PMD/CPD-artig ("Copy-Paste-Detector"), kein Doxygen-Feature | strukturelle Ähnlichkeit von Funktionskörpern über einen Baum von ~250 Dateien — genau das Muster, das in einer Utility-Bibliothek am ehesten unbemerkt entsteht |
| **Churn-Hotspots (Git-Historie × Komplexität)** | Adam Tornhills "Your Code as a Crime Scene", kein Doxygen-Feature | Module, die *oft geändert werden* **und** *komplex sind* — der eigentliche Refactor-Risiko-Indikator, den weder Abdeckung noch Komplexität allein zeigen |
| **God-Module-Geruch** | eigene Idee, verwandt mit `layer-violation` | Module mit ungewöhnlich hohem Fan-out (requiren fast alles) — Kandidat für Aufspaltung |
| **API-Stabilität über Zeit** | eigene Idee, baut auf `diff.lua` | wie oft ändert sich die öffentliche Oberfläche über die letzten N Commits — nutzt die bereits vorhandene Diff-Maschinerie mehrfach hintereinander |
| **Verwaiste Module** | Verfeinerung von `unreferenced-module` | dediziertes, browsbares Ranking statt einer Zeile in Findings |

### Einordnung — was zuerst

Nicht alles auf einmal: **Testabdeckung, Doku-Abdeckung und
Fan-in/Fan-out-Hotspots** (R2/R4/R6) sind die einzigen drei, die schon heute
mit vorhandenen Daten auskommen (keine neue Extraktion nötig). **Zyklomatische
Komplexität** ist der günstigste *neue* Rohdaten-Kandidat — ein einziger
zusätzlicher `vim.treesitter`-Query, dieselbe Kategorie Aufwand wie
`identifier_counts` in `calls.lua`. **Code-Duplikate** und
**Churn-Hotspots** sind die aufwendigsten (Baum-Ähnlichkeitsvergleich bzw.
`git log`-Auswertung über die Zeit) und lohnen erst, wenn der Tab selbst
schon existiert und benutzt wird — sonst ist die Reihenfolge verkehrt
(zuerst das teuerste Werkzeug bauen, bevor klar ist, ob der Tab überhaupt
gebraucht wird).

**Empfohlene Reihenfolge, wenn der Tab drankommt:** Tab-Grundgerüst (leerer
Werkzeugkasten mit Umschalter, nach dem Hierarchy-Toolbar-Muster) → R2 als
erstes eingehängtes Werkzeug → R4 nachziehen → zyklomatische Komplexität als
erstes wirklich neues Werkzeug, danach neu bewerten, ob Duplikate/Churn
echten Bedarf treffen.

**Umgesetzt (2026-07-28, `2b9ac67`):** Tab-Grundgerüst + R2 + R4 als die
ersten beiden Werkzeuge, siehe Abschnitt weiter unten. R6 (Fan-in/Fan-out)
und zyklomatische Komplexität bleiben die nächsten Kandidaten für diesen Tab.

**Nicht jetzt, nur notiert:** Lizenz-/Abhängigkeits-Scanning (für eine
in sich geschlossene Lua-Utility-Bibliothek ohne externe Paketabhängigkeiten
nicht relevant), Stilkonsistenz-Analyse (Namenskonventionen etc. — das ist
`luacheck`/`stylua`s Job, nicht docmaps).

---

# Konzept: Commit-Historie mit Ausstrahlung ("wohin wirkt dieser Diff")

Nutzeranfrage (2026-07-28): ein "Git"/"Repository"-Tab, der alle Commits
auflistet, in die man hineinklicken kann (Message, Metadaten, Diff), mit dem
eigentlichen Zusatzfeature: **wenn ein Commit eine Funktion ändert, zeigen,
welche Module diese Funktion aufrufen** — also nicht primär der geänderte
Code, sondern *wohin diese Änderung ausstrahlt*.

Die Idee ist gut und trifft eine echte Lücke: `:LibMap diff <ref>` sagt heute,
was sich an der *Form* des Baums geändert hat (Module/Funktionen dazu/weg,
Abhängigkeiten, Zyklen), aber nicht, was ein konkreter Zeilendiff an
*Aufrufern* berührt. Vor einem Plan stehen aber drei Befunde, von denen einer
die naheliegendste Umsetzung ausschließt.

> **Korrektur (2026-07-28, nach Rückfrage):** Die erste Fassung dieses
> Kapitels hat aus Befund 1 zu viel gefolgert — nämlich dass die
> Browser-Ansicht insgesamt problematisch sei. Das stimmt nicht. Befund 1
> gilt ausschließlich fürs **Einbetten ins committete Artefakt**. Holt man
> die Daten stattdessen **dynamisch beim Klick**, entfällt er vollständig,
> weil dann gar nichts committet wird. Befund 1b/1c unten klären, was
> "dynamisch" konkret erfordert — und die Empfehlung unten ist entsprechend
> umgedreht.

## Befund 1: Commit-Historie kann nicht ins `--check`-Artefakt *eingebettet* werden

Das ist kein Aufwands-, sondern ein Struktur-Problem, und es schließt genau
eine Variante aus: das statische Mitschreiben der Historie in `index.html`
(also "noch ein Tab wie Notes/Index/Analysis", mit den Daten fest drin):

`--check` vergleicht das committete Artefakt **byteweise** mit einer frisch
generierten Fassung. Enthielte das Artefakt `git log`-Daten, dann gilt:

1. Commit N wird erstellt → `HEAD` ist jetzt N
2. Eine Neugenerierung enthielte jetzt Commit N — das committete Artefakt
   (generiert als `HEAD` noch N−1 war) aber nicht
3. → Artefakt sofort nach *jedem* Commit stale, Hook/CI rot
4. Reparatur = neuer Commit = wieder stale

Es gibt **keinen Fixpunkt**: der Inhalt des Artefakts hinge vom Hash des
Commits ab, der das Artefakt enthält. Auch "alles außer HEAD einbetten" hilft
nicht (verschiebt die Regress nur um eins). Der einzige stabile Schnitt wäre
eine eingefrorene Grenze — was den Zweck aufhebt.

**Konsequenz:** die anderen vier Tabs sind *immer aktuell, committet und
geprüft*. Ein History-Tab kann das per Konstruktion nicht sein. Er wäre eine
konzeptionell andere Art Artefakt — das ist die zentrale Entscheidung, die
vor der Umsetzung bewusst getroffen werden muss, nicht nebenbei.

## Befund 2: der Diff-Text wird von den Artefakten selbst dominiert

Gemessen am letzten Commit (`fd27b90`):

| | Größe |
|---|---|
| voller `git show` | **4,8 MB** |
| ohne `docs/map/` | **15,8 KB** |

Faktor ~300. Jeder docmap-Commit schleppt das regenerierte `index.html` +
`module_map.json` mit. Zwei Folgerungen:

- Jede Diff-Anzeige **muss `opts.out_dir` ausschließen**, sonst zeigt sie fast
  ausschließlich generiertes Rauschen.
- "Alle Diffs einbetten" ist damit ohnehin erledigt — selbst ohne Befund 1.
  Einzubetten wäre die *Analyse* (welche Funktionen berührt, wer ruft sie),
  nicht der Diff-Text; für den Text existiert mit `opts.repo_url`/`srcUrl()`
  bereits die GitHub-Verlinkung, und lokal kann `git show` in einen Buffer.

## Befund 3: die nutzbare Historientiefe ist begrenzt (und messbar)

Die Funktions-Auflösung alter Zeilennummern hängt daran, dass jeder Commit
sein eigenes Artefakt mitbringt (derselbe Trick, den `diff.lua` schon nutzt:
`git show <ref>:docs/map/module_map.json`). Das geht aber nicht beliebig weit
zurück:

| Ab wann | Commits |
|---|---|
| Repository gesamt | 202 |
| Artefakt existiert (`910a26b`, 19.07.) | 126 |
| **Artefakt enthält Funktionen (`8362f89`, 21.07.)** | **92** |
| Schema 2 (`51ece89`, 27.07.) | 50 |

Die ersten committeten Maps sind Schema 1 **ohne** `functions` — für Commits
davor ist Funktions-Granularität schlicht nicht rekonstruierbar. Das ist kein
Fehler, sondern derselbe Fall, den `diff.lua` bereits sauber behandelt
("Dependencies, cycles and impact are not comparable" statt stillschweigend
Unvergleichbares zu vergleichen). Ein History-Werkzeug muss genauso ehrlich
degradieren: unterhalb der Grenze Commit + Message + Dateiliste, aber keine
Funktions-Ausstrahlung.

## Was schon existiert — die Hälfte "Ausstrahlung" ist fertig

Der eigentlich interessante Teil der Idee ist bereits gebaut:

| Baustein | Wo |
|---|---|
| direkte Aufrufer einer Funktion | `ir.edges`, `kind="call"`, `to`/`to_fn` |
| Blast-Radius eines Moduls (transitive Hülle `required_by`) | `deps.impact(ir, id)` |
| interaktiv im Editor | `:LibBrowse` `gI` |
| Fan-in-Ranking | Analysis-Tab, Dependencies-Panel (R6) |
| IR einer beliebigen Revision holen | `diff.lua` (`git show <ref>:…json`) |
| strukturelle Änderungen zwischen zwei Revisionen | `diff.compare` |

## Der einzige wirklich fehlende Baustein: `fn.line_end`

Um "Zeile 247 wurde geändert" → "das ist `M.scan_full`" aufzulösen, braucht
es den Zeilen*bereich* jeder Funktion. Aktuell wird nur `fn.line` (Startzeile)
serialisiert — der Endwert existiert beim Scan bereits (`ranges` in
`functions.lua` führt `{ name, srow, erow }` für genau diesen Zweck für
`calls.lua`), wird aber nicht in die `FunctionInfo` übernommen.

Das ist eine Ein-Feld-Ergänzung, exakt wie `complexity` gerade eine war: die
Daten liegen an derselben Stelle schon vor.

Die Diff-Seite ist ebenfalls billig: `git diff --unified=0` liefert exakte
Zeilenbereiche (verifiziert):

```
@@ -2003 +2003,47 @@     alt: Zeile 2003, neu: Zeilen 2003–2049
@@ -2034,0 +2082,3 @@     rein additiv ab Zeile 2082
```

Alte Zeilen werden gegen die IR von `<ref>~1` aufgelöst, neue gegen die von
`<ref>` — beide über den bereits etablierten `git show`-Trick.

**Kostenmessung:** ein historisches Artefakt holen dauert 0,27 s (1 MB JSON).
Für die vollen 92 auflösbaren Commits also grob 25–50 s plus Parsen — d.h.
**definitiv opt-in**, niemals Teil eines normalen `:LibMap`-Laufs.

## Drei mögliche Orte, mit Abwägung

### A) `:LibMap impact <ref>` → Quickfix-Liste

Kein Artefakt, keine Staleness, passt exakt in die bestehende
Kommando-Familie (`why`, `diff`, `dot`). Rechnet live für *einen* Commit
(oder Range): welche Funktionen berührt, wer ruft sie, welche Module strahlt
es an. Quickfix ist in diesem Repo bereits der etablierte Ort für "alles
Betroffene" (`gq`, `gI`, `why`).

**Dafür:** billigster echter Nutzen, sofort einsetzbar im Review-Alltag
("was fasse ich mit diesem Commit alles an").
**Dagegen:** kein Browsen, keine Liste, kein Diff-Viewer — nicht das, was
die Anfrage beschreibt.

### B) `:LibBrowse`-Modus (Editor-seitiger Commit-Browser) — **empfohlen**

`:LibBrowse` ist bereits ein Drill-down-Navigator mit Modi (`1`…`4`:
Structure/Deps/Calls/Types) — ein fünfter Modus "History" fügt sich exakt
ein. Commits als Liste, `<CR>` steigt in einen Commit, die berührten
Funktionen werden zur Liste, `<CR>` darauf zeigt deren Aufrufer, `gq`
schickt alles in die Quickfix-Liste, `gd` springt in die Quelle.

**Dafür:** git ist live verfügbar → **kein Staleness-Problem, kein
Artefakt**; Diff-Text kostenlos via `git show` in einen Buffer (und `gd`
springt in echte Dateien mit LSP — genau die Begründung, mit der schon der
HTML-Quelltext-Browser D4 verworfen wurde); die Kosten aus Befund 3 fallen
nur beim tatsächlichen Öffnen an, nicht bei jeder Generierung; passt zum
Selbstverständnis "nicht das Diagramm im Terminal, sondern das, was der
Editor besser kann".
**Dagegen:** kein Web-UI.

### C) HTML-"History"-Tab als **separat generiertes, gitignoriertes** Artefakt

Bekommt das visuelle Tab-Erlebnis der Anfrage, aber nur unter der Bedingung
aus Befund 1: eigene Datei (z.B. `docs/map/history.html`), **nicht committet,
nicht in `--check`**, erzeugt durch ein explizites `:LibMap history [N]`.
Eingebettet würde nur die Analyse (Commit-Metadaten + berührte Funktionen +
deren Aufrufer, grob geschätzt ~1 KB/Commit → ~100 KB für 92 Commits, neben
1,5 MB `index.html` unkritisch); der Diff-Text bliebe extern über
`repo_url` verlinkt.

**Dafür:** genau die beschriebene Oberfläche, teilbar/versendbar.
**Dagegen:** bricht die Eigenschaft "jeder Tab ist aktuell, committet,
geprüft"; veraltet ab dem nächsten Commit stillschweigend (bräuchte also
mindestens einen sichtbaren Stand-Hinweis, wie `:LibBrowse` ihn beim
Artefakt-Modus schon zeigt); zweiter Generierungspfad zu pflegen.

## Empfohlener Phasenplan

Die Phasen sind bewusst so geschnitten, dass jede für sich Nutzen liefert und
die Entscheidung B-vs-C erst am Ende fällt — wenn das Fundament steht und
sich zeigt, ob das Quickfix-Ergebnis den Bedarf schon deckt.

**Phase 1 — Fundament (klein, testbar, kein UI):**
1. `fn.line_end` in `functions.lua`/`@types` ergänzen (Daten liegen in
   `ranges` bereits vor), `to_json` mitziehen.
2. Neues `history.lua`, **pur** im Stil von `diff.lua` (kein git, kein
   Dateisystem — nur Daten rein, Struktur raus): `hunks + IR → berührte
   Funktionen`, und darauf aufbauend `→ direkte Aufrufer → betroffene
   Module`. Das git-Holen bleibt wie bei `diff.lua` in `command.lua`.
3. Test gegen echte Fixtures im `docmap_spec.lua`-Stil: Hunk-Bereich auf
   Funktion abbilden, inklusive der Ränder (Zeile == `line`, Zeile ==
   `line_end`, rein additiver Hunk `@@ -x,0 +y,n @@`).

**Phase 2 — erster echter Nutzen:** `:LibMap impact <ref>` (Variante A).
Klein, sofort brauchbar, deckt "wohin strahlt dieser Commit aus" bereits ab.

**Phase 3 — Browsing:** dann entscheiden. Empfehlung **B** (`:LibBrowse
history`), weil es das Staleness-Problem vollständig umgeht, den Diff-Text
gratis bekommt und dieselbe Begründung trägt, mit der D4 (HTML-Quelltext-
Browser) schon einmal zugunsten des Editors verworfen wurde. **C** bleibt
möglich, wenn ausdrücklich das Web-UI gewünscht ist — dann aber bewusst als
separates, gitignoriertes Artefakt mit sichtbarem Stand-Hinweis.

---

## Kandidaten, priorisiert

| # | Feature | Vorbild | Aufwand | Einschätzung |
|---|---|---|---|---|
| R1 | Cross-Projekt-Tag-Dateien | Doxygen `TAGFILES` | M | **✅ Erledigt (2026-07-28, `0c67b50`)** |
| R2 | Auto-erkannte Testabdeckung | — (eigene Idee) | S–M | **✅ Erledigt (2026-07-28, `ba919c2`)** |
| R3 | Modul-/Namespace-A-Z-Index | Doxygen File/Class Index | S | **✅ Erledigt (2026-07-28, `eb25ca9`)** |
| R4 | Doku-Abdeckung als Zahl + Badge | — (eigene Idee, auf Findings aufbauend) | S | **✅ Erledigt (2026-07-28, `a467e49`)** |
| R5 | `param-name-mismatch`-Check | — (Erweiterung von `undocumented-param`) | S | **✅ Erledigt (2026-07-28, `f353a16`)** |
| R6 | Fan-in/Fan-out-Hotspot-Übersicht | — (auf `n.requires`/`n.required_by` aufbauend) | S–M | **✅ Erledigt (2026-07-28, `ef36780`)** |
| R7 | Volltext-Suche (Prose, `@param`-Text) | Doxygen Search-Index | M | Später |
| R8 | `@group`/`@ingroup` (virtuelle Gruppen quer zur Modulstruktur) | Doxygen `\defgroup` | L | Eher nicht — kein aktueller Bedarf |
| R9 | `ctags`-Export (`:LibMap tags`) | ctags/gutentags | S | Eher nicht — LSP deckt das schon ab |
| R10 | Live-Diagramm-Reload bei `:LibBrowse live` auch für die HTML-Seite | — | M | Eher nicht — zwei offene Prozesse synchron zu halten lohnt den Aufwand nicht |
| R11 | Commit-Historie mit Ausstrahlung ("wohin wirkt dieser Diff") | — (eigene Idee; git-blame-artig, aber über den Call-Graph) | M–L | **Analysiert, Phasenplan steht — siehe eigenes Konzept-Kapitel oben** |

---

### R1. Cross-Projekt-Tag-Dateien — der naheliegendste nächste Schritt

Doxygens `TAGFILES` lässt ein Projekt in die generierte Doku eines anderen
projektfremden Symbols verlinken, statt sie nur als Text zu nennen. Genau das
fehlt `docmap` heute an der Stelle, wo es am meisten wehtun würde: seit O1
kann jedes Plugin, das `lib.nvim` einbindet, seine eigene Map erzeugen — aber
deren `requires_external`-Boxen (Deps-View, "+ external") sind tote Enden.
Ein Plugin, das `lib.nvim.fs` requires, sieht im eigenen Graphen nur eine
namenlose graue Box, obwohl `lib.nvim` selbst eine vollständige, generierte
Map dieses Moduls hat.

Umsetzung ohne neue Infrastruktur: `module_map.json` ist bereits das
komplette, deterministische Artefakt. Ein `opts.tag_files = { "lib.nvim" =
"https://stefanbartl.github.io/lib.nvim/module_map.json" }` (oder ein lokaler
Pfad) ließe `deps.build`/das Deps-View eine `requires_external`-Box gegen die
fremde IR auflösen und verlinken, statt sie inert zu lassen. Direkter Nutzen
für genau das Szenario, das O1 erst ermöglicht hat — mehrere eigene Plugins,
alle mit `docmap`, alle voneinander abhängig.

### R2. Auto-erkannte Testabdeckung statt manuellem `@test`

`@test` existiert bereits als Tag (siehe `ANNOTATIONS.md`), hat aber **0
Treffer** im echten Baum — niemand pflegt es manuell, was ehrlich gesagt zu
erwarten war (Doku-Tags, die eine zweite Quelle der Wahrheit neben dem
tatsächlichen Testfile sind, veralten). Stattdessen: `docmap` kennt bereits
jede Funktion und jeden Modulpfad; ein zusätzlicher Scan über
`docs/TESTS/*_spec.lua`, der prüft, welche Funktionsnamen dort *tatsächlich*
referenziert werden (dieselbe Technik wie `calls.lua`s `identifier_counts`,
nur gegen das Testverzeichnis statt gegen den Quellbaum selbst), würde
"getestet: ja/nein" ohne jede manuelle Pflege liefern — genau die Art
"gemessen, nicht angenommen"-Herangehensweise, die der Rest des Moduls schon
durchgehend verfolgt (`local_refs`, `dead-function`, `identifier_counts`).
Ersetzt `@test` nicht zwingend (ein manuelles Tag kann trotzdem etwas anderes
meinen als "irgendwo referenziert"), ergänzt es aber um die einzige Angabe, die
sich nie aus dem Tritt geraten kann.

### R3. Modul-/Namespace-Index neben dem Funktions-Index

Der Index-Tab (D3) deckt nur Funktionen ab — Doxygen hat daneben einen
eigenen "File Index" *und* "Class Index". `docmap`s Tree-Tab deckt das
strukturell ab (Baum statt Liste), aber es gibt keine flache A-Z-Liste aller
**Module** (nicht Funktionen) für den Fall "ich weiß den Modulnamen, aber
nicht wo er im Baum hängt". Billig, weil die Sortier-/Sprungbar-Logik aus
`bare()`/dem Index-Tab (D3) fast 1:1 wiederverwendbar ist.

### R4. Doku-Abdeckung als einzelne Zahl + Badge

`missing-summary`, `undocumented-param` und `missing-readme` sind heute
verstreute Findings — niemand sieht auf einen Blick "82% dokumentiert". Eine
aggregierte Prozentzahl (Funktionen mit vollständigen `@param`/`@return` ÷
alle Funktionen) im HTML-Kopf, optional als generierte SVG im
shields.io-Stil fürs README, macht daraus eine Zahl, die man über Zeit
verfolgen kann — und die bereits existierende `diff`-Funktion (Revisionen
vergleichen) bekäme damit fast geschenkt eine "Abdeckung hat sich um X%
verändert"-Zeile.

### R5. `param-name-mismatch` — `undocumented-param` schärfen

`undocumented-param` vergleicht heute nur die *Anzahl* der Parameter mit der
Anzahl der `@param`-Zeilen (bewusst als Heuristik, laut README). Ein
zusätzlicher, ebenso `info`-schwacher Check, der die *Namen* abgleicht (die
Signatur liegt über `vim.treesitter` schon vor), würde den häufigsten realen
Fehler fangen, den die reine Zählung übersieht: ein Parameter wurde umbenannt,
die Doku nicht mitgezogen. Gleiche Vorsicht wie beim bestehenden Check nötig
(nie über `info`, da text-basiert und auf komplexen Signaturen falsch liegen
kann).

### R6 — nächster Kandidat, umsetzungsbereite Spezifikation

**Ziel:** drittes Analysis-Tab-Werkzeug, "Fan-in/Fan-out" (Arbeitstitel;
Button-Label z.B. "Dependencies"), zeigt pro Modul, wie viele andere Module
es requiret (Fan-out) und wie viele es requiren (Fan-in) — beantwortet
"was bricht am meisten, wenn ich das hier anfasse" (hoher Fan-in) und
"was ist verdächtig verflochten" (hoher Fan-out).

**Warum jetzt dran:** einziges verbliebenes Werkzeug, das laut
"Einordnung"-Abschnitt oben ohne neue Datenextraktion auskommt — Fan-in/
Fan-out lässt sich vollständig aus bereits vorhandenem `n.requires`/
`n.required_by` ablesen (siehe `Lib.Docmap.Node` in `@types/init.lua`),
keine neue Lua-Berechnung nötig, nur JS-seitige Aggregation wie beim
Coverage-Panel.

**Umsetzungsplan (analog zum Coverage/Documentation-Panel-Bau in
`2b9ac67`):**
1. In `render/html.lua`: dritten Button `<button class="anview-btn"
   data-atool="deps">Dependencies</button>` im `#antoggle`-Toolbar
   ergänzen (nach dem Muster der bestehenden zwei Buttons).
2. `state.atool` um den Wert `"deps"` erweitern (`DEFAULT_STATE`,
   `serializeState`/`parseState`s `atool`-Zweig — dort steht aktuell nur
   `s.atool === "doc"`, muss auf drei Werte erweitert werden).
3. Eigene Render-Funktion (kein `renderAnalysisPanel`-Wiederverwendung,
   da das bestehende Panel auf *einer* pick-Funktion über Funktionen
   basiert, Fan-in/Fan-out aber Zahlen direkt aus `n.requires.length`/
   `n.required_by.length` liest, nicht aus `n.functions`): pro Modul zwei
   Spalten (Fan-in, Fan-out) statt Treffer/Gesamt, sortiert nach Fan-in
   absteigend (höchster Blast-Radius zuerst) — Klick-Navigation wie
   gehabt.
4. `drawAnalysis()`s if/else auf drei Zweige erweitern, dritten
   Cache (`analysisDepsHTML`) ergänzen.
5. Verifikation: gegen lib.nvims eigene Map im Browser (welches Modul hat
   den höchsten Fan-in? Plausibilitätscheck: sollte etwas Fundamentales
   wie `lib.nvim.fs`/`lib.nvim.notify` sein), Node-`--check`
   JS-Syntaxprüfung wie bei den vorherigen zwei Tools.

**Aufwand:** klein-mittel (S–M), da reine JS-Aggregation ohne neue
Lua-Datenextraktion — realistisch die schnellste der drei
Analysis-Tab-Ergänzungen nach R2/R4.
- **R7 Volltextsuche**: aktuell durchsucht die HTML-Suche Name/Modul/Summary,
  nicht Fließtext oder `@example`-Blöcke. Echter Mehrwert, aber die
  bestehende Suche deckt den Alltag (Modul/Funktion finden) schon ab — lohnt
  erst, wenn die Prosa-Menge im Baum spürbar wächst.
- **R8 `@group`/`@ingroup`**: Doxygens Feature für Gruppen quer zur
  Verzeichnisstruktur. Hoher Aufwand (neues Tag, neue Aggregation, neue View)
  für ein Bedürfnis, das in einem 250-Datei-Utility-Baum wie diesem noch nie
  aufkam — Module *sind* hier bereits die sinnvolle Gruppierung.
  Kandidat nur, falls das Repo mal so wächst, dass "alle öffentlichen
  APIs, modulübergreifend" eine echte Frage wird.
- **R9 ctags-Export**: klingt nach offensichtlichem Gewinn, ist es aber nicht
  — jeder Neovim-Nutzer mit LSP (also praktisch jeder, der `lib.nvim`
  überhaupt installiert) hat `gd`/`gr` bereits über `lua-language-server`,
  ohne dass docmap etwas exportieren müsste. Nur relevant für externe
  Nicht-LSP-Tooling, das hier niemand einsetzt.
- **R10 Live-Reload der HTML-Seite**: `:LibBrowse live` re-scanned schon im
  Editor; die HTML-Seite live nachzuführen bräuchte einen laufenden
  Prozess/Server, der bei jedem Save neu rendert und den Browser pusht —
  Aufwand und neue Fehlerquelle (Prozessverwaltung) für einen Fall, den
  `:LibBrowse live` im Editor bereits abdeckt, ohne einen Browser-Tab offen
  halten zu müssen.

---

## R1 — Umsetzung (2026-07-28, `0c67b50`)

`opts.tag_files: table<string, string>` (Modul-Präfix -> Verzeichnis mit einer
committeten `module_map.json` eines anderen Projekts). Ein
`requires_external`-Modul, das auf einen konfigurierten Präfix passt, wird
gegen die fremde Artefakt-Datei aufgelöst statt eine tote graue Box zu
bleiben — die Box wird durchgezogen/akzentfarben und öffnet beim Klick die
Seite des anderen Projekts an genau dem Knoten, in einem neuen Tab.

Neu: `lib.nvim`s `lua/lib/nvim/docmap/tagfiles.lua` mit `M.resolve(ir, opts)`,
`ir.tag_links` in `to_json` und im HTML-Payload
serialisiert, Auflösung über dieselbe Namens-Reihenfolge wie
`command.find_node` (deklariertes `@module`, rohe Node-ID,
Namespace-Fallback) — gegen die geladene fremde IR, nicht gegen die eigene.

Bewusst nur lokale Pfade, keine URLs: das Tag-File wird synchron während
`scan_full()` gelesen, genau wie `opts.root` selbst — ein Netzwerk-Fetch
hätte `--check` von deterministisch zu netzwerkabhängig gemacht, dieselbe
Begründung wie beim bewusst nicht an ein `dot`-Binary gekoppelten
DOT-Export.

Verifiziert: End-to-End-Test gegen einen echten zweiten gescannten Baum (kein
handgebautes JSON-Fixture) in `docmap_spec.lua`, zusätzlich manuell gegen
lib.nvims eigene, echte Map verifiziert (ein synthetisches Fixture-Plugin,
das `lib.nvim.fs.read` requiret, löst korrekt gegen `docs/map/module_map.json`
auf). `--check` grün, stylua/luacheck sauber (291 Dateien reposweit),
volle Testsuite grün. CI grün nach Push (`0c67b50`).

## R2 — Umsetzung (2026-07-28, `ba919c2`)

`coverage.lua` mit `M.resolve(ir, opts)` (setzt `fn.tested` auf jeder
Funktion, Abgleich gegen `opts.tests_dir`, Default `docs/TESTS`) und
`M.summary(ir)` (`tested, total`). Dieselbe Identifier-Zähltechnik wie
`calls.lua`s `identifier_counts`, nur über den Testbaum statt den
Quellbaum. `@test` selbst bleibt als manuelles Tag bestehen, hatte aber
**0** echte Treffer — dieser Mechanismus ersetzt die Notwendigkeit, es zu
pflegen, ohne das Tag selbst zu entfernen.

Bewusst asymmetrisch beim Rendern: nur ein positives "tested"-Badge
(Index-Tab, Funktions-Detail), nie ein "untested"-Warn-Badge — die
Heuristik hat einen echten, dokumentierten blinden Fleck (indirekt
getestete Funktionen, die nie namentlich in einer Spec auftauchen, bleiben
unsichtbar), und ein Warn-Badge auf der Mehrheit der ~600 Funktionen wäre
Rauschen, keine Information.

`:LibMap`/`gen_map.lua` drucken jetzt eine Zusammenfassungszeile:
`388/989 functions found by name in docs/TESTS (39%)` — lib.nvims eigene
aktuelle Zahl. Das ist absichtlich der erste Baustein für den geplanten
Analysis-Tab (siehe oben), aber schon jetzt ohne den Tab nutzbar.

Verifiziert: End-to-End-Test in `docmap_spec.lua` gegen eine echte
Spec-Datei-Fixture (nicht nur eine Namensliste), inkl. des
"tests_dir existiert nicht"-Falls. `--check` grün, stylua/luacheck
reposweit sauber (292 Dateien), volle Testsuite grün, CI grün.

## R5 — Umsetzung (2026-07-28, `f353a16`)

Neuer Check `param-name-mismatch` in `check.lua`, positional statt
mengenbasiert (Lua hat keine Keyword-Argumente — "die n-te `@param`-Zeile
beschreibt den n-ten Parameter" ist der eigentliche Vertrag, nicht "jeder
Doku-Name kommt irgendwo in der Signatur vor", was zwei vertauschte
Parameter durchwinken würde).

Ein echter Sonderfall musste behandelt werden, bevor der Check nutzbar war:
eine Doppelpunkt-Methode dokumentiert ihr eigenes `self` oft explizit
(legitimer LuaCATS-Stil), obwohl `self` im rohen Signatur-Text (Luas
Doppelpunkt-Zucker) gar nicht auftaucht — unkorrigiert hätte das *jede*
Doppelpunkt-Methode mit dokumentiertem `self` fälschlich gemeldet. Verifiziert
und gefixt gegen `lib.nvim`s eigene `Lru:get`/`Lru:put`.

**Beim ersten Lauf gegen den echten Baum zwei echte Bugs gefunden, keine
theoretischen**: `lua/lib/nvim/progress/styles/{float,kit}.lua`s
`bind_cancel_on_escape` hatte einen `bufnr`-Parameter bekommen, ohne dass
die `@param`-Zeile dafür ergänzt wurde — alle nachfolgenden Doku-Zeilen
waren dadurch stillschweigend um eine Position verschoben. Beide direkt
gefixt.

Verifiziert: Test in `docmap_spec.lua` inkl. des Self-Ausschluss-Falls,
`--check` grün, stylua/luacheck reposweit sauber, volle Testsuite grün,
CI grün.

## R4 — Umsetzung (2026-07-28, `a467e49`)

`doccoverage.lua` mit `M.summary(ir)` (`documented, total`) und
`M.badge_svg(ir)`. Definition "dokumentiert" bewusst deckungsgleich mit den
drei bereits existierenden Einzel-Findings (`missing-summary`,
`undocumented-param`, `param-name-mismatch`) statt einer zweiten,
möglicherweise abweichenden Logik — `check.declared_param_names` wurde dafür
aus `check.lua` exportiert. `@return` bewusst **nicht** Teil der Definition:
anders als bei Parametern gibt es in der rohen Signatur keine strukturelle
Tatsache, gegen die eine `@return`-Zeile geprüft werden könnte.

`opts.badge` (Default `false`) schreibt zusätzlich `coverage.svg` über das
neue `render/badge.lua` — handgebaut, nicht von shields.io selbst
abgerufen, dieselbe Begründung wie beim nicht an ein `dot`-Binary
gekoppelten DOT-Export: ein Netzwerkaufruf während `scan_full()` würde
`--check` von Netzwerkverfügbarkeit abhängig machen. `:LibMap`/`gen_map.lua`
drucken die reine Zahl immer, unabhängig von `opts.badge`.

lib.nvims eigene aktuelle Zahl: **666/997 (67%)** der veröffentlichten
Funktionen sind vollständig dokumentiert.

Verifiziert: Test in `docmap_spec.lua` inkl. Badge-SVG-Form und
-Prozentzahl, `--check` grün, stylua/luacheck reposweit sauber (294
Dateien), volle Testsuite grün, CI grün.

## Tag-Adoption — Umsetzung (2026-07-28, `7025e61`)

Vier Tasks, die parallel zu R1/R2/R5/R4 offen standen: die docmap-Tags
(`@todo`/`@bug`/`@internal`/`@see`/`@deprecated`), die laut
`ANNOTATIONS.md` alle bei **0 echten Treffern** standen, im tatsächlichen
`lib.nvim`-Code dort einführen, wo es echte Kandidaten gibt.

Ergebnis, ehrlich statt vollständig:

- **`@todo`/`@bug`**: nichts zu konvertieren. Grep nach reinen
  TODO/FIXME/HACK/XXX-Kommentaren im gesamten Baum fand nur
  Docstring-Beispiele, die `harvest`s eigenes TODO-Scan-Feature
  illustrieren — keine echten Marker.
- **`@deprecated`**: nichts Echtes gefunden. Jede "legacy"/"deprecated"-Erwähnung
  im Baum bezieht sich auf Neovim-eigene API-Deprecations, die umgangen
  werden, oder eine alte externe Aufrufkonvention, die aus
  Kompatibilitätsgründen noch gespiegelt wird — nie eine `lib.nvim`-Funktion,
  die durch eine andere tatsächlich ersetzt wurde.
- **`@internal`**: die eigene dokumentierte Konvention (`internal/`-Verzeichnis
  oder `_`-Präfix, `doc/lib.nvim.txt`s Conventions-Abschnitt) existierte
  schon auf Modulebene, hatte sich aber nie auf die Funktionsebene
  fortgepflanzt. Alle 15 exportierten Funktionen in
  `lua/lib/lua/time/diff/internal/*.lua` getaggt — dem einzigen echten
  `internal/`-Verzeichnis mit benannten (nicht anonymen) Funktionen. Deckte
  dabei zwei bereits tote Funktionen auf (`convert_batch`,
  `create_memoized_calculator`), die jetzt korrekt als `dead-function`-Finding
  erscheinen — bewusst nicht gelöscht, da Aufräumen nicht Teil dieses Tasks war.
- **`@see`**: ein klar 1:1 passendes Paar ergänzt, dessen Modul-Header sich
  bereits gegenseitig als "counterpart" beschreiben, aber nie auf
  Funktionsebene verlinkt waren: `fs.scan_cached.scan` ↔ `fs.scan_roots.scan`
  (session-lebendiger In-Memory-Cache vs. plattenpersistenter Cache
  desselben Walks). Gegen `dead-see-target` verifiziert — 0 Findings.

`--check` grün, stylua/luacheck reposweit sauber (294 Dateien), volle
Testsuite grün, CI grün.

## Zyklomatische Komplexität — Umsetzung (2026-07-28, `fd27b90`)

Viertes Analysis-Tab-Werkzeug, `fn.complexity` (McCabe): 1 Basis + ein
Punkt je `if`/`elseif`/`while`/`for`/`repeat`, plus ein Punkt je `and`/`or`
(ein Kurzschluss-Booleschoperator ist genauso eine Verzweigung wie ein
`if`). Neue `COMPLEXITY_QUERY` + `cyclomatic_complexity()` in
`functions.lua` — Knotentypen vorab empirisch gegen einen echten geparsten
Baum verifiziert, nicht geraten (`if_statement`, `elseif_statement`,
`while_statement`, `for_statement`, `repeat_statement`,
`(binary_expression "and"/"or")`).

Bewusst **unbedingt** während desselben Scans berechnet (nicht als
späterer `resolve()`-Schritt wie bei `fn.tested`/`fn.documented`): die
Berechnung braucht den Treesitter-Knoten selbst, der nur während dieses
einen Durchlaufs existiert. Zählt über den gesamten Teilbaum der Funktion
inklusive verschachtelter anonymer Closures — deren Verzweigungen muss der
Leser der äußeren Funktion trotzdem verstehen, und docmap scannt die
Closure ohnehin nicht als eigene Einheit.

Viertes Panel (`renderAnalysisComplexity`) rankt nach **Funktion**, nicht
nach Modul — das einzige Panel dieser Form, weil eine Durchschnittsbildung
pro Modul die eine wirklich komplexe Funktion in einem sonst gesunden
Modul verstecken würde.

Verifiziert: Knotentypen empirisch gegen echten Baum bestätigt, dedizierter
Test in `docmap_spec.lua` mit exakter erwarteter Zahl (if+elseif+while+for+
repeat+and+or+Basis = 8), im Browser durchgeklickt — höchste Komplexität im
echten `lib.nvim`-Baum: `docmap.command`s `M.setup` mit 104 (der
`:LibMap`-Subcommand-Dispatcher — genau die Art Funktion, die dieses
Ranking aufdecken soll). `--check` grün (0 errors, 0 warnings),
stylua/luacheck sauber, volle Testsuite grün, CI grün.

## R6 — Umsetzung (2026-07-28, `ef36780`)

Wie in der Spezifikation vorgesehen: drittes Analysis-Tab-Werkzeug
"Dependencies", reine JS-Aggregation über bereits vorhandenes
`n.requires`/`n.required_by` — keine neue Lua-Extraktion nötig, kein
Lua-Test nötig (rein clientseitig, gleiche Kategorie wie der R3-Umschalter).

Eigene Render-Funktion (`renderAnalysisDeps`) statt Wiederverwendung des
funktions-zählenden Panels: R6 zählt Kanten über den Knoten selbst, nicht
ein Boolean über dessen Funktionen. Sortiert nach Fan-in absteigend
(Tiebreak Fan-out) — das Modul mit den meisten Abhängigen zuerst, dieselbe
"folgenreichstes zuerst"-Regel wie bei den Prozent-sortierten
Coverage-Panels. `state.atool` von zwei- auf dreiwertig erweitert
(`test`/`doc`/`deps`).

Verifiziert im Browser: 241 Module mit mindestens einer Require-Kante,
höchster Fan-in ist `lib.nvim.notify` (30) — genau das erwartete Ergebnis
(ein fundamentales, breit genutztes Modul), Klick-Navigation bestätigt
`REQUIRED BY (30)` exakt. `--check` grün (0 errors, 0 warnings),
stylua/luacheck sauber, volle Testsuite grün, CI grün.

## R3 — Umsetzung (2026-07-28, `eb25ca9`)

Umschalter "Functions / Modules" im Index-Tab (`state.iview`), spiegelt das
Hierarchy-Toolbar-Muster. Zweiter Index über alle `module`/`namespace`-Knoten
(bewusst ohne `file`-Knoten — eine Datei wird über ihr Modul im Tree-Tab
erreicht), sortiert wie der Funktionsindex nach dem letzten Segment des
Modulpfads. Sortier-/Sprungbar-Logik aus dem Funktionsindex extrahiert
(`buildIndexBuckets`/`indexJumpBar`/`wireIndexBody`) statt dupliziert — genau
wie in der Ursprungsidee vorhergesagt. Verifiziert im Browser: 158
Module/Namespaces indiziert, Sprungleiste und Klick-Navigation funktionieren.

## Analysis-Tab — Umsetzung (2026-07-28, `2b9ac67`)

Fünfter Tab, wie oben entworfen: Werkzeugkasten-Toolbar statt Diagramm.
Zwei Werkzeuge live, beide auf bereits vorhandenen IR-Daten:

- **Test coverage** (R2) — `fn.tested`, pro Modul Treffer/Gesamt
- **Documentation** (R4) — `fn.documented`, neu: `doccoverage.lua` bekam
  `M.is_documented` (die eine Definition, auf der jetzt `M.resolve` UND
  `M.summary` aufbauen, damit sie nie auseinanderlaufen können) und
  `M.resolve`, das es in die IR stempelt — genau wie `coverage.resolve`
  das für `fn.tested` schon tut.

Beide Panels: pro Modul Treffer/Gesamt + Prozent + Balken, **schlechteste
zuerst** sortiert (Tiebreak: mehr betroffene Funktionen zuerst), Klick auf
eine Zeile öffnet das Modul im Tree-Tab. Das Documentation-Panel schließt
`@internal`-Funktionen aus den Summen aus — exakt wie `doccoverage.summary`
das selbst tut, verifiziert: CLI zeigt "653/984 (66%)", das Panel exakt
dieselbe Zahl. Bewusst nur zwei Werkzeuge — R6 und weitere sind echte
Kandidaten, haben aber noch keine in die IR gestempelten Daten; ein dritter
Button, der ein leeres Panel öffnet, wäre genau das, was die
"disabled mit Zähler"-Regel des Kontextmenüs an anderer Stelle vermeidet.

**Nebenbei gefunden und gefixt:** R3s Index-Umschalter fragte
`#ixtoggle .hview-btn` ab, um die Aktiv-Markierung zu setzen, aber die
Buttons hatten nur die Klasse `ixview-btn` (bewusst, um nicht mit dem
globalen `.hview-btn`-Klick-Handler zu kollidieren) — die aktive
Hervorhebung aktualisierte sich seit R3 nie wirklich. Selektor korrigiert.

Verifiziert: im Browser durchgeklickt (beide Panels, Sortierung,
Navigation, Zahlen gegen CLI abgeglichen), neuer Test in `docmap_spec.lua`
für `doccoverage.resolve`. `--check` grün, stylua/luacheck sauber (294
Dateien), volle Testsuite grün, CI grün.

## Stand 2026-07-28 — was als Nächstes (für eine Fortsetzung an anderer Stelle)

**Erledigt, alle verifiziert (`--check` grün, stylua/luacheck sauber,
Testsuite grün, CI grün) und gepusht:** R1 (`0c67b50`), R2 (`ba919c2`),
R3 (`eb25ca9`), R4 (`a467e49`), R5 (`f353a16`), Tag-Adoption (`7025e61`),
Analysis-Tab-Grundgerüst + erste zwei Werkzeuge (`2b9ac67`).

**R6 erledigt** (2026-07-28, `ef36780`) — siehe "R6 — Umsetzung" weiter
unten für Details.

**Zyklomatische Komplexität erledigt** (2026-07-28, `fd27b90`) — viertes
Analysis-Tab-Werkzeug, siehe "Zyklomatische Komplexität — Umsetzung"
weiter unten für Details.

**Nächster konkreter Schritt, in absteigender Priorität:**
- **R11 — Commit-Historie mit Ausstrahlung** (2026-07-28 analysiert, eigenes
  Konzept-Kapitel oben mit Phasenplan): Phase 1 (`fn.line_end` + pures
  `history.lua`) ist klein, testbar und ohne UI-Entscheidung umsetzbar —
  der beste nächste Schritt, wenn hier weitergemacht wird. Wichtig vorab
  lesen: Befund 1 (Historie kann strukturell nicht ins `--check`-Artefakt)
  bestimmt, welche der drei Umsetzungsvarianten überhaupt in Frage kommt.
- **Code-Duplikate** (PMD/CPD-artig) oder **Churn-Hotspots** als fünftes
  Analysis-Tab-Werkzeug — beide laut "Einordnung"-Abschnitt oben die
  aufwendigsten verbliebenen Kandidaten (Baum-Ähnlichkeitsvergleich bzw.
  `git log`-Auswertung über Zeit), noch keine umsetzungsbereite
  Spezifikation wie bei R6/Komplexität ausformuliert. Erst lohnend, wenn
  der Tab selbst (jetzt mit vier Werkzeugen) tatsächlich benutzt wird —
  siehe Begründung im "Einordnung"-Abschnitt.
- **R7** (Volltextsuche) — zurückgestellt, siehe Begründung oben.
- **R8/R9/R10** — bewusste Nicht-Entscheidungen, siehe Begründungen oben.
  Nur erneut aufgreifen, wenn sich die genannten Voraussetzungen ändern
  (R8: Repo wächst so, dass modulübergreifende API-Gruppen eine echte Frage
  werden; R9: jemand nutzt `lib.nvim` ohne LSP; R10: `:LibBrowse live`
  reicht nicht mehr aus).

**Nebenbei erledigt (2026-07-28, `ef4b430`):** die verbliebenen 10
`missing-summary`-Warnungen (letzte Warn-Findings von `--check` außer
Info-Meldungen) durch je eine Ein-Zeilen-Zusammenfassung behoben. `--check`
zeigt jetzt `0 errors, 0 warnings, 88 info`.

**Offene TaskList-Aufgabe (separat von diesem Dokument):** Task #7
"Runtime inspection of a loaded module" — bewusst zurückgestellt, siehe
Backlog-Abschnitt B1 in `docmodule.md`. Kein docmap-Feature, sondern ein
eigenständiges künftiges Werkzeug (`:LibInspect`-Arbeitstitel), da es Code
zur Laufzeit ausführen müsste (anderes Vertrauensmodell als der rein
statische Scanner) und nie in `--check` einfließen darf.
