# Handover — Usrcmd-Hilfe-Float (Root-/Gruppen-Commands)

Lebendes Dokument: nach **jedem** erledigten Schritt aktualisieren. Konzept und
Aufwandsanalyse (Stand 2026-10-01, noch **nichts implementiert**, kein Commit).

**Arbeitsweise (global):** Antworten deutsch, Code/Kommentare englisch; max. 1 Agent
gleichzeitig; nach jedem Schritt sofort auf `main` pushen; **keine** Co-Author-Zeile
(globale Regel); vor `git add` immer `git status`; kein bares `git stash`; Edit-Skripte
mit Backslashes nicht durch Bash-Heredocs jagen (siehe `HEREDOC.md`).
Hauptrepo: `lib.nvim` (`E:\repos\lib.nvim`). Folge-Änderungen in `ui.nvim`,
nvim-config (`C:\Users\bartl\AppData\Local\nvim`) und einzelnen Plugins.

## Wunsch (Originalwortlaut sinngemäß)

1. Wer nur den Root-Usrcmd eingibt (`:Clipboard`, `:Ui`, `:Reposcope`, …), bekommt heute
   eine Notify-Textausgabe der möglichen Optionen. Stattdessen soll ein **UI-Float** mit
   allen Optionen erscheinen: Liste, je `option — kurze Beschreibung`. **`<CR>` fügt die
   Option in die Cmdline ein.**
2. Perspektivisch **auf jeder Ebene**: `:Cdx prompt` (unvollständig) soll nicht in einen
   Fehler/Notify laufen, sondern das Float mit den Optionen der nächsten Ebene öffnen.
3. Alle Usrcmds hängen am Composer (`lib.nvim.bindings.usercmd.composer`) → **einmal dort
   implementieren, für alle ausspielen**. Mehraufwand: Optionen beschreiben (`desc`).

## Ist-Zustand (Befunde)

- **Dispatch-Stelle:** `lua/lib/nvim/bindings/usercmd/composer/parse.lua`, `M.dispatch`.
  Die drei Fälle, die heute notifizieren:
  - bare `:Verb` ohne `spec.default` und ohne Root-Route (`path = {}`) →
    `notify.info(M.usage(...))`;
  - gültiger Gruppen-Präfix ohne Blatt (`:Cdx prompt`) → `notify.error("'%s' needs a subcommand.\n<usage>")`;
  - unbekannter Subcommand → `notify.error("unknown subcommand '%s'.\n<usage>")`.
- **Datenquelle fertig:** `tree.walk(root, fargs)` liefert tiefsten Knoten + Anzahl
  verbrauchter Tokens; `node.children` / `node.route.desc` genügen für die Liste.
  `tree.child_keys`, `tree.each_route`, `format.invocation` existieren.
- **Notifier ist injiziert** (`deps = { error, info }`, gebaut in `composer/init.lua:
  make_deferred_notify`) → `parse.lua` bleibt synchron/headless testbar. Das Float muss
  genauso **injiziert** werden, nicht fest verdrahtet.
- **Float-Bausteine:** `lua/lib/nvim/ui/kit/menu.lua` (themed, j/k, `<CR>`, `<Esc>`/`q`,
  verschachtelte Items = Drill-down mit `Back`/`<BS>`, Gruppen-Boxen, rechtsbündige
  `rtxt`-Spalte), darunter `chooser.lua`/`surface.lua`/`theme.lua`.
  Der Routen-Baum lässt sich 1:1 auf verschachtelte Menü-Items abbilden.
- **Beschreibungen:** nur geringe Lücken. Grobe Zählung über die Composer-Repos:
  ~544 Routen, ~644 `desc`-Zeilen (Docgen braucht sie ohnehin). Lücken (je 1–2 Routen,
  1 `desc`): replacer.nvim, recommender.nvim, fileops.nvim, debugging.nvim.
