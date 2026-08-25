# Sweep-Plan: RULES-Backlog auf alle *.nvim-Plugins anwenden

Stand: 2026-08-24. Quelle: drei der vier `RULES-*.md` in diesem Verzeichnis.

**Nicht im Scope:** `RULES-plugin-ideas.md`. Bleibt vollstaendig liegen, kommt
spaeter als eigenes Vorhaben. Im Sweep wird sie weder gelesen noch veraendert.

## Grundentscheidung

Plugin-weise, nicht datei-weise. Pro Plugin wird der Kontext
(`bindings/usrcmds*`, `bindings/keymaps*`, `config`, `docs/BINDINGS.md`) einmal
geladen und fuer alle drei Task-Arten genutzt statt dreimal.

Das passt auch inhaltlich: `RULES-plugin-ideas.md` ist ohnehin keine
Pro-Plugin-Liste (lib.nvim-Bausteine, neue Standalone-Plugins, Quickfix-Audit)
und ist hier bewusst ausgeklammert.

## Harte Regel: lib.nvim ist die Basis

Bei jeder Implementierung im Sweep gilt:

1. Zuerst pruefen, ob `lib.nvim` das schon kann. Nichts lokal neu bauen, was
   dort existiert (usercmd.composer, autocmd, cross.fs, ui.kit, notify, ...).
2. Wenn lib.nvim es fast kann: **lib.nvim erweitern**, nicht im Plugin
   umgehen. Erweiterung als eigener Commit in `C:
epos\lib.nvim`, danach das
   Plugin darauf umstellen.
3. Wenn dieselbe Loesung im Sweep ein zweites Mal gebraucht wird, gehoert sie
   nach lib.nvim - sofort, nicht spaeter.
4. Jede lib.nvim-Erweiterung wird im Ledger vermerkt, damit spaetere Plugins
   sie wiederverwenden statt neu zu erfinden.

Praktisch heisst das: der Sweep laesst lib.nvim mitwachsen. Phase 1 ist nur
der bekannte Vorlauf, nicht die vollstaendige Liste der lib.nvim-Arbeit.

## Dokumentationspflichten (gelten fuer jede Aenderung)

Code ohne diese Eintraege gilt nicht als fertig.

### Im Plugin-Repo

- `docs/BINDINGS.md` - Keymaps/Usercmds/Autocmds des Plugins.
- `docs/FEATURES` bzw. `docs/FEATURES.md` - **jedes** Feature eintragen, auch
  rein interne. Das ist der Feature-Backlog fuer Devs, nicht nur die
  User-Kommunikation. Format wie in den bestehenden Dateien: Beschreibung plus
  `**Module:**` / `**Usercmds:**` / `**Autocmds:**` / `**Config:**`.
- `CHANGELOG.md`, Options-/Commands-Doku, wo vorhanden.

### Zentral in nvim-config

Jeder neue oder geaenderte Keymap, Usercmd oder Autocmd zusaetzlich in:

```
docs/NOTES/PersonelPlugins/BINDINGS/Keymaps/<plugin>.nvim.md
docs/NOTES/PersonelPlugins/BINDINGS/Usercmds/<plugin>.nvim.md
docs/NOTES/PersonelPlugins/BINDINGS/Autocmds/<plugin>.nvim.md
```

Dazu die Sammel-/Indexdateien: das jeweilige `All.md`, bei Autocmds ausserdem
`autocmds-by-event.md`, `autocmds-by-filetype.md`, `autocmds-by-plugin.md`.

Format strikt nach `docs/NOTES/BINDINGS-FORMAT.md` - die Tabellen werden von
`bindings-explorer` geparst, freie Prosa an der falschen Stelle bricht den
Scraper. Zur Verifikation am Ende jedes Plugins `:Bindings check` laufen lassen
(Drift-Erkennung) statt die Tabellen von Hand gegenzulesen.

### In lib.nvim

Neues Modul oder erweitertes Modul heisst zwingend auch:

