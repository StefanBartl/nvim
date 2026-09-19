# Regel-Audit — offene Punkte nach der ersten Fix-Runde

> Stand: 2026-09-19, aktualisiert nach Abschluss des `ERR-11`-Sweeps (selber
> Tag). Anschluss an [`Regel-Audit-rules-nvim.md`](Regel-Audit-rules-nvim.md)
> (der ursprüngliche Audit, 2026-09-18) und die Fix-Runde vom selben und vom
> Folgetag (SEC-34 in 7 Repos, `rules.nvim`s `SKIP_DIRS`, die sechs
> Check-Defekte samt zwei neuen Engine-Primitiven `excludes`/`paths`, vier
> `.rules-waivers.json`). Alle elf dabei geänderten Repos liefen auf allen
> drei CI-Plattformen grün.
>
> **Dieser Report ist eine Bestandsaufnahme, kein Fix** — mit einer Ausnahme:
> `ERR-11` wurde inzwischen als eigene Runde durchgeführt (siehe unten) und ist
> hier entsprechend als erledigt markiert, statt in einem separaten Dokument
> nachgetragen zu werden. Er hält weiterhin fest, was aus der ursprünglichen
> Arbeitsliste bewusst nicht behandelt wurde, und warum — damit eine künftige
> Session direkt weiß, wo sie ansetzt, statt den Audit zu wiederholen.
>
> **Wichtiger Kontext, der beim Schreiben der ersten Fassung noch fehlte:**
> Parallel zu diesem Report lief (und läuft teils noch) eine unabhängige
> Session ("Regel-Audit-Befunde Abarbeitung"), die 497 einzeln
> gegenverifizierte Befunde aus [`Regel-Audit-Befunde.md`](Regel-Audit-Befunde.md)
> quer über alle Regelfamilien und alle 38 Repos abarbeitet (Stand beim
> Nachfragen: 489/497 erledigt, Rest lief als Workflow für 8 bewusst offen
> gelassene Architektur-Befunde). Das ist NICHT derselbe Task wie die drei
> großen Rohsweeps hier — deren Fundstellen waren zum Zeitpunkt des
> ursprünglichen 2026-09-18-Audits noch nicht einzeln aufgelistet, nur als
> Repo-Zahl geschätzt — aber es bedeutet, dass ein Teil der hier geschätzten
> Fundstellen durch die 497er-Kampagne bereits inzident mitgefixt wurde, bevor
> der jeweilige große Sweep sie überhaupt erreicht. Jede künftige Runde muss
> das einkalkulieren (siehe `ERR-11`s Ergebnis unten: bei 10 von 24 geprüften
> Repos war schon nichts mehr zu tun).

