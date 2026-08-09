# `documentation.nvim`

## Long term (AN CLAUDE: NOCH NIHCT IMPLEMENTIEREN: EINFACH IGNORIEREN!)

- Eine Desktop/Webapp version, in der auf dieses konmzept aufgesetz wird, aber alles verfeinert wird, auch mit profiler und besserer view/ui/feature ausstattung

---

## Generell

- [ ] Kann ich,wenn das plugin `documentation.nvim` nutzt, etwas für
  - meinen Workflow gewinnen
  - etwas vom Kontext, über das Projekt in dem ich gerade arbeite, dazu verwenden um das Linting, LSP Diagnostic oder vielleicht das fehlende `in/outgoing calls` feature von luals, beisteurn kann das es  (besser) funktionert?
  Also sprich: uisecase dateen bzw workflow files mit tipps, wie man documentation.nvim effiziehnt nutzt, wie man die aufbereitetein daten inm browser gut nutzt, was man wo findet, was man wie kombinieren kann usw... am besten in die /docs geben

- [ ] Jedes plugin das documentation.nvim verwendet, könnte doch in der eigenen README.md auf die entstandenen files hinweißemn, dass s man die im browser anschauen kann. als auf die art "dieses plugin verewndet documentatiion.nim und du kannst dir die maps /views usw hier anschauen: PFAD/" (wobei ich gerade nicht sicher bin, ob da süheer diesen weg auch geht, denn der übliche weg ist ja glaube ich in der documentation.nvim indtallations spec andzugeben, welche projekte man analyisert haben will; daher würde der punkt wrsch nur begrnezt sinn machen oder?)
- [ ] In den plugins werden gerade doc regeln implementiert wie: einen docs/FEATURES Folder oder zumindest eine file in der alle features beschreiben werden in einen bestimmten format/regeln. auch docs/BINDINGS wo alle autocmds, usrcmds und keymaps aufgelistet sind. Das kann documentation.nvim nutzen, um eigene tabs dafür anzuzeigen. Das diese, wie jene tabs von runtime-anylsis.nvim nicht direkt von documentation.nvim kommen, sollten sie farblich/icon/form abweichen vom standard; Es wäre gut, eine Spezifikation für FEATURES und BINDINGS zu analysiren und ziu chcken, ob etwas anders gemahct werden soll, um es gut verwenden zu können. Hier könnte man auch ein feature anbieten, dass man sowas macht wie wenn im FEATURES folder ein file drinnen isst die ein features ausführlich beschriebt (und bewirbt), dann bekommt das einen eigenen tab; als idee
   -->  Regelvideen: In /FEATURES ordner werden thematisch files angelget wie UI, PERFORMANCE, SECURITY oder XY, dort werden die freatures eingetreagen. Wenn ein Feature in ein Bindfing mündet oder teil davopn ist, dann wird das kurz refreneziert (kann dan velrinkt werden in documentaiton.nvim zur entsprechenden Bindings page)
   --> Ein Feature kann auch zb, ein spezieller cache sein oä..
   --> Dasd weäre weiterfednkend auch desweghen cool, denn dann könnte man als zweiteres zusatzfeature im source code in der broiwser view, wenn man über eine funkltin oder table hovert oder in einer trefferliste findet, dann kann es dort wien wetieres icon geben, windem steht in welchen feratures der teil gerade eingesetzt wird.

## Neue Features

- [ ] lib.nvim nvim.deps als tab einbinden
- [ ] Spezielle tabs die vonm anderenr plugins komen wie runtime-anylsis.nvim oder lib.nvim.nvim.deps, dann werden die ja in der tablesite angheeikgt, wenn siue nxht isntalliert sind, dann ncht. es wäre suuper, wenn sie isntlliert ud in dedr tagleiste sind, das sich die tab iccons ein wenig vonden normalen abheben, leichtende bg odeer, hl und so...
- [ ] In der hriachie level auslednen/einblenden also zb root level ausbelnden sodass die level 2 folder als root ebeene dargestellt weren,.. viellei cht muit : an der seite ein so ein horizontaler strich it veikalen linien wie bnei einen masstatb, dass man poft hat bei google maps usw.. um den zoom level z bestmmten, da gibt es dann ein + zeichen bei top und ein minus bbei botomm oider so öhnlich
- [ ] hirachie view:einzelne module auslenden/verdunkeln und einblenden
- [ ] Alternative ansichten von modulen: view wie hierarchie, aber man ann verschiednee "daten" oder "filter auf da modul view legen wie zb welche calls macht das modul, dan weren alle module die calls empfangen rundherum eingeblendet und verbunden mit pfelen und gewuchtet darewtekltllt: ciele calls dickerer streich oder so ähnlch. und dda vercshiedne varianten davon auswählbar machen brainstorm, welche views man mache kölnte mit den daten ,  ich wwürde einen eigenen tab dafür machen nicht im hirarchie tab
- [ ] einen tab, indem der source code des projekts in https://godbolt.org/ geladen ist; bei den modulen / funktinen / tables usw... ein icon, bei dem einpopup aufgeht in der der code in  geladen ist ( wenn das sinn macht) oder zumimdnest ein icon, wenn man den klickt schickt er den funkltine/table usw.. in desas compiler explorer tab
- [ ] Neues Feature: Erkennung von externen calls/plugins: zb man hat plenary eingebunfdne, und zwar called man zweimal eine funklti dort, auch pdfport.nvim wird mit einer api calöl called; jetzt wäre es super, wen es einen subpunkt in der dependecy ansicht gibt, dercalls zu plugin exzernen cpde aufzeigt, damit man dann agleich sieht: aha, plenary ist eignebunden wegen deieser zwei funktionen;
  - [ ] Erweiterung: Externer source code liegt ja nicht vor, daher mus er via github repo gezigt werden, das könnte man so machen, wenn man auf eine externe funkltnie / table oder was auch immer zugreift, diese funkltnin irgendo in documentation.nvim gezeigt wird, dass man wenn man auf einen icon klickt den source code von github fetched und zeigt bzw auch gleich auf github weiterleiten kann auf die korrekte page; so kann man den externen source schenll finden;