- `docs/modules.md` - Namespace-Tabelle ergaenzen.
- `docs/API/<thema>.md` - Funktionssignaturen.
- `docs/FEATURES/<THEMA>.md` - Feature-Eintrag.
- `README.md` des Moduls unter `lua/lib/...`, wo die Nachbarmodule eines haben.
- `doc/lib.nvim-*.txt` (vimdoc), wo es fuer vergleichbare Module existiert.
- `docs/BINDINGS/Usercmds.md`, falls ein Kommando dazukommt.

## Phasen

### Phase 0 - Ledger erzeugen (einmalig, ~1 Session)

Aus den drei Pro-Plugin-Dateien eine Datei `SWEEP-LEDGER.md` generieren:
pro Plugin ein Block mit allen offenen Punkten aus allen drei Quellen,
als Checkboxen, mit Herkunftsmarker `[C]` Completion, `[N]` Count,
`[F]` Flags/Optionen.

Zweck: jede spaetere Session laedt nur ihren eigenen Block (~15-40 Zeilen)
statt der drei Quelldateien (~33k Zeichen). Das ist der groesste Einzelhebel
im ganzen Plan.

Regel: Der Ledger ist ab dann die Wahrheit. Die `RULES-*.md` werden erst am
Ende gestrichen, gesammelt.

### Phase 1 - lib.nvim-Blocker zuerst (1-2 Sessions)

Nur die Bausteine, die der Sweep selbst mehrfach braucht - abgeleitet aus den
Pro-Plugin-Listen, nicht aus der ausgeklammerten Ideen-Datei.

- [ ] `lib.nvim.autocmd.create`: `buffer`-Feld durchreichen. In pickers.nvim,
      github_stats.nvim, color_my_ascii.nvim, markdown.nvim existieren dafuer
      vier unabhaengige Workarounds. Ein Upstream-Fix, danach vier Rueckbauten.
- [ ] `composer.register_type`: generischer `PATH`/`DIR`-Completion-Typ.
      Gebraucht in debugging.nvim (keylogger path), gopath.nvim (add-root),
      reposcope.nvim (clone target), learn-cli.nvim, nvim-config
      (`:MyReposUpdate`).
- [ ] `lib.nvim.chained_action`: Count-sicheres Wiederholen asynchroner
      Aktionen, extrahiert aus dap.nvims `counted_step()`. Gebraucht fuer die
      Count-Nachruestungen mit Async-Anteil.
- [ ] Kleiner Count-Helper / Konvention: `count1`-Weiterreichung, Clamping.
      Kein Modul noetig wenn eine dokumentierte Zeile reicht - dann nur als
      Snippet in der Regeldatei festhalten.

Nicht in Phase 1: alles Weitergehende (Frecency-Konsolidierung,
TUI-Dashboard-Kit, Registry, ...). Das steht in der ausgeklammerten Ideen-Datei
und ist ein eigenes Vorhaben.

### Phase 2 - Plugin-Sweep (eine Session je Plugin)

Immer dasselbe Rezept, damit der Kontext pro Session minimal bleibt:

1. Ledger-Block des Plugins lesen (nur den).
2. `docs/BINDINGS.md` + Command/Keymap-Registrierungsdateien lesen. Sonst nichts.
3. Unverifizierte Punkte ("unklar ob ... completet") zuerst pruefen - viele
   loesen sich als bereits erledigt auf und kosten dann null Implementierung.
4. Implementieren: erst Completion, dann Count, dann Flags. In der Reihenfolge,
   weil Completion oft die Route-Struktur klaert, die Flags dann brauchen.
5. Doku nachziehen - vollstaendig nach "Dokumentationspflichten" oben:
   Plugin-`BINDINGS.md`, `docs/FEATURES`, CHANGELOG, **und** der zentrale
   `docs/NOTES/PersonelPlugins/BINDINGS/`-Baum inklusive Indexdateien.
