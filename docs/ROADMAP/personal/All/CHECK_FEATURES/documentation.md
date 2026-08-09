# documentation.nvim — Live-Test-Checkliste

Für dich, zum manuellen Durchtesten. Checkbox-Syntax ist Standard-Markdown
(`- [ ]` → `- [x]`) — mit deinem eigenen `cascade.nvim` (`<leader>tc`) direkt
in Neovim togglebar.

Reihenfolge folgt Priorität: erst das, was jeder Nutzer sofort trifft, zuletzt
Randfälle. Wo ich einen Verdacht habe, was schiefgehen könnte, steht er dabei
— das ist der Teil, der beim Lesen des Codes nicht hundertprozentig sicher
war und einen echten Blick verdient.

---

## 0. Vorher

- [ ] Sicherstellen, dass `documentation.nvim` und `lib.nvim` über den
      Plugin-Manager tatsächlich geladen sind (`:Lazy` / dein Äquivalent),
      bevor du unten irgendwas testest — sonst testest du einen alten Stand.
- [ ] Ein Repo mit `---@module`-Headern zur Hand haben, das *nicht*
      documentation.nvim selbst ist (z.B. ein anderes deiner Plugins) — damit
      du auch die Auto-Detection von `source`/`title` gegen ein zweites Layout
      prüfst, nicht nur gegen das, wofür es entwickelt wurde.

## 1. Grundinstallation & Lazy-Loading

- [ ] Frisch gestartetes Neovim: `:DocMap` und `:DocBrowse` existieren
      **nicht**, bis du sie tippst (Command-lazy via `cmd = {...}`) —
      `:command DocMap` sollte vor dem ersten Aufruf nichts finden, danach
      registriert.
- [ ] `opts = {}` reicht — kein `root` gesetzt, trotzdem mappt `:DocMap` das
      aktuelle Arbeitsverzeichnis, nicht `~/.local/share/nvim/lazy/...`.
      **Das ist der Punkt, der beim Umbau am meisten Sinn hatte, schiefzugehen**
      (Root-Auflösung wurde extra von "eigene Datei" auf `getcwd()`
      umgestellt) — einmal wirklich in zwei verschiedenen `cwd`s prüfen.
- [ ] `source`-Autodetection: in einem Repo mit genau einem Unterordner unter
      `lua/` testen (sollte den finden), und optional in einem mit mehreren
      (sollte auf `"lua"` zurückfallen statt zu raten).

## 2. `:DocMap` — Generator

- [ ] `:DocMap` (blank) — schreibt `index.html`/`module_map.json`/
      `overview.md`, druckt Node-Zählung, Test-Coverage-%, Doc-Coverage-%,
      Findings.
- [ ] `:DocMap check` — auf sauberem Baum: "up to date". Dann eine Kleinigkeit
      ändern (z.B. eine Doc-Zeile in einer Funktion löschen), erneut prüfen:
      sollte als **stale** oder als Finding auftauchen, und Findings landen in
      der **Quickfix-Liste** (`:copen`), nicht nur als Message.
- [ ] `:DocMap full` — mit installiertem `lua-language-server`: läuft durch,
      dauert spürbar länger. **Ohne** `lua-language-server` auf PATH: sollte
      *nicht* fehlschlagen, sondern ein `info`-Finding
      `luals-unavailable` erzeugen — das gezielt einmal ohne LS testen, das
      ist der Fehlerpfad, der leicht übersehen wird.
- [ ] `:DocMap open` — öffnet die HTML-Seite im System-Browser.

## 3. Die generierte HTML-Karte

- [ ] **Tree-Tab**: Baum navigierbar, Funktionen unter "ƒ N functions"
      eingeklappt, Klick öffnet Detail-Pane.
- [ ] **Hierarchy-Tab**, alle fünf Views durchklicken: Modules, Types (nur mit
      `:DocMap full` sinnvoll — ohne sollte sie das explizit sagen, nicht leer
      bleiben), Inheritance, Deps, Calls.
