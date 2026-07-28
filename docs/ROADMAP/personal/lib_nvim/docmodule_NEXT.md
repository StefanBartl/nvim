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

## Kandidaten, priorisiert

| # | Feature | Vorbild | Aufwand | Einschätzung |
|---|---|---|---|---|
| R1 | Cross-Projekt-Tag-Dateien | Doxygen `TAGFILES` | M | **Empfehlenswert, naheliegend nach O1** |
| R2 | Auto-erkannte Testabdeckung | — (eigene Idee) | S–M | **Empfehlenswert** |
| R3 | Modul-/Namespace-A-Z-Index | Doxygen File/Class Index | S | Empfehlenswert, günstig |
| R4 | Doku-Abdeckung als Zahl + Badge | — (eigene Idee, auf Findings aufbauend) | S | Empfehlenswert |
| R5 | `param-name-mismatch`-Check | — (Erweiterung von `undocumented-param`) | S | Empfehlenswert |
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

## Empfehlung für die nächste Runde

**R1 → R2 → R5 → R3 → R4**, in dieser Reihenfolge: R1 ist die einzige Idee,
die direkt auf der gerade abgeschlossenen O1-Arbeit aufbaut und ohne sie
wenig Sinn ergäbe; R2 und R5 sind kleine, in sich abgeschlossene
Check-Ergänzungen nach demselben Muster wie `dead-function`/`dead-see-target`;
R3/R4 sind günstige UI-Ergänzungen, die auf bereits vorhandenen Daten
aufbauen. R6–R10 bleiben Backlog, nicht weil sie schlecht wären, sondern weil
für keine davon bisher ein echter Schmerzpunkt aufgetreten ist — derselbe
Maßstab, an dem D4/O2 in `docmodule.md` schon gemessen wurden.