- **Composer-Verben:** ~40 Plugin-Repos (87 `.verb(`-Aufrufe), darunter nvim-config
  `lua/bindings/usrcmds/cdx/init.lua` (`:Cdx`) und `.../clipboard/init.lua` (`:Clipboard`)
  → profitieren automatisch.
- **Nicht-Composer (die echte Lücke):** `ui.nvim` — `:UI` und `:Theme` sind handgebaut
  (`lua/ui/bindings/usrcmds/init.lua`: eigener `dispatcher`, eigene `complete()` mit
  `if subcmd == …`-Ketten, ~1000 Zeilen). Außerdem handgebaute `usercmd.create`-Aufrufe
  in lsp.nvim (~10 Dateien) u. a.; ob diese eine Root-Verb-Struktur haben, ist **noch
  zu prüfen**.

## Design

### `composer/help.lua` (neu)
- `help.items(cmd_name, node, path)` → Menü-Items. Blatt: Label `:Verb sub`, Beschreibung
  `route.desc`; Gruppe: Eintrag mit `items = {…}` (Drill-down), Marker `→`.
  Reihenfolge wie `tree.child_keys` (sortiert). `route.available`/`route.check` beachten
  (gleiche Filterung wie `complete.lua`), damit nur Nutzbares erscheint.
- `help.open(cmd_name, node, path, opts)` öffnet `kit.menu` (oder die Variante mit
  `desc`-Spalte, s. u.). `<CR>` auf einem Blatt/Eintrag: Float schließen, dann
  `nvim_feedkeys(":" .. text .. " ", "nt", false)` → Cmdline bleibt offen, Tab-Completion
  und weitere Tokens funktionieren. **Einfügen, nicht ausführen** (Entscheidung des
  Nutzers; direktes Ausführen argloser Blätter wäre ein Opt-in, nicht Default).
- **Fallbacks** (alte Notify-Ausgabe bleibt): kein UI (`#nvim_list_uis() == 0`),
  `:silent`/`opts.smods.silent`, Float nicht öffenbar, `spec.help == false`.

### Einhängen in `parse.dispatch`
- Injektion wie beim Notifier: `deps.help` (`fun(cmd_name, node, consumed_path): boolean`,
  true = Float geöffnet). Fällt `help` aus/false, läuft der bisherige Notify-Pfad.
- Fall 1/2/3 oben rufen `help` mit dem erreichten Knoten; bei „unknown subcommand"
  zusätzlich den Fehlertext kurz anzeigen (Titel/Hinweiszeile im Float oder Notify), damit
  Tippfehler nicht stumm bleiben.
- `spec.default` gewinnt weiterhin (z. B. `:Replace`); Float nur dort, wo bisher die
  Usage-Notify kam.

### Beschreibungs-Spalte
- Variante A (0 h): `sub — Beschreibung` als reiner Label-Text.
- Variante B (~2 h, empfohlen): eigene `desc`-Spalte in `kit/menu.lua`, sauber
  ausgerichtet, abgeschnitten mit Ellipse; `rtxt` nicht zweckentfremden (Ausrichtung
  bricht bei langen Texten).

### Stufe 2 (optional): fehlende Argumente
- `bind_args` → `missing required argument …`: dasselbe Float mit den Enum-Werten /
  `values` des fehlenden Args. Dafür optionales Feld `enum_desc` (Wert → Beschreibung)
  im `ArgSpec`/`FlagSpec`/`KvSpec` (`composer/@types/init.lua`, `format.lua`,
  `argtypes.lua`, `docgen.lua` mitziehen). Nur dort befüllen, wo Werte nicht
  selbsterklärend sind.

## Arbeitspakete & Aufwand

