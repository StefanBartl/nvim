# CDX: Keymap/Usercmd/Autocmd — Laufzeit-Test, Duplikat-Check, Namensqualität

Handover vom 2026-09-07. Ausgangspunkt war dieser CDX-Punkt aus dem Chat:

```
- [ ] CDX: jedes Keymap/Usrcmd/Autocmd in echter nvim-Instanz durchtesten, ob
      Fehler geworfen werden. (Claude kann einen Testrunner vorbereiten, das
      Beobachten in Echtzeit ist deine Domäne — außer wir bauen dafür einen
      headless-Test.)
  - [ ] nochmal alle keymaps checken, ob kein keymap doppelt vergeben ist,
        über alle repos hinweg + nvim-config
  - [ ] gleich mitchecken, ob die usrcmd-Optionen wirklich gut benannt sind.
        Zb `:LspDoctor deep` wurde genannt für eine Aktion, die ausgegeben
        hat, welcher Formatter gerade aktiv ist... daher wurde es umbenannt
        auf `LspDoctor fmt_check`.
```

Dieses Dokument ist der Plan dazu, kein fertiges Tool. Bevor irgendwas gebaut
wird: der größte Teil der Bestandsaufnahme lag schon da, nur verstreut und
teils zwei Wochen alt. Das hier bündelt, was existiert, was davon jetzt eine
echte, wiederholbare Prüfung werden kann, und was zwangsläufig eine
Vor-Ort-Sitzung mit dir bleibt.

---