## Table of content

  - [Kurzfassung](#kurzfassung)
  - [Erledigt: `ERR-11` — 24 von 30 Repos geprüft, 14 echte Fixes](#erledigt-err-11--24-von-30-repos-geprft-14-echte-fixes)
  - [Die zwei verbleibenden offenen Mehrfach-Repo-Sweeps](#die-zwei-verbleibenden-offenen-mehrfach-repo-sweeps)
    - [`LUA-01` — 21 Repos, 25 Fundstellen](#lua-01--21-repos-25-fundstellen)
    - [`ERR-50`/`ERR-22` — 24 bzw. 22 Repos](#err-50err-22--24-bzw-22-repos)
  - [Warum nicht im Vorbeigehen miterledigt](#warum-nicht-im-vorbeigehen-miterledigt)
  - [Bekannte Abweichung: `ai.nvim`s `ERR-50`-Fund ist bereits erledigt](#bekannte-abweichung-ainvims-err-50-fund-ist-bereits-erledigt)
  - [Die 313 ungeprüften Regeln](#die-313-ungeprften-regeln)
  - [Empfehlung für die nächste Runde](#empfehlung-fr-die-nchste-runde)

---

## Kurzfassung

`ERR-11` ist durch (siehe eigener Abschnitt unten). Offen bleiben noch zwei
der ursprünglich drei großen Mehrfach-Repo-Sweeps (`LUA-01`, `ERR-50`/`ERR-22`)
und die 313 ungeprüften `recommended`/`nice-to-have`-Regeln — das sind eigene
Runden, kein Nachtrag.

Zusammen sind das noch über 70 Einzelstellen mit Verhaltensänderung, verteilt
über gut 25 der 38 Repos. Das ist dieselbe Größenordnung wie die
Cross-Platform-CI-Fix-Runde vom 2026-09-18/19 (dort: 18 Repos, 16 echte
Defekte, per Multi-Agent-Workflow mit adversarialer Gegenprüfung) und wie der
inzwischen abgeschlossene `ERR-11`-Sweep (24 Repos geprüft, 14 echte Fixes,
0 Refutationen im adversarialen Verify). Jede Gruppe gehört in eine eigene,
ebenso ausgestattete Runde, nicht in einen Nachtrag am Ende eines anderen
Tasks.

## Erledigt: `ERR-11` — 24 von 30 Repos geprüft, 14 echte Fixes

Durchgeführt am 2026-09-19 als eigener Multi-Agent-Workflow (pro Repo ein
Fix-Agent: frischer Audit gegen den aktuellen Code, kein Vertrauen auf die
2026-09-18-Zahlen, danach Fix + lokaler Lint/Test + Push; danach pro Repo ein
adversarialer Verify-Agent gegen den echten Diff). 48 Agents, 0 Fehler,
0 leere Ergebnisse, 0 Refutationen.

**6 der ursprünglich 30 Repos bewusst ausgeklammert** (`fileops`, `filetree`,
`hover`, `media`, `pickers`, `ui`) — dort liefen zum Startzeitpunkt aktiv
Agenten der parallelen 497er-Kampagne (Stage 1+2, lokale Commits + Verify+Push
auf demselben Checkout); ein gleichzeitiger Sweep hätte Merge-Konflikte
riskiert. **`ERR-11` ist für diese 6 Repos entsprechend NICHT geprüft** —
kurzer Nachtrag empfohlen, sobald sie sich nicht mehr aktiv in Bearbeitung
befinden.

**Ergebnis der geprüften 24 Repos:**

- **14 Repos mit echten, bis dahin ungefixten Verstößen** — gefunden, gefixt,
  verifiziert (Lint + repo-eigene Testsuite), gepusht auf `main`: `ai`,
  `buffer-ctx` (2 Stellen), `cascade`, `casedesk`, `cmdlog`, `insights`,
  `lib`, `markdown`, `my`, `pdfport`, `recommender`, `reposcope`
  (2 Stellen), `runtime-analysis`, `spotlight`.
- **10 Repos bereits sauber** — `ERR-11` dort schon durch frühere Arbeit
  behoben (teils aus der heutigen SEC-34/CI-Runde, teils aus der parallelen
  497er-Kampagne, teils aus älteren Commits): `dap`, `debugging`, `diff`,
  `documentation`, `github_stats`, `images`, `language`, `lsp`, `replacer`,
  `rules`.

Der adversariale Verify-Durchgang hat jeden einzelnen Fund gegen den
tatsächlichen `git show`-Diff geprüft (nicht die Prosa-Zusammenfassung) und
für alle 24 Repos **CONFIRMED** zurückgegeben — sowohl für die 14 echten
Fixes als auch für die 10 "nichts gefunden"-Verdikte (jeweils per eigenem
Gegen-Audit nachvollzogen, nicht nur vertraut). Ein harmloser Nebenbefund:
`rules.nvim`s Fix-Agent verschrieb sich in der Prosa ("119/119" statt
tatsächlich 108 Erfolgsmeldungen) — reine Beschreibungsungenauigkeit, keine
Code-Auswirkung.

**Lehre für `LUA-01` und `ERR-50`/`ERR-22`:** Dasselbe Muster hat sich
bewährt — pro Repo EIN Agent, der zuerst frisch auditiert (nicht die alte
Fundliste blind übernimmt), danach fixt, danach lokal verifiziert und pusht;
danach EIN adversarialer Verify-Agent pro Repo. Vorher unbedingt mit
laufenden Parallel-Sessions abgleichen (`ListAgents`/kurze Status-Nachricht),
welche Repos gerade in Bearbeitung sind, und die entsprechend ausklammern.

## Die zwei verbleibenden offenen Mehrfach-Repo-Sweeps

Zahlen aus dem ursprünglichen Audit vom 2026-09-18
([`Regel-Audit-Befunde.md`](Regel-Audit-Befunde.md)), **nicht** gegen den
aktuellen Stand nachverifiziert — siehe die Abweichung weiter unten, die
genau deshalb schon aufgefallen ist, und `ERR-11`s Ergebnis oben (dort war
bei fast der Hälfte der geprüften Repos inzwischen nichts mehr zu tun).

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

Jede der beiden verbleibenden Gruppen ist eine Verhaltensänderung, keine
mechanische Textersetzung wie SEC-34 (dort: ein fester Ersatz, `expand_path`
existiert bereits, jede Stelle ließ sich lokal mit der Repo-eigenen Suite
verifizieren). Hier braucht jede Fundstelle echtes Urteilsvermögen: bei
`LUA-01`, ob die fehlende Absicherung ein Bug ist oder ob die Dokumentation
nachgezogen werden muss (`ui.nvim` doch als hart deklarieren); bei
`ERR-50`/`ERR-22`, was der korrekte Default-Fallback für jeden einzelnen
Config-Wert ist.

Das ist exakt die Arbeit, die die Cross-Platform-CI-Runde für die
Plattform-Bugs geleistet hat, und die derselben Struktur folgende
`ERR-11`-Runde (siehe oben) hat sie für diese Art Befund bestätigt: pro Repo
ein Agent mit Kontext, der frisch auditiert und einen Fix vorschlägt, danach
ein zweiter Agent, der ihn gegen den echten Diff prüft und insbesondere
danach sucht, ob ein Test nur weichgeklopft statt der Bug wirklich behoben
wurde. Bei über 70 verbleibenden Fundstellen ist das weiterhin ein
Workflow-Auftrag pro Gruppe, kein Anhängsel an einen anderen Task.

## Bekannte Abweichung: `ai.nvim`s `ERR-50`-Fund ist bereits erledigt

Beim Zusammenstellen dieses Reports aufgefallen: `ai.nvim`s `ERR-50`-Fund
(`lua/ai/config/DEFAULTS.lua:64`) ist derselbe, den die heutige Fix-Runde
für Punkt 3 der vorherigen Arbeitsliste bereits verifiziert hat (durch eine
parallele Session behoben — `provider`/`model` sind jetzt `false` statt
`nil`, inklusive des Spiegelfehlers in `OPEN_SHAPE_KEYS`). Die Zahl „24
Repos" für `ERR-50` oben ist entsprechend um mindestens eins veraltet.

Das ist kein Einzelfall, sondern der Normalfall bei mehreren parallel
laufenden Sessions auf demselben Fleet: die Zahlen in diesem Report sind ein
Stand vom 2026-09-18, keine Live-Erhebung. **Jede der verbleibenden Gruppen
braucht vor dem eigentlichen Fix eine kurze Re-Prüfung, welche Fundstellen
seither schon anderweitig erledigt wurden**, bevor an einer bereits
behobenen Stelle gearbeitet wird — bei `ERR-11` betraf das fast die Hälfte
der geprüften Repos.

## Die 313 ungeprüften Regeln

Der Katalog hat 421 Regeln, davon wurden bisher nur die 76 `critical`-Regeln
der laufend relevanten Familien (ERR, LUA, SEC, XP, PERF, PRIN, UI, CMT, TS,
LLS, DEP) manuell geprüft. Die übrigen 313 — `recommended` und
`nice-to-have`, plus die `critical`-Regeln der Gate-Familien NEW/REL
außerhalb ihres automatisierten Teils — sind komplett offen. Größenordnung
zur Einordnung: `PERF` allein hat 64 Regeln, `LUA` 59, `UI` 41 — jede davon
zu 95%+ ungeprüft.

## Empfehlung für die nächste Runde

1. Vor jeder der beiden verbleibenden Gruppen: aktuellen Stand neu erheben
   (die Fundstellen aus dem 2026-09-18-Audit sind eine Startliste, kein
   verlässlicher Live-Stand — siehe oben, und `ERR-11`s Ergebnis: fast die
   Hälfte der geprüften Repos war bereits sauber).
2. Vorher kurz per `ListAgents` prüfen, ob eine parallele Session gerade in
   denselben Repos arbeitet, und betroffene Repos für diese Runde
   ausklammern (bei `ERR-11` waren das 6 von 30) — sonst Risiko von
   Merge-Konflikten auf demselben Checkout.
3. Eine Gruppe nach der anderen, nicht beide gemischt — jede hat ihr eigenes
   Urteilsmuster, ein Agent, der zwischen ihnen wechselt, verliert die
   Konsistenz seiner Entscheidungen.
4. Dieselbe Struktur wie `ERR-11` und die CI-Fix-Runde: ein Agent pro Repo,
   der zuerst frisch auditiert (nicht blind die alte Fundliste übernimmt),
   dann fixt, lokal verifiziert (Lint + repo-eigene Testsuite) und auf
   `main` pusht — danach ein adversarialer Verify-Agent pro Repo, der
   gezielt gegen den echten `git show`-Diff prüft, nicht gegen die
   Prosa-Zusammenfassung, und insbesondere nach weichgeklopften Tests statt
   echter Fixes sucht.
5. `rules.nvim` erneut über das gesamte Fleet laufen lassen, sobald eine
   Gruppe durch ist, um zu bestätigen, dass die Fundstellenzahl auf 0 geht —
   das funktioniert für die 76 automatisiert geprüften `critical`-Regeln,
   nicht für `LUA-01`/`ERR-50`/`ERR-22` selbst (rein manuelle Regeln ohne
   `check`-Block, siehe `ERR-11`s Erfahrung damit).