| # | Paket | Repo | Aufwand |
|---|---|---|---|
| 1 | `composer/help.lua`: Baum → Items, Fallbacks | lib.nvim | ~3 h |
| 2 | Einfügen bei `<CR>` (`feedkeys`), Drill-down | lib.nvim | ~2 h |
| 3 | `desc`-Spalte in `kit/menu.lua` (Variante B) | lib.nvim | 0–2 h |
| 4 | `parse.dispatch` + `composer/init.lua`: `deps.help` injizieren, 3 Fälle umstellen, `spec.help`-Opt-out | lib.nvim | ~2 h |
| 5 | Tests (s. u.) | lib.nvim | ~3 h |
| 6 | Docs/Typen: README Composer, `@types`, Docgen-Hinweis | lib.nvim | ~1 h |
| 7 | `:UI`/`:Theme` anbinden **oder** auf Composer migrieren | ui.nvim | 2 h (anbinden) / ~1 Tag (migrieren) |
| 8 | Beschreibungs-Lücken füllen | replacer/recommender/fileops/debugging | ~1–2 h |
| 9 | `enum_desc` + Missing-Arg-Float (Stufe 2) | lib.nvim | ~6–7 h |
| 10 | Handgebaute Commands in lsp.nvim u. a. prüfen/anbinden | diverse | offen (erst Inventur) |

**Kern (1–6): ~11–13 h.** Danach profitieren alle ~40 Composer-Repos ohne Änderung.

## Tests (lib.nvim)

- `help.items`: Baum mit Blatt/Gruppe/verschachtelt, Sortierung, `available`/`check`-Filter.
- Dispatch: bare Verb, Gruppen-Präfix, unbekannter Token → `help` wird mit korrektem
  Knoten/Pfad gerufen; Rückgabe `false`/nil → alter Notify-Text (bestehende Specs müssen
  unverändert grün bleiben).
- `spec.default` und Root-Route (`path = {}`) haben Vorrang.
- Headless/kein UI → Notify-Fallback.
- `<CR>`-Einfügetext (`feedkeys`-Inhalt, abschließendes Leerzeichen, Drill-down-Pfad).
- Vorlagen: `usrcmds_dispatch_spec.lua` (fileops.nvim), `bindings_usrcmds_spec.lua`
  (casedesk.nvim), `composer_spec_*`-Verben aus den lib.nvim-Tests.

## Risiken / Entscheidungen

- **Verhaltensänderung:** Keymaps/Skripte, die `:Verb` bare per `vim.cmd` rufen, öffnen
  ein Float statt Notify → Opt-out (`spec.help = false`) + Headless-Erkennung sind Pflicht.
- **Drift-Gefahr:** `kit/menu.lua` ist (wie `toast`) in lib.nvim **und** ui.nvim gespiegelt
  (`ui.nvim/lua/ui/kit/menu.lua`); eine `desc`-Spalte in beiden Kopien ändern, Drift-Test
  beachten.
- **Zirkuläre Requires:** `composer` wird lazy aus `bindings/usercmd/init.lua` exponiert
  (`lib.lua.lazy.require` ist eager — Cycle-Falle, siehe Memory „telemetry roadmaps");
  `help.lua` daher erst beim ersten Bedarf `require`n, nicht auf Modul-Ebene.
- **Fokus:** Das Float öffnet aus einer Cmdline-Callback heraus → ggf. `vim.schedule`
  (analog zum deferred Notifier), sonst kollidiert es mit dem Cmdline-Redraw.
- **Entscheidung offen:** `:UI` migrieren (Docgen/Health gratis, ~1 Tag) oder nur
  anbinden (2 h, Tabelle `{subcmd, desc}`)?

## Empfohlene Reihenfolge

1. Pakete 1–6 (Kern, ein Commit pro Paket, Tests inklusive).
2. Paket 7 (`:UI`), Entscheidung migrieren/anbinden vorher klären.
3. Paket 8 (Beschreibungs-Lücken) und Paket 10 (Inventur) bei Bedarf.
4. Stufe 2 (Paket 9).

## Stand

- 2026-10-01: Analyse + Konzept fertig, Handover geschrieben. **Nichts implementiert,
  keine Commits.** Nächster Schritt: Pakete 1–6 in lib.nvim (Branch/Worktree laut
  globaler Git-Regel: direkt `main`, nach Abschluss pushen).