- [ ] Deps-View: `+ external` Toggle zeigt externe Requires als graue Boxen.
- [ ] Rechtsklick auf eine Box/Funktion/einen Typ — Kontextmenü mit
      aktivierten/deaktivierten (mit Zahl) Einträgen.
- [ ] Zoom: Mausrad, `+`/`-`/`0`, und **Semantic Zoom** — weit reinzoomen auf
      eine Leaf-Box sollte eine Ebene tiefer springen (drill-in).
- [ ] Suche (`#q`) im Tree-Tab filtert; im Hierarchy-Tab re-centered sie live,
      **ohne** die Browser-History zu verschmutzen — Back-Button danach
      testen, sollte zum Zustand vor der Sucheingabe zurückgehen, nicht zu
      jedem Tastendruck.
- [ ] Browser Back/Forward über mehrere Aktionen hinweg (Tab wechseln, Node
      wählen, Hierarchy re-centern) — jeder Schritt ein eigener Stop.
- [ ] `↓ SVG`-Export im Hierarchy-Tab — Datei öffnet sich sauber (nicht nur in
      Chrome/Firefox, auch in einem SVG-Viewer/Inkscape, falls zur Hand).
- [ ] **Notes-Tab**: falls `@deprecated`/`@todo`/`@bug` im Baum vorkommen,
      hier gelistet; sonst expliziter "nichts hier"-Text statt leerer Tab.
- [ ] **Index-Tab**: A-Z-Liste, Functions/Modules-Toggle, Sortierung nach
      dem *letzten* Namensteil (`M.read` unter R, nicht M).
- [ ] **Analysis-Tab**, alle Panels: Test Coverage, Documentation, Dependencies
      (Fan-in/-out), Complexity, **Duplicates** (strukturelle Code-Doppelung),
      **Churn** (git-history × Komplexität, falls das Repo Git-History hat).
      Jede Zeile anklickbar → Tree-Tab.
- [ ] Direkt geöffnet als `file://` (also **ohne** `:DocMap serve`): History-
      Tab sollte sich selbst erklären ("needs a server"), nicht leer/kaputt
      wirken.

## 4. Die Graph-/Git-Subcommands

- [ ] `:DocMap graph deps` und `:DocMap graph calls <modul>` — öffnet die HTML
      direkt im richtigen Tab/View, nicht nur auf der Startseite.
- [ ] `:DocMap why <a> <b>` — mit zwei tatsächlich verbundenen Modulen:
      Quickfix-Liste mit dem Require-Pfad, jeder Hop auf der Zeile, wo der
      `require` steht.
- [ ] `:DocMap dot deps` und `:DocMap dot calls <modul>` — Scratch-Buffer mit
      Graphviz-DOT-Text, kein Fehler auch ohne `dot`-Binary installiert.
- [ ] `:DocMap diff HEAD~5` (oder passende Ref-Distanz für dein Repo) —
      Strukturbericht: neue/entfernte Module, Funktionen, Dependencies.
- [ ] `:DocMap impact` (ohne Ref, gegen uncommitted changes) — Quickfix mit
      betroffenen Funktionen + deren Call-Sites. **Am besten mit einer
      unfertigen, uncommitteten Änderung testen**, das ist der Use-Case.
- [ ] `:DocMap impact HEAD~1` — gleiche Analyse gegen den letzten Commit.
- [ ] `:DocMap churn` — Quickfix, absteigend nach `commits × complexity`.
      Prüfen, ob Merges wirklich rausgefiltert sind (Commit-Zahl sollte nicht
      absurd hoch wirken).
- [ ] `:DocMap serve` — startet lokalen Server; **danach `:DocMap open`**:
      History-Tab lädt jetzt wirklich (Commit anklicken → Analyse). `:DocMap
      serve stop` beendet ihn wieder — danach sollte ein erneutes `open`
      wieder auf `file://` zurückfallen.
  - [ ] Sicherheitscheck, einmal reicht: Server bindet nachweislich nur
        `127.0.0.1` (z.B. `netstat`/`ss` während er läuft), nicht `0.0.0.0`.

## 5. `:DocBrowse` — Editor-Navigator