6. `:Bindings check` gegen Drift.
7. Ein Commit pro Plugin (plus separater lib.nvim-Commit, falls die Lib
   erweitert wurde), Ledger-Haken setzen.
8. Die erledigten Punkte **sofort** aus der jeweiligen `RULES-*.md` entfernen -
   nicht sammeln. Ist eine `RULES-*.md` dadurch leer, wird sie geloescht.

Definition of Done pro Plugin: alle Ledger-Punkte abgehakt oder mit
Begruendung als "n/a" markiert, Plugin-Doku und zentraler Bindings-Baum
konsistent, `:Bindings check` sauber, Commit gepusht, RULES-Zeilen entfernt.

#### Welle A - Pilot und Einzelposten (je 1-2 Punkte)

Zuerst ein kleines Plugin als Pilot, um das Rezept zu schaerfen.
Vorschlag Pilot: `gopath.nvim` (genau ein Punkt, unverifiziert).

gopath, runtime-analysis, insights, open, dap, diff, cmdlog, sessions,
pdfport, recommender, migrate, color_my_ascii, debugging

#### Welle B - Mittlere Plugins (2-4 Punkte)

buffer-ctx, cascade, emojis, fileops, filetree, github_stats, images,
language, markdown, mdview, pickers, sandbox, spotlight, reposcope

#### Welle C - Schwer / unscharf (zuletzt, wenn das Rezept sitzt)

- `replacer.nvim`: volle Flag-/kv-Completion fuer `:Replace`
  (`--regex --type= --glob= --exclude= --changed= --engine= --context=`).
  Groesster Einzelbrocken, evtl. eigener composer-Mechanismus.
- `documentation.nvim`: Git-Ref-Completion, `<Plug>`-Mappings.
- `nvim-config` (dieses Repo): eigener Durchgang, andere Struktur.

#### Offen / Blocker

- `learn-cli.nvim` liegt nicht unter `C:\repos\*.nvim`. Tasks in allen drei
  Dateien vorhanden. Klaeren: existiert das Plugin, anderer Pfad, oder
  Eintraege streichen?

### Phase 3 - Quickfix-Audit (1 Session)

`UI-36`: Trefferlisten auch in die Quickfix-Liste. Bisher nur replacer.nvim.
Erst pruefen, welche Plugins schon exportieren, dann gezielt ergaenzen.
Kandidaten: pickers.nvim, documentation.nvim, markdown.nvim.
Bewusst nach dem Sweep, damit die Route-Strukturen schon stabil sind.

### Phase 4 - Backlog aufloesen

Da laufend gestrichen wird (Schritt 8 im Rezept), sollten
`RULES-audit-completion.md`, `RULES-audit-count.md` und
`RULES-flags-options.md` hier bereits geloescht sein. Falls Reste bleiben:
diese pruefen und aufloesen. `RULES-plugin-ideas.md` bleibt unangetastet
liegen.

## Token-Regeln fuer den Sweep

- Eine Session je Plugin, frisch. Nicht mehrere Plugins in einer Session -
  der Kontext des vorigen Plugins ist dann totes Gewicht.
- Nie die drei grossen `RULES-*.md` in einer Sweep-Session laden. Nur den
  Ledger-Block.
- lib.nvim-Erweiterungen bekommen einen eigenen Commit im lib.nvim-Repo,
  getrennt vom Plugin-Commit, der sie nutzt.
- Keine Subagenten fuer den Sweep. Jeder Agent startet kalt und liest das
  Plugin erneut - genau der Ladevorgang, den der plugin-weise Zuschnitt
  einspart.
- `RULES-plugin-ideas.md` nie oeffnen. Sie ist die groesste der vier Dateien
  und komplett out of scope.
- Unverifizierte Punkte immer zuerst. Sie sind billig und reduzieren oft die
  Arbeitsmenge.
- Ein Commit pro Plugin, damit ein abgebrochener Sweep an Plugin-Grenzen
  wieder aufsetzbar ist.
