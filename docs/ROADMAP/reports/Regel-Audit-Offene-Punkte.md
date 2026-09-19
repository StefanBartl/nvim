# Regel-Audit — offene Punkte nach der ersten Fix-Runde

> Stand: 2026-09-19. Anschluss an
> [`Regel-Audit-rules-nvim.md`](Regel-Audit-rules-nvim.md) (der ursprüngliche
> Audit, 2026-09-18) und die Fix-Runde vom selben und vom Folgetag (SEC-34 in
> 7 Repos, `rules.nvim`s `SKIP_DIRS`, die sechs Check-Defekte samt zwei neuen
> Engine-Primitiven `excludes`/`paths`, vier `.rules-waivers.json`). Alle elf
> dabei geänderten Repos liefen auf allen drei CI-Plattformen grün.
>
> **Dieser Report ist eine Bestandsaufnahme, kein Fix.** Er hält fest, was aus
> der ursprünglichen Arbeitsliste bewusst nicht in dieser Runde behandelt
> wurde, und warum — damit eine künftige Session direkt weiß, wo sie ansetzt,
> statt den Audit zu wiederholen.

## Table of content

  - [Kurzfassung](#kurzfassung)
  - [Die drei offenen Mehrfach-Repo-Sweeps](#die-drei-offenen-mehrfach-repo-sweeps)
    - [`ERR-11` — 30 Repos, 52 Fundstellen](#err-11--30-repos-52-fundstellen)
    - [`LUA-01` — 21 Repos, 25 Fundstellen](#lua-01--21-repos-25-fundstellen)
    - [`ERR-50`/`ERR-22` — 24 bzw. 22 Repos](#err-50err-22--24-bzw-22-repos)
  - [Warum nicht im Vorbeigehen miterledigt](#warum-nicht-im-vorbeigehen-miterledigt)
  - [Bekannte Abweichung: `ai.nvim`s `ERR-50`-Fund ist bereits erledigt](#bekannte-abweichung-ainvims-err-50-fund-ist-bereits-erledigt)
  - [Die 313 ungeprüften Regeln](#die-313-ungeprften-regeln)
  - [Empfehlung für die nächste Runde](#empfehlung-fr-die-nchste-runde)

---

## Kurzfassung

Offen bleiben die drei großen Mehrfach-Repo-Sweeps (`ERR-11`, `LUA-01`,
`ERR-50`/`ERR-22`) und die 313 ungeprüften `recommended`/`nice-to-have`-Regeln
— das sind eigene Runden, kein Nachtrag.

Zusammen sind das über 100 Einzelstellen mit Verhaltensänderung, verteilt
über gut 30 der 38 Repos. Das ist dieselbe Größenordnung wie die
Cross-Platform-CI-Fix-Runde vom 2026-09-18/19 (dort: 18 Repos, 16 echte
Defekte, per Multi-Agent-Workflow mit adversarialer Gegenprüfung) — nur
größer. Es gehört in eine eigene, ebenso ausgestattete Runde, nicht in einen
Nachtrag am Ende eines anderen Tasks.

## Die drei offenen Mehrfach-Repo-Sweeps

Zahlen aus dem ursprünglichen Audit vom 2026-09-18
([`Regel-Audit-Befunde.md`](Regel-Audit-Befunde.md)), **nicht** gegen den
aktuellen Stand nachverifiziert — siehe die Abweichung weiter unten, die
genau deshalb schon aufgefallen ist.

### `ERR-11` — 30 Repos, 52 Fundstellen

„Leer, weil nichts da" ≠ „leer, weil kaputt" — die laut Regelkatalog selbst
„häufigste reale Bugklasse eines ganzen 32-Repo-Sweeps" (Beleg vom
2026-09-07). Betroffen: `ai`, `buffer-ctx`, `cascade`, `casedesk`, `cmdlog`,
`dap`, `debugging`, `diff`, `documentation`, `fileops`, `filetree`,
`github_stats`, `hover`, `images`, `insights`, `language`, `lib`, `lsp`,
`markdown`, `media`, `my`, `pdfport`, `pickers`, `recommender`, `replacer`,
`reposcope`, `rules`, `runtime-analysis`, `spotlight`, `ui`.

### `LUA-01` — 21 Repos, 25 Fundstellen

„Hart oder weich, aber konsistent" — meist ein `require("ui.kit")` ohne
`pcall`, während die eigene `docs/installation.md` `ui.nvim` als optional
führt. Betroffen: `buffer-ctx`, `cascade`, `cmdlog`, `color_my_ascii`, `dap`,
`emojis`, `fileops`, `filetree`, `github_stats`, `gopath`, `insights`,
`markdown`, `media`, `open`, `pdfport`, `pickers`, `recommender`,
`reposcope`, `sandbox`, `sessions`, `spotlight`.

### `ERR-50`/`ERR-22` — 24 bzw. 22 Repos

Config-Key-Prüfung vor dem Merge (`ERR-50`) und Degradierung eines
ungültigen Werts auf den Default (`ERR-22`) — verwandte, aber getrennt zu
behandelnde Muster, oft im selben `config/init.lua`. `ERR-50` betrifft `ai`,
`buffer-ctx`, `cascade`, `casedesk`, `cmdlog`, `color_my_ascii`, `dap`,
`debugging`, `diff`, `emojis`, `fileops`, `filetree`, `gopath`, `images`,
`insights`, `lib`, `markdown`, `my`, `pdfport`, `pickers`, `recommender`,
`replacer`, `rules`, `sessions`. `ERR-22` betrifft `ai`, `cascade`,
`casedesk`, `cmdlog`, `color_my_ascii`, `dap`, `diff`, `documentation`,
`emojis`, `fileops`, `filetree`, `gopath`, `insights`, `open`, `pickers`,
`recommender`, `replacer`, `reposcope`, `runtime-analysis`, `sandbox`,
`spotlight`, `ui`.

## Warum nicht im Vorbeigehen miterledigt

Jede der drei Gruppen ist eine Verhaltensänderung, keine mechanische
Textersetzung wie SEC-34 (dort: ein fester Ersatz, `expand_path` existiert
bereits, jede Stelle ließ sich lokal mit der Repo-eigenen Suite verifizieren).
Hier braucht jede Fundstelle echtes Urteilsvermögen: bei `ERR-11`, ob „leer"
in diesem konkreten Aufrufkontext tatsächlich zwei verschiedene Ursachen
verdeckt oder ob eine leere Antwort dort immer korrekt ist; bei `LUA-01`, ob
die fehlende Absicherung ein Bug ist oder ob die Dokumentation nachgezogen
werden muss (`ui.nvim` doch als hart deklarieren); bei `ERR-50`/`ERR-22`, was
der korrekte Default-Fallback für jeden einzelnen Config-Wert ist.

Das ist exakt die Arbeit, die die Cross-Platform-CI-Runde für die
Plattform-Bugs geleistet hat: pro Fund ein Agent mit Kontext, der einen
Fix vorschlägt, danach ein zweiter Agent, der ihn gegen den Code prüft und
insbesondere danach sucht, ob ein Test nur weichgeklopft statt der Bug
wirklich behoben wurde. Bei über 100 Fundstellen ist das ein
Workflow-Auftrag mit mehreren Runden, kein Anhängsel an einen anderen Task.

## Bekannte Abweichung: `ai.nvim`s `ERR-50`-Fund ist bereits erledigt

Beim Zusammenstellen dieses Reports aufgefallen: `ai.nvim`s `ERR-50`-Fund
(`lua/ai/config/DEFAULTS.lua:64`) ist derselbe, den die heutige Fix-Runde
für Punkt 3 der vorherigen Arbeitsliste bereits verifiziert hat (durch eine
parallele Session behoben — `provider`/`model` sind jetzt `false` statt
`nil`, inklusive des Spiegelfehlers in `OPEN_SHAPE_KEYS`). Die Zahl „24
Repos" für `ERR-50` oben ist entsprechend um mindestens eins veraltet.

Das ist kein Einzelfall, sondern der Normalfall bei mehreren parallel
laufenden Sessions auf demselben Fleet: die Zahlen in diesem Report sind ein
Stand vom 2026-09-18, keine Live-Erhebung. **Jede der drei Gruppen braucht
vor dem eigentlichen Fix eine kurze Re-Prüfung, welche Fundstellen seither
schon anderweitig erledigt wurden**, bevor an einer bereits behobenen Stelle
gearbeitet wird.

## Die 313 ungeprüften Regeln

Der Katalog hat 421 Regeln, davon wurden bisher nur die 76 `critical`-Regeln
der laufend relevanten Familien (ERR, LUA, SEC, XP, PERF, PRIN, UI, CMT, TS,
LLS, DEP) manuell geprüft. Die übrigen 313 — `recommended` und
`nice-to-have`, plus die `critical`-Regeln der Gate-Familien NEW/REL
außerhalb ihres automatisierten Teils — sind komplett offen. Größenordnung
zur Einordnung: `PERF` allein hat 64 Regeln, `LUA` 59, `UI` 41 — jede davon
zu 95%+ ungeprüft.

## Empfehlung für die nächste Runde

1. Vor jeder der drei Gruppen: aktuellen Stand neu erheben (die
   Fundstellen aus dem 2026-09-18-Audit sind eine Startliste, kein
   verlässlicher Live-Stand — siehe oben).
2. Eine Gruppe nach der anderen, nicht alle drei gemischt — jede hat ihr
   eigenes Urteilsmuster, ein Agent, der zwischen dreien wechselt, verliert
   die Konsistenz seiner Entscheidungen.
3. Dieselbe Struktur wie die CI-Fix-Runde: Fix-Agent pro Fundstelle (oder
   pro Repo, wenn mehrere Stellen zusammenhängen), danach ein adversarialer
   Review-Agent, der gezielt nach weichgeklopften Tests statt echter Fixes
   sucht.
4. `rules.nvim` erneut über das gesamte Fleet laufen lassen, sobald eine
   Gruppe durch ist, um zu bestätigen, dass die Fundstellenzahl auf 0 geht.