- [ ] `:DocBrowse` (blank) — liest die Artefakt-Datei, fühlt sich schnell an
      (~10ms laut Doku).
- [ ] `:DocBrowse live` — merklich langsamer beim Öffnen (voller Scan). Dann
      eine Datei im gescannten `source`-Baum ändern und speichern: Browser
      sollte automatisch neu rendern. **Eine Datei außerhalb von `source`
      ändern** — sollte *nicht* neu scannen (Windows-Pfad-Edge-Case, den es
      laut Doku mal gab).
- [ ] `:DocBrowse <modul-oder-namespace>` — zentriert korrekt, auch auf einem
      **Namespace** ohne `init.lua` (z.B. `documentation.core.render`, falls
      es das als Verzeichnis ohne init gibt) — das ist der Fall, der früher
      stillschweigend auf die Root fiel.
- [ ] Modi durchschalten `1`–`6`: structure/deps/calls/types/history/trail.
- [ ] `j`/`k` bewegen, Detail-Pane folgt live mit.
- [ ] `<CR>` steigt ab / folgt einer Kante; `-`/`<BS>` geht hoch.
- [ ] `<C-o>`/`<C-i>` — mehrere Schritte navigieren, zurück, wieder vor;
      Cursor-Zeile sollte beim Zurückkommen stimmen, nicht auf Zeile 1
      springen.
- [ ] `h`/`l` (Deps/Calls) wechselt Richtung; `+`/`_` (nur Deps) Tiefe.
- [ ] `gd` — springt zur Quelle, Browser schließt sich dabei.
- [ ] `gq` — aktuelle Liste in Quickfix, Browser schließt sich.
- [ ] `gI` — Blast-Radius des **im Detail-Pane gezeigten** Eintrags (nicht
      zwingend des zentrierten Node) in Quickfix.
- [ ] `gO` — öffnet die HTML-Seite an exakt der Position (Modus + Richtung).
- [ ] `f` — Filter: einfacher Text, negierter Term (`-foo`), Phrase in
      Anführungszeichen; leere Eingabe hebt den Filter wieder auf.
- [ ] `/` — Fuzzy-Sprung über Module *und* Funktionen.
- [ ] `?` — Cheatsheet-Float; Tasten, die der aktuelle Modus ignoriert,
      erscheinen **markiert**, nicht versteckt (z.B. `+`/`_` außerhalb Deps).
- [ ] `q`/`<Esc>` schließt.

### Trail (Modus `6`)

- [ ] `p` in einem beliebigen Modus (z.B. Deps, `h` für incoming) pinnt den
      Eintrag unterm Cursor. Nochmal `p` auf demselben Eintrag → unpinnt.
- [ ] Modus `6` zeigt den gepinnten Eintrag; `<CR>` darauf stellt **Modus UND
      Richtung/Tiefe** wieder her, nicht nur den Node — das war explizit die
      Design-Entscheidung, einmal wirklich mit unterschiedlichem `dir`
      gepinnt gegenprüfen.
- [ ] `d` im Trail-Modus unpinnt den Eintrag unterm Cursor.
- [ ] `S` — nach Namenseingabe wird der aktuelle Trail gespeichert.
- [ ] `L` — Auswahl-Picker mit gespeicherten Trails; **Laden addiert**, ersetzt
      nicht — vorher etwas anderes pinnen, dann laden, beides sollte danach
      da sein.
- [ ] `X` — löscht einen gespeicherten (benannten) Trail, ohne die aktuell
      gepinnten Einträge anzufassen.
- [ ] **Neustart-Test**: Neovim komplett schließen, wieder öffnen,
      `:DocBrowse trail` — die vorher gepinnten Einträge sollten noch da sein
      (Persistenz nach `stdpath('state')/documentation.nvim/trails.json`,
      geschrieben debounced + beim Beenden). Danach einen Blick in die Datei
      selbst werfen, ob sie plausibel aussieht.
- [ ] Ein Pin auf etwas setzen, das Modul danach umbenennen/löschen und den
      Baum neu scannen — der Trail-Eintrag sollte als "no longer in the map"
      angezeigt werden, nicht als kaputter Link.

### History (Modus `5`)

