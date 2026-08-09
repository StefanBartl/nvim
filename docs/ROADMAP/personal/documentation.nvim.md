# `documentation.nvim`

## Generell

- [ ] documentation.nvim lernen
- [ ] Kann ich,wenn das plugin `documentation.nvim` nutzt, etwas für
  - meinen Workflow gewinnen
  - etwas vom Kontext, über das Projekt in dem ich gerade arbeite, dazu verwenden um das Linting, LSP Diagnostic oder vielleicht das fehlende `in/outgoing calls` feature von luals, beisteurn kann das es  (besser) funktionert?

## Neue Features

- [ ] lib.nvim nvim.deps als tab einbinden
- [ ] Spezielle tabs die vonm anderenr plugins komen wie runtime-anylsis.nvim oder lib.nvim.nvim.deps, dann werden die ja in der tablesite angheeikgt, wenn siue nxht isntalliert sind, dann ncht. es wäre suuper, wenn sie isntlliert ud in dedr tagleiste sind, das sich die tab iccons ein wenig vonden normalen abheben, l eichtende bg odeer so...O
- [ ] In mder hriachie level auslednen/einblenden also zb root level ausbelnden sodass die level 2 folder als root ebeene dargestellt weren,.
- [ ] hirachie view:einzelne module auslenden und einblenden
- [ ] Alternative ansichten von modulen: view wie hierarchie, aber man ann verschiednee "daten" oder "filter auf da modul view legen wie zb welche calls macht das modul, dan weren alle module die calls empfangen rundherum eingeblendet und verbunden mit pfelen und gewuchtet darewtekltllt: ciele calls dickerer streich oder so ähnlch. und dda vercshiedne varianten davon auswählbar machen brainstorm, welche views man mache kölnte mit den daten ,  ich wwürde einen eigenen tab dafür machen nicht im hirarchie tab
- [ ] einen ne en tab mit birwowser explorer gleich mit dem projekt geladen


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