---

## Aus `MyPlugin-Notes/LuaAnnotzGen/` (Analyse 2026-08-08)

Quelle: `E:/repos/Notes/MyPlugin-Notes/LuaAnnotzGen/`
(`Beschreibung.md`, `Architektur.md`, `Ideas.md`, `AI.md`).

Das Konzept beschreibt ein eigenständiges Go-CLI (`annotgen`), das Lua-Dateien
scannt und **Modul-Header schreibt**: `@module`, `@brief`, `@desc`, dazu
`@class`/`@field`-Blöcke aus den gefundenen `M.<name>`-Exporten — unter
Übernahme bereits vorhandener Annotationen an den Exporten selbst.

**Warum das hierher gehört und nicht in ein neues Repo:** `documentation.nvim`
macht heute exakt die Gegenrichtung. Es *liest* LuaCATS-Annotationen
(`core/luals.lua` wertet `lua-language-server --doc` aus, inkl. `@class`/`@alias`
samt Feldern) und misst deren Vollständigkeit (`core/doccoverage.lua`,
`core/check.lua`, `:DocMap check`). Was fehlt, ist der Schreibpfad: Es kann
sagen „hier fehlt ein Header", aber ihn nicht erzeugen.

Ein separates Go-Binary wäre zusätzlich ein Rückschritt gegenüber dem
Ist-Zustand — Scanner, Sprach-Adapter (`core/lang/{lua,js,ts,tsx,ecma}.lua`),
Symbol-Modell (`core/symbols.lua`, `core/functions.lua`) und IR existieren
bereits in Lua.

 KI-Implementierung mögich?

### 1. `:DocMap annotate` — Header generieren statt nur bemängeln

- [ ] Für Dateien ohne Modul-Header: `@module 'pfad.zum.modul'` aus dem
      Dateipfad ableiten, `@brief`/`@desc` als leere Platzhalter setzen.
- [ ] `@field`-Zeilen aus den `M.<name>`-Exporten erzeugen; ein am Export
      bereits stehender `@class`-Block wird **referenziert**
      (`---@field rate_limits RateLimits`), nicht dupliziert.
- [ ] Alles unterhalb von `local M = {}` bleibt unangetastet — das ist die
      wichtigste Regel des Konzepts.
- [ ] Flags analog zum CLI-Entwurf: `--dry-run` (nur anzeigen), Schreiben in die
      Datei oder in `*.annot.lua` daneben.
- [ ] Die Kandidatenliste kommt gratis aus `doccoverage`/`check`.

**Aufwand:** Mittel
**Nutzen:** hoch — schliesst die Lücke zwischen „Coverage-Report" und
„Coverage-Fix" und trifft die eigenen ~30 Repos direkt.

### 2. Der `@type`-vs-`@class`-Befund als Lint-Regel

`Beschreibung.md` enthält eine Erkenntnis, die mehr wert ist als das Tool selbst:

> `---@type Foo` an einem `local M = {}`, dem danach Felder zugewiesen werden,
> erzeugt in LuaLS `missing-fields` und „fields cannot be injected". Richtig ist
> `---@class M : FooDef` plus ein `@see` auf die Typdatei.

Das ist mechanisch prüfbar und kein Einzelfall.

- [ ] Als Check in `core/check.lua` aufnehmen: `@type` an einem Modul-Table, dem
      später Felder zugewiesen werden → Befund samt Fix-Vorschlag.
- [ ] Falls es hier keinen passenden Ort gibt, gehört die Regel in den Lint-Teil
      der eigenen Checklisten — aber sie darf nicht in einer Notizdatei versanden.

**Aufwand:** Quick Win
**Nutzen:** hoch — verhindert eine Fehlerklasse, die man sonst pro Repo einmal
neu entdeckt.

### 3. Erweiterte Annotationen

Aus `Ideas.md`: `---@see` (Querverweise), `---@generic`, `---@deprecated`.

`@see` ist der interessante Fall: In `debugging.nvim` war „`@see`-Verlinkung"
ein eigenes (inzwischen erledigtes) Roadmap-Item — hier ginge es darum, die
Verlinkung generieren zu lassen statt sie von Hand zu pflegen.

**Aufwand:** Quick Win je Annotation
**Nutzen:** mittel.
Sollten eigenkreationen notwendig werden, bin ich gerundsätzlkich offen dafür wenn sie nicht zwingend für kernfeatures notwenidig gemacht werden