- [ ] Commit-Liste lädt; `<CR>` auf einem Commit zeigt betroffene Funktionen +
      Caller-Zahl.
- [ ] `<CR>` auf einer betroffenen Funktion springt in Calls/incoming.
- [ ] `gD` zeigt den Commit-Diff in einem Scratch-Buffer.
- [ ] Einen **sehr alten** Commit öffnen (falls vorhanden, von vor dem
      Hinzufügen der Map) — sollte "predates the committed map" anzeigen statt
      falscher Zahlen.

## 6. Konfiguration

- [ ] `opts.keys = { quickfix = "gQ" }` — `gQ` funktioniert, `gq` nicht mehr;
      `?`-Cheatsheet zeigt die neue Taste.
- [ ] `opts.keys = { filter = false }` — `f` tut nichts mehr, taucht im
      Cheatsheet als `(disabled)` auf.
- [ ] `opts.which_key = true` (Default) mit installiertem which-key: Popup bei
      `<leader>`o.ä. zeigt die DocBrowse-Aktionen mit Beschreibung. **Falls du
      kein which-key installiert hast**, wenigstens prüfen, dass nichts
      crasht (soll `pcall`-geguarded sein).
- [ ] `opts.badge = true` einmal testweise setzen, `:DocMap` laufen lassen —
      `coverage.svg` wird geschrieben, öffnet sich als valides Bild.
- [ ] `opts.tests_dir` auf einen nicht-existenten Pfad setzen, `:checkhealth
      documentation` laufen lassen — sollte das *melden*, nicht schweigend
      0% Coverage im Analysis-Tab produzieren (das war der eigentliche Punkt,
      für den der Health-Check gebaut wurde — lohnt sich, ihn genau hierfür
      einmal zu triggern statt nur den Erfolgsfall zu sehen).

## 7. `:checkhealth documentation`

- [ ] Sauberer Lauf: alle Sektionen grün (Environment, lib.nvim-Deps,
      optionale Tools, registrierte Commands, aufgelöste Config, Artefakte).
- [ ] Einmal **absichtlich kaputt machen**: `lib.nvim` testweise aus dem `rtp`
      nehmen (oder `opts.root` auf ein Verzeichnis ohne `.lua`-Dateien
      zeigen) und prüfen, dass der Check das mit einer nützlichen Meldung
      auffängt statt einer rohen Lua-Fehlermeldung.
- [ ] Artefakt künstlich veralten lassen (Quelldatei nach der letzten
      `:DocMap`-Generierung anfassen) — Health meldet "older than the newest
      source file".

## 8. CI / Hooks lokal

- [ ] `scripts/ci.sh` (oder `nvim --headless -l scripts/ci.lua`) einmal
      komplett grün durchlaufen lassen, auf deiner echten Maschine (nicht nur
      wie hier mit `LIB_NVIM_DIR` gesetzt) — falls du lib.nvim über den
      Plugin-Manager statt manuell auflöst, ist das der erste echte Test
      dieses Pfads.
- [ ] `git config core.hooksPath scripts/hooks` in einem Test-Klon aktivieren,
      absichtlich eine stale Map committen versuchen — Hook blockiert mit
      brauchbarer Fehlermeldung, `git commit --no-verify` umgeht ihn wie
      dokumentiert.

## 9. Was ich *nicht* für nötig halte, aber du kannst

- [ ] `opts.tag_files` gegen ein zweites, eigenes Repo mit committeter Map
      testen (Cross-Project-Links im Deps-View).
- [ ] `opts.layers` / `layer-violation`-Check mit einer bewusst falschen Regel.
- [ ] `opts.dead_code = true` — prüfen, ob dann tatsächlich mehr `info`-Findings
      auftauchen als ohne.
- [ ] `opts.calls_heuristic = true` — gestrichelte, geratene Call-Kanten im
      Calls-View.

---

**Wenn beim Testen etwas nicht dem hier beschriebenen Verhalten entspricht:**
kurz notieren *was* du getan hast und *was* stattdessen passiert ist — das
reicht mir als Repro, den Rest finde ich im Code.
