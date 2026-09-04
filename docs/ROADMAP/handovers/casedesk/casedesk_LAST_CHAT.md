Beides ist durch, alles committet und gepusht, CI grün.

## 1. Der Typ-Rename — `Lib.Case.*` → `Casedesk.*`

261 Fundstellen, 35 Dateien, 53 Typnamen ([`d8be673`](https://github.com/StefanBartl/casedesk.nvim/commit/d8be673)).

**Eine Kollision musste aufgelöst statt ersetzt werden.** `Casedesk.SlaWindow` existierte schon — als Union `Lib.Case.SlaWindow|"24x7"`. Ein durchgehendes `sed` hätte daraus einen Alias auf sich selbst gemacht. Die Tabellenhälfte heißt jetzt `Casedesk.BusinessHours`, der Alias behält die Union, und die `---@cast`-Verengungen zeigen weiter auf die Tabelle — das war der Schritt, der syntaktisch sauber und semantisch wertlos geworden wäre.

**Der Gewinn stand nicht im Plan:** das Messartefakt aus Phase 1 ist weg. Der reguläre LuaLS-Scan meldete 231 `duplicate-doc-field` gegen die eingefrorene Zwillingskopie. Die Doppelung kam aus gleichen **Klassennamen**, nicht aus gleichen Dateien — also erledigt der Rename, was laut Plan erst Phase 7 erledigen sollte. Mit einer Konfiguration vorher/nachher gemessen:

| Lauf | Befunde |
| --- | --- |
| vorher, Config in `workspace.library` | **232** |
| vorher, Kontroll-Config | 1 |
| nachher, Config in `workspace.library` | **1** |

Die Kontroll-Config wird nicht mehr gebraucht. Beleg im wkdbook.

## 2. Phase 4 — Doku

[`ba5bc21`](https://github.com/StefanBartl/casedesk.nvim/commit/ba5bc21) und `9fc01127` in der Config.

**Umgezogen:** CONCEPT, SLA, EXTRACTION, SESSIONS, PTO, HANDOVER, Workflow → `docs/WORKFLOW.md`, Wunschliste → `docs/REQUESTS.md`. Kein Aufräumen um seiner selbst willen: **158 Doc-Verweise im Quelltext** zeigten auf `docs/ROADMAP/casedesk/…`, also auf Pfade, die ein fremder Checkout nicht hat. In der Config stehen Zeiger.

**`docs/commands.md` ist generiert** — über `lib.nvim.bindings.usercmd.composer.document()`, aus demselben Routen-Baum wie Dispatch und Completion. Damit kann die Referenz nicht veralten. `scripts/gen_docs.sh --check` vergleicht, ein vierter CI-Job schlägt bei einer alten Fassung fehl. Die handgeschriebene `CHEATSHEET.md` daneben sagt *warum*, die generierte *was*.

**Neu:** `configuration.md` (jede Option mit Typ und echtem Default, aus `DEFAULTS.lua` ausgelesen statt abgetippt), `BINDINGS.md`, `installation.md`, `install.json`, `doc/casedesk.txt` mit zehn Abschnitten und Tags.

### Drei Befunde beim Schreiben

**`health.lua` prüfte nie, was `:Cases export` braucht.** `pandoc` und ein Chromium fehlten — man hätte `:checkhealth casedesk` grün bekommen und der Export wäre trotzdem gescheitert. Beides drin, der Browser über `export.find_browser()` statt über eine zweite Kopie der Pfadliste: ein reiner `PATH`-Test meldet auf Windows einen Fehlalarm.

**Zwei Listen derselben Werkzeuge** hätten es werden können. Stattdessen liest `health.lua` jetzt `docs/install.json` über `lib.nvim.deps` — was `:Lib deps status` installiert und was `:checkhealth` meldet, ist eine Liste. Die winget-IDs habe ich gegen die Live-Quelle geprüft, nicht geraten.

**`MIGRATION.md` gibt es nicht.** Sechsmal aus dem Quelltext zitiert, zweimal aus CONCEPT.md, teils mit Abschnittsnummern — und in keinem Repo auffindbar. Die Verweise zeigen jetzt auf CONCEPT.md §3 und §10, wo die Begründungen wirklich stehen, und CONCEPT.md sagt einmal, dass die Datei weg ist.

### Eine Plan-Annahme ist gefallen

PLUGIN.md §3.3 sagte, `docs/NOTES/casedesk/` sei Teil des Bindings-Korpus, den `:Bindings` prüft. Nachgeprüft: `bindings_explorer/config.lua`s `M.roots()` liest nur `PersonelPlugins/BINDINGS/` und `ExternPlugins/Bindings/`. Der Ordner kam dort nie vor — er war ein eigenständiger Cheatsheet-Satz, also Plugin-Doku. §3.3 ist korrigiert, und `Usercmds/Case.md` heißt jetzt `Usercmds/casedesk.nvim.md`, weil `:Bindings drift` über den Dateistamm mit dem Checkout paart und `Case` zu keinem Repo passte.

## 3. Dein Completion-Wunsch steht im Plan

PLUGIN.md §9.2 und `casedesk.nvim/docs/ROADMAP.md`. Der Eingriffspunkt ist genau eine Funktion — `registry.complete()`, deren letzte Zeile heute `table.sort(out)` ist.

Vier mögliche Signale sind dokumentiert (Ordner-`mtime`, Benutzungsjournal, aktueller Buffer, `git log --since`) mit **Empfehlung: `mtime` als Basis, der Case des aktuellen Buffers als Fixstern, Journal erst wenn sich die Ordnung falsch anfühlt** — die erste Fassung braucht damit keinen neuen Zustand.

Zwei Regeln habe ich als nicht verhandelbar festgehalten: **sortieren, nie filtern** (eine Completion, die alte Cases weglässt, macht den gesuchten unerreichbar — deine 24 Stunden sind ein Ranking-, kein Sichtbarkeitsschwellwert), und **kein `stat`-Sturm pro Tastendruck** (die Zeitstempel gehören in den Registry-Cache). Bewusst offen: ob die Ordnung *stabil* sein soll — eine Liste, die sich zwischen zwei Tab-Drücken umsortiert, weil eine Minute vergangen ist, bedient sich unangenehm; grobe Zeitfenster als Sortierklasse wären die ruhigere Variante.

## Gates

stylua sauber, luacheck 0/0 über 45 Dateien, 32 Specs grün, `gen_docs.sh --check` grün, LuaLS 1 Befund (`assert.are_not` — eine Typlücke in luassert, kein Befund an diesem Code). nvim startet fehlerfrei, Statusline liefert weiter ihr Label. CI grün nach einem Nachschlag: `gen_docs.sh` ging als `100644` rein und lief in „Permission denied" — Windows trägt das Exec-Bit nicht, git musste es explizit bekommen.

## Als Nächstes

Phase 5 (Tests — heute 32 Specs für 11.295 Zeilen) oder Phase 6 (Rollout). Phase 7, das Löschen der eingefrorenen Kopie, würde ich bewusst liegen lassen, bis das Plugin ein paar Arbeitstage getragen hat. Meine Empfehlung ist **Phase 5**: die Testlücke ist das, was in diesem Projekt bisher zweimal echte Fehler verdeckt hat.