## Table of content

  - [Bestandsaufnahme](#bestandsaufnahme)
    - [Duplikat-Check (Punkt 2)](#duplikat-check-punkt-2)
    - [Namensqualität (Punkt 3)](#namensqualitt-punkt-3)
    - [Laufzeit-Fehlertest (Punkt 1)](#laufzeit-fehlertest-punkt-1)
  - [Was daraus folgt](#was-daraus-folgt)
  - [Plan, in Phasen](#plan-in-phasen)
    - [Phase 1 — Duplikat-Checks live schalten (klein, sofort machbar) — ✅ erledigt 2026-09-07](#phase-1-duplikat-checks-live-schalten-klein-sofort-machbar-erledigt-2026-09-07)
      - [Ursprünglicher Plan (Referenz)](#ursprnglicher-plan-referenz)
    - [Zwischenschritt — `:Bindings audit`/`conflicts` als Alias — ✅ erledigt 2026-09-07](#zwischenschritt-bindings-auditconflicts-als-alias-erledigt-2026-09-07)
    - [Phase 2 — Refresh der beiden Cross-Plugin-Dateien — ✅ erledigt 2026-09-07](#phase-2-refresh-der-beiden-cross-plugin-dateien-erledigt-2026-09-07)
    - [Phase 2 — ursprünglicher Plan (Referenz)](#phase-2-ursprnglicher-plan-referenz)
    - [Phase 3 — Namensqualität: Report statt Urteil — ✅ erledigt 2026-09-07](#phase-3-namensqualitt-report-statt-urteil-erledigt-2026-09-07)
    - [Phase 4 — Laufzeit-Testrunner, zweistufig — ✅ erledigt 2026-09-07](#phase-4-laufzeit-testrunner-zweistufig-erledigt-2026-09-07)
  - [Risiken / offene Fragen](#risiken-offene-fragen)
  - [Wie das Ergebnis dokumentiert wird](#wie-das-ergebnis-dokumentiert-wird)
  - [Status: alle vier Phasen erledigt (2026-09-07)](#status-alle-vier-phasen-erledigt-2026-09-07)

---

## Bestandsaufnahme

### Duplikat-Check (Punkt 2)

**Für Keymaps existiert das schon zweimal — einmal als Analyse, einmal als
API, aber die beiden sind nicht verbunden.**

- [`docs/NOTES/CrossPlugin/Keymaps-Collisions.md`](../../NOTES/CrossPlugin/Keymaps-Collisions.md)
  ist genau diese Prüfung, von Hand gemacht: **„Exact duplicates: None between
  plugins"**, plus zwei tatsächlich gefundene und seither behobene
  Config-vs-Plugin-Kollisionen (`<leader>cp`, `<leader>cs` gegen cascade.nvim,
  gelöst 2026-08-30). Datiert 2026-08-25, letzte Ergänzung 2026-09-02
  (filetree-Fix für `<leader>th`).
- `lib.nvim` (`E:/repos/lib.nvim/lua/lib/nvim/bindings/keymap/init.lua`,
  Funktion in `registry.lua:420`) hat eine echte `keymap.conflicts()`-Funktion, die
  genau das automatisch beantwortet — inklusive der Lehre, die im README
  dokumentiert ist: sie sieht sowohl `keymap.register()`-Actions **als auch**
  blanke `keymap.set()`-Aufrufe (davor waren `set()`-Keymaps für `conflicts()`
  unsichtbar — 59 registrierte Actions gegen 305 echte Keymaps, „over eighty
  percent blind"). Buffer-Scope ist Teil der Identität, ein buffer-lokaler Key
  gilt nicht als Kollision mit einem globalen — deckt sich mit der
  „scope decides everything"-Prämisse der Analyse-Datei.
- **Es gibt keinen Usercmd dafür.** `grep -rn "keymap.conflicts" lua/` über
  die ganze Config: 0 Treffer. Die Funktion existiert, wird aber nirgendwo
  aufgerufen — derselbe Bug-Typ wie beim letzten Sweep
  (`docs/ROADMAP/personal/All/FINISH/ERLEDIGT/roadmap-tools-analysis.md`,
  Nachtrag 2026-09-05): Modul echt, Kommando fehlt.

**Für Usercmds ist die gleiche Prüfung schon fertig**, siehe
[`docs/NOTES/CrossPlugin/Usercmds-Overview.md`](../../NOTES/CrossPlugin/Usercmds-Overview.md):
**148 Kommandonamen über 31 Plugins, alle 148 verschieden.** Plus eine Liste
generischer, noch nicht kollidierender Namen (`:Format`, `:Open`, `:Image`
…) und ein real gefundener und dokumentierter Fall (`:Lsp` unterdrückt
nvim-lspconfigs eigene Registrierung über eine Namens-Prüfung — kein Bug,
aber load-bearing).

**Für Autocmds gibt es keinen Kollisions-Check**, nur
[`docs/NOTES/CrossPlugin/Autocmds-Observations.md`](../../NOTES/CrossPlugin/Autocmds-Observations.md)
— explizit **„untriaged"** Fließtext-Beobachtungen (Event-Reihenfolge bei
`BufWritePre`, mehrfache `ColorScheme`-Handler etc.), keine automatisierte
Prüfung. Autocmd-Kollisionen sind ohnehin ein anderes Tier als Keymaps: zwei
Handler auf demselben Event feuern **beide**, es überschreibt sich nichts —
„Kollision" heißt hier höchstens „unerwartete Reihenfolge", nicht „einer
verschwindet".

---

### Namensqualität (Punkt 3)

Nichts prüft das automatisiert, und nichts sollte das vollautomatisiert
entscheiden — „ist `:LspDoctor deep` ein guter Name für einen
Formatter-Check" ist eine Bedeutungsfrage, kein Pattern-Match. Was es
gibt:

- `Usercmds-Overview.md`s Abschnitt „Names generic enough to be worth
  watching" ist verwandt, prüft aber **Kollisionsrisiko** (ist der Name so
  generisch, dass ein Drittanbieter-Plugin ihn auch will), nicht
  **Bedeutungstreue** (sagt der Name, was das Kommando tut).
- `:LibUsercmdDocs` (lib.nvim, gewired über
  `lua/bindings/usrcmds/autocmd_docs/init.lua`) generiert eine vollständige
  Liste aller Usercmds mit Beschreibung — die Rohliste, auf der eine
  Namens-Durchsicht aufbauen würde, existiert also schon als Kommando.
- `:Bindings browse usercmds` (bindings_explorer) ist dieselbe Liste als
  Picker, scopbar auf ein Plugin.

---

### Laufzeit-Fehlertest (Punkt 1)

**Das ist der einzige der drei Punkte, für den es noch kein Fundament gibt.**
Alles oben ist *statische* Registry-Introspektion — was ist registriert, mit
welchem `lhs`/Namen, unter welchem Scope. Nichts davon **ruft** eine Aktion
auf und schaut, ob sie wirft. Auch `:Bindings check` (Drift-Report) und
`:LibBindingsAudit` (Actions-vs-Routes) lesen nur Metadaten, nie den Callback
selbst aus.

Was an Infrastruktur dafür nutzbar ist:

- `keymap.registered()` / `usercmd.registered()` / `autocmd.registered()`
  geben die vollständigen Listen zurück — der Ausgangspunkt für „jede
  Aktion einmal anfassen".
- `run_all_tests.sh` (siehe `roadmap-tools-analysis.md`, Abschnitt „No
  natural plugin home") iteriert bereits alle `*.nvim`-Repos unter
  `$REPOS_DIR` und ruft deren eigene Testrunner auf — das ist aber
  Unit-/Plugin-eigene Tests, nicht "jede Keymap-Aktion im laufenden Setup
  auslösen".
- Kein bestehendes Werkzeug feuert Keys per `feedkeys()`, ruft Usercmds mit
  synthetischen Argumenten auf oder triggert Autocmd-Events künstlich.

---

## Was daraus folgt

Punkt 2 und die Kollisions-Hälfte von Punkt 3 sind **kein neues Tool**,
sondern zwei fehlende Zeilen: `keymap.conflicts()` und ein
Usercmd-Namens-Scan brauchen dieselbe Behandlung wie `bindings.audit`
in `roadmap-tools-analysis.md` — Modul ist echt, es fehlt nur der
`create_usercmd()`-Aufruf in `lua/plugins/personal/init.lua`. Danach ist
der Duplikat-Check jederzeit mit einem Tastendruck wiederholbar, statt
alle paar Wochen von Hand neu gelesen zu werden (die beiden
Cross-Plugin-Dateien sind vom 2026-08-25 — seither: der komplette
CDX-Comment-Sweep, der luals-Diagnostics-Sweep, mehrere neue Keymaps/Befehle.
Ein Refresh ist überfällig, unabhängig von diesem Punkt hier).

Punkt 3 (Bedeutungstreue der Namen) bleibt **Lesearbeit für dich** — das
Werkzeug kann bestenfalls die Liste sauber aufbereiten (gruppiert, mit
Beschreibung, evtl. mit einer Low-Confidence-Markierung für vage
Adjektiv-Subcommands wie `deep`/`full`/`check`/`info` ohne erklärenden
Zusatz), nicht das Urteil fällen.

Punkt 1 ist die einzige echte Neubau-Arbeit, und er zerfällt sauber in zwei
Hälften mit unterschiedlichem Risiko:

- **Sicher automatisierbar:** prüfen, ob der Callback hinter einer
  Keymap/einem Usercmd/einem Autocmd überhaupt eine aufrufbare Lua-Funktion
  ist (kein `nil`, kein fehlgeschlagener `require`). Das fängt die häufigste
  reale Fehlerklasse — Tippfehler in einem Modulpfad, ein Feld, das beim
  Refactor verschwunden ist — **ohne** die Aktion tatsächlich auszuführen.
  Läuft headless, ohne Beobachtung nötig.
- **Nicht sicher automatisierbar:** die Aktion wirklich auslösen. Viele
  Kommandos/Keymaps sind destruktiv, öffnen einen Picker, der auf Input
  wartet, oder verändern Editor-/Dateisystemzustand (`:File`-Operationen,
  `:Image scale`, alles unter `:Case`, Session-Speichern, `:Gopath`-Sprünge).
  Ein Skript, das diese blind durchklickt, ist selbst das Risiko, das der
  Check eigentlich finden soll. Das ist exakt der Grund, warum du im
  CDX-Punkt selbst schon zwischen „Testrunner vorbereiten" (mein Teil) und
  „Beobachten in Echtzeit" (dein Teil) unterschieden hast — die Trennung ist
  richtig, nicht nur eine Formalität.

---

## Plan, in Phasen

### Phase 1 — Duplikat-Checks live schalten (klein, sofort machbar) — ✅ erledigt 2026-09-07

Umgesetzt, verifiziert, gepusht (`lib.nvim@6ff0a61`, `nvim-config@5fe06d86d`):

- **`:LibKeymapConflicts`** — neu in `lib.nvim`, `keymap.create_usercmd()`
  (`bindings/keymap/init.lua`). Zeigt `conflicts()` über `kit.viewer`, mit
  einer Coverage-Zeile, wenn lazy.nvim-Plugins noch nicht alle geladen sind
  (`x/y lazy-loaded plugins loaded right now`).
- **`:LibBindingsAuditPrefixes`** — neu in `lib.nvim`, `audit.lua`, vierte
  Route neben `LibBindingsAudit[Keys|Gaps]`. Prüft `<Tab>`-/Abkürzungs-
  Ambiguität über `vim.api.nvim_get_commands({builtin=false})` — **kein**
  Namens-Duplikat-Scan, weil `nvim_create_user_command` ein zweites Mal
  registrieren desselben Namens ohnehin verweigert (echte Duplikate können
  im laufenden Zustand gar nicht existieren). Das ist im Docstring
  festgehalten, damit das nicht mit Punkt 2 des Original-Tickets verwechselt
  wird — jener war für Keymaps gemeint, `:LibKeymapConflicts` deckt ihn ab.
- Beide gewired über ein neues nvim-config-Submodul
  `lua/bindings/usrcmds/bindings_audit/init.lua`, registriert in
  `lua/bindings/usrcmds/init.lua` neben `autocmd_docs` — derselbe Ort, an
  dem `LibUsercmdDocs`/`LibAutocmdDocs` schon gewired sind.

**Verifiziert:** `stylua --check` + `luacheck` sauber in beiden Repos.
Beide Funktionen isoliert headless getestet (`nvim --headless --clean
--cmd "set rtp+=E:/repos/lib.nvim"`, lib.nvim ohne die volle Config
geladen) — `keymap.conflicts()` fand einen synthetischen `<leader>zz`-
Konflikt zwischen zwei registrierten Actions korrekt, `prefix_ambiguities()`
fand `:Lsp`/`:LspDoctor` und `:File`/`:Filetree` korrekt (dieselben Fälle,
die `Usercmds-Overview.md` von Hand notiert hatte), beide Kommandos liefen
ohne Fehler.

**Offener Nebenbefund, kein Blocker:** ein End-to-End-Test gegen die volle
Config (`nvim --headless -u init.lua`) zeigt **kein einziges** Usercmd aus
`bindings.usrcmds` — auch nicht die längst existierenden wie `:CopyLocation`
oder `:LibUsercmdDocs`. Ursache: `require("bindings.usrcmds")` hängt am
custom `"UIReady"`-Startup-Phase (`lua/startup/init.lua`), der laut eigenem
Kommentar erst feuert, wenn „VimEnter has fired and the paint that follows
it" tatsächlich stattfindet — das passiert unter reinem `--headless` (kein
UI-Client, auch nicht nach manuellem `doautocmd UIEnter`) nie. Das ist also
eine **generelle Lücke für Phase 4** (der eigentliche Laufzeit-Testrunner
braucht einen Weg, `UIReady` in einer headless-Session zu erzwingen, oder
läuft testweise mit `--embed` gegen einen echten UI-Client), keine, die
Phase 1 betrifft — die beiden neuen Kommandos sind über den isolierten Weg
bewiesen korrekt.

**Noch nicht gemacht, absichtlich:** der Usercmd-Namens-Präfix-Scan wurde
nicht gegen die echte Config laufen gelassen (s.o., `UIReady` blockiert
das headless). Phase 2 (Refresh von `Keymaps-Collisions.md` /
`Usercmds-Overview.md` gegen die neuen Live-Kommandos) ist damit der
nächste sinnvolle Schritt, aber **muss in einer echten UI-Session laufen**,
nicht headless — `:LibKeymapConflicts` und `:LibBindingsAuditPrefixes`
einfach in deiner normalen nvim-Instanz aufrufen.

---

#### Ursprünglicher Plan (Referenz)

1. `require("lib.nvim.bindings.keymap").conflicts()` einen Usercmd geben.
   Entweder als eigener Aufruf `M.create_usercmd()`-artig direkt in
   `lua/plugins/personal/init.lua` (dort, wo `lib.nvim` konfiguriert wird —
   dieselbe Stelle, die für `bindings.audit` und `dev.duplicates` schon
   fehlt), oder als neue Route unter dem bestehenden `:Bindings`-Composer
   (`bindings_explorer/init.lua`), näher an `check`/`report`, da dort schon
   die Infrastruktur für Ausgabe (`kit.viewer`) und Markdown-Report
   (`report.lua`) steht. Letzteres ist konsistenter mit dem Rest der Datei,
   Ersteres ist der Weg, den `roadmap-tools-analysis.md` für die
   Schwestermodule vorgesehen hat — beide sind vertretbar, deine
   Entscheidung beim Umsetzen.
2. Denselben Riegel für `usercmd.registered()` bauen: Namen sammeln, auf
   Duplikate prüfen (bei 31 Repos + Config eigentlich nur eine
   Häufigkeitstabelle über `name`), plus optional die Präfix-Ambiguitäts-
   Prüfung aus `Usercmds-Overview.md` (`vim.fn.exists(':' .. prefix) == 2`
   probieren) automatisieren. Existiert als Konzept noch nirgends als
   Funktion — wäre der eigentliche neue Code in dieser Phase.
3. **Vollständigkeits-Falle:** beide Checks sehen nur, was **aktuell
   geladen** ist. lazy.nvim verzögert die meisten der 31 Plugins bis zu
   einem Event/Kommando/Filetype. Vor dem Check entweder alles laden
   (`:Lazy load` ohne Argument lädt nicht alles — eher jedes Plugin einzeln
   mit `require("lazy").load({ plugins = {...} })` durchgehen, oder die
   Lazy-Spec kurzzeitig mit `lazy = false` überschreiben) oder — wie
   `bindings_explorer`'s `check repo`-Achse es für unentdeckte Kommandos
   schon tut — zusätzlich eine Source-Achse lesen statt nur die Registry.
   Ohne das meldet der Check nach einem frischen Start fälschlich „keine
   Duplikate", nur weil die Hälfte der Plugins noch gar nicht da ist.

---

### Zwischenschritt — `:Bindings audit`/`conflicts` als Alias — ✅ erledigt 2026-09-07

Auf Nachfrage geprüft, ob `:LibKeymapConflicts`/`:LibBindingsAudit*` und das
bestehende `:Bindings`-Kommando (bindings_explorer) sich überschneiden.
Ergebnis: keine Logik-Überschneidung — `:Bindings check/report` vergleicht
Doku-Corpus gegen Live-Registry, die neuen Kommandos vergleichen die
Live-Registry gegen sich selbst, ohne Doku. Trotzdem als dünne Routen unter
`:Bindings audit[/gaps/keys/prefixes]` und `:Bindings conflicts` verdrahtet
(`nvim-config@30e54d0f1`) — dieselben lib.nvim-Funktionen, keine Kopie,
selbes Verb-plus-Alias-Muster wie `:AllDrives` → `:Pickers drives files`.
Headless verifiziert: alle fünf Routen registrieren und laufen fehlerfrei,
auch mit optionalem `[root]`-Pfad-Argument.

---

### Phase 2 — Refresh der beiden Cross-Plugin-Dateien — ✅ erledigt 2026-09-07

Du hast `:LibKeymapConflicts` und `:LibBindingsAudit[Gaps|Keys]` in deiner
echten Session laufen lassen (74/115 lazy-Plugins geladen) und mir die
Ausgabe geschickt — das war der eigentliche Phase-2-Schritt, live gegen den
tatsächlichen Zustand statt headless.

**Echter Fund dabei, sofort behoben:** `:LibKeymapConflicts` meldete
`<leader>fm` als „claimed by more than one registration" — beide Claimants
dieselbe Zeile, `lsp.nvim/lua/lsp/languages/documentation/markdown.lua:56`.
Kein Zwei-Plugin-Konflikt, sondern eine echte Lücke in
`lib.nvim.bindings.keymap.records`: ein `FileType`-Autocmd, der für einen
schon getypten Buffer erneut feuert (Neovim tut das auch bei
No-Op-Zuweisung desselben Filetyps), registrierte denselben
Buffer-lokalen `<leader>fm` zweimal, und die Direct-Record-Liste
deduplizierte nie — anders als `bindings.usercmd`s eigene Records, die das
schon konnten. Gefixt: `records.add()` ersetzt jetzt einen
Buffer+lhs+mode-identischen Eintrag statt ihn anzuhängen
(`lib.nvim@d1f2a4b`). Verifiziert per Skript: dreifaches Feuern derselben
Stelle bleibt jetzt sauber, ein echter Zwei-Buffer- bzw.
Zwei-Actions-Konflikt wird weiterhin erkannt.

Damit fand der Live-Check **null** echte Cross-Plugin-Duplikate — deckt
sich mit der Handanalyse, allerdings nur auf den zum Checkzeitpunkt
geladenen ~64 % der Plugins (die Lazy-Coverage-Falle aus dem Plan war also
real, nicht nur Theorie). `Keymaps-Collisions.md` und `Usercmds-Overview.md`
tragen je einen Nachtrag mit den Details, dem Fix-Verweis und der
Klarstellung, dass echte Usercmd-Namens-*Duplikate* live prinzipiell nicht
beobachtbar sind (der Verlierer meldet keinen Fehler als „Duplikat", sein
`setup()` bricht einfach ab — `Usercmds-Overview.md`s 148-Namen-Ergebnis
bleibt auf der Handanalyse stehen, nicht auf einem Live-Recheck).

Nebenbefund: `:LibBindingsAudit`/`Gaps`/`Keys` liefen dabei zum ersten Mal
überhaupt gegen die echte Config (355 Keymap-Actions, 954 Command-Routes,
6 Gaps, 31 nicht-portable Keys) — vorher nur isoliert getestet in Phase 1.

**Nicht gemacht:** volle Neubewertung aller 355/954 Einträge gegen die
beiden Dateien Zeile für Zeile — das war nie der Plan (die Dateien sind
Prosa-Analyse, kein 1:1-Abgleich mit der Rohliste). Die 6 `Gaps`- und
31 `Keys`-Funde aus dem Nebenbefund sind nicht triagiert; das wäre ein
eigener, kleiner Punkt, falls gewünscht.

---

### Phase 2 — ursprünglicher Plan (Referenz)

Mit den Kommandos aus Phase 1 einmal laufen lassen und
`Keymaps-Collisions.md` + `Usercmds-Overview.md` gegen den aktuellen Stand
abgleichen (Diff zur Handanalyse vom 2026-08-25). Abweichungen sind
entweder neue echte Befunde (zurück in die jeweilige Datei) oder ein Zeichen,
dass der automatisierte Check etwas anders zählt als die Handanalyse
(Scope-Behandlung prüfen — das war schon einmal die Fehlerquelle, siehe
„A · Source-Achse von `:Bindings check`" in `PLUGIN_ROADMAPS_TESTPLAN.md`:
eine „wesentlich größere Zahl" an Befunden macht eher das Werkzeug
verdächtig als die Config).

---

### Phase 3 — Namensqualität: Report statt Urteil — ✅ erledigt 2026-09-07

Umgesetzt als fünfte `audit`-Variante statt einer eigenen Markdown-Tabelle:
`audit.naming_candidates()`/`naming_candidate_lines()` (`lib.nvim@8dfcbec`),
gewired als `:LibBindingsAuditNaming` und `:Bindings audit naming`
(`nvim-config@1c2af3e95`). Nutzt dieselbe Routenliste, die
`command_routes()` schon sammelt — kein neuer Datenweg.

Flag-Regel: letztes Pfad-Segment ist eins von `deep/full/check/info/debug/
all/basic/extra/advanced/misc`. Bewusst nur eine Kandidatenliste, kein
Urteil — im Docstring und in der Ausgabe selbst festgehalten ("a flag here
is a candidate, not a verdict"). Mit einer synthetischen `LspDoctor deep`-
Route verifiziert: wird erkannt, `probe` (dieselbe Verb-Familie) und eine
Plain-Kommando-Route nicht — keine falschen Positiven im Test.

**Nicht geprüft:** ob das echte, aktuelle `LspDoctor` in dieser Config
(nach der `fmt_check`-Umbenennung) noch etwas zum Flaggen hat — das
Kommando lief nicht gegen deine echte Session. `:LibBindingsAuditNaming`
oder `:Bindings audit naming` einmal bei dir aufrufen zeigt den echten
Stand.

---

### Phase 4 — Laufzeit-Testrunner, zweistufig — ✅ erledigt 2026-09-07

**Der ursprüngliche Tier-1-Plan (auto-invoke „sicher aussehender" Aktionen)
wurde verworfen, bevor Code dafür entstand.** Grund: `:LibBindingsAudit`s
eigener erster echter Lauf (Phase 2) zeigte 954 Command-Routes aus dieser
Config, darunter `:Sandbox wsl shutdown-all`, `:Cases delete`,
`:File delete`, `:MyPlugins remove`. Keine Keyword-Heuristik ist
zuverlässig genug, um automatisch zu entscheiden, welche von ~1300
Einträgen gefahrlos unbeaufsichtigt ausgelöst werden dürfen — ein
Fehlklassifizierter reicht für echten Schaden. Auto-Invoke bleibt deshalb
bewusst ungebaut.

**Umgesetzt stattdessen: ein Markdown-Checklisten-Generator**, der
`bindings.audit.keymap_actions()`/`command_routes()` (schon vorhanden,
keine neue Datenquelle) in eine Checkbox-Liste im exakt selben Format wie
[`PLUGIN_ROADMAPS_TESTPLAN.md`](../personal/All/FINISH/PLUGIN_ROADMAPS_TESTPLAN.md)
umwandelt — dieses Repo hatte die Konvention für „von Hand durcharbeiten,
Fortschritt im Dateizustand halten" schon, keine neue Erfindung nötig:

- `audit.checklist_lines(root)` (`lib.nvim@4c2fe98`) — invoke **nie**,
  gruppiert Keymaps nach Surface und Usercmds nach Verb, sortiert
  Kandidaten mit verdächtigem Wort in Beschreibung/Route (`delete`,
  `remove`, `kill`, `shutdown`, `wipe`, `force`, …) in einen eigenen
  „⚠ Handle with care"-Abschnitt — Hinweis für dich beim manuellen
  Durcharbeiten, keine Ausführungs-Gate.
- `:LibBindingsAuditChecklist` / `:Bindings audit checklist` — Vorschau
  (`kit.viewer`, nichts wird geschrieben).
- `:BindingsRuntimeChecklist[!]` (`nvim-config@23e71e5ac`) — schreibt nach
  `docs/ROADMAP/personal/All/BINDINGS-RUNTIME-CHECKLIST.md`. Verweigert
  Überschreiben ohne `!`, weil die Datei über mehrere Sitzungen hinweg von
  Hand abgehakt werden soll — eine stille Neugenerierung würde bereits
  gesetzte `[x]` zurücksetzen. Verifiziert (gegen ein per
  `package.loaded`-Override umgeleitetes Scratch-Verzeichnis, damit der
  Test nichts im echten Repo hinterlässt): erstes Schreiben ok, zweites
  ohne `!` verweigert + Warnung, mit `!` überschreibt.

**Tier 2 (interaktiv, mit dir am Gerät) ist damit dieselbe Datei, nicht ein
separates Kommando.** Eine eigene Stepper-UI (Warteschlange, `<CR>` für
„ok", Fortschritt in einem eigenen State-Format) wurde erwogen und
verworfen — sie hätte nur nachgebaut, was ein Markdown-Checkbox-File mit
`git diff`-Historie schon kann, plus neuen UI-Code ohne echten
Mehrwert gegenüber der etablierten `PLUGIN_ROADMAPS_TESTPLAN.md`-Arbeitsweise.
Destruktive/UI-öffnende Einträge landen im „Handle with care"-Abschnitt
statt automatisch angefasst zu werden — die Scope-Unterscheidung aus
`Keymaps-Collisions.md` (global/filetype/tree/UI) ist bewusst **nicht**
mit eingeflossen, weil `keymap_actions()` die Buffer-Scope-Information gar
nicht mehr trägt (nur `keymap.registered()` roh hat sie) — eine bekannte,
akzeptierte Vereinfachung, keine Untersuchung wert für den Nutzen, den sie
gebracht hätte.

**Nächster Schritt bei dir:** `:BindingsRuntimeChecklist` einmal aufrufen
und die Datei nach und nach abarbeiten, wie bei den `PLUGIN_ROADMAPS_TESTPLAN.md`-Punkten.

---

## Risiken / offene Fragen

- **Lazy-Loading-Vollständigkeit** (siehe Phase 1, Punkt 3) ist der Punkt,
  an dem ein „sieht sauber aus"-Ergebnis am ehesten falsch-negativ ist.
  Jeder der drei Checks muss vor der Auswertung explizit sagen, wie viele
  Plugins tatsächlich geladen waren — sonst ist ein Rückgang der
  Fund-Zahl gegenüber `Keymaps-Collisions.md` nicht von echtem Fortschritt
  zu unterscheiden.
- **Destruktive Aktionen in Tier 2** — die Warteschlange sollte den Scope
  aus `Keymaps-Collisions.md` (global/filetype/tree/UI) und, wo bekannt,
  eine grobe Risikoeinstufung mitführen, damit du nicht bei jedem Eintrag
  neu einschätzen musst, ob ein Auslösen etwas verändert.
  „`:Image scale`" schreibt eine Datei, "`:Lsp status`" nicht — das sollte
  vorher feststehen, nicht während der Sitzung.
- **`conflicts()`s Buffer-Scope-Prämisse** — sie behandelt buffer-lokale
  Bindings grundsätzlich als nicht-kollidierend mit globalen. Das ist laut
  README bewusst so (siehe Bestandsaufnahme), deckt sich aber nicht
  vollständig mit `Keymaps-Collisions.md`s „Cross-scope shadowing"-
  Abschnitt, der genau solche Fälle als **berichtenswert** einstuft (auch
  wenn sie kein Bug sind — `<leader>th` etwa). Der automatisierte Check
  wird also grundsätzlich weniger Fälle zeigen als die Handanalyse; das ist
  kein Fehler des Tools, nur ein anderer Anspruch. In der Doku des neuen
  Kommandos festhalten, damit ein „nur noch 40 statt 60 Funde" nicht als
  Verbesserung missverstanden wird, obwohl nur die schwächere Prüfung läuft.

---

## Wie das Ergebnis dokumentiert wird

Falls aus Phase 1/3/4 echter Code wird (neue Usercmds, ein Testrunner-Modul),
gilt dieselbe Behandlung wie in
[`roadmap-tools-analysis.md`](../personal/All/FINISH/ERLEDIGT/roadmap-tools-analysis.md):
eine Tabelle **Vorschlag → Verdikt → Zuhause (welches Repo) → Status**, und
„Status" heißt **verifiziert wired**, nicht nur „Modul existiert" — genau der
Fehler, den die Nachträge dieser Datei zweimal korrigieren mussten
(`create_usercmd()` real, aber nirgends aufgerufen). Ein `grep` nach dem
neuen Kommandonamen über die ganze Config, das mindestens einen Treffer
außerhalb der Definition selbst zeigt, ist die Mindestprüfung, bevor „Status:
✅" irgendwo steht.

---

## Status: alle vier Phasen erledigt (2026-09-07)

Alles auf `main`, beide Repos (`lib.nvim`, `nvim-config`), jeder Schritt
formatiert (`stylua`), gelinted (`luacheck`) und headless verifiziert, bevor
er committet wurde.

**Neue Kommandos, im Überblick:**

| Kommando | `:Bindings`-Alias | Was |
|---|---|---|
| `:LibKeymapConflicts` | `:Bindings conflicts` | `lhs` mehrfach vergeben |
| `:LibBindingsAudit` | `:Bindings audit` | Keymap-Actions vs. Command-Routes |
| `:LibBindingsAuditGaps` | `:Bindings audit gaps` | Actions ohne Kommando-Pendant |
| `:LibBindingsAuditKeys` | `:Bindings audit keys` | nicht-portable Tasten |
| `:LibBindingsAuditPrefixes` | `:Bindings audit prefixes` | `<Tab>`-Präfix-Ambiguität |
| `:LibBindingsAuditNaming` | `:Bindings audit naming` | vage Subcommand-Namen (Kandidaten) |
| `:LibBindingsAuditChecklist` | `:Bindings audit checklist` | Checkliste, nur Vorschau |
| — | `:BindingsRuntimeChecklist[!]` | Checkliste, schreibt nach Datei |

**Übrig aus dem Original-Ticket, bewusst nicht automatisiert:** das
tatsächliche Auslösen jeder Aktion (Punkt 1 im Original-Ticket) — dafür ist
jetzt [`BINDINGS-RUNTIME-CHECKLIST.md`](../BINDINGS-RUNTIME-CHECKLIST.md)
da. Das Abarbeiten ist wie im Original-Ticket festgehalten: deine Domäne.

> **Nachtrag 2026-09-07 — erste echte Generierung.** Gegen deine volle
> Session: **1303 Einträge** (331 Keymaps, 870 Usercmd-Routen, 102 im
> „Handle with care"-Abschnitt). Die Risiko-Heuristik hat genau die
> Beispiele erkannt, die Phase 4 überhaupt erst motiviert hatten
> (`:Sandbox wsl shutdown-all`, `:Case delete`, `:File delete`,
> `:MyPlugins remove`, …) — Design bestätigt. Nebenbefund, nicht Teil
> dieses Ranges: 261 Einträge ohne Beschreibung (`(no description)`),
> größtenteils `Debug`/`Filetree`-Subrouten — eine Doku-Lücke, keine
> Fehlfunktion. Committet als `nvim-config@f3b1ba281`.

---

