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
| **Zyklomatische Komplexität** | klassische Statik-Metrik (McCabe), kein Doxygen-Feature | längste/verschachteltste Funktionen, reiner `vim.treesitter`-Zähler über `if`/`elseif`/`while`/`for`/`repeat`/`and`/`or` je Funktionskörper — kein externes Tool nötig |
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
erstes eingehängtes Werkzeug (da ohnehin als Nächstes geplant, siehe unten) →
R4/R6 nachziehen (billig, bereits vorhandene Daten) → zyklomatische
Komplexität als erstes wirklich neues Werkzeug, danach neu bewerten, ob
Duplikate/Churn echten Bedarf treffen.

**Nicht jetzt, nur notiert:** Lizenz-/Abhängigkeits-Scanning (für eine
in sich geschlossene Lua-Utility-Bibliothek ohne externe Paketabhängigkeiten
nicht relevant), Stilkonsistenz-Analyse (Namenskonventionen etc. — das ist
`luacheck`/`stylua`s Job, nicht docmaps).

---

## Kandidaten, priorisiert

| # | Feature | Vorbild | Aufwand | Einschätzung |
|---|---|---|---|---|
| R1 | Cross-Projekt-Tag-Dateien | Doxygen `TAGFILES` | M | **✅ Erledigt (2026-07-28, `0c67b50`)** |
| R2 | Auto-erkannte Testabdeckung | — (eigene Idee) | S–M | **✅ Erledigt (2026-07-28, `ba919c2`)** |
| R3 | Modul-/Namespace-A-Z-Index | Doxygen File/Class Index | S | Empfehlenswert, günstig |
| R4 | Doku-Abdeckung als Zahl + Badge | — (eigene Idee, auf Findings aufbauend) | S | **✅ Erledigt (2026-07-28, `a467e49`)** |
| R5 | `param-name-mismatch`-Check | — (Erweiterung von `undocumented-param`) | S | **✅ Erledigt (2026-07-28, `f353a16`)** |
| R6 | Fan-in/Fan-out-Hotspot-Übersicht | — (auf `node.stats` aufbauend) | M | Später, wenn Bedarf konkret wird |
| R7 | Volltext-Suche (Prose, `@param`-Text) | Doxygen Search-Index | M | Später |
| R8 | `@group`/`@ingroup` (virtuelle Gruppen quer zur Modulstruktur) | Doxygen `\defgroup` | L | Eher nicht — kein aktueller Bedarf |
| R9 | `ctags`-Export (`:LibMap tags`) | ctags/gutentags | S | Eher nicht — LSP deckt das schon ab |
| R10 | Live-Diagramm-Reload bei `:LibBrowse live` auch für die HTML-Seite | — | M | Eher nicht — zwei offene Prozesse synchron zu halten lohnt den Aufwand nicht |

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

### R6–R10 — kurz begründet

- **R6 Hotspot-Übersicht** (meist-gebrauchtes Modul, größte Funktion nach
  Zeilen, höchster Fan-in): `node.stats` und `ir.edges` liefern die Rohdaten
  bereits, aber ohne konkreten Anlass (niemand hat bisher gefragt "welches
  Modul bricht am meisten, wenn ich es anfasse") ist das Spekulation auf
  Vorrat — zurückgestellt, nicht verworfen.
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

## Empfehlung für die nächste Runde

**R1 → R2 → R5 → R3 → R4**, in dieser Reihenfolge: R1 ist die einzige Idee,
die direkt auf der gerade abgeschlossenen O1-Arbeit aufbaut und ohne sie
wenig Sinn ergäbe; R2 und R5 sind kleine, in sich abgeschlossene
Check-Ergänzungen nach demselben Muster wie `dead-function`/`dead-see-target`;
R3/R4 sind günstige UI-Ergänzungen, die auf bereits vorhandenen Daten
aufbauen. R6–R10 bleiben Backlog, nicht weil sie schlecht wären, sondern weil
für keine davon bisher ein echter Schmerzpunkt aufgetreten ist — derselbe
Maßstab, an dem D4/O2 in `docmodule.md` schon gemessen wurden.
